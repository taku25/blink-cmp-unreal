local ue_provider = {}
ue_provider.__index = ue_provider

local config = {
  enable_uclass = true,
  enable_uproperty = true,
  enable_ufunction = true,
  enable_ustruct = true,
  enable_uenum = true,
  enable_uinterface = true,
}

function ue_provider.setup(opts)
  config = vim.tbl_deep_extend('force', config, opts or {})
end

function ue_provider.new(opts)
  ue_provider.setup(opts)
  return setmetatable({}, ue_provider)
end

--------------------------------------------------------------------------------
-- データベース
--------------------------------------------------------------------------------
local uclass_specifiers = {
  { label = 'Abstract', documentation = 'Declares this class as an "abstract base class", which prevents users from adding Actors of this class to Levels.' },
  { label = 'Blueprintable', documentation = 'Exposes this class as an acceptable base class for creating Blueprints.' },
  { label = 'BlueprintType', documentation = 'Exposes this class as a type that can be used for variables in Blueprints.' },
  { label = 'Config', documentation = 'Indicates that the class can store data in a configuration file (.ini). Example: Config=Game' },
  { label = 'DefaultToInstanced', documentation = 'All instances of this class are considered "instanced" and are duplicated upon construction.' },
  { label = 'Deprecated', documentation = 'This class is deprecated, and Objects of this class will not be saved during serialization.' },
  { label = 'EditInlineNew', documentation = 'Indicates that Objects of this class can be created from the Unreal Editor Property window.' },
  { label = 'HideCategories', documentation = 'Lists one or more categories that should be hidden from the user entirely.' },
  { label = 'MinimalAPI', documentation = 'Causes only the class\'s type information to be exported for use by other modules, improving compile times.' },
  { label = 'NotBlueprintable', documentation = 'Specifies that this class is not an acceptable base class for creating Blueprints.' },
  { label = 'Placeable', documentation = 'Indicates that this class can be created in the Editor and placed into a level, UI scene, or Blueprint.' },
  { label = 'Transient', documentation = 'Objects belonging to this class will never be saved to disk.' },
  { label = 'Within', documentation = 'Objects of this class cannot exist outside of an instance of an OuterClassName Object.' },
}
local uproperty_specifiers = {
  { label = 'EditAnywhere', documentation = 'This property can be edited by property windows, on archetypes and instances.' },
  { label = 'EditDefaultsOnly', documentation = 'This property can be edited by property windows, but only on archetypes.' },
  { label = 'EditInstanceOnly', documentation = 'This property can be edited by property windows, but only on instances, not on archetypes.' },
  { label = 'VisibleAnywhere', documentation = 'This property is visible in all property windows, but cannot be edited.' },
  { label = 'VisibleDefaultsOnly', documentation = 'This property is only visible in property windows for archetypes, and cannot be edited.' },
  { label = 'VisibleInstanceOnly', documentation = 'This property is only visible in property windows for instances, not for archetypes, and cannot be edited.' },
  { label = 'BlueprintReadOnly', documentation = 'This property can be read by Blueprints, but not modified.' },
  { label = 'BlueprintReadWrite', documentation = 'This property can be read or written from a Blueprint.' },
  { label = 'Category', documentation = 'Specifies the category of the property when displayed in Blueprint editing tools.' },
  { label = 'Config', documentation = 'This property will be configurable. The current value can be saved to the.ini file.' },
  { label = 'Replicated', documentation = 'The property should be replicated over the network.' },
  { label = 'ReplicatedUsing', documentation = 'Specifies a callback function which is executed when the property is updated over the network.' },
  { label = 'SaveGame', documentation = 'This specifier is a simple way to include fields explicitly for a checkpoint/save system.' },
  { label = 'Transient', documentation = 'Property is transient, meaning it will not be saved or loaded.' },
  { label = 'Instanced', documentation = 'UObject properties only. When an instance of this class is created, it will be given a unique copy of the Object.' },
  { label = 'meta = (AllowPrivateAccess = "true")', documentation = 'Allows a private property to be accessed from Blueprints.' },
}
local ufunction_specifiers = {
  { label = 'BlueprintCallable', documentation = 'This function can be executed in a Blueprint or Level Blueprint graph.' },
  { label = 'BlueprintPure', documentation = 'The function does not affect the owning object in any way (no execution pins).' },
  { label = 'BlueprintImplementableEvent', documentation = 'This function can be overridden in a Blueprint or Level Blueprint.' },
  { label = 'BlueprintNativeEvent', documentation = 'This function is designed to be overridden by a Blueprint, but also has a native C++ implementation.' },
  { label = 'Category', documentation = 'Specifies the category of the function when displayed in Blueprint editing tools.' },
  { label = 'Exec', documentation = 'The function can be executed from the in-game console.' },
  { label = 'Server', documentation = 'This function is only executed on the server (RPC).' },
  { label = 'Client', documentation = 'This function is only executed on the client that owns the Object (RPC).' },
  { label = 'NetMulticast', documentation = 'This function is executed locally on the server and replicated to all clients (RPC).' },
  { label = 'Reliable', documentation = 'The RPC is guaranteed to arrive regardless of bandwidth or network errors.' },
  { label = 'Unreliable', documentation = 'The RPC can fail due to bandwidth limitations or network errors.' },
  { label = 'WithValidation', documentation = 'Declares an additional _Validate function that is called before the RPC is executed.' },
  { label = 'CallInEditor', documentation = 'Adds a button to the Details panel in the editor to call this function on selected instances.' },
}
local ustruct_specifiers = {
  { label = 'BlueprintType', documentation = 'Exposes this struct as a type that can be used for variables in Blueprints.' },
  { label = 'Atomic', documentation = 'Indicates that this struct should always be serialized as a single unit.' },
  { label = 'NoExport', documentation = 'No autogenerated code will be created for this struct; the header is only provided for parsing metadata.' },
}
local uenum_specifiers = {
  { label = 'BlueprintType', documentation = 'Exposes this enum as a type that can be used for variables in Blueprints.' },
  { label = 'meta = (Bitflags)', documentation = 'Treats this enum as a bitmask, allowing multiple values to be selected in the editor.' },
}
local uinterface_specifiers = {
  { label = 'Blueprintable', documentation = 'Exposes this interface as one that can be implemented by Blueprints.' },
  { label = 'BlueprintType', documentation = 'Exposes this interface as a type that can be used for variables in Blueprints.' },
  { label = 'MinimalAPI', documentation = 'Causes only the interface\'s type information to be exported for use by other modules, improving compile times.' },
}

