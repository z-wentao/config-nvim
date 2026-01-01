-- Markdown 文件特定配置
-- 自动为任务列表添加续行

-- 设置 formatoptions 来自动处理列表
vim.bo.formatoptions = vim.bo.formatoptions .. "ro"

-- 设置 comments 选项来识别任务列表格式
vim.bo.comments = "b:*,b:-,b:+,b:1.,fb:- [ ],fb:- [x],fb:- [X]"

-- 设置 commentstring (虽然这里主要用于任务列表)
vim.bo.commentstring = ""

-- 自定义函数来处理任务列表的自动续行
local function setup_task_list_continuation()
    -- 当按 Enter 时，检查当前行是否为任务列表项
    local function handle_enter()
        local line = vim.api.nvim_get_current_line()
        local row, col = unpack(vim.api.nvim_win_get_cursor(0))

        -- 匹配不同类型的任务列表格式
        local patterns = {
            "^(%s*)%- %[ %] (.*)$",     -- - [ ] task
            "^(%s*)%- %[x%] (.*)$",     -- - [x] completed task
            "^(%s*)%- %[X%] (.*)$",     -- - [X] completed task
            "^(%s*)%* %[ %] (.*)$",     -- * [ ] task
            "^(%s*)%* %[x%] (.*)$",     -- * [x] completed task
            "^(%s*)%* %[X%] (.*)$",     -- * [X] completed task
        }

        for _, pattern in ipairs(patterns) do
            local indent, content = line:match(pattern)
            if indent then
                -- 如果内容为空，删除当前行的标记部分
                if content == "" or content:match("^%s*$") then
                    vim.api.nvim_set_current_line(indent)
                    return
                end

                -- 否则创建新的任务项
                local new_line = indent .. "- [ ] "
                vim.api.nvim_put({new_line}, "l", true, true)

                -- 将光标移动到新行的末尾
                local new_row = row + 1
                vim.api.nvim_win_set_cursor(0, {new_row, #new_line})
                return
            end
        end

        -- 如果不是任务列表，执行正常的回车
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<CR>", true, false, true), "n", false)
    end

    -- 绑定 Enter 键
    vim.keymap.set("i", "<CR>", handle_enter, { buffer = true, desc = "Smart task list continuation" })
end

-- 自动切换任务状态的函数
local function toggle_task_status()
    local line = vim.api.nvim_get_current_line()
    local row = vim.api.nvim_win_get_cursor(0)[1]

    local new_line = line

    -- 从未完成切换到完成
    new_line = new_line:gsub("^(%s*[%-%*] )%[ %]", "%1[x]")

    -- 如果没有变化，尝试从完成切换到未完成
    if new_line == line then
        new_line = new_line:gsub("^(%s*[%-%*] )%[[xX]%]", "%1[ ]")
    end

    if new_line ~= line then
        vim.api.nvim_set_current_line(new_line)
    end
end

-- 设置快捷键切换任务状态
vim.keymap.set("n", "<leader>tt", toggle_task_status, { buffer = true, desc = "Toggle task status" })

-- 应用任务列表续行功能
setup_task_list_continuation()

-- 设置一些有用的 Markdown 选项
vim.bo.textwidth = 0        -- 不自动换行
vim.wo.wrap = true          -- 软换行
vim.wo.linebreak = true     -- 在单词边界换行
vim.wo.number = true        -- 显示行号
vim.wo.relativenumber = false -- 不使用相对行号（对 Markdown 来说可能更清晰）

-- 设置缩进
vim.bo.expandtab = true
vim.bo.tabstop = 2
vim.bo.shiftwidth = 2
vim.bo.softtabstop = 2

-- print("Markdown task list auto-completion loaded!")
-- 更智能的 o/O 映射
local function smart_insert_below()
    local line = vim.api.nvim_get_current_line()
    local row = vim.api.nvim_win_get_cursor(0)[1]
    
    -- 检查当前行或上一行是否是任务列表
    local is_task_list = line:match("^%s*[%-%*] %[.%]")
    
    if is_task_list then
        local indent = line:match("^(%s*)")
        vim.api.nvim_buf_set_lines(0, row, row, false, {indent .. "- [ ] "})
        vim.api.nvim_win_set_cursor(0, {row + 1, #indent + 6})
        vim.cmd("startinsert!")
    else
        -- 执行默认的 o 行为
        vim.cmd("normal! o")
    end
end

local function smart_insert_above()
    local line = vim.api.nvim_get_current_line()
    local row = vim.api.nvim_win_get_cursor(0)[1]
    
    local is_task_list = line:match("^%s*[%-%*] %[.%]")
    
    if is_task_list then
        local indent = line:match("^(%s*)")
        vim.api.nvim_buf_set_lines(0, row - 1, row - 1, false, {indent .. "- [ ] "})
        vim.api.nvim_win_set_cursor(0, {row, #indent + 6})
        vim.cmd("startinsert!")
    else
        vim.cmd("normal! O")
    end
end

vim.keymap.set("n", "o", smart_insert_below, { buffer = true, desc = "Smart insert below" })
vim.keymap.set("n", "O", smart_insert_above, { buffer = true, desc = "Smart insert above" })

-- 字符美化配置 (conceal)
vim.wo.conceallevel = 1
vim.wo.concealcursor = "niv"

-- 设置语法美化规则
vim.api.nvim_create_autocmd("Syntax", {
  pattern = "markdown",
  callback = function()
    -- 右箭头符号美化: -> 显示为 →
    vim.cmd("syntax match markdownArrowRight '->' conceal cchar=→")
    -- 左箭头符号美化: <- 显示为 ←
    vim.cmd("syntax match markdownArrowLeft '<-' conceal cchar=←")
    -- 不等号美化: != 显示为 ≠
    vim.cmd("syntax match markdownNotEqual '!=' conceal cchar=≠")
  end,
})

-- 快速交换上下
vim.keymap.set("n", "J", ":m .+1<CR>==")
vim.keymap.set("n", "K", ":m .-2<CR>==")

