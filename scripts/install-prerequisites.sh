#!/usr/bin/env bash

if [ -z "${BASH_VERSION:-}" ]; then
    printf '%s\n' '[FAIL] Run ./scripts/install-prerequisites.sh with Bash.' >&2
    return 2 2>/dev/null || exit 2
fi

INSTALL_SCRIPTS="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
source "$INSTALL_SCRIPTS/check-prerequisites.sh"

NVM_INSTALL_VERSION=v0.41.0

can_prompt() {
    [[ -t 0 && -t 1 && -z "${CI:-}" ]]
}

confirm_install() {
    local answer
    can_prompt || return 1
    printf '%s\n' "$1"
    read -r -p 'Continue? [y/N] ' answer || return 1
    [[ "$answer" == y || "$answer" == Y ]]
}

run_remote_installer() {
    local url="$1" privilege="$2" interpreter="$3" temporary directory status
    shift 3
    command -v curl >/dev/null 2>&1 || { workshop_status_printf '%s\n' '[FAIL] curl is required.' >&2; return 1; }
    directory=$(mktemp -d "${TMPDIR:-/tmp}/workshop-installer.XXXXXX") || return 1
    temporary="$directory/install"
    if ! curl --fail --location --silent --show-error --proto '=https' --proto-redir '=https' --output "$temporary" "$url"; then
        rm -rf -- "$directory"
        workshop_status_printf '[FAIL] Could not download the installer script: %s\n' "$url" >&2
        return 1
    fi
    status=0
    if [[ "$privilege" == sudo ]]; then
        sudo env "$@" "$interpreter" "$temporary" || status=$?
    else
        env "$@" "$interpreter" "$temporary" || status=$?
    fi
    rm -rf -- "$directory"
    return "$status"
}

ensure_homebrew() {
    local environment
    if command -v brew >/dev/null 2>&1; then return 0; fi
    if ! confirm_install 'Homebrew: Run the official installer. Network access and administrator privileges are required; Xcode Command Line Tools may be installed. Source: https://brew.sh'; then
        workshop_status_printf '%s\n' '[FAIL] Homebrew installation was not approved; skipping tools that depend on Homebrew.' >&2; return 1
    fi
    if ! run_remote_installer 'https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh' user /bin/bash; then
        workshop_status_printf '%s\n' '[FAIL] Homebrew installation failed.' >&2; return 1
    fi
    if [[ -x /opt/homebrew/bin/brew ]]; then environment=$(/opt/homebrew/bin/brew shellenv)
    elif [[ -x /usr/local/bin/brew ]]; then environment=$(/usr/local/bin/brew shellenv); fi
    [[ -n "${environment:-}" ]] && eval "$environment"
    if ! brew --version >/dev/null; then workshop_status_printf '%s\n' '[FAIL] Could not verify that Homebrew runs.' >&2; return 1; fi
    workshop_status_printf '[MANUAL] Add this command to your shell profile: eval "$(%s shellenv)"\n' "$(command -v brew)"
}

ensure_apt() {
    if command -v apt-get >/dev/null 2>&1 && command -v sudo >/dev/null 2>&1; then return 0; fi
    workshop_status_printf '[MANUAL] %s: apt-get and sudo are required for automatic installation. Install it manually.\n' "$1"
    return 1
}

apt_install() {
    local tool="$1"
    shift
    ensure_apt "$tool" || return 1
    if ! confirm_install "$tool: Install the APT packages $* with sudo. Network access is required and system packages will change."; then return 0; fi
    if ! sudo apt-get update || ! sudo apt-get install -y "$@"; then
        workshop_status_printf '[FAIL] %s installation failed.\n' "$tool" >&2; return 1
    fi
}

brew_install() {
    local tool="$1"
    shift
    if ! confirm_install "$tool: Run brew install $*. Network access is required and Homebrew packages will change."; then return 0; fi
    if ! brew install "$@"; then workshop_status_printf '[FAIL] %s installation failed.\n' "$tool" >&2; return 1; fi
}

