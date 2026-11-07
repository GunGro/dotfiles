# dotfiles

Debian/Ubuntu dotfiles for Bash, Zsh, Git, tmux, kitty and Neovim, with a C/C++
and Godot game-dev toolset on top. Everything optional is behind a module flag or
a switch in an untracked local file, so you can take only the parts you want.

## What's in it

| Part | Files | Highlights |
| --- | --- | --- |
| Shell | `bashrc`, `zshrc`, `zshenv`, `shell/`, `bash/`, `zsh/` | vi line editing, zoxide, fzf/fzf-tab, atuin history, autosuggestions, syntax highlighting |
| Neovim (>= 0.11) | `nvim/` | lazy.nvim, native `vim.lsp` (clangd, vtsls, GDScript), blink.cmp, conform (formats changed lines only), DAP (codelldb, Godot), neotest, iron REPLs, Telescope, Harpoon |
| tmux / kitty | `tmux/`, `kitty/` | `C-Space` prefix, vim-tmux-navigator, resurrect/continuum, Catppuccin Mocha |
| Git | `git/` | many aliases, delta pager, LFS filter, global pre-commit hook (`git/template`) |
| C/C++ | `gdb/`, `lldb/`, `clangd/`, `shell/aliases.sh` | debugger defaults, clangd user config, CMake aliases |
| Game dev (opt-in) | `shell/gamedev.sh`, `nvim/lua/gamedev.lua`, `bin/godot-nvim` | Godot runners, tests, multiplayer and network simulation, profiling, crash triage, balance sims |
| AI (opt-in module) | `shell/aliases.sh`, tmux, `nvim/lua/plugins.lua` | aichat in shell/tmux, CodeCompanion in Neovim |

## Install

```bash
git clone --recurse-submodules https://github.com/GunGro/dotfiles ~/dotfiles
bash ~/dotfiles/setup.bash --dry-run        # see what would change
bash ~/dotfiles/setup.bash                  # core + dev
```

| Flag | Installs |
| --- | --- |
| *(none)* | `--core --dev` |
| `--core` | shell tools, tmux, Neovim >= 0.11, lazygit, delta, eza, atuin, and the config symlinks |
| `--dev` | cmake, ninja, clang/clangd, gdb/lldb, ccache, mold, git-lfs, node, rust, typos, yq, watchexec; debugger configs and git hooks |
| `--ai` | aichat with a key-less config template, Ollama |
| `--gamedev` | perf, hotspot, heaptrack, systemd-coredump, gdtoolkit, visidata, the Godot editor bridge; Godot itself with `GODOT_VER=4.x.y-stable` |
| `--all` | all of the above |
| `--links-only` | only the symlinks (use on other distros after installing tools yourself) |
| `--dry-run` | print the plan, change nothing |

Requirements: `sudo`, `git` and `curl`. Packages come from apt; a few tools are
prebuilt x86_64 binaries and are skipped with a warning on other architectures.
Re-running is safe: installed tools are skipped, and any existing file the
script replaces with a symlink is first moved to `<file>.bak.<timestamp>`.

Try it without touching your machine:

```bash
docker run --rm -it -v "$PWD":/root/dotfiles ubuntu:24.04 \
    bash -c 'apt-get update -qq && apt-get install -y -qq sudo git curl && bash /root/dotfiles/setup.bash && exec zsh'
```

## Local, untracked files

| File | Use |
| --- | --- |
| `shell/local_env.sh` | switches read first by both shells (created from `local_env.sh.example`): `DOTFILES_CPP=1`, `DOTFILES_GAMEDEV=1`, `DOTFILES_PERSONAL=1`, `GODOT=…` |
| `shell/local.d/*.sh` | anything machine- or project-specific; every file is sourced |
| `shell/local_{aliases,functions,changes}.sh` | shared by Bash and Zsh |
| `{bash,zsh}/local_{aliases,functions,changes}.{bash,zsh}` | per shell |
| `~/.gitconfig_local` | git name, email and machine settings (created from `git/gitconfig_local.example`) |

All of these are git-ignored. `local_changes.*` is sourced last, so it can override anything.

## License

MIT, see [LICENSE](LICENSE). Submodules under `zsh/plugins/` and `shell/plugins/` keep their own licenses.

