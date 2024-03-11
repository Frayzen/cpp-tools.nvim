local M = {}

function M.show_menu(choices, cb, name)
    local pickers = require("telescope.pickers")
    local finders = require("telescope.finders")
    local actions = require("telescope.actions")
    local action_state = require("telescope.actions.state")
    local conf = require("telescope.config").values
    local opts = require("telescope.themes").get_dropdown({})
    pickers
        .new(opts, {
            prompt_title = name,
            finder = finders.new_table({
                results = choices,
                entry_maker = function(entry)
                    return {
                        value = entry,
                        display = entry["key"],
                        ordinal = entry["key"],
                    }
                end,
            }),
            attach_mappings = function(prompt_bufnr, _)
                actions.select_default:replace(function()
                    actions.close(prompt_bufnr)
                    local val = action_state.get_selected_entry()
                    cb(val["value"])
                end)
                return true
            end,
            sorter = conf.generic_sorter(opts),
        })
        :find()
end

function M.close_menu()
    vim.api.nvim_win_close(0, true)
end

return M
