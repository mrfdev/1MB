# `1MB-start.sh` modernization TODO

This file records the reviewed improvements for `1MB-start.sh`. Do not apply
the remaining items silently: they should be approved, implemented, and tested
as deliberate follow-up changes.

## Known live baseline

- Script version: `2.17.9`, build `082`
- Release date: August 4, 2026
- Status: working, tested, and live in August 2026
- Git baseline: `c5f6c8c5c5ee4545ec4d0dcccaa46e8cc2fc52dc`
- Baseline source:
  `git show c5f6c8c5c5ee4545ec4d0dcccaa46e8cc2fc52dc:Resources/Server/1MB-start.sh`

The baseline records the proven production version; it is not a claim that the
script is free of edge-case defects. Follow-up work continues with version
`2.18.3`, build `086`.

## Completed in 2.17.0 build 073

- Status: locally syntax-tested and behavior-tested; not yet marked live.
- [x] **Critical — prevent commands from being injected into an existing tmux
  session.** The old top-level `return 1` did not terminate an executed Bash
  script when `tmux new` failed. Execution could continue into `tmux
  send-keys`, typing `./1MB-minecraft.sh` and Enter into an existing Paper
  console or stale shell. A failed tmux session creation now halts through the
  existing error path before `send-keys` can run.

No other behavioral modernization item below is included in this narrowly
scoped fix. The file's missing final newline was normalized mechanically.

## Completed in 2.17.1 build 074

- [x] Removed GNU Screen support. `tmux` is now the wrapper's only detached
  session backend.
- [x] Removed the automatic foreground fallback. A missing `tmux` executable
  now stops the wrapper instead of starting Paper outside a detached session.
- [x] Added a focused macOS installation hint: `brew install tmux`. Ubuntu
  installation guidance is intentionally omitted.

## Completed in 2.17.2 build 075

- [x] Replaced the separate `tmux new` and `tmux send-keys` operations with one
  checked `tmux new-session -d` command that directly executes
  `1MB-minecraft.sh`.
- [x] Made the approved lifecycle explicit: the tmux session closes when
  `1MB-minecraft.sh` exits, so a stopped or crashed server does not leave a
  stale shell session behind.
- [x] Stopped suppressing tmux's own session-creation error output.

## Completed in 2.17.3 build 076

- [x] Resolve the physical directory containing `1MB-start.sh` instead of
  relying on the caller's current working directory.
- [x] Support relative, absolute, PATH-based, and symlinked invocation without
  depending on GNU-only `readlink -f`, preserving compatibility with macOS and
  Ubuntu.
- [x] Give tmux the resolved server directory explicitly with `new-session -c`
  and validate the sibling through its resolved absolute path.

## Completed in 2.17.4 build 077

- [x] Replaced `echo -e` with Bash's built-in `printf` using fixed format
  strings and `%s` message arguments.
- [x] Emit ANSI colours only when the actual output destination is a terminal
  and `NO_COLOR` is not set. Stdout and stderr are checked independently.
- [x] Made output-function state local and removed the undefined `B` and `X`
  colour variables.

## Completed in 2.17.5 build 078

- [x] Disabled debug messages now return success without producing output, so
  `_debug=false` no longer turns an otherwise successful wrapper run into exit
  status `1`.
- [x] Real startup failures remain nonzero and continue through their existing
  error paths when debug output is disabled.

## Completed in 2.17.6 build 079

- [x] Report `tmux session started.` after successful session creation instead
  of implying that Paper completed startup. The wrapper can confirm tmux's
  result, but it cannot confirm that Paper reached its ready state.

## Completed in 2.17.7 build 080

- [x] Require `1MB-minecraft.sh` to be a regular, non-symlink, readable and
  executable file physically located beside the resolved `1MB-start.sh`.
- [x] Continue launching that exact sibling through `./1MB-minecraft.sh` with
  tmux's working directory fixed to the wrapper directory. The caller's current
  directory, `PATH`, other directories, and other volumes are not searched.

## Completed in 2.17.8 build 081

- [x] Audited the complete wrapper against macOS's stock Bash `3.2.57` and
  verified that it contains no Bash 4+ constructs.
- [x] Retained Bash 3.2-compatible implementations for case conversion,
  indexed `BASH_SOURCE`, output handling, symlink resolution, and conditionals.
