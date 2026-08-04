#!/usr/bin/env bash

# @Filename: 1MB-start.sh
# @Version: 2.19.0, build 088
# @Release: August 4th, 2026
# @Description: Starts the adjacent Minecraft server launcher in a detached tmux session.
# @Contact: I am @floris on Twitter, and mrfloris in MineCraft.
# @Discord: @mrfloris on https://discord.gg/floris
# @Install: chmod +x 1MB-start.sh
# @Syntax: ./1MB-start.sh [command] [name] (see --help)
# @URL: Latest source, wiki, & support: https://scripts.1moreblock.com/

### CONFIGURATION
#
# Declarations here you can customize to your preferred setup.
# Generally only if you actually have to. Check Wiki for details.
#
###

_serverName="mcserver"
# Use 1-32 lowercase ASCII letters, numbers, hyphens or underscores. The first
# character must be a letter or number.
# The name makes it easier to recognize the session in 'tmux ls', you can
# re-attach to the forked sessions with 'tmux attach -t (name)'.

### INTERNAL CONFIGURATION
#
# Configuration variables you should probably
# leave alone, but can change if really needed.
#
###

_sibling="1MB-minecraft.sh"
_startupCheckSeconds=2 # Check process liveness only; this is not Paper readiness.
_debug=true # Set to false to minimize output.
_scriptName="1MB-start.sh"
_scriptVersion="2.19.0"
_scriptBuild="088"
_tmuxPath=""
_sleepPath=""
_launchArguments=()
_doctorFailures=0

### FUNCTIONS AND CODE
#
# ! WE ARE DONE, STOP EDITING BEYOND THIS POINT !
#
###

function _output {
    local _mode="${1:-}"
    local _args=""
    local _prefix=""
    local _fd=1
    local _yellow=""
    local _cyan=""
    local _reset=""

    if [ "$_mode" = debug ] && [ "$_debug" != true ]; then
        return 0
    fi

    case "$_mode" in
    oops) _fd=2 ;;
    esac

    if [ -z "${NO_COLOR+x}" ] && [ -t "$_fd" ]; then
        printf -v _yellow '\033[33m'
        printf -v _cyan '\033[36m'
        printf -v _reset '\033[0m'
    fi

    case "$_mode" in
    oops)
        _args="${*:2}"; _prefix="(Script Halted!)";
        printf '\n%s%s %s%s\n' "$_yellow" "$_prefix" "$_args" "$_reset" >&2; exit 1
    ;;
    okay)
        _args="${*:2}"; _prefix="(Info)";
        printf '\n%s%s%s %s%s\n' "$_yellow" "$_prefix" "$_cyan" "$_args" "$_reset"; return 0
    ;;
    debug)
        _args="${*:2}"; _prefix="(Debug)";
        [[ "$_debug" == true ]] && printf '%s%s%s %s%s\n' "$_yellow" "$_prefix" "$_cyan" "$_args" "$_reset"
    ;;
    *)
        _args="${*:1}"; _prefix="(Info)";
        printf '\n%s %s\n' "$_prefix" "$_args"
    ;;
    esac
}

