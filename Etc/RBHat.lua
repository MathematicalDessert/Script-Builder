wait()
script.Parent = nil
lasthat = nil

game.Players.LocalPlayer.CharacterAdded:connect(function()
	for i,v in next, game.Players.LocalPlayer.Character:GetChildren() do
		if v:IsA("Hat") then
			v:Destroy()
		end
	end

	lasthat = game:GetService("InsertService"):LoadAsset(2972302):GetChildren()[1]
	lasthat.Parent = game.Players.LocalPlayer.Character	
end)
