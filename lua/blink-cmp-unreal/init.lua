local M = {}

local unl_api_ok, unl_api = pcall(require, "UNL.api")
local ts_parser_ok, ts_parser = pcall(require, "blink-cmp-unreal.ts_parser")

--------------------------------------------------------------------------------
-- 1. デフォルト設定
--------------------------------------------------------------------------------
local default_config = {
  enable_uclass = true,
  enable_uproperty = true,
  enable_ufunction = true,
  enable_ustruct = true,
  enable_uenum = true,
  enable_uinterface = true,
  enable_meta_specifiers = true,
  enable_delegate_macros = true,
  enable_module_macros = true,
  enable_log_levels = true,
  enable_slate_macros = true,
  enable_uep_member_completion = true,
}

--------------------------------------------------------------------------------
-- 2. データ定義 (静的データ)
--------------------------------------------------------------------------------
local DB_STATIC = {
  UCLASS = {
    { label = 'Abstract', documentation = 'Prevents users from adding Actors of this class to Levels.' },
    { label = 'Blueprintable', documentation = 'Exposes this class as an acceptable base class for creating Blueprints.' },
    { label = 'BlueprintType', documentation = 'Exposes this class as a type that can be used for variables in Blueprints.' },
    { label = 'Config', documentation = 'Indicates that the class can store data in a configuration file (.ini).', insertText = 'Config=${1:Game}' },
    { label = 'DefaultToInstanced', documentation = 'All instances of this class are considered "instanced".' },
    { label = 'EditInlineNew', documentation = 'Objects of this class can be created from the Unreal Editor Property window.' },
    { label = 'MinimalAPI', documentation = 'Causes only the class type info to be exported.' },
    { label = 'NotBlueprintable', documentation = 'Specifies that this class is not an acceptable base class for Blueprints.' },
    { label = 'Placeable', documentation = 'Indicates that this class can be created in the Editor and placed into a level.' },
    { label = 'Transient', documentation = 'Objects belonging to this class will never be saved to disk.' },
  },
  UPROPERTY = {
    { label = 'EditAnywhere', documentation = 'Can be edited by property windows, on archetypes and instances.' },
    { label = 'EditDefaultsOnly', documentation = 'Can be edited by property windows, but only on archetypes.' },
    { label = 'EditInstanceOnly', documentation = 'Can be edited by property windows, but only on instances.' },
    { label = 'VisibleAnywhere', documentation = 'Visible in all property windows, but cannot be edited.' },
    { label = 'VisibleDefaultsOnly', documentation = 'Visible in property windows for archetypes only.' },
    { label = 'VisibleInstanceOnly', documentation = 'Visible in property windows for instances only.' },
    { label = 'BlueprintReadOnly', documentation = 'Can be read by Blueprints, but not modified.' },
    { label = 'BlueprintReadWrite', documentation = 'Can be read or written from a Blueprint.' },
    { label = 'Category = ""', documentation = 'Specifies the category of the property.', insertText = 'Category="${1:CategoryName}"' },
    { label = 'Replicated', documentation = 'The property should be replicated over the network.' },
    { label = 'ReplicatedUsing = ""', documentation = 'Specifies a callback function for replication.', insertText = 'ReplicatedUsing=${1:OnRep_Function}' },
    { label = 'meta = ()', documentation = 'Metadata specifiers.', insertText = 'meta=($1)' },
    { label = 'Instanced', documentation = 'Object property only. Unique copy per instance.' },
    { label = 'Transient', documentation = 'Property is transient, not saved/loaded.' },
    { label = 'SaveGame', documentation = 'Include for checkpoint/save systems.' },
  },
  UFUNCTION = {
    { label = 'BlueprintCallable', documentation = 'Can be executed in a Blueprint graph.' },
    { label = 'BlueprintPure', documentation = 'Does not affect the owning object (no execution pins).' },
    { label = 'BlueprintImplementableEvent', documentation = 'Can be overridden in a Blueprint.' },
    { label = 'BlueprintNativeEvent', documentation = 'Can be overridden by a Blueprint, but also has a native C++ implementation.' },
    { label = 'Category = ""', documentation = 'Specifies the category.', insertText = 'Category="${1:CategoryName}"' },
    { label = 'Exec', documentation = 'Can be executed from the in-game console.' },
    { label = 'Server', documentation = 'Executed on the server (RPC).', insertText = 'Server, Reliable, WithValidation' },
    { label = 'Client', documentation = 'Executed on the client (RPC).', insertText = 'Client, Reliable' },
    { label = 'NetMulticast', documentation = 'Executed on all clients (RPC).', insertText = 'NetMulticast, Reliable' },
    { label = 'Reliable', documentation = 'RPC is guaranteed to arrive.' },
    { label = 'Unreliable', documentation = 'RPC can fail.' },
    { label = 'CallInEditor', documentation = 'Adds a button to details panel.' },
  },
  META = {
    { label = 'DisplayName = ""', documentation = 'Name to display in the editor.', insertText = 'DisplayName="${1:Name}"' },
    { label = 'ToolTip = ""', documentation = 'Tooltip to display in the editor.', insertText = 'ToolTip="${1:Text}"' },
    { label = 'ClampMin = ""', documentation = 'Minimum value.', insertText = 'ClampMin="${1:0.0}"' },
    { label = 'ClampMax = ""', documentation = 'Maximum value.', insertText = 'ClampMax="${1:100.0}"' },
    { label = 'UIMin = ""', documentation = 'Slider minimum.', insertText = 'UIMin="${1:0.0}"' },
    { label = 'UIMax = ""', documentation = 'Slider maximum.', insertText = 'UIMax="${1:100.0}"' },
    { label = 'EditCondition = ""', documentation = 'Boolean property to enable/disable editing.', insertText = 'EditCondition="${1:bBoolProp}"' },
    { label = 'AllowPrivateAccess = "true"', documentation = 'Allows private property access from Blueprints.', insertText = 'AllowPrivateAccess="true"' },
    { label = 'MakeEditWidget', documentation = 'Draws a 3D widget in the viewport for this Transform/Vector.' },
    { label = 'Bitmask', documentation = 'Treats integer as a bitmask.' },
  },
  LOG_LEVEL = {
    { label = 'Fatal', documentation = 'Crash.' },
    { label = 'Error', documentation = 'Red text.' },
    { label = 'Warning', documentation = 'Yellow text.' },
    { label = 'Display', documentation = 'Console and log.' },
    { label = 'Log', documentation = 'Log only.' },
    { label = 'Verbose', documentation = 'Detailed.' },
    { label = 'VeryVerbose', documentation = 'Very detailed.' },
  },
  SLATE = {
    { label = 'SLATE_ARGUMENT', documentation = 'Widget argument (value).', insertText = 'SLATE_ARGUMENT(${1:Type}, ${2:Name})' },
    { label = 'SLATE_ATTRIBUTE', documentation = 'Widget argument (value or delegate).', insertText = 'SLATE_ATTRIBUTE(${1:Type}, ${2:Name})' },
    { label = 'SLATE_EVENT', documentation = 'Widget argument (callback).', insertText = 'SLATE_EVENT(${1:DelegateType}, ${2:Name})' },
    { label = 'SLATE_BEGIN_ARGS', documentation = 'Begin args struct.', insertText = 'SLATE_BEGIN_ARGS(${1:WidgetClass})\n\t: _${2:Arg}(${3:Default})\n\t{}\n$0\nSLATE_END_ARGS()' },
  },
  UENUM = {
    { label = 'BlueprintType', documentation = 'Exposes this enum as a type that can be used for variables in Blueprints.' },
    { label = 'meta = ()', documentation = 'Metadata specifiers.', insertText = 'meta=($1)' },
  },
  UINTERFACE = {
    { label = 'MinimalAPI', documentation = 'Causes only the interface type info to be exported.' },
    { label = 'Blueprintable', documentation = 'Exposes this interface as an acceptable base for creating Blueprints.' },
    { label = 'BlueprintType', documentation = 'Exposes this interface as a type that can be used for variables in Blueprints.' },
  }
}

