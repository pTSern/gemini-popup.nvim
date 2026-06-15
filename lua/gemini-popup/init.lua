local M = {
    state = {
        buf = -1,
        win = -1,
        config = {
            size = {
                horizontal = 0.8,
                vertical = 0.8,
            },
            toggle = {},
            kill = {},
        }
    }
}

function M.toggle_gemini_cli()
    -- Create buffer if it doesn't exist or is invalid
    if not vim.api.nvim_buf_is_valid(M.state.buf) then
        M.state.buf = vim.api.nvim_create_buf(false, true)
    end

    -- Close window if it exists and is valid
    if vim.api.nvim_win_is_valid(M.state.win) then
        vim.api.nvim_win_close(M.state.win, true)
        M.state.win = -1
        return
    end

    -- Calculate window size and position
    local width = math.floor(vim.o.columns * M.state.config.size.horizontal)
    local height = math.floor(vim.o.lines * M.state.config.size.vertical)
    local col = math.floor((vim.o.columns - width) / 2)
    local row = math.floor((vim.o.lines - height) / 2)

    -- Window options
    local win_opts = {
        relative = "editor",
        width = width,
        height = height,
        col = col,
        row = row,
        style = "minimal",
        border = "rounded",
    }

    -- Open the floating window
    M.state.win = vim.api.nvim_open_win(M.state.buf, true, win_opts)

    -- Start terminal if buffer is empty
    if vim.bo[M.state.buf].buftype ~= "terminal" then
        vim.fn.termopen("gemini")
    end

    -- Enter insert mode
    vim.cmd("startinsert")
end

function M.kill_gemini_cli()
    if vim.api.nvim_win_is_valid(M.state.win) then
        vim.api.nvim_win_close(M.state.win, true)
        M.state.win = -1
    end
    if vim.api.nvim_buf_is_valid(M.state.buf) then
        vim.api.nvim_buf_delete(M.state.buf, { force = true })
        M.state.buf = -1
    end
end

function M.setup(user_config)
    -- Merge config
    if user_config then
        if user_config.size then
            M.state.config.size.horizontal = user_config.size.horizontal or M.state.config.size.horizontal
            M.state.config.size.vertical = user_config.size.vertical or M.state.config.size.vertical
        end
        M.state.config.toggle = user_config.toggle or M.state.config.toggle
        M.state.config.kill = user_config.kill or M.state.config.kill
    end

    -- Register toggle keybindings
    for _, bind in ipairs(M.state.config.toggle) do
        vim.keymap.set(bind.mode or { 'n' }, bind.key, function()
            M.toggle_gemini_cli()
        end, { desc = bind.desc or "Toggle Gemini CLI popup", silent = true })
    end

    -- Register kill keybindings
    for _, bind in ipairs(M.state.config.kill) do
        vim.keymap.set(bind.mode or { 'n' }, bind.key, function()
            M.kill_gemini_cli()
        end, { desc = bind.desc or "Kill Gemini CLI popup", silent = true })
    end
end

return M
