-- Indent guides almost invisible: SnacksIndent sits 8% of the way from the Normal background
-- to the Normal text color, so it follows the Terminal Noir variant (dark or light).
-- The guide of the current scope (SnacksIndentScope) keeps the hue of the theme's Special
-- color but at 30% strength: stronger than the other guides, much softer than Special.
local group = vim.api.nvim_create_augroup("noir_indent", { clear = true })

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
  vim.api.nvim_set_hl(0, "SnacksIndent", { fg = blend(normal.bg, normal.fg, 0.08) })
  local special = vim.api.nvim_get_hl(0, { name = "Special", link = false })
  if special.fg then
    vim.api.nvim_set_hl(0, "SnacksIndentScope", { fg = blend(normal.bg, special.fg, 0.30) })
  end
end

vim.api.nvim_create_autocmd("ColorScheme", { group = group, callback = define })
define()

-- This file only registers an autocmd; lazy.nvim expects a spec table.
return {}
