#!/usr/bin/env bash

# @Filename: 1MB-minecraft.sh
# @Version: 2.22.0, build 085 for Minecraft 26.2 (Java 26, 64bit)
# @Release: August 22nd, 2026
# @Description: Helps us start a Paper 26.2 server.
# @Contact: I am @floris on Twitter, and mrfloris in MineCraft.
# @Discord: @mrfloris on https://discord.gg/floris
# @Install: chmod +x 1MB-minecraft.sh
# @Syntax: ./1MB-minecraft.sh
# @URL: Latest source, wiki, & support: https://scripts.1moreblock.com/

### CONFIGURATION
#
# Declarations here you can customize to your preferred setup.
# Generally only if you actually have to. Check Wiki for details.
#
###

_minecraftVersion="26.2"
# Which version are we running?

_minJavaVersion=26
# use 26 for java 26.0.2 which can be used with Minecraft 26.2+
# use 25 for java 25.0.4 which can be used with Minecraft 1.21.11+
# use 24 for java 24.x which can be used with Minecraft 1.21.8
# use 23 for java 23.x which can be used with Minecraft 1.21.4+
# use 21 for java 21.x which can be used with Minecraft 1.19.x+

_javaMemory="-Xms4G -Xmx4G"
# "" = uses the default
# "-Xmx2G" = maximum memory allocation pool of memory for JVM.
# "-Xms1G" = initial memory allocation pool of memory for JVM.
# More details here: https://stackoverflow.com/questions/14763079/
# Example: (10GB host for dedicated Paper 26.2 server with custom flags, using 10GB ram, etc.)
# _javaMemory="-Xms10G -Xmx10G -XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:+AlwaysPreTouch -XX:G1NewSizePercent=30 -XX:G1MaxNewSizePercent=40 -XX:G1HeapRegionSize=8M -XX:G1ReservePercent=20 -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=15 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1 -Dusing.aikars.flags=https://mcflags.emc.gs -Daikars.new.flags=true"
# _javaMemory="-Xms10240M -Xmx10240M -XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:+AlwaysPreTouch -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=15 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1 -Dusing.aikars.flags=https://mcflags.emc.gs -Daikars.new.flags=true -XX:G1NewSizePercent=30 -XX:G1MaxNewSizePercent=40 -XX:G1HeapRegionSize=8M -XX:G1ReservePercent=20"
# Figure out optimal flags for your configuration here: https://flags.sh/

# jvm startup parameters
_javaParams="-Dfile.encoding=UTF-8 -Dapple.awt.UIElement=true --sun-misc-unsafe-memory-access=allow -Xlog:gc*:logs/gc.log:time,uptime,level,tags:filecount=5,filesize=10M -XX:ErrorFile=logs/hs_err_pid%p.log"
# -Dfile.encoding=UTF-8 (UTF-8 characters will be saved properly in the log files, and should correctly display in the console.)
# -Dapple.awt.UIElement=true (Helps on macOS to not show icon in cmd-tab)
# -Dhttps.protocols=TLSv1 (Temporary fix for older discordsrv, you can ignore this one probably)
# -Dterminal.ansi=false (Temporary fix for older screen sessions that have hex-issues)
# --add-opens java.base/java.lang=ALL-UNNAMED --add-opens java.base/java.security=ALL-UNNAMED (Temporary fix for asyncworldedit and java16)
# and --add-opens java.desktop/java.awt=ALL-UNNAMED
# and --add-opens java.desktop/java.awt.color=ALL-UNNAMED
# --illegal-access=permit (Temporary fix to get outdated plugins to work on 1.17.1)
# -Dlog4j2.formatMsgNoLookups=true (Temporary fix to help address log4j2 issue for pre 1.18.2 servers)
# -Dpaper.useLegacyPluginLoading=true (Temporary fix circular plugin loading issue)
# --enable-native-access=ALL-UNNAMED (Remove startup warning when using java24)
# --sun-misc-unsafe-memory-access=allow (Remove unsafe warning during java24 jvm startup)

# Override auto engine jar detection; only use this if you have issues
_engine="Paper"
# spigot until paper jar is out
# "" assumes auto detection for <engine>-26.2.jar or Paper-26.2-<build>.jar
# "spigot" assumes to look for spigot-26.2.jar
# "paper" prefers the greatest numeric Paper-26.2-<build>.jar, then falls back to paper-26.2.jar

