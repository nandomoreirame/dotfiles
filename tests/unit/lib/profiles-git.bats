#!/usr/bin/env bats

# Git identity profile module.

setup() {
    ROOT="$(cd "$BATS_TEST_DIRNAME/../../.." && pwd)"
    export HOME="$BATS_TEST_TMPDIR/home" DOTFILES="$BATS_TEST_TMPDIR/dot"
    mkdir -p "$HOME" "$DOTFILES/profiles/linux-arch" "$DOTFILES/lib" "$DOTFILES/lib/profiles"
    cp -r "$ROOT/lib/." "$DOTFILES/lib/"
    printf 'GIT_NAME="Jane Dev"\nGIT_EMAIL="jane@example.com"\nGIT_SIGNING_KEY="ssh-ed25519 AAAAexample"\nGIT_GPG_FORMAT="ssh"\n' \
        > "$DOTFILES/profiles/linux-arch/git-personal.conf"
}

@test "switching git writes the identity to gitconfig.local" {
    run env -i HOME="$HOME" PATH="/usr/bin:/bin" DOTFILES="$DOTFILES" DOTFILES_YES=1 bash -c \
        "source '$DOTFILES/lib/profiles.sh'; profile_switch_git personal"
    [ "$status" -eq 0 ]
    grep -q "name = Jane Dev" "$HOME/.gitconfig.local"
    grep -q "email = jane@example.com" "$HOME/.gitconfig.local"
    grep -q "format = ssh" "$HOME/.gitconfig.local"
}

@test "switching git never writes inside the repository" {
    env -i HOME="$HOME" PATH="/usr/bin:/bin" DOTFILES="$DOTFILES" DOTFILES_YES=1 bash -c \
        "source '$DOTFILES/lib/profiles.sh'; profile_switch_git personal" >/dev/null
    [ -z "$(find "$DOTFILES/configs" -name '.gitconfig*' 2>/dev/null)" ]
}

@test "an unknown git profile fails and lists the available ones" {
    run env -i HOME="$HOME" PATH="/usr/bin:/bin" DOTFILES="$DOTFILES" bash -c \
        "source '$DOTFILES/lib/profiles.sh'; profile_switch_git nope"
    [ "$status" -ne 0 ]
    [[ "$output" == *"personal"* ]]
}

@test "the git module carries no hard-coded identity" {
    _a="nando""moreira"
    run grep -nE "Fernando|${_a}|@gmail" "$ROOT/lib/profiles/git.sh"
    [ "$status" -ne 0 ]
}

@test "_profile_list_git_configs: lists git*.conf files" {
    mkdir -p "$DOTFILES/profiles/demo"
    printf 'GIT_NAME="A"\n' > "$DOTFILES/profiles/demo/git-personal.conf"
    printf 'GIT_NAME="B"\n' > "$DOTFILES/profiles/demo/git-work.conf"
    run env -i HOME="$HOME" PATH="/usr/bin:/bin" DOTFILES="$DOTFILES" bash -c \
        "source '$DOTFILES/lib/profiles.sh'; _profile_list_git_configs demo"
    [ "$status" -eq 0 ]
    [[ "$output" == *"git-personal.conf"* ]]
    [[ "$output" == *"git-work.conf"* ]]
}

@test "_profile_list_git_configs: returns empty for a profile without configs" {
    mkdir -p "$DOTFILES/profiles/empty"
    run env -i HOME="$HOME" PATH="/usr/bin:/bin" DOTFILES="$DOTFILES" bash -c \
        "source '$DOTFILES/lib/profiles.sh'; _profile_list_git_configs empty"
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "profile_list_git_configs lists short names under linux-arch" {
    printf 'GIT_NAME="Work"\nGIT_EMAIL="work@example.com"\n' \
        > "$DOTFILES/profiles/linux-arch/git-work.conf"
    run env -i HOME="$HOME" PATH="/usr/bin:/bin" DOTFILES="$DOTFILES" bash -c \
        "source '$DOTFILES/lib/profiles.sh'; profile_list_git_configs"
    [ "$status" -eq 0 ]
    [[ "$output" == *"personal"* ]]
    [[ "$output" == *"work"* ]]
}

@test "switching git clears the previous identity signing settings" {
    printf 'GIT_NAME="Alice A"\nGIT_EMAIL="a@example.com"\nGIT_SIGNING_KEY="ssh-ed25519 KEYA"\nGIT_GPG_FORMAT="ssh"\n' \
        > "$DOTFILES/profiles/linux-arch/git-a.conf"
    printf 'GIT_NAME="Bob B"\nGIT_EMAIL="b@example.com"\n' \
        > "$DOTFILES/profiles/linux-arch/git-b.conf"
    env -i HOME="$HOME" PATH="/usr/bin:/bin" DOTFILES="$DOTFILES" DOTFILES_YES=1 bash -c \
        "source '$DOTFILES/lib/profiles.sh'; profile_switch_git a" >/dev/null
    grep -q "signingkey = ssh-ed25519 KEYA" "$HOME/.gitconfig.local"
    run env -i HOME="$HOME" PATH="/usr/bin:/bin" DOTFILES="$DOTFILES" DOTFILES_YES=1 bash -c \
        "source '$DOTFILES/lib/profiles.sh'; profile_switch_git b"
    [ "$status" -eq 0 ]
    grep -q "name = Bob B" "$HOME/.gitconfig.local"
    grep -q "email = b@example.com" "$HOME/.gitconfig.local"
    ! grep -q "signingkey" "$HOME/.gitconfig.local"
    ! grep -q "format = ssh" "$HOME/.gitconfig.local"
    ! grep -qi "gpgsign" "$HOME/.gitconfig.local"
}
