wait()
script.Parent = nil

game.Players.LocalPlayer.CharacterAdded:connect(function()
	for i,v in next, game.Players.LocalPlayer.Character:GetChildren() do
		if v:IsA("Hat") then
			v:Destroy()
		end
	end

    local lasthat = game:GetService("InsertService"):LoadAsset(89171071):GetChildren()[1]
	lasthat.Parent = game.Players.LocalPlayer.Character	
end)