--------------------------------------------------------------------------------
-- 3. デリゲート スニペット生成ロジック
--------------------------------------------------------------------------------
local SUFFIXES = {
  [0] = "", [1] = "_OneParam", [2] = "_TwoParams", [3] = "_ThreeParams",
  [4] = "_FourParams", [5] = "_FiveParams", [6] = "_SixParams",
  [7] = "_SevenParams", [8] = "_EightParams", [9] = "_NineParams",
}

local function generate_delegate_snippets()
  local items = {}
  local definitions = {
    { prefix = 'DECLARE_DYNAMIC_MULTICAST_DELEGATE', type = 'dynamic', desc = 'BP Assignable (Multicast)' },
    { prefix = 'DECLARE_DYNAMIC_DELEGATE',           type = 'dynamic', desc = 'BP Callable (Single)' },
    { prefix = 'DECLARE_MULTICAST_DELEGATE',         type = 'raw',     desc = 'C++ Multicast' },
    { prefix = 'DECLARE_DELEGATE',                   type = 'raw',     desc = 'C++ Single' },
    { prefix = 'DECLARE_EVENT',                      type = 'event',   desc = 'C++ Event (Owner First)' },
    { prefix = 'DECLARE_DELEGATE_RetVal',            type = 'retval',  desc = 'C++ Single RetVal' },
  }

  for _, def in ipairs(definitions) do
    for count = 0, 8 do
      local suffix = SUFFIXES[count]
      if suffix then
        local label = def.prefix .. suffix
        local idx = 1
        local args = {}
        if def.type == 'retval' then
          table.insert(args, string.format("${%d:ReturnType}", idx))
          idx = idx + 1
        end
        if def.type == 'event' then
          table.insert(args, string.format("${%d:OwningType}", idx))
          idx = idx + 1
        end
        table.insert(args, string.format("${%d:FDelegateName}", idx))
        idx = idx + 1
        for i = 1, count do
          table.insert(args, string.format("${%d:Type%d}", idx, i))
          idx = idx + 1
          if def.type == 'dynamic' then
            table.insert(args, string.format("${%d:Name%d}", idx, i))
            idx = idx + 1
          end
        end
        local snippet = string.format("%s(%s);", label, table.concat(args, ", "))
        table.insert(items, {
          label = label,
          kind = require('blink.cmp.types').CompletionItemKind.Snippet,
          documentation = {
            kind = 'markdown',
            value = string.format("**%s**\n\nArguments: %d\nMacro: %s", def.desc, count, label),
          },
          insertText = snippet,
          insertTextFormat = 2,
          sortText = string.format("%s_%02d", def.prefix, count) 
        })
      end
    end
  end
  return items
