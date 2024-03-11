local M = {}
require("cpp-tools.tools")

local qs_hh = [[
[
(
    class_specifier
    name: (type_identifier) @class
    body: (field_declaration_list [
        (field_declaration declarator: (function_declarator))
        (declaration)
    ] @meth)
)
(declaration type: (_)) @meth
]
]]

local qs_cc = [[
(function_definition) @meth
]]

local function get_method(buffer, qs, base_namespace)
    local parser = ts.get_parser(buffer)
    local tree = parser:parse()[1]
    local root = tree:root()
    local lang = parser:lang()
    local query = ts.query.parse(lang, qs)
    local methods = {}
    for _, match, _ in query:iter_matches(root, buffer) do
        local meth, class = {}, nil
        for id, node in pairs(match) do
            local name = query.captures[id]
            if name == "meth" then
                meth = parse_meth(node, buffer, base_namespace)
            end
            if name == "class" then
                class = t(node, buffer)
            end
        end
        if meth then
            if class then
                meth["class"] = class
                table.insert(meth["namespace"], class)
            end
            methods[mth_to_str(meth, true)] = meth
        end
    end
    return methods
end

function M.cc_methods(cc_buffer, base_namespace)
    return get_method(cc_buffer, qs_cc, base_namespace)
end

function M.hh_methods(hh_buffer, base_namespace)
    return get_method(hh_buffer, qs_hh, base_namespace)
end

function M.retrieve_unimplemented(hh_buffer, cc_buffer)
    local cur_namespace = get_current_namespace()
    local implemented = M.cc_methods(cc_buffer, cur_namespace)
    local all = M.hh_methods(hh_buffer, cur_namespace)
    for k, _ in pairs(implemented) do
        all[k] = nil
    end
    return all
end

function M.retrieve_methods()
    local hh_buffer = get_hh_buff()
    if not hh_buffer then
        return
    end
    local cc_buffer = vim.api.nvim_get_current_buf()
    local line = vim.fn.line(".")
    local unimplemented = M.retrieve_unimplemented(hh_buffer, cc_buffer)
    local choices = table_to_list(unimplemented)
    if #choices == 0 then
        print("No method to implement")
        return
    end
    table.insert(choices, 1, { key = "All" })
    require("cpp-tools.menu").show_menu(choices, function(sel)
        local key = sel["key"]
        local to_implmt = { [key] = sel }
        if key == "All" then
            to_implmt = unimplemented
        end
        local impl_lines = {}
        for _, v in pairs(to_implmt) do
            if #impl_lines ~= 0 then
                table.insert(impl_lines, "")
            end
            table.insert(impl_lines, mth_to_str(v))
            table.insert(impl_lines, "{")
            table.insert(impl_lines, "	")
            table.insert(impl_lines, "}")
        end
        vim.api.nvim_buf_set_text(cc_buffer, line - 1, 0, line - 1, 0, impl_lines)
        vim.api.nvim_win_set_cursor(vim.api.nvim_get_current_win(), { line, 0 })
    end, "Chose method to implement")
end

function M.get_hovered()
    local node = ts.get_node()
    while node and node:type() ~= "function_definition" do
        node = node:parent()
    end
    return node
end

return M
