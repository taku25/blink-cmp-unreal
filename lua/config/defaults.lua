local M = {}

M.config = {
  -- 各種補完の有効/無効設定
  enable_uclass = true,
  enable_uproperty = true,
  enable_ufunction = true,
  enable_ustruct = true,
  enable_uenum = true,
  enable_uinterface = true,
  enable_meta_specifiers = true,
  
  -- 新機能: デリゲートマクロのスニペット補完
  enable_delegate_macros = true,
  
  enable_module_macros = true,
  enable_log_levels = true,
  enable_slate_macros = true,
}

return M
