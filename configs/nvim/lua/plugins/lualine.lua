-- The bar sits above the tmux status line, which already shows the folder, host and clock, so it
-- carries what tmux cannot know: git ahead/behind, the LSP attached, encoding/EOL/indent and the
-- word count of text files. Helpers live in config/statusline.lua.
return {
  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      local s = require("config.statusline")
      s.setup_refresh()
      opts.sections.lualine_b = {
        "branch",
        { s.ahead_behind, cond = function() return s.ahead_behind() ~= "" end },
      }
      opts.sections.lualine_y = {
        { s.words, cond = function() return s.words() ~= "" end },
        s.encoding,
        { "progress", separator = " ", padding = { left = 1, right = 0 } },
        { "location", padding = { left = 0, right = 1 } },
      }
      opts.sections.lualine_z = {
        { s.lsp, cond = function() return s.lsp() ~= "" end },
      }
    end,
  },
}
