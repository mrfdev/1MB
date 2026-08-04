#!/usr/bin/env bash

# Repeatable, non-production tests for Resources/Server/1MB-start.sh.
# Compatible with the Bash 3.2 shipped by macOS.

_suiteDir=$(cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd -P) || exit 1
_serverDir=$(cd -P -- "$_suiteDir/../.." >/dev/null 2>&1 && pwd -P) || exit 1
_target="$_serverDir/1MB-start.sh"
_runner="$_suiteDir/run-tests.sh"
_fakeTmux="$_suiteDir/fake-bin/tmux"
_fakeSleep="$_suiteDir/fake-bin/sleep"
_originalPath="$PATH"
_mode="${1:-all}"

_passed=0
_failed=0
_skipped=0
_caseNumber=0
_caseFailed=0
_caseLabel=""
_tempRoot=""
_bashUnderTest=""
_caseDir=""
_caseServerDir=""
_caseStateDir=""
_caseWrapper=""
_stdoutFile=""
_stderrFile=""
_runStatus=0
_siblingMarker=""

function _usage {
    printf '%s\n' \
        "Usage: ${0##*/} [all|test|lint]" \
        "" \
        "  all   Run syntax, fake-tmux behavior, and ShellCheck (default)." \
        "  test  Run syntax and fake-tmux behavior without ShellCheck." \
        "  lint  Run ShellCheck only."
}

if [ "$#" -gt 1 ]; then
    _usage >&2
    exit 2
fi

case "$_mode" in
all|test|lint)
    ;;
-h|--help)
    _usage
    exit 0
    ;;
*)
    _usage >&2
    exit 2
    ;;
esac

function _pass {
    _passed=$((_passed + 1))
    printf 'PASS: %s\n' "$1"
}

function _fail {
    _failed=$((_failed + 1))
    printf 'FAIL: %s\n' "$1" >&2
}

function _skip {
    _skipped=$((_skipped + 1))
    printf 'SKIP: %s\n' "$1"
}

function _beginCase {
    _caseLabel="$1"
    _caseFailed=0
}

function _problem {
    _caseFailed=1
    printf '  %s\n' "$1" >&2
    if [ -n "$_caseDir" ]; then
        printf '  fixture: %s\n' "$_caseDir" >&2
    fi
}

function _showFile {
    local _label="$1"
    local _file="$2"

    if [ -s "$_file" ]; then
        printf '  %s:\n' "$_label" >&2
        sed 's/^/    /' "$_file" >&2
    fi
}

function _finishCase {
    if [ "$_caseFailed" -eq 0 ]; then
        _pass "$_caseLabel"
        return 0
    fi

    _showFile "stdout" "$_stdoutFile"
    _showFile "stderr" "$_stderrFile"
    if [ -n "$_caseStateDir" ]; then
        _showFile "fake tmux calls" "$_caseStateDir/tmux.log"
        _showFile "fake sleep calls" "$_caseStateDir/sleep.log"
    fi
    _fail "$_caseLabel"
    return 1
}

function _cleanup {
    if [ -z "$_tempRoot" ] || [ ! -d "$_tempRoot" ]; then
        return
    fi

    if [ "$_failed" -eq 0 ]; then
        rm -rf -- "$_tempRoot"
    else
        printf 'Failed-test artifacts retained at: %s\n' "$_tempRoot" >&2
    fi
}

trap _cleanup EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

function _addBash {
    local _candidate="$1"
    local _candidateDir=""
    local _candidatePath=""
    local _known=""

    [ -x "$_candidate" ] || return 0
    _candidateDir=$(cd -P -- "$(dirname -- "$_candidate")" >/dev/null 2>&1 && pwd -P) || return 0
    _candidatePath="$_candidateDir/$(basename -- "$_candidate")"

    for _known in "${_bashPaths[@]}"; do
        [ "$_known" = "$_candidatePath" ] && return 0
    done
    _bashPaths[${#_bashPaths[@]}]="$_candidatePath"
}

function _discoverBashes {
    local _pathBash=""

    _bashPaths=()
    _addBash /bin/bash
    _pathBash=$(command -v bash 2>/dev/null || true)
    [ -n "$_pathBash" ] && _addBash "$_pathBash"
    _addBash /opt/homebrew/bin/bash
    _addBash /usr/local/bin/bash
}

function _newFixture {
    local _siblingMode="${1:-executable}"

    _caseNumber=$((_caseNumber + 1))
    _caseDir="$_tempRoot/case-$_caseNumber"
    _caseServerDir="$_caseDir/server directory with spaces"
    _caseStateDir="$_caseDir/state"
    _caseWrapper="$_caseServerDir/1MB-start.sh"
    _stdoutFile="$_caseDir/stdout"
    _stderrFile="$_caseDir/stderr"

    mkdir -p "$_caseServerDir" "$_caseStateDir/tmux-socket"
    cp "$_target" "$_caseWrapper"
    chmod 0755 "$_caseWrapper"

    case "$_siblingMode" in
    executable)
        printf '%s\n' '#!/usr/bin/env bash' 'exit 0' >"$_caseServerDir/1MB-minecraft.sh"
        chmod 0755 "$_caseServerDir/1MB-minecraft.sh"
        ;;
    nonexecutable)
        printf '%s\n' '#!/usr/bin/env bash' 'exit 0' >"$_caseServerDir/1MB-minecraft.sh"
        chmod 0644 "$_caseServerDir/1MB-minecraft.sh"
        ;;
    unreadable)
        printf '%s\n' '#!/usr/bin/env bash' 'exit 0' >"$_caseServerDir/1MB-minecraft.sh"
        chmod 0111 "$_caseServerDir/1MB-minecraft.sh"
        ;;
    directory)
        mkdir "$_caseServerDir/1MB-minecraft.sh"
        ;;
    symlink)
        ln -s "1MB-start.sh" "$_caseServerDir/1MB-minecraft.sh"
        ;;
    missing)
        ;;
    *)
        printf '%s\n' "Unknown sibling fixture mode: $_siblingMode" >&2
        exit 2
        ;;
    esac
}

