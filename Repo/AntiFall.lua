wait()
script.Parent = nil

local Player = game.Players.LocalPlayer

game:GetService("RunService").Stepped:connect(function()
	if Player and Player.Character and Player.Character.Parent == workspace and Player.Character:FindFirstChild("HumanoidRootPart") ~= nil then
		local char = Player.Character.HumanoidRootPart.CFrame.p
		
		if char.Y <= -300 then
			Player.Character.Torso.Velocity = Vector3.new(0,0,0)
			Player.Character:MoveTo(Vector3.new(0,5,0))
		end
	end
end)
