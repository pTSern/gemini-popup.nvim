local M = {
    state = {
        instances = {}, -- list of { buf = number, path = string }
        active_idx = 0,
        win = -1,
        config = {
            size = { horizontal = 0.8, vertical = 0.8 },
            toggle = { { key = "<Leader>gm", mode = { 'n', 'v', 't' }, desc = "Toggle [G]e[M]ini CLI popup" } },
            kill = { { key = "<Leader>gk", mode = { "n", "v", "t" }, desc = "[G]emini Popup will be [K]illed" } },
            new = { { key = "<Leader>gn", mode = { 'n', 'v', 't' }, desc = "New Gemini Popup at path" } },
            next = { { key = "<Tab>k", mode = { 'n', 'v', 't' }, desc = "Next Gemini Popup" } },
            prev = { { key = "<Tab>j", mode = { 'n', 'v', 't' }, desc = "Prev Gemini Popup" } },
        }
    }
}

local function get_short_path(path)
    if path == "." or path == "" then return "root" end
    return vim.fn.fnamemodify(path, ":~:.")
end

function M.update_window_title()
    if not vim.api.nvim_win_is_valid(M.state.win) then return end
    local instance = M.state.instances[M.state.active_idx]
    if not instance then return end

    local short_path = get_short_path(instance.path)
    local title = string.format(" %s [%d/%d] ", short_path, M.state.active_idx, #M.state.instances)

    -- Note: Window title support requires Neovim 0.9+
    pcall(vim.api.nvim_win_set_config, M.state.win, {
        title = title,
        title_pos = "center"
    })
end

function M.open_path(path)
    path = path or "."
    if path == "" then path = "." end
    local absolute_path = vim.fn.fnamemodify(path, ":p")

    -- Check if instance already exists
    local found_idx = -1
    for i, inst in ipairs(M.state.instances) do
        if inst.path == absolute_path then
            found_idx = i
            break
        end
    end

    if found_idx == -1 then
        -- Create new instance
        local buf = vim.api.nvim_create_buf(false, true)
        table.insert(M.state.instances, { buf = buf, path = absolute_path })
        M.state.active_idx = #M.state.instances
        
        -- Start terminal
        vim.api.nvim_buf_call(buf, function()
            vim.fn.termopen(string.format("cd %s && gemini", vim.fn.shellescape(absolute_path)))
        end)
    else
        M.state.active_idx = found_idx
    end

    M.show_current()
end

function M.show_current()
    local instance = M.state.instances[M.state.active_idx]
    if not instance then return end

    -- Close old window if invalid
    if M.state.win ~= -1 and not vim.api.nvim_win_is_valid(M.state.win) then
        M.state.win = -1
    end

    local width = math.floor(vim.o.columns * M.state.config.size.horizontal)
    local height = math.floor(vim.o.lines * M.state.config.size.vertical)
    local col = math.floor((vim.o.columns - width) / 2)
    local row = math.floor((vim.o.lines - height) / 2)

    local win_opts = {
        relative = "editor",
        width = width,
        height = height,
        col = col,
        row = row,
        style = "minimal",
        border = "rounded",
    }

    if M.state.win == -1 then
        M.state.win = vim.api.nvim_open_win(instance.buf, true, win_opts)
    else
        vim.api.nvim_win_set_buf(M.state.win, instance.buf)
    end

    M.update_window_title()
    vim.cmd("startinsert")
end

function M.toggle_gemini_cli()
    if vim.api.nvim_win_is_valid(M.state.win) then
        vim.api.nvim_win_close(M.state.win, true)
        M.state.win = -1
        return
    end

    if #M.state.instances == 0 then
        M.open_path(".")
    else
        if M.state.active_idx == 0 then M.state.active_idx = 1 end
        M.show_current()
    end
end

function M.navigate(delta)
    if #M.state.instances <= 1 then return end
    
    M.state.active_idx = M.state.active_idx + delta
    if M.state.active_idx > #M.state.instances then
        M.state.active_idx = 1
    elseif M.state.active_idx < 1 then
        M.state.active_idx = #M.state.instances
    end

    M.show_current()
end

function M.kill_gemini_cli()
    if vim.api.nvim_win_is_valid(M.state.win) then
        vim.api.nvim_win_close(M.state.win, true)
        M.state.win = -1
    end
    
    local instance = M.state.instances[M.state.active_idx]
    if instance then
        if vim.api.nvim_buf_is_valid(instance.buf) then
            vim.api.nvim_buf_delete(instance.buf, { force = true })
        end
        table.remove(M.state.instances, M.state.active_idx)
        
        if #M.state.instances > 0 then
            M.state.active_idx = math.min(M.state.active_idx, #M.state.instances)
            M.show_current()
        else
            M.state.active_idx = 0
        end
    end
end

function M.input_new_path()
    local width = 50
    local height = 1
    local col = math.floor((vim.o.columns - width) / 2)
    local row = math.floor((vim.o.lines - height) / 2)

    local buf = vim.api.nvim_create_buf(false, true)
    local win = vim.api.nvim_open_win(buf, true, {
        relative = "editor",
        width = width,
        height = height,
        col = col,
        row = row,
        style = "minimal",
        border = "rounded",
        title = " Gemini Path ",
        title_pos = "center"
    })

    vim.api.nvim_buf_set_keymap(buf, 'n', '<Esc>', '<cmd>q!<CR>', { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(buf, 'i', '<Esc>', '<cmd>q!<CR>', { noremap = true, silent = true })
    
    vim.api.nvim_buf_set_keymap(buf, 'i', '<CR>', '', {
        callback = function()
            local path = vim.api.nvim_get_current_line()
            vim.api.nvim_win_close(win, true)
            M.open_path(path)
        end,
        noremap = true, silent = true
    })

    vim.cmd("startinsert")
end

function M.setup(user_config)
    M.state.config = vim.tbl_deep_extend("force", M.state.config, user_config or {})

    local function register(binds, callback)
        for _, bind in ipairs(binds) do
            vim.keymap.set(bind.mode or { 'n' }, bind.key, callback, { desc = bind.desc, silent = true })
        end
    end

    register(M.state.config.toggle, M.toggle_gemini_cli)
    register(M.state.config.kill, M.kill_gemini_cli)
    register(M.state.config.new, M.input_new_path)
    register(M.state.config.next, function() M.navigate(1) end)
    register(M.state.config.prev, function() M.navigate(-1) end)

    vim.api.nvim_create_user_command("GeminiPopup", function(opts)
        M.open_path(opts.args)
    end, { nargs = "?" })
end

return M
