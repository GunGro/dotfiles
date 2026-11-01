# shellcheck shell=bash
# Sourced by bashrc and zshrc (not executed), so no shebang.
# Game dev helpers: Godot 4 + GDScript + C++ GDExtension (CMake/godot-cpp).
# Sourced from aliases.sh after shell/cpp.sh, which provides the engine-neutral
# parts (CMake env, cm* builds, perfstat/cmprofile, netem, core dumps).

# ─── Environment ─────────────────────────────────────────────────────────────

# Godot binary (override in local_changes.* if it lives elsewhere).
export GODOT="${GODOT:-godot}"

# ─── Project discovery ───────────────────────────────────────────────────────

# Print the Godot project dir: nearest ancestor with project.godot, else the
# shallowest project.godot below the git root (e.g. repo/game/project.godot).
gd_root() {
    local d="$PWD"
    while [ "$d" != "/" ]; do
        [ -f "$d/project.godot" ] && { echo "$d"; return 0; }
        d="$(dirname "$d")"
    done
    local g
    g="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "gd_root: no project.godot found" >&2; return 1; }
    local p
    p="$(find "$g" -maxdepth 3 -name project.godot -not -path '*/.godot/*' -not -path '*/addons/*' 2>/dev/null |
        awk '{ print length, $0 }' | sort -n | head -n1 | cut -d' ' -f2-)"
    [ -n "$p" ] || { echo "gd_root: no project.godot found" >&2; return 1; }
    dirname "$p"
}

# CMake source dir; kept as a name for older muscle memory (see cpp_src).
gd_src() { cpp_src; }

alias cdgd='cd "$(gd_root)"'

# ─── Godot runners ───────────────────────────────────────────────────────────

gdr() { "$GODOT" --path "$(gd_root)" "$@"; }                    # run game
gde() { "$GODOT" --path "$(gd_root)" -e "$@"; }                 # editor
gdh() { "$GODOT" --headless --path "$(gd_root)" "$@"; }         # headless
gdimport() { gdh --import "$@"; }                               # (re)import assets, exit
gds() { gdh --script "$@"; }                                    # run a SceneTree/MainLoop script
gdcheck() { gdh --check-only --script "$@"; }                   # parse-check one script
gdverbose() { gdr --verbose --debug "$@"; }                     # stdout logging + debug

# Parse-check every .gd file (fast lint via gdtoolkit if present).
gdlintall() {
    local root
    root="$(gd_root)" || return 1
    if command -v gdlint >/dev/null 2>&1; then
        (cd "$root" && fd -e gd -E addons -E .godot -X gdlint)
    else
        echo "gdlintall: gdlint not found (pipx install 'gdtoolkit==4.*')" >&2
        return 1
    fi
}

