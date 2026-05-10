-- Disable default file browser in favor of nvim-tree
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- Packages
vim.pack.add({
  -- Language server protocol (LSP) configs for many languages
  { src = 'https://github.com/neovim/nvim-lspconfig' },
  -- Icons for file tree
  { src = 'https://github.com/nvim-tree/nvim-web-devicons' },
  -- File tree
  { src = 'https://github.com/nvim-tree/nvim-tree.lua' },
})

-- Setup nvim-tree
require("nvim-tree").setup()

vim.o.number = true -- Show line numbers
vim.o.shiftwidth = 2 -- Use 2 spaces for tabs before first non-space char
vim.o.tabstop = 2 -- Use 2 spaces for tabs after first non-space char
vim.o.smartindent = true -- Auto indent lines
vim.o.cursorline = true -- Highlight the current line
vim.o.expandtab = true -- Use spaces instead of tabs
vim.o.termguicolors = true -- Enable 24-bit colors

-- Autocomplete
vim.opt.completeopt = {
  "menuone", -- Show autocomplete menu, even if there's only 1 option
  "noselect", -- Don't select an item by default
  "popup", -- Show extra info about completion options
}

-- LSP

-- Good list of LSPs here: https://wiki.archlinux.org/title/Language_Server_Protocol
-- Available configs here: https://github.com/neovim/nvim-lspconfig/tree/master/lsp

-- List of LSPs to enable
lsps = {"bashls", "pyright"}

-- For each LSP config, enable autocomplete in it
for i, lsp in ipairs(lsps) do
  vim.lsp.config(lsp, {
    on_attach = function(client, bufnr)
      vim.lsp.completion.enable(true, client.id, bufnr, {
        autotrigger = true,
        convert = function(item)
          return { abbr = item.label:gsub("%b()", "") }
        end,
      })
      vim.keymap.set("i", "<C-space>", vim.lsp.completion.get, { desc = "trigger autocompletion" })
    end
  })
  vim.lsp.enable(lsp)
end