function _runWrapper {
    local _scenario="$1"
    shift

    _runWrapperWithPath "$_scenario" "$_suiteDir/fake-bin:$_originalPath" "$@"
}

function _runWrapperWithPath {
    local _scenario="$1"
    local _runPath="$2"
    shift 2

    : >"$_stdoutFile"
    : >"$_stderrFile"
    FAKE_TMUX_SCENARIO="$_scenario" \
        FAKE_TMUX_STATE_DIR="$_caseStateDir" \
        NO_COLOR=1 \
        PATH="$_runPath" \
        TMUX='' \
        TMUX_TMPDIR="$_caseStateDir/tmux-socket" \
        "$_bashUnderTest" "$_caseWrapper" "$@" >"$_stdoutFile" 2>"$_stderrFile"
    _runStatus=$?
}

function _expectStatus {
    local _expected="$1"
    if [ "$_runStatus" -ne "$_expected" ]; then
        _problem "expected exit $_expected, got $_runStatus"
    fi
}

function _expectEmpty {
    local _file="$1"
    local _description="$2"
    [ ! -s "$_file" ] || _problem "expected empty $_description"
}

function _expectContains {
    local _file="$1"
    local _text="$2"
    local _description="$3"
    grep -Fq -- "$_text" "$_file" || _problem "missing $_description: $_text"
}

function _expectExactLine {
    local _file="$1"
    local _line="$2"
    local _description="$3"

    grep -Fqx -- "$_line" "$_file" || _problem "missing exact $_description: $_line"
}

function _expectNotContains {
    local _file="$1"
    local _text="$2"
    local _description="$3"
    if grep -Fq -- "$_text" "$_file"; then
        _problem "unexpected $_description: $_text"
    fi
}

function _expectNoTmuxCall {
    if [ -s "$_caseStateDir/tmux.log" ]; then
        _problem "tmux was called unexpectedly"
    fi
}

function _expectNoSleepCall {
    if [ -s "$_caseStateDir/sleep.log" ]; then
        _problem "sleep was called unexpectedly"
    fi
}

function _setFixtureDefaultName {
    local _name="$1"
    local _updatedWrapper="$_caseDir/updated-1MB-start.sh"

    sed "s/^_serverName=.*/_serverName=\"$_name\"/" "$_caseWrapper" >"$_updatedWrapper" || exit 2
    mv "$_updatedWrapper" "$_caseWrapper"
    chmod 0755 "$_caseWrapper"
}

function _makeToolPathWithoutSleep {
    local _path="$1"
    local _tool=""
    local _toolSource=""

    mkdir -p "$_path"
    for _tool in dirname readlink; do
        _toolSource=$(PATH="$_originalPath" command -v "$_tool") || exit 2
        ln -s "$_toolSource" "$_path/$_tool"
    done
    ln -s "$_fakeTmux" "$_path/tmux"
}

function _armSiblingMarker {
    _siblingMarker="$_caseDir/sibling-executed"
    printf '#!/usr/bin/env bash\nprintf "executed\\n" > %q\n' "$_siblingMarker" >"$_caseServerDir/1MB-minecraft.sh"
    chmod 0755 "$_caseServerDir/1MB-minecraft.sh"
}

function _expectSiblingNotExecuted {
    if [ -e "$_siblingMarker" ]; then
        _problem "the sibling launcher was executed unexpectedly"
    fi
}

function _expectLogLine {
    local _line="$1"
    if ! grep -Fqx -- "$_line" "$_caseStateDir/tmux.log" 2>/dev/null; then
        _problem "missing exact tmux call: $_line"
    fi
}

function _expectOnlyTmuxLogLine {
    local _line="$1"
    local _expected="$_caseDir/expected-only-tmux.log"

    printf '%s\n' "$_line" >"$_expected"
    _expectFilesEqual "$_expected" "$_caseStateDir/tmux.log" "tmux call log"
}

function _expectNoLogCommand {
    local _command="$1"
    if grep -q "^${_command}" "$_caseStateDir/tmux.log" 2>/dev/null; then
        _problem "unexpected tmux command: $_command"
    fi
}

function _setExpectedLaunch {
    local _name="$1"
    printf -v _expectedLaunch 'new-session\t-d\t-P\t-F\t#{pane_id}\t-s\t%s\t-c\t%s\texec "./1MB-minecraft.sh"\t;\tset-option\t-p\t-t\t=%s:\tremain-on-exit\ton' \
        "$_name" "$_caseServerDir" "$_name"
}

