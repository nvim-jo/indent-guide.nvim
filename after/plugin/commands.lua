local indentguide = require "indentguide"
local conf = require "indentguide.config"

vim.api.nvim_create_user_command("IGEnable", function()
    indentguide.update { enabled = true }
end, {
    bar = true,
    desc = "Enables indent-blankline",
})

vim.api.nvim_create_user_command("IGDisable", function()
    indentguide.update { enabled = false }
end, {
    bar = true,
    desc = "Disables indent-blankline",
})

vim.api.nvim_create_user_command("IGToggle", function()
    if indentguide.initialized then
        indentguide.update { enabled = not conf.get_config(-1).enabled }
    else
        indentguide.setup {}
    end
end, {
    bar = true,
    desc = "Toggles indent-blankline on and off",
})

vim.api.nvim_create_user_command("IGEnableScope", function()
    indentguide.update { scope = { enabled = true } }
end, {
    bar = true,
    desc = "Enables indent-guide scope",
})

vim.api.nvim_create_user_command("IGDisableScope", function()
    indentguide.update { scope = { enabled = false } }
end, {
    bar = true,
    desc = "Disables indent-guide scope",
})

vim.api.nvim_create_user_command("IGToggleScope", function()
    if indentguide.initialized then
        indentguide.update { scope = { enabled = not conf.get_config(-1).scope.enabled } }
    else
        indentguide.setup {}
    end
end, {
    bar = true,
    desc = "Toggles indent-guide scope on and off",
})