#!/usr/bin/env bats

# Obsidian CSS snippet with the Terminal Noir palette .
#
# Run:
#   ./tests/run-tests unit/configs/obsidian-theme.bats

load '../../bats/helpers/setup'

SNIPPET="$PROJECT_ROOT/configs/obsidian/snippets/terminal-noir.css"
PALETTE="$PROJECT_ROOT/configs/noctalia/palettes/Terminal Noir.json"

# Value of a CSS custom property inside the .theme-dark block.
css_var() {
    sed -n '/^\.theme-dark {/,/^}/p' "$SNIPPET" \
        | sed -nE "s/^\s*--$1:\s*([^;]+);.*/\1/p"
}

pal() {
    jq -r ".dark.$1" "$PALETTE"
}

@test "snippet exists and themes dark mode only" {
    [ -f "$SNIPPET" ]
    grep -q '^\.theme-dark {' "$SNIPPET"
    ! grep -q '^\.theme-light' "$SNIPPET"
}

@test "surfaces and text come from the palette" {
    [ "$(css_var background-primary)" = "$(pal mSurface)" ]
    [ "$(css_var background-secondary-alt)" = "$(pal mSurfaceVariant)" ]
    [ "$(css_var text-normal)" = "$(pal mOnSurface)" ]
    [ "$(css_var text-muted)" = "$(pal mOnSurfaceVariant)" ]
}

@test "accent is the primary amber" {
    [ "$(css_var interactive-accent)" = "$(pal mPrimary)" ]
    [ "$(css_var text-accent)" = "$(pal mPrimary)" ]
    [ "$(css_var text-on-accent)" = "$(pal mOnPrimary)" ]
    [ "$(css_var accent-h)" = "37" ]
}

@test "status colors come from the palette" {
    [ "$(css_var text-success)" = "$(pal mSecondary)" ]
    [ "$(css_var text-warning)" = "$(pal mTertiary)" ]
    [ "$(css_var text-error)" = "$(pal mError)" ]
}

@test "code colors match the editor syntax theme" {
    local syntax="$PROJECT_ROOT/configs/themes/terminal-noir/syntax.json"
    tok() { jq -r --arg n "$1" '.tokens[] | select(.name == $n) | .color' "$syntax"; }
    [ "$(css_var code-keyword)" = "$(tok Keyword)" ]
    [ "$(css_var code-string)" = "$(tok String)" ]
    [ "$(css_var code-function)" = "$(tok Function)" ]
    [ "$(css_var code-comment)" = "$(tok Comment)" ]
}
