#!/usr/bin/env bash
: "${DOTFILES:=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"



validate_args_count() {
    local required=$1
    local provided=$2
    local script_name=${3:-"script"}

    if [ "$provided" -lt "$required" ]; then
        echo "❌ Error: insufficient arguments"
        echo "   Required: $required"
        echo "   Provided: $provided"
        echo ""
        echo "   Use: $script_name --help"
        return 1
    fi
    return 0
}

validate_not_empty() {
    local value="$1"
    local name="$2"

    if [ -z "$value" ]; then
        echo "❌ Error: $name cannot be empty"
        return 1
    fi
    return 0
}

validate_pattern() {
    local value="$1"
    local pattern="$2"
    local name="$3"

    if ! [[ "$value" =~ $pattern ]]; then
        echo "❌ Error: invalid $name: '$value'"
        echo "   Must match pattern: $pattern"
        return 1
    fi
    return 0
}

validate_option() {
    local value="$1"
    shift
    local valid_options=("$@")

    for option in "${valid_options[@]}"; do
        if [ "$value" = "$option" ]; then
            return 0
        fi
    done

    echo "❌ Error: invalid option: '$value'"
    echo "   Valid options: ${valid_options[*]}"
    return 1
}


validate_directory() {
    local dir="$1"
    local name="${2:-directory}"

    if [ ! -d "$dir" ]; then
        echo "❌ Error: $name not found"
        echo "   Path: $dir"
        return 1
    fi
    return 0
}

validate_file() {
    local file="$1"
    local name="${2:-file}"

    if [ ! -f "$file" ]; then
        echo "❌ Error: $name not found"
        echo "   Path: $file"
        return 1
    fi
    return 0
}

validate_read_permission() {
    local path="$1"

    if [ ! -r "$path" ]; then
        echo "❌ Error: no read permission"
        echo "   Path: $path"
        return 1
    fi
    return 0
}

validate_write_permission() {
    local path="$1"

    if [ ! -w "$path" ]; then
        echo "❌ Error: no write permission"
        echo "   Path: $path"
        echo ""
        echo "   Try: sudo chmod u+w $path"
        return 1
    fi
    return 0
}

validate_symlink() {
    local link="$1"

    if [ ! -L "$link" ]; then
        echo "❌ Error: not a symbolic link"
        echo "   Path: $link"
        return 1
    fi
    return 0
}

validate_symlink_not_broken() {
    local link="$1"

    if [ -L "$link" ] && [ ! -e "$link" ]; then
        echo "❌ Error: broken symbolic link"
        echo "   Link: $link"
        echo "   Points to: $(readlink "$link")"
        return 1
    fi
    return 0
}


_dotfiles_install_hint_prefix() {
    echo "sudo pacman -S"
}

_dotfiles_install_hint_command() {
    local cmd="$1"
    echo "$(_dotfiles_install_hint_prefix) $cmd"
}

_dotfiles_install_hint_many() {
    local commands=("$@")
    local prefix
    local IFS=' '

    prefix=$(_dotfiles_install_hint_prefix)
    echo "$prefix ${commands[*]}"
}

validate_command() {
    local cmd="$1"
    local install_hint

    if [ -n "${2:-}" ]; then
        install_hint="$2"
    else
        install_hint=$(_dotfiles_install_hint_command "$cmd")
    fi

    if ! command -v "$cmd" &> /dev/null; then
        echo "❌ Error: command '$cmd' not found"
        echo "   Install with: $install_hint"
        return 1
    fi
    return 0
}

