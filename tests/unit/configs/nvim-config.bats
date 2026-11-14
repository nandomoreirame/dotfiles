#!/usr/bin/env bats

setup() {
    ROOT="$(cd "$BATS_TEST_DIRNAME/../../.." && pwd)"
    NVIM_DIR="$ROOT/configs/nvim"
}

@test "lazy.lua imports LazyVim and the six language extras" {
    f="$NVIM_DIR/lua/config/lazy.lua"
    [ -f "$f" ]
    grep -q 'lazyvim.plugins' "$f"
    for extra in lang.typescript lang.json lang.python lang.rust lang.go lang.clangd; do
        grep -q "lazyvim.plugins.extras.$extra" "$f"
    done
}

@test "theme file defines both variants and the amber and gray values" {
    f="$NVIM_DIR/colors/terminal-noir.lua"
    [ -f "$f" ]
    grep -qF '#F5A623' "$f"
    grep -qF '#64646B' "$f"
    grep -q 'dark' "$f"
    grep -q 'light' "$f"
    grep -q 'terminal-noir' "$NVIM_DIR/lua/plugins/colorscheme.lua"
}

@test "borders spec sets winborder rounded and gray float border" {
    grep -q 'winborder' "$NVIM_DIR/lua/config/options.lua"
    grep -q 'rounded' "$NVIM_DIR/lua/config/options.lua"
    grep -q 'FloatBorder' "$NVIM_DIR/lua/plugins/borders.lua"
}

@test "borders spec switches amber on focus and gray on blur" {
    f="$NVIM_DIR/lua/plugins/borders.lua"
    grep -q 'WinEnter' "$f"
    grep -q 'WinLeave' "$f"
    grep -q 'winhighlight' "$f"
    grep -q 'FloatBorderActive' "$f"
    grep -q 'WinSeparatorActive' "$f"
    grep -q 'noir_border_prev' "$f"
    grep -q 'vim.schedule' "$f"
    grep -q 'VimResized' "$f"
    grep -q 'BufWinEnter' "$f"
}

@test "motions spec disables flash and installs no motion trainer" {
    f="$NVIM_DIR/lua/plugins/motions.lua"
    grep -Eq '"folke/flash.nvim", *enabled = false' "$f"
    run grep -rniIE 'hardtime|precognition' "$NVIM_DIR"
    [ "$status" -eq 1 ]
}

@test "ghostty keeps JetBrainsMono Nerd Font and no neovide config exists" {
    grep -q 'font-family = "JetBrainsMono Nerd Font"' "$ROOT/configs/ghostty/config"
    [ ! -e "$ROOT/configs/neovide" ]
}

@test "no absolute home paths in configs/nvim" {
    run grep -rnIE '/home/[a-z_][a-z0-9_-]*/' "$NVIM_DIR"
    [ "$status" -eq 1 ]
}

@test "lazy.lua imports the tooling extras and none of the forbidden ones" {
    f="$NVIM_DIR/lua/config/lazy.lua"
    for extra in formatting.prettier linting.eslint lang.tailwind; do
        grep -q "lazyvim.plugins.extras.$extra" "$f"
    done
    for forbidden in lang.typescript.biome dap.core test.core editor.telescope; do
        run grep -q "$forbidden" "$f"
        [ "$status" -eq 1 ]
    done
}

@test "css and html support is configured without emmet" {
    f="$NVIM_DIR/lua/plugins/css-html.lua"
    grep -q 'css' "$f"
    grep -q 'html' "$f"
    grep -q 'css-lsp' "$f"
    grep -q 'html-lsp' "$f"
    run grep -rniI 'emmet' "$NVIM_DIR"
    [ "$status" -eq 1 ]
}

@test "vscode keys map the safe set and avoid ctrl-d and ctrl-x" {
    f="$NVIM_DIR/lua/config/vscode-keys.lua"
    [ -f "$f" ]
    for key in '<C-p>' '<A-Up>' '<A-Down>' '<A-S-Up>' '<A-S-Down>'; do
        grep -qF "$key" "$f"
    done
    for key in '<C-d>' '<C-x>' '<C-S-Up>' '<C-S-Down>'; do
        run grep -qF "$key" "$f"
        [ "$status" -eq 1 ]
    done
    grep -qF 'pcall(require, "config.vscode-keys")' "$NVIM_DIR/lua/config/keymaps.lua"
}

@test "lazy.lua imports treesitter-context and no animation extras" {
    f="$NVIM_DIR/lua/config/lazy.lua"
    grep -q "lazyvim.plugins.extras.ui.treesitter-context" "$f"
    for extra in ui.smear-cursor ui.mini-animate; do
        run grep -q "$extra" "$f"
        [ "$status" -eq 1 ]
    done
    grep -q 'vim.g.snacks_animate = false' "$NVIM_DIR/lua/config/options.lua"
}

@test "snacks spec turns off smooth scroll and replaces the dashboard logo with the NEOVIM art" {
    f="$NVIM_DIR/lua/plugins/snacks.lua"
    grep -q 'folke/snacks.nvim' "$f"
    grep -Eq 'scroll = \{ enabled = false \}' "$f"
    grep -qF '███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗' "$f"
    run grep -qF '██╗      █████╗ ███████╗██╗   ██╗' "$f"
    [ "$status" -eq 1 ]
}

@test "the picker is snacks and telescope is not enabled" {
    run grep -rniE 'lazyvim_picker|telescope' "$NVIM_DIR/lua"
    [ "$status" -eq 1 ]
}

