local conf = require "indentguide.config"
local utils = require "indentguide.utils"
local indent = require "indentguide.indent"
local M = {}

---@enum indentguide.hooks.type
M.type = {
    ACTIVE = "ACTIVE",
    SCOPE_ACTIVE = "SCOPE_ACTIVE",
    SKIP_LINE = "SKIP_LINE",
    WHITESPACE = "WHITESPACE",
    VIRTUAL_TEXT = "VIRTUAL_TEXT",
    SCOPE_HIGHLIGHT = "SCOPE_HIGHLIGHT",
    CLEAR = "CLEAR",
    HIGHLIGHT_SETUP = "HIGHLIGHT_SETUP",
}

---@class indentguide.hooks.options
---@field bufnr number?
local default_opts = {
    bufnr = nil,
}

local hooks = {
    [M.type.ACTIVE] = {},
    [M.type.SCOPE_ACTIVE] = {},
    [M.type.SKIP_LINE] = {},
    [M.type.WHITESPACE] = {},
    [M.type.VIRTUAL_TEXT] = {},
    [M.type.SCOPE_HIGHLIGHT] = {},
    [M.type.CLEAR] = {},
    [M.type.HIGHLIGHT_SETUP] = {},
    buffer_scoped = {},
}
local count = 0

---@alias indentguide.hooks.cb.active fun(bufnr: number): boolean
---@alias indentguide.hooks.cb.scope_active fun(bufnr: number): boolean
---@alias indentguide.hooks.cb.skip_line fun(tick: number, bufnr: number, row: number, line: string): boolean
---@alias indentguide.hooks.cb.whitespace fun(tick: number, bufnr: number, row: number, whitespace: indentguide.indent.whitespace[]): indentguide.indent.whitespace[]
---@alias indentguide.hooks.cb.virtual_text fun(tick: number, bufnr: number, row: number, virt_text: indentguide.virtual_text): indentguide.virtual_text
---@alias indentguide.hooks.cb.scope_highlight fun(tick: number, bufnr: number, scope: TSNode, scope_index: number): number
---@alias indentguide.hooks.cb.clear fun(bufnr: number)
---@alias indentguide.hooks.cb.highlight_setup fun()

--- Registers a hook
---
--- Each hook type takes a callback a different function, and a configuration table
---@param type indentguide.hooks.type
---@param cb function
---@param opts indentguide.hooks.options
---@overload fun(type: 'ACTIVE', cb: indentguide.hooks.cb.active, opts: indentguide.hooks.options?): string
---@overload fun(type: 'SCOPE_ACTIVE', cb: indentguide.hooks.cb.scope_active, opts: indentguide.hooks.options?): string
---@overload fun(type: 'SKIP_LINE', cb: indentguide.hooks.cb.skip_line, opts: indentguide.hooks.options?): string
---@overload fun(type: 'WHITESPACE', cb: indentguide.hooks.cb.whitespace, opts: indentguide.hooks.options?): string
---@overload fun(type: 'VIRTUAL_TEXT', cb: indentguide.hooks.cb.virtual_text, opts: indentguide.hooks.options?): string
---@overload fun(type: 'SCOPE_HIGHLIGHT', cb: indentguide.hooks.cb.scope_highlight, opts: indentguide.hooks.options?): string
---@overload fun(type: 'CLEAR', cb: indentguide.hooks.cb.clear, opts: indentguide.hooks.options?): string
---@overload fun(type: 'HIGHLIGHT_SETUP', cb: indentguide.hooks.cb.highlight_setup, opts: indentguide.hooks.options?): string
M.register = function(type, cb, opts)
    vim.validate {
        type = {
            type,
            function(t)
                return M.type[t] == t
            end,
            "hooks type enum",
        },
        cb = { cb, "function" },
        opts = { opts, "table", true },
    }
    opts = vim.tbl_deep_extend("keep", opts or {}, default_opts)
    vim.validate {
        bufnr = { opts.bufnr, "number", true },
    }
    if opts.bufnr then
        opts.bufnr = utils.get_bufnr(opts.bufnr)
    end
    count = count + 1
    local hook_id = type .. "_" .. tostring(count)

    if opts.bufnr then
        local bufnr = tostring(opts.bufnr)
        if not hooks.buffer_scoped[bufnr] then
            hooks.buffer_scoped[bufnr] = {
                [M.type.ACTIVE] = {},
                [M.type.SCOPE_ACTIVE] = {},
                [M.type.SKIP_LINE] = {},
                [M.type.WHITESPACE] = {},
                [M.type.VIRTUAL_TEXT] = {},
                [M.type.SCOPE_HIGHLIGHT] = {},
                [M.type.CLEAR] = {},
                [M.type.HIGHLIGHT_SETUP] = {},
            }
        end
        hooks.buffer_scoped[bufnr][type][hook_id] = cb
    else
        hooks[type][hook_id] = cb
    end

    return hook_id