function _resolveScriptDirectory {
    local _source="${BASH_SOURCE[0]}"
    local _sourceDir=""
    local _linkTarget=""
    local _linkDepth=0

    case "$_source" in
    */*)
        ;;
    *)
        if [ -e "$_source" ] || [ -L "$_source" ]; then
            _source="./$_source"
        else
            _source=$(command -v "$_source") || return 1
        fi
        ;;
    esac

    while [ -L "$_source" ]; do
        _linkDepth=$((_linkDepth + 1))
        [ "$_linkDepth" -gt 40 ] && return 1

        _sourceDir=$(cd -P -- "$(dirname -- "$_source")" >/dev/null 2>&1 && pwd -P) || return 1
        _linkTarget=$(readlink "$_source") || return 1

        case "$_linkTarget" in
        /*) _source="$_linkTarget" ;;
        *) _source="$_sourceDir/$_linkTarget" ;;
        esac
    done

    cd -P -- "$(dirname -- "$_source")" >/dev/null 2>&1 && pwd -P
}

function _showHelp {
    local _programName="${0##*/}"

    printf '%s\n' \
        "Usage:" \
        "  $_programName [name]" \
        "  $_programName --start [name]" \
        "  $_programName --status [name]" \
        "  $_programName --attach [name]" \
        "  $_programName --dry-run [name]" \
        "  $_programName --doctor" \
        "  $_programName --list" \
        "  $_programName --version" \
        "  $_programName --help" \
        "" \
        "Commands:" \
        "  (none)           Start the adjacent $_sibling in detached tmux." \
        "  --start [name]   Explicit form of the default start command." \
        "  --status [name]  Report whether the exact tmux session exists." \
        "  --attach [name]  Attach to the exact tmux session." \
        "  --dry-run [name] Validate and print the launch plan without running it." \
        "  --doctor         Run read-only launch-readiness diagnostics." \
        "  --list           List all tmux session names visible to the current OS user." \
        "  --version        Show this wrapper's version and build." \
        "  --help, -h       Show this help." \
        "" \
        "The session name defaults to '$_serverName'." \
        "Names use 1-32 lowercase ASCII letters, numbers, hyphens or underscores." \
        "The first character must be a letter or number." \
        "Doctor and dry-run perform static checks only; neither starts the server."
}

function _showVersion {
    printf '%s %s, build %s\n' "$_scriptName" "$_scriptVersion" "$_scriptBuild"
}

function _isValidServerName {
    local _requestedName="${1-}"
    local LC_ALL=C

    [ "${#_requestedName}" -le 32 ] && [[ "$_requestedName" =~ ^[a-z0-9][a-z0-9_-]*$ ]]
}

function _setServerName {
    local _requestedName="${1-}"

    if ! _isValidServerName "$_requestedName"; then
        _output oops "Invalid session name. Use 1-32 lowercase ASCII letters, numbers, hyphens or underscores. The first character must be a letter or number."
    fi

    _serverName="$_requestedName"
}

function _isValidSiblingPath {
    local _path="${1:-}"

    [ ! -L "$_path" ] && [ -f "$_path" ] && [ -r "$_path" ] && [ -x "$_path" ]
}

function _findExecutable {
    local _name="${1:-}"
    local _path=""

    _path=$(type -P "$_name" 2>/dev/null) || return 1
    [ -n "$_path" ] && [ -f "$_path" ] && [ -x "$_path" ] || return 1
    printf '%s\n' "$_path"
}

function _requireTmux {
    _tmuxPath=$(_findExecutable tmux) || _output oops "'tmux' is required but was not found. On macOS, install it with: brew install tmux"
}

function _requireSleep {
    _sleepPath=$(_findExecutable sleep) || _output oops "'sleep' is required for the startup liveness check but was not found."
}

function _quoteValue {
    printf '%q' "$1"
}

function _setLaunchArguments {
    _launchArguments=(
        new-session -d -P -F '#{pane_id}'
        -s "$_serverName"
        -c "$_scriptDir"
        "exec \"./$_sibling\""
        ';'
        set-option -p -t "=$_serverName:" remain-on-exit on
    )
}

function _showDryRun {
    printf '%s\n' "Static launch preflight passed."
    printf 'Session: %q\n' "$_serverName"
    printf 'Server directory: %q\n' "$_scriptDir"
    printf 'Launcher: %q\n' "$_siblingPath"
    printf 'tmux executable: %q\n' "$_tmuxPath"
    printf 'sleep executable: %q\n' "$_sleepPath"
    printf 'Startup check: %s seconds (not performed)\n' "$_startupCheckSeconds"
    printf 'Session availability: not checked (use --status %q)\n' "$_serverName"
    printf 'Command:'
    printf ' %q' "$_tmuxPath" "${_launchArguments[@]}"
    printf '\n%s\n' "Dry run only: no tmux session was created and '$_sibling' was not executed."
}

function _doctorOkay {
    printf '[OK] %s\n' "$1"
}

function _doctorFail {
    _doctorFailures=$((_doctorFailures + 1))
    printf '[FAIL] %s\n' "$1"
}

