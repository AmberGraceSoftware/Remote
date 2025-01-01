--!strict
local RunService = game:GetService("RunService")
local TIMEOUT = 60
local function createOrWaitFor(
    parent: Instance,
    childName: string,
    className: string
): Instance
    local child = parent:FindFirstChild(childName) :: any
    if not child then
        if RunService:IsServer() then
            child = Instance.new(className)
            child.Name = childName
            child.Parent = parent
        else
            child = parent:WaitForChild(childName, TIMEOUT)
            if not child then
                error(
                    "Timed out while waiting for Remote object "
                        .. parent:GetFullName()
                        .. "."
                        .. childName
                        .. "; perhaps"
                        .. "it was never referenced or connected to on the server?"
                )
            end
        end
    end

    return child
end

local function getRootContainer()
    return createOrWaitFor(script.Parent, "Remotes", "Folder")
end

local function getClassNameContainer(className: string)
    return createOrWaitFor(getRootContainer(), className, "Folder")
end

--[[
    Utility function that helps generate or wait for namespaced remote objects.
]]
local function GetRemoteInstance(className: string, name: string)
    return createOrWaitFor(getClassNameContainer(className), name, className)
end

return GetRemoteInstance
