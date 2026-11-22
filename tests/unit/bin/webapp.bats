#!/usr/bin/env bats

# Unit tests for bin/utils/webapp: one command with install, list, remove,
# launch and browser subcommands. The command follows clig.dev: help on -h and
# per subcommand, usage errors exit 2, no prompt without a TTY, no color when
# output is not a terminal or NO_COLOR is set, and -- passes browser arguments.

load '../../bats/helpers/setup'
bats_require_minimum_version 1.5.0

SCRIPT="$PROJECT_ROOT/bin/utils/webapp"

setup() {
    TEST_DIR="$(temp_make)"
    STUB_DIR="$TEST_DIR/stubs"
    export HOME="$TEST_DIR/home"
    export XDG_CONFIG_HOME="$TEST_DIR/config"
    # Hermetic system data dirs: keep the XDG spec default from leaking host browsers in.
    export XDG_DATA_DIRS="$TEST_DIR/xdg-data"
    APPS="$HOME/.local/share/applications"
    mkdir -p "$APPS/icons" "$STUB_DIR" "$XDG_CONFIG_HOME/webappbar" "$XDG_DATA_DIRS/applications"
    export PATH="$STUB_DIR:/usr/bin:/bin"
    # BASH_ENV would source ~/.bashrc (mise activation) in every child bash.
    unset WEBAPP_BROWSER BASH_ENV

    cat > "$STUB_DIR/curl" <<'STUB'
#!/usr/bin/env bash
# Never touch the network: write one byte to the -o target.
while (($#)); do
    case "$1" in -o) shift; printf 'x' > "$1" ;; esac
    shift
done
STUB
    printf '#!/usr/bin/env bash\nexit 0\n' > "$STUB_DIR/update-desktop-database"
    printf '#!/usr/bin/env bash\ncat\n' > "$STUB_DIR/fzf"
    cat > "$STUB_DIR/xdg-settings" <<'STUB'
#!/usr/bin/env bash
[[ "$1" == "get" && "$2" == "default-web-browser" ]] || exit 2
[[ -n "${FAKE_XDG_ID:-}" ]] || exit 1
printf '%s\n' "$FAKE_XDG_ID"
STUB
    cat > "$STUB_DIR/chromium" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' "$@" > "$FAKE_ARGV_FILE"
STUB
    chmod +x "$STUB_DIR"/*
    export FAKE_ARGV_FILE="$TEST_DIR/argv"
}

teardown() {
    temp_del "$TEST_DIR"
}

# ---- command surface ----

@test "no arguments prints the usage on stderr and exits 2" {
    run --separate-stderr "$SCRIPT"
    [ "$status" -eq 2 ]
    [[ "$stderr" == *"Usage: webapp <command>"* ]]
}

@test "--help lists every command and exits 0" {
    run "$SCRIPT" --help
    [ "$status" -eq 0 ]
    for c in install list remove launch browser; do
        [[ "$output" == *"  $c"* ]] || { echo "missing: $c"; false; }
    done
    [[ "$output" == *"webapp <command> --help"* ]]
}

@test "each command has its own help" {
    for c in install list remove launch browser; do
        run "$SCRIPT" "$c" --help
        [ "$status" -eq 0 ] || { echo "no help: $c"; false; }
        [[ "$output" == *"Usage: webapp $c"* ]] || { echo "bad help: $c"; false; }
    done
}

@test "an unknown command is a usage error that names the valid ones" {
    run --separate-stderr "$SCRIPT" instal
    [ "$status" -eq 2 ]
    [[ "$stderr" == *"unknown command 'instal'"* ]]
    [[ "$stderr" == *"install"* ]]
}

@test "--version prints the version" {
    run "$SCRIPT" --version
    [ "$status" -eq 0 ]
    [[ "$output" =~ ^webapp\ [0-9]+\.[0-9]+\.[0-9]+$ ]]
}

@test "output carries no color codes when it is not a terminal" {
    run "$SCRIPT" list
    [[ "$output" != *$'\033['* ]]
}

@test "the old per-action scripts are gone" {
    for old in webapp-install webapp-browser webapp-remove webapp-launch; do
        [ ! -e "$PROJECT_ROOT/bin/utils/$old" ] || { echo "still there: $old"; false; }
    done
}

# ---- install ----

@test "install writes a managed entry with a direct Exec" {
    export WEBAPP_BROWSER=brave-browser
    run "$SCRIPT" install "YouTube Music" music.youtube.com
    [ "$status" -eq 0 ]
    entry="$APPS/YouTube Music.desktop"
    [ -f "$entry" ]
    grep -q '^Exec="brave-browser" --app="https://music.youtube.com"$' "$entry"
    grep -q '^X-Webappbar-Id=YouTube Music$' "$entry"
    grep -q '^X-Webappbar-Url=https://music.youtube.com$' "$entry"
    grep -q '^X-Webappbar-Browser=brave-browser$' "$entry"
    grep -q '^Icon=.*/icons/YouTube Music.png$' "$entry"
}

@test "install --icon keeps a local icon reference" {
    run "$SCRIPT" install Gmail mail.google.com --icon gmail.png
    [ "$status" -eq 0 ]
    grep -q '^Icon=.*/applications/icons/gmail.png$' "$APPS/Gmail.desktop"
}

@test "install --icon=<url> downloads the icon" {
    run "$SCRIPT" install Mail mail.example --icon=https://icons.example/mail.png
    [ "$status" -eq 0 ]
    [ -s "$APPS/icons/Mail.png" ]
}

@test "install --exec and --mime override the entry" {
    run "$SCRIPT" install Viewer viewer.example --exec "viewer %U" --mime "image/png;"
    [ "$status" -eq 0 ]
    grep -q '^Exec=viewer %U$' "$APPS/Viewer.desktop"
    grep -q '^MimeType=image/png;$' "$APPS/Viewer.desktop"
}

@test "install escapes percent in Exec but keeps the raw URL in the marker" {
    export WEBAPP_BROWSER=chromium
    run "$SCRIPT" install "Search" "https://a.example/?q=50%25"
    [ "$status" -eq 0 ]
    grep -q '^Exec="chromium" --app="https://a.example/?q=50%%25"$' "$APPS/Search.desktop"
    grep -q '^X-Webappbar-Url=https://a.example/?q=50%25$' "$APPS/Search.desktop"
}

@test "install honors XDG_DATA_HOME" {
    export XDG_DATA_HOME="$TEST_DIR/xdg-data-home" WEBAPP_BROWSER=chromium
    mkdir -p "$XDG_DATA_HOME"
    run "$SCRIPT" install "XDG App" https://xdg.example
    [ "$status" -eq 0 ]
    [ -f "$XDG_DATA_HOME/applications/XDG App.desktop" ]
    [ ! -f "$APPS/XDG App.desktop" ]
}

# Drives the interactive install through a pseudo-terminal (util-linux script).
# The curl stub logs every URL it is asked to fetch.
run_interactive_install() {
    command -v script >/dev/null || skip "script (util-linux) not installed"
    cat > "$STUB_DIR/curl" <<'STUB'
#!/usr/bin/env bash
out=""
for a in "$@"; do case "$prev" in -o) out="$a" ;; esac; prev="$a"; done
printf '%s\n' "${@: -1}" >> "$CURL_LOG"
[ -n "$out" ] && printf 'x' > "$out"
STUB
    chmod +x "$STUB_DIR/curl"
    export CURL_LOG="$TEST_DIR/curl.log" WEBAPP_BROWSER=chromium
    run bash -c "printf '$1' | script -qec '$SCRIPT install' /dev/null"
}

