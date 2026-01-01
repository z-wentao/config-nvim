local M = {}

-- 当前活动的计时器
local active_timer = nil
local timer_state = {
  task_name = nil,
  total_seconds = 0,
  remaining_seconds = 0,
  start_time = nil,
  paused = false,
}

-- 格式化时间显示
local function format_time(seconds)
  local hours = math.floor(seconds / 3600)
  local mins = math.floor((seconds % 3600) / 60)
  local secs = seconds % 60

  if hours > 0 then
    return string.format("%02d:%02d:%02d", hours, mins, secs)
  else
    return string.format("%02d:%02d", mins, secs)
  end
end

-- 更新sketchybar（异步，避免光标闪烁）
local function update_sketchybar()
  if not active_timer then
    -- 隐藏sketchybar项目
    vim.fn.jobstart('sketchybar --set parkinson.timer drawing=off', { detach = true })
    return
  end

  local time_display = format_time(timer_state.remaining_seconds)
  local icon = timer_state.paused and "⏸" or "⏱"
  local label = string.format("%s %s • %s", icon, timer_state.task_name, time_display)

  -- 更新sketchybar（异步）
  vim.fn.jobstart(string.format(
    'sketchybar --set parkinson.timer label="%s" drawing=on',
    label:gsub('"', '\\"')
  ), { detach = true })
end

-- 显示完成通知
local function show_completion_notification(task_name, total_seconds)
  -- 创建一个大的浮动窗口显示完成信息
  local buf = vim.api.nvim_create_buf(false, true)

  local width = 60
  local height = 10

  local messages = {
    "",
    "        ✨ TASK COMPLETED! ✨",
    "",
    "  Task: " .. task_name,
    "  Duration: " .. format_time(total_seconds),
    "",
    "  Parkinson's Law: Work expands to fill",
    "  the time available. You did it! 🎉",
    "",
    "  Press any key to close",
  }

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, messages)

  local opts = {
    relative = "editor",
    width = width,
    height = height,
    row = (vim.o.lines - height) / 2,
    col = (vim.o.columns - width) / 2,
    style = "minimal",
  }

  local win = vim.api.nvim_open_win(buf, true, opts)
  vim.api.nvim_win_set_option(win, 'winblend', 20)

  -- 设置高亮
  vim.api.nvim_buf_add_highlight(buf, -1, "Title", 1, 0, -1)
  vim.api.nvim_buf_add_highlight(buf, -1, "String", 3, 0, -1)
  vim.api.nvim_buf_add_highlight(buf, -1, "Number", 4, 0, -1)
  vim.api.nvim_buf_add_highlight(buf, -1, "Comment", 6, 0, -1)
  vim.api.nvim_buf_add_highlight(buf, -1, "Comment", 7, 0, -1)

  -- 播放系统声音（多次播放确保听到）
  vim.fn.jobstart('afplay /System/Library/Sounds/Glass.aiff', { detach = true })

  -- 延迟再播放一次
  vim.defer_fn(function()
    vim.fn.jobstart('afplay /System/Library/Sounds/Glass.aiff', { detach = true })
  end, 500)

  -- 按任意键关闭
  vim.keymap.set('n', '<Esc>', '<cmd>q<CR>', { buffer = buf, silent = true })
  vim.keymap.set('n', '<CR>', '<cmd>q<CR>', { buffer = buf, silent = true })
  vim.keymap.set('n', 'q', '<cmd>q<CR>', { buffer = buf, silent = true })

  vim.api.nvim_create_autocmd("BufLeave", {
    buffer = buf,
    once = true,
    callback = function()
      if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, true)
      end
    end
  })
end

-- 计时器主循环
local function timer_tick()
  if not active_timer then
    return
  end

  if not timer_state.paused then
    timer_state.remaining_seconds = timer_state.remaining_seconds - 1

    if timer_state.remaining_seconds <= 0 then
      -- 计时器完成 - 先保存信息再清空
      local task_name = timer_state.task_name
      local total_seconds = timer_state.total_seconds

      M.stop_timer()
      show_completion_notification(task_name, total_seconds)
      return
    end

    update_sketchybar()
  end
end

