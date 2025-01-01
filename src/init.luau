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

local Event = require(script.Event)
local Function = require(script.Function)
local State = require(script.State)
local Types = require(script.Types)

export type Namespace = Types.Namespace
export type Event = Types.Event
export type Function = Types.Function
export type State<T = any?> = Types.State<T>

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
    @param namespacePrefix string
    @return Remote
    
    Creates a copy of the Remote library that automatically prefixes key
    arguments to all Remote library function calls. Conventionally uses dots
    to prefix keys within the namespace.

    For example:
    ```lua
    local wearOutfit = Remote.Function("Avatar.WearOutfit")
    local equipItem = Remote.Event("Avatar.EquipItem")
    local itemIds = Remote.State("Avatar.EquippedItemIDs", {} :: {string})
    ```

    In the instance above, the prefix "Avatar" can converted to a namespace:
    ```lua
    local AvatarRemotes = Remote.Namespace("Avatar")
    ```

    Objects can then be created/accessed using the same API as the [Remote]()
    library through the `Avatar` namespace:
    ```lua
    local wearOutfit = AvatarRemotes.Function("WearOutfit")
    local equipItem = AvatarRemotes.Event("EquipItem")
    local itemIds = AvatarRemotes.State("EquippedItemIDs", {} :: {string})
    ```
    
]=]
Remote.Namespace = function(namespaceKey: string): Namespace
    namespaceKey ..= "."
    return table.freeze(setmetatable({}, {
        __index = function(_self: any, methodName: string): any
            local method = (Remote :: any)[methodName]
            if not method then
                return nil
            end
            if typeof(method) == "function" then
                return function(key: string, ...: any)
                    return method(namespaceKey .. key, ...)
                end
            end

            return method
        end,
    })) :: any
end

Remote.Event = function(key: string)
    return Event.new(key, true)
end

Remote.UnreliableEvent = function(key: string)
    return Event.new(key, false)
end

Remote.Function = function(key: string)
    return Function.new(key)
end

Remote.State = function(key: string, placeholderValue: any?)
    return State.new(key, placeholderValue)
end

return (Remote :: any) :: Namespace
