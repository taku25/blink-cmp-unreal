local M = {}

-- local ts_utils = require("nvim-treesitter.ts_utils")

-- ローカル変数や引数の定義を探すクエリ
-- キャプチャ名: @type, @var_name, @value (初期化式)
local LOCAL_VAR_QUERY = [[
  ;; 通常の宣言: Type Var; Type* Var;
  (declaration
    type: (_) @type
    declarator: [
      (identifier) @var_name
      (pointer_declarator (identifier) @var_name)
      (reference_declarator (identifier) @var_name)
      (template_type) @type
    ]
  )

  ;; 初期化付き宣言: Type Var = ...; auto Var = ...;
  (declaration
    type: (_) @type
    declarator: (init_declarator
      declarator: [
        (identifier) @var_name
        (pointer_declarator (identifier) @var_name)
        (reference_declarator (identifier) @var_name)
      ]
      value: (_) @value
    )
  )

  ;; 関数の引数: void Func(Type Var)
  (parameter_declaration
    type: (_) @type
    declarator: [
      (identifier) @var_name
      (pointer_declarator (identifier) @var_name)
      (reference_declarator (identifier) @var_name)
    ]
  )
  
  ;; Range-based for: for (auto& Var : Container)
  (for_range_loop
    type: (_) @type
    declarator: [
      (identifier) @var_name
      (pointer_declarator (identifier) @var_name)
      (reference_declarator (identifier) @var_name)
    ]
  )
]]

-- ノードのテキストを取得するヘルパー
local function get_node_text(node, bufnr)
    if not node then return nil end
    return vim.treesitter.get_node_text(node, bufnr)
end

-- 型ノードから実際の型名を抽出する
-- TObjectPtr<T> などを剥がす処理もここで行う
local function extract_type_name(type_node, bufnr)
    local raw_text = get_node_text(type_node, bufnr)
    
    -- 1. テンプレート型: TObjectPtr<AMyActor> -> AMyActor
    local _, inner_type = raw_text:match("([%w_]+)%s*<[%s*]*([%w_]+)[%s%*]*>")
    if inner_type then
        -- スマートポインタ系か確認 (TObjectPtr, TWeakObjectPtr, TSharedPtr, etc)
        -- もし TArray<T> なら T を返すか？ (TArrayはポインタ挙動しないが、要素アクセス時は...)
        -- ここでは "-> でアクセスする可能性があるもの" として、ラッパー型の中身を返す
        return inner_type, true -- true = is_smart_pointer
    end
    
    -- 2. 通常の型: AMyActor, int32, etc.
    -- const や & を除去
    local clean_type = raw_text:gsub("^const%s+", ""):gsub("[%s&]+$", "")
    
    return clean_type, false
end

-- 初期化式 (RHS) から型を推論する
local function infer_from_rhs(rhs_node, bufnr)
    local text = get_node_text(rhs_node, bufnr)
    
    -- 1. Cast<T>(...)
    local cast_type = text:match("Cast%s*<%s*([%w_]+)%s*>")
    if cast_type then return cast_type end
    
    -- 2. NewObject<T>(...)
    local new_obj_type = text:match("NewObject%s*<%s*([%w_]+)%s*>")
    if new_obj_type then return new_obj_type end
    
    -- 3. SpawnActor<T>(...)
    local spawn_type = text:match("SpawnActor%s*<%s*([%w_]+)%s*>")
    if spawn_type then return spawn_type end
    
    -- 4. CreateDefaultSubobject<T>(...)
    local subobj_type = text:match("CreateDefaultSubobject%s*<%s*([%w_]+)%s*>")
    if subobj_type then return subobj_type end
    
    -- 5. コンストラクタ呼び出し: FVector(...) -> FVector
    -- 難しいのでパス、あるいは単純なクラス名のみ対応
    
    return nil
end

