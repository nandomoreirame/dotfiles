-- VS Code style tabs: flat tabs split by thin gray borders, the bar in the sidebar tone and the
-- active tab in the editor tone (bold text, no indicator bar).
-- Colors come from the active Terminal Noir variant, so dark and light both follow.
local function hl(name, attr)
  return vim.api.nvim_get_hl(0, { name = name, link = false })[attr]
end

-- every bufferline highlight that sits on a tab gets the tab background
local PARTS = {
  "background", "buffer_visible", "buffer_selected", "numbers", "numbers_visible", "numbers_selected",
  "close_button", "close_button_visible", "close_button_selected", "modified", "modified_visible",
  "modified_selected", "duplicate", "duplicate_visible", "duplicate_selected", "diagnostic",
  "diagnostic_visible", "diagnostic_selected", "hint", "hint_visible", "hint_selected", "hint_diagnostic",
  "hint_diagnostic_visible", "hint_diagnostic_selected", "info", "info_visible", "info_selected",
  "info_diagnostic", "info_diagnostic_visible", "info_diagnostic_selected", "warning", "warning_visible",
  "warning_selected", "warning_diagnostic", "warning_diagnostic_visible", "warning_diagnostic_selected",
  "error", "error_visible", "error_selected", "error_diagnostic", "error_diagnostic_visible",
  "error_diagnostic_selected", "indicator_visible", "indicator_selected", "pick", "pick_visible",
  "pick_selected", "tab", "tab_close",
}

local function highlights()
  local bar = hl("NormalFloat", "bg") or hl("Normal", "bg")
  local editor = hl("Normal", "bg")
  local idle = hl("StatusLine", "bg") or bar
  local text = hl("Normal", "fg")
  local muted = hl("LineNr", "fg") or text
  local amber = hl("CursorLineNr", "fg") or text
  local border = hl("FloatBorder", "fg") or muted

  local out = { fill = { bg = bar } }
  for _, part in ipairs(PARTS) do
    local selected = part:find("selected", 1, true) ~= nil
    local visible = part:find("visible", 1, true) ~= nil
    out[part] = {
      bg = (selected or visible) and editor or idle,
      fg = selected and text or ((visible and hl("StatusLineNC", "fg")) or muted),
      bold = selected,
      italic = false,
    }
  end
  out.modified_selected.fg = amber
  out.modified_visible.fg = amber
  out.modified.fg = amber
  out.tab_selected = { bg = editor, fg = text, bold = true }
  -- thin borders between tabs: gray line on the tab color
  out.separator = { fg = border, bg = idle }
  out.separator_visible = { fg = border, bg = editor }
  out.separator_selected = { fg = border, bg = editor }
  -- the divider column next to the sidebar: editor tone, like the split divider below it
  out.offset_separator = { fg = editor, bg = editor }
  return out
end

return {
  {
    "akinsho/bufferline.nvim",
    opts = {
      options = {
        separator_style = "thin",
        indicator = { style = "none" },
        always_show_bufferline = true, -- LazyVim hides the bar with one buffer, which also hides the Project label
        show_buffer_close_icons = true,
        show_close_icon = false,
        tab_size = 0, -- no minimum width: short names would be centered and pushed to the right
        -- the sidebar offset also reserves its divider column, so the first tab starts at the
        -- editor's left edge instead of on top of the divider (the list replaces LazyVim's)
        offsets = {
          { filetype = "neo-tree", text = "Neo-tree", highlight = "Directory", text_align = "left", separator = true },
          { filetype = "snacks_layout_box", text = "Project", highlight = "Directory", text_align = "left", separator = true },
        },
        padding = 0,
      },
      highlights = highlights,
    },
  },
}
