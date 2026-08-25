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


local telescope = require('telescope.builtin')

local function set_keymap(modes, expected_mode, trigger, command, description)
  -- Setup flags
  local flags = {
    desc = description,
    noremap = true,
    silent = true
  }

  -- Exit early if the command isn't a string
  if (type(command) ~= "string") then
    vim.keymap.set(modes, trigger, command, flags)
    return
  end

  -- Convert single mode to a list
  if (type(modes) == "string") then
    modes = {modes}
  end

  -- Assign each mode
  for _, mode in ipairs(modes) do
    local mode_pair = string.format("%s%s", mode, expected_mode)
    local custom_command = command
    -- Modify command for special cases
    if (mode == expected_mode or expected_mode == "") then
      -- Nothing to do

    -- Change command based on the current vs expected mode
    elseif (mode_pair == "in") then
      custom_command = string.format("<C-o>%s", command)
    else
      error(string.format("Unrecognized mode pair: %s->%s", mode, expected_mode))
    end

    -- Set
    vim.keymap.set(mode, trigger, custom_command, flags)
  end
end


local i = "i"
local n = "n"
local v = "v"
local in_ = {"i", "n"}
--local iv = {"i", "v"}
--local nv = {"n", "v"}
local inv = {"i", "n", "v"}

-- Leader + ...
set_keymap(n, "", "<Leader>w", "<cmd>w<cr>", "save file")
set_keymap(n, "", "<Leader>w", "<cmd>w<cr>", "save file")
set_keymap(n, "", "<Leader>s", "<cmd>w<cr>", "save file")

-- Ctrl-J + ...
-- f (find)
set_keymap(inv, "", "<C-j>fb", telescope.buffers, "search buffers")
set_keymap(inv, "", "<C-j>fc", telescope.command_history, "search commands")
set_keymap(inv, "", "<C-j>ff", telescope.grep_string, "search")
set_keymap(inv, "", "<C-j>fg", telescope.live_grep, "search with regex")
set_keymap(inv, "", "<C-j>fk", telescope.keymaps, "search key mappings")
set_keymap(inv, "", "<C-j>fm", telescope.man_pages, "search man pages")

-- h (help)
set_keymap(inv, "", "<C-j>h", telescope.help_tags, "help")

-- o (open file)
set_keymap(inv, "", "<C-j>oo", telescope.find_files, "open in current window")
set_keymap(inv, "", "<C-j>oc", telescope.find_files, "open in current window")
set_keymap(inv, "", "<C-j>oh", "<cmd>vs<cr><cmd>wincmd l<cr><cmd>Telescope find_files<cr>", "open in new window (right)")
set_keymap(inv, "", "<C-j>ov", "<cmd>sp<cr><cmd>wincmd j<cr><cmd>Telescope find_files<cr>", "open in new window (up)")
set_keymap(inv, "", "<C-j>ot", "<cmd>tab new<cr><cmd>Telescope find_files<cr>", "open in new tab")

-- s (spellcheck)
set_keymap(inv, "", "<C-j>s", telescope.spell_suggest, "spellcheck on current word")

-- Ctrl + ... (delete)
-- Note: for some reason Ctrl+BS is <BS>, not <C-BS>...
-- single word
set_keymap(in_, n, "<BS>", "db", "delete word before cursor")
set_keymap(in_, n, "<C-Del>", "de", "delete word after cursor")
-- line
set_keymap(in_, n, "<C-S-BS>", "d^", "delete line before cursor")
set_keymap(in_, n, "<C-S-Del>", "_d$", "delete line after cursor")
-- Copy-paste
set_keymap(v, "", "<C-c>", "y", "copy")
set_keymap(v, "", "<C-c>", "y", "copy")
set_keymap(i, "", "<C-v>", "p", "paste")
set_keymap(v, "", "<C-v>", "p", "paste")


-- Ctrl + ... (file management)
set_keymap(inv, "", "<C-s>", "<cmd>w<cr>", "save")
set_keymap(inv, "", "<C-S-s>", "<cmd>w<cr>", "save all")
set_keymap(inv, "", "<C-q>", "<cmd>q<cr>", "quit")
set_keymap(inv, "", "<C-S-q>", "<cmd>qa<cr>", "quit all")


-- Other

-- Disable mouse popup in menu
vim.cmd('aunmenu PopUp.How-to\\ disable\\ mouse')
vim.cmd('aunmenu PopUp.-2-')