end

--- Clears a hook by id
---
---@param id string
M.clear = function(id)
    vim.validate { id = { id, "string" } }
    local type, hook_id = unpack(vim.split(id, "_"))
    if not type or not hook_id or not vim.tbl_contains(M.type, type) then
        return
    end
    hooks[type][hook_id] = nil
end

--- Clears all hooks
---
M.clear_all = function()
    hooks = {
        [M.type.ACTIVE] = {},
        [M.type.SCOPE_ACTIVE] = {},
        [M.type.SKIP_LINE] = {},
        [M.type.WHITESPACE] = {},
        [M.type.VIRTUAL_TEXT] = {},
        [M.type.SCOPE_HIGHLIGHT] = {},
        [M.type.CLEAR] = {},
        [M.type.HIGHLIGHT_SETUP] = {},
        buffer_scoped = {},
    }
end

--- Returns all hooks of the given type for a buffer
---
---@param bufnr number
---@param type indentguide.hooks.type
---@overload fun(bufnr: number, type: 'ACTIVE'): indentguide.hooks.cb.active[]
---@overload fun(bufnr: number, type: 'SCOPE_ACTIVE'): indentguide.hooks.cb.scope_active[]
---@overload fun(bufnr: number, type: 'SKIP_LINE'): indentguide.hooks.cb.skip_line[]
---@overload fun(bufnr: number, type: 'WHITESPACE'): indentguide.hooks.cb.whitespace[]
---@overload fun(bufnr: number, type: 'VIRTUAL_TEXT'): indentguide.hooks.cb.virtual_text[]
---@overload fun(bufnr: number, type: 'SCOPE_HIGHLIGHT'): indentguide.hooks.cb.scope_highlight[]
---@overload fun(bufnr: number, type: 'CLEAR'): indentguide.hooks.cb.clear[]
---@overload fun(bufnr: number, type: 'HIGHLIGHT_SETUP'): indentguide.hooks.cb.highlight_setup[]
M.get = function(bufnr, type)
    local bufnr_str = tostring(bufnr)
    local list = {}
    for _, hook in pairs(hooks[type]) do
        table.insert(list, hook)
    end
    if hooks.buffer_scoped[bufnr_str] then
        for _, hook in pairs(hooks.buffer_scoped[bufnr_str][type]) do
            table.insert(list, hook)
        end
    end

    return list
end

