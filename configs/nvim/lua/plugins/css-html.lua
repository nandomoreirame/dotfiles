-- LazyVim has no css or html extra: add the Treesitter css parser and the two
-- language servers (Mason: css-lsp -> cssls, html-lsp -> html).
return {
  { "nvim-treesitter/nvim-treesitter", opts = { ensure_installed = { "css" } } },
  { "mason-org/mason.nvim", opts = { ensure_installed = { "css-lsp", "html-lsp" } } },
  { "neovim/nvim-lspconfig", opts = { servers = { cssls = {}, html = {} } } },
}
