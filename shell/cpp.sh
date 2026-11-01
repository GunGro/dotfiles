# shellcheck shell=bash
# Sourced by bashrc and zshrc (not executed), so no shebang.
# C/C++ (CMake) helpers with no engine assumptions: build presets, sanitizers,
# profiling, crash triage, determinism checks, network shaping, tmux layout.
# Loaded when DOTFILES_CPP=1 or DOTFILES_GAMEDEV=1 (see local_env.sh.example).

# ─── Environment ─────────────────────────────────────────────────────────────

# CMake defaults picked up from the environment (CMake >= 3.17 / 3.24).
export CMAKE_GENERATOR="${CMAKE_GENERATOR:-Ninja}"
export CMAKE_EXPORT_COMPILE_COMMANDS="${CMAKE_EXPORT_COMPILE_COMMANDS:-ON}"
export CMAKE_COLOR_DIAGNOSTICS="${CMAKE_COLOR_DIAGNOSTICS:-ON}"
if command -v ccache >/dev/null 2>&1; then
    export CMAKE_C_COMPILER_LAUNCHER="${CMAKE_C_COMPILER_LAUNCHER:-ccache}"
    export CMAKE_CXX_COMPILER_LAUNCHER="${CMAKE_CXX_COMPILER_LAUNCHER:-ccache}"
fi
export CMAKE_BUILD_PARALLEL_LEVEL="${CMAKE_BUILD_PARALLEL_LEVEL:-$(nproc 2>/dev/null || echo 4)}"
export CTEST_OUTPUT_ON_FAILURE=1
export CTEST_PARALLEL_LEVEL="${CTEST_PARALLEL_LEVEL:-$CMAKE_BUILD_PARALLEL_LEVEL}"

# Readable ASan/UBSan reports by default.
export ASAN_OPTIONS="${ASAN_OPTIONS:-detect_leaks=1:abort_on_error=1:strict_string_checks=1}"
export UBSAN_OPTIONS="${UBSAN_OPTIONS:-print_stacktrace=1:halt_on_error=1}"
export TSAN_OPTIONS="${TSAN_OPTIONS:-halt_on_error=1:second_deadlock_stack=1}"

# Allow core dumps for processes started from this shell (systemd-coredump
# stores them; it honours the crashing process's RLIMIT_CORE).
ulimit -c unlimited 2>/dev/null || true

# ─── Project discovery ───────────────────────────────────────────────────────

# CMake source dir: git root, else the current directory.
cpp_src() {
    git rev-parse --show-toplevel 2>/dev/null || echo "$PWD"
}

alias cdsrc='cd "$(cpp_src)"'

# ─── CMake ───────────────────────────────────────────────────────────────────


# Configure + build + link compile_commands.json. Uses CMakePresets.json if present.
# Usage: cmb [preset|build-type]   (default: debug / Debug)
cmb() {
    local src
    src="$(cpp_src)"
    if [ -f "$src/CMakePresets.json" ]; then
        local p="${1:-debug}"
        (cd "$src" && cmake --preset "$p" && cmake --build --preset "$p") || return 1
    else
        local t="${1:-Debug}"
        local b="$src/build"
        [ "$t" = "Debug" ] || b="$src/build-$(echo "$t" | tr '[:upper:]' '[:lower:]')"
        cmake -S "$src" -B "$b" -DCMAKE_BUILD_TYPE="$t" && cmake --build "$b" || return 1
        ln -sf "$b/compile_commands.json" "$src/compile_commands.json"
    fi
}

# ctest in the default build dir. Usage: cmt [-R regex] ...
cmt() { ctest --test-dir "$(cpp_src)/build" "$@"; }

# ASan+UBSan build in build-asan (for the standalone sim-core test binaries).
cmasan() {
    local src
    src="$(cpp_src)"
    cmake -S "$src" -B "$src/build-asan" -DCMAKE_BUILD_TYPE=Debug \
        -DCMAKE_C_FLAGS="-fsanitize=address,undefined -fno-omit-frame-pointer" \
        -DCMAKE_CXX_FLAGS="-fsanitize=address,undefined -fno-omit-frame-pointer" \
        -DCMAKE_EXE_LINKER_FLAGS="-fsanitize=address,undefined" \
        -DCMAKE_SHARED_LINKER_FLAGS="-fsanitize=address,undefined" \
        "$@" && cmake --build "$src/build-asan" && ctest --test-dir "$src/build-asan"
}

