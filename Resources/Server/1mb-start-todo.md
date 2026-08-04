# `1MB-start.sh` modernization TODO

This file records the reviewed improvements for `1MB-start.sh`. Do not apply
the remaining items silently: they should be approved, implemented, and tested
as deliberate follow-up changes.

## Known live baseline

- Script version: `2.16.3`, build `072`
- Release date: August 4, 2026
- Status: working, tested, and live in August 2026
- Git baseline: `a2dc6cc8f5d14062b848c87389859e1eab1e4e48`
- Baseline source:
  `git show a2dc6cc8f5d14062b848c87389859e1eab1e4e48:Resources/Server/1MB-start.sh`

The baseline records the proven production version; it is not a claim that the
script was free of edge-case defects. New work begins with version `2.17.0`,
build `073`.

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

## Critical

- [x] Stop immediately when tmux session creation fails; never send startup
  text to an existing session. Completed in `2.17.0`, build `073`.

## High priority

- [x] Resolve `1MB-minecraft.sh` relative to the wrapper's own directory, not
  the caller's current working directory. Completed in `2.17.3`, build `076`,
  including launchd, systemd, SSH, PATH, absolute-path, and symlinked
  invocation scenarios.
- [x] Replace the two-stage `tmux new` plus `tmux send-keys` launch with one
  checked, atomic `tmux new-session -d` command that starts the sibling
  directly. Completed in `2.17.2`, build `075`.
- [ ] Detect and report when the child exits immediately after tmux successfully
  creates the session. The tmux command confirms session creation, not that
  Paper completed startup.
- [x] Fix `_debug=false`: disabled debug messages now return success, so an
  otherwise successful wrapper exits successfully. Completed in `2.17.5`,
  build `078`.
- [x] Remove the implicit GNU Screen fallback. Completed in `2.17.1`, build
  `074`; tmux is now required.
- [ ] Add a per-server-instance lock in `1MB-minecraft.sh` during that script's
  later review. Different tmux names can otherwise launch the same server
  directory twice, and this wrapper cannot protect standalone launches.

## Medium priority

- [ ] Stop splitting and truncating the requested session name before
  validation. Validate the complete input and length, reject invalid or
  overlong names, and reject unexpected extra arguments.
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
- [ ] Correct the `okay` branch so a successful status message does not exit
  with status `1`.
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

- [ ] Keep compatibility with the stock macOS Bash 3.2 and current Ubuntu
  Bash. Avoid Bash 4-only lowercase expansion, associative arrays, `mapfile`,
  GNU `flock`, and `readlink -f`.
- [ ] Introduce a `main "$@"` function and explicit checked error paths. Review
  all helper return statuses before considering `set -e`; `set -u` and
  `set -o pipefail` can then be evaluated safely.
- [ ] Add optional `--help`, `--version`, `--status`, and `--attach` commands
  only if their added complexity is worthwhile.
- [ ] Add repeatable checks with `bash -n`, ShellCheck, and disposable fake or
  isolated tmux sessions for success, duplicate-name, missing-sibling, and
  missing-dependency paths.
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

1. Confirm whether session names remain letters-only or expand to a documented
   safe character set.
2. Confirm which quality-of-life commands, if any, belong in this intentionally
   small wrapper.