function _runDoctor {
    local _commandName=""
    local _commandPath=""
    local _doctorScriptDir=""
    local _doctorSiblingPath=""
    local _tmuxCandidate=""
    local _tmuxVersion=""
    local _quotedValue=""

    _doctorFailures=0
    printf '%s doctor\n\n' "$_scriptName"

    if [ "${BASH_VERSINFO[0]}" -gt 3 ] || \
        { [ "${BASH_VERSINFO[0]}" -eq 3 ] && [ "${BASH_VERSINFO[1]}" -ge 2 ]; }; then
        _doctorOkay "Bash $BASH_VERSION is supported (3.2 or newer)."
    else
        _doctorFail "Bash $BASH_VERSION is unsupported; Bash 3.2 or newer is required."
    fi

    if [ "$EUID" -eq 0 ]; then
        _doctorFail "Startup would refuse the root user or sudo."
    else
        _doctorOkay "The current user is not root."
    fi

    if _isValidServerName "$_serverName"; then
        _quotedValue=$(_quoteValue "$_serverName")
        _doctorOkay "Configured default session name: $_quotedValue"
    else
        _quotedValue=$(_quoteValue "$_serverName")
        _doctorFail "Configured default session name is invalid: $_quotedValue"
    fi

    for _commandName in dirname readlink sleep; do
        if _commandPath=$(_findExecutable "$_commandName"); then
            _quotedValue=$(_quoteValue "$_commandPath")
            _doctorOkay "Command '$_commandName': $_quotedValue"
        else
            _doctorFail "Required command '$_commandName' was not found as an executable file."
        fi
    done

    if _doctorScriptDir=$(_resolveScriptDirectory 2>/dev/null); then
        _quotedValue=$(_quoteValue "$_doctorScriptDir")
        _doctorOkay "Server directory: $_quotedValue"
        _doctorSiblingPath="$_doctorScriptDir/$_sibling"
        if _isValidSiblingPath "$_doctorSiblingPath"; then
            _quotedValue=$(_quoteValue "$_doctorSiblingPath")
            _doctorOkay "Adjacent launcher is regular, non-symlink, readable and executable: $_quotedValue"
        else
            _quotedValue=$(_quoteValue "$_doctorSiblingPath")
            _doctorFail "Adjacent launcher is missing or unsafe: $_quotedValue"
        fi
    else
        _quotedValue=$(_quoteValue "$0")
        _doctorFail "Could not resolve the physical server directory containing $_quotedValue."
        _doctorFail "Adjacent launcher could not be checked because the server directory was unresolved."
    fi

    if _tmuxCandidate=$(_findExecutable tmux); then
        if _tmuxVersion=$("$_tmuxCandidate" -V 2>&1); then
            _tmuxCandidate=$(_quoteValue "$_tmuxCandidate")
            _tmuxVersion=$(_quoteValue "$_tmuxVersion")
            _doctorOkay "tmux: $_tmuxCandidate ($_tmuxVersion)"
        else
            _tmuxCandidate=$(_quoteValue "$_tmuxCandidate")
            _tmuxVersion=$(_quoteValue "$_tmuxVersion")
            _doctorFail "tmux exists but its version check failed: $_tmuxCandidate ($_tmuxVersion)"
        fi
    else
        _doctorFail "tmux was not found as an executable file."
    fi

    printf '\n%s\n' "Doctor scope: static checks only; no session was queried and '$_sibling' was not executed."
    if [ "$_doctorFailures" -eq 0 ]; then
        printf '%s\n' "Doctor result: PASS"
        return 0
    fi

    printf 'Doctor result: FAIL (%s failed checks)\n' "$_doctorFailures"
    return 1
}

function _isPaneId {
    local _paneId="${1:-}"
    local _paneNumber=""

    case "$_paneId" in
    %*) _paneNumber="${_paneId#%}" ;;
    *) return 1 ;;
    esac

    case "$_paneNumber" in
    ""|*[!0-9]*) return 1 ;;
    *) return 0 ;;
    esac
}

