return{
  'nvim-tree/nvim-tree.lua',
  'nvim-tree/nvim-web-devicons',
  config = function ()
  	require("nvim-tree").setup({
	  view = { relativenumber = true }
	})
  end
}