end

local delegate_cache = nil

--------------------------------------------------------------------------------
-- 4. コンテキスト解析 / 型推論ロジック (再帰対応)
--------------------------------------------------------------------------------

local function get_context(line_text, col, config)
  local before_cursor = line_text:sub(1, col)
  if config.enable_log_levels and before_cursor:match('UE_LOG%s*%([^,]+,%s*[%w_]*$') then
    return { type = 'UE_LOG' }
  end
  local macro_capture = before_cursor:match('([%w_]+)%s*%([^%)]*$')
  if macro_capture then
    if macro_capture == 'UPROPERTY' and config.enable_uproperty then
      if before_cursor:match('meta%s*=%s*%([^%)]*$') then return { type = 'UPROPERTY', sub = 'META' } end
      return { type = 'UPROPERTY' }
    elseif macro_capture == 'UFUNCTION' and config.enable_ufunction then
      if before_cursor:match('meta%s*=%s*%([^%)]*$') then return { type = 'UFUNCTION', sub = 'META' } end
      return { type = 'UFUNCTION' }
    elseif macro_capture == 'UCLASS' and config.enable_uclass then return { type = 'UCLASS' }
    elseif (macro_capture == 'USTRUCT' and config.enable_ustruct) then return { type = 'USTRUCT' }
    elseif (macro_capture == 'UINTERFACE' and config.enable_uinterface) then return { type = 'UINTERFACE' }
    elseif (macro_capture == 'UENUM' and config.enable_uenum) then return { type = 'UENUM' }
    end
  end
  if config.enable_slate_macros and before_cursor:match('^%s*SLATE_[%w_]*$') then
    return { type = 'SLATE_GLOBAL' }
  end
  if config.enable_delegate_macros and before_cursor:match('^%s*DECLARE_[%w_]*$') then
    return { type = 'DELEGATE_GLOBAL' }
  end
  return nil