- [x] Changed awk's substring start index from implementation-tolerated `0` to
  POSIX-defined `1`, preserving the existing 16-character truncation on both
  macOS and Ubuntu.

## Completed in 2.17.9 build 082

- [x] Added `--help` (`-h`) with concise usage that works without tmux or an
  adjacent `1MB-minecraft.sh`.
- [x] Added `--status [name]`, using an exact tmux session target and exit
  status `0` for running or `1` for not running.
- [x] Added `--attach [name]`, which checks the exact session and then replaces
  the wrapper with `tmux attach-session` so tmux's exit status is preserved.
- [x] Kept sibling resolution and validation exclusive to normal startup, so
  existing sessions remain inspectable when the sibling file is unavailable.

## Completed in 2.18.0 build 083

- [x] Added a two-second liveness check for the exact tmux pane created for
  `1MB-minecraft.sh`; attach guidance and success output now wait for it.
- [x] Temporarily retain only that new pane during the check, allowing immediate
  clean exits, nonzero statuses, and terminating signals to be reported.
- [x] Restore `remain-on-exit=off` after a successful check so the tmux session
  still closes normally whenever `1MB-minecraft.sh` later exits.
- [x] Keep the check explicitly bounded to process liveness; it does not claim
  that Paper completed startup.

## Completed in 2.18.1 build 084

- [x] Successful `_output okay` messages now write to stdout, return status
  `0`, and allow the caller to continue instead of terminating the wrapper.
- [x] The fatal `_output oops` path remains unchanged: it writes to stderr and
  exits with status `1`.

## Completed in 2.18.2 build 085

- [x] Validate the complete requested session name without lowercasing,
  splitting or truncating it. Names use 1-32 lowercase ASCII letters, numbers,
  hyphens or underscores and must begin with a letter or number.
- [x] Validate the configured default name through the same path and reject
  empty, uppercase, overlong or otherwise invalid names with a clear error.
- [x] Reject unexpected extra arguments for startup, `--help`, `--status` and
  `--attach` instead of silently ignoring them.

## Completed in 2.18.3 build 086

- [x] Added a committed Bash 3.2-compatible test runner with syntax, behavioral
  and ShellCheck modes under `Resources/Server/tests/1MB-start/`.
- [x] Added scenario-driven fake `tmux` and instant fake `sleep` executables.
  Disposable fixtures exercise startup success and failure without contacting
  a real tmux server or launching Paper.
- [x] Covered exact atomic launch arguments, duplicate sessions, pane and child
  exit states, probe-boundary races, status and attach behavior, sibling and
  dependency failures, session names, argument arity, and output semantics.
- [x] Added a path-filtered GitHub Actions workflow that runs the complete suite
  with ShellCheck on current macOS and Ubuntu hosted runners.

## Critical

- [x] Stop immediately when tmux session creation fails; never send startup
  text to an existing session. Completed in `2.17.0`, build `073`.

## High priority

- [x] Resolve `1MB-minecraft.sh` relative to the wrapper's own directory, not
  the caller's current working directory. Completed in `2.17.3`, build `076`,
  including launchd, systemd, SSH, PATH, absolute-path, and symlinked
  invocation scenarios.
- [x] Reject a symlinked `1MB-minecraft.sh`, preventing the adjacent filename
  from redirecting execution to a file in another location. Completed in
  `2.17.7`, build `080`.
- [x] Replace the two-stage `tmux new` plus `tmux send-keys` launch with one
  checked, atomic `tmux new-session -d` command that starts the sibling
  directly. Completed in `2.17.2`, build `075`.
- [x] Detect and report when the child exits immediately after tmux successfully
  creates the session. Completed in `2.18.0`, build `083`, with a two-second
  exact-pane liveness check that does not claim Paper completed startup.
- [x] Fix `_debug=false`: disabled debug messages now return success, so an
  otherwise successful wrapper exits successfully. Completed in `2.17.5`,
  build `078`.
- [x] Remove the implicit GNU Screen fallback. Completed in `2.17.1`, build
  `074`; tmux is now required.
- [ ] Add a per-server-instance lock in `1MB-minecraft.sh` during that script's
  later review. Different tmux names can otherwise launch the same server
  directory twice, and this wrapper cannot protect standalone launches.

## Medium priority

