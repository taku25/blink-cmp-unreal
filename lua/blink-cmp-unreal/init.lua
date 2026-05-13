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
  return { '(', ',', '.', '>', ':' }
end

function M:get_completions(ctx, callback)
  if not unl_api_ok then return callback() end

  local bufnr = ctx.bufnr
  local cursor = ctx.cursor -- [row, col] (1-based)

  -- Send only a window of lines around the cursor to reduce Tree-sitter parse time.
  -- Variables declared more than WINDOW_BEFORE lines above the cursor are rare enough
  -- that the DB-based fallback handles them.  The enclosing class name is also found
  -- within the class body, which is almost always within this window.
  local WINDOW_BEFORE = 300
  local WINDOW_AFTER  = 60
  local all_lines   = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local total_lines = #all_lines

  local win_start  = math.max(1, cursor[1] - WINDOW_BEFORE)   -- 1-based, inclusive
  local win_end    = math.min(total_lines, cursor[1] + WINDOW_AFTER) -- 1-based, inclusive
  local win_lines  = vim.list_slice(all_lines, win_start, win_end)
  local content    = table.concat(win_lines, "\n")

  -- cursor[1] is 1-based; server expects 0-based line relative to the sent content.
  local adjusted_line = cursor[1] - win_start  -- 0-based inside the window

  local file_path = vim.api.nvim_buf_get_name(bufnr)
  
  unl_api.db.get_completions({
    content = content,
    line = adjusted_line,
    character = cursor[2], -- 0-based (カーソル位置は文字の直後)
    file_path = file_path,
    absolute_line = cursor[1] - 1, -- 0-based absolute line in file
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