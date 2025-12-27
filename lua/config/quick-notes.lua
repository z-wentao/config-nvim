-- 快速记事本模块
local M = {}

-- 配置
M.config = {
	notes_file = vim.fn.expand("~/Documents/quick-notes.md"),
	window = {
		width = 0.8, -- 窗口宽度（比例）
		height = 0.8, -- 窗口高度（比例）
		border = "rounded", -- 边框样式: 'single', 'double', 'rounded', 'solid', 'shadow'
	},
}

M.win_id = nil
M.buf_id = nil

-- 确保 buffer 已创建（懒加载）
M.ensure_buffer = function()
	if M.buf_id and vim.api.nvim_buf_is_valid(M.buf_id) then
		return
	end

	-- 使用 Vim 命令快速加载文件到 buffer
	M.buf_id = vim.api.nvim_create_buf(false, false)

	-- 批量设置 buffer 选项（更快）
	vim.api.nvim_buf_call(M.buf_id, function()
		vim.cmd('silent! edit ' .. vim.fn.fnameescape(M.config.notes_file))
		vim.bo.bufhidden = 'hide'
		vim.bo.swapfile = false
		vim.bo.filetype = 'markdown'
	end)
end

-- 创建悬浮窗口
M.create_floating_window = function()
	-- 确保 buffer 存在
	M.ensure_buffer()

	local width = math.floor(vim.o.columns * M.config.window.width)
	local height = math.floor(vim.o.lines * M.config.window.height)
	local col = math.floor((vim.o.columns - width) / 2)
	local row = math.floor((vim.o.lines - height) / 2)

	-- 窗口配置
	local win_config = {
		relative = "editor",
		width = width,
		height = height,
		col = col,
		row = row,
		style = "minimal",
		border = M.config.window.border,
		title = " Quick Notes ",
		title_pos = "center",
	}

	-- 创建窗口
	M.win_id = vim.api.nvim_open_win(M.buf_id, true, win_config)

	-- 批量设置窗口选项
	vim.api.nvim_win_call(M.win_id, function()
		vim.wo.wrap = true
		vim.wo.linebreak = true
		vim.wo.number = true
		vim.wo.relativenumber = true
		vim.wo.cursorline = true
	end)
end

-- 保存并关闭窗口
M.close_and_save = function()
	if M.buf_id and vim.api.nvim_buf_is_valid(M.buf_id) then
		-- 使用 Vim 原生命令保存（更快）
		vim.api.nvim_buf_call(M.buf_id, function()
			if vim.bo.modified then
				vim.cmd('silent! write')
			end
		end)
	end

	-- 关闭窗口
	if M.win_id and vim.api.nvim_win_is_valid(M.win_id) then
		vim.api.nvim_win_close(M.win_id, false)
		M.win_id = nil
	end
end

-- 切换记事本
M.toggle_notes = function()
	if M.win_id and vim.api.nvim_win_is_valid(M.win_id) then
		-- 关闭并保存
		M.close_and_save()
	else
		-- 打开窗口
		M.create_floating_window()

		-- 设置当前窗口的快捷键
		local opts = { buffer = M.buf_id, noremap = true, silent = true }
		vim.keymap.set("n", "<Esc>", M.close_and_save, opts)
		vim.keymap.set("n", "q", M.close_and_save, opts)
		vim.keymap.set("n", "<C-s>", M.close_and_save, opts)
	end
end

-- 初始化
M.setup = function(user_config)
	-- 合并用户配置
	if user_config then
		M.config = vim.tbl_deep_extend("force", M.config, user_config)
	end

	-- 确保记事本目录存在
	local notes_dir = vim.fn.fnamemodify(M.config.notes_file, ":h")
	vim.fn.mkdir(notes_dir, "p")

	-- 预加载 buffer（延迟 100ms，避免影响启动速度）
	vim.defer_fn(function()
		M.ensure_buffer()
	end, 100)

	-- 设置全局快捷键
	vim.keymap.set("n", "<leader>n", M.toggle_notes, {
		noremap = true,
		silent = true,
		desc = "Toggle floating quick notes",
	})

	-- 额外的实用快捷键（可选）
	vim.keymap.set("n", "<leader>nt", function()
		if M.buf_id and vim.api.nvim_buf_is_valid(M.buf_id) and M.win_id and vim.api.nvim_win_is_valid(M.win_id) then
			local timestamp = os.date("## %Y-%m-%d %H:%M:%S")
			local pos = vim.api.nvim_win_get_cursor(M.win_id)
			vim.api.nvim_buf_set_lines(M.buf_id, pos[1], pos[1], false, { "", timestamp, "" })
			vim.api.nvim_win_set_cursor(M.win_id, { pos[1] + 3, 0 })
		else
			vim.notify("Quick notes is not open!", vim.log.levels.WARN)
		end
	end, {
		noremap = true,
		silent = true,
		desc = "Insert timestamp in quick notes",
	})
end

return M
