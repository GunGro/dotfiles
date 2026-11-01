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
	vim.keymap.set("n", "<leader>d", vim.diagnostic.open_float, opts)
end

vim.api.nvim_create_autocmd("LspAttach", {
	callback = function(args)
		on_attach(nil, args.buf)
	end,
})

-- ─── Shared LSP capabilities (enables full nvim-cmp completion features) ────
-- vim.lsp.config("*") is merged into every server (here, plugins.lua and
-- gamedev.lua), so no per-server capabilities tables.

local capabilities = vim.lsp.protocol.make_client_capabilities()
if pcall(require, "cmp_nvim_lsp") then
	capabilities = vim.tbl_deep_extend("force", capabilities, require("cmp_nvim_lsp").default_capabilities())
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
