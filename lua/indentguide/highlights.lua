local conf = require "indentguide.config"
local hooks = require "indentguide.hooks"

---@class indentguide.highlight
---@field char string
---@field underline string?

local M = {
    ---@type indentguide.highlight[]
    indent = {},
    ---@type indentguide.highlight[]
    whitespace = {},
    ---@type indentguide.highlight[]
    scope = {},
}

---@param name string
local get = function(name)
    -- TODO [Lukas]: remove this when AstroNvim drops support for 0.8
    if not vim.api.nvim_get_hl then
        ---@diagnostic disable-next-line
        return (vim.fn.hlexists(name) == 1 and vim.api.nvim_get_hl_by_name(name, true)) or vim.empty_dict() --[[@as table]]
    end

    return vim.api.nvim_get_hl(0, { name = name })
end

---@param hl table
local not_set = function(hl)
    return not hl or vim.tbl_count(hl) == 0
end

local setup_builtin_hl_groups = function()
    local whitespace_hl = get "Whitespace"
    local line_nr_hl = get "LineNr"
    local indentguide_indent_hl_name = "IGIndent"
    local indentguide_whitespace_hl_name = "IGWhitespace"
    local indentguide_scope_hl_name = "IGScope"

    if not_set(get(indentguide_indent_hl_name)) then
        vim.api.nvim_set_hl(0, indentguide_indent_hl_name, whitespace_hl)
    end
    if not_set(get(indentguide_whitespace_hl_name)) then
        vim.api.nvim_set_hl(0, indentguide_whitespace_hl_name, whitespace_hl)
    end
    if not_set(get(indentguide_scope_hl_name)) then
        vim.api.nvim_set_hl(0, indentguide_scope_hl_name, line_nr_hl)
    end
end

M.setup = function()
    local config = conf.get_config(-1)

    for _, fn in
        pairs(hooks.get(-1, hooks.type.HIGHLIGHT_SETUP) --[=[@as indentguide.hooks.cb.highlight_setup[]]=])
    do
        fn()
    end

    setup_builtin_hl_groups()

    local indent_highlights = config.indent.highlight
    if type(indent_highlights) == "string" then
        indent_highlights = { indent_highlights }
    end
    M.indent = {}
    for i, name in ipairs(indent_highlights) do
        local hl = get(name)
        if not_set(hl) then
            error(string.format("No highlight group '%s' found", name))
        end
        hl.nocombine = true
        M.indent[i] = { char = string.format("@indentguide.indent.char.%d", i) }
        vim.api.nvim_set_hl(0, M.indent[i].char, hl)
    end

    local whitespace_highlights = config.whitespace.highlight
    if type(whitespace_highlights) == "string" then
        whitespace_highlights = { whitespace_highlights }
    end
    M.whitespace = {}
    for i, name in ipairs(whitespace_highlights) do
        local hl = get(name)
        if not_set(hl) then
            error(string.format("No highlight group '%s' found", name))
        end
        hl.nocombine = true
        M.whitespace[i] = { char = string.format("@indentguide.whitespace.char.%d", i) }
        vim.api.nvim_set_hl(0, M.whitespace[i].char, hl)
    end

    local scope_highlights = config.scope.highlight
    if type(scope_highlights) == "string" then
        scope_highlights = { scope_highlights }
    end
    M.scope = {}
    for i, scope_name in ipairs(scope_highlights) do
        local char_hl = get(scope_name)
        if not_set(char_hl) then
            error(string.format("No highlight group '%s' found", scope_name))
        end
        char_hl.nocombine = true
        M.scope[i] = {
            char = string.format("@indentguide.scope.char.%d", i),
            underline = string.format("@indentguide.scope.underline.%d", i),
        }
        vim.api.nvim_set_hl(0, M.scope[i].char, char_hl)
        vim.api.nvim_set_hl(0, M.scope[i].underline, { sp = char_hl.fg, underline = true })
    end
end

return M