-- 変数の定義を探し、型情報とポインタかどうかを返す
-- @return type_name (string), is_pointer (boolean)
function M.get_var_type(bufnr, target_var_name, cursor_row)
    local parser = vim.treesitter.get_parser(bufnr, "cpp")
    if not parser then return nil, false end
    
    local tree = parser:parse()[1]
    if not tree then return nil, false end
    
    local root = tree:root()
    local query = vim.treesitter.query.parse("cpp", LOCAL_VAR_QUERY)
    
    -- カーソル位置より前の定義の中で、最も近い (行番号が大きい) ものを探す
    -- ※本来はスコープ解析が必要だが、簡易的に「一番近い上の定義」を採用する
    
    local best_match = nil
    local best_row = -1
    
    for id, node, _ in query:iter_captures(root, bufnr, 0, cursor_row + 1) do
        local capture_name = query.captures[id]
        if capture_name == "var_name" then
            local var_name = get_node_text(node, bufnr)
            if var_name == target_var_name then
                local s_row, _, _, _ = node:range()
                
                -- カーソルより後ろの定義は無視 (ただし引数はカーソルと同じスコープとみなせる)
                if s_row <= cursor_row then
                    if s_row > best_row then
                        best_row = s_row
                        best_match = node -- var_name node
                    end
                end
            end
        end
    end
    
    if best_match then
        -- マッチした var_name の親や兄弟から type や value を探す
        local parent = best_match:parent() -- declarator or parameter_declaration
        -- もし declarator が pointer_declarator なら、それはポインタ
        local is_raw_pointer = false
        if parent:type() == "pointer_declarator" then
            is_raw_pointer = true
            parent = parent:parent() -- declaration or init_declarator
        end
        if parent:type() == "init_declarator" then
            parent = parent:parent() -- declaration
        end
        
        -- ここで parent は declaration / parameter_declaration / for_range_loop のはず
        -- type ノードを探す
        local type_node = parent:field("type")[1]
        local value_node = nil
        
        -- init_declarator の場合、value (RHS) も探す
        if parent:type() == "declaration" then
            for child in parent:iter_children() do
                if child:type() == "init_declarator" then
                    value_node = child:field("value")[1]
                    break
                end
            end
        end

        local type_text = get_node_text(type_node, bufnr)
        
        -- auto の場合
        if type_text == "auto" and value_node then
            -- RHS から推論
            local inferred_type = infer_from_rhs(value_node, bufnr)
            if inferred_type then
                return inferred_type, true 
            end
            
            local rhs_text = get_node_text(value_node, bufnr)
            return nil, false, rhs_text -- 3番目の戻り値としてRHSを返す
        end
        
        -- 通常の型定義
        if type_node then
            local type_name, is_smart_ptr = extract_type_name(type_node, bufnr)
            
            -- 生ポインタ OR スマートポインタ ならポインタ扱い
            local is_pointer = is_raw_pointer or is_smart_ptr
            
            return type_name, is_pointer
        end
    end
    
    return nil, false
end

-- 現在のカーソル位置が属するクラス名を取得する
function M.get_current_class_name(bufnr, cursor_row)
    local parser = vim.treesitter.get_parser(bufnr, "cpp")
    if not parser then return nil end
    local tree = parser:parse()[1]
    if not tree then return nil end
    local root = tree:root()
    
    local node = root:named_descendant_for_range(cursor_row, 0, cursor_row, 0)
    while node do
        local ntype = node:type()
        if ntype == "class_specifier" or ntype == "struct_specifier" or 
           ntype == "unreal_class_declaration" or ntype == "unreal_struct_declaration" then
            local name_node = node:field("name")[1]
            if name_node then
                return get_node_text(name_node, bufnr)
            end
        elseif ntype == "function_definition" then
            -- AMyClass::MyFunc の AMyClass 部分を取得
            local declarator = node:field("declarator")[1]
            -- declarator が pointer_declarator や reference_declarator の場合、中身を掘り下げる
            while declarator and (declarator:type() == "pointer_declarator" or 
                                 declarator:type() == "reference_declarator" or 
                                 declarator:type() == "function_declarator" or
                                 declarator:type() == "abstract_pointer_declarator") do
                local next_node = declarator:field("declarator")[1]
                if not next_node then break end
                declarator = next_node
            end

            if declarator and declarator:type() == "qualified_identifier" then
                 local scope = declarator:field("scope")[1]
                 if scope then
                     local class_name = get_node_text(scope, bufnr)
                     if class_name then
                         return class_name:gsub("::$", "")
                     end
                 end
            end
            -- フォールバック: テキストから AMyClass:: を探す
            local text = get_node_text(node, bufnr)
            if text then
                local m = text:match("([%w_]+)::[%w_]+%s*%b()")
                if m then return m end
            end
        end
        node = node:parent()
    end
    return nil
end

return M
