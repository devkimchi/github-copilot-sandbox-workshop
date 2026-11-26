#!/usr/bin/env bash

if [ -z "${BASH_VERSION:-}" ]; then
    printf '%s\n' '[FAIL] Run ./scripts/check-prerequisites.sh with Bash.' >&2
    return 2 2>/dev/null || exit 2
fi

CHECK_SCRIPTS="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
source "$CHECK_SCRIPTS/terminal-output.sh"

WORKSHOP_NODE_MINIMUM=24.0.0
WORKSHOP_NODE_MAJOR=24
CHECK_FAILURES=0
CHECK_CONTEXT=''
PROBE_TEXT=''
PROBE_CODE=0

probe() {
    if ! command -v "$1" >/dev/null 2>&1; then
        PROBE_TEXT="$1 not found"
        PROBE_CODE=127
        return
    fi
    PROBE_TEXT=$("$@" 2>&1)
    PROBE_CODE=$?
}

check_result() {
    local status="$1" id="$2" message="$3"
    workshop_status_printf '[%s] [%s] %s: %s\n' "$status" "$CHECK_CONTEXT" "$id" "$message"
    if [[ "$status" == FAIL ]]; then CHECK_FAILURES=$(( CHECK_FAILURES + 1 )); fi
}

check_group() {
    printf '\n== %s ==\n' "$1"
}

extract_version() {
    [[ "$1" =~ ([0-9]+\.[0-9]+(\.[0-9]+)?) ]] && printf '%s\n' "${BASH_REMATCH[1]}"
}

version_not_older() {
    local -a actual minimum
    local index
    IFS=. read -r -a actual <<< "$1"
    IFS=. read -r -a minimum <<< "$2"
    for index in 0 1 2; do
        if (( 10#${actual[index]:-0} > 10#${minimum[index]:-0} )); then return 0; fi
        if (( 10#${actual[index]:-0} < 10#${minimum[index]:-0} )); then return 1; fi
    done
    return 0
}

minimum_version() {
    local id="$1" minimum="$2" version
    shift 2
    probe "$@"
    if (( PROBE_CODE != 0 )); then
        check_result FAIL "$id" "${PROBE_TEXT:-exit code $PROBE_CODE}"
        return 1
    fi
    version=$(extract_version "$PROBE_TEXT")
    if [[ -z "$version" ]]; then
        check_result FAIL "$id" "Could not read the version: ${PROBE_TEXT%%$'\n'*}"
        return 1
    fi
    if version_not_older "$version" "$minimum"; then
        check_result PASS "$id" "$version (>= $minimum)"
    else
        check_result FAIL "$id" "$version (requires >= $minimum)"
        return 1
    fi
}

tool_path() {
    command -v "$1" 2>/dev/null || true
}

nvm_directory() {
    if [[ -n "${NVM_DIR:-}" ]]; then printf '%s\n' "$NVM_DIR"
    elif [[ -n "${XDG_CONFIG_HOME:-}" && -s "$XDG_CONFIG_HOME/nvm/nvm.sh" ]]; then printf '%s/nvm\n' "$XDG_CONFIG_HOME"
    else printf '%s/.nvm\n' "$HOME"; fi
}

initialize_node_environment() {
    local nvm_dir
    nvm_dir=$(nvm_directory)
    if [[ $(type -t nvm) != function && -s "$nvm_dir/nvm.sh" ]]; then
        export NVM_DIR="$nvm_dir"
        # shellcheck disable=SC1091
        source "$NVM_DIR/nvm.sh" >/dev/null 2>&1 || true
    fi
}

check_host() {
    local os version arch
    check_group 'Host'
    os=$(uname -s)
    arch=$(uname -m)
    case "$os" in
        Darwin)
            version=$(sw_vers -productVersion 2>/dev/null)
            if [[ -n "$version" ]] && version_not_older "$version" 14.0; then check_result PASS macos "$version (Sonoma 14 or later)"
            else check_result FAIL macos "${version:-unknown} (requires macOS Sonoma 14 or later)"; fi
            if [[ "$arch" == arm64 ]]; then check_result PASS architecture "$arch (Apple silicon)"
            else check_result FAIL architecture "$arch (requires Apple silicon)"; fi ;;
        Linux)
            check_linux_host "$arch" ;;
        *)
            check_result FAIL os "$os is not supported. On Windows, run ./scripts/check-prerequisites.ps1." ;;
    esac
    check_result PASS bash "$BASH_VERSION"
}

check_linux_host() {
    local arch="$1" id='' version_id=''
    if [[ -r /etc/os-release ]]; then
        id=$(. /etc/os-release && printf '%s' "${ID:-}")
        version_id=$(. /etc/os-release && printf '%s' "${VERSION_ID:-}")
    fi
    if [[ "$id" == ubuntu ]] && version_not_older "$version_id" 24.04; then check_result PASS linux "Ubuntu $version_id"
    else check_result WARN linux "${id:-unknown} ${version_id} (the tested target is Ubuntu 24.04 or later)"; fi
    case "$arch" in
        x86_64|aarch64) check_result PASS architecture "$arch" ;;
        *) check_result FAIL architecture "$arch (requires 64-bit Intel, AMD, or Arm)" ;;
    esac
    if [[ -r /dev/kvm && -w /dev/kvm ]]; then check_result PASS kvm '/dev/kvm is accessible'
    elif [[ -e /dev/kvm ]]; then check_result FAIL kvm '/dev/kvm exists but is not accessible. Add your user to the kvm group, then sign out and back in.'
    else check_result FAIL kvm '/dev/kvm is missing. Enable KVM or nested virtualization for local sandboxes.'; fi
    minimum_version bwrap 0.5.0 bwrap --version
    probe slirp4netns --version
    if (( PROBE_CODE == 0 )); then check_result PASS slirp4netns "$(extract_version "$PROBE_TEXT")"
    else check_result FAIL slirp4netns "${PROBE_TEXT:-exit code $PROBE_CODE}"; fi
}

