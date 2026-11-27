-- Explorer colors: the selected row is a soft tone (not the strong Visual gray) and hidden or
-- ignored entries are brighter than NonText, so a dimmed name stays readable when selected.
local function blend(bg, fg, amount)
  local function ch(n) return { math.floor(n / 65536) % 256, math.floor(n / 256) % 256, n % 256 } end
  local a, b, out = ch(bg), ch(fg), {}
  for i = 1, 3 do
    out[i] = math.floor(a[i] + (b[i] - a[i]) * amount + 0.5)
  end
  return out[1] * 65536 + out[2] * 256 + out[3]
end

local function define_explorer_colors()
  local float = vim.api.nvim_get_hl(0, { name = "NormalFloat", link = false })
  local normal = vim.api.nvim_get_hl(0, { name = "Normal", link = false })
  if not (float.bg and normal.fg) then
    return
  end
  local dim = { fg = blend(float.bg, normal.fg, 0.45) }
  vim.api.nvim_set_hl(0, "SnacksPickerListCursorLine", { bg = blend(float.bg, normal.fg, 0.12) })
  vim.api.nvim_set_hl(0, "SnacksPickerPathHidden", dim)
  vim.api.nvim_set_hl(0, "SnacksPickerPathIgnored", dim)
end

vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("noir_explorer", { clear = true }),
  callback = function()
    vim.schedule(define_explorer_colors)
  end,
})

-- Folders that file and text search skip, by name (a path like go/pkg matches at any depth).
-- Everything else is searched, dot directories included (.oh-my-zsh, .config, .github), and
-- files ignored by git stay out because the pickers honor .gitignore. Even so, the list holds the
-- noisy folders by name because searching from ~ has no .gitignore to lean on.
-- Explorer sidebar width in columns (the Snacks default is 40).
local EXPLORER_WIDTH = 30

-- Add a name here to hide one more folder. The explorer lists all of them on purpose.
local SEARCH_EXCLUDE = {
  -- version control, dependencies and build output
  ".git",
  "node_modules",
  "dist",
  "build",
  "target",
  ".next",
  ".turbo",
  -- caches and virtual environments
  ".cache",
  "__pycache__",
  ".mypy_cache",
  ".pytest_cache",
  ".ruff_cache",
  ".venv",
  "venv",
  -- package manager and language toolchain data in the home folder
  "go/pkg",
  ".npm",
  ".cargo/registry",
  ".rustup",
  ".local/share",
  ".local/state",
  ".var/app",
  ".wine",
  ".cargo/advisory-db",
  -- application data and extensions in the home folder (browsers, editors, emulators, agents)
  ".config/google-chrome",
  ".config/chromium",
  ".config/chromium-headless",
  ".config/discord",
  ".config/retroarch",
  ".config/Claude",
  ".config/Cursor",
  ".config/Code",
  ".config/Forja Dev",
  ".config/gcloud",
  ".vscode/extensions",
  ".cursor/extensions",
  ".cursor/projects",
  ".grok/sessions",
  ".codex/.tmp",
  ".gemini",
}

return {
  {
    "folke/snacks.nvim",
    opts = {
      -- no smooth-scroll animation
      scroll = { enabled = false },
      -- explorer: show dotfiles and git-ignored entries (dimmed by Snacks) and drop the input box
      -- on top of the sidebar; the layout keeps the window hidden, it is not removed
      picker = {
        sources = {
          -- only projects of files opened recently: no scan of ~/hub (the Snacks default)
          projects = { dev = {}, recent = true },
          files = { hidden = true, exclude = SEARCH_EXCLUDE },
          grep = { hidden = true, exclude = SEARCH_EXCLUDE },
          explorer = {
            hidden = true,
            ignored = true,
            layout = {
              preset = "sidebar",
              preview = false,
              hidden = { "input" },
              layout = { width = EXPLORER_WIDTH, min_width = EXPLORER_WIDTH },
            },
            -- the root row shows the whole project path (~/hub/) instead of its folder name
            format = function(item, picker)
              local ret = Snacks.picker.format.file(item, picker)
              if item.file == picker:cwd() then
                for _, chunk in ipairs(ret) do
                  if chunk.field == "file" then
                    chunk[1] = vim.fn.fnamemodify(item.file, ":~") .. "/"
                  end
                end
              end
              return ret
            end,
            -- one column of inner padding on the left (about half a tree indent step)
            win = { list = { wo = { foldcolumn = "1" } } },
          },
        },
      },
      -- dashboard header: the NEOVIM art (the Snacks default) instead of the LazyVim logo;
      -- the menu and recent files stay
      dashboard = {
        preset = {
          header = [[
███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗
████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║
██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║
██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║
██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║
╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝
]],
        },
      },
    },
  },
}