# Run GDScript tests headless (GUT or gdUnit4, whichever the project has).
# Usage: gdtest [extra args]
gdtest() {
    local root
    root="$(gd_root)" || return 1
    if [ -d "$root/addons/gut" ]; then
        gdh -d -s addons/gut/gut_cmdln.gd -gexit "$@"
    elif [ -d "$root/addons/gdUnit4" ]; then
        (cd "$root" && GODOT_BIN="$(command -v "$GODOT")" ./addons/gdUnit4/runtest.sh -a res://test "$@")
    else
        echo "gdtest: no GUT or gdUnit4 addon in $root/addons" >&2
        return 1
    fi
}

# Launch N game instances side by side for local multiplayer testing.
# Each gets `-- --instance=<i>` (read via OS.get_cmdline_user_args()) and logs
# to /tmp/gd-instance-<i>.log. Usage: gdmulti 3 [extra godot args]. Ctrl-C kills all.
gdmulti() {
    local n="${1:-2}"
    shift 2>/dev/null || true
    local root i x pids=""
    root="$(gd_root)" || return 1
    i=0
    while [ "$i" -lt "$n" ]; do
        x=$((i * 660))
        "$GODOT" --path "$root" --resolution 640x360 --position "$x,40" "$@" -- --instance="$i" \
            >"/tmp/gd-instance-$i.log" 2>&1 &
        pids="$pids $!"
        i=$((i + 1))
    done
    echo "gdmulti: pids$pids (logs: /tmp/gd-instance-*.log)"
    # shellcheck disable=SC2064,SC2086
    trap "kill $pids 2>/dev/null; trap - INT" INT
    wait
}

# ─── Debugging the GDExtension (godot is the host process) ───────────────────

# Breakpoints in the extension are pending until Godot dlopen()s it; the gdbinit
# sets `breakpoint pending on`. Usage: gdgdb [godot args], e.g. gdgdb -e
gdgdb() { gdb -q --args "$GODOT" --path "$(gd_root)" "$@"; }
gdlldb() { lldb -- "$GODOT" --path "$(gd_root)" "$@"; }
# Run until crash, print all backtraces, exit. Good for CI-ish repro.
gdbt() { gdb -q -batch -ex run -ex 'thread apply all bt' --args "$GODOT" --path "$(gd_root)" "$@"; }

# Rerun GDScript tests on every .gd change (cmwatch covers C++).
gdwatch() {
    command -v watchexec >/dev/null 2>&1 || { echo "gdwatch: watchexec missing" >&2; return 1; }
    watchexec -w "$(gd_root)" -e gd -i '.godot/**' -- "$SHELL" -ic "gdtest $*"
}

# ─── tmux dev session ────────────────────────────────────────────────────────

# nvim (left) | build watch (top right) | godot editor log (bottom right)
gdsession() {
    local name="${1:-game}" src root
    src="$(gd_src)"
    root="$(gd_root)" || return 1
    if tmux has-session -t "$name" 2>/dev/null; then
        tmux attach -t "$name"
        return
    fi
    tmux new-session -d -s "$name" -c "$src" "nvim; $SHELL"
    tmux split-window -h -l 40% -t "$name" -c "$src"
    tmux send-keys -t "$name" "cmwatch" C-m
    tmux split-window -v -t "$name" -c "$root"
    tmux send-keys -t "$name" "gde 2>&1 | tee /tmp/godot-editor.log" C-m
    tmux select-pane -t "$name:.0"
    tmux attach -t "$name"
}

# ─── Profiling (Godot host process; cxperf/cxheap for any binary) ───────────

# CPU profile of the game (or editor with -e). DWARF unwinding works on
# Godot's release binary, which has no frame pointers. Opens hotspot after.
# Usage: gdperf [godot args]   → /tmp/gdperf.data
gdperf() {
    local out="${GDPERF_OUT:-/tmp/gdperf.data}"
    perf record -F "${GDPERF_FREQ:-499}" --call-graph dwarf,32768 -o "$out" \
        -- "$GODOT" --path "$(gd_root)" "$@" || return 1
    if command -v hotspot >/dev/null 2>&1; then
        hotspot "$out" >/dev/null 2>&1 &
    else
        perf report -i "$out" --no-children
    fi
}

# Heap profile (allocations, leaks, peak) of the game. Usage: gdheap [godot args]
gdheap() {
    command -v heaptrack >/dev/null 2>&1 || { echo "gdheap: heaptrack missing" >&2; return 1; }
    heaptrack -o /tmp/gdheap "$GODOT" --path "$(gd_root)" "$@"
}

# ─── Balance sims ────────────────────────────────────────────────────────────

# Run a headless Godot sim script (extends SceneTree/MainLoop) and keep its CSV.
# The script gets `-- --out=FILE [user args]` (OS.get_cmdline_user_args()).
# Output: $GDSIM_DIR (default <repo>/.sims/, globally git-ignored). Prints the path.
# Usage: gdsim res://tools/sim/dps.gd --seed=1 --n=10000
gdsim() {
    local script="${1:?usage: gdsim res://path/sim.gd [user args]}"
    shift
    local dir="${GDSIM_DIR:-$(gd_src)/.sims}" out
    mkdir -p "$dir"
    out="$dir/$(basename "$script" .gd)-$(date +%Y%m%d-%H%M%S).csv"
    gdh --script "$script" -- --out="$out" "$@" && echo "$out"
}

# Newest sim CSV (or a given one) in visidata. Usage: simview [file.csv]
simview() {
    local f="${1:-}"
    [ -n "$f" ] || f="$(ls -t "${GDSIM_DIR:-$(gd_src)/.sims}"/*.csv 2>/dev/null | head -n1)"
    [ -n "$f" ] || { echo "simview: no sim CSVs" >&2; return 1; }
    vd "$f"
}

# Julia / R with the project environment.
alias jl='julia --project=@.'
alias jlt='julia --project=@. -e "using Pkg; Pkg.test()"'
alias Rq='R --no-save --quiet'

# ─── Crash triage ────────────────────────────────────────────────────────────

_gd_exe() { readlink -f "$(command -v "$GODOT")"; }

# Recent Godot crashes. Usage: gdcores
gdcores() { coredumpctl list --no-pager "$(_gd_exe)" 2>/dev/null || echo "gdcores: no Godot core dumps"; }

# Open the newest (or a given PID's) Godot core in gdb. The GDExtension's
# symbols load from the .so path recorded in the core, so this is exact only
# until you rebuild it. Usage: gdcore [pid]
gdcore() { coredumpctl gdb "${1:-$(_gd_exe)}"; }

# Full backtrace of all threads from the newest core, to stdout (paste-able).
gdcorebt() {
    coredumpctl debug --debugger-arguments="-q -batch -ex 'thread apply all bt full'" \
        "${1:-$(_gd_exe)}" 2>&1
}

# Godot's own log for this project: user://logs/godot.log.
# Usage: gdlogs [-f]   (-f follows)
gdlogs() {
    local root name log
    root="$(gd_root)" || return 1
    name="$(sed -n 's/^config\/name="\(.*\)"$/\1/p' "$root/project.godot" | head -n1)"
    log="${XDG_DATA_HOME:-$HOME/.local/share}/godot/app_userdata/$name/logs/godot.log"
    [ -f "$log" ] || { echo "gdlogs: $log not found (custom user dir?)" >&2; return 1; }
    if [ "${1:-}" = -f ]; then tail -F "$log"; else ${PAGER:-less} "$log"; fi
}