end

-- 再帰的に変数の型を解決する関数
local function resolve_type_recursive(bufnr, cursor_row, var_name, callback)
    if not ts_parser_ok then callback(nil, false); return end
    
    -- Tree-sitterで定義を探す
    local type_name, is_pointer, rhs_text = ts_parser.get_var_type(bufnr, var_name, cursor_row)
    
    -- 1. 明示的な型、または単純な RHS で解決できた場合
    if type_name then
        callback(type_name, is_pointer)
        return
    end
    
    -- 2. auto かつ RHS が関数呼び出し (Obj->Func) の場合
    if rhs_text then
        local obj_name, func_name = rhs_text:match("([%w_]+)[%-%.>]+([%w_]+)")
        if obj_name and func_name then
            -- 再帰的に Obj の型を解決する
            resolve_type_recursive(bufnr, cursor_row, obj_name, function(obj_type, obj_is_ptr)
                if obj_type then
                    -- Obj の型が分かったので、Func の戻り値を問い合わせる
                    unl_api.db.get_class_members(obj_type, function(members)
                        if members then
                            for _, m in ipairs(members) do
                                if m.name == func_name then
                                    if m.return_type and m.return_type ~= "" then
                                        -- 型名抽出の強化: _API マクロをスキップして実際の型名を探す
                                        local ret_type = nil
                                        for word in m.return_type:gmatch("[%w_]+") do
                                            if not word:match("_API$") and word:match("^[AUFET]") then
                                                local is_likely_template_param = (#word == 1) or (word == "ElementType") or (word == "KeyType") or (word == "ValueType")
                                                if not is_likely_template_param then
                                                    ret_type = word
                                                    break
                                                end
                                            end
                                        end
                                        -- フォールバック: 従来の大文字開始マッチ
                                        ret_type = ret_type or m.return_type:match("([A-Z]%w+)")
                                        
                                        if ret_type then
                                            local ret_is_ptr = m.return_type:find("*") ~= nil
                                            if not ret_is_ptr and m.return_type:find("Ptr") then ret_is_ptr = true end
                                            callback(ret_type, ret_is_ptr)
                                            return
                                        end
                                    end
                                end
                            end
                        end
                        callback(nil, false) -- 関数が見つからない、または戻り値なし
                    end)
                else
                    callback(nil, false) -- Objの型不明
                end
            end)
            return
        end
    end
    
    callback(nil, false)
end
--------------------------------------------------------------------------------
-- 5. blink.cmp Source Interface Implementation
--------------------------------------------------------------------------------

function M.new(opts)
  local self = setmetatable({}, { __index = M })
  self.config = vim.tbl_deep_extend('force', default_config, opts or {})
  if not delegate_cache then
    delegate_cache = generate_delegate_snippets()
  end
  return self
end

function M:get_trigger_characters()
  return { '(', ',', ' ', '=', '_', '.', '>', ':' }
end

function M:get_completions(ctx, callback)
  local line_text = ctx.line
  local col = ctx.cursor[2]
  local bufnr = ctx.bufnr
  local cursor_row = ctx.cursor[1]
  
  -- --------------------------------------------------------
  -- A. UEP Member Completion (Async)
  -- --------------------------------------------------------
  if unl_api_ok and self.config.enable_uep_member_completion then
      local before_cursor = line_text:sub(1, col)
      local var_name_ptr = before_cursor:match("([%w_]+)%->[%w_]*$")
      local var_name_dot = before_cursor:match("([%w_]+)%.[%w_]*$")
      local type_name_scoped = before_cursor:match("([%w_:]+)::[%w_]*$")
      
      -- [New] Function Call: GetComp()-> or GetComp<T>()->
      local func_call_name, template_type
      local fn_tpl, tp_tpl = before_cursor:match("([%w_]+)%s*<([%w_]+)>%s*%b()%s*%-+[%>%.]+[%w_]*$")
      if fn_tpl then
          func_call_name = fn_tpl
          template_type = tp_tpl
      else
          func_call_name = before_cursor:match("([%w_]+)%s*%b()%s*%-+[%>%.]+[%w_]*$")
      end
      
      local var_name = var_name_ptr or var_name_dot
      
      local is_static_context = (type_name_scoped ~= nil)
      local is_instance_context = (var_name ~= nil) or (func_call_name ~= nil)

      if var_name or type_name_scoped or func_call_name then
          local current_ns = ts_parser.get_current_namespace(bufnr, cursor_row)
          
          -- 結果を表示する共通関数
          local function fetch_members(class_name, cb)
              -- print("DEBUG: fetch_members for " .. tostring(class_name))
              unl_api.db.get_class_members_recursive(class_name, current_ns, function(members)
                  if members and #members > 0 then
                      local items = {}
                      local kinds = require('blink.cmp.types').CompletionItemKind
                      for _, m in ipairs(members) do
                          local is_this_access = (var_name == "this")
                          if m.access == 'private' and not is_this_access then goto continue end

                          local is_static_member = (m.is_static == 1) or (m.type == 'enum_item')
                          
                          if is_static_context then
                              if not is_static_member then goto continue end
                          elseif is_instance_context then
                              if is_static_member then goto continue end
                          end

                          local kind = kinds.Field
                          if m.type == "function" then kind = kinds.Method
                          elseif m.type == "property" then kind = kinds.Property
                          elseif m.type == "enum_item" then kind = kinds.EnumMember end
                          
                          local item_detail = m.detail or ""
                          if m.flags and m.flags ~= "" then 
                              item_detail = item_detail .. " [" .. m.flags .. "]" 
                          end
                          
                          table.insert(items, {
                              label = m.name,
                              kind = kind,
                              detail = item_detail,
                              insertText = m.name,
                              filterText = m.name,
                              documentation = {
                                  kind = 'markdown',
                                  value = string.format("**%s**\nType: %s\nSignature: %s\nDefined in: %s", m.name, m.type, m.detail or "N/A", m.class_name or class_name)
                              }
                          })
                          ::continue::
                      end
                      cb({ is_incomplete_forward = false, is_incomplete_backward = false, items = items })
                  else
                      cb()
                  end
              end)
          end

          -- Type Resolution Logic
          if type_name_scoped then
              -- Static access (ClassName::) -> No resolution needed, use class name directly
              fetch_members(type_name_scoped, function(res)
                  if res and #res.items > 0 then
                      callback(res)
                  else
                      -- [New] Fallback for UE-style namespaced enums (ELoadingPhase:: -> ELoadingPhase::Type::)
                      fetch_members(type_name_scoped .. "::Type", callback)
                  end
              end)
              return
          elseif func_call_name then
              -- print("DEBUG: Resolving func_call_name: " .. func_call_name)
              if template_type then
                  fetch_members(template_type, callback)
                  return
              end

              local current_class = ts_parser.get_current_class_name(bufnr, cursor_row)
              if not current_class then callback(); return end

              -- 再帰的にメンバを探す関数 (継承対応)
              local function find_function_return_type(class_name, target_fn, cb)
                  unl_api.db.get_class_members_recursive(class_name, nil, function(members)
                      if members then
                          for _, m in ipairs(members) do
                              local m_name = m.name:gsub("%s+", "")
                              if m_name == target_fn and m.type == "function" then
                                  if m.return_type and m.return_type ~= "" then
                                      local ret_class = nil
                                      local skip_words = { 
                                          FORCEINLINE=1, inline=1, virtual=1, const=1, static=1, 
                                          class=1, struct=1, typename=1, enum=1, 
                                          ENGINE_API=1, CORE_API=1
                                      }
                                      for word in m.return_type:gmatch("[%w_]+") do
                                          if not skip_words[word] and not word:match("_API$") then
                                              if word:match("^[AUFET]") then
                                                  local is_tpl = (#word == 1) or (word == "ElementType") or (word == "KeyType") or (word == "ValueType")
                                                  if not is_tpl then
                                                      ret_class = word
                                                      break
                                                  end
                                              end
                                          end
                                      end
                                      if ret_class then cb(ret_class); return end
                                  end
                              end
                          end
                      end
                      cb(nil)
                  end)
              end

              find_function_return_type(current_class, func_call_name, function(ret_type)
                  if ret_type then
                      fetch_members(ret_type, callback)
                  else
                      callback()
                  end
              end)
              return
          elseif var_name then
              -- Instance access (Var-> or Var.) -> Need to resolve variable type
              resolve_type_recursive(bufnr, cursor_row, var_name, function(type_name, is_pointer)
                  if type_name then
                      -- Strict Operator Check
                      local op = var_name_ptr and "->" or "."
                      if op == "->" and not is_pointer then
                           -- Warn or skip? For now, allow it but log?
                           -- print("[blink] Warning: Used -> on non-pointer type " .. type_name)
                      elseif op == "." and is_pointer then
                           -- print("[blink] Warning: Used . on pointer type " .. type_name)
                      end
                      
                      fetch_members(type_name, callback)
                  else
                      callback() -- Failed to resolve type
                  end
              end)
              return
          end
      end
  end

  -- --------------------------------------------------------
  -- B. Static Completions (Sync)
  -- --------------------------------------------------------
  local context = get_context(line_text, col, self.config)
  if not context then
    -- [New] Global Type Completion (Async)
    if unl_api_ok then
      local before_cursor = line_text:sub(1, col)
      local prefix = before_cursor:match("([%w_]+)$")
      if prefix and #prefix >= 2 then
        unl_api.db.search_classes_prefix(prefix, 20, function(results)
          if results then
            local items = {}
            local kinds = require('blink.cmp.types').CompletionItemKind
            for _, res in ipairs(results) do
              local kind = kinds.Class
              if res.symbol_type == 'struct' or res.symbol_type == 'USTRUCT' then
                kind = kinds.Struct
              elseif res.symbol_type == 'enum' or res.symbol_type == 'UENUM' then
                kind = kinds.Enum
              elseif res.symbol_type == 'interface' or res.symbol_type == 'UINTERFACE' then
                kind = kinds.Interface
              end
              
              table.insert(items, {
                label = res.name,
                kind = kind,
                insertText = res.name,
                documentation = {
                  kind = 'markdown',
                  value = string.format("**%s** (%s)", res.name, res.symbol_type)
                }
              })
            end
            callback({ is_incomplete_forward = false, is_incomplete_backward = false, items = items })
          else
            callback()
          end
        end)
        return
      end
    end

    callback()
    return
  end

  local items = {}
  local kind_kw = require('blink.cmp.types').CompletionItemKind.Keyword
  local kind_snip = require('blink.cmp.types').CompletionItemKind.Snippet
  local kind_enum = require('blink.cmp.types').CompletionItemKind.EnumMember

  local function add_items(source_table, item_kind)
    for _, item in ipairs(source_table) do
      table.insert(items, {
        label = item.label,
        kind = item_kind or kind_kw,
        documentation = item.documentation,
        insertText = item.insertText or item.label,
        insertTextFormat = item.insertTextFormat or (item.insertText and 2 or 1),
        sortText = item.sortText,
      })
    end
  end

  if context.type == 'UE_LOG' then add_items(DB_STATIC.LOG_LEVEL, kind_enum)
  elseif context.sub == 'META' then add_items(DB_STATIC.META, kind_kw)
  elseif context.type == 'UPROPERTY' then add_items(DB_STATIC.UPROPERTY, kind_kw)
  elseif context.type == 'UFUNCTION' then add_items(DB_STATIC.UFUNCTION, kind_kw)
  elseif context.type == 'UCLASS' or context.type == 'USTRUCT' then add_items(DB_STATIC.UCLASS, kind_kw)
  elseif context.type == 'UENUM' then add_items(DB_STATIC.UENUM, kind_kw)
  elseif context.type == 'UINTERFACE' then add_items(DB_STATIC.UINTERFACE, kind_kw)
  elseif context.type == 'DELEGATE_GLOBAL' then add_items(delegate_cache, kind_snip)
  elseif context.type == 'SLATE_GLOBAL' then add_items(DB_STATIC.SLATE, kind_snip)
  end

  callback({
    is_incomplete_forward = false,
    is_incomplete_backward = false,
    items = items,
  })
end

return M
