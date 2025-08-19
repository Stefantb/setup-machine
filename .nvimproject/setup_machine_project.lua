-- local utils = require("projects.utils")
-- local project_root = utils.local_project_path(utils.script_path())
local M = {
    -- root_dir not needed if local project
    root_dir = '/home/stefanb/dev/local-tools/setup_machine',
    extensions = {
        builds = {
            task_name = {
                executor     = 'vim',
                compiler     = 'gcc',
                makeprg      = 'make',
                command      = 'Make release',
                abortcommand = 'AbortDispatch'
            },
        },
        lspconfig = {
            clangd = {
                --cmd = { 'clangd', '--log=verbose' },
                --lsp_root = 'repo root',
            }
        },
    },
}
function M.on_project_open()
    vim.opt.makeprg = 'make'
    --vim.cmd('PBuildSetDefault make')
end
function M.on_project_close()
end
return M
