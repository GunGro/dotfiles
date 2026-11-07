-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable",
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

-- Leader key (before plugins)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- ─── Core settings ─────────────────────────────────────────────────────────

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.cursorline = true
vim.opt.scrolloff = 8
vim.opt.sidescrolloff = 8
vim.opt.wrap = false

-- Indentation
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4
vim.opt.expandtab = true
vim.opt.autoindent = true

-- Search
vim.opt.hlsearch = true
vim.opt.incsearch = true
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- Splits
vim.opt.splitbelow = true
vim.opt.splitright = true

-- Files
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undofile = true
vim.opt.undodir = vim.fn.stdpath("data") .. "/undo"

-- Appearance
vim.opt.termguicolors = true
vim.opt.signcolumn = "yes"
vim.opt.colorcolumn = "100"
vim.opt.laststatus = 2
vim.opt.showmode = false -- lualine handles this

-- Clipboard
vim.opt.clipboard = "unnamedplus"

-- Provider: wl-copy/xclip when a display works, OSC 52 otherwise. A tmux
-- server outlives logins, so its panes can hold a DISPLAY whose cookie is gone
-- (XAUTHORITY under GNOME/Xwayland is a new random file per login): xclip then
-- fails with "Authorization required". On failure we pull DISPLAY, XAUTHORITY
-- and WAYLAND_DISPLAY of the current tmux client and retry once, then fall
-- back to OSC 52 (through tmux set-clipboard and ssh to the terminal you type
-- in) for the rest of the session. Over ssh we go straight to OSC 52. OSC 52
-- paste comes from Nvim's own register: terminal reads are unsupported or
-- prompt, so paste the local clipboard with the terminal (Ctrl+Shift+V).
do
	local osc52 = require("vim.ui.clipboard.osc52")
	local selection = { ["+"] = "clipboard", ["*"] = "primary" }
	local use_system = not (vim.env.SSH_TTY or vim.env.SSH_CONNECTION)

	local function refresh_env()
		if not vim.env.TMUX then
			return
		end
		for _, name in ipairs({ "DISPLAY", "XAUTHORITY", "WAYLAND_DISPLAY" }) do
			local r = vim.system({ "tmux", "show-environment", name }, { text = true }):wait()
			if r.code == 0 then
				local val = r.stdout:match("^" .. name .. "=(.-)\n?$")
				vim.env[name] = val -- "-NAME" (removed) gives nil
			end
		end
	end

	local function tool(reg, paste)
		if vim.env.WAYLAND_DISPLAY and vim.fn.executable("wl-copy") == 1 then
			local cmd = paste and { "wl-paste", "--no-newline" } or { "wl-copy", "--type", "text/plain" }
			if reg == "*" then
				table.insert(cmd, "--primary")
			end
			return cmd
		elseif vim.env.DISPLAY and vim.fn.executable("xclip") == 1 then
			return { "xclip", paste and "-o" or "-i", "-selection", selection[reg] }
		end
	end

	-- xclip/wl-copy fork a child that owns the selection; the parent exits 0
	-- once it is set and non-zero when the display is unusable.
	local function system_copy(reg, text)
		local cmd = tool(reg, false)
		if not cmd then
			return false
		end
		local ok, r = pcall(function()
			return vim.system(cmd, { stdin = text, stdout = false, stderr = false, timeout = 2000 }):wait()
		end)
		return ok and r.code == 0
	end

	local function copy(reg)
		local fallback = osc52.copy(reg)
		return function(lines, regtype)
			if use_system then
				local text = table.concat(lines, "\n") .. (regtype == "V" and "\n" or "")
				if system_copy(reg, text) then
					return
				end
				refresh_env()
				if system_copy(reg, text) then
					return
				end
				use_system = false
				vim.notify("clipboard: no usable display, yanking via OSC 52", vim.log.levels.WARN)
			end
			fallback(lines, regtype)
		end
	end

	local function paste(reg)
		return function()
			local cmd = use_system and tool(reg, true)
			if cmd then
				local r = vim.system(cmd, { text = true, timeout = 2000 }):wait()
				if r.code == 0 then
					local lines = vim.split(r.stdout, "\n", { plain = true })
					if #lines > 1 and lines[#lines] == "" then
						table.remove(lines)
						return { lines, "V" }
					end
					return { lines, "v" }
				end
			end
			return { vim.fn.split(vim.fn.getreg('"'), "\n"), vim.fn.getregtype('"') }
		end
	end

	vim.g.clipboard = {
		name = "system or OSC 52",
		copy = { ["+"] = copy("+"), ["*"] = copy("*") },
		paste = { ["+"] = paste("+"), ["*"] = paste("*") },
	}
