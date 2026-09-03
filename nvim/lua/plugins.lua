return {

  -- ─── Colorscheme: Solarized ───────────────────────────────────────────────
  {
    "ishan9299/nvim-solarized-lua",
    lazy = false,
    priority = 1000,
    config = function()
      vim.o.background = "dark"
      vim.cmd("colorscheme solarized")
    end,
  },

  -- ─── Statusline: Lightline ────────────────────────────────────────────────
  {
    "itchyny/lightline.vim",
    lazy = false,
    config = function()
      vim.g.lightline = {
        colorscheme = "solarized",
        active = {
          left  = { { "mode", "paste" }, { "gitbranch", "readonly", "filename", "modified" } },
          right = { { "lineinfo" }, { "percent" }, { "fileformat", "fileencoding", "filetype" } },
        },
        component_function = {
          gitbranch = "FugitiveHead",
        },
      }
    end,
  },

  -- ─── Git ──────────────────────────────────────────────────────────────────
  { "tpope/vim-fugitive", lazy = false },

  {
    "lewis6991/gitsigns.nvim",
    config = function()
      require("gitsigns").setup({
        signs = {
          add          = { text = "▎" },
          change       = { text = "▎" },
          delete       = { text = "▁" },
          topdelete    = { text = "▔" },
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
    build = ":TSUpdate",
    main = "nvim-treesitter",
    opts = {
      ensure_installed = { "c", "cpp", "lua", "python", "bash", "cmake" },
      highlight = { enable = true },
      indent    = { enable = true },
    },
  }, 
  -- ─── LSP ──────────────────────────────────────────────────────────────────
   {
    "williamboman/mason.nvim",
    config = function()
      require("mason").setup()
    end,
  },

  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "williamboman/mason.nvim" },
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = { "clangd", "pyright" },
      })
    end,
  },

  {
    "neovim/nvim-lspconfig",
    dependencies = { "williamboman/mason-lspconfig.nvim" },
    config = function()
      local on_attach = function(_, bufnr)
        local bmap = function(mode, lhs, rhs)
          vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, noremap = true, silent = true })
        end
        bmap("n", "gd",         vim.lsp.buf.definition)
        bmap("n", "gD",         vim.lsp.buf.declaration)
        bmap("n", "gr",         vim.lsp.buf.references)
        bmap("n", "gi",         vim.lsp.buf.implementation)
        bmap("n", "K",          vim.lsp.buf.hover)
        bmap("n", "<leader>rn", vim.lsp.buf.rename)
        bmap("n", "<leader>ca", vim.lsp.buf.code_action)
        bmap("n", "<leader>f",  function() vim.lsp.buf.format({ async = true }) end)
      end

      -- clangd
      vim.lsp.config("clangd", {
        cmd = {
          "clangd",
          "--background-index",
          "--clang-tidy",
          "--header-insertion=iwyu",
          "--completion-style=detailed",
          "--function-arg-placeholders",
        },
        filetypes = { "c", "cpp", "objc", "objcpp" },
        on_attach = on_attach,
      })
      vim.lsp.enable("clangd")

      -- pyright
      vim.lsp.config("pyright", {
        on_attach = on_attach,
      })
      vim.lsp.enable("pyright")
    end,
  },
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
      local cmp     = require("cmp")
      local luasnip = require("luasnip")

      cmp.setup({
        snippet = {
          expand = function(args) luasnip.lsp_expand(args.body) end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-b>"]     = cmp.mapping.scroll_docs(-4),
          ["<C-f>"]     = cmp.mapping.scroll_docs(4),
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<C-e>"]     = cmp.mapping.abort(),
          ["<CR>"]      = cmp.mapping.confirm({ select = true }),
          ["<Tab>"]     = cmp.mapping(function(fallback)
            if cmp.visible() then cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then luasnip.expand_or_jump()
            else fallback() end
          end, { "i", "s" }),
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "luasnip" },
          { name = "buffer" },
          { name = "path" },
        }),
      })
    end,
  },

  -- ─── Formatting ───────────────────────────────────────────────────────────
  {
    "stevearc/conform.nvim",
    config = function()
      require("conform").setup({
        formatters_by_ft = {
          cpp = { "clang_format" },
          c   = { "clang_format" },
          lua = { "stylua" },
        },
        format_on_save = {
          timeout_ms = 500,
          lsp_fallback = true,
        },
      })
    end,
  },

  -- ─── Quality of life ──────────────────────────────────────────────────────
  {
    "numToStr/Comment.nvim",
    config = function() require("Comment").setup() end,
  },

  {
    "windwp/nvim-autopairs",
    config = function() require("nvim-autopairs").setup() end,
  },

  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    config = function() require("ibl").setup() end,
  },

}
