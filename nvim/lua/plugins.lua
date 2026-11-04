return {
	-- <C-hjkl> across nvim splits and tmux panes. The tmux half is the
	-- christoomey/vim-tmux-navigator TPM plugin in tmux.conf; without this
	-- side, <C-hjkl> inside nvim never reached a neighbouring tmux pane.
	{
		"christoomey/vim-tmux-navigator",
		cmd = {
			"TmuxNavigateLeft",
			"TmuxNavigateDown",
			"TmuxNavigateUp",
			"TmuxNavigateRight",
			"TmuxNavigatePrevious",
		},
		keys = {
			{ "<C-h>", "<cmd>TmuxNavigateLeft<cr>", desc = "Window/pane left" },
			{ "<C-j>", "<cmd>TmuxNavigateDown<cr>", desc = "Window/pane down" },
			{ "<C-k>", "<cmd>TmuxNavigateUp<cr>", desc = "Window/pane up" },
			{ "<C-l>", "<cmd>TmuxNavigateRight<cr>", desc = "Window/pane right" },
		},
	},

	{
		"folke/which-key.nvim",
		event = "VeryLazy",
		config = function()
			require("which-key").setup({})
		end,
	},

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
					blink_cmp = true,
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
		event = "VeryLazy",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		config = function()
			require("lualine").setup({
				options = {
					theme = "auto",
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
	{
		"tpope/vim-fugitive",
		cmd = { "G", "Git", "Gdiffsplit", "Gvdiffsplit", "Gread", "Gwrite", "Gedit", "GBrowse" },
	},

	{
		"lewis6991/gitsigns.nvim",
		event = { "BufReadPre", "BufNewFile" },
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
		cmd = "Telescope",
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
					-- Godot cache / generated sidecar files
					file_ignore_patterns = { "^%.godot/", "/%.godot/", "%.import$", "%.uid$" },
				},
			})
			telescope.load_extension("fzf")
		end,
	},

	-- ─── Harpoon: fixed-file quick-switching ───────────────────────────────────
	{
		"ThePrimeagen/harpoon",
		branch = "harpoon2",
		dependencies = { "nvim-lua/plenary.nvim" },
		keys = function()
			local h = function()
				return require("harpoon")
			end
			local keys = {
				{ "<leader>ha", function() h():list():add() end, desc = "Harpoon: add file" },
				{ "<leader>hh", function() h().ui:toggle_quick_menu(h():list()) end, desc = "Harpoon: toggle menu" },
			}
			for i = 1, 4 do
				table.insert(keys, { "<leader>" .. i, function() h():list():select(i) end, desc = "Harpoon: file " .. i })
			end
			return keys
		end,
		config = function()
			require("harpoon"):setup()
		end,
	},

	-- ─── Treesitter ───────────────────────────────────────────────────────────
	{
		"nvim-treesitter/nvim-treesitter",
		branch = "main",
		lazy = false, -- the main branch does not support lazy-loading
		build = ":TSUpdate",
		config = function()
			local ts = require("nvim-treesitter")

			ts.setup()

			-- Install parsers for the languages you use
			ts.install({
				"c",
				"cpp",
				"lua",
				"python",
				"bash",
				"cmake",
				"markdown",
				"typescript",
				"tsx",
				"javascript",
				"vim",
				"vimdoc",
				"query",
				"gdscript",
				"godot_resource",
				"gdshader",
				"julia",
				"r",
			})
			vim.treesitter.language.register("godot_resource", "gdresource")

			-- Start highlighting + indent per-buffer for these filetypes. Patterns
			-- are filetypes, not parser names: shell scripts are "sh" and TSX is
			-- "typescriptreact" (Neovim maps both to the bash/tsx parsers), so the
			-- old "bash"/"tsx" entries never matched. pcall: the parser may still be
			-- installing on first start.
			vim.api.nvim_create_autocmd("FileType", {
				pattern = {
					"c", "cpp", "lua", "python", "sh", "bash", "cmake",
					"typescript", "typescriptreact", "javascript", "julia", "r",
				},
				callback = function()
					if pcall(vim.treesitter.start) then
						vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
					end
				end,
			})

			-- Godot: highlight only (keep Vim's own gdscript indent)
			vim.api.nvim_create_autocmd("FileType", {
				pattern = { "gdscript", "gdresource", "gdshader" },
				callback = function()
					pcall(vim.treesitter.start)
				end,
			})
		end,
	},

	-- ─── C++ / LSP (native vim.lsp API, Neovim >= 0.11) ────────────────────────

	{
		"mason-org/mason.nvim", -- moved from williamboman/mason.nvim (v2)
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
					"vtsls",
					"js-debug-adapter",
					"prettier",
					-- clang-format intentionally omitted: installed via apt
				},
				auto_update = false,
				run_on_start = true,
			})
		end,
	},

	-- nvim-lspconfig kept only for its server definitions (name→cmd mappings),
	-- NOT as a setup framework. No require('lspconfig').X.setup() anywhere.
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			"mason-org/mason.nvim",
		},
		config = function()
			-- capabilities come from vim.lsp.config("*") in init.lua
			vim.lsp.config("vtsls", {
				cmd = { "vtsls", "--stdio" },
				filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
				settings = {
					typescript = {
						updateImportsOnFileMove = { enabled = "always" },
						inlayHints = {
							parameterNames = { enabled = "all" },
							variableTypes = { enabled = true },
						},
					},
				},
			})

			vim.lsp.enable("vtsls")
		end,
	},

	-- ─── Completion ───────────────────────────────────────────────────────────
	-- blink.cmp: LSP/path/snippet/buffer sources, signature help and auto
	-- brackets built in (replaces nvim-cmp + 4 source plugins + the autopairs
	-- confirm hook). version = "1.*" pulls the prebuilt Rust fuzzy matcher
	-- from the release tag; without it, blink falls back to its Lua matcher.
	{
		"saghen/blink.cmp",
		version = "1.*",
		dependencies = {
			{ "L3MON4D3/LuaSnip", version = "v2.*" },
		},
		opts = {
			-- Same keys as the old nvim-cmp setup.
			keymap = {
				preset = "none",
				["<C-Space>"] = { "show", "show_documentation", "hide_documentation" },
				["<C-e>"] = { "hide", "fallback" },
				["<CR>"] = { "accept", "fallback" },
				["<Tab>"] = { "select_next", "snippet_forward", "fallback" },
				["<S-Tab>"] = { "select_prev", "snippet_backward", "fallback" },
				["<C-n>"] = { "select_next", "fallback" },
				["<C-p>"] = { "select_prev", "fallback" },
				["<C-b>"] = { "scroll_documentation_up", "fallback" },
				["<C-f>"] = { "scroll_documentation_down", "fallback" },
			},
			snippets = { preset = "luasnip" },
			sources = {
				default = { "lsp", "path", "snippets", "buffer" },
			},
			completion = {
				-- <CR> with nothing selected takes the first item (cmp's select = true)
				list = { selection = { preselect = true, auto_insert = false } },
				-- () after accepting a function/method (was nvim-autopairs' cmp hook)
				accept = { auto_brackets = { enabled = true } },
				documentation = { auto_show = true, auto_show_delay_ms = 250 },
			},
			signature = { enabled = true },
			fuzzy = { implementation = "prefer_rust_with_warning" },
		},
		opts_extend = { "sources.default" },
	},

	-- ─── Formatting ───────────────────────────────────────────────────────────
	{
		"stevearc/conform.nvim",
		event = "BufWritePre",
		cmd = { "ConformInfo", "FormatMode" },
		dependencies = { "lewis6991/gitsigns.nvim" },
		config = function()
			local conform = require("conform")
			conform.setup({
				formatters_by_ft = {
					c = { "clang_format" },
					cpp = { "clang_format" },
					lua = { "stylua" },
					python = { "ruff_format" },
					javascript = { "prettier" },
					typescript = { "prettier" },
					javascriptreact = { "prettier" },
					typescriptreact = { "prettier" },
					gdscript = { "gdformat" },
					sh = { "shfmt" }, -- installed by mason, was never wired up
				},
				-- Match the repo's shell style: 4-space indent, indented case arms.
				-- An .editorconfig in a project still wins (shfmt reads it).
				formatters = {
					shfmt = { prepend_args = { "-i", "4", "-ci" } },
				},
				-- no format_on_save here; the autocmd below handles it
			})

			local fmt_opts = { async = false, timeout_ms = 1000, lsp_format = "fallback" }

			local function format_changed_or_all(bufnr)
				local mode = vim.b[bufnr].format_mode -- optional override via :FormatMode
				if mode == "off" then
					return
				end

				-- gitsigns sets this only when the buffer is attached (tracked file in a repo)
				local tracked = vim.b[bufnr].gitsigns_status_dict ~= nil
				if mode == "full" or not tracked then
					conform.format(vim.tbl_extend("force", fmt_opts, { bufnr = bufnr }))
					return
				end

				local hunks = require("gitsigns").get_hunks(bufnr) or {}
				for i = #hunks, 1, -1 do -- bottom-up so earlier ranges don't shift
					local h = hunks[i]
					if h.type ~= "delete" and h.added.count > 0 then
						local first = h.added.start
						local last = first + h.added.count - 1
						local last_line = vim.api.nvim_buf_get_lines(bufnr, last - 1, last, true)[1]
						conform.format(vim.tbl_extend("force", fmt_opts, {
							bufnr = bufnr,
							range = { start = { first, 0 }, ["end"] = { last, #last_line } },
						}))
					end
				end
			end

			vim.api.nvim_create_autocmd("BufWritePre", {
				group = vim.api.nvim_create_augroup("FormatOnSave", { clear = true }),
				callback = function(args)
					format_changed_or_all(args.buf)
				end,
			})

			-- :FormatMode full | auto | off   (current buffer only)
			vim.api.nvim_create_user_command("FormatMode", function(opts)
				vim.b.format_mode = opts.args ~= "auto" and opts.args or nil
				vim.notify("Format on save: " .. opts.args)
			end, {
				nargs = 1,
				complete = function()
					return { "auto", "full", "off" }
				end,
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
		keys = {
			{ "<F5>", function() require("dap").continue() end, desc = "Debug: continue" },
			{ "<F10>", function() require("dap").step_over() end, desc = "Debug: step over" },
			{ "<F11>", function() require("dap").step_into() end, desc = "Debug: step into" },
			{ "<F12>", function() require("dap").step_out() end, desc = "Debug: step out" },
			{ "<leader>b", function() require("dap").toggle_breakpoint() end, desc = "Debug: breakpoint" },
			{ "<leader>du", function() require("dapui").toggle() end, desc = "Debug: UI" },
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
				-- WellTemp tree: bin/WellTemp (wtt builds it Release + -ffast-math,
				-- so locals are often optimized out; use a Debug build for stepping)
				{
					name = "WellTemp",
					type = "codelldb",
					request = "launch",
					program = "${workspaceFolder}/bin/WellTemp",
					args = function()
						return vim.split(vim.fn.input("Args: ", "", "file"), " ", { trimempty = true })
					end,
					cwd = "${workspaceFolder}",
					stopOnEntry = false,
				},
			}
			dap.configurations.c = dap.configurations.cpp

			dap.adapters["pwa-node"] = {
				type = "server",
				host = "localhost",
				port = "${port}",
				executable = {
					command = "node",
					args = { mason_path .. "/packages/js-debug-adapter/js-debug/src/dapDebugServer.js", "${port}" },
				},
			}
			for _, language in ipairs({ "typescript", "javascript", "typescriptreact", "javascriptreact" }) do
				dap.configurations[language] = {
					{
						type = "pwa-node",
						request = "launch",
						name = "Launch Current File (ts-node)",
						runtimeExecutable = "ts-node",
						runtimeArgs = { "${file}" },
						rootPath = "${workspaceFolder}",
						cwd = "${workspaceFolder}",
						console = "integratedTerminal",
					},
					{
						type = "pwa-node",
						request = "attach",
						name = "Attach to Process",
						processId = require("dap.utils").pick_process,
						cwd = "${workspaceFolder}",
					},
				}
			end

			-- Godot / GDExtension configs (lua/gamedev.lua)
			require("gamedev").setup_dap(dap)
		end,
	},

	-- ─── Tests: neotest (ctest for C++ gtest/Catch2/doctest, pytest for sims) ─────

	{
		"nvim-neotest/neotest",
		dependencies = {
			"nvim-neotest/nvim-nio",
			"nvim-lua/plenary.nvim",
			"nvim-treesitter/nvim-treesitter",
			"orjangj/neotest-ctest",
			"nvim-neotest/neotest-python",
		},
		keys = function()
			local nt = function()
				return require("neotest")
			end
			return {
				{ "<leader>tn", function() nt().run.run() end, desc = "Test: nearest" },
				{ "<leader>tf", function() nt().run.run(vim.fn.expand("%")) end, desc = "Test: file" },
				{ "<leader>ta", function() nt().run.run(vim.fn.getcwd()) end, desc = "Test: all" },
				{ "<leader>tl", function() nt().run.run_last() end, desc = "Test: last" },
				{ "<leader>td", function() nt().run.run({ strategy = "dap" }) end, desc = "Test: debug nearest" },
				{ "<leader>tx", function() nt().run.stop() end, desc = "Test: stop" },
				{ "<leader>ts", function() nt().summary.toggle() end, desc = "Test: summary" },
				{ "<leader>to", function() nt().output.open({ enter = true, auto_close = true }) end, desc = "Test: output" },
				{ "<leader>tO", function() nt().output_panel.toggle() end, desc = "Test: output panel" },
				{ "<leader>tw", function() nt().watch.toggle(vim.fn.expand("%")) end, desc = "Test: watch file" },
				{ "[t", function() nt().jump.prev({ status = "failed" }) end, desc = "Prev failed test" },
				{ "]t", function() nt().jump.next({ status = "failed" }) end, desc = "Next failed test" },
			}
		end,
		config = function()
			local neotest = require("neotest")
			neotest.setup({
				adapters = {
					-- Discovers tests via ctest in the build dir (cmb configures build/).
					require("neotest-ctest").setup({}),
					require("neotest-python")({ runner = "pytest" }),
				},
				output = { open_on_run = false },
				quickfix = { open = false },
			})
		end,
	},

	-- ─── REPLs: iron.nvim (Python / Julia / R, for balance sims) ────────────────

	{
		"Vigemus/iron.nvim",
		ft = { "python", "julia", "r" },
		config = function()
			local iron = require("iron.core")
			local common = require("iron.fts.common")
			iron.setup({
				config = {
					scratch_repl = true,
					repl_definition = {
						python = {
							command = { "ipython", "--no-autoindent" },
							format = common.bracketed_paste_python,
							block_dividers = { "# %%", "#%%" },
						},
						-- @. = nearest Project.toml upwards
						julia = { command = { "julia", "--project=@." }, block_dividers = { "# %%", "##" } },
						r = { command = { "R", "--no-save", "--quiet" }, block_dividers = { "# %%", "#%%" } },
					},
					repl_open_cmd = require("iron.view").split.vertical.botright(0.4),
				},
				keymaps = {
					toggle_repl = "<leader>sr",
					restart_repl = "<leader>sR",
					send_motion = "<leader>sc",
					visual_send = "<leader>sc",
					send_line = "<leader>sl",
					send_file = "<leader>sf",
					send_until_cursor = "<leader>su",
					send_code_block = "<leader>sb",
					send_code_block_and_move = "<leader>sn",
					cr = "<leader>s<cr>",
					interrupt = "<leader>s<space>",
					exit = "<leader>sq",
					clear = "<leader>sx",
				},
				highlight = { italic = true },
				ignore_blank_lines = true,
			})
		end,
	},

	-- ─── Build runner ───────────────────────────────────────────────────────────

	{
		"stevearc/overseer.nvim",
		cmd = { "OverseerRun", "OverseerToggle", "OverseerOpen" },
		keys = {
			{ "<leader>or", "<cmd>OverseerRun<cr>", desc = "Overseer run task" },
			{ "<leader>ot", "<cmd>OverseerToggle<cr>", desc = "Overseer toggle panel" },
		},
		config = function()
			require("overseer").setup()
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
		cmd = { "CodeCompanion", "CodeCompanionChat", "CodeCompanionActions" },
		keys = {
			{ "<leader>ai", "<cmd>CodeCompanionChat Toggle<cr>", mode = { "n", "v" }, desc = "AI chat panel" },
			{ "<leader>aa", "<cmd>CodeCompanionActions<cr>", mode = { "n", "v" }, desc = "AI actions" },
			{ "<leader>ae", "<cmd>CodeCompanion /explain<cr>", mode = "v", desc = "AI explain selection" },
			{ "<leader>ar", "<cmd>CodeCompanion /review<cr>", mode = "v", desc = "AI review selection" },
			{ "<leader>af", "<cmd>CodeCompanion /fix<cr>", mode = "v", desc = "AI fix selection" },
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
		end,
	},

	-- ─── Quality of life ──────────────────────────────────────────────────────
	-- Comments: Neovim's built-in gc/gcc (>= 0.10) replaced Comment.nvim.
	{
		"windwp/nvim-autopairs",
		event = "InsertEnter",
		config = function()
			require("nvim-autopairs").setup()
		end,
	},

	{
		"lukas-reineke/indent-blankline.nvim",
		main = "ibl",
		event = { "BufReadPost", "BufNewFile" },
		config = function()
			require("ibl").setup()
		end,
	},
}