-- 开始新的任务计时器
function M.start_timer(task_name, minutes)
  if active_timer then
    vim.notify("Timer already running! Stop it first.", vim.log.levels.WARN)
    return
  end

  timer_state.task_name = task_name
  timer_state.total_seconds = minutes * 60
  timer_state.remaining_seconds = timer_state.total_seconds
  timer_state.start_time = os.time()
  timer_state.paused = false

  update_sketchybar()

  -- 启动计时器（每秒更新）
  active_timer = vim.fn.timer_start(1000, timer_tick, { ["repeat"] = -1 })

  vim.notify(string.format("⏱ Started: %s (%d min)", task_name, minutes), vim.log.levels.INFO)
end

-- 停止计时器
function M.stop_timer()
  if active_timer then
    vim.fn.timer_stop(active_timer)
    active_timer = nil
  end

  timer_state = {
    task_name = nil,
    total_seconds = 0,
    remaining_seconds = 0,
    start_time = nil,
    paused = false,
  }

  -- 清空sketchybar
  update_sketchybar()
end

-- 暂停/继续计时器
function M.toggle_pause()
  if not active_timer then
    vim.notify("No active timer", vim.log.levels.WARN)
    return
  end

  timer_state.paused = not timer_state.paused
  update_sketchybar()

  if timer_state.paused then
    vim.notify("⏸ Timer paused", vim.log.levels.INFO)
  else
    vim.notify("▶ Timer resumed", vim.log.levels.INFO)
  end
end

-- 显示当前状态
function M.show_status()
  if not active_timer then
    vim.notify("No active timer", vim.log.levels.INFO)
    return
  end

  local msg = string.format(
    "Task: %s | Time left: %s | Status: %s",
    timer_state.task_name,
    format_time(timer_state.remaining_seconds),
    timer_state.paused and "PAUSED" or "RUNNING"
  )
  vim.notify(msg, vim.log.levels.INFO)
end

-- 检查是否有活动的计时器
function M.has_active_timer()
  return active_timer ~= nil
end

-- 智能启动：从当前行解析或交互式
function M.smart_start()
  -- 检查当前行内容
  local line = vim.api.nvim_get_current_line()

  -- 尝试匹配格式：任务名 数字
  local task_name, minutes = line:match("^(.-)%s+(%d+)%s*$")

  if task_name and minutes then
    -- 解析成功，直接启动
    minutes = tonumber(minutes)
    if minutes and minutes > 0 then
      M.start_timer(task_name, minutes)
      return
    end
  end

  -- 解析失败，使用交互式输入
  M.start_interactive()
end

-- 交互式启动计时器
function M.start_interactive()
  vim.ui.input({ prompt = "Task name: " }, function(task_name)
    if not task_name or task_name == "" then
      return
    end

    vim.ui.input({ prompt = "Duration (minutes): " }, function(minutes_str)
      if not minutes_str or minutes_str == "" then
        return
      end

      local minutes = tonumber(minutes_str)
      if not minutes or minutes <= 0 then
        vim.notify("Invalid duration", vim.log.levels.ERROR)
        return
      end

      M.start_timer(task_name, minutes)
    end)
  end)
end

-- 设置命令
function M.setup()
  vim.api.nvim_create_user_command("ParkStart", function(opts)
    if #opts.fargs == 0 then
      M.start_interactive()
    elseif #opts.fargs >= 2 then
      local minutes = tonumber(opts.fargs[#opts.fargs])
      local task_name = table.concat(vim.list_slice(opts.fargs, 1, #opts.fargs - 1), " ")
      M.start_timer(task_name, minutes)
    else
      vim.notify("Usage: :ParkStart [task name] [minutes] or :ParkStart (interactive)", vim.log.levels.ERROR)
    end
  end, { nargs = "*" })

  vim.api.nvim_create_user_command("ParkStop", function()
    M.stop_timer()
  end, {})

  vim.api.nvim_create_user_command("ParkPause", function()
    M.toggle_pause()
  end, {})

  vim.api.nvim_create_user_command("ParkStatus", function()
    M.show_status()
  end, {})

  -- 初始化sketchybar项目（居中显示）
  -- 先移除可能存在的旧项目，然后添加新的
  vim.fn.jobstart([[
    sketchybar --remove parkinson.timer 2>/dev/null
    sketchybar --add item parkinson.timer center \
      --set parkinson.timer \
      label="" \
      icon.drawing=off \
      label.color=0xffed8796 \
      label.font="SF Pro:Semibold:14.0" \
      background.drawing=off \
      padding_left=8 \
      padding_right=8 \
      y_offset=0 \
      position=center \
      drawing=off
  ]], { detach = true })
end

return M
