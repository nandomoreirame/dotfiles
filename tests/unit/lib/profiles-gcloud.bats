#!/usr/bin/env bats

# GCloud / Firebase profile module.

setup() {
    ROOT="$(cd "$BATS_TEST_DIRNAME/../../.." && pwd)"
    export HOME="$BATS_TEST_TMPDIR/home" DOTFILES="$BATS_TEST_TMPDIR/dot"
    mkdir -p "$HOME" "$DOTFILES/profiles/linux-arch" "$DOTFILES/lib" "$DOTFILES/lib/profiles"
    cp -r "$ROOT/lib/." "$DOTFILES/lib/"
    STUBS="$BATS_TEST_TMPDIR/stubs"
    LOG="$BATS_TEST_TMPDIR/calls"
    mkdir -p "$STUBS"
    : > "$LOG"
    cat > "$STUBS/gcloud" <<EOF
#!/bin/sh
echo "gcloud \$*" >> "$LOG"
case "\$*" in
  auth\ list*) printf '%s\n' "jane@example.com" ;;
esac
exit 0
EOF
    chmod +x "$STUBS/gcloud"
    export STUBS LOG
}

@test "switching gcloud activates the matching configuration" {
    printf 'GCLOUD_ACCOUNT_NAME="Jane Dev"\nGCLOUD_ACCOUNT="jane@example.com"\nGCLOUD_PROJECTS=(\n  "your-project-id|Example Project"\n)\n' \
        > "$DOTFILES/profiles/linux-arch/gcloud-personal.conf"
    run env -i HOME="$HOME" PATH="$STUBS:/usr/bin:/bin" DOTFILES="$DOTFILES" DOTFILES_YES=1 bash -c \
        "source '$DOTFILES/lib/profiles.sh'; profile_switch_gcloud personal"
    [ "$status" -eq 0 ]
    grep -q "config configurations activate" "$LOG"
    grep -q "your-project-id" "$LOG"
}

@test "gcloud missing is reported without failing the whole switch" {
    printf 'GCLOUD_ACCOUNT_NAME="Jane Dev"\nGCLOUD_ACCOUNT="jane@example.com"\nGCLOUD_PROJECTS=(\n  "your-project-id|Example Project"\n)\n' \
        > "$DOTFILES/profiles/linux-arch/gcloud-personal.conf"
    run env -i HOME="$HOME" PATH="/usr/bin:/bin" DOTFILES="$DOTFILES" DOTFILES_YES=1 bash -c \
        "source '$DOTFILES/lib/profiles.sh'; profile_switch_gcloud personal"
    [[ "$output" == *"gcloud"* ]]
}

@test "the gcloud module never runs an interactive login on its own" {
    run grep -nE "auth login|application-default login" "$ROOT/lib/profiles/gcloud.sh"
    [ "$status" -ne 0 ]
}

@test "_profile_list_gcloud_configs: lists gcloud*.conf files" {
    mkdir -p "$DOTFILES/profiles/demo"
    printf 'GCLOUD_ACCOUNT="a@example.com"\n' > "$DOTFILES/profiles/demo/gcloud-personal.conf"
    printf 'GCLOUD_ACCOUNT="b@example.com"\n' > "$DOTFILES/profiles/demo/gcloud-work.conf"
    run env -i HOME="$HOME" PATH="/usr/bin:/bin" DOTFILES="$DOTFILES" bash -c \
        "source '$DOTFILES/lib/profiles.sh'; _profile_list_gcloud_configs demo"
    [ "$status" -eq 0 ]
    [[ "$output" == *"gcloud-personal.conf"* ]]
    [[ "$output" == *"gcloud-work.conf"* ]]
}

@test "profile_switch_gcloud_config delegates to profile_switch_gcloud" {
    printf 'GCLOUD_ACCOUNT_NAME="Jane Dev"\nGCLOUD_ACCOUNT="jane@example.com"\nGCLOUD_PROJECTS=(\n  "your-project-id|Example Project"\n)\n' \
        > "$DOTFILES/profiles/linux-arch/gcloud-personal.conf"
    run env -i HOME="$HOME" PATH="$STUBS:/usr/bin:/bin" DOTFILES="$DOTFILES" DOTFILES_YES=1 bash -c \
        "source '$DOTFILES/lib/profiles.sh'; profile_switch_gcloud_config personal"
    [ "$status" -eq 0 ]
    grep -q "your-project-id" "$LOG"
}
