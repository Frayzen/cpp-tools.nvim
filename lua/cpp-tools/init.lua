local M = {}

ts = vim.treesitter

function M.setup(opts)
    opts = opts or {}
end

function M.implement()
    require("cpp-tools.method_retriever").retrieve_methods()
end

function M.refactor()
    require("cpp-tools.method_refactorer").refactor_method()
end

return M
