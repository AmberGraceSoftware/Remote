--!strict
local Remote = require(game.ReplicatedStorage.Packages.Remote)

return function()
    it("maps existing API methods to original library type", function()
        local FooRemotes = Remote.Namespace("Foo") :: any
        for key, object in Remote :: any do
            local namespaced = FooRemotes[key]
            expect(typeof(namespaced)).to.equal(typeof(object))
        end
    end)
    it("maps nonexisting API methods to nil", function()
        local FooRemotes = Remote.Namespace("Foo") :: any
        expect(FooRemotes["DOES_NOT_EXIST!"]).to.equal(nil)
    end)
end