end

-- ─── Keymaps ──────────────────────────────────────────────────────────────────

local map = function(mode, lhs, rhs, opts)
	opts = opts or { noremap = true, silent = true }
	vim.keymap.set(mode, lhs, rhs, opts)
end

-- Window navigation: <C-hjkl> come from vim-tmux-navigator (lua/plugins.lua),
-- which moves across nvim splits and tmux panes alike.

-- Clear search highlight
map("n", "<Esc>", ":nohlsearch<CR>")

-- Better indenting in visual mode
map("v", "<", "<gv")
map("v", ">", ">gv")

-- Move lines up/down
map("n", "<A-j>", ":m .+1<CR>==")
map("n", "<A-k>", ":m .-2<CR>==")
map("v", "<A-j>", ":m '>+1<CR>gv=gv")
map("v", "<A-k>", ":m '<-2<CR>gv=gv")

-- Quick save
map("n", "<leader>w", ":w<CR>")
map("n", "<leader>q", ":q<CR>")

-- Telescope
map("n", "<leader>ff", ":Telescope find_files<CR>")
map("n", "<C-p>", ":Telescope find_files<CR>")
map("n", "<leader>fg", ":Telescope live_grep<CR>")
map("n", "<leader>fb", ":Telescope buffers<CR>")
map("n", "<leader>fs", ":Telescope lsp_document_symbols<CR>")

-- Diagnostics. Neovim >= 0.11 already maps [d ]d (jump), K (hover) and
-- grn/gra/grr/gri (rename/action/references/implementation).
map("n", "<leader>e", vim.diagnostic.open_float)

-- ─── Load plugins ─────────────────────────────────────────────────────────────

require("lazy").setup("plugins", {
	change_detection = { notify = false },
    readme = { enabled = false },
})

-- ─── LSP on_attach (shared across all servers) ──────────────────────────────

local on_attach = function(_, bufnr)
	local opts = { buffer = bufnr, silent = true }
	vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
	vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
	vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
	vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
end

vim.api.nvim_create_autocmd("LspAttach", {
	callback = function(args)
		on_attach(nil, args.buf)
	end,
})

-- ─── Shared LSP capabilities (completion features from blink.cmp) ──────────
-- vim.lsp.config("*") is merged into every server (here, plugins.lua and
-- gamedev.lua), so no per-server capabilities tables.

local capabilities = vim.lsp.protocol.make_client_capabilities()
local ok_blink, blink = pcall(require, "blink.cmp")
if ok_blink then
	capabilities = blink.get_lsp_capabilities(capabilities)
end
vim.lsp.config("*", { capabilities = capabilities })

-- ─── clangd ─────────────────────────────────────────────────────────────────

vim.lsp.config("clangd", {
	cmd = {
		"clangd",
		"--background-index",
		"--clang-tidy",
		"--header-insertion=iwyu",
		"--completion-style=detailed",
		"--function-arg-placeholders=true",
		"--all-scopes-completion",
		"--pch-storage=memory",
		"--query-driver=/usr/bin/c++,/usr/bin/g++*,/usr/bin/clang++*",
	},
	filetypes = { "c", "cpp", "objc", "objcpp" },
	root_markers = { "compile_commands.json", "CMakeLists.txt", ".git" },
})
vim.lsp.enable("clangd")

-- ─── typos-lsp ──────────────────────────────────────────────────────────────

vim.lsp.config("typos_lsp", {
	cmd = { "typos-lsp" },
	filetypes = { "c", "cpp", "lua", "python", "sh", "markdown", "text" },
	root_markers = { ".git" },
})
vim.lsp.enable("typos_lsp")

-- ─── Game dev (Godot / GDExtension) ─────────────────────────────────────────

require("gamedev")
