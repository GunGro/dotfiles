-- Game dev: Godot 4 (GDScript LSP/DAP, external-editor server) + GDExtension debugging.
-- Required from init.lua after lazy.setup().

local M = {}

-- ─── Helpers ─────────────────────────────────────────────────────────────────

local godot_bin = os.getenv("GODOT") or "godot"

-- Godot project dir: ancestor of the current buffer/cwd with project.godot,
-- else the shallowest project.godot below cwd (repo/game/project.godot).
function M.project_root()
	local root = vim.fs.root(0, "project.godot") or vim.fs.root(vim.fn.getcwd(), "project.godot")
	if root then
		return root
	end
	local found = vim.fs.find("project.godot", {
		path = vim.fn.getcwd(),
		type = "file",
		limit = 1,
		skip = function(name)
			return name ~= ".godot" and name ~= "addons" and name ~= ".git" and not name:match("^build")
		end,
	})
	return found[1] and vim.fs.dirname(found[1]) or nil
end

local function run_in_term(cmd)
	vim.cmd("botright 15split")
	vim.cmd.terminal(cmd)
	vim.cmd("startinsert")
end

local function godot(args)
	local root = M.project_root()
	if not root then
		vim.notify("No project.godot found", vim.log.levels.WARN)
		return
	end
	run_in_term(string.format("%s --path %s %s", godot_bin, vim.fn.shellescape(root), args or ""))
end

-- ─── Filetypes ───────────────────────────────────────────────────────────────

vim.filetype.add({
	extension = {
		gd = "gdscript",
		gdshader = "gdshader",
		gdshaderinc = "gdshader",
		tscn = "gdresource",
		tres = "gdresource",
	},
	filename = { ["project.godot"] = "gdresource" },
})

-- Godot style guide: tabs, width 4.
vim.api.nvim_create_autocmd("FileType", {
	pattern = { "gdscript", "gdshader" },
	callback = function()
		vim.bo.expandtab = false
		vim.bo.tabstop = 4
		vim.bo.shiftwidth = 4
		vim.bo.softtabstop = 0
	end,
})

-- ─── GDScript LSP (served by the running Godot editor over TCP) ─────────────
-- Editor Settings → Network → Language Server (default port 6005).

local capabilities = vim.lsp.protocol.make_client_capabilities()
if pcall(require, "cmp_nvim_lsp") then
	capabilities = vim.tbl_deep_extend("force", capabilities, require("cmp_nvim_lsp").default_capabilities())
end

vim.lsp.config("gdscript", {
	capabilities = capabilities,
	cmd = vim.lsp.rpc.connect("127.0.0.1", tonumber(os.getenv("GDScript_Port") or "6005")),
	filetypes = { "gdscript" },
	root_markers = { "project.godot" },
})
vim.lsp.enable("gdscript")

-- ─── clangd extras (GDExtension) ─────────────────────────────────────────────

vim.api.nvim_create_autocmd("LspAttach", {
	callback = function(args)
		local client = vim.lsp.get_client_by_id(args.data.client_id)
		if not client then
			return
		end
		local o = { buffer = args.buf, silent = true }
		if client.name == "clangd" then
			vim.keymap.set("n", "<leader>ch", "<cmd>LspClangdSwitchSourceHeader<cr>",
				vim.tbl_extend("force", o, { desc = "Switch source/header" }))
		end
		if client:supports_method("textDocument/inlayHint") then
			vim.keymap.set("n", "<leader>ih", function()
				vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = args.buf }), { bufnr = args.buf })
			end, vim.tbl_extend("force", o, { desc = "Toggle inlay hints" }))
		end
	end,
})

-- ─── External editor server ──────────────────────────────────────────────────
-- When nvim starts inside a Godot project, listen on a fixed socket so the
-- `godot-nvim` wrapper (Godot: Editor Settings → Text Editor → External) can
-- open files here instead of spawning a new editor.

M.socket = (os.getenv("XDG_RUNTIME_DIR") or "/tmp") .. "/godot-nvim.sock"