function _writeExpectedHealthyTmuxLog {
    local _name="$1"
    local _file="$2"

    _setExpectedLaunch "$_name"
    printf '%s\n' \
        "$_expectedLaunch" \
        $'display-message\t-p\t-t\t%42\t#{pane_dead}|#{pane_dead_status}|#{pane_dead_signal}' \
        $'set-option\t-p\t-t\t%42\tremain-on-exit\toff' \
        $'display-message\t-p\t-t\t%42\t#{pane_dead}' \
        'ls' >"$_file"
}

function _expectFilesEqual {
    local _expected="$1"
    local _actual="$2"
    local _description="$3"
    if ! cmp -s "$_expected" "$_actual"; then
        _problem "$_description differs"
        diff -u "$_expected" "$_actual" >&2 || true
    fi
}

function _testHealthyStart {
    local _expectedLog=""
    local _escape=""

    _beginCase "healthy startup uses exact atomic tmux calls"
    _newFixture executable
    _runWrapper healthy mcserver-2
    _expectStatus 0
    _expectEmpty "$_stderrFile" "stderr"
    _expectContains "$_stdoutFile" "To re-attach: tmux attach -t mcserver-2" "attach guidance"
    _expectContains "$_stdoutFile" "tmux session started." "success message"
    _escape=$(printf '\033')
    _expectNotContains "$_stdoutFile" "$_escape" "ANSI escape"
    _expectedLog="$_caseDir/expected-tmux.log"
    _writeExpectedHealthyTmuxLog mcserver-2 "$_expectedLog"
    _expectFilesEqual "$_expectedLog" "$_caseStateDir/tmux.log" "tmux call order"
    printf '%s\n' '2' >"$_caseDir/expected-sleep.log"
    _expectFilesEqual "$_caseDir/expected-sleep.log" "$_caseStateDir/sleep.log" "sleep call"
    _finishCase
}

function _testExplicitStart {
    local _expectedLog=""

    _beginCase "explicit --start is the exact startup alias"

    _newFixture executable
    _runWrapper healthy --start mcserver-2
    _expectStatus 0
    _expectEmpty "$_stderrFile" "stderr"
    _expectedLog="$_caseDir/expected-tmux.log"
    _writeExpectedHealthyTmuxLog mcserver-2 "$_expectedLog"
    _expectFilesEqual "$_expectedLog" "$_caseStateDir/tmux.log" "explicit-start tmux call order"
    _expectContains "$_stdoutFile" "tmux session started." "success message"
    printf '%s\n' '2' >"$_caseDir/expected-sleep.log"
    _expectFilesEqual "$_caseDir/expected-sleep.log" "$_caseStateDir/sleep.log" "sleep call"

    _newFixture executable
    _runWrapper healthy --start
    _expectStatus 0
    _expectedLog="$_caseDir/expected-tmux.log"
    _writeExpectedHealthyTmuxLog mcserver "$_expectedLog"
    _expectFilesEqual "$_expectedLog" "$_caseStateDir/tmux.log" "default explicit-start tmux call order"
    printf '%s\n' '2' >"$_caseDir/expected-sleep.log"
    _expectFilesEqual "$_caseDir/expected-sleep.log" "$_caseStateDir/sleep.log" "default explicit-start sleep call"
    _expectContains "$_stdoutFile" "tmux attach -t mcserver" "default attach guidance"
    _finishCase
}

function _testVersionCommand {
    local _emptyPath=""
    local _headerVersion=""

    _beginCase "version is exact and independent of runtime dependencies"
    _newFixture missing
    _setFixtureDefaultName "Invalid Name"
    _emptyPath="$_caseDir/empty-path"
    mkdir -p "$_emptyPath"
    _runWrapperWithPath healthy "$_emptyPath" --version
    _expectStatus 0
    _headerVersion=$(sed -n 's/^# @Version: //p' "$_target")
    printf '1MB-start.sh %s\n' "$_headerVersion" >"$_caseDir/expected-version"
    _expectFilesEqual "$_caseDir/expected-version" "$_stdoutFile" "version output"
    _expectEmpty "$_stderrFile" "stderr"
    _expectNotContains "$_stdoutFile" "Paper" "runtime product"
    _expectNotContains "$_stdoutFile" "Java" "runtime version"
    _expectNotContains "$_stdoutFile" "Minecraft" "game version"
    _expectNoTmuxCall
    _expectNoSleepCall
    _finishCase
}