## Cheat sheet

Notation: `C-x` is Ctrl+x, `A-x` is Alt+x, `<prefix>` is the tmux prefix, `<leader>` is Space in Neovim.

### Shell (Bash and Zsh)

Both shells use vi line editing (`bindkey -v` / `set -o vi`): you start in insert mode, `Esc` switches to normal mode (`h j k l`, `w b`, `dd`, `/` history search). `KEYTIMEOUT=1` makes `Esc` instant.

| Shortcut | What it does |
| --- | --- |
| `..` / `...` | Up one / two directories |
| `z <part>` | zoxide: jump to the most used directory matching `<part>` (`z dotf`) |
| `zi` | zoxide with an interactive fzf picker |
| `cdgr` | cd to the root of the current git repository |
| `ls` `l` `la` `ll` `lt` | eza listings: plain, classified, with hidden, long with git status, tree two levels deep |
| `c` | clear the screen |
| `e` / `s` | exit / `shutdown -h` (power off in a minute, `shutdown -c` cancels); only with `DOTFILES_PERSONAL=1` |
| `top` | btop |
| `vim` `vi` `v` | all open Neovim |
| `sshx host` | ssh with X11 forwarding |
| `lg` | lazygit |
| `gag pattern` | ripgrep (`rg`) run from the repository root |
| `PR_SHOW_GIT=false` | hide git status in the Bash prompt (it runs `git status` synchronously per prompt) |
| `path_prepend dir` / `path_append dir` / `path_remove dir` | edit `$PATH` without duplicates |
| `zbench [N]` / `zbench -p` | Zsh startup time (mean of N runs) / zprof breakdown |
| `compreset` | rebuild the cached Zsh completion dump (after adding completions) |

Keys in the Zsh prompt:

