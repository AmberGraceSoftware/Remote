--!strict
return function()
    it("requires the full library runtime with no errors", function()
        require(game.ReplicatedStorage.Packages.Remote)
    end)
end