function _testDoctorCommand {
    local _emptyPath=""

    _beginCase "doctor aggregates static checks without touching a session"

    _newFixture executable
    _armSiblingMarker
    _runWrapper healthy --doctor
    _expectStatus 0
    _expectEmpty "$_stderrFile" "stderr"
    _expectContains "$_stdoutFile" "Configured default session name: mcserver" "session-name check"
    _expectContains "$_stdoutFile" "3.5a-test" "tmux version"
    _expectContains "$_stdoutFile" "Doctor result: PASS" "healthy result"
    _expectOnlyTmuxLogLine '-V'
    _expectNoSleepCall
    _expectSiblingNotExecuted

    _newFixture symlink
    _runWrapper doctor-version-failure --doctor
    _expectStatus 1
    _expectContains "$_stdoutFile" "Adjacent launcher is missing or unsafe" "unsafe-launcher failure"
    _expectContains "$_stdoutFile" "version check failed" "tmux-version failure"
    _expectContains "$_stdoutFile" "Doctor result: FAIL (2 failed checks)" "aggregated result"
    _expectOnlyTmuxLogLine '-V'
    _expectNoSleepCall

    _newFixture executable
    _setFixtureDefaultName "Invalid Name"
    _runWrapper healthy --doctor
    _expectStatus 1
    _expectContains "$_stdoutFile" 'Configured default session name is invalid: Invalid\ Name' "invalid-default failure"
    _expectContains "$_stdoutFile" "Doctor result: FAIL (1 failed checks)" "invalid-default result"
    _expectOnlyTmuxLogLine '-V'

    _newFixture executable
    _emptyPath="$_caseDir/empty-path"
    mkdir -p "$_emptyPath"
    _runWrapperWithPath healthy "$_emptyPath" --doctor
    _expectStatus 1
    _expectContains "$_stdoutFile" "Required command 'dirname' was not found" "dirname failure"
    _expectContains "$_stdoutFile" "Required command 'readlink' was not found" "readlink failure"
    _expectContains "$_stdoutFile" "Required command 'sleep' was not found" "sleep failure"
    _expectContains "$_stdoutFile" "Could not resolve the physical server directory" "directory failure"
    _expectContains "$_stdoutFile" "tmux was not found" "tmux failure"
    _expectContains "$_stdoutFile" "Doctor result: FAIL" "missing-tools result"
    _expectEmpty "$_stderrFile" "structured doctor stderr"
    _expectNoTmuxCall
    _expectNoSleepCall
    _finishCase
}

function _testConfiguredDefaultName {
    _beginCase "omitted name validates and preserves the configured default"

    _newFixture executable
    _runWrapper healthy
    _expectStatus 0
    _setExpectedLaunch mcserver
    _expectLogLine "$_expectedLaunch"
    _expectContains "$_stdoutFile" "tmux attach -t mcserver" "default attach guidance"

    _newFixture executable
    _runWrapper status-running --status
    _expectStatus 0
    _expectLogLine $'has-session\t-t\t=mcserver'
    _expectContains "$_stdoutFile" "tmux session 'mcserver' is running" "default status"
    _finishCase
}

function _testListFailureIsNonfatal {
    _beginCase "tmux list failure does not redefine startup success"
    _newFixture executable
    _runWrapper list-failure mcserver
    _expectStatus 0
    _expectContains "$_stdoutFile" "tmux session started." "success message"
    _expectLogLine 'ls'
    _finishCase
}

function _testDuplicateSession {
    _beginCase "duplicate session fails without mutating an existing session"
    _newFixture executable
    _runWrapper duplicate mcserver
    _expectStatus 1
    _expectContains "$_stderrFile" "duplicate session" "tmux duplicate error"
    _expectContains "$_stderrFile" "Could not create" "wrapper failure"
    _expectNotContains "$_stdoutFile" "tmux session started." "success message"
    _expectNoLogCommand kill-pane
    _expectNoLogCommand kill-session
    _expectNoLogCommand send-keys
    _finishCase
}

function _testNewFailureWithPane {
    _beginCase "partial new-session failure cleans only the returned pane"
    _newFixture executable
    _runWrapper new-failure-with-pane mcserver
    _expectStatus 1
    _expectLogLine $'kill-pane\t-t\t%42'
    _expectNoLogCommand kill-session
    _finishCase
}

function _testInvalidPane {
    local _scenario="$1"
    local _label="$2"

    _beginCase "$_label"
    _newFixture executable
    _runWrapper "$_scenario" mcserver
    _expectStatus 1
    _expectContains "$_stderrFile" "did not return a valid pane identifier" "invalid-pane error"
    _expectLogLine $'kill-session\t-t\t=mcserver'
    _expectNotContains "$_stdoutFile" "tmux session started." "success message"
    _finishCase
}

function _testChildExit {
    local _scenario="$1"
    local _expectedText="$2"
    local _label="$3"

    _beginCase "$_label"
    _newFixture executable
    _runWrapper "$_scenario" mcserver
    _expectStatus 1
    _expectContains "$_stderrFile" "$_expectedText" "exit description"
    _expectLogLine $'kill-pane\t-t\t%42'
    _expectNoLogCommand ls
    _expectNotContains "$_stdoutFile" "tmux session started." "success message"
    _finishCase
}

function _testFirstDisplayMissing {
    _beginCase "disappearing pane fails and restores close-on-exit best-effort"
    _newFixture executable
    _runWrapper first-display-missing mcserver
    _expectStatus 1
    _expectContains "$_stderrFile" "pane disappeared" "missing-pane error"
    _expectLogLine $'set-option\t-p\t-t\t%42\tremain-on-exit\toff'
    _expectNoLogCommand ls
    _finishCase
}

function _testUnexpectedPaneState {
    _beginCase "unexpected pane state fails closed"
    _newFixture executable
    _runWrapper unexpected-pane-state mcserver
    _expectStatus 1
    _expectContains "$_stderrFile" "unexpected state" "unexpected-state error"
    _expectLogLine $'set-option\t-p\t-t\t%42\tremain-on-exit\toff'
    _expectNoLogCommand ls
    _finishCase
}

