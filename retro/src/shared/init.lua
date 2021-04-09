--[[
                _                                    _       
    _ __ ___| |_ _ __ ___     _ __ ___   __ _  __| | __ _ 
    | '__/ _ \ __| '__/ _ \   | '_ ` _ \ / _` |/ _` |/ _` |
    | | |  __/ |_| | | (_) |  | | | | | | (_| | (_| | (_| |
    |_|  \___|\__|_|  \___/___|_| |_| |_|\__,_|\__,_|\__,_|
                        |_____|                           


    File Information:
        name: Simple Module Loader
        description: A simple and easy to use module loader that modifies the the function environment
            to allow for custom globals for requiring modules. Also allows for custom typed paths such.
            e.g: import '@config/market/dev-products'


    Instructions:
        Globals:
            To add or remove a global edit the 'globals' table. You can add or remove as many as you want.

        Delimiter:
            To change the delimiter modify the delimiter variable. By default it is set to '/'.
            The delimiter is the symbol that seperates keywords in your path. eg: @config/myconfig or @config.myconfig
            Note: If you change the delimiter you must also update your paths to the new delimiter.

        Paths:
            To add a path you must first figure out what side your path is going to run on.
            If you're requiring a module from the server the loader is going to scan the 'server' paths first to
            see if a prefix exists in it's context. If no prefix is found it will check for other.

            Think of 'other' as a 'shared' table between server & client. Both can require from there.

            Server will always check server paths first, and client will always check client first. Afterwards they will
            both fallback to 'other'. If there is no 'other' path it will require as normal as if that path it will
            continue its normal require operation of 'modules/PATH/YOU/INPUTED'.

            Server paths will always come out of ServerStorage.Modules/PATH
            Client paths will always come out of PlayerScripts.Modules/PATH
            Other paths will come out of ReplicatedStorage.Modules/PATH

            There is one exception, if you use an INSTANCE instead a string it will use that full path instead.
            This will work for all Server, Client and Other.



            Example of a path:
            ['@config'] = 'config'
]]

-- Roblox Services
local run_svc   = game:GetService('RunService')
local rep_svc   = game:GetService('ReplicatedStorage')
local ssg_svc   = game:GetService('ServerStorage')

-- Configuration
local globals   = { 
        'require', 'import', 'include' }

local delimiter = '/'

local paths     = {
    server = { },

    client = { },

    other = { }
}

local function traverse_nodes(base, nodes)
    local res
    for _, node in pairs(nodes) do
        if not res then
            if base:FindFirstChild(node) then
                res = base[node]
            end
        elseif res[node] then
            res = res[node]
        else
            res = nil
        end
    end

    return res
end

local function split_nodes(str)
    local nodes = {}
    for s in str:gmatch('([^' .. delimiter .. ']+)') do
        table.insert(nodes, s)
    end
    return nodes
end

local function require_file(file, clone)
    if type(file) == 'string' then
        local client = run_svc:IsClient() 
        local nodes = split_nodes(file)

        local prefix = nodes[1]
        local storage
        local base = client and game.StarterPlayer.StarterPlayerScripts:WaitForChild('modules') 
            or ssg_svc:WaitForChild('modules')

        local container = paths[client and 'client' or 'server'][prefix]
        local other_container = paths['other'][prefix]
        if container then
            table.remove(nodes, 1)

            storage = type(container) == 'string' 
                and traverse_nodes(base, split_nodes(container)) or container
        elseif other_container then
            table.remove(nodes, 1)
            storage = type(other_container) == 'string' 
                and traverse_nodes(base, split_nodes(other_container)) or other_container
        else
            storage = base
        end

        local res = traverse_nodes(storage, nodes)
        return require(clone and res:Clone() or res)
    else
        return require(clone and file:Clone() or file)
    end
end

local function init()
    local fenv = getfenv(2)

    for _, global in pairs(globals) do
        fenv[global] =  require_file
    end
end

return init