load_nvm() {
    export NVM_DIR
    NVM_DIR=$(nvm_directory)
    if [[ ! -s "$NVM_DIR/nvm.sh" ]] || ! source "$NVM_DIR/nvm.sh" --no-use || [[ $(type -t nvm) != function ]]; then
        workshop_status_printf '[FAIL] Failed to initialize nvm: %s\n' "$NVM_DIR" >&2; return 1
    fi
}

install_nvm() {
    local nvm_dir
    nvm_dir=$(nvm_directory)
    if [[ -s "$nvm_dir/nvm.sh" ]]; then
        workshop_status_printf '[INFO] nvm: Found in %s.\n' "$nvm_dir"
        return 0
    fi
    if [[ -e "$nvm_dir" || -L "$nvm_dir" ]]; then
        workshop_status_printf '[FAIL] nvm.sh is missing from the nvm path. The existing path will not be changed: %s\n' "$nvm_dir" >&2
        return 1
    fi
    if ! confirm_install "nvm: Run the official $NVM_INSTALL_VERSION installer in $nvm_dir. Network access is required and your shell profile will change. Source: https://github.com/nvm-sh/nvm"; then
        workshop_status_printf '%s\n' '[WARN] nvm installation was not approved; Node.js will not be installed.'
        return 1
    fi
    mkdir -p "$nvm_dir" || { workshop_status_printf '[FAIL] Could not create %s.\n' "$nvm_dir" >&2; return 1; }
    if ! run_remote_installer "https://raw.githubusercontent.com/nvm-sh/nvm/$NVM_INSTALL_VERSION/install.sh" user bash NVM_DIR="$nvm_dir" NODE_VERSION= PROFILE="${PROFILE:-}"; then
        workshop_status_printf '%s\n' '[FAIL] nvm installation failed.' >&2; return 1
    fi
}

install_node() {
    local latest current='' node_path
    node_path=$(tool_path node)
    if [[ -n "$node_path" ]]; then current=$(node --version 2>/dev/null); fi
    install_nvm || return 1
    load_nvm || return 1
    latest=$(nvm version-remote "$WORKSHOP_NODE_MAJOR") || latest=''
    if [[ ! "$latest" =~ ^v$WORKSHOP_NODE_MAJOR\.[0-9]+\.[0-9]+$ ]]; then
        workshop_status_printf '[FAIL] Could not retrieve the latest Node.js %s.x version.\n' "$WORKSHOP_NODE_MAJOR" >&2; return 1
    fi
    if [[ $(nvm version "$latest") == "$latest" ]]; then
        workshop_status_printf '[INFO] node: %s is already installed with nvm.\n' "$latest"
    else
        if [[ -n "$current" ]]; then
            workshop_status_printf '[INFO] node: Current version is %s (%s). Existing versions will be preserved.\n' "$current" "$node_path"
        fi
        if ! confirm_install "Node.js: Install $latest (latest $WORKSHOP_NODE_MAJOR.x) with nvm. Network access is required."; then
            workshop_status_printf '%s\n' '[WARN] Node.js installation was not approved.'
            return 0
        fi
        if ! nvm install "$latest"; then workshop_status_printf '%s\n' '[FAIL] Node.js installation failed.' >&2; return 1; fi
    fi
    if [[ $(nvm version default 2>/dev/null) != "$latest" ]] &&
        confirm_install "Node.js: Set nvm default to $latest so new terminals use it."; then
        nvm alias default "$latest" || { workshop_status_printf '%s\n' '[FAIL] Could not set the nvm default alias.' >&2; return 1; }
    fi
    if ! nvm use "$latest" >/dev/null || [[ $(node --version) != "$latest" ]] || ! npm --version >/dev/null; then
        workshop_status_printf '%s\n' '[FAIL] Could not activate Node.js or verify npm.' >&2; return 1
    fi
    workshop_status_printf '[PASS] Node.js %s is active in the script environment.\n' "$latest"
    workshop_status_printf '[INFO] To use it in the current terminal, run: source "%s/nvm.sh"; nvm use %s\n' "$NVM_DIR" "$latest"
}

