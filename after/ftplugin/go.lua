local set = vim.opt_local

set.shiftwidth = 4
set.number = true
set.relativenumber = true

-- 在右侧终端运行 Go 文件,焦点保持在当前窗口
vim.keymap.set("n", "<leader>r", function()
  local file = vim.fn.expand("%")
  vim.cmd("vsplit")
  vim.cmd("wincmd l")  -- 移动到右侧窗口
  vim.cmd("terminal go run " .. file)
  vim.cmd("wincmd h")  -- 移回左侧窗口
end, { desc = "Run Go file in right terminal" })
