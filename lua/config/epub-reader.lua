-- ~/.config/nvim/plugin/epub-reader.lua

if vim.fn.executable("pandoc") == 0 then
  return
end

local function read_epub()
  local filepath = vim.fn.expand("%:p")
  local filename = vim.fn.expand("%:t:r")
  local temp_dir = vim.fn.tempname()
  local markdown_file = temp_dir .. "/" .. filename .. ".md"

  vim.fn.mkdir(temp_dir, "p")

  -- 优化的 pandoc 命令：只保留文字和标题
  local pandoc_cmd = string.format(
    "pandoc '%s' -t markdown-raw_html-native_divs-native_spans-fenced_divs-bracketed_spans " ..
    "--strip-comments " ..
    "--wrap=auto " ..
    "--columns=80 " ..
    "-o '%s'",
    filepath,
    markdown_file
  )

  vim.notify("正在转换 EPUB...", vim.log.levels.INFO)
  local result = vim.fn.system(pandoc_cmd)

  if vim.v.shell_error ~= 0 then
    vim.notify("转换失败: " .. result, vim.log.levels.ERROR)
    return
  end

  vim.cmd("enew")
  vim.cmd("read " .. markdown_file)
  vim.cmd("1delete")

  -- Buffer 选项（使用 vim.bo）
  vim.bo.filetype = "markdown"
  vim.bo.readonly = true
  vim.bo.modifiable = false
  vim.bo.buftype = "nofile"

  -- Window 选项（使用 vim.wo）
  vim.wo.wrap = true          -- 自动换行
  vim.wo.linebreak = true     -- 在单词边界换行
  vim.wo.number = false       -- 隐藏行号
  vim.wo.relativenumber = false
  vim.wo.signcolumn = "no"    -- 隐藏符号列
  vim.wo.cursorline = true    -- 高亮当前行

  vim.api.nvim_buf_set_name(0, "[EPUB] " .. filename)

  -- 删除多余内容
  vim.cmd([[silent! %s/\n\n\n\+/\r\r/ge]])  -- 压缩多个空行
  vim.cmd([[silent! %s/!\[.*\](.*)/[图片]/ge]])  -- 删除图片链接
  vim.cmd([[silent! %s/^[-*_]\{3,}$//ge]])  -- 删除分隔线

  -- 优化的快捷键
  local opts = { buffer = true, silent = true }

  -- 退出
  vim.keymap.set("n", "q", ":bdelete<CR>", opts)
  -- 移除 ESC 键映射，避免与 quick-notes 冲突
  -- vim.keymap.set("n", "<Esc>", ":bdelete<CR>", opts)

  -- 滚动（按显示行移动）
  vim.keymap.set("n", "j", "gj", opts)
  vim.keymap.set("n", "k", "gk", opts)
  vim.keymap.set("n", "<Down>", "gj", opts)
  vim.keymap.set("n", "<Up>", "gk", opts)

  -- 翻页
  vim.keymap.set("n", "<Space>", "<C-d>", opts)      -- 半页向下
  vim.keymap.set("n", "<S-Space>", "<C-u>", opts)    -- 半页向上
  vim.keymap.set("n", "<PageDown>", "<C-f>", opts)   -- 整页向下
  vim.keymap.set("n", "<PageUp>", "<C-b>", opts)     -- 整页向上
  vim.keymap.set("n", "d", "<C-d>", opts)            -- d 向下半页
  vim.keymap.set("n", "u", "<C-u>", opts)            -- u 向上半页

  -- 快速跳转
  vim.keymap.set("n", "gg", "gg", opts)
  vim.keymap.set("n", "G", "G", opts)
  vim.keymap.set("n", "H", "H", opts)
  vim.keymap.set("n", "M", "M", opts)
  vim.keymap.set("n", "L", "L", opts)

  -- 章节导航
  vim.keymap.set("n", "]]", "/^#\\+\\s<CR>:nohl<CR>", opts)
  vim.keymap.set("n", "[[", "?^#\\+\\s<CR>:nohl<CR>", opts)

  -- 搜索
  vim.keymap.set("n", "/", "/", opts)
  vim.keymap.set("n", "n", "n", opts)
  vim.keymap.set("n", "N", "N", opts)
  vim.keymap.set("n", "<C-l>", ":nohl<CR>", opts)  -- 清除搜索高亮

  -- 书签
  vim.keymap.set("n", "m", "m", opts)
  vim.keymap.set("n", "'", "'", opts)

  -- 清理临时文件
  vim.api.nvim_create_autocmd("BufDelete", {
    buffer = 0,
    callback = function()
      vim.fn.delete(markdown_file)
      vim.fn.delete(temp_dir, "d")
    end,
  })

  vim.notify(
    "EPUB 加载成功！\n" ..
    "快捷键: q=退出 | Space=向下 | d/u=半页 | ]]/[[=章节 | /=搜索 | Ctrl+l=清除高亮",
    vim.log.levels.INFO
  )
end

vim.api.nvim_create_autocmd("BufReadCmd", {
  pattern = "*.epub",
  callback = read_epub,
})

vim.api.nvim_create_user_command("EpubOpen", function(opts)
  vim.cmd("edit " .. vim.fn.fnameescape(opts.args))
end, { nargs = 1, complete = "file" })
