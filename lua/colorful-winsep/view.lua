local api = vim.api
local fn = vim.fn
local utils = require('colorful-winsep.utils')
local M = {
  config = utils.defaultopts,
  wins = {},
  bufs = {},
  width = 0,
  height = 0,
  timers = {}
}

--- Create floating win show  line
---@return
function M.create_dividing_win()
  if utils.can_create(M.config.no_exec_files) then
    if utils.isCreated() then
      return false
    end
    local direction = utils.direction
    for _, value in pairs(direction) do
      local opts = utils.create_direction_win_option(value)
      if utils.direction_have(value) and opts ~= nil then
        local buf = api.nvim_create_buf(false, false)
        M.bufs[value] = buf
        api.nvim_buf_set_option(buf, "buftype", "nofile")
        local win = api.nvim_open_win(buf, false, opts)
        M.wins[value] = win
        api.nvim_win_set_option(win, 'winhl', 'Normal:NvimSeparator')
      end
    end
    M.width = vim.fn.winwidth(0)
    M.height = vim.fn.winwidth(0)
    return true
  end
  return false
end

--- move show line for floating win
---@return
function M.move_dividing_win()
  if M.width == fn.winwidth(0) and M.height == fn.winheight(0) then
    return false
  end
  for key, _ in pairs(M.wins) do
    local opts = utils.create_direction_win_option(key)
    api.nvim_win_set_config(M.wins[key], opts)
  end
  return true
end

--- close show line for floating win
function M.close_dividing()
  for key, _ in pairs(M.wins) do
    api.nvim_win_close(M.wins[key], true)
  end
  M.wins = {}
  for key, _ in pairs(M.bufs) do
    api.nvim_buf_delete(M.bufs[key], { force = true })
  end
  M.bufs = {}
end

--- set line symbol
function M.set_buf_char()
  local direction = utils.direction
  local symbols = M.config.symbols
  for key, _ in pairs(M.wins) do
    if key == direction.up or key == direction.down then
      local len = fn.winwidth(M.wins[key])
      local str = { "" }
      for i = 1, len do
        str[1] = str[1] .. symbols[1]
      end
      api.nvim_buf_set_lines(M.bufs[key], 0, -1, false, str)
    elseif key == direction.left then
      local len = fn.winheight(M.wins[key])
      local str = {}
      for i = 1, len do
        str[i] = symbols[2]
      end
      if utils.direction_have(direction.up) then
        str[1] = symbols[3]
      end
      if utils.direction_have(direction.down) or vim.o.laststatus ~= 3 then
        str[len] = symbols[5]
      end
      api.nvim_buf_set_lines(M.bufs[key], 0, -1, false, str)
    elseif key == direction.right then
      local len = fn.winheight(M.wins[key])
      local str = {}
      for i = 1, len do
        str[i] = symbols[2]
      end
      if utils.direction_have(direction.up) then
        str[1] = symbols[4]
      end
      if utils.direction_have(direction.down) or vim.o.laststatus ~= 3 then
        str[len] = symbols[6]
      end
      api.nvim_buf_set_lines(M.bufs[key], 0, -1, false, str)
    end
  end
end

function M.highlight()
  local opts = M.config.highlight
  vim.api.nvim_set_hl(0, 'NvimSeparator', { fg = opts.guifg, bg = opts.guibg })
end

function M.set_config(opts)
  utils.set_user_config(opts)
  M.config = utils.defaultopts
end

function M.resize_auto_show_float_win()
  if M.width ~= fn.winwidth(0) or M.height ~= fn.winheight(0) then
    if M.create_dividing_win() then
      M.set_buf_char()
    elseif M.move_dividing_win() then
      M.set_buf_char()
    end
    M.width = fn.winwidth(0)
    M.height = fn.winheight(0)
  end
end

function M.start_timer()
  timer = vim.loop.new_timer()
  timer:start(0, M.config.interval, vim.schedule_wrap(M.resize_auto_show_float_win))
  table.insert(M.timers, timer)
end

function M.stop_timer()
  for i = 1, #M.timers do
    M.timers[i]:stop()
    M.timers[i] = nil
  end
  M.timers = {}
end

return M
