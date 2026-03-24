local M = {}

local unl_api_ok, unl_api = pcall(require, "UNL.api")

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
-- 2. blink.cmp Source Interface Implementation
--------------------------------------------------------------------------------

function M.new(opts)
  local self = setmetatable({}, { __index = M })
  self.config = vim.tbl_deep_extend('force', default_config, opts or {})
  return self
end

function M:get_trigger_characters()
  return { '(', ',', ' ', '=', '_', '.', '>', ':' }
end

function M:get_completions(ctx, callback)
  if not unl_api_ok then return callback() end

  local bufnr = ctx.bufnr
  local cursor = ctx.cursor -- [row, col] (1-based)
  
  -- バッファ内容を取得 (パフォーマンスのために必要な範囲だけ送る最適化も検討可能だが、一旦全体)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local content = table.concat(lines, "\n")
  local file_path = vim.api.nvim_buf_get_name(bufnr)
  
  unl_api.db.get_completions({
    content = content,
    line = cursor[1] - 1, -- 0-based for server
    character = cursor[2], -- 0-based (カーソル位置は文字の直後)
    file_path = file_path
  }, function(result, err)
      if err or not result then
          return callback()
      end
      
      -- サーバーからの結果 (JSON Array) を blink.cmp の形式に変換
      local items = {}
      local kinds = require('blink.cmp.types').CompletionItemKind
      
      for _, item in ipairs(result) do
          local kind = kinds.Text
          local raw_kind = tonumber(item.kind) or 1
          
          if raw_kind == 2 then kind = kinds.Method
          elseif raw_kind == 5 then kind = kinds.Field
          elseif raw_kind == 7 then kind = kinds.Class
          elseif raw_kind == 12 then kind = kinds.Keyword -- Specifiers
          elseif raw_kind == 13 then kind = kinds.Enum
          elseif raw_kind == 15 then kind = kinds.Snippet -- Macros
          elseif raw_kind == 20 then kind = kinds.EnumMember
          end
          
          table.insert(items, {
              label = item.label,
              kind = kind,
              detail = item.detail,
              documentation = (item.documentation and item.documentation ~= "") and {
                  kind = 'markdown',
                  value = item.documentation
              } or nil,
              insertText = item.insertText or item.label,
              sortText = item.sortText,
              filterText = item.filterText or item.label,
              insertTextFormat = (item.insertText and item.insertText:find("$")) and 2 or 1, -- Snippet support
          })
      end
      
      callback({
        is_incomplete_forward = false,
        is_incomplete_backward = false,
        items = items,
      })
  end)
end

return M