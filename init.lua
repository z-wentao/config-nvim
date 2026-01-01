require("config.lazy")

vim.opt.shiftwidth = 4
vim.opt.clipboard = "unnamedplus"
vim.opt.scrolloff = 8


vim.cmd [[hi @function.builtin guifg=yellow]]

vim.keymap.set("n", "<space><space>x", "<cmd>source %<CR>")
vim.keymap.set("n", "<space>x", ":.lua<CR>")
vim.keymap.set("v", "<space>x", ":lua<CR>")
vim.keymap.set("n", "<space>pv", ":Vex<CR>")
vim.keymap.set("n", "<space><space>k", "I~~<Esc>A~~<Esc>")
vim.keymap.set("n", "Y", "mmggyG`m")
-- 缩进与选中优化
vim.keymap.set("v", ">", ">gv")
vim.keymap.set("v", "<", "<gv")
vim.keymap.set("n", ">", "V>")
vim.keymap.set("n", "<", "V<")

-- insert arrow
vim.keymap.set("i", "vj", "<Esc>o<space><space><space><C-k>-v<Esc>o<BS>")
vim.keymap.set("i", "vk", "<Esc>o<space><space><space><C-k>!-<Esc>o<BS>")
vim.keymap.set("i", "vl", "<C-k>-><space>")
vim.keymap.set("i", "vh", "<C-k><-")

vim.keymap.set("i", "vo", "<C-k>OK")  -- ✓ 勾选
vim.keymap.set("i", "vx", "<C-k>XX")  -- ✗ 叉号
vim.keymap.set("i", "v.", "<C-k>.M")  -- · 中点
vim.keymap.set("i", "vc", "```<Esc>O```<Esc>o")
-- 用 v* 创建标记并在底部生成对应内容
vim.keymap.set("i", "v*", "<C-k>2*<space>")
vim.keymap.set("i", "vv", "<Esc>hea<Esc>byiwi★<Esc>emmGo<CR>★ <Esc>p<Esc>`ma")
vim.keymap.set("v", "vv", "<Esc>hea<Esc>byiwi★<Esc>emmGo<CR>★ <Esc>p<Esc>`m")
-- add ** quickly
vim.keymap.set("v", "bb", "c**<C-r>\"**<Esc>")

-- [[wiki link]] 跳转功能
vim.keymap.set('n', '<CR>', function()
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2] + 1
  -- 匹配 [[...]] 模式
  for link in line:gmatch('%[%[(.-)%]%]') do
    local escaped = link:gsub('([%%%]%[])','%%%1')
    local start_pos, end_pos = line:find('%[%[' .. escaped .. '%]%]')
    if start_pos and col >= start_pos and col <= end_pos then
      -- 获取当前文件所在目录
      local current_dir = vim.fn.expand('%:p:h')
      local filepath = current_dir .. '/' .. link .. '.txt'
      if vim.fn.filereadable(filepath) == 1 then
        -- 文件存在，直接打开
        vim.cmd('edit ' .. vim.fn.fnameescape(filepath))
      else
        local choice = vim.fn.confirm(link .. '.txt 不存在，创建?', '&Yes\n&No', 2)
        if choice == 1 then
          vim.cmd('edit ' .. vim.fn.fnameescape(filepath))
          vim.cmd('write')
        end
      end
      return
    end
  end
end)

-- 离开插入模式时自动保存
vim.api.nvim_create_autocmd('InsertLeave', {
  pattern = '*.txt',
  callback = function()
    vim.cmd('silent! write')
  end
})

-- Move lines up and down in visual mode (ThePrimeagen style)
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")



vim.api.nvim_create_autocmd('TextYankPost', {
	desc = 'Highlight when yanking (copying) text',
	group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
	callback = function()
		vim.highlight.on_yank()
	end,
})

-- EPUB 阅读器配置
require('config.epub-reader')

-- 快速记事本配置
require('config.quick-notes').setup({
	notes_file = vim.fn.expand("~/Documents/quick-notes.md"), -- 你可以修改路径
	window = {
		width = 0.8,   -- 80% 屏幕宽度
		height = 0.8,  -- 80% 屏幕高度
		border = "rounded", -- 边框样式
	}
})

require('config.veg').setup()

-- 帕金森定律任务计时器
require('config.parkinson-timer').setup()

-- Things快速添加
require('config.things-quick-add').setup()
