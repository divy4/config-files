-- ########## Helper functions ##########

local function is_file(path)
   local f = io.open(path, "r")
   return f ~= nil and io.close(f)
end

local function is_directory(path)
  return vim.fn.isdirectory(path) ~= 0
end


-- ########## Directory ##########

-- nvim      --> argv_path = "",              argv_dir = "/path/to/dir"
-- nvim dir/ --> argv_path = "/path/to/dir/", argv_dir = "/path/to/dir"
-- nvim file --> argv_path = "/path/to/file", argv_dir = "/path/to"

local argv_path = vim.fn.expand('%:p') -- path passed to nvim
local argv_dir = vim.fn.expand('%:p:h') -- directory containing path passed to nvim
if argv_path == "" or is_directory(argv_path) then
  argv_path = argv_dir
end

-- nvim      --> argv_path = "/path/to/dir",  argv_dir = "/path/to/dir"
-- nvim dir/ --> argv_path = "/path/to/dir",  argv_dir = "/path/to/dir"
-- nvim file --> argv_path = "/path/to/file", argv_dir = "/path/to"

vim.cmd("silent! cd " .. vim.fn.fnameescape(argv_dir))


-- ########## Plugins ##########

-- Packages
vim.pack.add({
  -- AI autocomplete
  { src = 'https://github.com/huggingface/llm.nvim' },
  -- Language server protocol (LSP) configs for many languages
  { src = 'https://github.com/neovim/nvim-lspconfig' },
  -- Icons for file tree
  { src = 'https://github.com/nvim-tree/nvim-web-devicons' },
  -- Fuzzy finder / file opening
  { src = 'https://github.com/nvim-telescope/telescope.nvim' },
  -- Library of helper functions
  { src = 'https://github.com/nvim-lua/plenary.nvim' },
  -- Fuzzy finder
  { src = 'https://github.com/nvim-telescope/telescope-fzf-native.nvim' },
  -- File finder
  { src = 'https://github.com/sharkdp/fd' },
  -- Recursive grep
  { src = 'https://github.com/BurntSushi/ripgrep' },
  -- Color scheme
  { src = 'https://github.com/srcery-colors/srcery-vim' },
})


-- AI autocomplete
local llm = require('llm')

llm.setup({
  backend = "ollama",
  model = "qwen2.5-coder:7b",
  url = "http://localhost:11434",
  accept_keymap = "<C-Tab>",
  dismiss_keymap = "<S-Tab>",
  enable_suggestions_on_startup = false,
})


-- Autocomplete
vim.opt.completeopt = {
  "menuone", -- Show autocomplete menu, even if there's only 1 option
  "noselect", -- Don't select an item by default
  "popup", -- Show extra info about completion options
}


-- Diagnostics
vim.diagnostic.config({
  virtual_text = true,       -- Enable inline messages
  signs = false,             -- Enable gutter signs
  underline = true,          -- Enable underlines for errors
  update_in_insert = false,  -- Disable updates while typing
  severity_sort = true,      -- Sort diagnostics by severity
})


-- LSP

-- Good list of LSPs here: https://wiki.archlinux.org/title/Language_Server_Protocol
-- Available configs here: https://github.com/neovim/nvim-lspconfig/tree/master/lsp

-- List of LSPs to enable
local lsps = {
  "bashls",
  "deno", -- JavaScript and TypeScript
  "dockerls",
  "gopls",
  "lua_ls",
  "pyright",
  "rumdl", -- Markdown
  "systemd_lsp",
  "terraformls",
}

vim.lsp.config("lua_ls", {
  settings = {
    Lua = {
      diagnostics = {
        globals = {
          "vim"
        }
      }
    }
  }
})


