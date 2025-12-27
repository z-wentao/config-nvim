local M = {}

function M.setup()
  vim.api.nvim_create_autocmd("BufEnter", {
    pattern = "*/VEG.txt",
    callback = function()
      -- 回车自动转表格
      vim.keymap.set('i', '<CR>', function()
        local line = vim.api.nvim_get_current_line()
        local activity, v, e, g = line:match("^(.-)%s+([-+]?%d+)%s+([-+]?%d+)%s+([-+]?%d+)%s*$")
        
        if activity and v and e and g then
          local row = vim.api.nvim_win_get_cursor(0)[1]
          v, e, g = tonumber(v), tonumber(e), tonumber(g)
          local sum = v + e + g
          local fmt = function(n) return n >= 0 and "+"..n or tostring(n) end
          local new_line = string.format("| %s | %s | %s | %s | %s |", activity, fmt(v), fmt(e), fmt(g), fmt(sum))
          
          vim.schedule(function()
            vim.api.nvim_buf_set_lines(0, row - 1, row, false, { new_line })
            vim.api.nvim_win_set_cursor(0, { row, #new_line })
            vim.cmd('startinsert!')
            vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<CR>', true, false, true), 'n', false)
          end)
          return ""
        end
        return "<CR>"
      end, { buffer = true, expr = true })
      
      -- <leader>vs 可视化分析
      vim.keymap.set('n', '<leader>vs', function()
        local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
        local data = {}
        
        for _, line in ipairs(lines) do
          if line:match("^|") and not line:match("Activity") and not line:match("%-%-") then
            local activity = line:match("^|%s*(.-)%s*|")
            local score = line:match("[-+]?%d+%s*|%s*$")
            score = score and tonumber(score:match("[-+]?%d+")) or 0
            if activity then
              table.insert(data, { name = activity, score = score })
            end
          end
        end
        
        table.sort(data, function(a, b) return a.score > b.score end)
        
        local groups = {}
        for _, item in ipairs(data) do
          local s = item.score
          if not groups[s] then groups[s] = {} end
          table.insert(groups[s], item.name)
        end
        
        local result = { "VEG Energy Analysis", "" }
        local scores = {}
        for s in pairs(groups) do table.insert(scores, s) end
        table.sort(scores, function(a, b) return a > b end)
        
        local max_score = math.max(math.abs(scores[1] or 1), math.abs(scores[#scores] or 1))
        for _, s in ipairs(scores) do
          local bar_len = math.max(1, math.floor(math.abs(s) / max_score * 30))
          local bar = s >= 0 and string.rep("█", bar_len) or string.rep("▓", bar_len)
          local names = table.concat(groups[s], " / ")
          table.insert(result, string.format("%+3d %s %s", s, bar, names))
        end
        
        local buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, result)
        
        local width = 60
        local height = #result + 2
        vim.api.nvim_open_win(buf, true, {
          relative = "editor",
          width = width,
          height = height,
          row = (vim.o.lines - height) / 2,
          col = (vim.o.columns - width) / 2,
          style = "minimal",
          border = "rounded",
        })
        
        vim.bo[buf].bufhidden = "wipe"
        vim.keymap.set('n', 'q', ':q<CR>', { buffer = buf })
        vim.keymap.set('n', '<Esc>', ':q<CR>', { buffer = buf })
      end, { buffer = true })
    end
  })
end

return M
