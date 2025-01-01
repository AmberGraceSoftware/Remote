--!strict
local RunService = game:GetService("RunService")
local GetRemoteInstance = require(script.Parent.GetRemoteInstance)

local Function = {}
Function.__index = Function

function Function.new(key: string)
    local self = setmetatable({}, Function)
    self._instance = GetRemoteInstance("RemoteFunction", key) :: RemoteFunction
    return self
end

type Function = typeof(Function.new(""))

function Function.OnInvoke(
    self: Function,
    callback: (player: Player, ...unknown) -> any
)
    if not RunService:IsServer() then
        error("Function:OnInvoke can only be called on the server")
    end
    self._instance.OnServerInvoke = callback
end

function Function.Invoke(self: Function, ...: any): any
    if not RunService:IsClient() then
        error("Function:Invoke can only be called on the client")
    end
    return self._instance:InvokeServer(...)
end

function Function.Destroy(self: Function)
    self._instance:Destroy()
end

return Function