# Rebuild + run tests on every C++/CMake change; GDScript changes rerun gdtest.
cmwatch() {
    command -v watchexec >/dev/null 2>&1 || { echo "cmwatch: watchexec missing" >&2; return 1; }
    watchexec -w "$(cpp_src)" -e cpp,hpp,h,cc,inl,cmake,txt -i 'build*/**' \
        -- "cmake --build '$(cpp_src)/build' && ctest --test-dir '$(cpp_src)/build'"
}

# ThreadSanitizer build in build-tsan (threads/job system/net code; cannot be
# combined with ASan). Usage: cmtsan [extra cmake args]
cmtsan() {
    local src
    src="$(cpp_src)"
    cmake -S "$src" -B "$src/build-tsan" -DCMAKE_BUILD_TYPE=RelWithDebInfo \
        -DCMAKE_C_FLAGS="-fsanitize=thread -fno-omit-frame-pointer" \
        -DCMAKE_CXX_FLAGS="-fsanitize=thread -fno-omit-frame-pointer" \
        -DCMAKE_EXE_LINKER_FLAGS="-fsanitize=thread" \
        -DCMAKE_SHARED_LINKER_FLAGS="-fsanitize=thread" \
        "$@" && cmake --build "$src/build-tsan" && ctest --test-dir "$src/build-tsan"
}

# List configure presets of the current project.
cmpresets() { (cd "$(cpp_src)" && cmake --list-presets); }

# ─── Profiling ───────────────────────────────────────────────────────────────

# Temporarily allow unprivileged perf + kernel symbols (reset on reboot).
perf-allow() { sudo sysctl -w kernel.perf_event_paranoid=1 kernel.kptr_restrict=0; }

# Hardware counters for a sim-core benchmark binary, 5 runs with variance.
# Usage: perfstat build-profile/bench_sim [args]
perfstat() {
    perf stat -r "${PERFSTAT_RUNS:-5}" \
        -e task-clock,cycles,instructions,branch-misses,cache-references,cache-misses,L1-dcache-load-misses \
        -- "$@"
}

# RelWithDebInfo + frame pointers in build-profile: cheap, accurate call
# graphs for the extension and sim core (perf record -g, no DWARF needed).
cmprofile() {
    local src
    src="$(cpp_src)"
    cmake -S "$src" -B "$src/build-profile" -DCMAKE_BUILD_TYPE=RelWithDebInfo \
        -DCMAKE_C_FLAGS="-fno-omit-frame-pointer -mno-omit-leaf-frame-pointer" \
        -DCMAKE_CXX_FLAGS="-fno-omit-frame-pointer -mno-omit-leaf-frame-pointer" \
        "$@" && cmake --build "$src/build-profile"
}

# CPU profile of any binary; opens hotspot (or perf report). Build with
# cmprofile for frame pointers; set CXPERF_DWARF=1 for binaries without them.
# Usage: cxperf build-profile/app [args]   -> /tmp/cxperf.data
cxperf() {
    local out="${CXPERF_OUT:-/tmp/cxperf.data}" cg=fp
    [ "${CXPERF_DWARF:-0}" = 1 ] && cg=dwarf,32768
    perf record -F "${CXPERF_FREQ:-999}" --call-graph "$cg" -o "$out" -- "$@" || return 1
    if command -v hotspot >/dev/null 2>&1; then
        hotspot "$out" >/dev/null 2>&1 &
    else
        perf report -i "$out" --no-children
    fi
}

# Heap profile (allocations, leaks, peak) of any binary. Usage: cxheap BIN [args]
cxheap() {
    command -v heaptrack >/dev/null 2>&1 || { echo "cxheap: heaptrack missing" >&2; return 1; }
    heaptrack -o /tmp/cxheap "$@"
}

# ─── Determinism ─────────────────────────────────────────────────────────────

