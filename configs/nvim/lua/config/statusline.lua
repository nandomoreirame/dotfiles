-- Statusline helpers: pure formatters (unit tested) plus the components lualine.lua plugs in.
local M = {}

-- `git rev-list --left-right --count @{u}...HEAD` prints "<behind>\t<ahead>".
function M.parse_upstream_counts(text)
  local behind, ahead = (text or ""):match("^(%d+)%s+(%d+)")
  if not behind then
    return nil
  end
  return tonumber(ahead), tonumber(behind)
end

function M.format_ahead_behind(ahead, behind)
  return ("↑%d ↓%d"):format(ahead, behind)
end

function M.format_encoding(encoding, fileformat, expandtab, shiftwidth)
  local eol = ({ unix = "LF", dos = "CRLF", mac = "CR" })[fileformat] or fileformat
  local indent = expandtab and (shiftwidth .. "sp") or "tab"
  return ("%s %s %s"):format(encoding ~= "" and encoding or "utf-8", eol, indent)
end

function M.join_names(names)
  local seen, list = {}, {}
  for _, name in ipairs(names) do
    if not seen[name] then
      seen[name] = true
      list[#list + 1] = name
    end
  end
  return table.concat(list, ", ")
end

function M.encoding()
  local o = vim.bo
  return M.format_encoding(o.fileencoding ~= "" and o.fileencoding or vim.o.encoding, o.fileformat, o.expandtab, o.shiftwidth)
end

function M.lsp()
  local names = {}
  for _, client in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
    names[#names + 1] = client.name
  end
  return M.join_names(names)
end

function M.words()
  if not vim.tbl_contains({ "markdown", "text", "gitcommit" }, vim.bo.filetype) then
    return ""
  end
  local count = vim.fn.wordcount().words
  return count .. (count == 1 and " word" or " words")
end

-- Ahead/behind is read asynchronously, cached per directory and re-read only after an event marks
-- it stale (the statusline redraws far too often to spawn git each time).
local cache = {}
local stale = {}
local pending = {}

local function refresh(cwd)
  if pending[cwd] then
    return
  end
  pending[cwd] = true
  stale[cwd] = nil
  vim.system({ "git", "-C", cwd, "rev-list", "--left-right", "--count", "@{u}...HEAD" }, { text = true }, function(res)
    local ahead, behind
    if res.code == 0 then
      ahead, behind = M.parse_upstream_counts(res.stdout)
    end
    cache[cwd] = ahead and M.format_ahead_behind(ahead, behind) or ""
    pending[cwd] = nil
    vim.schedule(function()
      pcall(vim.cmd, "redrawstatus")
    end)
  end)
end

function M.ahead_behind()
  local cwd = vim.fn.getcwd()
  if cache[cwd] == nil or stale[cwd] then
    refresh(cwd)
  end
  return cache[cwd] or ""
end

function M.setup_refresh()
  vim.api.nvim_create_autocmd({ "FocusGained", "DirChanged", "BufWritePost", "ShellCmdPost", "TermClose" }, {
    group = vim.api.nvim_create_augroup("noir_statusline_git", { clear = true }),
    callback = function()
      stale[vim.fn.getcwd()] = true
    end,
  })
end

return M