function _verifyStartedPane {
    local _paneId="${1:-}"
    local _paneReport=""
    local _paneDead=""
    local _paneResult=""
    local _paneStatus=""
    local _paneSignal=""
    local _exitDescription=""

    _output debug "Checking whether '$_sibling' remains active for $_startupCheckSeconds seconds ..."

    if ! "$_sleepPath" "$_startupCheckSeconds"; then
        if ! "$_tmuxPath" set-option -p -t "$_paneId" remain-on-exit off >/dev/null 2>&1; then
            _output oops "The $_startupCheckSeconds-second startup check was interrupted, and tmux could not restore normal close-on-exit behavior. Inspect the '$_serverName' session before retrying."
        fi
        _output oops "The $_startupCheckSeconds-second startup check was interrupted. The tmux session was not reported as started."
    fi

    if ! _paneReport=$("$_tmuxPath" display-message -p -t "$_paneId" '#{pane_dead}|#{pane_dead_status}|#{pane_dead_signal}' 2>/dev/null); then
        "$_tmuxPath" set-option -p -t "$_paneId" remain-on-exit off >/dev/null 2>&1 || true
        _output oops "'$_sibling' ended or its tmux pane disappeared during the $_startupCheckSeconds-second startup check. Run './$_sibling' directly from '$_scriptDir' to inspect its full output."
    fi

    _paneDead="${_paneReport%%|*}"
    _paneResult="${_paneReport#*|}"
    _paneStatus="${_paneResult%%|*}"
    _paneSignal="${_paneResult#*|}"

    case "$_paneDead" in
    0)
        if ! "$_tmuxPath" set-option -p -t "$_paneId" remain-on-exit off >/dev/null 2>&1; then
            _output oops "'$_sibling' remained active, but tmux could not restore normal close-on-exit behavior for pane '$_paneId'. Inspect the '$_serverName' session before retrying."
        fi

        if ! _paneDead=$("$_tmuxPath" display-message -p -t "$_paneId" '#{pane_dead}' 2>/dev/null); then
            _output oops "'$_sibling' ended as the $_startupCheckSeconds-second startup check completed. The tmux session was not reported as started."
        fi

        if [ "$_paneDead" != 0 ]; then
            "$_tmuxPath" kill-pane -t "$_paneId" >/dev/null 2>&1 || true
            _output oops "'$_sibling' ended as the $_startupCheckSeconds-second startup check completed. The tmux session was not reported as started."
        fi
        ;;
    1)
        if [ -n "$_paneStatus" ]; then
            _exitDescription="exit status $_paneStatus"
        fi
        if [ -n "$_paneSignal" ]; then
            if [ -n "$_exitDescription" ]; then
                _exitDescription="$_exitDescription, signal $_paneSignal"
            else
                _exitDescription="signal $_paneSignal"
            fi
        fi
        [ -z "$_exitDescription" ] && _exitDescription="unknown exit status"

        "$_tmuxPath" kill-pane -t "$_paneId" >/dev/null 2>&1 || true
        _output oops "'$_sibling' exited during the $_startupCheckSeconds-second startup check ($_exitDescription). Run './$_sibling' directly from '$_scriptDir' to inspect its full output."
        ;;
    *)
        "$_tmuxPath" set-option -p -t "$_paneId" remain-on-exit off >/dev/null 2>&1 || true
        _output oops "tmux returned an unexpected state for pane '$_paneId' during the startup check. The session was not reported as started."
        ;;
    esac
}

_action="start"
_nameArgument="$_serverName"

case "${1:-}" in
-h|--help)
    [ "$#" -eq 1 ] || _output oops "Unexpected extra arguments. Run '$0 --help' for usage."
    _showHelp
    exit 0
    ;;
--version)
    [ "$#" -eq 1 ] || _output oops "Unexpected extra arguments. Run '$0 --help' for usage."
    _showVersion
    exit 0
    ;;
--doctor)
    [ "$#" -eq 1 ] || _output oops "Unexpected extra arguments. Run '$0 --help' for usage."
    _action="doctor"
    ;;
--start)
    [ "$#" -le 2 ] || _output oops "Unexpected extra arguments. Run '$0 --help' for usage."
    _action="start"
    if [ "$#" -eq 2 ]; then
        _nameArgument="$2"
    fi
    ;;
--status)
    [ "$#" -le 2 ] || _output oops "Unexpected extra arguments. Run '$0 --help' for usage."
    _action="status"
    if [ "$#" -eq 2 ]; then
        _nameArgument="$2"
    fi
    ;;
