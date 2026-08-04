# `1MB-start.sh` tests

This suite tests `../../1MB-start.sh` without starting Paper or contacting a
real tmux server. Every behavioral test runs against disposable copies under a
temporary directory and prepends the committed fake `tmux` and `sleep`
executables to `PATH`. The runner refuses to continue unless those exact fakes
resolve first and also assigns a disposable `TMUX_TMPDIR` as a second isolation
layer.

Run the complete suite from the repository root:

```bash
Resources/Server/tests/1MB-start/run-tests.sh
```

The default `all` mode runs:

- `bash -n` with macOS's Bash 3.2 and any supported modern Bash found locally;
- fake-tmux behavioral tests with every discovered Bash interpreter;
- ShellCheck over the production wrapper, runner, and fake executables.

ShellCheck is the only additional dependency for `all` and `lint` mode:

```bash
# macOS
brew install shellcheck

# Ubuntu
sudo apt install shellcheck
```

Individual modes are available when needed:

```bash
# Bash syntax and fake-tmux behavior only
Resources/Server/tests/1MB-start/run-tests.sh test

# ShellCheck only
Resources/Server/tests/1MB-start/run-tests.sh lint
```

The behavior suite covers healthy startup, exact tmux targets, duplicate
sessions, child exit statuses and signals, probe-boundary failures,
`remain-on-exit` restoration, missing or invalid siblings, missing tmux,
status and attach behavior, session-name validation, argument validation, and
output return/stream behavior. The fake `sleep` makes the two-second liveness
probe complete immediately.

Tests must not be run with `sudo`: the production wrapper deliberately refuses
to run as root. When a test fails, its disposable state and tmux call log are
retained and their location is printed. Successful runs remove their temporary
state.