function _testRestoreFailure {
    _beginCase "failure to restore close-on-exit prevents success"
    _newFixture executable
    _runWrapper restore-failure mcserver
    _expectStatus 1
    _expectContains "$_stderrFile" "could not restore normal close-on-exit behavior" "restore error"
    _expectNoLogCommand ls
    _finishCase
}

function _testBoundaryResult {
    local _scenario="$1"
    local _label="$2"

    _beginCase "$_label"
    _newFixture executable
    _runWrapper "$_scenario" mcserver
    _expectStatus 1
    _expectContains "$_stderrFile" "ended as the 2-second startup check completed" "boundary error"
    _expectNoLogCommand ls
    if [ "$_scenario" = boundary-dead ]; then
        _expectLogLine $'kill-pane\t-t\t%42'
    else
        _expectNoLogCommand kill-pane
    fi
    _finishCase
}

function _testSleepFailure {
    local _scenario="$1"
    local _expectedText="$2"
    local _label="$3"

    _beginCase "$_label"
    _newFixture executable
    _runWrapper "$_scenario" mcserver
    _expectStatus 1
    _expectContains "$_stderrFile" "$_expectedText" "sleep interruption error"
    _expectLogLine $'set-option\t-p\t-t\t%42\tremain-on-exit\toff'
    _expectNoLogCommand display-message
    _expectNoLogCommand ls
    printf '%s\n' '2' >"$_caseDir/expected-sleep.log"
    _expectFilesEqual "$_caseDir/expected-sleep.log" "$_caseStateDir/sleep.log" "sleep call"
    _finishCase
}

function _testStatusCommands {
    _beginCase "status uses an exact session target and meaningful statuses"

    _newFixture executable
    _runWrapper status-running --status mcserver-2
    _expectStatus 0
    _expectContains "$_stdoutFile" "'mcserver-2' is running" "running status"
    _expectLogLine $'has-session\t-t\t=mcserver-2'

    _newFixture executable
    _runWrapper status-missing --status mcserver-2
    _expectStatus 1
    _expectContains "$_stdoutFile" "'mcserver-2' is not running" "missing status"
    _expectLogLine $'has-session\t-t\t=mcserver-2'
    _finishCase
}

function _testAttachCommands {
    _beginCase "attach uses exec, an exact target, and preserves tmux status"

    _newFixture executable
    _runWrapper attach-running --attach mcserver_3
    _expectStatus 23
    _expectLogLine $'has-session\t-t\t=mcserver_3'
    _expectLogLine $'attach-session\t-t\t=mcserver_3'

    _newFixture executable
    _runWrapper attach-missing --attach mcserver_3
    _expectStatus 1
    _expectContains "$_stderrFile" "No tmux session named 'mcserver_3'" "missing attach error"
    _expectLogLine $'has-session\t-t\t=mcserver_3'
    _expectNoLogCommand attach-session
    _finishCase
}

function _testListCommand {
    _beginCase "list shows all current-user tmux sessions and preserves status"

    _newFixture missing
    _setFixtureDefaultName "Invalid Name"
    _runWrapper list-sessions-present --list
    _expectStatus 0
    _expectEmpty "$_stderrFile" "stderr"
    printf '%s\n' mcserver maintenance_session >"$_caseDir/expected-list"
    _expectFilesEqual "$_caseDir/expected-list" "$_stdoutFile" "listed sessions"
    _expectOnlyTmuxLogLine $'list-sessions\t-F\t#{session_name}'
    _expectNoSleepCall

    _newFixture missing
    _runWrapper list-sessions-empty --list
    _expectStatus 1
    _expectEmpty "$_stdoutFile" "empty-list stdout"
    _expectContains "$_stderrFile" "no server running on test socket" "empty-list diagnostic"
    _expectOnlyTmuxLogLine $'list-sessions\t-F\t#{session_name}'
    _expectNoSleepCall

    _newFixture missing
    _runWrapper list-sessions-failure --list
    _expectStatus 17
    _expectEmpty "$_stdoutFile" "failed-list stdout"
    _expectContains "$_stderrFile" "list query failed" "list failure"
    _expectOnlyTmuxLogLine $'list-sessions\t-F\t#{session_name}'
    _expectNoSleepCall
    _finishCase
}

function _testSiblingValidation {
    local _mode=""

    _beginCase "invalid sibling file types and permissions fail before tmux"
    for _mode in missing nonexecutable unreadable directory symlink; do
        _newFixture "$_mode"
        _runWrapper healthy mcserver
        _expectStatus 1
        _expectContains "$_stderrFile" "must be a regular, non-symlink, readable and executable file" "sibling validation"
        _expectNoTmuxCall
    done
    _finishCase
}

