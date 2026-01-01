local M = {}

-- URL encode函数
local function url_encode(str)
  if str then
    str = string.gsub(str, "([^%w%-%.%~])", function(c)
      return string.format("%%%02X", string.byte(c))
    end)
  end
  return str
end

-- 添加任务到Things Today（使用AppleScript批量添加）
local function add_to_things_today(task_name)
  local script = string.format([[
    tell application "Things3"
      set newToDo to make new to do with properties {name:"%s"}
      move newToDo to list "Today"
    end tell
  ]], task_name:gsub('"', '\\"'))

  local result = vim.fn.system('osascript -e ' .. vim.fn.shellescape(script))
  local exit_code = vim.v.shell_error

  if exit_code ~= 0 then
    vim.notify("Error: " .. result, vim.log.levels.ERROR)
    return false
  end

  return true
end

-- 获取选中的文本
local function get_visual_selection()
  local _, start_line, start_col, _ = unpack(vim.fn.getpos("'<"))
  local _, end_line, end_col, _ = unpack(vim.fn.getpos("'>"))

  local lines = vim.fn.getline(start_line, end_line)

  -- 确保lines是表格
  if type(lines) ~= "table" then
    lines = {lines}
  end

  -- 检查是否为空
  if #lines == 0 or not lines[1] then
    return {}
  end

  -- 如果只选了一行，处理列选择
  if #lines == 1 then
    lines[1] = string.sub(lines[1], start_col, end_col)
  else
    -- 多行选择，处理首尾
    lines[1] = string.sub(lines[1], start_col)
    if lines[#lines] then
      lines[#lines] = string.sub(lines[#lines], 1, end_col)
    end
  end

  return lines
end

-- 添加选中的任务到Things（批量添加）
function M.add_selection_to_things()
  -- Debug: 确认函数被调用
  vim.notify("🔍 Quick add triggered!", vim.log.levels.INFO)

  local lines = get_visual_selection()

  if #lines == 0 then
    vim.notify("No selection", vim.log.levels.WARN)
    return
  end

  -- 收集所有任务
  local tasks = {}
  for _, line in ipairs(lines) do
    line = vim.trim(line)
    if line ~= "" and not line:match("^#") and not line:match("^//") then
      -- 移除markdown任务列表标记
      line = line:gsub("^%s*[%-%*]%s*%[.%]%s*", "")
      line = line:gsub("^%s*[%-%*]%s*", "")
      table.insert(tasks, line)
    end
  end

  if #tasks == 0 then
    vim.notify("No valid tasks found", vim.log.levels.WARN)
    return
  end

  -- 构建批量添加的AppleScript（反向添加以保持正确顺序）
  local script_parts = {"tell application \"Things3\""}

  -- Reverse iteration: add tasks from last to first
  -- This way, the first selected line ends up on top
  for i = #tasks, 1, -1 do
    local task = tasks[i]
    local escaped = task:gsub('"', '\\"')
    -- Use direct move without intermediate variable to avoid AppleScript syntax error
    table.insert(script_parts, string.format('  move (make new to do with properties {name:"%s"}) to list "Today"', escaped))
  end

  table.insert(script_parts, "end tell")

  local script = table.concat(script_parts, "\n")
  local result = vim.fn.system('osascript -e ' .. vim.fn.shellescape(script))
  local exit_code = vim.v.shell_error

  if exit_code ~= 0 then
    vim.notify("Error: " .. result, vim.log.levels.ERROR)
  else
    vim.notify(string.format("✅ Added %d task(s) to Things Today", #tasks), vim.log.levels.INFO)
  end
end

-- 设置快捷键
function M.setup()
  -- Visual mode: <leader>it = insert to Things
  -- Use "x" for visual mode (includes v, V, and Ctrl-V)
  -- Use command mode to ensure visual selection marks are updated
  vim.keymap.set("x", "<leader>it", ":<C-u>lua require('config.things-quick-add').add_selection_to_things()<CR>",
    { desc = "Insert to Things Today" })
end

return M
