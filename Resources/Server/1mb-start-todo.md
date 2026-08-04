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

## Critical

- [x] Stop immediately when tmux session creation fails; never send startup
  text to an existing session. Completed in `2.17.0`, build `073`.

## High priority

- [ ] Resolve `1MB-minecraft.sh` relative to the wrapper's own directory, not
  the caller's current working directory. This is required for reliable
  launchd, systemd, SSH, and absolute-path invocation.
- [ ] Replace the two-stage `tmux new` plus `tmux send-keys` launch with one
  checked, atomic `tmux new-session -d` command that starts the sibling
  directly.
- [ ] Preserve and report tmux failures accurately. Do not suppress the useful
  tmux diagnostic or print `Done` after a failed child launch.
- [ ] Fix `_debug=false`: the final debug call currently returns status `1`, so
  an otherwise successful wrapper exits as a failure when debug output is
  disabled.
- [ ] Remove the implicit GNU Screen fallback, make it explicit opt-in, or add
  reliable duplicate-session protection and checked startup. Screen permits
  materially different and potentially duplicate session behavior.
- [ ] Add a per-server-instance lock in `1MB-minecraft.sh` during that script's
  later review. Different tmux names can otherwise launch the same server
  directory twice, and this wrapper cannot protect standalone launches.

## Medium priority

- [ ] Stop splitting and truncating the requested session name before
  validation. Validate the complete input and length, reject invalid or
  overlong names, and reject unexpected extra arguments.
- [ ] Decide whether the tmux session should close when
  `1MB-minecraft.sh` exits. Starting the script as the pane's direct process
  avoids the current stale shell/session after Paper stops.
- [ ] Establish deterministic command discovery for non-login environments.
  Account for Apple Silicon Homebrew (`/opt/homebrew/bin`), Intel Homebrew
  (`/usr/local/bin`), and standard macOS/Ubuntu paths.
- [ ] Remove the implicit foreground fallback. If tmux is unavailable, fail
  clearly and let users run `1MB-minecraft.sh` directly for foreground tests.
- [ ] Use exact tmux targets such as `-t "=$name"` in scripted checks so prefix
  matching cannot select another session.

## Low priority and cleanup

- [ ] Replace `echo -e` with Bash's built-in `printf`.
- [ ] Make output-function variables local, initialize or remove the undefined
  `B` and `X` color variables, and correct the `okay` branch so it does not exit
  with status `1`.
- [ ] Emit ANSI colors only to an interactive terminal and honor `NO_COLOR` so
  launchd/systemd logs remain clean.
- [ ] Verify that the sibling is a regular readable and executable file, and
  include its absolute path in errors.
- [ ] Correct the Ubuntu dependency hint to recommend `apt install tmux` when
  tmux is the preferred backend.
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

1. Confirm whether automatic Screen support may be removed.
2. Confirm whether the tmux session should disappear when Paper stops.
3. Confirm whether session names remain letters-only or expand to a documented
   safe character set.
4. Confirm which quality-of-life commands, if any, belong in this intentionally
   small wrapper.