@test "interactive install asks for the icon and uses the site favicon when it is empty" {
    run_interactive_install 'Demo\ndemo.example\n\n'
    [[ "$output" == *"Icon"* ]]
    grep -q 'google.com/s2/favicons?domain=https://demo.example' "$CURL_LOG"
    grep -q '^Icon=.*/icons/Demo.png$' "$APPS/Demo.desktop"
}

@test "interactive install downloads the icon URL it is given" {
    run_interactive_install 'Demo\ndemo.example\nhttps://icons.example/demo.png\n'
    grep -qx 'https://icons.example/demo.png' "$CURL_LOG"
    run grep -q 'favicons' "$CURL_LOG"
    [ "$status" -ne 0 ]
    grep -q '^Icon=.*/icons/Demo.png$' "$APPS/Demo.desktop"
}

@test "install without a TTY and without a name and URL never prompts" {
    run --separate-stderr "$SCRIPT" install </dev/null
    [ "$status" -eq 2 ]
    [[ "$stderr" == *"needs <name> and <url>"* ]]
}

@test "install rejects an empty name" {
    run "$SCRIPT" install "" "https://x.dev"
    [ "$status" -ne 0 ]
}

@test "install rejects an unknown option and a third positional argument" {
    run "$SCRIPT" install App app.example --nope
    [ "$status" -eq 2 ]
    run "$SCRIPT" install App app.example extra
    [ "$status" -eq 2 ]
}

