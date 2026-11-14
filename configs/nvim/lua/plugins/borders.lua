-- Gray float borders, amber on the focused float; split dividers are invisible (background only).
--
-- Colors come from the active Terminal Noir variant: gray is FloatBorder's fg,
-- amber is CursorLineNr's fg (dark: #64646B and #F5A623).
-- A float owns its whole border. A split owns only the separators drawn on its
-- own edges (Neovim assigns each separator to one window), so the rightmost and
-- bottom windows show no amber separator. Plugin floats (snacks) already set a
-- window-local `winhighlight`, so the active mapping is merged into it and the
-- previous entry is put back when the window loses focus.

local group = vim.api.nvim_create_augroup("noir_borders", { clear = true })

local function hl(name)
  return vim.api.nvim_get_hl(0, { name = name, link = false })
end

local function define()
  local float_border, cursor_nr = hl("FloatBorder"), hl("CursorLineNr")
  if not (float_border.fg and cursor_nr.fg) then
    return
  end
  -- split dividers are drawn in the editor tone, so the background alone separates the blocks
  local editor_bg = hl("Normal").bg
  vim.api.nvim_set_hl(0, "WinSeparator", { fg = editor_bg, bg = editor_bg })
  vim.api.nvim_set_hl(0, "FloatBorderActive", { fg = cursor_nr.fg, bg = float_border.bg })
  vim.api.nvim_set_hl(0, "WinSeparatorActive", { fg = editor_bg, bg = editor_bg })
end

local function parse(value)
  local entries = {}
  for pair in vim.gsplit(value or "", ",", { plain = true, trimempty = true }) do
    local from, to = pair:match("^([^:]+):(.+)$")
    if from then
      entries[#entries + 1] = { from, to }
    end
  end
  return entries
end

local function format(entries)
  return table.concat(
    vim.tbl_map(function(entry)
      return entry[1] .. ":" .. entry[2]
    end, entries),
    ","
  )
end

local function target(win)
  if vim.api.nvim_win_get_config(win).relative ~= "" then
    return "FloatBorder", "FloatBorderActive"
  end
  return "WinSeparator", "WinSeparatorActive"
end

local function activate(win)
  if not vim.api.nvim_win_is_valid(win) then
    return
  end
  -- the sidebar's divider stays gray: it is the same line whether the explorer or the editor has focus
  if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == "snacks_layout_box" then
    return
  end
  local key, active = target(win)
  local entries, kept = {}, nil
  for _, entry in ipairs(parse(vim.wo[win].winhighlight)) do
    if entry[1] == key and entry[2] == active then
      return -- already active
    elseif entry[1] ~= key then
      entries[#entries + 1] = entry
    else
      kept = entry[2]
    end
  end
  entries[#entries + 1] = { key, active }
  vim.w[win].noir_border_prev = kept
  vim.wo[win].winhighlight = format(entries)
end

local function deactivate(win)
  if not vim.api.nvim_win_is_valid(win) then
    return
  end
  local key, active = target(win)
  local entries = {}
  for _, entry in ipairs(parse(vim.wo[win].winhighlight)) do
    if not (entry[1] == key and entry[2] == active) then
      entries[#entries + 1] = entry
    end
  end
  local kept = vim.w[win].noir_border_prev
  if kept then
    -- a plugin may already have written its own entry back: keep one per key
    entries = vim.tbl_filter(function(entry)
      return entry[1] ~= key
    end, entries)
    entries[#entries + 1] = { key, kept }
  end
  vim.w[win].noir_border_prev = nil
  vim.wo[win].winhighlight = format(entries)
end

vim.api.nvim_create_autocmd("ColorScheme", { group = group, callback = define })
vim.api.nvim_create_autocmd("WinEnter", {
  group = group,
  callback = function()
    local win = vim.api.nvim_get_current_win()
    activate(win)
    -- plugin floats (snacks) set their own winhighlight after WinEnter; reapply once they have
    vim.schedule(function()
      if vim.api.nvim_get_current_win() == win then
        activate(win)
      end
    end)
  end,
})
-- snacks rewrites the focused window's winhighlight when it shows another buffer
-- (BufWinEnter) or resizes (VimResized): put the amber mapping back afterwards
vim.api.nvim_create_autocmd({ "BufWinEnter", "VimResized" }, {
  group = group,
  callback = function()
    vim.schedule(function()
      activate(vim.api.nvim_get_current_win())
    end)
  end,
})
vim.api.nvim_create_autocmd("WinLeave", {
  group = group,
  callback = function()
    deactivate(vim.api.nvim_get_current_win())
  end,
})
define()

-- This file only registers autocmds; lazy.nvim expects a spec table.
return {}
