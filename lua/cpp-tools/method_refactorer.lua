local M = {}
require("cpp-tools.tools")

function M.refactor_method()
    local hh_buf = get_hh_buff()
    if not hh_buf then
        return
    end
    local method_node = require("cpp-tools.method_retriever").get_hovered()
    if method_node == nil then
        print("Method not found")
        return
    end
    local cc_buf = vim.api.nvim_get_current_buf()
    local base_namespace = get_current_namespace()
    local method = parse_meth(method_node, cc_buf, base_namespace)
    if not method then
        error("An error occured, please report it")
        return
    end

    local unimplemented = require("cpp-tools.method_retriever").retrieve_unimplemented(hh_buf, cc_buf)
    print(vim.inspect(method))
    local choices = table_to_list(unimplemented, function(_, v)
        return v["class"] == method["class"]
    end)
    if #choices == 0 then
        print("No method to override")
        return
    end
    require("cpp-tools.menu").show_menu(choices, function(sel)
        local replacment = mth_to_str(method, true) .. ";"
        local line = sel["line"]
        vim.api.nvim_buf_set_lines(hh_buf, line, line + 1, false, { replacment })
        vim.api.nvim_buf_call(hh_buf, function()
            vim.cmd(":w")
            vim.cmd(
                ":lua vim.lsp.buf.format({ async = true, range = { start = { "
                .. line
                .. ', 0 }, ["end"] = { '
                .. line
                .. " , 0 } } })"
            )
        end)
    end, "Override method ?")
end

return M
