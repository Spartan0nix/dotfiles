require'nvim-treesitter.configs'.setup {
    -- List of parsers to install
    ensure_installed = { 
        "bash",
        "c", 
        "lua", 
        "go",
        "hcl"
    },
    highlight = {
      enable = true,
    },
    indent = {
        enable = true,
    },
    incremental_selection = {
      enable = true,
        keymaps = {
          init_selection = "gnn",
          node_incremental = "grn",
          scope_incremental = "grc",
          node_decremental = "grm",
        },
    },
  }