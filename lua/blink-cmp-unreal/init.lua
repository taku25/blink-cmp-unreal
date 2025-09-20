local ue_provider = {}
ue_provider.__index = ue_provider

-- すべての機能フラグを含む、完全なconfig
local config = {
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

function ue_provider.setup(opts)
  config = vim.tbl_deep_extend('force', config, opts or {})
end

function ue_provider.new(opts)
  ue_provider.setup(opts)
  return setmetatable({}, ue_provider)
end

--------------------------------------------------------------------------------
-- データベース (すべてを統合・定義省略なし)
--------------------------------------------------------------------------------

-- UCLASS/UPROPERTY/UFUNCTIONなどの基本指定子
local uclass_specifiers = {
  { label = 'Abstract', documentation = 'Declares this class as an "abstract base class", which prevents users from adding Actors of this class to Levels.' },
  { label = 'abstract', documentation = 'Declares this class as an "abstract base class", which prevents users from adding Actors of this class to Levels.' },
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
}
local uinterface_specifiers = {
  { label = 'Blueprintable', documentation = 'Exposes this interface as one that can be implemented by Blueprints.' },
  { label = 'BlueprintType', documentation = 'Exposes this interface as a type that can be used for variables in Blueprints.' },
  { label = 'MinimalAPI', documentation = 'Causes only the interface\'s type information to be exported, improving compile times.' },
}

-- Meta Specifiers for UPROPERTY
local uproperty_meta_specifiers = {
  { label = 'DisplayName = ""', documentation = 'The name to display for this property in the editor.' },
  { label = 'ToolTip = ""', documentation = 'A tooltip to display for this property in the editor.' },
  { label = 'ClampMin = ""', documentation = 'Specifies the minimum value that may be entered for a numeric property.' },
  { label = 'ClampMax = ""', documentation = 'Specifies the maximum value that may be entered for a numeric property.' },
  { label = 'UIMin = ""', documentation = 'Specifies the minimum value for the UI slider for a numeric property.' },
  { label = 'UIMax = ""', documentation = 'Specifies the maximum value for the UI slider for a numeric property.' },
  { label = 'EditCondition = ""', documentation = 'Names a boolean property that is used to enable/disable editing of this property.' },
  { label = 'AllowPrivateAccess = "true"', documentation = 'Allows a private property to be accessed from Blueprints.' },
  { label = 'Bitmask', documentation = 'Marks an integer property as a bitmask, showing a dropdown of flags.' },
  { label = 'BitmaskEnum = ""', documentation = 'Used with Bitmask to specify a UENUM to use for the flag names.' },
}

-- Meta Specifiers for UFUNCTION
local ufunction_meta_specifiers = {
  { label = 'DisplayName = ""', documentation = 'The name to display for this function node in Blueprints.' },
  { label = 'Keywords = ""', documentation = 'A set of keywords that can be used to find this node in the Blueprint editor.' },
  { label = 'AdvancedDisplay = ""', documentation = 'Hides the specified pins in the node by default, under an "Advanced" dropdown.' },
  { label = 'DefaultToSelf = ""', documentation = 'If an object pin is not connected, it will default to the "self" context of the node.' },
  { label = 'WorldContext = ""', documentation = 'Specifies which parameter provides the World context for the function.' },
  { label = 'AutoCreateRefTerm = ""', documentation = 'For reference parameters, an automatically created default will be used if their pins are left disconnected.' },
  { label = 'DeprecatedFunction = "true"', documentation = 'Marks this function as deprecated, causing a compile warning in Blueprints.' },
  { label = 'DeprecationMessage = ""', documentation = 'A custom message to display for a deprecated function.' },
}

-- Delegate Declaration Macros
local delegate_macros = {
  { label = 'DECLARE_DELEGATE', documentation = 'Declares a single-cast delegate.' },
  { label = 'DECLARE_MULTICAST_DELEGATE', documentation = 'Declares a multi-cast delegate.' },
  { label = 'DECLARE_DYNAMIC_DELEGATE', documentation = 'Declares a dynamic, serializable single-cast delegate.' },
  { label = 'DECLARE_DYNAMIC_MULTICAST_DELEGATE', documentation = 'Declares a dynamic, serializable multi-cast delegate, assignable in Blueprints.' },
}

-- UE_LOG Verbosity Levels
local log_verbosity_levels = {
  { label = 'Fatal', documentation = 'Always prints a fatal error and crashes.' },
  { label = 'Error', documentation = 'Prints an error message (red).' },
  { label = 'Warning', documentation = 'Prints a warning message (yellow).' },
  { label = 'Display', documentation = 'Prints a message to the console and log file.' },
  { label = 'Log', documentation = 'Prints a message to the log file only.' },
  { label = 'Verbose', documentation = 'Prints a detailed message if verbose logging is enabled.' },
  { label = 'VeryVerbose', documentation = 'Prints an extremely detailed message if very verbose logging is enabled.' },
}

-- Slate Argument Macros
local slate_argument_macros = {
  { label = 'SLATE_ARGUMENT', documentation = 'Defines a widget argument that takes a value once at construction.' },
  { label = 'SLATE_ATTRIBUTE', documentation = 'Defines a widget argument that can be a value or a delegate for polling.' },
  { label = 'SLATE_EVENT', documentation = 'Defines a widget argument for event callbacks (e.g., OnClicked).' },
}

-- Module Implementation Macros
local module_macros = {
  { label = 'IMPLEMENT_MODULE', documentation = 'Implements a standard engine module.' },
  { label = 'IMPLEMENT_PRIMARY_GAME_MODULE', documentation = 'Implements the primary game module for a project.' },
}


--------------------------------------------------------------------------------
-- ヘルパー関数 (最終完成版)
--------------------------------------------------------------------------------
local function get_macro_context(line)
  if not line then return nil end

  -- metaの状況をチェック
  if config.enable_meta_specifiers then
    if line:match('UPROPERTY%s*%(.*meta%s*=%s*%(([^)]*)$') then return { primary = 'UPROPERTY', secondary = 'META' } end
    if line:match('UFUNCTION%s*%(.*meta%s*=%s*%(([^)]*)$') then return { primary = 'UFUNCTION', secondary = 'META' } end
  end
  
  -- UE_LOGの状況をチェック
  if config.enable_log_levels then
    if line:match('UE_LOG%s*%((%s*[^,]+%s*),([^,)]*)$') then return { primary = 'UE_LOG', secondary = 'VERBOSITY' } end
  end

  -- Slateの状況をチェック (安全なバージョン)
  if config.enable_slate_macros then
    if line:match('^%s*SLATE_') then 
      return { primary = 'SLATE_ARGS' }
    end
  end

  -- 標準指定子のチェック
  if line:match('UCLASS%s*%(([^)]*)$') and config.enable_uclass then return { primary = 'UCLASS' } end
  if line:match('UPROPERTY%s*%(([^)]*)$') and config.enable_uproperty then return { primary = 'UPROPERTY' } end
  if line:match('UFUNCTION%s*%(([^)]*)$') and config.enable_ufunction then return { primary = 'UFUNCTION' } end
  if line:match('USTRUCT%s*%(([^)]*)$') and config.enable_ustruct then return { primary = 'USTRUCT' } end
  if line:match('UENUM%s*%(([^)]*)$') and config.enable_uenum then return { primary = 'UENUM' } end
  if line:match('UINTERFACE%s*%(([^)]*)$') and config.enable_uinterface then return { primary = 'UINTERFACE' } end

  -- グローバルと判断
  return { primary = 'GLOBAL' }
end

--------------------------------------------------------------------------------
-- blink.cmp ネイティブプロバイダ APIの実装 (最終完成版)
--------------------------------------------------------------------------------
function ue_provider:get_trigger_characters()
  return { '(', ',', ' ', '=' }
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

  local macro_context = get_macro_context(line_before_cursor)

  if not macro_context then
    callback({ items = {} })
    return
  end

  local specifiers_db
  if macro_context.primary == 'UPROPERTY' and macro_context.secondary == 'META' then specifiers_db = uproperty_meta_specifiers
  elseif macro_context.primary == 'UFUNCTION' and macro_context.secondary == 'META' then specifiers_db = ufunction_meta_specifiers
  elseif macro_context.primary == 'UE_LOG' and macro_context.secondary == 'VERBOSITY' then specifiers_db = log_verbosity_levels
  elseif macro_context.primary == 'SLATE_ARGS' then specifiers_db = slate_argument_macros
  elseif macro_context.primary == 'UCLASS' then specifiers_db = uclass_specifiers
  elseif macro_context.primary == 'UPROPERTY' then specifiers_db = uproperty_specifiers
  elseif macro_context.primary == 'UFUNCTION' then specifiers_db = ufunction_specifiers
  elseif macro_context.primary == 'USTRUCT' then specifiers_db = ustruct_specifiers
  elseif macro_context.primary == 'UENUM' then specifiers_db = uenum_specifiers
  elseif macro_context.primary == 'UINTERFACE' then specifiers_db = uinterface_specifiers
  elseif macro_context.primary == 'GLOBAL' then
    specifiers_db = {}
    if config.enable_delegate_macros then
      for _, item in ipairs(delegate_macros) do table.insert(specifiers_db, item) end
    end
    if config.enable_module_macros then
      for _, item in ipairs(module_macros) do table.insert(specifiers_db, item) end
    end
  else
    callback({ items = {} })
    return
  end

  local items = {}
  for _, spec in ipairs(specifiers_db) do
    table.insert(items, {
      label = spec.label,
      kind = completion_item_kind.Keyword,
      documentation = spec.documentation,
    })
  end

  callback({
    is_incomplete_backward = false,
    is_incomplete_forward = false,
    items = items,
  })
end

return ue_provider