--------------------------------------------------------------------------------
-- ヘルパー関数
--------------------------------------------------------------------------------
local function get_macro_context(line)
  if not line then return nil end
  if line:match('UCLASS%s*%(([^)]*)$') and config.enable_uclass then return 'UCLASS' end
  if line:match('UPROPERTY%s*%(([^)]*)$') and config.enable_uproperty then return 'UPROPERTY' end
  if line:match('UFUNCTION%s*%(([^)]*)$') and config.enable_ufunction then return 'UFUNCTION' end
  if line:match('USTRUCT%s*%(([^)]*)$') and config.enable_ustruct then return 'USTRUCT' end
  if line:match('UENUM%s*%(([^)]*)$') and config.enable_uenum then return 'UENUM' end
  if line:match('UINTERFACE%s*%(([^)]*)$') and config.enable_uinterface then return 'UINTERFACE' end
  return nil
end

--------------------------------------------------------------------------------
-- blink.cmp ネイティブプロバイダ APIの実装
--------------------------------------------------------------------------------
function ue_provider:get_trigger_characters()
  return { '(', ',', ' ' }
end

function ue_provider:get_keyword_pattern()
  return '\\w\\+'
end

--- @param context blink.cmp.Context
--- @param callback fun(response?: blink.cmp.CompletionResponse)
function ue_provider:get_completions(context, callback)
  local completion_item_kind = require('blink.cmp.types').CompletionItemKind
  local cursor = context.cursor
  local bufnr = context.bufnr or 0

  local lines = vim.api.nvim_buf_get_lines(bufnr, cursor[1] - 1, cursor[1], false)
  if not lines[1] then
    callback({ items = {} })
    return
  end
  local current_line_text = lines[1]
  local line_before_cursor = string.sub(current_line_text, 1, cursor[2])

  local macro_type = get_macro_context(line_before_cursor)

  if not macro_type then
    callback({ items = {} })
    return
  end

  local specifiers_db
  if macro_type == 'UCLASS' then specifiers_db = uclass_specifiers
  elseif macro_type == 'UPROPERTY' then specifiers_db = uproperty_specifiers
  elseif macro_type == 'UFUNCTION' then specifiers_db = ufunction_specifiers
  elseif macro_type == 'USTRUCT' then specifiers_db = ustruct_specifiers
  elseif macro_type == 'UENUM' then specifiers_db = uenum_specifiers
  elseif macro_type == 'UINTERFACE' then specifiers_db = uinterface_specifiers
  else
    callback({ items = {} })
    return
  end

  -- ▼▼▼ これが最終形です ▼▼▼
  -- textEdit を完全に削除し、最も基本的な情報だけを提供します。
  -- これにより、blink.cmpが最も安定したデフォルトの置換処理を行います。
  local items = {}
  for _, spec in ipairs(specifiers_db) do
    table.insert(items, {
      label = spec.label,
      kind = completion_item_kind.Keyword,
      documentation = spec.documentation,
    })
  end
  -- ▲▲▲ ここまで ▲▲▲

  callback({
    is_incomplete_backward = false,
    is_incomplete_forward = false,
    items = items,
  })
end

return ue_provider