_engineParams=""
# Leave empty for every day running, only edit when you need this!
# --forceUpgrade (One time converts world chunks to new engine version) (Note: Do not use Paper's forceUpgrade, it will ruin your worlds)
# --eraseCache (Removes caches. Cached data is used to store the skylight, blocklight and biomes, alongside other stuff) (Note: Do not use Paper's eraseCache, it will ruin your worlds)
# --recreateRegionFiles: Triggers world optimization similar to --forceUpgrade,
# but also rewrites all chunks regardless of whether they have already been upgraded.
# Note: Be sure to adjust the region-file-compression setting before using this option.


# By changing the setting below to true you are indicating your agreement to Mojang's EULA
# which is legally binding, and you should read it! https://account.mojang.com/documents/minecraft_eula
_eula=false

# leave "" if you want the 26.2 server GUI
_noGui="--nogui"

### INTERNAL CONFIGURATION
#
# Configuration variables you should probably
# leave alone, but can change if really needed.
#
###

_javaBin=""
# Leave empty for auto-discovery of java path, and
# if this fails, you could hard code the path, as exampled below:
# _javaBin="/Library/Java/JavaVirtualMachines/jdk-25.0.2.jdk/Contents/Home/bin/java"
# _javaBin="/Library/Java/JavaVirtualMachines/jdk-21.0.1.jdk/Contents/Home/bin/java"

_debug=true
# Debug mode off or on? Default: false (true means it spits out progress)

### FUNCTIONS AND CODE
#
# ! WE ARE DONE, STOP EDITING BEYOND THIS POINT !
#
###

function _output {
    case "$1" in
    oops)
        _args="${*:2}"; _prefix="(Script Halted!)";
        echo -e "\\n$B$Y$_prefix$X $_args $R" >&2; exit 1
    ;;
    okay)
        _args="${*:2}"; _prefix="(Info)";
        echo -e "\\n$B$Y$_prefix$C $_args $R" >&2; exit 1
    ;;
    debug)
        _args="${*:2}"; _prefix="(Debug)";
        [[ "$_debug" == true ]] && echo -e "$Y$_prefix$C $_args $R"
    ;;
    *)
        _args="${*:1}"; _prefix="(Info)";
        echo -e "\\n$_prefix $_args"
    ;;
    esac
}

[ "$EUID" -eq 0 ] && _output oops "*!* This script should not be run using sudo, or as the root user!"
Y="\\033[33m"; C="\\033[36m"; R="\\033[0m" # theme

_launcherDir=$(cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd) || \
    _output oops "Could not resolve the directory containing ${BASH_SOURCE[0]}."
cd -- "$_launcherDir" || _output oops "Could not enter the server directory: $_launcherDir"