install_copilot() {
    if ! confirm_install 'GitHub Copilot CLI: Run the official installer for the current user. Network access is required. Source: https://gh.io/copilot-install'; then return 0; fi
    if ! run_remote_installer 'https://gh.io/copilot-install' user bash; then
        workshop_status_printf '%s\n' '[FAIL] GitHub Copilot CLI installation failed.' >&2; return 1
    fi
    if ! command -v copilot >/dev/null 2>&1 && [[ -x "$HOME/.local/bin/copilot" ]]; then
        export PATH="$HOME/.local/bin:$PATH"
        workshop_status_printf '%s\n' '[MANUAL] Add $HOME/.local/bin to PATH in your shell profile.'
    fi
}

install_sbx() {
    local os="$1"
    if [[ "$os" == Darwin ]]; then
        if ! confirm_install 'Docker Sandboxes: Run brew trust docker/tap and brew install docker/tap/sbx. Network access is required.'; then return 0; fi
        if ! brew trust docker/tap || ! brew install docker/tap/sbx; then
            workshop_status_printf '%s\n' '[FAIL] Docker Sandboxes installation failed.' >&2; return 1
        fi
        return 0
    fi
    ensure_apt sbx || return 1
    if ! confirm_install "Docker Sandboxes: Add Docker's APT repository with sudo, then install docker-sbx. Network access is required and APT repositories will change. Source: https://get.docker.com"; then return 0; fi
    if ! run_remote_installer 'https://get.docker.com' sudo sh REPO_ONLY=1 || ! sudo apt-get install -y docker-sbx; then
        workshop_status_printf '%s\n' '[FAIL] Docker Sandboxes installation failed.' >&2; return 1
    fi
}

install_az() {
    local os="$1"
    if [[ "$os" == Darwin ]]; then brew_install az azure-cli; return; fi
    ensure_apt az || return 1
    if ! confirm_install 'Azure CLI: Run the official Microsoft installer with sudo. Network access is required and APT repositories will change. Source: https://aka.ms/InstallAzureCLIDeb'; then return 0; fi
    if ! run_remote_installer 'https://aka.ms/InstallAzureCLIDeb' sudo bash; then
        workshop_status_printf '%s\n' '[FAIL] Azure CLI installation failed.' >&2; return 1
    fi
}

install_aca() {
    if ! confirm_install 'Azure Container Apps CLI: Run the official installer. It verifies the SHA-256 of the archive and installs to /usr/local/bin, using sudo if needed. Source: https://aka.ms/aca-cli-install'; then return 0; fi
    if ! run_remote_installer 'https://aka.ms/aca-cli-install' user sh; then
        workshop_status_printf '%s\n' '[FAIL] Azure Container Apps CLI installation failed.' >&2; return 1
    fi
}

install_linux_sandbox_packages() {
    local -a packages=()
    command -v bwrap >/dev/null 2>&1 || packages+=(bubblewrap)
    command -v slirp4netns >/dev/null 2>&1 || packages+=(slirp4netns)
    if (( ${#packages[@]} )); then apt_install 'Local sandbox packages' "${packages[@]}" || return 1
    else workshop_status_printf '%s\n' '[INFO] bubblewrap and slirp4netns: Found on PATH.'; fi
    if [[ -e /dev/kvm && ! -w /dev/kvm ]]; then
        workshop_status_printf '%s\n' '[MANUAL] Run sudo usermod -aG kvm "$USER", then sign out and back in.'
    fi
}

install_tool() {
    local os="$1" tool="$2" path
    path=$(tool_path "$tool")
    if [[ -n "$path" ]]; then
        workshop_status_printf '[INFO] %s: Found on PATH (%s). It will not be installed or updated.\n' "$tool" "$path"
        return 0
    fi
    case "$os:$tool" in
        Darwin:git) brew_install git git ;;
        Linux:git) apt_install git git ;;
        Darwin:gh) brew_install 'GitHub CLI' gh ;;
        Linux:gh) apt_install 'GitHub CLI' gh ;;
        *:copilot) install_copilot ;;
        *:sbx) install_sbx "$os" ;;
        *:az) install_az "$os" ;;
        *:aca) install_aca ;;
    esac
}

