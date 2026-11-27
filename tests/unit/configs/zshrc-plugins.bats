#!/usr/bin/env bats

setup() {
    ROOT="$(cd "$BATS_TEST_DIRNAME/../../.." && pwd)"
    HOME_DECOY="$BATS_TEST_TMPDIR/home"
    mkdir -p "$HOME_DECOY"
}

@test "zshrc starts clean without the plugin packages" {
    run env -i HOME="$HOME_DECOY" PATH="/usr/bin:/bin" DOTFILES="$ROOT" ZDOTDIR="$BATS_TEST_TMPDIR" \
        zsh -f -c "ZSH=/nonexistent; source '$ROOT/configs/.zshrc' 2>&1; print done"
    [[ "$output" == *"done" ]]
}

@test "zshrc sources the packages only from usr share" {
    run grep -nE 'source .*/usr/share/(zsh-theme-powerlevel10k|zsh/plugins/zsh-autosuggestions|zsh/plugins/zsh-syntax-highlighting)' "$ROOT/configs/.zshrc"
    [ "$status" -eq 0 ]
    run grep -nE '\[\[ -r .*/usr/share' "$ROOT/configs/.zshrc"
    [ "$status" -eq 0 ]
}

@test "zshrc loads the private shell files in name order" {
    mkdir -p "$BATS_TEST_TMPDIR/dot/private/shell" "$BATS_TEST_TMPDIR/dot/lib"
    cp "$ROOT/lib/private.sh" "$BATS_TEST_TMPDIR/dot/lib/"
    echo 'echo B' > "$BATS_TEST_TMPDIR/dot/private/shell/20-b.zsh"
    echo 'echo A' > "$BATS_TEST_TMPDIR/dot/private/shell/10-a.zsh"
    run env -i HOME="$HOME_DECOY" PATH="/usr/bin:/bin" DOTFILES="$BATS_TEST_TMPDIR/dot" \
        zsh -f -c "ZSH=/nonexistent; source '$ROOT/configs/.zshrc' 2>/dev/null"
    [[ "$output" == *"A"*"B"* ]]
}

@test "the three packages are in the package lists" {
    grep -q 'zsh-autosuggestions' "$ROOT/packages/pacman.list"
    grep -q 'zsh-syntax-highlighting' "$ROOT/packages/pacman.list"
    grep -qE 'zsh-theme-powerlevel10k' "$ROOT/packages/pacman.list" "$ROOT/packages/aur.list"
}

@test "no third party plugin or theme is vendored" {
    [ ! -e "$ROOT/.oh-my-zsh/custom/plugins" ] || [ -z "$(ls -A "$ROOT/.oh-my-zsh/custom/plugins" | grep -v '^\.gitignore$')" ]
    [ ! -e "$ROOT/.oh-my-zsh/custom/themes/powerlevel10k" ]
}

@test "zshrc reads no token file" {
    run grep -nE 'tokens\.env|\.env"|stitch|typesafe|marginalia|homelab' "$ROOT/configs/.zshrc"
    [ "$status" -ne 0 ]
}

@test "zshrc loads oh-my-zsh from ~/.oh-my-zsh when ZSH is not inherited" {
    # A graphical session started without a login shell exports no ZSH.
    mkdir -p "$HOME_DECOY/.oh-my-zsh"
    echo 'print OMZ-LOADED' > "$HOME_DECOY/.oh-my-zsh/oh-my-zsh.sh"
    run env -i HOME="$HOME_DECOY" PATH="/usr/bin:/bin" DOTFILES="$ROOT" ZDOTDIR="$BATS_TEST_TMPDIR" \
        zsh -f -c "source '$ROOT/configs/.zshrc' 2>/dev/null; print \"ZSH=\$ZSH\""
    [[ "$output" == *"OMZ-LOADED"* ]]
    [[ "$output" == *"ZSH=$HOME_DECOY/.oh-my-zsh"* ]]
}

@test "zshrc keeps an inherited ZSH" {
    mkdir -p "$BATS_TEST_TMPDIR/omz"
    echo 'print CUSTOM-OMZ' > "$BATS_TEST_TMPDIR/omz/oh-my-zsh.sh"
    run env -i HOME="$HOME_DECOY" PATH="/usr/bin:/bin" DOTFILES="$ROOT" ZDOTDIR="$BATS_TEST_TMPDIR" ZSH="$BATS_TEST_TMPDIR/omz" \
        zsh -f -c "source '$ROOT/configs/.zshrc' 2>/dev/null"
    [[ "$output" == *"CUSTOM-OMZ"* ]]
}

@test "zshrc re-derives a missing exported DOTFILES and ZSH_CUSTOM" {
    # Match the live layout: ~/.oh-my-zsh/custom -> clone custom (profiles.sh
    # later sets ZSH_CUSTOM=$ZSH/custom from the default ZSH).
    mkdir -p "$HOME_DECOY/.oh-my-zsh"
    ln -s "$ROOT/.oh-my-zsh/custom" "$HOME_DECOY/.oh-my-zsh/custom"
    run env -i HOME="$HOME_DECOY" PATH="/usr/bin:/bin" \
        DOTFILES=/nonexistent/dotfiles \
        ZSH_CUSTOM=/nonexistent/custom \
        ZDOTDIR="$BATS_TEST_TMPDIR" \
        zsh -f -c "source '$ROOT/configs/.zshrc' 2>/dev/null; print -r -- \$DOTFILES; print -r -- \$ZSH_CUSTOM"
    [[ "$output" == *"$ROOT"* ]]
    [[ "$output" != *"/nonexistent/"* ]]
    [[ "$output" == *"$HOME_DECOY/.oh-my-zsh/custom"* || "$output" == *"$ROOT/.oh-my-zsh/custom"* ]]
}
