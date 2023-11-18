local highlights = require "indentguide.highlights"
local M = {}

M.setup = function()
    local group = vim.api.nvim_create_augroup("IndentGuide", {})
    local indentguide = require "indentguide"
    local buffer_leftcol = {}

    vim.api.nvim_create_autocmd("VimEnter", {
        group = group,
        pattern = "*",
        callback = indentguide.refresh_all,
    })
    vim.api.nvim_create_autocmd({
        "CursorMoved",
        "BufWinEnter",
        "CompleteChanged",
        "FileChangedShellPost",
        "FileType",
        "TextChanged",
        "TextChangedI",
    }, {
        group = group,
        pattern = "*",
        callback = function(opts)
            indentguide.debounced_refresh(opts.buf)
        end,
    })
    vim.api.nvim_create_autocmd("OptionSet", {
        group = group,
        pattern = "list,listchars,shiftwidth,tabstop,vartabstop",
        callback = function(opts)
            indentguide.debounced_refresh(opts.buf)
        end,
    })
    vim.api.nvim_create_autocmd("WinScrolled", {
        group = group,
        pattern = "*",
        callback = function(opts)
            local win_view = vim.fn.winsaveview() or { leftcol = 0 }

            if buffer_leftcol[opts.buf] ~= win_view.leftcol then
                buffer_leftcol[opts.buf] = win_view.leftcol
                -- Refresh immediately for horizontal scrolling
                indentguide.refresh(opts.buf)
            else
                indentguide.debounced_refresh(opts.buf)
            end
        end,
    })
    vim.api.nvim_create_autocmd("ColorScheme", {
        group = group,
        pattern = "*",
        callback = function()
            highlights.setup()
            indentguide.refresh_all()
        end,
    })
end

return M