@test "install rejects unsafe names" {
    export WEBAPP_BROWSER=chromium
    local id
    for id in '../Evil' 'Evil/Name' $'Bad\nName' '.Hidden'; do
        run "$SCRIPT" install "$id" https://evil.example
        [ "$status" -ne 0 ]
        [ ! -e "$APPS/$id.desktop" ]
        [ ! -e "$HOME/.local/share/Evil.desktop" ]
    done
}

@test "install rejects unsafe local icon paths" {
    printf 'x' > "$TEST_DIR/outside.png"
    run "$SCRIPT" install SafeApp https://safe.example --icon '../outside.png'
    [ "$status" -ne 0 ]
    [ ! -f "$APPS/SafeApp.desktop" ]
}

# ---- list ----

@test "list separates managed, legacy and chrome entries" {
    printf '[Desktop Entry]\nName=Mine\nExec="chromium" --app="https://a.example"\nX-Webappbar-Id=Mine\n' > "$APPS/Mine.desktop"
    printf '[Desktop Entry]\nName=Old\nExec=$HOME/bin/webapp-launch https://b.example\n' > "$APPS/Old.desktop"
    printf '[Desktop Entry]\nName=Pwa\nExec=/usr/bin/google-chrome --app-id=abcdef\n' > "$APPS/chrome-abcdef-Default.desktop"
    run "$SCRIPT" list
    [ "$status" -eq 0 ]
    [[ "$output" == *"[webapp]"*"Mine"* ]]
    [[ "$output" == *"[legacy]"*"Old"* ]]
    [[ "$output" == *"[chrome]"*"Pwa"* ]]
    # Only the kind and the name: no Exec line, URL or app id.
    [[ "$output" != *"--app"* ]]
    [[ "$output" != *"app-id"* ]]
    [[ "$output" != *"https://"* ]]
}

# ---- remove ----

remove_fixture() {
    printf 'x' > "$APPS/icons/Mine.png"
    printf '[Desktop Entry]\nName=Mine\nExec="chromium" --app="https://a.example"\nX-Webappbar-Id=Mine\n' > "$APPS/Mine.desktop"
    printf '[Desktop Entry]\nName=Pwa\nExec=/usr/bin/google-chrome --app-id=abc\n' > "$APPS/chrome-abc-Default.desktop"
}

@test "remove deletes a managed entry and its icon by name" {
    remove_fixture
    run "$SCRIPT" remove Mine
    [ "$status" -eq 0 ]
    [ ! -f "$APPS/Mine.desktop" ]
    [ ! -f "$APPS/icons/Mine.png" ]
    [[ "$output" == *"Removed Mine"* ]]
}

@test "remove without names picks managed entries through fzf" {
    remove_fixture
    run "$SCRIPT" remove
    [ "$status" -eq 0 ]
    [ ! -f "$APPS/Mine.desktop" ]
}

@test "remove deletes a legacy entry" {
    printf 'x' > "$APPS/icons/Old.png"
    printf '[Desktop Entry]\nName=Old\nExec=/usr/bin/webapp-launch https://old.example\n' > "$APPS/Old.desktop"
    run "$SCRIPT" remove Old
    [ "$status" -eq 0 ]
    [ ! -f "$APPS/Old.desktop" ]
    [ ! -f "$APPS/icons/Old.png" ]
}

@test "remove warns instead of deleting a chrome PWA" {
    remove_fixture
    run "$SCRIPT" remove Pwa
    [ -f "$APPS/chrome-abc-Default.desktop" ]
    [[ "$output" == *"chrome://apps"* ]]
}

@test "remove keeps an unrelated entry and reports a failure" {
    printf 'x' > "$APPS/icons/Other.png"
    printf '[Desktop Entry]\nName=Other\nExec=/usr/bin/other\n' > "$APPS/Other.desktop"
    run "$SCRIPT" remove Other
    [ "$status" -eq 1 ]
    [ -f "$APPS/Other.desktop" ]
    [ -f "$APPS/icons/Other.png" ]
    [[ "$output" == *"No web app named 'Other' found"* ]]
}

