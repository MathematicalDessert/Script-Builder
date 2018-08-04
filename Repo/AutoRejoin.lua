coroutine.yield()
script.Parent = nil
local user = game:service'Players'.LocalPlayer
local users = game:service'Players'
local m = Instance.new("Message",workspace)
pcall(function() --acts like a kick somewhat
        user.Parent = nil
        user.Parent = users
        user.Parent = nil
end)
m.Text = "Waiting for server close"
repeat wait() until #game:GetService("NetworkClient"):GetChildren() == 0;
wait(1)
m.Text =
[[
        Rejoining...
]]
game:service'TeleportService':Teleport(game.PlaceId)