| Key | What it does |
| --- | --- |
| `C-r` | atuin: full-screen fuzzy search of shell history (overrides fzf's `C-r`) |
| `C-t` | fzf: pick a file and insert its path |
| `A-c` | fzf: pick a directory and cd into it |
| `Tab` | fzf-tab completion menu; `cd` previews the directory, `<` and `>` switch completion groups |
| `→` | accept the grey zsh-autosuggestion (from history, then completion) |

Also loaded: direnv (a `.envrc` in a directory is loaded when you cd into it; run `direnv allow` once per file).

History: commands are written as they run; duplicates of the previous line and lines starting with a space are not saved (use that for commands containing secrets).

### AI (aichat)

| Command | What it does |
| --- | --- |
| `ai "question"` | ask aichat |
| `aicode "question"` | aichat with the terse `code` role |
| `aireview file.cpp` | review a file for correctness, style and numerical stability |
| `cmd 2>&1 \| aiexplain` | explain a command's output and suggest fixes |

### CMake

See the C++ section below (`cmb`, `cmt`, `cmwatch`, ...; on with `DOTFILES_CPP=1`).

### Git

Defaults worth knowing: histogram diffs with moved lines coloured, `zdiff3` conflict markers, rerere (a resolved conflict is resolved again automatically), `rebase` with autoSquash/autoStash/updateRefs, `fetch` prunes, branches sorted by last commit. Needs git ≥ 2.38.

### Git aliases (`git <alias>`)

Status, staging and commits:

| Alias | Runs | What it does |
| --- | --- | --- |
| `st` | `status -sb` | short status with branch line |
| `aa` | `add --all :/` | stage everything in the whole repository |
| `ci` / `ca` | `commit -v` / `commit --amend -v` | commit / amend, showing the diff in the editor |
| `save` | `commit -a -m "Save"` | quick save of all tracked changes |
| `co` | `checkout` | |
| `stsh` / `staash` | `stash --keep-index` / `stash --include-untracked` | stash unstaged only / stash including untracked files |

Diffs (suffix `s` = `--stat`, `w` = word diff):

| Alias | Compares |
| --- | --- |
| `di` `dis` `diw` | working tree vs index |
| `dc` `dcs` `dcw` | index vs HEAD (what you are about to commit) |
| `dh` `dhs` `dhw` | working tree vs the previous commit |
| `du` `dus` `duw` | your branch vs its upstream since they diverged (what you would push) |

History and inspection:

| Alias | What it does |
| --- | --- |
| `gr` / `grd` | graph log, one line / detailed |
| `gra` / `grad` | the same for all branches |
| `lg` | log with patches |
| `sf` / `sfs` / `sfw` | show a commit with full metadata / stat / word diff |
| `showtool [commit]` | open a commit in the difftool |
| `info <obj>` | print any object (commit, tree, blob) |
| `grp pattern` | grep with one line of context and line numbers |
| `cc` / `cca` | number of commits on HEAD / in all refs |
| `credit` / `linecredit` | commits per author / lines per author |
| `count` | size of the whole tree as a diff stat |
| `versions` | tags sorted as versions |
| `root` | path of the repository root |

Branches, remotes and merging:

| Alias | What it does |
| --- | --- |
| `br` / `bra` | branches with upstream and last commit / including remote branches |
| `bed` | edit the branch description |
| `f` / `fa` | fetch with tags and prune / from all remotes |
| `ff` / `noff` | merge fast-forward only / always with a merge commit |
| `pullrb` | pull with rebase (plain `pull` is fast-forward only) |
| `fmp` | fetch, merge the remote default branch (`origin/HEAD`), push |
| `mirror-remote from to` | push all branches of remote `from` to remote `to` |
| `update-submodules` / `upgrade-submodules` | init and check out pinned submodules / move them to their remote's latest |

Archives and misc:

| Alias | What it does |
| --- | --- |
| `tar f.tar` / `targz f.tar.gz` / `zip f.zip` | archive HEAD with the directory name as prefix |
| `ctags` | regenerate `.git/tags` |
| `empty-tree-hash` | hash of the empty tree |
| `cleanall` | `clean -fdx`: deletes every untracked and ignored file. Destructive. |

Defaults worth knowing: `pull` is fast-forward only, `push` sets the upstream automatically, the pager is delta (side by side, `n`/`N` jump between files), new repositories start on `main`, your name and email live in `~/.gitconfig_local`, and the Git LFS filter is preconfigured (run `git lfs install` inside a repository to add its hooks).

### tmux

The prefix is `C-Space`. Press `C-Space` twice to send a literal `C-Space` to the program inside, for example Neovim's completion.

| Keys | What it does |
| --- | --- |
| `<prefix> \|` / `<prefix> -` | split side by side / top and bottom, in the current directory |
| `<prefix> h j k l` | move between panes |
| `C-h C-j C-k C-l` | move between tmux panes and Neovim windows seamlessly (vim-tmux-navigator) |
| `<prefix> C-l` | clear the screen (plain `C-l` is taken by the navigator) |
| `<prefix> r` | reload `~/.tmux.conf` |
| `<prefix> L` | lazygit in a popup |
| `<prefix> A` | aichat in a pane on the right (25 % wide) |
| `<prefix> g` | aichat in a popup |
| `<prefix> G` | send the last 50 lines of the pane to aichat and show the answer in a popup |
| `<prefix> [` | copy mode (vi keys): `v` starts a selection, `y` copies to the system clipboard |
| `<prefix> C-s` / `<prefix> C-r` | save / restore sessions (tmux-resurrect) |

The mouse works for selecting panes, resizing and scrolling. Windows and panes are numbered from 1. Sessions are saved automatically and restored when tmux starts (tmux-continuum). Copying uses OSC 52, so it reaches your local clipboard over ssh too.

### Neovim

`<leader>` is Space. Press it and wait to see the available keys (which-key).

General:

| Keys | What it does |
| --- | --- |
| `<leader>w` / `<leader>q` | save / quit |
| `C-h C-j C-k C-l` | move between windows (and tmux panes) |
| `Esc` | clear search highlighting |
| `<` / `>` in visual mode | indent and keep the selection |
| `A-j` / `A-k` | move the line or selection down / up |
| `gcc` / `gc` in visual mode | toggle comments (built in) |

Finding files (Telescope) and Harpoon:

| Keys | What it does |
| --- | --- |
| `<leader>ff` or `C-p` | find files |
| `<leader>fg` | live grep in the project |
| `<leader>fb` | open buffers |
| `<leader>fs` | symbols in the current file |
| `<leader>ha` | add the file to Harpoon |
| `<leader>hh` | Harpoon menu |
| `<leader>1` … `<leader>4` | jump to Harpoon file 1–4 |

Code (LSP, diagnostics, completion):

| Keys | What it does |
| --- | --- |
| `gd` | go to definition |
| `K` | hover documentation |
| `<leader>rn` | rename the symbol |
| `<leader>ca` | code action |
| `<leader>e` | show the diagnostic under the cursor |
| `[d` / `]d` | previous / next diagnostic |
| `C-Space` (insert) | open completion (twice inside tmux) |
| `Tab` / `S-Tab` / `Enter` / `C-e` | next / previous item (or snippet field) / confirm (the first item is preselected) / close completion |
| `C-b` / `C-f` | scroll the completion docs |

On save, conform formats only the lines you changed in git-tracked files, and the whole file otherwise (clang-format, stylua, prettier, shfmt and others). `:FormatMode full` formats whole files, `:FormatMode off` disables it for the buffer, `:FormatMode auto` restores the default.

Debugging, tasks, math and AI:

| Keys | What it does |
| --- | --- |
| `F5` | start or continue the debugger |
| `F10` / `F11` / `F12` | step over / into / out |
| `<leader>b` | toggle a breakpoint |
| `<leader>du` | toggle the debugger UI |
| `<leader>or` / `<leader>ot` | run an Overseer task / toggle the task panel |
| `<leader>m` | toggle inline math rendering (C, C++, TeX, Markdown) |
| `<leader>ai` | AI chat panel (CodeCompanion) |
| `<leader>aa` | AI actions menu |
| `<leader>ae` / `<leader>ar` / `<leader>af` in visual mode | AI explain / review / fix the selection |

Godot and C++ (`nvim/lua/gamedev.lua`). GDScript LSP and debugging talk to the running Godot editor (ports 6005 and 6006):

| Keys | What it does |
| --- | --- |
| `<leader>Gr` / `<leader>Ge` / `<leader>Gs` | run the game / open the editor / run the current scene |
| `<leader>Gt` / `<leader>Gb` | run GDScript tests (`gdtest`) / build with CMake (`cmb`) |
| `<leader>ch` | switch between C++ source and header (clangd) |
| `<leader>ih` | toggle inlay hints |
| `<leader>B` | conditional breakpoint |
| `<leader>Dl` / `<leader>Dr` / `<leader>Dt` | debugger: run last / REPL / terminate |
| `F5` in a `.gd` file | debug the main or current scene through the editor |
| `F5` in a C++ file | pick "Godot: run game / editor / headless (GDExtension)", "Attach to Godot" or a test binary |

Inside a Godot project Neovim listens on `$XDG_RUNTIME_DIR/godot-nvim.sock`. Set Godot's external editor (Editor Settings → Text Editor → External) to `~/.local/bin/godot-nvim` with flags `{file} {line} {col}` and scripts open in that Neovim.

Tests (neotest: ctest adapter for C++, pytest for Python sims):

| Keys | What it does |
| --- | --- |
| `<leader>tn` / `<leader>tf` / `<leader>ta` | run nearest test / file / all |
| `<leader>tl` / `<leader>td` / `<leader>tx` | rerun last / debug nearest (codelldb) / stop |
| `<leader>ts` / `<leader>to` / `<leader>tO` | summary tree / output of test / output panel |
| `<leader>tw` | watch the file and rerun on save |
| `[t` / `]t` | previous / next failed test |

REPLs for balance sims (iron.nvim; Python uses IPython, Julia `--project=@.`, R). Cells are separated by `# %%`:

| Keys | What it does |
| --- | --- |
| `<leader>sr` / `<leader>sR` / `<leader>sq` | toggle / restart / quit the REPL |
| `<leader>sl` / `<leader>sf` / `<leader>su` | send line / file / up to the cursor |
| `<leader>sc{motion}`, `<leader>sc` in visual | send motion / selection |
| `<leader>sb` / `<leader>sn` | send cell / send cell and jump to the next |
| `<leader>s<space>` / `<leader>sx` | interrupt / clear |

### C++ (`DOTFILES_CPP=1`; also on with `DOTFILES_GAMEDEV=1`)

No engine assumptions; the project is the git root (`cpp_src`, `cdsrc`). The environment defaults to Ninja, `compile_commands.json`, ccache and parallel builds, and enables core dumps.

| Command | What it does |
| --- | --- |
| `cmb [preset\|Debug\|Release]` | configure and build; uses `CMakePresets.json` if present, otherwise `build[-type]/` and links `compile_commands.json` to the root |
| `cmpresets` | list the project's configure presets |
| `cmt [-R regex]` | ctest in `build/`, output on failure |
| `cmasan` / `cmtsan` | ASan + UBSan build in `build-asan/` / TSan build in `build-tsan/`, then run their tests |
| `cmprofile` | RelWithDebInfo with frame pointers in `build-profile/` |
| `cmwatch` | rebuild and test on every C++/CMake change |
| `cxdet [-n N] cmd [args]` | run N times (default 2) and compare stdout byte for byte; print per-tick state hashes from a lockstep sim to check determinism |
| `cxperf bin [args]` / `cxheap bin [args]` | CPU profile with perf, opens hotspot (`CXPERF_DWARF=1` without frame pointers) / heap profile with heaptrack |
| `perfstat bin [args]` | hardware counters over 5 runs |
| `perf-allow` | allow perf for your user until reboot |
| `cxcores [exe]` / `cxcore [exe\|pid]` / `cxcorebt` | list core dumps / open the newest in gdb / print its full backtrace |
| `netem wifi\|dsl\|mobile\|bad` | add latency, jitter, loss and a rate limit to loopback (round trip ≈ 2× the delay) |
| `netem set 40 8 1 10mbit` / `netem off` / `netem status` | custom delay ms, jitter ms, loss %, rate / remove / show |
| `cxsession [name] [run cmd]` | tmux session: Neovim, build watcher, a pane running `run cmd` |

### Game dev (`DOTFILES_GAMEDEV=1`)

Godot on top of the C++ helpers above.

The commands find the Godot project themselves (the nearest `project.godot`, or the shallowest one under the git root) and use `$GODOT` (default `godot`).

Run and test:

| Command | What it does |
| --- | --- |
| `gdr` / `gde` / `gdh [args]` | run the game / open the editor / run headless |
| `cdgd` | cd to the Godot project |
| `gdimport` | import assets headless, then exit |
| `gds script.gd` / `gdcheck script.gd` | run a script / parse-check it |
| `gdlintall` | gdlint every `.gd` file (skips `addons/`) |
| `gdverbose` | run with `--verbose --debug` |
| `gdtest [args]` / `gdwatch` | GUT or gdUnit4 tests headless / rerun them on every `.gd` change |
| `gdmulti N [args]` | N tiled instances for multiplayer; each gets `-- --instance=i`, logs in `/tmp/gd-instance-i.log`, `C-c` stops all |
| `gdsession [name]` | tmux session: Neovim, build watcher, editor log |

Debugging, profiling and crashes:

| Command | What it does |
| --- | --- |
| `gdgdb` / `gdlldb [args]` | Godot under gdb / lldb; extension breakpoints stay pending until the `.so` loads |
| `gdbt [args]` | run under gdb until it crashes, print every thread's backtrace |
| `gdcores` / `gdcore [pid]` / `gdcorebt` | list Godot core dumps / open the newest in gdb / print its full backtrace |
| `gdlogs [-f]` | Godot's own `user://logs/godot.log` for the project (`-f` follows) |
| `gdperf [args]` | CPU profile with perf (DWARF call graphs), opens hotspot |
| `gdheap [args]` | heap profile with heaptrack |

Balance sims:

| Command | What it does |
| --- | --- |
| `gdsim res://sim.gd [args]` | run a sim script headless; it gets `-- --out=FILE` and its CSV lands in `.sims/` (git-ignored) |
| `simview [file.csv]` | open the newest (or given) sim CSV in visidata |
| `jl` / `jlt` / `Rq` | Julia with the nearest project / run its tests / quiet R |

The global pre-commit hook (dev module) runs gdformat and gdlint on staged `.gd` files, clang-format on staged C++ when the repository has a `.clang-format`, and blocks files over 1 MiB that are not tracked by Git LFS. New clones get it automatically; run `git init` once in an existing repository. Skip it with `git commit --no-verify` or `SKIP_HOOKS=1`.
