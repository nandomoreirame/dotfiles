-- Options are loaded before lazy.nvim starts.
-- LazyVim defaults: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua

-- rounded border on every floating window (snacks, which-key, hover, mason, lazy)
vim.o.winborder = "rounded"

-- no animations: smooth scroll and the other snacks animations stay off
vim.g.snacks_animate = false

-- fixed absolute line numbers, as in VS Code (LazyVim turns relative numbers on)
vim.opt.number = true
vim.opt.relativenumber = false

-- Wayland: read only text from the clipboard. Neovim's default `wl-paste --no-newline` returns
-- the raw bytes of an image when the clipboard holds one (a screenshot), and `p` then pastes a
-- PNG into the buffer. With --type text wl-paste fails instead, and `|| true` makes that a silent
-- empty paste.
if vim.env.WAYLAND_DISPLAY and vim.fn.executable("wl-paste") == 1 then
  vim.g.clipboard = {
    name = "wl-clipboard-text-only",
    copy = {
      ["+"] = { "wl-copy", "--foreground", "--type", "text/plain" },
      ["*"] = { "wl-copy", "--foreground", "--primary", "--type", "text/plain" },
    },
    paste = {
      ["+"] = { "sh", "-c", "wl-paste --no-newline --type text 2>/dev/null || true" },
      ["*"] = { "sh", "-c", "wl-paste --no-newline --primary --type text 2>/dev/null || true" },
    },
    cache_enabled = 0,
  }
end

-- Spell checking (LazyVim turns it on for markdown, text and commit messages).
-- Default is English so a fresh clone does not prompt for an extra dictionary.
-- Override with DOTFILES_SPELLLANG (comma-separated locales) in a private shell overlay.
do
  local raw = vim.env.DOTFILES_SPELLLANG or "en"
  local langs = {}
  for lang in string.gmatch(raw, "[^,]+") do
    langs[#langs + 1] = vim.trim(lang)
  end
  if #langs == 0 then
    langs = { "en" }
  end
  vim.opt.spelllang = langs
end
