--!strict
local RunService = game:GetService("RunService")
local GetRemoteInstance = require(script.Parent.GetRemoteInstance)
local Types = require(script.Parent.Types)

local Event = {}
Event.__index = Event

function Event.new(key: string, isReliable: boolean)
    local self = setmetatable({}, Event)
    self._instance = GetRemoteInstance(
        if isReliable then "RemoteEvent" else "UnreliableRemoteEvent",
        key
    ) :: RemoteEvent
    return self
end

type Event = typeof(Event.new("", true))

function Event.ConnectServer(
    self: Event,
    callback: (player: Player, ...unknown) -> ()
): Types.Connection
    if not RunService:IsServer() then
        error("Event:ConnectServer can only be called on the server")
    end
    return self._instance.OnServerEvent:Connect(callback)
end

function Event.ConnectClient(
    self: Event,
    callback: (...any) -> ()
): Types.Connection
    if RunService:IsServer() then
        error("Event:ConnectClient can only be called on the client")
    end
    return self._instance.OnClientEvent:Connect(callback)
end

function Event.FireServer(self: Event, ...: any)
    if not RunService:IsClient() then
        error("Event:FireServer can only be called on the client")
    end
    self._instance:FireServer(...)
end

function Event.FireClient(self: Event, player: Player, ...: any)
    if not RunService:IsServer() then
        error("Event:FireClient can only be called on the server")
    end
    self._instance:FireClient(player, ...)
end

function Event.FireAllClients(self: Event, ...: any)
    if not RunService:IsServer() then
        error("Event:FireAllClients can only be called on the server")
    end
    self._instance:FireAllClients(...)
end

function Event.FireExceptClient(self: Event, player: Player, ...: any)
    if not RunService:IsServer() then
        error("Event:FireExceptClient can only be called on the server")
    end
    for _, otherPlayer in RunService:GetPlayers() do
        if otherPlayer ~= player then
            self._instance:FireClient(otherPlayer, ...)
        end
    end
end

function Event.Destroy(self: Event)
    self._instance:Destroy()
end

return Event
