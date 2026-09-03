-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", lazypath
  })
end
vim.opt.rtp:prepend(lazypath)

-- Leader key (before plugins)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- ─── Core settings (mirrors your vimrc) ───────────────────────────────────────

vim.opt.compatible    = false
vim.opt.encoding      = "utf-8"
vim.opt.number        = true
vim.opt.relativenumber = true
vim.opt.cursorline    = true
vim.opt.scrolloff     = 8
vim.opt.sidescrolloff = 8
vim.opt.wrap          = false

-- Indentation
vim.opt.tabstop       = 4
vim.opt.shiftwidth    = 4
vim.opt.softtabstop   = 4
vim.opt.expandtab     = true
vim.opt.smartindent   = true
vim.opt.autoindent    = true

-- Search
vim.opt.hlsearch      = true
vim.opt.incsearch     = true
vim.opt.ignorecase    = true
vim.opt.smartcase     = true

-- Splits
vim.opt.splitbelow    = true
vim.opt.splitright    = true

-- Files
vim.opt.swapfile      = false
vim.opt.backup        = false
vim.opt.undofile      = true
vim.opt.undodir       = vim.fn.stdpath("data") .. "/undo"

-- Appearance
vim.opt.termguicolors = true
vim.opt.signcolumn    = "yes"
vim.opt.colorcolumn   = "100"
vim.opt.laststatus    = 2
vim.opt.showmode      = false  -- lightline handles this

-- Clipboard
vim.opt.clipboard     = "unnamedplus"

-- ─── Keymaps ──────────────────────────────────────────────────────────────────

local map = function(mode, lhs, rhs, opts)
  opts = opts or { noremap = true, silent = true }
  vim.keymap.set(mode, lhs, rhs, opts)
end

-- Window navigation
map("n", "<C-h>", "<C-w>h")
map("n", "<C-j>", "<C-w>j")
map("n", "<C-k>", "<C-w>k")
map("n", "<C-l>", "<C-w>l")

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
map("n", "<leader>fg", ":Telescope live_grep<CR>")
map("n", "<leader>fb", ":Telescope buffers<CR>")
map("n", "<leader>fs", ":Telescope lsp_document_symbols<CR>")

-- LSP (set in on_attach, but global fallbacks)
map("n", "<leader>e", vim.diagnostic.open_float)
map("n", "[d",        vim.diagnostic.goto_prev)
map("n", "]d",        vim.diagnostic.goto_next)

-- ─── Load plugins ─────────────────────────────────────────────────────────────

require("lazy").setup("plugins", {
  change_detection = { notify = false },
})
