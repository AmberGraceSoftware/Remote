--!strict
--[[
    Remote management library for Roblox.

    Remote provides a centralized interface for creating and accessing remote
    events, functions, and states (i.e. replicated data) for a Roblox project.

    Github Repository: AmberGraceSoftware/Remote
    Wally Package ID: ambergracesoftware/remote
    Documentation: Found on Github
    License: MIT
]]

local Types = require(script.Types)

export type Namespace = Types.Namespace

--[=[
    @class Remote

    :::warning
    Remote is still a work in progress and does not currently have a full
    release! Please avoiding Remote in production-bound projects, as the library
    is not fully tested, and the API may be subject to change
    :::

    Remote provides a centralized interface for creating and accessing remote
    events, functions, and states (i.e. replicated data) for a Roblox project.
    
    For more information, see the [Usage Guide](../docs/intro)
]=]
local Remote = {}

Remote.Namespace = function(...: string): Namespace
    local keys = table.pack(...)
    
    return table.freeze(setmetatable({}, {
        __index = function(_self: any, methodName: string)
            local method = (Remote :: any)[methodName]
            return function(...: any)
                local postArgs = table.pack(...)
                local newArgs = table.create(#keys + #postArgs)
                for i = 1, keys.n do
                    newArgs[i] = keys[i]
                end
                for i = 1, postArgs.n do
                    newArgs[keys.n + i] = postArgs[i]
                end
                return method(table.unpack(newArgs))
            end
        end,
    })) :: any
end

return Remote :: Namespace