# 'better comparing' fix to replace: function version_gt() { test "$(printf '%s\n' "$@"|sort -V|head -n 1)" -ge "$1"; }
function version_gt() {
    local result="$1"
    local value="$2"

    # When the versions (strings) has fewer components we need to properly split the version strings into arrays
    IFS='.' read -ra result_parts <<< "$result"
    IFS='.' read -ra value_parts <<< "$value"

    # So we can then compare each part of the version (using 0 for missing parts).
    for ((i = 0; i < ${#value_parts[@]}; i++)); do
        result_part="${result_parts[i]:-0}"
        value_part="${value_parts[i]}"

        if [[ "$result_part" -gt "$value_part" ]]; then
            # true
            return 0
        elif [[ "$result_part" -lt "$value_part" ]]; then
            # false
            return 1
        fi
    done

    # return true when they're equal or have fewer components.
    return 0
}

function binExists() { type "$1">/dev/null 2>&1; }
function binDetails() {
    _cmd="$1"
    _cmdpath=$(command -V "$_cmd" | awk '{print $3}')
    _cmdversion=$($_cmd -version 2>&1 | awk -F '"' '/version/ {print $2}')
}

function _lowercaseValue() {
    printf '%s' "$1" | tr '[:upper:]' '[:lower:]'
}

function _findJarCaseInsensitive() {
    local _wantedLower=""
    local _candidate=""
    local _candidateName=""
    local _candidateLower=""

    _foundJar=""
    _wantedLower=$(_lowercaseValue "$1")
    for _candidate in ./*; do
        [[ -f "$_candidate" ]] || continue
        [[ -L "$_candidate" ]] && continue
        _candidateName=${_candidate#./}
        _candidateLower=$(_lowercaseValue "$_candidateName")
        if [[ "$_candidateLower" == "$_wantedLower" ]]; then
            _foundJar="$_candidateName"
            return 0
        fi
    done
    return 1
}

function _findLatestPaperBuildJar() {
    local _version="$1"
    local _prefix="paper-${_version}-"
    local _candidate=""
    local _candidateName=""
    local _candidateLower=""
    local _candidateBuild=""
    local _candidateBuildNumber=0

    _latestPaperJar=""
    _latestPaperBuild=-1
    for _candidate in ./*; do
        [[ -f "$_candidate" ]] || continue
        [[ -L "$_candidate" ]] && continue
        _candidateName=${_candidate#./}
        _candidateLower=$(_lowercaseValue "$_candidateName")
        case "$_candidateLower" in
        "${_prefix}"*.jar)
            _candidateBuild=${_candidateLower#"$_prefix"}
            _candidateBuild=${_candidateBuild%.jar}
            case "$_candidateBuild" in
            ""|*[!0-9]*) continue ;;
            esac
            _candidateBuildNumber=$((10#$_candidateBuild))
            if [[ "$_candidateBuildNumber" -gt "$_latestPaperBuild" ]]; then
                _latestPaperBuild="$_candidateBuildNumber"
                _latestPaperJar="$_candidateName"
            fi
            ;;
        esac
    done

    [[ -n "$_latestPaperJar" ]] || return 1
    _engineJar="$_latestPaperJar"
    _serverJar="$_latestPaperJar"
    return 0
}

function _selectEngineJar() {
    local _engineLower=""

    _engineJar=""
    _engineLower=$(_lowercaseValue "$_engine")
    if [[ -n "$_engine" ]]; then
        if [[ "$_engineLower" == "paper" ]] && _findLatestPaperBuildJar "$_minecraftVersion"; then
            _output debug "Selected latest Paper build for Minecraft $_minecraftVersion: $_engineJar (build $_latestPaperBuild)"
            return 0
        fi

        _serverJar="$_engine-$_minecraftVersion.jar"
        if _findJarCaseInsensitive "$_serverJar"; then
            _engineJar="$_foundJar"
            _serverJar="$_foundJar"
            return 0
        fi
        _output oops "Oops, we did not find $_serverJar, please check your configuration."
    fi

    if _findLatestPaperBuildJar "$_minecraftVersion"; then
        _output debug "Selected latest Paper build for Minecraft $_minecraftVersion: $_engineJar (build $_latestPaperBuild)"
        return 0
    fi
    _serverJar="paper-$_minecraftVersion.jar"
    if _findJarCaseInsensitive "$_serverJar"; then
        _engineJar="$_foundJar"
        _serverJar="$_foundJar"
        return 0
    fi
    _serverJar="spigot-$_minecraftVersion.jar"
    if _findJarCaseInsensitive "$_serverJar"; then
        _engineJar="$_foundJar"
        _serverJar="$_foundJar"
        return 0
    fi
    _output oops "Oops, we did not find a paper or spigot jar for Minecraft $_minecraftVersion, please read a manual."
}

_launcherRunLock=""
_launcherRunLockMayRelease=true

function _releaseLauncherRunLock() {
    local _ownerFile=""
    local _ownerPid=""
    [[ "$_launcherRunLockMayRelease" == true ]] || return 0
    [[ -n "$_launcherRunLock" ]] || return 0
    [[ -d "$_launcherRunLock" && ! -L "$_launcherRunLock" ]] || return 0
    _ownerFile="$_launcherRunLock/owner.pid"
    [[ -f "$_ownerFile" && ! -L "$_ownerFile" ]] || return 0
    IFS= read -r _ownerPid < "$_ownerFile" || true
    if [[ "$_ownerPid" == "$$" ]]; then
        rm -- "$_ownerFile" 2>/dev/null || true
        rmdir "$_launcherRunLock" 2>/dev/null || true
    fi
}

function _preserveLauncherRunLockOnSignal() {
    local _signalName="$1"
    _launcherRunLockMayRelease=false
    _output oops "Launcher received $_signalName while Java may still be alive. The server-launch lock was preserved; confirm the JVM is fully stopped before removing it manually."
}

function _claimLauncherRunLock() {
    local _runtimeDirectory="paperscript"
    local _locksDirectory="$_runtimeDirectory/locks"
    local _lockDirectory="$_locksDirectory/server-launch"
    local _ownerFile="$_lockDirectory/owner.pid"
    local _ownerPid=""

    # Servers without PaperScript keep their historical launcher behavior.
    [[ -d "$_runtimeDirectory" ]] || return 0
    [[ ! -L "$_runtimeDirectory" ]] || \
        _output oops "PaperScript runtime is a symlink; refusing to create the server-launch lock."
    if [[ -e "$_locksDirectory" ]]; then
        [[ -d "$_locksDirectory" && ! -L "$_locksDirectory" ]] || \
            _output oops "PaperScript lock path is not a regular directory: $_locksDirectory"
    else
        mkdir -m 700 "$_locksDirectory" || \
            _output oops "Could not create the PaperScript lock directory: $_locksDirectory"
    fi

    if ! mkdir -m 700 "$_lockDirectory" 2>/dev/null; then
        [[ -d "$_lockDirectory" && ! -L "$_lockDirectory" ]] || \
            _output oops "PaperScript server-launch lock is not a regular directory: $_lockDirectory"
        if [[ -f "$_ownerFile" && ! -L "$_ownerFile" ]]; then
            IFS= read -r _ownerPid < "$_ownerFile" || true
        elif [[ -e "$_ownerFile" || -L "$_ownerFile" ]]; then
            _output oops "PaperScript server-launch owner file is unsafe: $_ownerFile"
        fi
        if [[ "$_ownerPid" =~ ^[0-9]+$ ]]; then
            _output oops "A 1MB-minecraft.sh launch lock already exists for this server (recorded wrapper PID $_ownerPid). Refusing automatic recovery because Java may still be running after its wrapper exits. Confirm the server is fully stopped before manually removing $_lockDirectory."
        fi
        _output oops "A 1MB-minecraft.sh launch lock already exists for this server. Refusing automatic recovery because Java may still be running. Confirm the server is fully stopped before manually removing $_lockDirectory."
    fi

    _launcherRunLock="$_lockDirectory"
    trap _releaseLauncherRunLock EXIT
    trap '_preserveLauncherRunLockOnSignal HUP' HUP
    trap '_preserveLauncherRunLockOnSignal INT' INT
    trap '_preserveLauncherRunLockOnSignal QUIT' QUIT
    trap '_preserveLauncherRunLockOnSignal TERM' TERM
    (umask 077; printf '%s\n' "$$" > "$_ownerFile") || \
        _output oops "Could not record ownership of the server-launch lock: $_ownerFile"
}

function _recordLastLaunchedJar() {
    local _markerDirectory="paperscript"

    # Servers without PaperScript can keep using this launcher normally. Once the
    # runtime directory exists, the marker is required so cleanup can protect the
    # exact jar selected for this launch.
    if [[ ! -d "$_markerDirectory" ]]; then
        _output debug "PaperScript runtime directory was not found; skipping the last-launched jar marker."
        return 0
    fi
    binExists "python3" || \
        _output oops "python3 is required to safely claim the launcher-selected jar for PaperScript retention."

    if ! python3 - "$_launcherDir" "$_engineJar" <<'PY'
import fcntl
import os
import stat
import sys
import tempfile
from pathlib import Path


def fsync_directory(path: Path) -> None:
    descriptor = os.open(path, os.O_RDONLY)
    try:
        os.fsync(descriptor)
    finally:
        os.close(descriptor)


def atomic_write_text(path: Path, content: str) -> None:
    descriptor, temporary_name = tempfile.mkstemp(
        dir=path.parent,
        prefix=f".{path.name}.",
        suffix=".tmp",
    )
    temporary = Path(temporary_name)
    try:
        os.fchmod(descriptor, 0o600)
        with os.fdopen(descriptor, "w", encoding="utf-8") as handle:
            descriptor = -1
            handle.write(content)
            handle.flush()
            os.fsync(handle.fileno())
        os.replace(temporary, path)
        fsync_directory(path.parent)
    finally:
        if descriptor >= 0:
            os.close(descriptor)
        if temporary.exists():
            temporary.unlink()


try:
    server_root = Path(sys.argv[1]).resolve(strict=True)
    selected_name = sys.argv[2]
    if not selected_name or selected_name != Path(selected_name).name or "/" in selected_name or "\\" in selected_name:
        raise RuntimeError(f"selected jar is not a safe basename: {selected_name!r}")

    runtime = server_root / "paperscript"
    if runtime.is_symlink() or not runtime.is_dir():
        raise RuntimeError(f"PaperScript runtime is not a regular directory: {runtime}")
    runtime.resolve().relative_to(server_root)

    locks = runtime / "locks"
    locks.mkdir(mode=0o700, exist_ok=True)
    if locks.is_symlink() or not locks.is_dir():
        raise RuntimeError(f"PaperScript lock path is not a regular directory: {locks}")
    lock_path = locks / "paper-jars.lock"
    if lock_path.is_symlink():
        raise RuntimeError(f"PaperScript lock file is a symlink: {lock_path}")

    with lock_path.open("a+", encoding="utf-8") as lock_handle:
        fcntl.flock(lock_handle.fileno(), fcntl.LOCK_EX)

        selected_path = server_root / selected_name
        if selected_path.is_symlink():
            raise RuntimeError(f"selected jar became a symlink: {selected_path}")
        selected_stat = selected_path.lstat()
        if not stat.S_ISREG(selected_stat.st_mode):
            raise RuntimeError(f"selected jar is no longer a regular file: {selected_path}")

        marker = runtime / "last-launched-jar.txt"
        if marker.is_symlink() or (marker.exists() and not marker.is_file()):
            raise RuntimeError(f"last-launched marker is not a regular file: {marker}")
        rollback = runtime / ".launcher-marker-rollback"
        if rollback.is_symlink() or (rollback.exists() and not rollback.is_file()):
            raise RuntimeError(f"launcher marker rollback path is unsafe: {rollback}")

        previous_name = ""
        if marker.exists() and marker.stat().st_size <= 512:
            candidate = marker.read_text(encoding="utf-8").strip()
            previous_path = server_root / candidate
            if (
                candidate
                and candidate == Path(candidate).name
                and "/" not in candidate
                and "\\" not in candidate
                and not previous_path.is_symlink()
                and previous_path.is_file()
            ):
                previous_name = candidate

        atomic_write_text(rollback, previous_name + "\n")
        atomic_write_text(marker, selected_name + "\n")
except Exception as error:
    print(f"Could not safely record the launcher-selected jar: {error}", file=sys.stderr)
    raise SystemExit(1)
PY
    then
        _output oops "Could not safely claim the launcher-selected jar."
    fi
    _output debug "Recorded launcher-selected jar: $_engineJar"
}

function _finalizeLauncherMarker() {
    local _outcome="$1"
    [[ -d "paperscript" ]] || return 0

    if ! python3 - "$_launcherDir" "$_engineJar" "$_outcome" <<'PY'
import fcntl
import os
import stat
import sys
import tempfile
from pathlib import Path


def fsync_directory(path: Path) -> None:
    descriptor = os.open(path, os.O_RDONLY)
    try:
        os.fsync(descriptor)
    finally:
        os.close(descriptor)


def atomic_write_text(path: Path, content: str) -> None:
    descriptor, temporary_name = tempfile.mkstemp(
        dir=path.parent,
        prefix=f".{path.name}.",
        suffix=".tmp",
    )
    temporary = Path(temporary_name)
    try:
        os.fchmod(descriptor, 0o600)
        with os.fdopen(descriptor, "w", encoding="utf-8") as handle:
            descriptor = -1
            handle.write(content)
            handle.flush()
            os.fsync(handle.fileno())
        os.replace(temporary, path)
        fsync_directory(path.parent)
    finally:
        if descriptor >= 0:
            os.close(descriptor)
        if temporary.exists():
            temporary.unlink()


try:
    server_root = Path(sys.argv[1]).resolve(strict=True)
    selected_name = sys.argv[2]
    outcome = sys.argv[3]
    if outcome not in {"success", "failure"}:
        raise RuntimeError(f"unknown launcher finalization outcome: {outcome}")

    runtime = server_root / "paperscript"
    runtime.resolve().relative_to(server_root)
    marker = runtime / "last-launched-jar.txt"
    rollback = runtime / ".launcher-marker-rollback"
    lock_path = runtime / "locks" / "paper-jars.lock"
    if lock_path.is_symlink():
        raise RuntimeError(f"PaperScript lock file is a symlink: {lock_path}")

    with lock_path.open("a+", encoding="utf-8") as lock_handle:
        fcntl.flock(lock_handle.fileno(), fcntl.LOCK_EX)
        if rollback.is_symlink() or (rollback.exists() and not rollback.is_file()):
            raise RuntimeError(f"launcher marker rollback path is unsafe: {rollback}")

        if outcome == "failure" and rollback.exists():
            if marker.is_symlink() or not marker.is_file():
                raise RuntimeError(f"last-launched marker changed type before rollback: {marker}")
            current_name = marker.read_text(encoding="utf-8").strip()
            if current_name != selected_name:
                raise RuntimeError(
                    f"last-launched marker changed after this launch selected {selected_name}: {current_name}"
                )
            previous_name = rollback.read_text(encoding="utf-8").strip()
            if previous_name:
                if (
                    previous_name != Path(previous_name).name
                    or "/" in previous_name
                    or "\\" in previous_name
                ):
                    raise RuntimeError("launcher rollback marker does not contain a safe basename")
                previous_path = server_root / previous_name
                previous_stat = previous_path.lstat()
                if previous_path.is_symlink() or not stat.S_ISREG(previous_stat.st_mode):
                    raise RuntimeError(f"previous launcher-selected jar is no longer safe: {previous_path}")
                atomic_write_text(marker, previous_name + "\n")
            else:
                marker.unlink()
                fsync_directory(runtime)

        if rollback.exists():
            rollback.unlink()
            fsync_directory(runtime)
except Exception as error:
    print(f"Could not safely finalize the launcher-selected jar marker: {error}", file=sys.stderr)
    raise SystemExit(1)
PY
    then
        _output oops "Could not safely finalize the launcher-selected jar marker."
    fi
}

if binExists "java"; then
    binDetails "java"
    if version_gt "$_cmdversion" "$_minJavaVersion"; then
        if [ -z "$_javaBin" ]; then
            _output debug "_javaBin is empty, trying to auto discover java .."
            if [ -z "$_cmdpath" ]; then
                _output oops "Path to java bin was found empty, maybe set _javaBin manually"
            else
                _output debug "Path to java ($_cmdversion) auto discovered: $_cmdpath"
                _javaBin="$_cmdpath"
            fi
        else
            # todo: Reconsider how to approach this, if _javaBin is set, check that. If that fails, try auto discovery.
            if [[ -f "$_javaBin" ]]; then
                _output debug "Path to java was set in _javaBin, found it and trying to use this instead of auto discovery."
            else
                _output oops "Could not find $_javaBin, leave _javaBin empty for auto discovery or install java properly."
            fi
        fi
        _output debug "Installed $_cmd version $_cmdversion is newer than $_minJavaVersion (this is great)!"
    else
        _output oops "Installed $_cmd version $_cmdversion is NOT newer \\n -> Please upgrade to the minimal required version: $_minJavaVersion "
    fi
else
    _output oops "java was not found, please install it for this operating system \\n -> https://www.digitalocean.com/community/tutorials?q=install+java"
fi

# before we continue, let's select the latest matching Paper build or a legacy fallback
_claimLauncherRunLock
_selectEngineJar
_recordLastLaunchedJar

[[ "$_eula" == true ]] && _javaParams="${_javaParams} -Dcom.mojang.eula.agree=true"

_startJVM="$_javaBin $_javaMemory $_javaParams -jar $_engineJar $_engineParams $_noGui"
$_startJVM <&0 &
_jvmPid=$!
wait "$_jvmPid"
_jvmStatus=$?
if [[ "$_jvmStatus" -eq 0 ]]; then
    _finalizeLauncherMarker success
else
    _finalizeLauncherMarker failure
    _output oops "Failed to start the jvm for some reason."
fi

#EOF Copyright (c) 1977-2026 - Floris Fiedeldij Dop - https://scripts.1moreblock.com