function _testDryRunCommand {
    local _expectedCommand=""
    local _tool=""
    local _toolPath=""
    local _toolSource=""

    _beginCase "dry-run previews the exact launch without side effects"

    _newFixture executable
    _armSiblingMarker
    _runWrapper healthy --dry-run mcserver-2
    _expectStatus 0
    _expectEmpty "$_stderrFile" "stderr"
    _expectContains "$_stdoutFile" "Static launch preflight passed." "preflight result"
    _expectContains "$_stdoutFile" "Session: mcserver-2" "session"
    _expectContains "$_stdoutFile" "server\\ directory\\ with\\ spaces" "escaped server directory"
    _expectContains "$_stdoutFile" "Startup check: 2 seconds (not performed)" "unperformed probe"
    _expectContains "$_stdoutFile" "sleep executable:" "resolved sleep"
    _expectContains "$_stdoutFile" "Session availability: not checked" "unqueried session"
    # The Bash under test renders the same argument vector format as dry-run.
    # shellcheck disable=SC2016
    _expectedCommand=$("$_bashUnderTest" -c 'printf "Command:"; for argument in "$@"; do printf " %q" "$argument"; done; printf "\n"' \
        _ "$_fakeTmux" new-session -d -P -F '#{pane_id}' -s mcserver-2 \
        -c "$_caseServerDir" 'exec "./1MB-minecraft.sh"' ';' \
        set-option -p -t '=mcserver-2:' remain-on-exit on)
    _expectExactLine "$_stdoutFile" "$_expectedCommand" "launch command preview"
    _expectContains "$_stdoutFile" "no tmux session was created" "side-effect notice"
    _expectNotContains "$_stdoutFile" "tmux session started." "startup success"
    _expectNoTmuxCall
    _expectNoSleepCall
    _expectSiblingNotExecuted

    _newFixture executable
    _runWrapper healthy --dry-run
    _expectStatus 0
    _expectContains "$_stdoutFile" "Session: mcserver" "default session"
    _expectContains "$_stdoutFile" "--status mcserver" "default status guidance"
    _expectNoTmuxCall
    _expectNoSleepCall

    _newFixture missing
    _runWrapper healthy --dry-run mcserver
    _expectStatus 1
    _expectContains "$_stderrFile" "must be a regular, non-symlink, readable and executable file" "missing sibling"
    _expectNoTmuxCall
    _expectNoSleepCall

    _newFixture executable
    _toolPath="$_caseDir/path-without-tmux"
    mkdir -p "$_toolPath"
    for _tool in dirname readlink sleep; do
        _toolSource=$(PATH="$_originalPath" command -v "$_tool") || exit 2
        ln -s "$_toolSource" "$_toolPath/$_tool"
    done
    _runWrapperWithPath healthy "$_toolPath" --dry-run mcserver
    _expectStatus 1
    _expectContains "$_stderrFile" "'tmux' is required but was not found" "missing tmux"
    _expectNoTmuxCall
    _expectNoSleepCall
    _finishCase
}

function _testMissingSleepPreflight {
    local _toolPath=""

    _beginCase "missing sleep fails start and dry-run before tmux"

    _newFixture executable
    _toolPath="$_caseDir/path-without-sleep"
    _makeToolPathWithoutSleep "$_toolPath"
    _runWrapperWithPath healthy "$_toolPath" --dry-run mcserver
    _expectStatus 1
    _expectContains "$_stderrFile" "'sleep' is required" "dry-run sleep dependency"
    _expectNoTmuxCall
    _expectNoSleepCall

    _newFixture executable
    _toolPath="$_caseDir/path-without-sleep"
    _makeToolPathWithoutSleep "$_toolPath"
    _runWrapperWithPath healthy "$_toolPath" --start mcserver
    _expectStatus 1
    _expectContains "$_stderrFile" "'sleep' is required" "startup sleep dependency"
    _expectNoTmuxCall
    _expectNoSleepCall
    _finishCase
}

function _testMissingTmux {
    local _emptyPath=""

    _beginCase "missing tmux fails clearly without falling back"
    _newFixture executable
    _emptyPath="$_caseDir/empty-path"
    mkdir -p "$_emptyPath"
    : >"$_stdoutFile"
    : >"$_stderrFile"
    NO_COLOR=1 \
        PATH="$_emptyPath" \
        TMUX='' \
        TMUX_TMPDIR="$_caseStateDir/tmux-socket" \
        "$_bashUnderTest" "$_caseWrapper" --status mcserver >"$_stdoutFile" 2>"$_stderrFile"
    _runStatus=$?
    _expectStatus 1
    _expectContains "$_stderrFile" "'tmux' is required but was not found" "missing-tmux error"
    _expectNoTmuxCall
    _finishCase
}

function _testNames {
    local _name=""
    local _validNames=(a 0 mcserver1 mcserver-2 mcserver_3 1mb abcdefghijklmnopq a1234567890123456789012345678901)
    local _invalidNames=("" MCServer -server _server " mcserver" "mcserver " "mc server" $'mc\tserver' $'mc\nserver' mcserver:1 mcserver.1 'mcserver*' 'mcserver?' mc/server '=mcserver' "\$1" @mcserver +mcserver a12345678901234567890123456789012 'mcsérver')

    _beginCase "complete session names are preserved or rejected without tmux"
    for _name in "${_validNames[@]}"; do
        _newFixture executable
        _runWrapper status-running --status "$_name"
        _expectStatus 0
        _expectContains "$_stdoutFile" "tmux session '$_name' is running" "preserved session name"
        _expectLogLine "has-session"$'\t'"-t"$'\t'"=$_name"
    done

    for _name in "${_invalidNames[@]}"; do
        _newFixture executable
        _runWrapper status-running --status "$_name"
        _expectStatus 1
        _expectContains "$_stderrFile" "Invalid session name." "invalid-name error"
        _expectNoTmuxCall
    done
    _finishCase
}

