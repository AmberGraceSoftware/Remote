--!strict
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Event = require(script.Parent.Event)

local StatesInit = Event.new("@@AmberGraceSoftware.Remote.StatesInit", true)
local StateUpdate = Event.new("@@AmberGraceSoftware.Remote.StateUpdate", true)
local ClientReady = Event.new("@@AmberGraceSoftware.Remote.ClientReady", true)

type GlobalState = {
    placeholderValue: any?,
    globalValue: any?,
    globalValueWasSet: boolean,
    perPlayerValues: { [Player]: any },
    perPlayerValueWasSet: { [Player]: boolean },
    listenerSet: { [(newValue: any) -> ()]: boolean },
    perPlayerListenerSet: { [Player]: { [(newValue: any) -> ()]: boolean } },
}
local GlobalStateStore = {} :: {
    [string]: GlobalState,
}
local ReadyClientCache = {} :: { [Player]: boolean }

local function resolveCurrentState(key: string, forPlayer: Player?): any?
    local globalState = GlobalStateStore[key]
    if globalState then
        if forPlayer then
            if globalState.perPlayerValueWasSet[forPlayer] then
                return globalState.perPlayerValues[forPlayer]
            end
        end
        if globalState.globalValueWasSet then
            return globalState.globalValue
        end
        return globalState.placeholderValue
    end
    return nil
end

local function fireListeners(key: string, newValue: any, forPlayer: Player?)
    local globalState = GlobalStateStore[key]
    if not globalState then
        return
    end
    if forPlayer then
        local perPlayerListenerSet = globalState.perPlayerListenerSet[forPlayer]
        if perPlayerListenerSet then
            for listener in table.clone(perPlayerListenerSet) do
                task.spawn(listener, newValue)
            end
        end
    else
        for listener in table.clone(globalState.listenerSet) do
            task.spawn(listener, newValue)
        end
    end
end