@test "headless: borders are gray and rounded and follow the focused window" {
    [ -d "$HOME/.local/share/nvim/lazy/LazyVim" ] || skip "plugins are not installed"
    script="$(mktemp --suffix=.lua)"
    cat > "$script" <<'LUA'
vim.wait(90000, function() return vim.g.colors_name == "terminal-noir" end, 200)
local function hex(n) return string.format("#%06x", n or 0) end
local function hl(name) return vim.api.nvim_get_hl(0, { name = name, link = false }) end
local out = {}
out[#out + 1] = "winborder=" .. vim.o.winborder
out[#out + 1] = "floatborder=" .. hex(hl("FloatBorder").fg)
out[#out + 1] = "separator-hidden=" .. tostring(hl("WinSeparator").fg == hl("Normal").bg and hl("WinSeparatorActive").fg == hl("Normal").bg)
out[#out + 1] = "floatactive=" .. hex(hl("FloatBorderActive").fg)
local base = vim.api.nvim_get_current_win()
local buf = vim.api.nvim_create_buf(false, true)
local float = vim.api.nvim_open_win(buf, true, { relative = "editor", row = 2, col = 2, width = 10, height = 2, border = "rounded" })
out[#out + 1] = "float-focused=" .. vim.wo[float].winhighlight
vim.api.nvim_set_current_win(base)
out[#out + 1] = "float-blurred=[" .. vim.wo[float].winhighlight .. "]"
vim.cmd("vsplit")
local focused = vim.api.nvim_get_current_win()
out[#out + 1] = "split-focused=" .. vim.wo[focused].winhighlight
out[#out + 1] = "split-other=[" .. vim.wo[base].winhighlight .. "]"
io.write(table.concat(out, "\n"), "\n")
vim.cmd("qa!")
LUA
    run env -i HOME="$HOME" PATH="/usr/bin:/bin" TERM=xterm-256color timeout 180 nvim --headless -c "luafile $script"
    rm -f "$script"
    [[ "$output" == *"winborder=rounded"* ]]
    [[ "$output" == *"floatborder=#64646b"* ]]
    [[ "$output" == *"separator-hidden=true"* ]]
    [[ "$output" == *"floatactive=#f5a623"* ]]
    [[ "$output" == *"float-focused="*"FloatBorder:FloatBorderActive"* ]]
    [[ "$output" == *"float-blurred=[]"* ]]
    [[ "$output" == *"split-focused="*"WinSeparator:WinSeparatorActive"* ]]
    [[ "$output" == *"split-other=[]"* ]]
}

@test "headless: vscode keys work and ctrl-d and ctrl-x stay Vim's own" {
    [ -d "$HOME/.local/share/nvim/lazy/LazyVim" ] || skip "plugins are not installed"
    script="$(mktemp --suffix=.lua)"
    cat > "$script" <<'LUA'
vim.wait(90000, function() return vim.g.colors_name == "terminal-noir" end, 200)
vim.api.nvim_exec_autocmds("User", { pattern = "VeryLazy" })
local function mapped(lhs, mode)
  return vim.fn.maparg(lhs, mode) ~= "" and "yes" or "no"
end
local out = {}
out[#out + 1] = "ctrl-p=" .. mapped("<C-p>", "n")
for _, mode in ipairs({ "n", "i", "v" }) do
  out[#out + 1] = "alt-up-" .. mode .. "=" .. mapped("<A-Up>", mode)
  out[#out + 1] = "alt-down-" .. mode .. "=" .. mapped("<A-Down>", mode)
  out[#out + 1] = "dup-up-" .. mode .. "=" .. mapped("<A-S-Up>", mode)
  out[#out + 1] = "dup-down-" .. mode .. "=" .. mapped("<A-S-Down>", mode)
end
out[#out + 1] = "ctrl-d=" .. mapped("<C-d>", "n")
out[#out + 1] = "ctrl-x=" .. mapped("<C-x>", "n")
local function feed(keys) vim.fn.feedkeys(vim.keycode(keys), "x") end
vim.cmd("enew")
vim.api.nvim_buf_set_lines(0, 0, -1, false, { "a", "b", "c" })
vim.api.nvim_win_set_cursor(0, { 1, 0 })
feed("<A-Down>")
out[#out + 1] = "moved=" .. table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "")
vim.api.nvim_buf_set_lines(0, 0, -1, false, { "a", "b" })
vim.api.nvim_win_set_cursor(0, { 1, 0 })
feed("<A-S-Down>")
out[#out + 1] = "duplicated=" .. table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "")
vim.api.nvim_buf_set_lines(0, 0, -1, false, { "a", "b", "c" })
vim.api.nvim_win_set_cursor(0, { 2, 0 })
feed("V<A-S-Down>")
out[#out + 1] = "visual-dup=" .. table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "") .. " selected-line=" .. vim.fn.line("v")
vim.cmd("normal! \27")
vim.api.nvim_buf_set_lines(0, 0, -1, false, { "a", "b", "c" })
vim.api.nvim_win_set_cursor(0, { 1, 0 })
feed("V<A-Down>")
out[#out + 1] = "visual-moved=" .. table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "")
vim.cmd("normal! \27")
vim.api.nvim_buf_set_lines(0, 0, -1, false, { "a", "b", "c" })
vim.api.nvim_win_set_cursor(0, { 1, 0 })
feed("i<A-Down>")
out[#out + 1] = "insert-moved=" .. table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "")
vim.cmd("normal! \27")
vim.api.nvim_buf_set_lines(0, 0, -1, false, { "a", "b" })
vim.api.nvim_win_set_cursor(0, { 1, 0 })
feed("i<A-S-Down>")
out[#out + 1] = "insert-dup=" .. table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "") .. " cursor-line=" .. vim.api.nvim_win_get_cursor(0)[1]
io.write(table.concat(out, "\n"), "\n")
vim.cmd("qa!")
LUA
    run env -i HOME="$HOME" PATH="/usr/bin:/bin" TERM=xterm-256color timeout 180 nvim --headless -c "luafile $script"
    rm -f "$script"
    [[ "$output" == *"visual-dup=abbc selected-line=3"* ]]
    [[ "$output" == *"visual-moved=bac"* ]]
    [[ "$output" == *"insert-moved=bac"* ]]
    [[ "$output" == *"insert-dup=aab cursor-line=2"* ]]
    [[ "$output" == *"ctrl-p=yes"* ]]
    for mode in n i v; do
        [[ "$output" == *"alt-up-$mode=yes"* ]]
        [[ "$output" == *"alt-down-$mode=yes"* ]]
        [[ "$output" == *"dup-up-$mode=yes"* ]]
        [[ "$output" == *"dup-down-$mode=yes"* ]]
    done
    [[ "$output" == *"ctrl-d=no"* ]]
    [[ "$output" == *"ctrl-x=no"* ]]
    [[ "$output" == *"moved=bac"* ]]
    [[ "$output" == *"duplicated=aab"* ]]
}

@test "headless: the config still starts without the vscode keys file" {
    [ -d "$HOME/.local/share/nvim/lazy/LazyVim" ] || skip "plugins are not installed"
    tmp="$(mktemp -d)"
    cp -r "$NVIM_DIR" "$tmp/nvim"
    rm -f "$tmp/nvim/lua/config/vscode-keys.lua"
    run env -i HOME="$HOME" XDG_CONFIG_HOME="$tmp" PATH="/usr/bin:/bin" TERM=xterm-256color timeout 120 nvim --headless "+lua vim.api.nvim_exec_autocmds('User', { pattern = 'VeryLazy' })" +qa
    rm -rf "$tmp"
    [ "$status" -eq 0 ]
    [[ "$output" != *"Error"* ]]
}

@test "headless: borders merge into a plugin winhighlight and restore it" {
    [ -d "$HOME/.local/share/nvim/lazy/LazyVim" ] || skip "plugins are not installed"
    script="$(mktemp --suffix=.lua)"
    cat > "$script" <<'LUA'
vim.wait(90000, function() return vim.g.colors_name == "terminal-noir" end, 200)
local out = {}
local base = vim.api.nvim_get_current_win()
local buf = vim.api.nvim_create_buf(false, true)
local float = vim.api.nvim_open_win(buf, false, { relative = "editor", row = 2, col = 2, width = 10, height = 2, border = "rounded" })
vim.wo[float].winhighlight = "Normal:SnacksNormal,WinSeparator:SnacksWinSeparator,FloatBorder:Custom"
vim.api.nvim_set_current_win(float)
vim.wait(100)
out[#out + 1] = "focused=" .. vim.wo[float].winhighlight
-- a plugin rewrites winhighlight while the float is focused (snacks update on resize)
vim.wo[float].winhighlight = "Normal:SnacksNormal,WinSeparator:SnacksWinSeparator,FloatBorder:Custom"
vim.api.nvim_exec_autocmds("VimResized", {})
vim.wait(200)
out[#out + 1] = "rewritten=" .. vim.wo[float].winhighlight
vim.api.nvim_set_current_win(base)
vim.wait(100)
out[#out + 1] = "blurred=" .. vim.wo[float].winhighlight
-- a plugin rewrite that no longer has a border entry means it wants none: blur must not bring the old one back
vim.wo[float].winhighlight = "Normal:SnacksNormal,FloatBorder:Other"
vim.api.nvim_set_current_win(float)
vim.wait(100)
vim.wo[float].winhighlight = "Normal:SnacksNormal"
vim.api.nvim_exec_autocmds("VimResized", {})
vim.wait(200)
vim.api.nvim_set_current_win(base)
vim.wait(100)
out[#out + 1] = "no-border-rewrite=" .. vim.wo[float].winhighlight
io.write(table.concat(out, "\n"), "\n")
vim.cmd("qa!")
LUA
    run env -i HOME="$HOME" PATH="/usr/bin:/bin" TERM=xterm-256color timeout 180 nvim --headless -c "luafile $script"
    rm -f "$script"
    [ "$(grep '^no-border-rewrite=' <<<"$output")" = "no-border-rewrite=Normal:SnacksNormal" ]
    focused="$(grep '^focused=' <<<"$output")"
    rewritten="$(grep '^rewritten=' <<<"$output")"
    blurred="$(grep '^blurred=' <<<"$output")"
    [ "$focused" = "focused=Normal:SnacksNormal,WinSeparator:SnacksWinSeparator,FloatBorder:FloatBorderActive" ]
    [ "$rewritten" = "rewritten=Normal:SnacksNormal,WinSeparator:SnacksWinSeparator,FloatBorder:FloatBorderActive" ]
    [ "$blurred" = "blurred=Normal:SnacksNormal,WinSeparator:SnacksWinSeparator,FloatBorder:Custom" ]
}

@test "headless: flash is off so s S r R stay Vim's and no motion trainer loads" {
    [ -d "$HOME/.local/share/nvim/lazy/LazyVim" ] || skip "plugins are not installed"
    script="$(mktemp --suffix=.lua)"
    cat > "$script" <<'LUA'
vim.wait(90000, function() return vim.g.colors_name == "terminal-noir" end, 200)
vim.api.nvim_exec_autocmds("User", { pattern = "VeryLazy" })
vim.wait(2500)
local function mapped(lhs, mode) return vim.fn.maparg(lhs, mode) ~= "" and "yes" or "no" end
io.write("s=", mapped("s", "n"), " S=", mapped("S", "n"), " r=", mapped("r", "o"), " R=", mapped("R", "x"), "\n")
io.write("flash-loaded=", tostring(package.loaded["flash"] ~= nil), " precognition-loaded=", tostring(package.loaded["precognition"] ~= nil), " hardtime-loaded=", tostring(package.loaded["hardtime"] ~= nil), "\n")
vim.cmd("qa!")
LUA
    run env -i HOME="$HOME" PATH="/usr/bin:/bin" TERM=xterm-256color timeout 180 nvim --headless -c "luafile $script"
    rm -f "$script"
    [[ "$output" == *"s=no S=no r=no R=no"* ]]
    [[ "$output" == *"flash-loaded=false precognition-loaded=false hardtime-loaded=false"* ]]
}

@test "headless: css and html servers attach and the css parser loads" {
    [ -d "$HOME/.local/share/nvim/mason/packages/css-lsp" ] || skip "css-lsp is not installed"
    [ -d "$HOME/.local/share/nvim/mason/packages/html-lsp" ] || skip "html-lsp is not installed"
    dir="$(mktemp -d)"
    printf 'body { display: flex }\n' > "$dir/a.css"
    printf '<div class="x"></div>\n' > "$dir/a.html"
    script="$(mktemp --suffix=.lua)"
    cat > "$script" <<LUA
vim.wait(90000, function() return vim.g.colors_name == "terminal-noir" end, 200)
vim.api.nvim_exec_autocmds("User", { pattern = "VeryLazy" })
local function names(buf)
  local t = {}
  for _, c in ipairs(vim.lsp.get_clients({ bufnr = buf })) do t[#t + 1] = c.name end
  return table.concat(t, ",")
end
vim.cmd("edit $dir/a.css")
local css = vim.api.nvim_get_current_buf()
vim.wait(30000, function() return #vim.lsp.get_clients({ bufnr = css }) > 0 end, 200)
io.write("css-clients=", names(css), " css-parser=", tostring(pcall(vim.treesitter.get_parser, css, "css")), "\n")
vim.cmd("edit $dir/a.html")
local html = vim.api.nvim_get_current_buf()
vim.wait(30000, function() return #vim.lsp.get_clients({ bufnr = html }) > 0 end, 200)
io.write("html-clients=", names(html), "\n")
vim.cmd("qa!")
LUA
    run env -i HOME="$HOME" PATH="/usr/bin:/bin" TERM=xterm-256color timeout 240 nvim --headless -c "luafile $script"
    rm -rf "$script" "$dir"
    [[ "$output" == *"css-clients=cssls css-parser=true"* ]]
    [[ "$output" == *"html-clients=html"* ]]
}

@test "headless: animations are off, the dashboard header is the NEOVIM art and no browser preview command exists" {
    [ -d "$HOME/.local/share/nvim/lazy/LazyVim" ] || skip "plugins are not installed"
    script="$(mktemp --suffix=.lua)"
    cat > "$script" <<'LUA'
vim.wait(90000, function() return vim.g.colors_name == "terminal-noir" end, 200)
vim.api.nvim_exec_autocmds("User", { pattern = "VeryLazy" })
vim.wait(1500)
io.write("snacks_animate=", tostring(vim.g.snacks_animate), "\n")
local header = Snacks.config.dashboard.preset.header or ""
io.write("scroll-enabled=", tostring(Snacks.config.scroll.enabled), " neovim-art=", tostring(header:find("███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗", 1, true) ~= nil), " lazy-art=", tostring(header:find("██╗      █████╗ ███████╗██╗   ██╗", 1, true) ~= nil), "\n")
io.write("preview-cmd=", vim.fn.exists(":MarkdownPreview"), " smear=", tostring(package.loaded["smear_cursor"] ~= nil), " animate=", tostring(package.loaded["mini.animate"] ~= nil), "\n")
vim.cmd("qa!")
LUA
    run env -i HOME="$HOME" PATH="/usr/bin:/bin" TERM=xterm-256color timeout 180 nvim --headless -c "luafile $script"
    rm -f "$script"
    [[ "$output" == *"snacks_animate=false"* ]]
    [[ "$output" == *"scroll-enabled=false neovim-art=true lazy-art=false"* ]]
    [[ "$output" == *"preview-cmd=0 smear=false animate=false"* ]]
}

@test "options keep fixed absolute line numbers" {
    f="$NVIM_DIR/lua/config/options.lua"
    grep -q 'vim.opt.relativenumber = false' "$f"
    grep -q 'vim.opt.number = true' "$f"
}

@test "headless: line numbers are absolute, not relative" {
    [ -d "$HOME/.local/share/nvim/lazy/LazyVim" ] || skip "plugins are not installed"
    script="$(mktemp --suffix=.lua)"
    cat > "$script" <<'LUA'
vim.wait(90000, function() return vim.g.colors_name == "terminal-noir" end, 200)
vim.api.nvim_exec_autocmds("User", { pattern = "VeryLazy" })
vim.cmd("enew")
io.write("number=", tostring(vim.wo.number), " relativenumber=", tostring(vim.wo.relativenumber), "\n")
vim.cmd("qa!")
LUA
    run env -i HOME="$HOME" PATH="/usr/bin:/bin" TERM=xterm-256color timeout 180 nvim --headless -c "luafile $script"
    rm -f "$script"
    [[ "$output" == *"number=true relativenumber=false"* ]]
}

@test "indent guides are defined from the theme colors" {
    f="$NVIM_DIR/lua/plugins/indent.lua"
    grep -q 'SnacksIndent' "$f"
    grep -q 'ColorScheme' "$f"
    grep -q 'Normal' "$f"
}

@test "headless: indent guides are almost invisible on both variants" {
    [ -d "$HOME/.local/share/nvim/lazy/LazyVim" ] || skip "plugins are not installed"
    script="$(mktemp --suffix=.lua)"
    cat > "$script" <<'LUA'
vim.wait(90000, function() return vim.g.colors_name == "terminal-noir" end, 200)
vim.api.nvim_exec_autocmds("User", { pattern = "VeryLazy" })
vim.wait(800)
local function channels(n) return { math.floor(n / 65536) % 256, math.floor(n / 256) % 256, n % 256 } end
local function gap(variant)
  vim.o.background = variant
  vim.cmd("colorscheme terminal-noir")
  local bg = vim.api.nvim_get_hl(0, { name = "Normal", link = false }).bg
  local guide = vim.api.nvim_get_hl(0, { name = "SnacksIndent", link = false }).fg
  if not (bg and guide) then return -1 end
  local a, b, max = channels(bg), channels(guide), 0
  for i = 1, 3 do max = math.max(max, math.abs(a[i] - b[i])) end
  return max
end
io.write("dark-gap=", gap("dark"), " light-gap=", gap("light"), "\n")
vim.cmd("qa!")
LUA
    run env -i HOME="$HOME" PATH="/usr/bin:/bin" TERM=xterm-256color timeout 180 nvim --headless -c "luafile $script"
    rm -f "$script"
    dark="$(grep -o 'dark-gap=[-0-9]*' <<<"$output" | cut -d= -f2)"
    light="$(grep -o 'light-gap=[-0-9]*' <<<"$output" | cut -d= -f2)"
    [ -n "$dark" ] && [ "$dark" -ge 1 ] && [ "$dark" -le 32 ]
    [ -n "$light" ] && [ "$light" -ge 1 ] && [ "$light" -le 32 ]
}

@test "the scope guide is stronger than the indent guides but softer than the theme color" {
    f="$NVIM_DIR/lua/plugins/indent.lua"
    grep -q 'SnacksIndentScope' "$f"
    grep -q 'Special' "$f"
}

@test "headless: the scope guide sits between the indent guide and the theme color" {
    [ -d "$HOME/.local/share/nvim/lazy/LazyVim" ] || skip "plugins are not installed"
    script="$(mktemp --suffix=.lua)"
    cat > "$script" <<'LUA'
vim.wait(90000, function() return vim.g.colors_name == "terminal-noir" end, 200)
vim.api.nvim_exec_autocmds("User", { pattern = "VeryLazy" })
vim.wait(800)
local function channels(n) return { math.floor(n / 65536) % 256, math.floor(n / 256) % 256, n % 256 } end
local function gap(bg, color)
  if not (bg and color) then return -1 end
  local a, b, max = channels(bg), channels(color), 0
  for i = 1, 3 do max = math.max(max, math.abs(a[i] - b[i])) end
  return max
end
local function result(variant)
  vim.o.background = variant
  vim.cmd("colorscheme terminal-noir")
  local function fg(name) return vim.api.nvim_get_hl(0, { name = name, link = false }).fg end
  local bg = vim.api.nvim_get_hl(0, { name = "Normal", link = false }).bg
  return gap(bg, fg("SnacksIndent")), gap(bg, fg("SnacksIndentScope")), gap(bg, fg("Special"))
end
local dg, ds, dp = result("dark")
local lg, ls, lp = result("light")
io.write(string.format("dark=%d,%d,%d light=%d,%d,%d\n", dg, ds, dp, lg, ls, lp))
vim.cmd("qa!")
LUA
    run env -i HOME="$HOME" PATH="/usr/bin:/bin" TERM=xterm-256color timeout 180 nvim --headless -c "luafile $script"
    rm -f "$script"
    IFS=', =' read -r _ dg ds dp _ lg ls lp <<<"$(grep -o 'dark=[-0-9,]* light=[-0-9,]*' <<<"$output")"
    [ "$dg" -ge 1 ] && [ "$dg" -lt "$ds" ] && [ "$ds" -lt "$dp" ]
    [ "$lg" -ge 1 ] && [ "$lg" -lt "$ls" ] && [ "$ls" -lt "$lp" ]
}

@test "bufferline draws flat tabs with thin gray borders and no indicator bar" {
    f="$NVIM_DIR/lua/plugins/bufferline.lua"
    grep -q 'akinsho/bufferline.nvim' "$f"
    grep -q 'separator_style = "thin"' "$f"
    grep -q 'style = "none"' "$f"
    run grep -q 'underline' "$f"
    [ "$status" -eq 1 ]
    grep -q 'tab_size = 0' "$f"
    grep -q 'snacks_layout_box' "$f"
    grep -q 'separator = true' "$f"
    grep -q 'NormalFloat' "$f"
    grep -q 'highlights = highlights' "$f"
    run grep -qE 'nr2char|0xE0B' "$f"
    [ "$status" -eq 1 ]
}

@test "headless: the tab bar is flat, flush with the editor and follows the sidebar and editor colors" {
    [ -d "$HOME/.local/share/nvim/lazy/LazyVim" ] || skip "plugins are not installed"
    script="$(mktemp --suffix=.lua)"
    cat > "$script" <<'LUA'
vim.wait(90000, function() return vim.g.colors_name == "terminal-noir" end, 200)
vim.api.nvim_exec_autocmds("User", { pattern = "VeryLazy" })
vim.wait(1500)
local function hl(name) return vim.api.nvim_get_hl(0, { name = name, link = false }) end
local o = require("bufferline.config").get().options
io.write("style=", tostring(o.separator_style), " indicator=", tostring(o.indicator.style), " tab_size=", tostring(o.tab_size), "\n")
local explorer_offset = false
for _, offset in ipairs(o.offsets or {}) do
  if offset.filetype == "snacks_layout_box" and offset.separator == true then explorer_offset = true end
end
io.write("explorer-offset-reserves-divider=", tostring(explorer_offset), " offset-divider-is-hidden=", tostring(hl("BufferLineOffsetSeparator").fg == hl("Normal").bg), "\n")
io.write("fill-is-sidebar-tone=", tostring(hl("BufferLineFill").bg == hl("NormalFloat").bg), " selected-is-editor-tone=", tostring(hl("BufferLineBufferSelected").bg == hl("Normal").bg), " visible-is-editor-tone=", tostring(hl("BufferLineBufferVisible").bg == hl("Normal").bg), "\n")
io.write("no-underline=", tostring(not hl("BufferLineBufferSelected").underline), " border-is-gray=", tostring(hl("BufferLineSeparator").fg == hl("FloatBorder").fg), "\n")
vim.cmd("qa!")
LUA
    run env -i HOME="$HOME" PATH="/usr/bin:/bin" TERM=xterm-256color timeout 180 nvim --headless -c "luafile $script"
    rm -f "$script"
    [[ "$output" == *"style=thin indicator=none tab_size=0"* ]]
    [[ "$output" == *"explorer-offset-reserves-divider=true offset-divider-is-hidden=true"* ]]
    [[ "$output" == *"fill-is-sidebar-tone=true selected-is-editor-tone=true visible-is-editor-tone=true"* ]]
    [[ "$output" == *"no-underline=true border-is-gray=true"* ]]
}

@test "clipboard paste asks wl-paste for text only" {
    f="$NVIM_DIR/lua/config/options.lua"
    grep -q 'vim.g.clipboard' "$f"
    grep -q 'wl-paste' "$f"
    grep -q -- '--type text' "$f"
    grep -q 'WAYLAND_DISPLAY' "$f"
}

@test "headless: pasting never reads image data from the clipboard" {
    [ -d "$HOME/.local/share/nvim/lazy/LazyVim" ] || skip "plugins are not installed"
    script="$(mktemp --suffix=.lua)"
    cat > "$script" <<'LUA'
vim.wait(90000, function() return vim.g.colors_name == "terminal-noir" end, 200)
local c = vim.g.clipboard
local plus = c and c.paste and table.concat(c.paste["+"], " ") or "none"
local star = c and c.paste and table.concat(c.paste["*"], " ") or "none"
io.write("plus-text-only=", tostring(plus:find("--type text", 1, true) ~= nil), " star-text-only=", tostring(star:find("--type text", 1, true) ~= nil), " fails-silently=", tostring(plus:find("|| true", 1, true) ~= nil), "\n")
vim.cmd("qa!")
LUA
    run env -i HOME="$HOME" PATH="/usr/bin:/bin" TERM=xterm-256color WAYLAND_DISPLAY=wayland-test timeout 180 nvim --headless -c "luafile $script"
    rm -f "$script"
    [[ "$output" == *"plus-text-only=true star-text-only=true fails-silently=true"* ]]
}


@test "markdown renders inside the editor and no browser preview is installed" {
    f="$NVIM_DIR/lua/plugins/markdown.lua"
    grep -q 'MeanderingProgrammer/render-markdown.nvim' "$f"
    grep -q 'ft = { "markdown"' "$f"
    grep -qF '<leader>um' "$f"
    [ ! -e "$NVIM_DIR/lua/plugins/markdown-preview.lua" ]
    run grep -rniIE 'markdown-preview|mkdp|iamcco' "$NVIM_DIR"
    [ "$status" -eq 1 ]
}

@test "headless: a markdown buffer is rendered in the editor, with a toggle and no browser command" {
    [ -d "$HOME/.local/share/nvim/lazy/LazyVim" ] || skip "plugins are not installed"
    dir="$(mktemp -d)"
    printf '# Title\n\n- item\n\n```lua\nlocal x = 1\n```\n' > "$dir/a.md"
    script="$(mktemp --suffix=.lua)"
    cat > "$script" <<LUA
vim.wait(90000, function() return vim.g.colors_name == "terminal-noir" end, 200)
vim.api.nvim_exec_autocmds("User", { pattern = "VeryLazy" })
vim.cmd("edit $dir/a.md")
vim.wait(3000, function() return package.loaded["render-markdown"] ~= nil end, 100)
vim.wait(500)
local ok, rm = pcall(require, "render-markdown")
io.write("loaded=", tostring(ok), " enabled=", tostring(ok and rm.get()), " toggle=", tostring(vim.fn.maparg("<leader>um", "n", false, true).desc or "none"), " browser-cmd=", vim.fn.exists(":MarkdownPreview"), "\n")
vim.cmd("qa!")
LUA
    run env -i HOME="$HOME" PATH="/usr/bin:/bin" TERM=xterm-256color timeout 180 nvim --headless -c "luafile $script"
    rm -rf "$script" "$dir"
    [[ "$output" == *"loaded=true enabled=true toggle=Toggle Render Markdown browser-cmd=0"* ]]
}

@test "markdown heading bands are defined from the theme colors" {
    f="$NVIM_DIR/lua/plugins/markdown.lua"
    grep -q 'RenderMarkdownH' "$f"
    grep -qF '.. "Bg"' "$f"
    grep -q 'ColorScheme' "$f"
    grep -q 'Normal' "$f"
}

@test "headless: markdown heading bands are subtle on both variants" {
    [ -d "$HOME/.local/share/nvim/lazy/LazyVim" ] || skip "plugins are not installed"
    script="$(mktemp --suffix=.lua)"
    cat > "$script" <<'LUA'
vim.wait(90000, function() return vim.g.colors_name == "terminal-noir" end, 200)
vim.api.nvim_exec_autocmds("User", { pattern = "VeryLazy" })
local function channels(n) return { math.floor(n / 65536) % 256, math.floor(n / 256) % 256, n % 256 } end
local function gap(variant)
  vim.o.background = variant
  vim.cmd("colorscheme terminal-noir")
  local bg = vim.api.nvim_get_hl(0, { name = "Normal", link = false }).bg
  local band = vim.api.nvim_get_hl(0, { name = "RenderMarkdownH1Bg", link = false }).bg
  if not (bg and band) then return -1 end
  local a, b, max = channels(bg), channels(band), 0
  for i = 1, 3 do max = math.max(max, math.abs(a[i] - b[i])) end
  return max
end
io.write("dark-gap=", gap("dark"), " light-gap=", gap("light"), "\n")
vim.cmd("qa!")
LUA
    run env -i HOME="$HOME" PATH="/usr/bin:/bin" TERM=xterm-256color timeout 180 nvim --headless -c "luafile $script"
    rm -f "$script"
    dark="$(grep -o 'dark-gap=[-0-9]*' <<<"$output" | cut -d= -f2)"
    light="$(grep -o 'light-gap=[-0-9]*' <<<"$output" | cut -d= -f2)"
    [ -n "$dark" ] && [ "$dark" -ge 1 ] && [ "$dark" -le 40 ]
    [ -n "$light" ] && [ "$light" -ge 1 ] && [ "$light" -le 40 ]
}


@test "spelllang defaults to english" {
    run grep -nE 'DOTFILES_SPELLLANG' "$NVIM_DIR/lua/config/options.lua"
    [ "$status" -eq 0 ]
    run grep -nE 'pt_br' "$NVIM_DIR/lua/config/options.lua"
    [ "$status" -ne 0 ]
    run grep -q 'spell = false' "$NVIM_DIR/lua/config/autocmds.lua"
    [ "$status" -eq 1 ]
}

@test "headless: spell checking in markdown defaults to english" {
    [ -d "$HOME/.local/share/nvim/lazy/LazyVim" ] || skip "plugins are not installed"
    xdg="$(mktemp -d)"
    ln -s "$NVIM_DIR" "$xdg/nvim"
    dir="$(mktemp -d)"
    printf '# Title\n\ntext\n' > "$dir/a.md"
    script="$(mktemp --suffix=.lua)"
    cat > "$script" <<LUA
vim.wait(90000, function() return vim.g.colors_name == "terminal-noir" end, 200)
vim.api.nvim_exec_autocmds("User", { pattern = "VeryLazy" })
vim.wait(1000)
vim.cmd("edit $dir/a.md")
vim.wait(500)
local function bad(word) return vim.fn.spellbadword(word)[1] ~= "" end
io.write("spell=", tostring(vim.wo.spell), " lang=", vim.o.spelllang, " en-ok=", tostring(not bad("repository")), " en-wrong-caught=", tostring(bad("reposiotry")), "\n")
vim.cmd("qa!")
LUA
    run env -i HOME="$HOME" XDG_CONFIG_HOME="$xdg" PATH="/usr/bin:/bin" TERM=xterm-256color timeout 180 nvim --headless -c "luafile $script"
    rm -rf "$script" "$dir" "$xdg"
    [[ "$output" == *"spell=true lang=en en-ok=true en-wrong-caught=true"* ]]
}

@test "nvim lua holds no personal path or portuguese" {
    # Accent character classes false-positive on listchars box-drawing under this grep.
    run grep -rnE "nando""moreira|/home/[a-z]|\b(não|erro|arquivo)\b" \
        "$NVIM_DIR/lua" "$NVIM_DIR/init.lua"
    [ "$status" -ne 0 ]
}

@test "the generated terminal noir colorscheme is not edited by hand" {
    head -5 "$NVIM_DIR/colors/terminal-noir.lua" | grep -qi "generated"
}

@test "explorer shows hidden and ignored entries and has no input box" {
    f="$NVIM_DIR/lua/plugins/snacks.lua"
    grep -q 'explorer' "$f"
    grep -q 'hidden = true' "$f"
    grep -q 'ignored = true' "$f"
    grep -q '"input"' "$f"
}

@test "the sidebar offset is labelled Project" {
    f="$NVIM_DIR/lua/plugins/bufferline.lua"
    line="$(grep -F 'snacks_layout_box' "$f")"
    [[ "$line" == *'text = "Project"'* ]]
    [[ "$line" == *'text_align = "left"'* ]]
}

@test "headless: the explorer lists dotfiles and ignored files without the input window" {
    [ -d "$HOME/.local/share/nvim/lazy/LazyVim" ] || skip "plugins are not installed"
    dir="$(mktemp -d)"
    git -C "$dir" init -q
    printf 'ignored.txt\n' > "$dir/.gitignore"
    : > "$dir/ignored.txt"; : > "$dir/.hidden"; : > "$dir/shown.txt"
    script="$(mktemp --suffix=.lua)"
    cat > "$script" <<LUA
vim.wait(90000, function() return vim.g.colors_name == "terminal-noir" end, 200)
vim.api.nvim_exec_autocmds("User", { pattern = "VeryLazy" })
vim.wait(1000)
vim.cmd("cd $dir")
local explorer = Snacks.picker.explorer({ cwd = "$dir" })
vim.wait(2500)
local names = {}
for _, item in ipairs(explorer:items()) do names[#names + 1] = vim.fn.fnamemodify(item.file, ":t") end
table.sort(names)
local src = Snacks.config.picker.sources.explorer
io.write("names=", table.concat(names, ","), " hidden-win=", tostring(vim.tbl_contains(src.layout.hidden or {}, "input")), "\n")
vim.cmd("qa!")
LUA
    run env -i HOME="$HOME" PATH="/usr/bin:/bin" TERM=xterm-256color timeout 180 nvim --headless -c "luafile $script"
    rm -rf "$script" "$dir"
    [[ "$output" == *".gitignore"* ]]
    [[ "$output" == *".hidden"* ]]
    [[ "$output" == *"ignored.txt"* ]]
    [[ "$output" == *"hidden-win=true"* ]]
}

@test "headless: a focused explorer keeps the divider next to it gray" {
    [ -d "$HOME/.local/share/nvim/lazy/LazyVim" ] || skip "plugins are not installed"
    dir="$(mktemp -d)"
    : > "$dir/a.txt"
    script="$(mktemp --suffix=.lua)"
    cat > "$script" <<LUA
vim.wait(90000, function() return vim.g.colors_name == "terminal-noir" end, 200)
vim.api.nvim_exec_autocmds("User", { pattern = "VeryLazy" })
vim.wait(1000)
vim.wait(3500)
local active, boxes = 0, 0
for _, win in ipairs(vim.api.nvim_list_wins()) do
  if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == "snacks_layout_box" then
    boxes = boxes + 1
    if vim.wo[win].winhighlight:find("WinSeparator:WinSeparatorActive", 1, true) then active = active + 1 end
  end
end
io.write("boxes=", boxes, " active-dividers=", active, "\n")
vim.cmd("qa!")
LUA
    run env -i HOME="$HOME" PATH="/usr/bin:/bin" TERM=xterm-256color timeout 180 nvim --headless "$dir" -c "luafile $script"
    rm -rf "$script" "$dir"
    [[ "$output" == *"boxes=1 active-dividers=0"* ]]
}

@test "explorer pads the list, shows the root as a ~ path and softens the cursor line" {
    f="$NVIM_DIR/lua/plugins/snacks.lua"
    grep -q 'foldcolumn' "$f"
    grep -q 'fnamemodify(item.file, ":~")' "$f"
    grep -q 'SnacksPickerListCursorLine' "$f"
    grep -q 'SnacksPickerPathHidden' "$f"
}

@test "headless: the explorer root reads as a ~ path and hidden entries stay readable on the cursor line" {
    [ -d "$HOME/.local/share/nvim/lazy/LazyVim" ] || skip "plugins are not installed"
    mkdir -p "$HOME/.cache"
    dir="$(mktemp -d -p "$HOME/.cache")"
    : > "$dir/.hidden"
    script="$(mktemp --suffix=.lua)"
    cat > "$script" <<LUA
vim.wait(90000, function() return vim.g.colors_name == "terminal-noir" end, 200)
vim.api.nvim_exec_autocmds("User", { pattern = "VeryLazy" })
vim.wait(1000)
vim.cmd("cd $dir")
local explorer = Snacks.picker.explorer({ cwd = "$dir" })
vim.wait(2500)
local function hl(name) return vim.api.nvim_get_hl(0, { name = name, link = false }) end
local function lum(n) return ((n / 65536) % 256) + ((n / 256) % 256) + (n % 256) end
local line = vim.api.nvim_buf_get_lines(explorer.list.win.buf, 0, 1, false)[1] or ""
io.write("root-tilde=", tostring(line:find("~/.cache/", 1, true) ~= nil), " cursor-softer=", tostring(lum(hl("SnacksPickerListCursorLine").bg or 1e9) < lum(hl("Visual").bg)), " hidden-brighter=", tostring(lum(hl("SnacksPickerPathHidden").fg or 0) > lum(hl("NonText").fg)), " pad=", vim.wo[explorer.list.win.win].foldcolumn, "\n")
vim.cmd("qa!")
LUA
    run env -i HOME="$HOME" PATH="/usr/bin:/bin" TERM=xterm-256color timeout 180 nvim --headless -c "luafile $script"
    rm -rf "$script" "$dir"
    [[ "$output" == *"root-tilde=true cursor-softer=true hidden-brighter=true pad=1"* ]]
}

@test "the tab bar is always shown so the Project label stays with a single buffer" {
    grep -q 'always_show_bufferline = true' "$NVIM_DIR/lua/plugins/bufferline.lua"
}

@test "headless: the tab bar is visible with one buffer open" {
    [ -d "$HOME/.local/share/nvim/lazy/LazyVim" ] || skip "plugins are not installed"
    dir="$(mktemp -d)"
    printf 'x\n' > "$dir/a.txt"
    script="$(mktemp --suffix=.lua)"
    cat > "$script" <<LUA
vim.wait(90000, function() return vim.g.colors_name == "terminal-noir" end, 200)
vim.api.nvim_exec_autocmds("User", { pattern = "VeryLazy" })
vim.wait(1000)
vim.cmd("edit $dir/a.txt")
vim.wait(800)
io.write("buffers=", #vim.fn.getbufinfo({ buflisted = 1 }), " showtabline=", vim.o.showtabline, "\n")
vim.cmd("qa!")
LUA
    run env -i HOME="$HOME" PATH="/usr/bin:/bin" TERM=xterm-256color timeout 180 nvim --headless -c "luafile $script"
    rm -rf "$script" "$dir"
    [[ "$output" == *"buffers=1 showtabline=2"* ]]
}

@test "autocmds do not bring the dashboard back when the last buffer is closed" {
    run grep -q 'Snacks.dashboard' "$NVIM_DIR/lua/config/autocmds.lua"
    [ "$status" -eq 1 ]
}

@test "headless: closing the last buffer leaves an empty buffer, not the dashboard" {
    [ -d "$HOME/.local/share/nvim/lazy/LazyVim" ] || skip "plugins are not installed"
    dir="$(mktemp -d)"
    printf 'x\n' > "$dir/a.txt"; printf 'y\n' > "$dir/b.txt"
    script="$(mktemp --suffix=.lua)"
    cat > "$script" <<LUA
vim.wait(90000, function() return vim.g.colors_name == "terminal-noir" end, 200)
vim.api.nvim_exec_autocmds("User", { pattern = "VeryLazy" })
vim.wait(1000)
vim.cmd("edit $dir/a.txt")
vim.cmd("edit $dir/b.txt")
Snacks.bufdelete()
vim.wait(600)
local after_first = vim.bo.filetype
Snacks.bufdelete()
vim.wait(1200)
local after_last = vim.bo.filetype .. "/float=" .. tostring(vim.api.nvim_win_get_config(0).relative ~= "")
vim.cmd("edit $dir/a.txt")
vim.cmd("enew")
vim.wait(600)
io.write("after-first=", after_first, " after-last=", after_last, " after-enew=[", vim.bo.filetype, "]\n")
vim.cmd("qa!")
LUA
    run env -i HOME="$HOME" PATH="/usr/bin:/bin" TERM=xterm-256color timeout 180 nvim --headless -c "luafile $script"
    rm -rf "$script" "$dir"
    [[ "$output" == *"after-first=text after-last=/float=false after-enew=[]"* ]]
}

@test "ctrl-w closes the tab in normal mode and keeps the window prefix in special buffers" {
    grep -qF '<C-w>' "$NVIM_DIR/lua/config/vscode-keys.lua"
    grep -q 'bufdelete' "$NVIM_DIR/lua/config/vscode-keys.lua"
}

@test "headless: ctrl-w closes the buffer, but a special buffer keeps the window prefix" {
    [ -d "$HOME/.local/share/nvim/lazy/LazyVim" ] || skip "plugins are not installed"
    dir="$(mktemp -d)"
    printf 'x\n' > "$dir/a.txt"; printf 'y\n' > "$dir/b.txt"
    script="$(mktemp --suffix=.lua)"
    cat > "$script" <<LUA
vim.wait(90000, function() return vim.g.colors_name == "terminal-noir" end, 200)
vim.api.nvim_exec_autocmds("User", { pattern = "VeryLazy" })
vim.wait(1000)
vim.cmd("edit $dir/a.txt")
vim.cmd("edit $dir/b.txt")
vim.api.nvim_feedkeys(vim.keycode("<C-w>"), "mx", false)
vim.wait(300)
local name = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":t")
local listed = #vim.fn.getbufinfo({ buflisted = 1 })
vim.cmd("vsplit")
local wins = #vim.api.nvim_list_wins()
vim.cmd("enew | setlocal buftype=nofile")
vim.api.nvim_feedkeys(vim.keycode("<C-w>") .. "c", "mx", false)
vim.wait(300)
io.write("current=", name, " listed=", listed, " wins-before=", wins, " wins-after=", #vim.api.nvim_list_wins(), "\n")
vim.cmd("qa!")
LUA
    run env -i HOME="$HOME" PATH="/usr/bin:/bin" TERM=xterm-256color timeout 180 nvim --headless -c "luafile $script"
    rm -rf "$script" "$dir"
    [[ "$output" == *"current=a.txt listed=1 wins-before=2 wins-after=1"* ]]
}

@test "cloak masks .env secrets and leaves .env.example readable" {
    f="$NVIM_DIR/lua/plugins/cloak.lua"
    grep -q 'laytan/cloak.nvim' "$f"
    grep -qF '".env"' "$f"
    run grep -qF '".env.example"' "$f"
    [ "$status" -eq 1 ]
    grep -q 'cloak.nvim' "$NVIM_DIR/lazy-lock.json"
}

@test "headless: an .env value is masked, .env.example is not, and the toggle reveals it" {
    [ -d "$HOME/.local/share/nvim/lazy/cloak.nvim" ] || skip "cloak.nvim is not installed"
    dir="$(mktemp -d)"
    printf 'API_KEY=supersecret\n' > "$dir/.env"
    printf 'API_KEY=example\n' > "$dir/.env.example"
    script="$(mktemp --suffix=.lua)"
    cat > "$script" <<LUA
vim.wait(90000, function() return vim.g.colors_name == "terminal-noir" end, 200)
vim.api.nvim_exec_autocmds("User", { pattern = "VeryLazy" })
vim.wait(1000)
local function marks()
  local n = 0
  for ns_name, ns in pairs(vim.api.nvim_get_namespaces()) do
    if ns_name:lower():find("cloak", 1, true) then
      n = n + #vim.api.nvim_buf_get_extmarks(0, ns, 0, -1, {})
    end
  end
  return n
end
vim.cmd("edit $dir/.env")
vim.wait(500)
local masked = marks()
vim.cmd("CloakToggle")
vim.wait(300)
local revealed = marks()
vim.cmd("CloakToggle")
vim.cmd("edit $dir/.env.example")
vim.wait(500)
io.write("masked=", tostring(masked > 0), " revealed=", tostring(revealed == 0), " example-masked=", tostring(marks() > 0), "\n")
vim.cmd("qa!")
LUA
    run env -i HOME="$HOME" PATH="/usr/bin:/bin" TERM=xterm-256color timeout 180 nvim --headless -c "luafile $script"
    rm -rf "$script" "$dir"
    [[ "$output" == *"masked=true revealed=true example-masked=false"* ]]
}

@test "ctrl-r opens recent projects and redo moves to alt-r" {
    f="$NVIM_DIR/lua/config/vscode-keys.lua"
    grep -qF '"<C-r>"' "$f"
    grep -q 'picker.projects' "$f"
    grep -qF '"<A-r>"' "$f"
    grep -q 'redo' "$f"
}

@test "headless: alt-r redoes, ctrl-r opens the projects picker and insert ctrl-r keeps registers" {
    [ -d "$HOME/.local/share/nvim/lazy/LazyVim" ] || skip "plugins are not installed"
    script="$(mktemp --suffix=.lua)"
    cat > "$script" <<'LUA'
vim.wait(90000, function() return vim.g.colors_name == "terminal-noir" end, 200)
vim.api.nvim_exec_autocmds("User", { pattern = "VeryLazy" })
vim.wait(1000)
vim.cmd("enew")
vim.api.nvim_buf_set_lines(0, 0, -1, false, { "one" })
vim.cmd("set undolevels=1000 | normal! ixx")
vim.cmd("normal! u")
local undone = vim.api.nvim_get_current_line()
vim.api.nvim_feedkeys(vim.keycode("<A-r>"), "mx", false)
local redone = vim.api.nvim_get_current_line()
local n = vim.fn.maparg("<C-r>", "n", false, true)
local i = vim.fn.maparg("<C-r>", "i", false, true)
io.write("undone=", undone, " redone=", redone, " ctrl-r-normal=", n.desc or "NONE", " ctrl-r-insert-mapped=", tostring(next(i) ~= nil), "\n")
vim.cmd("qa!")
LUA
    run env -i HOME="$HOME" PATH="/usr/bin:/bin" TERM=xterm-256color timeout 180 nvim --headless -c "luafile $script"
    rm -f "$script"
    [[ "$output" == *"undone=one redone=xxone ctrl-r-normal=Projects ctrl-r-insert-mapped=false"* ]]
}

@test "the file and text pickers ignore build output, caches, package folders and the home data folders" {
    f="$NVIM_DIR/lua/plugins/snacks.lua"
    block="$(sed -n '/^local SEARCH_EXCLUDE = {/,/^}/p' "$f")"
    for name in .git node_modules dist build target .cache __pycache__ .venv .next go/pkg .local/share .npm .cargo/registry .vscode/extensions .config/google-chrome .config/discord; do
        [[ "$block" == *"\"$name\""* ]] || { echo "missing from SEARCH_EXCLUDE: $name"; return 1; }
    done
    # dot directories as a class are not ignored
    [[ "$block" != *'".*"'* ]]
}

@test "headless: the files picker skips the ignored folders and lists everything else, dot directories included" {
    [ -d "$HOME/.local/share/nvim/lazy/LazyVim" ] || skip "plugins are not installed"
    dir="$(mktemp -d)"
    mkdir -p "$dir/src" "$dir/.oh-my-zsh/custom" "$dir/.config/app" "$dir/node_modules/pkg" "$dir/.git/objects" "$dir/dist" "$dir/build" "$dir/.cache/x" "$dir/go/pkg/m" "$dir/.local/share/y" "$dir/.npm/_cacache" "$dir/target"
    for f in src/a.js .oh-my-zsh/custom/a.zsh .config/app/a.toml node_modules/pkg/a.js .git/objects/a dist/a.js build/a.js .cache/x/a.js go/pkg/m/a.go .local/share/y/a.txt .npm/_cacache/a target/a.rs; do : > "$dir/$f"; done
    script="$(mktemp --suffix=.lua)"
    cat > "$script" <<LUA
vim.wait(90000, function() return vim.g.colors_name == "terminal-noir" end, 200)
vim.api.nvim_exec_autocmds("User", { pattern = "VeryLazy" })
vim.wait(1000)
local picker = Snacks.picker.files({ cwd = "$dir" })
vim.wait(2500)
local files = {}
for _, item in ipairs(picker:items()) do files[#files + 1] = item.file end
table.sort(files)
io.write("files=", table.concat(files, ","), "\n")
vim.cmd("qa!")
LUA
    run env -i HOME="$HOME" PATH="/usr/bin:/bin" TERM=xterm-256color timeout 180 nvim --headless -c "luafile $script"
    rm -rf "$script" "$dir"
    for kept in src/a.js .oh-my-zsh/custom/a.zsh .config/app/a.toml; do
        [[ "$output" == *"$kept"* ]] || { echo "missing: $kept"; return 1; }
    done
    for dropped in node_modules .git/ dist/ build/ .cache/ go/pkg .local/share .npm target/; do
        [[ "$output" != *"$dropped"* ]] || { echo "should be ignored: $dropped"; return 1; }
    done
}

@test "the projects picker lists only recent projects, with no directory scan" {
    f="$NVIM_DIR/lua/plugins/snacks.lua"
    grep -q 'projects = {' "$f"
    grep -q 'dev = {}' "$f"
    grep -q 'recent = true' "$f"
    run grep -q 'projects_finder' "$f"
    [ "$status" -eq 1 ]
}

@test "headless: the projects picker is configured for recent projects only" {
    [ -d "$HOME/.local/share/nvim/lazy/LazyVim" ] || skip "plugins are not installed"
    script="$(mktemp --suffix=.lua)"
    cat > "$script" <<'LUA'
vim.wait(90000, function() return vim.g.colors_name == "terminal-noir" end, 200)
vim.api.nvim_exec_autocmds("User", { pattern = "VeryLazy" })
vim.wait(1000)
local p = Snacks.picker.projects()
vim.wait(1500)
io.write("dev-empty=", tostring(#(p.opts.dev or {}) == 0), " recent=", tostring(p.opts.recent), " finder=", tostring(p.opts.finder), "\n")
vim.cmd("qa!")
LUA
    run env -i HOME="$HOME" PATH="/usr/bin:/bin" TERM=xterm-256color timeout 180 nvim --headless -c "luafile $script"
    rm -f "$script"
    [[ "$output" == *"dev-empty=true recent=true finder=recent_projects"* ]]
}

@test "the window prefix on the leader still works while Ctrl+W closes the tab" {
    f="$NVIM_DIR/lua/config/vscode-keys.lua"
    grep -qF '"<leader>w" .. key' "$f"
    grep -q 'wincmd' "$f"
}

@test "headless: <leader>w keys run wincmd instead of reaching the Ctrl+W close mapping" {
    [ -d "$HOME/.local/share/nvim/lazy/LazyVim" ] || skip "plugins are not installed"
    script="$(mktemp --suffix=.lua)"
    cat > "$script" <<'LUA'
vim.wait(90000, function() return vim.g.colors_name == "terminal-noir" end, 200)
vim.api.nvim_exec_autocmds("User", { pattern = "VeryLazy" })
vim.wait(1000)
local bad = {}
for _, key in ipairs({ "s", "v", "h", "j", "k", "l", "w", "o", "c", "=" }) do
  local m = vim.fn.maparg("<leader>w" .. key, "n", false, true)
  if not (m.rhs and m.rhs:find("wincmd", 1, true)) then bad[#bad + 1] = key end
end
io.write("missing=[", table.concat(bad, ","), "]\n")
vim.cmd("qa!")
LUA
    run env -i HOME="$HOME" PATH="/usr/bin:/bin" TERM=xterm-256color timeout 180 nvim --headless -c "luafile $script"
    rm -f "$script"
    [[ "$output" == *"missing=[]"* ]]
}

@test "headless: the files picker finds files inside dot directories and still ignores node_modules and the caches" {
    [ -d "$HOME/.local/share/nvim/lazy/LazyVim" ] || skip "plugins are not installed"
    dir="$(mktemp -d)"
    mkdir -p "$dir/.oh-my-zsh/custom" "$dir/.cache/x" "$dir/node_modules/p" "$dir/src"
    : > "$dir/.oh-my-zsh/custom/aliases.zsh"; : > "$dir/.cache/x/aliases.zsh"
    : > "$dir/node_modules/p/aliases.zsh"; : > "$dir/src/aliases.zsh"; : > "$dir/.env"
    script="$(mktemp --suffix=.lua)"
    cat > "$script" <<LUA
vim.wait(90000, function() return vim.g.colors_name == "terminal-noir" end, 200)
vim.api.nvim_exec_autocmds("User", { pattern = "VeryLazy" })
vim.wait(1000)
local picker = Snacks.picker.files({ cwd = "$dir" })
vim.wait(2500)
local files = {}
for _, item in ipairs(picker:items()) do files[#files + 1] = item.file end
table.sort(files)
local grep = Snacks.picker.grep({ cwd = "$dir" })
io.write("files=", table.concat(files, ","), " grep-hidden=", tostring(grep.opts.hidden), "\n")
vim.cmd("qa!")
LUA
    run env -i HOME="$HOME" PATH="/usr/bin:/bin" TERM=xterm-256color timeout 180 nvim --headless -c "luafile $script"
    rm -rf "$script" "$dir"
    [[ "$output" == *".oh-my-zsh/custom/aliases.zsh"* ]]
    [[ "$output" == *"src/aliases.zsh"* ]]
    [[ "$output" == *".env"* ]]
    [[ "$output" != *".cache"* ]]
    [[ "$output" != *"node_modules"* ]]
    [[ "$output" == *"grep-hidden=true"* ]]
}

@test "statusline helpers format ahead/behind, encoding and LSP names" {
    command -v nvim >/dev/null || skip "nvim is not installed"
    script="$(mktemp --suffix=.lua)"
    cat > "$script" <<'LUA'
local s = require("config.statusline")
local out = {}
local a, b = s.parse_upstream_counts("1\t2\n")
out[#out + 1] = "parsed=" .. tostring(a) .. "," .. tostring(b)
out[#out + 1] = "parsed-bad=" .. tostring(s.parse_upstream_counts("fatal: no upstream"))
out[#out + 1] = "ab=" .. s.format_ahead_behind(2, 0)
out[#out + 1] = "enc-spaces=" .. s.format_encoding("utf-8", "unix", true, 2)
out[#out + 1] = "enc-tab=" .. s.format_encoding("", "dos", false, 4)
out[#out + 1] = "lsp=" .. s.join_names({ "ts_ls", "tailwindcss", "ts_ls" })
out[#out + 1] = "lsp-empty=[" .. s.join_names({}) .. "]"
io.write(table.concat(out, "\n"), "\n")
vim.cmd("qa!")
LUA
    run env -i HOME="$HOME" PATH="/usr/bin:/bin" TERM=xterm-256color timeout 60 nvim --headless -u NONE --cmd "set rtp+=$NVIM_DIR" -c "luafile $script"
    rm -f "$script"
    [[ "$output" == *"parsed=2,1"* ]]
    [[ "$output" == *"parsed-bad=nil"* ]]
    [[ "$output" == *"ab=↑2 ↓0"* ]]
    [[ "$output" == *"enc-spaces=utf-8 LF 2sp"* ]]
    [[ "$output" == *"enc-tab=utf-8 CRLF tab"* ]]
    [[ "$output" == *"lsp=ts_ls, tailwindcss"* ]]
    [[ "$output" == *"lsp-empty=[]"* ]]
}

@test "lualine spec puts ahead/behind by the branch and LSP, encoding and words in the bar" {
    f="$NVIM_DIR/lua/plugins/lualine.lua"
    [ -f "$f" ]
    grep -q 'config.statusline' "$f"
    grep -q 'lualine_z' "$f"
    run grep -q 'os.date' "$f"
    [ "$status" -eq 1 ]
}

@test "explorer sidebar width comes from one constant" {
    f="$NVIM_DIR/lua/plugins/snacks.lua"
    grep -Eq '^local EXPLORER_WIDTH = [0-9]+' "$f"
    grep -q 'min_width = EXPLORER_WIDTH' "$f"
}

@test "whitespace: trailing spaces are shown and trimmed on save, except in markdown" {
    command -v nvim >/dev/null || skip "nvim is not installed"
    script="$(mktemp --suffix=.lua)"
    tmp="$(mktemp -d)"
    cat > "$script" <<LUA
vim.cmd("filetype on")
require("config.whitespace").setup()
local out = {}
out[#out + 1] = "list=" .. tostring(vim.o.list)
out[#out + 1] = "trail=" .. (vim.opt.listchars:get().trail or "none")
out[#out + 1] = "space=" .. (vim.opt.listchars:get().space or "none")
local function save(name, lines)
  vim.cmd("edit $tmp/" .. name)
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
  vim.api.nvim_win_set_cursor(0, { 1, 1 })
  vim.cmd("write")
  local saved = table.concat(vim.fn.readfile("$tmp/" .. name), "|")
  return saved .. " cursor=" .. vim.api.nvim_win_get_cursor(0)[1] .. "," .. vim.api.nvim_win_get_cursor(0)[2]
end
out[#out + 1] = "lua=" .. save("a.lua", { "local x = 1   ", "\t ", "return x" })
out[#out + 1] = "md=" .. save("a.md", { "line one  ", "line two" })
io.write(table.concat(out, "\n"), "\n")
vim.cmd("qa!")
LUA
    run env -i HOME="$HOME" PATH="/usr/bin:/bin" TERM=xterm-256color timeout 60 nvim --headless -u NONE --cmd "set rtp+=$NVIM_DIR" -c "luafile $script"
    rm -rf "$script" "$tmp"
    [[ "$output" == *"list=true"* ]]
    [[ "$output" == *"trail=·"* ]]
    [[ "$output" == *"space=·"* ]]
    [[ "$output" == *"lua=local x = 1||return x cursor=1,1"* ]]
    [[ "$output" == *"md=line one  |line two"* ]]
}
