#! /bin/env bash
# Game dev helpers: Godot 4 + GDScript + C++ GDExtension (CMake/godot-cpp).
# Sourced from aliases.sh; works in bash and zsh.

# ─── Environment ─────────────────────────────────────────────────────────────

# Godot binary (override in local_changes.* if it lives elsewhere).
export GODOT="${GODOT:-godot}"

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

# Print the CMake source dir (git root by default).
gd_src() {
    git rev-parse --show-toplevel 2>/dev/null || echo "$PWD"
}

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

# ─── CMake (GDExtension / sim core) ──────────────────────────────────────────

# Configure + build + link compile_commands.json. Uses CMakePresets.json if present.
# Usage: cmb [preset|build-type]   (default: debug / Debug)
cmb() {
    local src
    src="$(gd_src)"
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
cmt() { ctest --test-dir "$(gd_src)/build" "$@"; }

# ASan+UBSan build in build-asan (for the standalone sim-core test binaries).
cmasan() {
    local src
    src="$(gd_src)"
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
    watchexec -w "$(gd_src)" -e cpp,hpp,h,cc,inl,cmake,txt -i 'build*/**' -i '**/godot-cpp/**' \
        -- "cmake --build '$(gd_src)/build' && ctest --test-dir '$(gd_src)/build'"
}
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
    tmux split-window -h -p 40 -t "$name" -c "$src"
    tmux send-keys -t "$name" "cmwatch" C-m
    tmux split-window -v -t "$name" -c "$root"
    tmux send-keys -t "$name" "gde 2>&1 | tee /tmp/godot-editor.log" C-m
    tmux select-pane -t "$name:.0"
    tmux attach -t "$name"
}

# ─── Profiling ───────────────────────────────────────────────────────────────

# Temporarily allow unprivileged perf + kernel symbols (reset on reboot).
perf-allow() { sudo sysctl -w kernel.perf_event_paranoid=1 kernel.kptr_restrict=0; }

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
    src="$(gd_src)"
    cmake -S "$src" -B "$src/build-profile" -DCMAKE_BUILD_TYPE=RelWithDebInfo \
        -DCMAKE_C_FLAGS="-fno-omit-frame-pointer -mno-omit-leaf-frame-pointer" \
        -DCMAKE_CXX_FLAGS="-fno-omit-frame-pointer -mno-omit-leaf-frame-pointer" \
        "$@" && cmake --build "$src/build-profile"
}