# Run a command N times (default 2) and compare stdout byte for byte; for a
# lockstep sim, make it print per-tick state hashes. On mismatch, shows the
# first differing lines. Usage: cxdet [-n N] build/sim_headless --seed 1 --ticks 10000
cxdet() {
    local n=2 i ref out d
    if [ "${1:-}" = -n ]; then n="$2"; shift 2; fi
    [ $# -gt 0 ] || { echo "usage: cxdet [-n N] CMD [args]" >&2; return 2; }
    d="$(mktemp -d)"
    i=1
    while [ "$i" -le "$n" ]; do
        "$@" >"$d/$i.out" 2>/dev/null || { echo "cxdet: run $i exited $?" >&2; rm -rf "$d"; return 1; }
        i=$((i + 1))
    done
    ref="$(sha256sum <"$d/1.out")"
    i=2
    while [ "$i" -le "$n" ]; do
        out="$(sha256sum <"$d/$i.out")"
        if [ "$out" != "$ref" ]; then
            echo "cxdet: run $i differs from run 1:" >&2
            diff "$d/1.out" "$d/$i.out" | head -n 20 >&2
            rm -rf "$d"
            return 1
        fi
        i=$((i + 1))
    done
    echo "cxdet: $n runs identical (${ref%% *})"
    rm -rf "$d"
}

# ─── Crash triage ────────────────────────────────────────────────────────────

# Recent core dumps (optionally of one executable). Usage: cxcores [exe]
cxcores() { coredumpctl list --no-pager ${1:+"$(readlink -f "$1")"}; }
# Open the newest core (of exe/PID if given) in gdb. Usage: cxcore [exe|pid]
cxcore() { coredumpctl gdb ${1:+"$1"}; }
# All-thread full backtrace of the newest core, to stdout (paste-able).
cxcorebt() {
    coredumpctl debug --debugger-arguments="-q -batch -ex 'thread apply all bt full'" ${1:+"$1"} 2>&1
}

# ─── Network conditions (local client+server) ────────────────────────────────


# Shape loopback traffic with tc netem. Applies to *every* packet on the
# interface in each direction, so on lo the RTT is ~2x the delay.
# Usage: netem lan|wifi|dsl|mobile|bad      presets (one-way delay)
#        netem set DELAY_MS [JITTER_MS] [LOSS_%] [RATE]   e.g. netem set 40 8 1 10mbit
#        netem off | netem status
# Env: NETEM_DEV (default lo)
netem() {
    local dev="${NETEM_DEV:-lo}" d j l r
    case "${1:-status}" in
        lan) d=1 j=0 l=0 ;;
        wifi) d=10 j=5 l=0.5 ;;
        dsl) d=25 j=4 l=0.2 ;;
        mobile) d=50 j=20 l=1 r=5mbit ;;
        bad) d=120 j=40 l=4 r=1mbit ;;
        set) d="${2:?delay ms}" j="${3:-0}" l="${4:-0}" r="${5:-}" ;;
        off)
            sudo tc qdisc del dev "$dev" root 2>/dev/null
            echo "netem: off on $dev"
            return 0
            ;;
        status)
            tc qdisc show dev "$dev"
            return 0
            ;;
        *)
            echo "usage: netem lan|wifi|dsl|mobile|bad|set D [J] [L] [RATE]|off|status" >&2
            return 1
            ;;
    esac
    # Build args positionally (no word splitting, so it behaves the same in zsh).
    set -- delay "${d}ms"
    [ "$j" != 0 ] && set -- "$@" "${j}ms" distribution normal
    set -- "$@" loss "${l}%"
    [ -n "$r" ] && set -- "$@" rate "$r"
    sudo tc qdisc replace dev "$dev" root netem "$@" &&
        echo "netem: $dev delay ${d}ms±${j}ms loss ${l}%${r:+ rate $r} (RTT on lo ≈ 2×)"
}

# ─── tmux dev session ────────────────────────────────────────────────────────

# nvim (left) | build+test watch (top right) | shell or RUN_CMD (bottom right)
# Usage: cxsession [name] [run cmd]   e.g. cxsession mb 'build/mantlebound'
cxsession() {
    local name="${1:-$(basename "$(cpp_src)")}" run="${2:-}" src
    src="$(cpp_src)"
    if tmux has-session -t "=$name" 2>/dev/null; then
        tmux attach -t "=$name"
        return
    fi
    tmux new-session -d -s "$name" -c "$src" "nvim; $SHELL"
    tmux split-window -h -p 40 -t "$name" -c "$src"
    tmux send-keys -t "$name" "cmwatch" C-m
    tmux split-window -v -t "$name" -c "$src"
    [ -n "$run" ] && tmux send-keys -t "$name" "$run" C-m
    tmux select-pane -t "$name:.0"
    tmux attach -t "$name"
}
