local M = {}

--------------------------------------------------------------------------------
-- 1. デフォルト設定 (依存回避のためここに定義)
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
    for count = 0, 8 do -- 0〜8パラメータまで生成
      local suffix = SUFFIXES[count]
      if suffix then
        local label = def.prefix .. suffix
        local idx = 1
        local args = {}

        -- 1. 戻り値 (RetVal系)
        if def.type == 'retval' then
          table.insert(args, string.format("${%d:ReturnType}", idx))
          idx = idx + 1
        end

        -- 2. OwningType (Event系)
        if def.type == 'event' then
          table.insert(args, string.format("${%d:OwningType}", idx))
          idx = idx + 1
        end

        -- 3. DelegateName
        table.insert(args, string.format("${%d:FDelegateName}", idx))
        idx = idx + 1

        -- 4. パラメータ群
        for i = 1, count do
          -- 型
          table.insert(args, string.format("${%d:Type%d}", idx, i))
          idx = idx + 1
          
          -- 名前 (Dynamic系は必須、Raw系も利便性のため含める)
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
          insertTextFormat = 2, -- Snippet Format
          sortText = string.format("%s_%02d", def.prefix, count) 
        })
      end
    end
  end
  return items
end

-- キャッシュ用
local delegate_cache = nil

--------------------------------------------------------------------------------
-- 4. コンテキスト解析ロジック
--------------------------------------------------------------------------------

local function get_context(line_text, col, config)
  local before_cursor = line_text:sub(1, col)

  -- 1. UE_LOG の Verbosity
  if config.enable_log_levels and before_cursor:match('UE_LOG%s*%([^,]+,%s*[%w_]*$') then
    return { type = 'UE_LOG' }
  end

  -- 2. マクロの中身
  local macro_capture = before_cursor:match('([%w_]+)%s*%([^%)]*$')
  if macro_capture then
    if macro_capture == 'UPROPERTY' and config.enable_uproperty then
      if before_cursor:match('meta%s*=%s*%([^%)]*$') then return { type = 'UPROPERTY', sub = 'META' } end
      return { type = 'UPROPERTY' }
    elseif macro_capture == 'UFUNCTION' and config.enable_ufunction then
      if before_cursor:match('meta%s*=%s*%([^%)]*$') then return { type = 'UFUNCTION', sub = 'META' } end
      return { type = 'UFUNCTION' }
    elseif macro_capture == 'UCLASS' and config.enable_uclass then return { type = 'UCLASS' }
    elseif (macro_capture == 'USTRUCT' and config.enable_ustruct) then return { type = 'UCLASS' }
    elseif (macro_capture == 'UINTERFACE' and config.enable_uinterface) then return { type = 'UCLASS' }
    elseif (macro_capture == 'UENUM' and config.enable_uenum) then return { type = 'UENUM' }
    end
  end

  -- 3. Slate マクロ (行頭付近)
  if config.enable_slate_macros and before_cursor:match('^%s*SLATE_[%w_]*$') then
    return { type = 'SLATE_GLOBAL' }
  end

  -- 4. グローバル (行頭) - DECLARE_ などをトリガー
  if config.enable_delegate_macros and before_cursor:match('^%s*DECLARE_[%w_]*$') then
    return { type = 'DELEGATE_GLOBAL' }
  end

  return nil
end

--------------------------------------------------------------------------------
-- 5. blink.cmp Source Interface Implementation
--------------------------------------------------------------------------------

function M.new(opts)
  local self = setmetatable({}, { __index = M })
  
  -- ★ 修正ポイント: require せず、ここでマージする
  self.config = vim.tbl_deep_extend('force', default_config, opts or {})
  
  if not delegate_cache then
    delegate_cache = generate_delegate_snippets()
  end
  return self
end

function M:get_trigger_characters()
  return { '(', ',', ' ', '=', '_' }
end

function M:get_completions(ctx, callback)
  local line_text = ctx.line
  local col = ctx.cursor[2]
  
  -- インスタンス変数として保持したconfigを使用
  local context = get_context(line_text, col, self.config)
  
  if not context then
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
  elseif context.type == 'UCLASS' then add_items(DB_STATIC.UCLASS, kind_kw)
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
