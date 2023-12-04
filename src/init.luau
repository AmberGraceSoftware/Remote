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


--[=[
    @function Namespace
    @within Remote
    @param ... string
    @return Remote
    
    Creates a copy of the Remote library that automatically prefixes key
    arguments to all Remote library function calls.

    For example:
    ```lua
    local wearOutfit = Remote.Function("AvatarEditor", "WearOutfit")
    local equipItem = Remote.Event("AvatarEditor", "EquipItem")
    local itemIds = Remote.State("AvatarEditor", "EquippedItemIDs", {} :: {string})
    ```

    In this example, the "AvatarEditor" key being used can converted to a
    namespace:
    ```lua
    local AvatarRemotes = Remote.Namespace("AvatarEditor")
    ```

    Objects can then be created/accessed using the same API as the [Remote]()
    library through the `AvatarRemotes` namespace:
    ```lua
    local wearOutfit = AvatarRemotes.Function("WearOutfit")
    local equipItem = AvatarRemotes.Event("EquipItem")
    local itemIds = AvatarRemotes.State("EquippedItemIDs", {} :: {string})
    ```
    
]=]
Remote.Namespace = function(...: string): Namespace
    local keys = table.pack(...)
    
    return table.freeze(setmetatable({}, {
        __index = function(_self: any, methodName: string): any
            local method = (Remote :: any)[methodName]
            if not method then
                return nil
            end
            if typeof(method) == "function" then
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
            end

            return method
        end,
    })) :: any
end

return Remote :: Namespace