-- Run global replication system
if RunService:IsRunning() then
    if RunService:IsServer() then
        Players.PlayerAdded:Connect(function(player)
            ReadyClientCache[player] = false
        end)
        ClientReady:ConnectServer(function(player)
            if ReadyClientCache[player] ~= false then
                return
            end
            local keys = {}
            for key in GlobalStateStore do
                table.insert(keys, key)
            end
            local values = table.create(#keys)
            for i, key in keys do
                values[i] = resolveCurrentState(key, player)
            end
            StatesInit:FireClient(player, keys, values)
            ReadyClientCache[player] = true
        end)
        -- Clear cache on player removing
        Players.PlayerRemoving:Connect(function(player)
            for _key, globalState in GlobalStateStore do
                globalState.perPlayerValueWasSet[player] = nil
                globalState.perPlayerValues[player] = nil
                globalState.perPlayerListenerSet[player] = nil
            end
            ReadyClientCache[player] = nil
        end)
    else
        StatesInit:ConnectClient(function(keys: { string }, values: { any })
            for i, key in keys do
                local globalState = GlobalStateStore[key]
                if globalState then
                    globalState.globalValue = values[i]
                    globalState.globalValueWasSet = true
                    fireListeners(key, values[i])
                else
                    GlobalStateStore[key] = {
                        placeholderValue = nil,
                        globalValue = values[i],
                        globalValueWasSet = true,
                        perPlayerValues = {},
                        perPlayerValueWasSet = {},
                        listenerSet = {},
                        perPlayerListenerSet = {},
                    }
                end
            end
        end)
        StateUpdate:ConnectClient(function(key: string, newValue: any)
            local globalState = GlobalStateStore[key]
            if not globalState then
                return
            end
            globalState.globalValue = newValue
            globalState.globalValueWasSet = true
            fireListeners(key, newValue)
        end)
        ClientReady:FireServer()
    end
end

local State = {}
State.__index = State

function State.new(key: string, placeholderValue: any?): State
    local self = setmetatable({}, State)
    self._connectedListeners = {} :: { [(newValue: any) -> ()]: boolean }
    self._key = key
    if not GlobalStateStore[key] then
        GlobalStateStore[key] = {
            placeholderValue = placeholderValue,
            globalValue = nil,
            globalValueWasSet = false,
            perPlayerValues = {},
            perPlayerValueWasSet = {},
            listenerSet = {},
            perPlayerListenerSet = {},
        }
    end
    self._globalState = GlobalStateStore[key]
    return self
end

function State.Get(self: State): any?
    return resolveCurrentState(self._key, nil)
end

function State.GetFor(self: State, player: Player): any?
    return resolveCurrentState(self._key, player)
end

function State.Set(self: State, newValue: any)
    if
        self._globalState.globalValueWasSet
        and self._globalState.globalValue == newValue
        and typeof(newValue) ~= "table"
    then
        return
    end
    if RunService:IsServer() then
        self._globalState.globalValue = newValue
        self._globalState.globalValueWasSet = true
        fireListeners(self._key, newValue)
        for player, isReady in ReadyClientCache do
            if not isReady then
                continue
            end
            if self._globalState.perPlayerValueWasSet[player] then
                continue
            end
            StateUpdate:FireClient(player, self._key, newValue)
        end
    else
        self._globalState.globalValue = newValue
        self._globalState.globalValueWasSet = true
        fireListeners(self._key, newValue)
    end
end

function State.SetFor(self: State, player: Player, newValue: any)
    if not RunService:IsServer() then
        error("State:SetFor can only be called on the server")
    end
    if not player:IsDescendantOf(game) and ReadyClientCache[player] == nil then
        return
    end
    if
        self._globalState.perPlayerValueWasSet[player]
        and self._globalState.perPlayerValues[player] == newValue
        and typeof(newValue) ~= "table"
    then
        return
    end
    self._globalState.perPlayerValues[player] = newValue
    self._globalState.perPlayerValueWasSet[player] = true
    fireListeners(self._key, newValue, player)
    if ReadyClientCache[player] then
        StateUpdate:FireClient(player, self._key, newValue)
    end
end

function State.SetTop(self: State, newValue: any)
    if not RunService:IsServer() then
        return
    end
    if
        self._globalState.globalValueWasSet
        and self._globalState.globalValue == newValue
        and typeof(newValue) ~= "table"
    then
        return
    end
    self._globalState.globalValue = newValue
    self._globalState.globalValueWasSet = true
    fireListeners(self._key, newValue)
    for player, isReady in ReadyClientCache do
        if not isReady then
            continue
        end
        if self._globalState.perPlayerValueWasSet[player] then
            continue
        end
        StateUpdate:FireClient(player, self._key, newValue)
    end
end

function State.ClearFor(self: State, player: Player)
    if not RunService:IsServer() then
        error("State:ResetFor can only be called on the server")
    end
    if not player:IsDescendantOf(game) and ReadyClientCache[player] == nil then
        return
    end
    if not self._globalState.perPlayerValueWasSet[player] then
        return
    end
    local previousValue = self._globalState.perPlayerValues[player]
    self._globalState.perPlayerValues[player] = nil
    self._globalState.perPlayerValueWasSet[player] = nil
    local fallbackValue = resolveCurrentState(self._key, player)
    fireListeners(self._key, fallbackValue, player)
    if ReadyClientCache[player] and previousValue ~= fallbackValue then
        StateUpdate:FireClient(player, self._key, fallbackValue)
    end
end

function State.Subscribe(
    self: State,
    callback: (newValue: any) -> (),
    immediatelyCallListener: boolean?
)
    if immediatelyCallListener == nil then
        immediatelyCallListener = true
    end
    self._connectedListeners[callback] = true
    self._globalState.listenerSet[callback] = true

    if immediatelyCallListener then
        task.spawn(callback, self:Get())
    end
    return function()
        self._connectedListeners[callback] = nil
        self._globalState.listenerSet[callback] = nil
    end
end

function State.SubscribeFor(
    self: State,
    player: Player,
    callback: (newValue: any) -> (),
    immediatelyCallListener: boolean?
)
    if immediatelyCallListener == nil then
        immediatelyCallListener = true
    end
    if not RunService:IsServer() then
        error("State:SubscribeFor can only be called on the server")
    end
    self._connectedListeners[callback] = true
    local perPlayerListenerSet = self._globalState.perPlayerListenerSet[player]
    if not perPlayerListenerSet then
        perPlayerListenerSet = {}
        self._globalState.perPlayerListenerSet[player] = perPlayerListenerSet
    end
    perPlayerListenerSet[callback] = true
    if immediatelyCallListener then
        task.spawn(callback, self:GetFor(player))
    end
    return function()
        self._connectedListeners[callback] = nil
        perPlayerListenerSet[callback] = nil
        if
            not next(perPlayerListenerSet)
            and self._globalState.perPlayerListenerSet[player]
                == perPlayerListenerSet
        then
            self._globalState.perPlayerListenerSet[player] = nil
        end
    end
end

function State.Destroy(self: State)
    for listener in self._connectedListeners do
        self._globalState.listenerSet[listener] = nil
        for _, perPlayerListenerSet in self._globalState.perPlayerListenerSet do
            perPlayerListenerSet[listener] = nil
        end
    end
    table.clear(self._connectedListeners)
end

type State = typeof(State.new("", nil))

return State