function _testArgumentsAndHelp {
    _beginCase "help works and surplus or unknown arguments fail before tmux"

    _newFixture executable
    _runWrapper healthy --help
    _expectStatus 0
    _expectContains "$_stdoutFile" "Names use 1-32 lowercase ASCII letters" "name help"
    _expectContains "$_stdoutFile" "--version" "version help"
    _expectContains "$_stdoutFile" "--doctor" "doctor help"
    _expectContains "$_stdoutFile" "--start [name]" "start help"
    _expectContains "$_stdoutFile" "--list" "list help"
    _expectContains "$_stdoutFile" "--dry-run [name]" "dry-run help"
    _expectContains "$_stdoutFile" "all tmux session names visible to the current OS user" "list scope help"
    _expectNoTmuxCall

    _newFixture executable
    _runWrapper healthy --help extra
    _expectStatus 1
    _expectContains "$_stderrFile" "Unexpected extra arguments." "help arity error"
    _expectNoTmuxCall

    _newFixture executable
    _runWrapper healthy --version extra
    _expectStatus 1
    _expectContains "$_stderrFile" "Unexpected extra arguments." "version arity error"
    _expectNoTmuxCall

    _newFixture executable
    _runWrapper healthy --doctor extra
    _expectStatus 1
    _expectContains "$_stderrFile" "Unexpected extra arguments." "doctor arity error"
    _expectNoTmuxCall

    _newFixture executable
    _runWrapper healthy --start mcserver extra
    _expectStatus 1
    _expectContains "$_stderrFile" "Unexpected extra arguments." "start arity error"
    _expectNoTmuxCall

    _newFixture executable
    _runWrapper healthy --status mcserver extra
    _expectStatus 1
    _expectContains "$_stderrFile" "Unexpected extra arguments." "status arity error"
    _expectNoTmuxCall

    _newFixture executable
    _runWrapper healthy --attach mcserver extra
    _expectStatus 1
    _expectContains "$_stderrFile" "Unexpected extra arguments." "attach arity error"
    _expectNoTmuxCall

    _newFixture executable
    _runWrapper healthy --dry-run mcserver extra
    _expectStatus 1
    _expectContains "$_stderrFile" "Unexpected extra arguments." "dry-run arity error"
    _expectNoTmuxCall

    _newFixture executable
    _runWrapper healthy --list extra
    _expectStatus 1
    _expectContains "$_stderrFile" "Unexpected extra arguments." "list arity error"
    _expectNoTmuxCall

    _newFixture executable
    _runWrapper healthy mcserver extra
    _expectStatus 1
    _expectContains "$_stderrFile" "Unexpected extra arguments." "startup arity error"
    _expectNoTmuxCall

    _newFixture executable
    _runWrapper healthy --start --help
    _expectStatus 1
    _expectContains "$_stderrFile" "Invalid session name." "option-like start name"
    _expectNoTmuxCall

    _newFixture executable
    _runWrapper healthy --dry-run "Invalid Name"
    _expectStatus 1
    _expectContains "$_stderrFile" "Invalid session name." "invalid dry-run name"
    _expectNoTmuxCall

    _newFixture executable
    _runWrapper healthy --unknown
    _expectStatus 1
    _expectContains "$_stderrFile" "Unknown option '--unknown'" "unknown-option error"
    _expectNoTmuxCall
    _finishCase
}

function _testOutputHelper {
    local _fragment=""
    local _escape=""

    _beginCase "output helper preserves success, failure, debug, and no-color behavior"
    _newFixture executable
    _fragment="$_caseDir/output-function.sh"
    sed -n '/^function _output {$/,/^}$/p' "$_target" >"$_fragment"

    : >"$_stdoutFile"
    : >"$_stderrFile"
    # The nested Bash, not this runner, deliberately expands these variables.
    # shellcheck disable=SC2016
    "$_bashUnderTest" -c '_debug=true; unset NO_COLOR; source "$1"; _output okay "successful message"; result=$?; printf "continued:%s\n" "$result"; exit "$result"' _ "$_fragment" >"$_stdoutFile" 2>"$_stderrFile"
    _runStatus=$?
    _expectStatus 0
    _expectContains "$_stdoutFile" "successful message" "okay output"
    _expectContains "$_stdoutFile" "continued:0" "caller continuation"
    _expectEmpty "$_stderrFile" "okay stderr"
    _escape=$(printf '\033')
    _expectNotContains "$_stdoutFile" "$_escape" "non-TTY ANSI escape"

    : >"$_stdoutFile"
    : >"$_stderrFile"
    # shellcheck disable=SC2016
    "$_bashUnderTest" -c '_debug=true; source "$1"; _output oops "fatal message"; printf "unreachable\n"' _ "$_fragment" >"$_stdoutFile" 2>"$_stderrFile"
    _runStatus=$?
    _expectStatus 1
    _expectEmpty "$_stdoutFile" "oops stdout"
    _expectContains "$_stderrFile" "fatal message" "oops output"
    _expectNotContains "$_stderrFile" "unreachable" "post-oops output"

    : >"$_stdoutFile"
    : >"$_stderrFile"
    # shellcheck disable=SC2016
    "$_bashUnderTest" -c '_debug=false; source "$1"; _output debug "hidden"; result=$?; exit "$result"' _ "$_fragment" >"$_stdoutFile" 2>"$_stderrFile"
    _runStatus=$?
    _expectStatus 0
    _expectEmpty "$_stdoutFile" "disabled debug stdout"
    _expectEmpty "$_stderrFile" "disabled debug stderr"
    _finishCase
}

