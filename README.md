# dotfiles

Personal Debian/Ubuntu-oriented dotfiles for Bash, Zsh, Git, tmux and Neovim.

## Installation

Run `bash path_to_repository/setup.bash` from anywhere.

The setup script installs required packages, initializes submodules, installs shell/editor tooling, and links the config files into `$HOME`.

## Includes

- Bash and Zsh configuration
- Shared shell aliases and functions
- Zsh completions and syntax highlighting
- Neovim configuration using `lazy.nvim`
- tmux configuration with TPM plugins
- Git configuration and global ignore rules
- Modern CLI tooling: zoxide, eza, btop, lazygit, git-delta
- Game dev (Godot 4 + C++ GDExtension): shell helpers (`shell/gamedev.sh`),
  GDScript LSP/DAP and Godot-hosted C++ debugging in Neovim (`nvim/lua/gamedev.lua`),
  gdb/lldb/clangd configs, Godot external-editor bridge (`bin/godot-nvim`)

## Game dev quick reference

| Command | Does |
| --- | --- |
| `gdr` / `gde` / `gdh` | run game / editor / headless (`--path` = nearest `project.godot`) |
| `gdimport`, `gdcheck f.gd`, `gdlintall` | import assets, parse-check, gdlint all |
| `gdtest`, `gdwatch` | GUT/gdUnit4 headless tests, rerun on change |
| `gdmulti N` | N tiled instances for multiplayer testing (`-- --instance=i`) |
| `gdgdb` / `gdlldb` / `gdbt` | Godot under gdb/lldb; batch backtrace on crash |
| `cmb [preset]`, `cmt`, `cmasan`, `cmwatch` | CMake build, ctest, ASan+UBSan, watch |
| `gdsession` | tmux: nvim, build watch, editor log |
| `gdperf`, `gdheap` | CPU profile (perf + hotspot) / heap profile (heaptrack) of the game |
| `cmprofile`, `perfstat bin` | RelWithDebInfo + frame pointers build; perf counters over 5 runs |
| `perf-allow` | allow unprivileged perf until reboot |
| `netem wifi\|dsl\|mobile\|bad`, `netem set 40 8 1`, `netem off` | add latency, jitter, loss and rate limits to loopback (RTT ≈ 2× delay) |
| `gdsim res://sim.gd [args]`, `simview` | headless sim → `.sims/*.csv` (script gets `--out=`), open newest in visidata |
| `jl`, `jlt`, `Rq` | Julia with the nearest project / run its tests; quiet R |

Global pre-commit hook (`git/template/hooks/pre-commit`): gdformat/gdlint on staged `.gd`, clang-format on staged C++ (only if the repo has `.clang-format`), and a block on files over 1 MiB that are not in LFS. New clones get it automatically; run `git init` once in existing repos. Skip with `git commit --no-verify`.

Set `GODOT=/path/to/godot` in a `local_changes.*` file if it is not on `PATH`.
Install Godot with `GODOT_VER=4.x.y-stable bash setup.bash`.

## Local changes

Use the `*_local` and `local_*` files for machine-specific changes. These files are ignored by Git.

## Cheat sheet

Notation: `C-x` is Ctrl+x, `A-x` is Alt+x, `<prefix>` is the tmux prefix, `<leader>` is Space in Neovim.

### Shell (Bash and Zsh)

Both shells use vi line editing (`bindkey -v` / `set -o vi`): you start in insert mode, `Esc` switches to normal mode (`h j k l`, `w b`, `dd`, `/` history search). `KEYTIMEOUT=1` makes `Esc` instant.

| Shortcut | What it does |
| --- | --- |
| `..` / `...` | Up one / two directories |
| `z <part>` | zoxide: jump to the most used directory matching `<part>` (`z athen`) |
| `zi` | zoxide with an interactive fzf picker |
| `cdgr` | cd to the root of the current git repository |
| `ls` `l` `la` `ll` `lt` | eza listings: plain, classified, with hidden, long with git status, tree two levels deep |
| `c` | clear the screen |
| `e` | exit the shell |
| `s` | `shutdown -h`: power off in one minute (`shutdown -c` cancels) |
| `top` | btop |
| `vim` `vi` `v` | all open Neovim |
| `sshx host` | ssh with X11 forwarding |
| `lg` | lazygit |
| `gag pattern` | `ag` (the silver searcher) run from the repository root |
| `path_prepend dir` / `path_append dir` / `path_remove dir` | edit `$PATH` without duplicates |

Keys in the Zsh prompt:

