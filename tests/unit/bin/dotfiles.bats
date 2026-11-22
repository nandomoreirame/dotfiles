#!/usr/bin/env bats

# Command surface of bin/dotfiles: noun-verb subcommands separated by spaces,
# one way to name a package manager (--manager) and actions never spelled as
# flags. The old colon forms and action flags are gone.

setup() {
    ROOT="$(cd "$BATS_TEST_DIRNAME/../../.." && pwd)"
    export HOME="$BATS_TEST_TMPDIR/home"; mkdir -p "$HOME"
    export DOTFILES_PRIVATE="$BATS_TEST_TMPDIR/private"; mkdir -p "$DOTFILES_PRIVATE"
    CLI() { run env -i HOME="$HOME" PATH="/usr/bin:/bin" TERM=xterm-256color DOTFILES_PRIVATE="$DOTFILES_PRIVATE" bash "$ROOT/bin/dotfiles" "$@"; }
    DOT="$BATS_TEST_TMPDIR/dot"
    mkdir -p "$DOT/configs"; printf 'a\n' > "$DOT/configs/.sample"
    printf '[files]\n.sample\n' > "$DOT/configs/links.conf"
    DCLI() { run env -i HOME="$HOME" PATH="/usr/bin:/bin" TERM=xterm-256color DOTFILES="$DOT" DOTFILES_PRIVATE="$DOTFILES_PRIVATE" bash "$ROOT/bin/dotfiles" "$@"; }
}

# ---- help and version ----

@test "help prints usage and exits 0" {
    CLI --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"Usage: dotfiles <command>"* ]]
}

@test "help lists the noun-verb commands" {
    CLI --help
    for c in "packages install" "packages remove" "--manager" "langs install" "fonts install" \
        "links create" "links verify" "setup run" "status" "init" "doctor" "install" "profile" "hooks" \
        "-V, --version" "-h, --help"; do
        [[ "$output" == *"$c"* ]] || { echo "missing: $c"; false; }
    done
}

@test "help has no colon commands, action flags, --only or interactive note" {
    CLI --help
    run grep -E '[a-z]+:(install|remove|run)|--status|--verify|--only|Interactive|--version, -v' <<< "$output"
    [ "$status" -ne 0 ]
}

@test "every help row lines its description up in one column" {
    CLI --help
    cols="$(grep -E '^  [a-z-]' <<< "$output" | awk '{ match($0, /  +[A-Z]/); print RSTART + RLENGTH }' | sort -u | wc -l)"
    [ "$cols" -eq 1 ]
}

@test "help is English" {
    CLI --help
    [[ "$output" != *"Exibe"* ]]
    [[ "$output" != *"Cria"* ]]
}

@test "version prints a version with --version and -V" {
    CLI --version
    [ "$status" -eq 0 ]
    [[ "$output" =~ [0-9]+\.[0-9]+ ]]
    CLI -V
    [ "$status" -eq 0 ]
    [[ "$output" == *"dotfiles v"* ]]
}

@test "-v is not a version alias" {
    CLI -v
    [ "$status" -ne 0 ]
}

@test "a symlink on PATH resolves the clone" {
    ln -s "$ROOT/bin/dotfiles" "$HOME/df"
    run env -i HOME="$HOME" PATH=/usr/bin:/bin bash "$HOME/df" --version
    [ "$status" -eq 0 ]
    [[ "$output" == *"$ROOT"* ]]
}

@test "an unknown command is rejected with the help text" {
    CLI frobnicate
    [ "$status" -ne 0 ]
    [[ "$output" == *"frobnicate"* ]]
    [[ "$output" == *"Usage: dotfiles"* ]]
}

@test "extra arguments after --help are rejected" {
    CLI --help unexpected
    [ "$status" -ne 0 ]
}

@test "each command group has its own help" {
    for c in packages links setup install status; do
        CLI "$c" --help
        [ "$status" -eq 0 ] || { echo "no help: $c"; false; }
        [[ "$output" == *"Usage: dotfiles $c"* ]] || { echo "bad help: $c"; false; }
    done
}

# ---- removed forms ----

@test "the old colon commands are rejected" {
    for c in pacman:install apps:install fonts:install setup:run aur:remove; do
        CLI "$c" --dry-run --yes
        [ "$status" -ne 0 ] || { echo "still accepted: $c"; false; }
        [[ "$output" == *"Unknown command"* ]] || { echo "not rejected as unknown: $c"; false; }
    done
}

@test "the old per-manager commands are rejected" {
    for c in pacman aur flatpak node sh apps; do
        CLI "$c" install --dry-run --yes
        [ "$status" -ne 0 ] || { echo "still accepted: $c install"; false; }
        [[ "$output" == *"Unknown command: $c"* ]] || { echo "not rejected as unknown: $c"; false; }
    done
}