check_core_tools() {
    local node_path version nvm_dir
    check_group 'Core tools'
    minimum_version git 2.0.0 git --version
    initialize_node_environment
    if minimum_version node "$WORKSHOP_NODE_MINIMUM" node --version; then
        node_path=$(tool_path node)
        nvm_dir=$(nvm_directory)
        if [[ -n "$node_path" && -d "$nvm_dir" ]] &&
            [[ "$(cd -P -- "$(dirname -- "$node_path")" && pwd)" == "$(cd -P -- "$nvm_dir" && pwd)"/* ]]; then
            check_result PASS node-manager "nvm ($nvm_dir)"
        else
            check_result WARN node-manager "${node_path:-node} is not managed by nvm. The workshop installs Node.js through nvm."
        fi
    else
        check_result INFO node-install "Run bash scripts/install-prerequisites.sh to install the latest Node.js $WORKSHOP_NODE_MAJOR.x with nvm."
    fi
    probe npm --version
    if (( PROBE_CODE == 0 )); then check_result PASS npm "$PROBE_TEXT"
    else check_result FAIL npm "${PROBE_TEXT:-exit code $PROBE_CODE}"; fi
}

check_copilot() {
    check_group 'GitHub Copilot CLI'
    probe copilot --version
    if (( PROBE_CODE == 0 )); then check_result PASS copilot "$(extract_version "$PROBE_TEXT")"
    else check_result FAIL copilot "${PROBE_TEXT:-exit code $PROBE_CODE}"; fi
    check_result MANUAL copilot-auth 'Confirm the Copilot license and sign in with /login in copilot, or prepare a fine-grained PAT with Copilot Requests.'
}

check_docker_sandboxes() {
    check_group 'Docker Sandboxes'
    minimum_version sbx 0.45.0 sbx --version || true
    check_result MANUAL sbx-auth 'Run sbx login, then store the Copilot token with sbx secret set copilot.'
}

check_azure() {
    local saved_dynamic="${AZURE_EXTENSION_USE_DYNAMIC_INSTALL-__unset__}"
    check_group 'Azure'
    export AZURE_EXTENSION_USE_DYNAMIC_INSTALL=no
    if minimum_version az 2.0.0 az --version; then
        probe az account show --query state --output tsv
        if (( PROBE_CODE == 0 )) && [[ "$PROBE_TEXT" == Enabled ]]; then check_result PASS az-login 'Signed in with an enabled subscription'
        else check_result FAIL az-login "Run az login and select the workshop subscription (exit code $PROBE_CODE)."; fi
    fi
    if [[ "$saved_dynamic" == __unset__ ]]; then unset AZURE_EXTENSION_USE_DYNAMIC_INSTALL
    else export AZURE_EXTENSION_USE_DYNAMIC_INSTALL="$saved_dynamic"; fi
    probe aca --version
    if (( PROBE_CODE == 0 )); then check_result PASS aca "$(extract_version "$PROBE_TEXT")"
    else check_result FAIL aca "${PROBE_TEXT:-exit code $PROBE_CODE}"; fi
    check_result MANUAL aca-config 'Run aca doctor and aca config show. Confirm the sandbox group, region, and RBAC.'
}

check_optional() {
    check_group 'Optional (180-minute extension)'
    probe docker --version
    if (( PROBE_CODE == 0 )); then check_result PASS docker "$(extract_version "$PROBE_TEXT")"
    else check_result WARN docker 'Not found. Required only to build the custom mixin in the 180-minute extension.'; fi
    probe docker buildx version
    if (( PROBE_CODE == 0 )); then check_result PASS buildx "$(extract_version "$PROBE_TEXT")"
    else check_result WARN buildx 'Not found. Required only to build the custom mixin in the 180-minute extension.'; fi
    check_result INFO docker-note 'Docker Desktop and az containerapp do not replace sbx or aca.'
}

prerequisite_main() {
    while (( $# )); do
        case "$1" in
            --help|-h) printf '%s\n' './scripts/check-prerequisites.sh'; return 0 ;;
            *) workshop_status_printf '[FAIL] Unknown argument: %s\n' "$1" >&2; return 2 ;;
        esac
    done
    CHECK_FAILURES=0
    if [[ "$(uname -s)" == Darwin ]]; then CHECK_CONTEXT='macOS Bash'; else CHECK_CONTEXT='Linux Bash'; fi
    check_host
    check_core_tools
    check_copilot
    check_docker_sandboxes
    check_azure
    check_optional
    printf '\nRequired failures: %d. MANUAL items were not checked automatically.\n' "$CHECK_FAILURES"
    (( CHECK_FAILURES == 0 ))
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then prerequisite_main "$@"; exit $?; fi
