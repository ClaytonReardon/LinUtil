vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Show [F]ile [T]ree
vim.keymap.set("n", "<leader>ft", vim.cmd.Ex, { desc = 'Show [F]ile [T]ree' })

-- Keep cursor middle screen while moving with Ctrl+u/d
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")

-- Keep search term middle screen while searching
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

-- Paste over word without loosing the initial copy
vim.keymap.set("x", "<leader>p", "\"dP", { desc = 'Paste over word w/o loosing cop' })

-- Delete without putting in clipboard
vim.keymap.set("n", "<leader>d", "\"_d", { desc = 'Delete w/o adding to clipboard' })
vim.keymap.set("v", "<leader>d", "\"_d", { desc = 'Delete w/o adding to clipboard' })

-- Copy into system clipboard
vim.keymap.set("n", "<leader>y", "\"+y", { desc = 'Copy into system clipboard' })
vim.keymap.set("v", "<leader>y", "\"+y", { desc = 'Copy into system clipboard' })
vim.keymap.set("n", "<leader>Y", "\"+Y", { desc = 'Copy line into system clipboard' })

-- Replace all instances of current word
vim.keymap.set("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]], { desc = 'Replace all instances of current word' })

-- Make current file executable
vim.keymap.set("n", "<leader>x", "<cmd>!chmod +x %<CR>", { silent = true, desc = 'Make current file executable' })