@test "the old action flags are rejected" {
    CLI --status
    [ "$status" -ne 0 ]
    CLI --verify
    [ "$status" -ne 0 ]
}

@test "--only is no longer a flag" {
    CLI packages install --manager pacman --only bat --dry-run --yes
    [ "$status" -ne 0 ]
    [[ "$output" == *"Unknown option: --only"* ]]
}

# ---- packages ----

@test "packages install --manager pacman honors --group" {
    CLI packages install --manager pacman --group fonts --dry-run --yes
    [ "$status" -eq 0 ]
    [[ "$output" == *"ttf-meslo-nerd"* ]]
}

@test "packages install --manager=pacman also works" {
    CLI packages install --manager=pacman --group fonts --dry-run --yes
    [ "$status" -eq 0 ]
    [[ "$output" == *"ttf-meslo-nerd"* ]]
}

@test "packages install takes package names as arguments" {
    CLI packages install --manager pacman ripgrep fd --dry-run --yes
    [ "$status" -eq 0 ]
    [[ "$output" == *"ripgrep"* ]]
    [[ "$output" == *"fd"* ]]
    [[ "$output" != *"ttf-meslo-nerd"* ]]
}

@test "packages install without --manager runs every manager" {
    CLI packages install --dry-run --yes
    for kind in "Selected pacman" "Selected AUR" "Selected Flatpak" "Selected shell"; do
        [[ "$output" == *"$kind"* ]] || { echo "missing: $kind"; false; }
    done
}

@test "package names without --manager are rejected" {
    CLI packages install bat --dry-run --yes
    [ "$status" -ne 0 ]
    [[ "$output" == *"Package names need --manager"* ]]
}

@test "packages install rejects an unknown manager and lists the valid ones" {
    CLI packages install --manager apt
    [ "$status" -ne 0 ]
    [[ "$output" == *"apt"* ]]
    [[ "$output" == *"pacman, aur, flatpak, node, sh"* ]]
}

@test "--manager needs a value" {
    CLI packages install --manager
    [ "$status" -ne 0 ]
    [[ "$output" == *"--manager needs a value"* ]]
    CLI packages install --manager= --dry-run --yes
    [ "$status" -ne 0 ]
    [[ "$output" == *"--manager needs a value"* ]]
}

@test "packages remove needs --manager" {
    CLI packages remove bat
    [ "$status" -ne 0 ]
    [[ "$output" == *"--manager"* ]]
}

@test "packages remove needs package names" {
    CLI packages remove --manager pacman
    [ "$status" -ne 0 ]
    [[ "$output" == *"packages remove needs at least one package name"* ]]
}

@test "packages remove refuses the sh manager" {
    CLI packages remove --manager sh mise
    [ "$status" -ne 0 ]
    [[ "$output" == *"cannot remove with the sh manager"* ]]
}

@test "packages without an action shows its help and fails" {
    CLI packages
    [ "$status" -ne 0 ]
    [[ "$output" == *"Usage: dotfiles packages"* ]]
}

@test "fonts install previews the fonts group" {
    CLI fonts install --dry-run --yes
    [ "$status" -eq 0 ]
    [[ "$output" == *"ttf-meslo-nerd"* ]]
}

# ---- links, status, setup ----

@test "links create links every entry by default" {
    DCLI links create
    [ "$status" -eq 0 ]
    [ -L "$HOME/.sample" ]
}

@test "links create --files limits the run to the files section" {
    DCLI links create --files
    [ "$status" -eq 0 ]
    [ -L "$HOME/.sample" ]
}

@test "links verify works through the command line" {
    DCLI links create
    DCLI links verify
    [ "$status" -eq 0 ]
}

@test "links without an action shows its help and fails" {
    CLI links
    [ "$status" -ne 0 ]
    [[ "$output" == *"Usage: dotfiles links"* ]]
}

@test "links rejects extra arguments" {
    DCLI links create --files unexpected
    [ "$status" -ne 0 ]
    [[ "$output" == *"unexpected"* ]]
}

@test "status runs as a subcommand" {
    DCLI status
    [[ "$output" != *"Unknown"* ]]
}

@test "setup run without a name prints the new usage" {
    CLI setup run
    [ "$status" -ne 0 ]
    [[ "$output" == *"dotfiles setup run <name>"* ]]
}

@test "the bin README names every directory that status expects on PATH" {
    grep -Fq '$DOTFILES/bin:$DOTFILES/bin/sys:$DOTFILES/bin/utils:$DOTFILES/bin/git' "$ROOT/bin/README.md"
}
