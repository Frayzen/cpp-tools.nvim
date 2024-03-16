local M = {}

local options = {
    header_retriever = function(path, name, ext)
        print(path .. name .. "." .. ext)
        if ext == "cc" then
            return path .. name .. ".hh"
        end
        return nil
    end
}

function M.setup(opts)
    opts = opts or {}
    for k, v in pairs(opts) do
        options[k] = v
    end
end

function M.get_options()
    return options
end

function M.implement()
    require("cpp-tools.method_retriever").retrieve_methods()
end

function M.refactor()
    require("cpp-tools.method_refactorer").refactor_method()
end

return M