| Key | What it does |
| --- | --- |
| `C-r` | atuin: full-screen fuzzy search of shell history (overrides fzf's `C-r`) |
| `C-t` | fzf: pick a file and insert its path |
| `A-c` | fzf: pick a directory and cd into it |
| `Tab` | fzf-tab completion menu; `cd` previews the directory, `<` and `>` switch completion groups |
| `→` | accept the grey zsh-autosuggestion (from history, then completion) |

Also loaded: direnv (a `.envrc` in a directory is loaded when you cd into it; run `direnv allow` once per file) and conda.

### AI (aichat)

| Command | What it does |
| --- | --- |
| `ai "question"` | ask aichat |
| `aicode "question"` | aichat with the terse `code` role |
| `aireview file.cpp` | review a file for correctness, style and numerical stability |
| `cmd 2>&1 \| aiexplain` | explain a command's output and suggest fixes |

### CMake

| Alias | What it does |
| --- | --- |
| `cmake-init` | configure into `build/` with Ninja and `compile_commands.json` |
| `cmake-build` | build |
| `cmake-clean` | delete `build/` |
| `cmake-rebuild` | clean, configure, build |
| `cmake-link` | symlink `compile_commands.json` to the project root (for clangd) |
| `cmake-fresh` | clean, configure, build, link |
| `cmake-watch` | rebuild on every C/C++ file change (needs watchexec) |

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
| `fmp` | fetch, merge `origin/master`, push (only for repositories whose branch is `master`) |
| `mirror-remote from to` | push all branches of remote `from` to remote `to` |
| `update-submodules` / `upgrade-submodules` | init and check out pinned submodules / move them to their remote's latest |

Archives and misc:

| Alias | What it does |
| --- | --- |
| `tar f.tar` / `targz f.tar.gz` / `zip f.zip` | archive HEAD with the directory name as prefix |
| `ctags` | regenerate `.git/tags` |
| `empty-tree-hash` | hash of the empty tree |
| `cleanall` | `clean -fdx`: deletes every untracked and ignored file. Destructive. |

Defaults worth knowing: `pull` is fast-forward only, `push` sets the upstream automatically, the pager is delta (side by side, `n`/`N` jump between files), new repositories start on `master`, and your name and email live in `~/.gitconfig_local`.

### tmux

The prefix is `C-Space`. Press `C-Space` twice to send a literal `C-Space` to the program inside, for example Neovim's completion.

| Keys | What it does |
| --- | --- |
| `<prefix> \|` / `<prefix> -` | split side by side / top and bottom, in the current directory |
| `<prefix> h j k l` | move between panes |
| `C-h C-j C-k C-l` | move between tmux panes and Neovim windows seamlessly (vim-tmux-navigator) |
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
| `gcc` / `gc` in visual mode | toggle comments (Comment.nvim) |

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
| `<leader>e` or `<leader>d` | show the diagnostic under the cursor |
| `[d` / `]d` | previous / next diagnostic |
| `C-Space` (insert) | open completion (twice inside tmux) |
| `Tab` / `Enter` / `C-e` | next item / confirm / close completion |
| `C-b` / `C-f` | scroll the completion docs |

On save, conform formats only the lines you changed in git-tracked files, and the whole file otherwise (clang-format, stylua, prettier and others). `:FormatMode full` formats whole files, `:FormatMode off` disables it for the buffer, `:FormatMode auto` restores the default.

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

### Athenebra helpers (machine-local)

`~/.config/shell/local_athenebra.sh` is not in this repository; `zshrc` and `bashrc` source it when it exists.

| Command | What it does |
| --- | --- |
| `ath` | cd to the Athenebra repository |
| `ath-lint` | ruff, ruff format check, mypy |
| `ath-test [args]` | pytest with the test database (integration tests included) |
| `ath-check` | `ath-lint` and `ath-test`: what CI runs |
| `ath-apply p.diff …` | check that all patches apply, apply them, `uv sync`, `ath-check` |
| `ath-migrate` | database upgrade as the owner role, re-run `roles.sql`, `alembic check` |
| `ath-snapshot` | today's data snapshot with readable logs and the exit code |
| `ath-qc [--as-of T]` | data-quality gates |
| `ath-status` | row counts and freshness per table |
| `ath-psql [role]` | psql into the database (default role `athenebra_ro`) |
| `ath-sql 'SELECT …'` | one read-only query |
| `ath-raw ID\|SHA` | first bytes of a stored raw response |
| `ath-logs` | journal of the snapshot service |
