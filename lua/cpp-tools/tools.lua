function mth_to_str(meth, simple)
    disable_class = disable_class or false
    local full = ""
    if meth["type"] ~= "" then
        full = meth["type"] .. " "
    end
    if not simple then
        if #meth["namespace"] ~= 0 then
            full = full .. table.concat(meth["namespace"], "::") .. "::"
        end
    end
    full = full .. meth["name"] .. "(" .. meth["params"] .. ")"
    return full
end

function get_hh_buff()
    if vim.fn.expand("%:e") == "hh" then
        print("Cannot do that in a header file")
        return nil
    end
    local name = vim.fn.expand("%:r")
    local buf = vim.fn.bufadd(name .. ".hh")
    vim.fn.bufload(buf)
    return buf
end

function t(node, buf)
    buf = buf or 0
    return ts.get_node_text(node, buf)
end

function get_namespace_list(namespace_str, node, buf)
    local function split(val)
        local sep, fields = "::", {}
        local pattern = string.format("([^%s]+)", sep)
        val:gsub(pattern, function(c)
            fields[#fields + 1] = c
        end)
        return fields
    end

    local current = split(namespace_str)
    while node ~= nil do
        if node:type() == "namespace_definition" then
            for i = 0, node:child_count() - 1 do
                local c = node:child(i)
                if c:type() == "namespace_identifier" then
                    table.insert(current, 1, t(c, buf))
                    break
                end
            end
        end
        node = node:parent()
    end
    return current
end

function parse_meth(node, buffer, base_namespace)
    buffer = buffer or vim.api.nvim_get_current_buf()
    local text = t(node, buffer)
    local type = "(.-)%s*"
    local namespace = "([a-zA-Z_:]-)"
    local name = "([a-zA-Z_]+)%("
    local params = "(.*)%)"
    local pattern = string.format("^%s%s%s%s", type, namespace, name, params)
    _, _, type, namespace, name, params = string.find(text, pattern)
    if name == nil then
        error("Error parsing " .. text, nil)
    end
    if namespace ~= "" then
        namespace = namespace:sub(1, -3)
    end
    namespace = get_namespace_list(namespace, node, buffer)
    for _, v in pairs(base_namespace) do
        if namespace[1] ~= v then
            return nil
        end
        table.remove(namespace, 1)
    end
    return {
        type = type,
        class = namespace[#namespace],
        name = name,
        namespace = namespace,
        line = node:start(),
        params = params,
    }
end

function get_current_namespace()
    return get_namespace_list("", ts.get_node(), vim.api.nvim_get_current_buf())
end

function table_to_list(tbl, check)
    local ret = {}
    for k, v in pairs(tbl) do
        if not check or check(k, v) then
            local val = v
            val["key"] = k
            table.insert(ret, val)
        end
    end
    return ret
end