-- For each LSP config, enable autocomplete in it
for _, lsp in ipairs(lsps) do
  vim.lsp.config(lsp, {
    on_attach = function(client, bufnr)
      -- Any printable char triggers autocomplete
      local chars = {}
      for i = 32, 126 do
        table.insert(chars, string.char(i))
      end
      client.server_capabilities.completionProvider.triggerCharacters = chars

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

-- Note: check lsp health with :checkhealth vim.lsp


-- Tree browser

require('telescope').setup{
  defaults = {
    layout_strategy = 'flex',
    layout_config = {
      flip_columns = 200,
      vertical = {
        preview_height = 0.2
      },
    }
  }
}


-- ########## Native settings ##########


-- General settings

-- Markers
vim.o.number = true -- Show line numbers
vim.wo.relativenumber = true -- Show relative line numbers
vim.o.cursorline = true -- Highlight the current line
vim.opt.colorcolumn = "80,100,200,300,400,500,600,700,800,900,1000"
-- Indenting
vim.o.shiftwidth = 2 -- Use 2 spaces for tabs before first non-space char
vim.o.tabstop = 2 -- Use 2 spaces for tabs after first non-space char
vim.o.smartindent = true -- Auto indent lines
vim.o.expandtab = true -- Use spaces instead of tabs
-- Color scheme
vim.g.srcery_bold = 0 -- Don't use bold
vim.g.srcery_italic = 0 -- Don't use italic
vim.cmd.colorscheme('srcery')
-- Other
vim.o.termguicolors = true -- Enable 24-bit colors
vim.g.mapleader = "," -- Set leader key to comma


-- Sessions

local function get_session_file()
  return vim.fn.getcwd() .. "/.nvim-session"
end

-- If we opened a directory, register autocmds to load/save the session
if argv_path == argv_dir then
  -- Load session during loading
  vim.api.nvim_create_autocmd({ "VimEnter" }, {
    pattern = "*",
    callback = function()
      -- Do nothing if we don't have a session file
      if not is_file(get_session_file()) then return end

      -- vim.schedule... because vim hasn't loaded everything just yet.
      vim.schedule(function()
        vim.cmd("silent! source " .. get_session_file())
      end)
    end,
  })

  -- Save session right before closing
  vim.api.nvim_create_autocmd({ "VimLeavePre" }, {
    pattern = "*",
    callback = function()
      vim.cmd("silent! mksession! " .. get_session_file())
    end,
  })
end


-- Mappings

local all_modes = {'n', 'i', 'v'}
local telescope = require('telescope.builtin')

local function keymap_flags(description)
  return {
    desc = description,
    noremap = true,
    silent = true
  }
end

-- Leader + ...
vim.keymap.set('n', "<Leader>w", "<cmd>w<cr>", keymap_flags("save file"))
vim.keymap.set('n', "<Leader>s", "<cmd>w<cr>", keymap_flags("save file"))

-- Ctrl-J + ...
-- f (find)
vim.keymap.set(all_modes, "<C-j>fb", telescope.buffers, keymap_flags("search buffers"))
vim.keymap.set(all_modes, "<C-j>fc", telescope.command_history, keymap_flags("search commands"))
vim.keymap.set(all_modes, "<C-j>ff", telescope.grep_string, keymap_flags("search"))
vim.keymap.set(all_modes, "<C-j>fg", telescope.live_grep, keymap_flags("search with regex"))
vim.keymap.set(all_modes, "<C-j>fk", telescope.keymaps, keymap_flags("search key mappings"))
vim.keymap.set(all_modes, "<C-j>fm", telescope.man_pages, keymap_flags("search man pages"))

-- h (help)
vim.keymap.set(all_modes, "<C-j>h", telescope.help_tags, keymap_flags("help"))

-- o (open file)
vim.keymap.set(all_modes, "<C-j>oo", telescope.find_files, keymap_flags("open in current window"))
vim.keymap.set(all_modes, "<C-j>oc", telescope.find_files, keymap_flags("open in current window"))
vim.keymap.set(all_modes, "<C-j>oh", "<cmd>vs<cr><cmd>wincmd l<cr><cmd>Telescope find_files<cr>", keymap_flags("open in new window (right)"))
vim.keymap.set(all_modes, "<C-j>ov", "<cmd>sp<cr><cmd>wincmd j<cr><cmd>Telescope find_files<cr>", keymap_flags("open in new window (up)"))
vim.keymap.set(all_modes, "<C-j>ot", "<cmd>tab new<cr><cmd>Telescope find_files<cr>", keymap_flags("open in new tab"))

-- s (spellcheck)
vim.keymap.set(all_modes, "<C-j>s", telescope.spell_suggest, keymap_flags("spellcheck on current word"))

-- Ctrl + ...
vim.keymap.set(all_modes, "<C-s>", "<cmd>w<cr>", keymap_flags("save"))
vim.keymap.set(all_modes, "<C-S-s>", "<cmd>w<cr>", keymap_flags("save all"))
vim.keymap.set(all_modes, "<C-q>", "<cmd>q<cr>", keymap_flags("quit"))
vim.keymap.set(all_modes, "<C-S-q>", "<cmd>qa<cr>", keymap_flags("quit all"))


-- Other

-- Disable mouse popup in menu
vim.cmd('aunmenu PopUp.How-to\\ disable\\ mouse')
vim.cmd('aunmenu PopUp.-2-')
