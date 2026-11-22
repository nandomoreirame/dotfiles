#!/usr/bin/env bash
: "${DOTFILES:=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

# One column for every command row, so descriptions line up.
_help_row() { printf '  %-40s%s\n' "$1" "$2"; }

_help_options() {
    _help_row "--dry-run" "Print the commands without running them"
    _help_row "-y, --yes" "Answer yes to every confirmation"
    _help_row "--no-remote" "Skip downloads from remote installers"
    _help_row "--group <name>" "Use one group of the lists (for example fonts)"
}

_help_packages() {
    printf '%s\n' 'Usage: dotfiles packages install [--manager <m>] [options] [<names>...]' \
        '       dotfiles packages remove --manager <m> <names>...' ''
    _help_row "--manager <m>" "One of: pacman, aur, flatpak, node, sh"
    _help_row "" "Without it, install runs every manager, then langs"
    _help_row "" "remove accepts every manager except sh"
    _help_options
    _help_row "<names>" "Only these packages (needs --manager)"
}

_help_links() {
    printf '%s\n' 'Usage: dotfiles links create [--files|--paths]' \
        '       dotfiles links verify' ''
    _help_row "create" "Create every configured symbolic link"
    _help_row "create --files" "Link only the [files] entries"
    _help_row "create --paths" "Link only the [paths] entries ([paths:arch] on Arch)"
    _help_row "verify" "Report missing, broken and foreign links"
    printf '\n%s\n' 'Conflicting files are backed up. DOTFILES_YES=1 skips confirmations.'
}

_help_setup() {
    printf '%s\n' 'Usage: dotfiles setup [--dry-run]' \
        '       dotfiles setup run <name> [<args>...]' ''
    _help_row "setup" "Run every auto script from scripts/setup/registry.conf"
    _help_row "setup run <name> [<args>...]" "Run one registered script by name"
}

_help_install() {
    printf '%s\n' 'Usage: dotfiles install [options]' '' \
        'Run the new-machine flow: prerequisites, AUR helper, packages, fonts,' \
        'runtimes, links and setup. Each step asks first unless --yes is given.' ''
    _help_options
}

_help_status() {
    printf '%s\n' 'Usage: dotfiles status' '' \
        'Check links, PATH, environment variables, packages and the active profile.'
}

_help_profile() {
    printf '%s\n' 'Usage: dotfiles profile <action> [<name>]' ''
    _help_row "list" "List Git identity short names"
    _help_row "show [<name>]" "Show the active (or named) identity"
    _help_row "switch <name>" "Switch Git identity (and gcloud when configured)"
    _help_row "validate [<name>]" "Validate an identity profile file"
    _help_row "create|edit|delete <name>" "Manage a directory-based profile"
    _help_row "export <name> [<file>]" "Export a directory-based profile"
    _help_row "import <file>" "Import a directory-based profile"
}

_help_hooks() {
    printf '%s\n' 'Usage: dotfiles hooks enable [guard] [strip] | disable | status' ''
    _help_row "enable [guard] [strip]" "Turn on the opt-in Git hooks"
    _help_row "disable" "Turn off the opt-in Git hooks"
    _help_row "status" "Show the guard and strip hook state"
}

# _help [topic]: the overview, or the help of one command group.
_help() {
    case "${1:-}" in
        packages|links|setup|install|status|profile|hooks)
            "_help_$1"
            return
            ;;
    esac
    printf '%s\n' 'Usage: dotfiles <command> [options]' '' 'Install'
    _help_row "install [options]" "Run the new-machine install flow"
    _help_row "packages install [--manager <m>]" "Install from packages/<manager>.list"
    _help_row "packages remove --manager <m> <names>" "Remove packages by name"
    _help_row "langs install" "Install languages from configs/mise/config.toml"
    _help_row "fonts install" "Install the pacman fonts group"
    _help_row "setup" "Run the auto setup scripts"
    _help_row "setup run <name>" "Run one setup script by name"
    printf '\n%s\n' 'Configure'
    _help_row "links create [--files|--paths]" "Create the configured symbolic links"
    _help_row "links verify" "Report missing, broken and foreign links"
    _help_row "init" "Write the local Git identity to ~/.gitconfig.local"
    _help_row "profile <action>" "Manage Git identity profiles"
    _help_row "hooks enable|disable|status" "Manage the opt-in Git hooks"
    printf '\n%s\n' 'Check'
    _help_row "status" "Check links, PATH and environment variables"
    _help_row "doctor" "Check prerequisites, links, packages and identity"
    printf '\n%s\n' 'Options'
    _help_row "-h, --help" "Show this help"
    _help_row "-V, --version" "Print the version"
    printf '\n'
    printf '%s\n' 'Managers: pacman, aur, flatpak, node, sh' \
        'Install options: --dry-run, -y/--yes, --no-remote, --group <name>' \
        'Run dotfiles <command> --help for the options of one command.'
}