if M.project_root() then
	if vim.uv.fs_stat(M.socket) then
		-- Owned by a live nvim? Leave it. Stale (crash leftover)? Remove it.
		local ok, chan = pcall(vim.fn.sockconnect, "pipe", M.socket)
		if ok and chan > 0 then
			vim.fn.chanclose(chan)
		else
			os.remove(M.socket)
		end
	end
	if not vim.uv.fs_stat(M.socket) then
		pcall(vim.fn.serverstart, M.socket)
	end
end

-- ─── Debugging ───────────────────────────────────────────────────────────────

local ok_dap, dap = pcall(require, "dap")
if ok_dap then
	-- GDScript: Godot editor's debug adapter (Editor Settings → Network → Debug Adapter, port 6006).
	dap.adapters.godot = {
		type = "server",
		host = "127.0.0.1",
		port = tonumber(os.getenv("GODOT_DAP_PORT") or "6006"),
	}
	dap.configurations.gdscript = {
		{ type = "godot", request = "launch", name = "Godot: main scene", project = "${workspaceFolder}", scene = "main" },
		{ type = "godot", request = "launch", name = "Godot: current scene", project = "${workspaceFolder}", scene = "current" },
	}

	-- C++ GDExtension: launch/attach Godot itself under codelldb.
	local function godot_launch(name, extra)
		return {
			name = name,
			type = "codelldb",
			request = "launch",
			program = function()
				return vim.fn.exepath(godot_bin) ~= "" and vim.fn.exepath(godot_bin) or godot_bin
			end,
			args = function()
				local a = { "--path", M.project_root() or vim.fn.getcwd() }
				return vim.list_extend(a, extra or {})
			end,
			cwd = function()
				return M.project_root() or vim.fn.getcwd()
			end,
			stopOnEntry = false,
		}
	end

	dap.configurations.cpp = dap.configurations.cpp or {}
	vim.list_extend(dap.configurations.cpp, {
		godot_launch("Godot: run game (GDExtension)"),
		godot_launch("Godot: editor (GDExtension)", { "-e" }),
		godot_launch("Godot: headless (GDExtension)", { "--headless" }),
		{
			name = "Attach to Godot",
			type = "codelldb",
			request = "attach",
			pid = function()
				return require("dap.utils").pick_process({ filter = "godot" })
			end,
		},
		{
			name = "Launch test binary",
			type = "codelldb",
			request = "launch",
			program = function()
				return vim.fn.input("Test binary: ", vim.fn.getcwd() .. "/build/", "file")
			end,
			cwd = "${workspaceFolder}",
		},
	})
	dap.configurations.c = dap.configurations.cpp

	vim.keymap.set("n", "<leader>B", function()
		dap.set_breakpoint(vim.fn.input("Condition: "))
	end, { desc = "Conditional breakpoint" })
	-- <leader>D… (not <leader>d…, which would collide with the diagnostic float)
	vim.keymap.set("n", "<leader>Dl", dap.run_last, { desc = "DAP run last" })
	vim.keymap.set("n", "<leader>Dr", dap.repl.toggle, { desc = "DAP REPL" })
	vim.keymap.set("n", "<leader>Dt", dap.terminate, { desc = "DAP terminate" })
end

-- ─── Run keymaps ─────────────────────────────────────────────────────────────

vim.keymap.set("n", "<leader>Gr", function() godot("") end, { desc = "Godot: run game" })
vim.keymap.set("n", "<leader>Ge", function() godot("-e") end, { desc = "Godot: editor" })
vim.keymap.set("n", "<leader>Gs", function()
	local root, file = M.project_root(), vim.fn.expand("%:p")
	if root and file:sub(1, #root + 1) == root .. "/" then
		godot(vim.fn.shellescape("res://" .. file:sub(#root + 2)))
	else
		vim.notify("Current file is not inside the Godot project", vim.log.levels.WARN)
	end
end, { desc = "Godot: run current scene" })
vim.keymap.set("n", "<leader>Gt", function() run_in_term(vim.o.shell .. " -ic gdtest") end,
	{ desc = "Godot: run tests" })
vim.keymap.set("n", "<leader>Gb", function() run_in_term(vim.o.shell .. " -ic cmb") end,
	{ desc = "CMake: build GDExtension" })

return M
