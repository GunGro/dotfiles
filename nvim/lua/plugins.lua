return {

	-- ─── Colorscheme: Catppuccin ────────────────────────────────────────────────
	{
		"catppuccin/nvim",
		name = "catppuccin",
		lazy = false,
		priority = 1000,
		config = function()
			require("catppuccin").setup({
				flavour = "mocha", -- mocha (darkest), macchiato, frappe, latte (light)
				transparent_background = false,
				integrations = {
					cmp = true,
					gitsigns = true,
					telescope = true,
					treesitter = true,
					native_lsp = {
						enabled = true,
						underlines = {
							errors = { "undercurl" },
							warnings = { "undercurl" },
						},
					},
					dap = { enabled = true, enable_ui = true },
					mason = true,
					which_key = true,
					indent_blankline = { enabled = true },
				},
			})
			vim.cmd.colorscheme("catppuccin")
		end,
	},

	-- ─── Statusline: Lualine ────────────────────────────────────────────────────
	{
		"nvim-lualine/lualine.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		config = function()
			require("lualine").setup({
				options = {
					theme = "catppuccin",
					component_separators = "|",
					section_separators = "",
				},
				sections = {
					lualine_a = { "mode" },
					lualine_b = { "branch", "diff", "diagnostics" },
					lualine_c = { "filename" },
					lualine_x = { "filetype" },
					lualine_y = { "progress" },
					lualine_z = { "location" },
				},
			})
		end,
	},

	-- ─── Git ──────────────────────────────────────────────────────────────────
	{ "tpope/vim-fugitive", lazy = false },

	{
		"lewis6991/gitsigns.nvim",
		config = function()
			require("gitsigns").setup({
				signs = {
					add = { text = "▎" },
					change = { text = "▎" },
					delete = { text = "▁" },
					topdelete = { text = "▔" },
					changedelete = { text = "▎" },
				},
			})
		end,
	},

	-- ─── Telescope ────────────────────────────────────────────────────────────
	{
		"nvim-telescope/telescope.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim",
			{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
		},
		config = function()
			local telescope = require("telescope")
			telescope.setup({
				defaults = {
					layout_strategy = "horizontal",
					sorting_strategy = "ascending",
					layout_config = { prompt_position = "top" },
				},
			})
			telescope.load_extension("fzf")
		end,
	},

	-- ─── Treesitter ───────────────────────────────────────────────────────────
	{
		"nvim-treesitter/nvim-treesitter",
		branch = "main",
		build = ":TSUpdate",
		config = function()
			local ts = require("nvim-treesitter")

			ts.setup()

			-- Install parsers for the languages you use
			ts.install({ "c", "cpp", "lua", "python", "bash", "cmake" })

			-- Start highlighting + indent per-buffer for these filetypes
			vim.api.nvim_create_autocmd("FileType", {
				pattern = { "c", "cpp", "lua", "python", "bash", "cmake" },
				callback = function()
					vim.treesitter.start()
					vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
				end,
			})
		end,
	},

	-- ─── C++ / LSP (native vim.lsp API, Neovim >= 0.11) ────────────────────────

	{
		"williamboman/mason.nvim",
		dependencies = {
			"WhoIsSethDaniel/mason-tool-installer.nvim",
		},
		config = function()
			require("mason").setup({
				ui = {
					icons = {
						package_installed = "✓",
						package_pending = "➜",
						package_uninstalled = "✗",
					},
				},
			})

			require("mason-tool-installer").setup({
				ensure_installed = {
					"clangd",
					"codelldb",
					"typos-lsp",
					"stylua",
					"shfmt",
					-- clang-format intentionally omitted: installed via apt
				},
				auto_update = false,
				run_on_start = true,
			})
		end,
	},

	-- nvim-lspconfig kept only for its server definitions (name→cmd mappings),
	-- NOT as a setup framework. No require('lspconfig').X.setup() anywhere.
	{ "neovim/nvim-lspconfig" },

	-- ─── Completion ───────────────────────────────────────────────────────────
	{
		"hrsh7th/nvim-cmp",
		dependencies = {
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/cmp-buffer",
			"hrsh7th/cmp-path",
			"L3MON4D3/LuaSnip",
			"saadparwaiz1/cmp_luasnip",
		},
		config = function()
			local cmp = require("cmp")
			local luasnip = require("luasnip")

			cmp.setup({
				snippet = {
					expand = function(args)
						luasnip.lsp_expand(args.body)
					end,
				},
				mapping = cmp.mapping.preset.insert({
					["<C-b>"] = cmp.mapping.scroll_docs(-4),
					["<C-f>"] = cmp.mapping.scroll_docs(4),
					["<C-Space>"] = cmp.mapping.complete(),
					["<C-e>"] = cmp.mapping.abort(),
					["<CR>"] = cmp.mapping.confirm({ select = true }),
					["<Tab>"] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.select_next_item()
						elseif luasnip.expand_or_jumpable() then
							luasnip.expand_or_jump()
						else
							fallback()
						end
					end, { "i", "s" }),
				}),
				sources = cmp.config.sources({
					{ name = "nvim_lsp" },
					{ name = "luasnip" },
					{ name = "buffer" },
					{ name = "path" },
				}),
			})

			-- Wire autopairs into cmp: auto-insert () after accepting a function completion
			local cmp_autopairs = require("nvim-autopairs.completion.cmp")
			cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
		end,
	},

	-- ─── Formatting ───────────────────────────────────────────────────────────
	{
		"stevearc/conform.nvim",
		config = function()
			require("conform").setup({
				formatters_by_ft = {
					cpp = { "clang_format" },
					c = { "clang_format" },
					lua = { "stylua" },
					sh = { "shfmt" },
				},
				format_on_save = {
					timeout_ms = 500,
					lsp_fallback = true,
				},
			})
		end,
	},

	-- ─── Debugger (DAP) ─────────────────────────────────────────────────────────

	{
		"mfussenegger/nvim-dap",
		dependencies = {
			"rcarriga/nvim-dap-ui",
			"nvim-neotest/nvim-nio",
		},
		config = function()
			local dap = require("dap")
			local dapui = require("dapui")

			dapui.setup()

			-- Auto-open/close UI on session start/end
			dap.listeners.after.event_initialized["dapui_config"] = dapui.open
			dap.listeners.before.event_terminated["dapui_config"] = dapui.close
			dap.listeners.before.event_exited["dapui_config"] = dapui.close

			-- codelldb adapter (installed by Mason)
			local mason_path = vim.fn.stdpath("data") .. "/mason"
			dap.adapters.codelldb = {
				type = "server",
				port = "${port}",
				executable = {
					command = mason_path .. "/packages/codelldb/extension/adapter/codelldb",
					args = { "--port", "${port}" },
				},
			}

			dap.configurations.cpp = {
				{
					name = "Launch",
					type = "codelldb",
					request = "launch",
					program = function()
						return vim.fn.input("Executable: ", vim.fn.getcwd() .. "/build/", "file")
					end,
					cwd = "${workspaceFolder}",
					stopOnEntry = false,
					args = {},
				},
			}
			dap.configurations.c = dap.configurations.cpp

			-- Keymaps
			vim.keymap.set("n", "<F5>", dap.continue)
			vim.keymap.set("n", "<F10>", dap.step_over)
			vim.keymap.set("n", "<F11>", dap.step_into)
			vim.keymap.set("n", "<F12>", dap.step_out)
			vim.keymap.set("n", "<leader>b", dap.toggle_breakpoint)
			vim.keymap.set("n", "<leader>du", dapui.toggle)
		end,
	},

	-- ─── Build runner ───────────────────────────────────────────────────────────

	{
		"stevearc/overseer.nvim",
		config = function()
			require("overseer").setup()
			vim.keymap.set("n", "<leader>or", "<cmd>OverseerRun<cr>", { desc = "Overseer run task" })
			vim.keymap.set("n", "<leader>ot", "<cmd>OverseerToggle<cr>", { desc = "Overseer toggle panel" })
		end,
	},

	-- ─── LaTeX math in comments ─────────────────────────────────────────────────

	{
		"jbyuki/nabla.nvim",
		ft = { "cpp", "c", "tex", "markdown" },
		config = function()
			-- Toggle inline math rendering with <leader>m
			vim.keymap.set("n", "<leader>m", function()
				require("nabla").toggle_virt()
			end, { desc = "Toggle math preview" })
		end,
	},

	-- ─── AI: codecompanion (in-editor AI chat + inline actions) ─────────────────

	{
		"olimorris/codecompanion.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-treesitter/nvim-treesitter",
			"nvim-telescope/telescope.nvim",
		},
		config = function()
			require("codecompanion").setup({
				-- Reads OPENAI_API_KEY from env, or set api_key directly below.
				-- For local Ollama: change adapter to "ollama" and set model below.
				adapters = {
					openai = require("codecompanion.adapters").extend("openai", {
						env = { api_key = "OPENAI_API_KEY" }, -- reads from env var
						schema = { model = { default = "gpt-4o" } },
					}),
				},
				strategies = {
					chat = { adapter = "openai" },
					inline = { adapter = "openai" },
				},
				display = {
					chat = { window = { layout = "vertical", width = 0.35 } },
				},
			})

			-- Keymaps
			vim.keymap.set({ "n", "v" }, "<leader>ai", "<cmd>CodeCompanionChat Toggle<cr>", { desc = "AI chat panel" })
			vim.keymap.set({ "n", "v" }, "<leader>aa", "<cmd>CodeCompanionActions<cr>", { desc = "AI actions" })
			vim.keymap.set("v", "<leader>ae", "<cmd>CodeCompanion /explain<cr>", { desc = "AI explain selection" })
			vim.keymap.set("v", "<leader>ar", "<cmd>CodeCompanion /review<cr>", { desc = "AI review selection" })
			vim.keymap.set("v", "<leader>af", "<cmd>CodeCompanion /fix<cr>", { desc = "AI fix selection" })
		end,
	},

	-- ─── Quality of life ──────────────────────────────────────────────────────
	{
		"numToStr/Comment.nvim",
		config = function()
			require("Comment").setup()
		end,
	},

	{
		"windwp/nvim-autopairs",
		config = function()
			require("nvim-autopairs").setup()
		end,
	},

	{
		"lukas-reineke/indent-blankline.nvim",
		main = "ibl",
		config = function()
			require("ibl").setup()
		end,
	},
}