@test "remove rejects unsafe names without deleting files" {
    remove_fixture
    printf '[Desktop Entry]\nName=Outside\nX-Webappbar-Id=../Outside\n' > "$HOME/.local/share/Outside.desktop"
    local id
    for id in '../Outside' '.Mine' 'Mine\Other' $'Mine\nOther'; do
        run "$SCRIPT" remove "$id"
        [[ "$output" == *"No web app named"* ]]
    done
    [ -f "$HOME/.local/share/Outside.desktop" ]
    [ -f "$APPS/Mine.desktop" ]
}

# ---- launch ----

@test "launch opens app mode and passes the arguments after --" {
    export WEBAPP_BROWSER=chromium
    run "$SCRIPT" launch https://music.youtube.com -- --new-window
    [ "$status" -eq 0 ]
    [ "$(sed -n 1p "$FAKE_ARGV_FILE")" = "--app=https://music.youtube.com" ]
    [ "$(sed -n 2p "$FAKE_ARGV_FILE")" = "--new-window" ]
}

@test "launch requires a URL" {
    run --separate-stderr "$SCRIPT" launch
    [ "$status" -eq 2 ]
    [[ "$stderr" == *"Usage: webapp launch"* ]]
}

# ---- browser ----

@test "browser: the env var wins over everything" {
    export WEBAPP_BROWSER=brave-browser FAKE_XDG_ID=google-chrome.desktop
    run "$SCRIPT" browser
    [ "$status" -eq 0 ]
    [ "$output" = "brave-browser" ]
}

@test "browser: the config file decides when the env var is unset" {
    printf 'vivaldi-stable\n' > "$XDG_CONFIG_HOME/webappbar/browser"
    export FAKE_XDG_ID=google-chrome.desktop
    run "$SCRIPT" browser get
    [ "$output" = "vivaldi-stable" ]
}

@test "browser: falls back to the xdg default when it is a Chromium family" {
    export FAKE_XDG_ID=google-chrome.desktop
    run "$SCRIPT" browser get
    [ "$output" = "google-chrome" ]
}

@test "browser: ignores a non-Chromium default and picks the first installed" {
    export FAKE_XDG_ID=firefox.desktop
    printf '[Desktop Entry]\nExec=/usr/bin/chromium %%U\n' > "$XDG_DATA_DIRS/applications/chromium.desktop"
    printf '[Desktop Entry]\nExec=/usr/bin/google-chrome %%U\n' > "$XDG_DATA_DIRS/applications/google-chrome.desktop"
    run "$SCRIPT" browser get
    [ "$output" = "google-chrome" ]
}

@test "browser: falls back to chromium when nothing is installed" {
    export FAKE_XDG_ID=firefox.desktop
    run "$SCRIPT" browser get
    [ "$output" = "chromium" ]
}

@test "browser: a custom binary in the config file is used verbatim" {
    printf '/opt/thorium/thorium\n' > "$XDG_CONFIG_HOME/webappbar/browser"
    run "$SCRIPT" browser get
    [ "$output" = "/opt/thorium/thorium" ]
    run "$SCRIPT" browser exec
    [ "$output" = "/opt/thorium/thorium" ]
}

@test "browser set writes the config file and browser list reports installed ids" {
    run "$SCRIPT" browser set brave-browser
    [ "$status" -eq 0 ]
    [ "$(cat "$XDG_CONFIG_HOME/webappbar/browser")" = "brave-browser" ]
    printf '[Desktop Entry]\nExec=/usr/bin/brave-browser %%U\n' > "$APPS/brave-browser.desktop"
    run "$SCRIPT" browser list
    [ "$output" = "brave-browser" ]
}

@test "browser id prints the desktop id" {
    export WEBAPP_BROWSER=vivaldi
    run "$SCRIPT" browser id
    [ "$output" = "vivaldi-stable" ]
}

@test "browser exec maps a PATH-less name through its desktop Exec line" {
    printf '[Desktop Entry]\nExec=/usr/bin/google-chrome-stable %%U\n' > "$XDG_DATA_DIRS/applications/google-chrome.desktop"
    export FAKE_XDG_ID=google-chrome.desktop
    run "$SCRIPT" browser exec
    [ "$output" = "/usr/bin/google-chrome-stable" ]
}

@test "browser exec keeps a binary on PATH and falls back to the logical name" {
    export WEBAPP_BROWSER=chromium
    run "$SCRIPT" browser exec
    [ "$output" = "chromium" ]
    export WEBAPP_BROWSER=brave-browser
    run "$SCRIPT" browser exec
    [ "$output" = "brave-browser" ]
}

@test "browser rejects an unknown action" {
    run "$SCRIPT" browser --nope
    [ "$status" -eq 2 ]
}