function _runBehaviorForBash {
    local _version=""

    _bashUnderTest="$1"
    _version=$("$_bashUnderTest" --version | sed -n '1p')
    printf '\nBehavior tests with %s\n' "$_version"

    _testHealthyStart
    _testExplicitStart
    _testVersionCommand
    _testDoctorCommand
    _testConfiguredDefaultName
    _testListFailureIsNonfatal
    _testDuplicateSession
    _testNewFailureWithPane
    _testInvalidPane empty-pane "empty pane identifier closes only the new session"
    _testInvalidPane malformed-pane "malformed pane identifier closes only the new session"
    _testChildExit child-exit-zero "exit status 0" "immediate clean child exit is reported"
    _testChildExit child-exit-seven "exit status 7" "immediate nonzero child exit is reported"
    _testChildExit child-signal-fifteen "signal 15" "immediate signal termination is reported"
    _testChildExit child-unknown-exit "unknown exit status" "missing child exit metadata is reported"
    _testFirstDisplayMissing
    _testUnexpectedPaneState
    _testRestoreFailure
    _testBoundaryResult boundary-dead "death at the probe boundary fails safely"
    _testBoundaryResult boundary-disappeared "disappearance at the probe boundary fails safely"
    _testSleepFailure sleep-failure "startup check was interrupted" "interrupted probe restores close-on-exit"
    _testSleepFailure sleep-failure-restore-failure "could not restore normal close-on-exit behavior" "interrupted probe reports restore failure"
    _testStatusCommands
    _testAttachCommands
    _testListCommand
    _testSiblingValidation
    _testDryRunCommand
    _testMissingSleepPreflight
    _testMissingTmux
    _testNames
    _testArgumentsAndHelp
    _testOutputHelper
}

function _runSyntaxChecks {
    local _bashPath=""
    local _file=""
    local _version=""
    local _syntaxFailed=0
    local _files=("$_target" "$_runner" "$_fakeTmux" "$_fakeSleep")

    for _bashPath in "${_bashPaths[@]}"; do
        _version=$("$_bashPath" --version | sed -n '1p')
        _syntaxFailed=0
        for _file in "${_files[@]}"; do
            if ! "$_bashPath" -n "$_file"; then
                _syntaxFailed=1
            fi
        done
        if [ "$_syntaxFailed" -eq 0 ]; then
            _pass "syntax with $_version"
        else
            _fail "syntax with $_version"
        fi
    done
}

function _runShellCheck {
    if ! command -v shellcheck >/dev/null 2>&1; then
        _fail "ShellCheck is required for '$_mode' (macOS: brew install shellcheck; Ubuntu: apt install shellcheck)"
        return
    fi

    if shellcheck --shell=bash "$_target" "$_runner" "$_fakeTmux" "$_fakeSleep"; then
        _pass "ShellCheck"
    else
        _fail "ShellCheck"
    fi
}

if [ ! -f "$_target" ] || [ ! -f "$_runner" ] || \
    [ ! -f "$_fakeTmux" ] || [ ! -x "$_fakeTmux" ] || \
    [ ! -f "$_fakeSleep" ] || [ ! -x "$_fakeSleep" ]; then
    printf '%s\n' "Test suite files are incomplete." >&2
    exit 2
fi

if [ "$(PATH="$_suiteDir/fake-bin:$_originalPath" command -v tmux 2>/dev/null)" != "$_fakeTmux" ] || \
    [ "$(PATH="$_suiteDir/fake-bin:$_originalPath" command -v sleep 2>/dev/null)" != "$_fakeSleep" ]; then
    printf '%s\n' "The test fakes do not take precedence in PATH; refusing to run." >&2
    exit 2
fi

_discoverBashes
if [ "${#_bashPaths[@]}" -eq 0 ]; then
    printf '%s\n' "No Bash interpreter was found." >&2
    exit 2
fi

if [ "$_mode" != lint ]; then
    if [ "$EUID" -eq 0 ]; then
        printf '%s\n' "Behavior tests must not run as root because the wrapper intentionally rejects root." >&2
        exit 2
    fi

    _tempRoot=$(mktemp -d "${TMPDIR:-/tmp}/1mb-start-tests.XXXXXX") || exit 2
    _tempRoot=$(cd -P -- "$_tempRoot" >/dev/null 2>&1 && pwd -P) || exit 2
    _runSyntaxChecks
    for _bashUnderTest in "${_bashPaths[@]}"; do
        _runBehaviorForBash "$_bashUnderTest"
    done
fi

if [ "$_mode" != test ]; then
    _runShellCheck
fi

printf '\nSummary: %s passed, %s failed, %s skipped\n' "$_passed" "$_failed" "$_skipped"
[ "$_failed" -eq 0 ]