- [x] Stop splitting and truncating the requested session name before
  validation. Validate the complete input and length, reject invalid or
  overlong names, and reject unexpected extra arguments. Completed in
  `2.18.2`, build `085`.
- [x] Close the tmux session when `1MB-minecraft.sh` exits. Approved and
  completed in `2.17.2`, build `075`; the launcher is now the pane's direct
  process.
- [ ] Establish deterministic command discovery for non-login environments.
  Account for Apple Silicon Homebrew (`/opt/homebrew/bin`), Intel Homebrew
  (`/usr/local/bin`), and standard macOS/Ubuntu paths.
- [x] Remove the implicit foreground fallback. Completed in `2.17.1`, build
  `074`; a missing tmux executable now fails clearly.
- [x] Remove the scripted tmux target lookup. Completed in `2.17.2`, build
  `075`; the atomic launch no longer uses `send-keys` against a separate
  session target.

## Low priority and cleanup

- [x] Replace `echo -e` with Bash's built-in `printf`. Completed in `2.17.4`,
  build `077`.
- [x] Make output-function variables local and remove the undefined `B` and `X`
  colour variables. Completed in `2.17.4`, build `077`.
- [x] Correct the `okay` branch so a successful status message does not exit
  with status `1`. Completed in `2.18.1`, build `084`.
- [x] Emit ANSI colours only to an interactive terminal and honor `NO_COLOR`
  so launchd/systemd logs remain clean. Completed in `2.17.4`, build `077`.
- [x] Verify that the sibling is a regular readable and executable file, and
  include its absolute path in errors. Completed in `2.17.3`, build `076`.
- [x] Remove the obsolete Screen and Ubuntu dependency hints. Completed in
  `2.17.1`, build `074`; the missing-tmux error gives the requested macOS
  Homebrew command only.
- [ ] Make the wrapper header independent of Paper and Java versions, because
  RAM, JVM selection, Java version, and Paper arguments belong in
  `1MB-minecraft.sh`.
- [x] Add the missing final newline. Completed mechanically in `2.17.0`, build
  `073`; broader formatting remains deferred.

## Bash hardening and quality of life

- [x] Keep compatibility with the stock macOS Bash 3.2 and current Ubuntu
  Bash. Avoid Bash 4-only lowercase expansion, associative arrays, `mapfile`,
  GNU `flock`, and `readlink -f`. Audited and tested in `2.17.8`, build `081`.
- [ ] Introduce a `main "$@"` function and explicit checked error paths. Review
  all helper return statuses before considering `set -e`; `set -u` and
  `set -o pipefail` can then be evaluated safely.
- [x] Add small `--help`, `--status`, and `--attach` commands. Completed in
  `2.17.9`, build `082`; `--version` was intentionally not added.
- [x] Add repeatable checks with `bash -n`, ShellCheck, and disposable fake or
  isolated tmux sessions for success, duplicate-name, missing-sibling, and
  missing-dependency paths. Completed in `2.18.3`, build `086`, with committed
  local tests and path-filtered macOS/Ubuntu CI.
- [ ] Consider an optional `umask 027` only after auditing backup, web, and
  group-access requirements. Do not change inherited Paper file permissions
  as part of an unrelated launcher update.

## Deliberately outside this wrapper

- Keep the 10 GB memory allocation, Java discovery, JVM flags, and Paper
  arguments in `1MB-minecraft.sh`.
- Do not add `&`, `nohup`, or `disown`; detached tmux already provides the
  background session.
- Do not add `caffeinate` by default. The live Mac is already configured with
  system sleep and disk sleep disabled.
- Treat tmux as an interactive console, not a crash or boot supervisor. Use a
  separate launchd configuration on macOS or systemd unit on Ubuntu for boot
  orchestration. A service that calls this detached wrapper must be one-shot;
  applying `KeepAlive` or `Restart=always` to the wrapper itself would create a
  restart loop.
- Graceful shutdown must send Paper `stop` and wait. Killing a tmux session is
  not a safe Minecraft shutdown procedure.

## Compatibility decisions before the next larger revision

1. [x] Session names use a documented safe set: 1-32 lowercase ASCII letters,
   numbers, hyphens or underscores, beginning with a letter or number.
   Completed in `2.18.2`, build `085`.
2. Confirm which quality-of-life commands, if any, belong in this intentionally
   small wrapper.
