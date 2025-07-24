local M = {}
require("cpp-tools.tools")
local qs_classes = [[
(class_specifier name: (type_identifier) @name ) @class
]]

function getClasses(buffer)
	local parser = ts.get_parser(buffer)
	local tree = parser:parse()[1]
	local root = tree:root()
	local lang = parser:lang()
	local query = ts.query.parse(lang, qs_classes)
	local classes = {}
	local class_name, line
	for id, node, metadata, match in query:iter_captures(root, buffer) do
		local name = query.captures[id]
		if name == "name" then
			class_name = ts.get_node_text(node, buffer)
			classes[class_name] = {
				name = class_name,
				line = line,
			}
		elseif name == "class" then
			line = node:end_()
		end
	end
	return classes
end

M.create_method = function()
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
	local classes = getClasses(hh_buf)
	require("cpp-tools.menu").show_menu(table_to_list(classes), function(class)
		if class == nil then
			return
		end
		require("cpp-tools.menu").show_menu(
			{ { key = "public" }, { key = "private" }, { key = "protected" } },
			function(access)
				local mth_str = mth_to_str(method, {
					const = true,
				})
				local line = class.line
				vim.api.nvim_buf_set_lines(hh_buf, line, line, false, { access.key .. ":", mth_str .. ";" })
				vim.api.nvim_buf_call(hh_buf, function()
					vim.cmd(":w")
					vim.cmd(
						":lua vim.lsp.buf.format({ async = true, range = { start = { "
							.. line - 1
							.. ', 0 }, ["end"] = { '
							.. line + 1
							.. " , 0 } } })"
					)
				end)
			end,
			"What accesibility ?"
		)
	end, "In wich class ?")
end

return M
