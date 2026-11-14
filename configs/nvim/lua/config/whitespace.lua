-- VS Code habit: show trailing whitespace and remove it when the file is saved. Markdown keeps it
-- (two trailing spaces are a hard line break) and so do diffs.
local M = {}

local KEEP = { markdown = true, diff = true, gitcommit = true }

function M.trim(buf)
  if KEEP[vim.bo[buf].filetype] or not vim.bo[buf].modifiable then
    return
  end
  vim.api.nvim_buf_call(buf, function()
    local view = vim.fn.winsaveview()
    vim.cmd([[keeppatterns silent! %s/\s\+$//e]])
    vim.fn.winrestview(view)
  end)
end

function M.setup()
  vim.opt.list = true
  vim.opt.listchars = { tab = "→ ", space = "·", trail = "·", nbsp = "␣" }
  vim.api.nvim_create_autocmd("BufWritePre", {
    group = vim.api.nvim_create_augroup("noir_trim_whitespace", { clear = true }),
    callback = function(args)
      M.trim(args.buf)
    end,
  })
end

return M