--attach)
    [ "$#" -le 2 ] || _output oops "Unexpected extra arguments. Run '$0 --help' for usage."
    _action="attach"
    if [ "$#" -eq 2 ]; then
        _nameArgument="$2"
    fi
    ;;
--dry-run)
    [ "$#" -le 2 ] || _output oops "Unexpected extra arguments. Run '$0 --help' for usage."
    _action="dry-run"
    if [ "$#" -eq 2 ]; then
        _nameArgument="$2"
    fi
    ;;
--list)
    [ "$#" -eq 1 ] || _output oops "Unexpected extra arguments. Run '$0 --help' for usage."
    _action="list"
    ;;
--*)
    _output oops "Unknown option '$1'. Run '$0 --help' for usage."
    ;;
*)
    [ "$#" -le 1 ] || _output oops "Unexpected extra arguments. Run '$0 --help' for usage."
    if [ "$#" -eq 1 ]; then
        _nameArgument="$1"
    fi
    ;;
esac

if [ "$_action" = doctor ]; then
    _runDoctor
    exit $?
fi

case "$_action" in
start|status|attach|dry-run)
    _setServerName "$_nameArgument"
    ;;
esac

[ "$EUID" -eq 0 ] && _output oops "*!* This script should not be run using sudo, or as the root user!"

case "$_action" in
start|dry-run)
    _scriptDir=$(_resolveScriptDirectory) || _output oops "Could not resolve the server directory containing '$0'."
    _siblingPath="$_scriptDir/$_sibling"

    if ! _isValidSiblingPath "$_siblingPath"; then
        _output oops "'$_sibling' must be a regular, non-symlink, readable and executable file beside this wrapper: '$_siblingPath'. Files elsewhere are not used. Correct the file, or download it from https://scripts.1moreblock.com/ "
    fi
    _requireSleep
    ;;
esac

_requireTmux

case "$_action" in
start|dry-run)
    _setLaunchArguments
    ;;
esac

case "$_action" in
dry-run)
    _showDryRun
    exit 0
    ;;
list)
    exec "$_tmuxPath" list-sessions -F '#{session_name}'
    _output oops "Could not execute tmux list-sessions."
    ;;
status)
    if "$_tmuxPath" has-session -t "=$_serverName" 2>/dev/null; then
        _output "tmux session '$_serverName' is running."
        exit 0
    fi

    _output "tmux session '$_serverName' is not running."
    exit 1
    ;;
attach)
    if ! "$_tmuxPath" has-session -t "=$_serverName" 2>/dev/null; then
        _output oops "No tmux session named '$_serverName' is running."
    fi

    _output debug "Attaching to tmux session '$_serverName' ..."
    exec "$_tmuxPath" attach-session -t "=$_serverName"
    _output oops "Could not execute tmux attach-session for '$_serverName'."
    ;;
esac

_output debug "Attempting to start your Minecraft '$_serverName' server ... "
_output debug "Using server directory: $_scriptDir"

_output debug "Found 'tmux', attempting to start '$_sibling' in a detached tmux session ..."
# Deliberately launch only ./1MB-minecraft.sh from the wrapper's own directory.
_paneId=""
if ! _paneId=$("$_tmuxPath" "${_launchArguments[@]}"); then
    if _isPaneId "$_paneId"; then
        "$_tmuxPath" kill-pane -t "$_paneId" >/dev/null 2>&1 || true
    fi
    _output oops "Could not create the '$_serverName' tmux session and prepare its startup check. Review the tmux error above and check with 'tmux ls'."
fi

if ! _isPaneId "$_paneId"; then
    "$_tmuxPath" kill-session -t "=$_serverName" >/dev/null 2>&1 || true
    _output oops "tmux created the '$_serverName' session but did not return a valid pane identifier, so the new session was closed."
fi

_verifyStartedPane "$_paneId"

[[ "$_debug" == true ]] && "$_tmuxPath" ls; _output debug "To re-attach: tmux attach -t $_serverName"

_output debug "tmux session started."

#EOF Copyright (c) 1977-2026 - Floris Fiedeldij Dop - https://scripts.1moreblock.com