--- Built in hooks
---
--- You can register them yourself using `hooks.register`
---
--- <code>
--- hooks.register(
---     hooks.type.SKIP_LINE,
---     hooks.builtin.skip_preproc_lines,
---     { bufnr = 0 }
--- )
--- </code>
M.builtin = {
    ---@type indentguide.hooks.cb.skip_line
    skip_preproc_lines = function(_, _, _, line)
        for _, pattern in ipairs {
            "^#%s*if",
            "^#%s*ifdef",
            "^#%s*ifndef",
            "^#%s*elif",
            "^#%s*elifdef",
            "^#%s*elifndef",
            "^#%s*else",
            "^#%s*endif",
            "^#%s*define",
            "^#%s*undef",
            "^#%s*warning",
            "^#%s*error",
        } do
            if line:match(pattern) then
                return true
            end
        end
        return false
    end,

    ---@type indentguide.hooks.cb.scope_highlight
    scope_highlight_from_extmark = function(_, bufnr, scope, scope_index)
        local config = conf.get_config(bufnr)
        local highlight = config.scope.highlight

        if type(highlight) ~= "table" then
            return scope_index
        end

        local start_row, start_col = scope:start()
        local end_row, end_col = scope:end_()
        local start_line = vim.api.nvim_buf_get_lines(bufnr, start_row, start_row + 1, false)
        local end_line = vim.api.nvim_buf_get_lines(bufnr, end_row, end_row + 1, false)
        local end_pos
        local start_pos
        local start_pos_scope
        local end_pos_scope

        if end_line[1] then
            end_pos = vim.inspect_pos(bufnr, end_row, #end_line[1] - 1, {
                extmarks = true,
                syntax = false,
                treesitter = false,
                semantic_tokens = false,
            })
            end_pos_scope = vim.inspect_pos(bufnr, end_row, end_col - 1, {
                extmarks = true,
                syntax = false,
                treesitter = false,
                semantic_tokens = false,
            })
        end
        if start_line[1] then
            start_pos = vim.inspect_pos(bufnr, start_row, #start_line[1] - 1, {
                extmarks = true,
                syntax = false,
                treesitter = false,
                semantic_tokens = false,
            })
            start_pos_scope = vim.inspect_pos(bufnr, start_row, start_col, {
                extmarks = true,
                syntax = false,
                treesitter = false,
                semantic_tokens = false,
            })
        end

        if not end_pos and not start_pos then
            return scope_index
        end

        -- it is most accurate to get correct colors from rainbow-delimiters via
        -- the scope, since you can have something like:
        -- function()
        --   ...
        -- end,
        -- where the last symbol will give you rainbow-delimiters highlights
        -- from the comma (nothing) and the last parenthesis (the wrong color)
        for i, hl_group in ipairs(highlight) do
            if end_pos_scope then
                for _, extmark in ipairs(end_pos_scope.extmarks) do
                    if extmark.opts.hl_group == hl_group then
                        return i
                    end
                end
            end
            if start_pos_scope then
                for _, extmark in ipairs(start_pos_scope.extmarks) do
                    if extmark.opts.hl_group == hl_group then
                        return i
                    end
                end
            end
        end
        -- For some languages the scope extends before or after the delimiters. Make an attempt to capture them anyway by looking at the first character of the last line, and the last character of the first line.
        for i, hl_group in ipairs(highlight) do
            if end_pos then
                for _, extmark in ipairs(end_pos.extmarks) do
                    if extmark.opts.hl_group == hl_group then
                        return i
                    end
                end
            end
            if start_pos then
                for _, extmark in ipairs(start_pos.extmarks) do
                    if extmark.opts.hl_group == hl_group then
                        return i
                    end
                end
            end
        end
        return scope_index
    end,

    ---@type indentguide.hooks.cb.whitespace
    hide_first_space_indent_level = function(_, _, _, whitespace_tbl)
        if whitespace_tbl[1] == indent.whitespace.INDENT then
            whitespace_tbl[1] = indent.whitespace.SPACE
        end
        return whitespace_tbl
    end,

    ---@type indentguide.hooks.cb.whitespace
    hide_first_tab_indent_level = function(_, _, _, whitespace_tbl)
        if
            whitespace_tbl[1] == indent.whitespace.TAB_START
            or whitespace_tbl[1] == indent.whitespace.TAB_START_SINGLE
        then
            whitespace_tbl[1] = indent.whitespace.TAB_FILL
        end
        return whitespace_tbl
    end,
}

return M