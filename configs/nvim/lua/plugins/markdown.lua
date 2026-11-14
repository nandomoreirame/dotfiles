-- Markdown rendered inside the editor (headings, lists, tables and code blocks get styled in
-- the buffer); <leader>um turns it on and off. No browser preview on purpose.

-- Heading bands: render-markdown paints each heading line with a Bg group; the theme leaves them
-- bright (a peach band on H1), so they get a subtle tone, 7% of the way from the Normal
-- background to the Normal text color, in either variant.
local group = vim.api.nvim_create_augroup("noir_markdown", { clear = true })

local function channels(n)
  return { math.floor(n / 65536) % 256, math.floor(n / 256) % 256, n % 256 }
end

local function blend(bg, fg, amount)
  local a, b, out = channels(bg), channels(fg), {}
  for i = 1, 3 do
    out[i] = math.floor(a[i] + (b[i] - a[i]) * amount + 0.5)
  end
  return out[1] * 65536 + out[2] * 256 + out[3]
end

local function define()
  local normal = vim.api.nvim_get_hl(0, { name = "Normal", link = false })
  if not (normal.bg and normal.fg) then
    return
  end
  for level = 1, 6 do
    vim.api.nvim_set_hl(0, "RenderMarkdownH" .. level .. "Bg", { bg = blend(normal.bg, normal.fg, 0.07) })
  end
end

vim.api.nvim_create_autocmd("ColorScheme", { group = group, callback = define })
define()

return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown", "norg", "rmd", "org" },
    opts = {
      code = { sign = false, width = "block", right_pad = 1 },
      heading = { sign = false, icons = {} },
      checkbox = { enabled = false },
    },
    config = function(_, opts)
      require("render-markdown").setup(opts)
      Snacks.toggle({
        name = "Render Markdown",
        get = require("render-markdown").get,
        set = require("render-markdown").set,
      }):map("<leader>um")
    end,
  },
}
