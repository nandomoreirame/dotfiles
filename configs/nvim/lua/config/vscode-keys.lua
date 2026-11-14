-- Optional VS Code habits. Delete this file to drop them: keymaps.lua loads it under pcall.
-- Nothing here shadows a Vim motion.
local map = vim.keymap.set

-- quick open: the same file picker LazyVim binds to <leader><space>
map("n", "<C-p>", function()
  LazyVim.pick("files")()
end, { desc = "Find Files (Root Dir)" })

-- move the line or selection (LazyVim already maps the same action to Alt+j and Alt+k)
for _, mode in ipairs({ "n", "i", "v" }) do
  map(mode, "<A-Down>", "<A-j>", { remap = true, desc = "Move Down" })
  map(mode, "<A-Up>", "<A-k>", { remap = true, desc = "Move Up" })
end

-- duplicate the line or selection
map("n", "<A-S-Down>", "<cmd>copy .<cr>", { desc = "Duplicate Line Down" })
map("n", "<A-S-Up>", "<cmd>copy .-1<cr>", { desc = "Duplicate Line Up" })
map("i", "<A-S-Down>", "<cmd>copy .<cr>", { desc = "Duplicate Line Down" })
map("i", "<A-S-Up>", "<cmd>copy .-1<cr>", { desc = "Duplicate Line Up" })
map("v", "<A-S-Down>", ":<C-u>'<,'>copy '><cr>'[V']", { desc = "Duplicate Selection Down" })
map("v", "<A-S-Up>", ":<C-u>'<,'>copy '<-1<cr>'[V']", { desc = "Duplicate Selection Up" })

-- close the tab (buffer) like Ctrl+W in VS Code. In normal mode only: insert mode keeps
-- delete-word. This shadows the window prefix in file buffers (use the Ctrl+h/j/k/l window
-- moves and <leader>w instead); special buffers (explorer, help, terminals) keep the prefix.
map("n", "<C-w>", function()
  if vim.bo.buftype ~= "" then
    vim.api.nvim_feedkeys(vim.keycode("<C-w>"), "ni", false)
    return
  end
  Snacks.bufdelete()
end, { desc = "Close Tab" })

-- recent projects on Ctrl+R; redo moves to Alt+R (the normal-mode Ctrl+R was Vim's redo).
-- Insert and command-line Ctrl+R keep pasting registers.
map("n", "<C-r>", function()
  Snacks.picker.projects()
end, { desc = "Projects" })
map("n", "<A-r>", "<cmd>redo<cr>", { desc = "Redo" })

-- which-key's <leader>w proxies Ctrl+W, so with the mapping above every <leader>w key would close
-- the tab first. Explicit window commands keep Space w working.
for _, key in ipairs({ "s", "v", "h", "j", "k", "l", "w", "o", "c", "=" }) do
  map("n", "<leader>w" .. key, "<cmd>wincmd " .. key .. "<cr>", { desc = "Window " .. key })
end
