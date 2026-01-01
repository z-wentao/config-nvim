vim.keymap.set("n", "J", ":m .+1<CR>==")
vim.keymap.set("n", "K", ":m .-2<CR>==")

-- vt: 插入当前时间
vim.keymap.set("i", "vt", function()
  vim.api.nvim_put({os.date("%H:%M")}, 'c', true, true)
end, { desc = "Insert current time" })

-- vn: 开始任务计时器
vim.keymap.set("i", "vn", function()
  local parkinson = require('config.parkinson-timer')

  -- 检查是否有活动的计时器
  if parkinson.has_active_timer() then
    -- 有计时器，显示状态
    parkinson.show_status()
  else
    -- 智能启动：解析当前行或交互式输入
    parkinson.smart_start()
  end
end, { desc = "Start task timer" })