validate_commands() {
    local missing=()

    for cmd in "$@"; do
        if ! command -v "$cmd" &> /dev/null; then
            missing+=("$cmd")
        fi
    done

    if [ ${#missing[@]} -gt 0 ]; then
        echo "❌ Missing dependencies: ${missing[*]}"
        echo "   Install with: $(_dotfiles_install_hint_many "${missing[@]}")"
        return 1
    fi
    return 0
}

validate_command_version() {
    local cmd="$1"
    local min_version="$2"

    if ! command -v "$cmd" &> /dev/null; then
        echo "❌ Error: command '$cmd' not found"
        return 1
    fi

    local current_version
    current_version=$("$cmd" --version 2>&1 | head -n1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n1)

    if [ -z "$current_version" ]; then
        echo "⚠️  Warning: could not determine version of $cmd"
        return 0
    fi

    if [ "$(printf '%s\n' "$min_version" "$current_version" | sort -V | head -n1)" != "$min_version" ]; then
        echo "❌ Error: $cmd version is too old"
        echo "   Minimum: $min_version"
        echo "   Current: $current_version"
        return 1
    fi

    return 0
}


validate_git_repo() {
    if ! git rev-parse --is-inside-work-tree &> /dev/null; then
        echo "❌ Error: not a Git repository"
        echo "   Run: git init"
        return 1
    fi
    return 0
}

validate_git_branch() {
    local branch="$1"

    validate_git_repo || return 1

    if ! git show-ref --verify --quiet "refs/heads/$branch"; then
        echo "❌ Error: branch '$branch' does not exist"
        echo "   Available branches:"
        git branch | sed 's/^/   /'
        return 1
    fi
    return 0
}

validate_git_clean() {
    validate_git_repo || return 1

    if ! git diff-index --quiet HEAD --; then
        echo "⚠️  Warning: uncommitted changes exist"
        echo ""
        git status --short | sed 's/^/   /'
        echo ""
        read -r -p "Continue anyway? (y/n): " answer
        case ${answer:0:1} in
            y|Y) return 0 ;;
            *) return 1 ;;
        esac
    fi
    return 0
}


validate_env_var() {
    local var_name="$1"

    if [ -z "${!var_name}" ]; then
        echo "❌ Error: environment variable '$var_name' is not set"
        return 1
    fi
    return 0
}

validate_os() {
    local supported=("$@")
    local current_os

    if [ -f /etc/os-release ]; then
        current_os=$(grep "^ID=" /etc/os-release | cut -d= -f2 | tr -d '"')
    else
        echo "❌ Error: could not detect operating system"
        return 1
    fi

    for os in "${supported[@]}"; do
        if [ "$current_os" = "$os" ]; then
            return 0
        fi
    done

    echo "❌ Error: unsupported operating system: $current_os"
    echo "   Supported: ${supported[*]}"
    return 1
}

validate_is_root() {
    if [ "$EUID" -ne 0 ]; then
        echo "❌ Error: this script requires root privileges"
        echo "   Run with: sudo $0"
        return 1
    fi
    return 0
}

validate_not_root() {
    if [ "$EUID" -eq 0 ]; then
        echo "❌ Error: this script must not run as root"
        echo "   Run without sudo"
        return 1
    fi
    return 0
}

validate_internet_connection() {
    if ! ping -c 1 8.8.8.8 &> /dev/null; then
        echo "❌ Error: no internet connection"
        echo "   Check your connection and try again"
        return 1
    fi
    return 0
}


validate_dotfiles_environment() {
    if ! validate_env_var "DOTFILES"; then
        echo "   Configure in your shell environment:"
        echo "   export DOTFILES=\"/path/to/clone\""
        return 1
    fi

    if ! validate_directory "$DOTFILES" "dotfiles directory"; then
        return 1
    fi

    local required_dirs=("bin" "lib")
    local missing_dirs=()

    for dir in "${required_dirs[@]}"; do
        if [ ! -d "$DOTFILES/$dir" ]; then
            missing_dirs+=("$dir")
        fi
    done

    if [ ${#missing_dirs[@]} -gt 0 ]; then
        echo "❌ Error: incomplete dotfiles structure"
        echo "   Missing directories: ${missing_dirs[*]}"
        return 1
    fi

    return 0
}

validate_git_flow_requirements() {
    validate_git_repo || return 1
    validate_command "git" "sudo pacman -S git" || return 1
    validate_command "git-flow" "yay -S gitflow-avh" || return 1
    return 0
}