install_missing_tools() {
    local os="$1" tool failed=0 brew_ready=1
    check_group 'Core tools'
    if [[ "$os" == Darwin ]] && ! ensure_homebrew; then failed=1; brew_ready=0; fi
    for tool in git gh; do
        if [[ "$os" == Darwin ]] && (( ! brew_ready )) && [[ -z $(tool_path "$tool") ]]; then
            workshop_status_printf '[WARN] %s: Skipping because Homebrew is unavailable.\n' "$tool"; failed=1; continue
        fi
        install_tool "$os" "$tool" || failed=1
    done
    install_node || failed=1

    check_group 'GitHub Copilot CLI'
    install_tool "$os" copilot || failed=1

    check_group 'Azure Container Apps Sandboxes'
    for tool in az aca; do
        if [[ "$tool" == az && "$os" == Darwin ]] && (( ! brew_ready )) && [[ -z $(tool_path "$tool") ]]; then
            workshop_status_printf '[WARN] %s: Skipping because Homebrew is unavailable.\n' "$tool"; failed=1; continue
        fi
        install_tool "$os" "$tool" || failed=1
    done

    check_group 'Docker Sandboxes'
    if [[ "$os" == Darwin ]] && (( ! brew_ready )) && [[ -z $(tool_path sbx) ]]; then
        workshop_status_printf '%s\n' '[WARN] sbx: Skipping because Homebrew is unavailable.'; failed=1
    else
        install_tool "$os" sbx || failed=1
    fi

    if [[ "$os" == Linux ]]; then
        check_group 'Local sandbox packages'
        install_linux_sandbox_packages || failed=1
    fi
    return "$failed"
}

prepare_azure_login() {
    command -v az >/dev/null 2>&1 || return 0
    check_group 'Azure sign-in'
    probe az account show --query state --output tsv
    if (( PROBE_CODE == 0 )) && [[ "$PROBE_TEXT" == Enabled ]]; then
        workshop_status_printf '%s\n' '[INFO] az: Already signed in with an enabled subscription.'
        return 0
    fi
    if confirm_install 'Azure CLI: Run az login in this terminal. A browser window may open.'; then
        az login || { workshop_status_printf '%s\n' '[FAIL] az login failed.' >&2; return 1; }
    fi
}

install_prerequisite_main() {
    local os result=0
    while (( $# )); do
        case "$1" in
            --help|-h) printf '%s\n' './scripts/install-prerequisites.sh'; return 0 ;;
            *) workshop_status_printf '[FAIL] Unknown argument: %s\n' "$1" >&2; return 2 ;;
        esac
    done
    os=$(uname -s)
    case "$os" in
        Darwin|Linux) ;;
        *) workshop_status_printf '%s\n' '[FAIL] Run this on macOS or Linux. On Windows, run ./scripts/install-prerequisites.ps1.' >&2; return 1 ;;
    esac
    if ! can_prompt; then
        workshop_status_printf '%s\n' '[FAIL] Installation is available only in an interactive terminal. Nothing is installed in a non-interactive environment.' >&2
        return 1
    fi
    printf 'Installation target: %s. Tools already on PATH will not be changed; Node.js %s.x is installed with nvm.\n' "$os" "$WORKSHOP_NODE_MAJOR"
    install_missing_tools "$os" || result=1
    hash -r
    prepare_azure_login || result=1
    workshop_status_printf '%s\n' '[INFO] Running read-only prerequisite checks from ./scripts/check-prerequisites.sh. Verify MANUAL items yourself.'
    prerequisite_main || result=1
    return "$result"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then install_prerequisite_main "$@"; exit $?; fi
