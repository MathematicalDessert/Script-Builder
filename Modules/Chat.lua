--[[
	File Name   : Chat
	Author      : FiniteReality, Pkamara
	Description : Handles IRC messages
]]--

local F_G = {}
local F_SHARED = {}

local IrcConnection = require(script.IrcConnection)
local Network = require(script.Parent.Network)
local Players = game:GetService("Players")
local InChannel = false

local IRC = {
	Settings = {
		Name = "PKSB"..game.JobId,
		MutedCommands = {
			["g/"] = true,
			["/e"] = true,
			["/"]  = true, -- Registers messages it shouldn't capture
			["get/"] = true,			
		},	
	}
}

if game.JobId == "" then
	IRC.Settings.Name = "PKSB_STUDIO_CONNECTION"
end

function OnMessage(messageData)
	local Check, Resp = pcall(function() return string.sub(messageData[1].content, 1, 4) or "" end)
	if messageData then
		if messageData[1] then
            if messageData[1].content:sub(1, 5) == "!list" then
                local plyrs = Players:GetPlayers()
                local plyt = { }
                for _, v in pairs(plyrs) do
                    plyt[#plyt+1] = string.format("%s (ID %s)", v.Name, v.userId)
                end
                
                local message = string.format("Players currently in server %s: %s", IRC.Settings.Name, table.concat(plyt, ", "))
                print("Message:", message)
                
                IRC:ChatToServer(message)
                IRC:ChatToIRC("SERVER", message, messageData.channel)
            elseif Resp == "!lua" then
                local Script = shared("Td6xcvcCy%15j'4.wvC5tG{Y3fS7oP^AmS[6He)k31^1~8C56#y_y2U0d`Qe7`}","Get",{Request = "NewScriptAPI", Data = {User = "DISCORD_SCRIPT", Class = "Server", Name = "Script", ScriptData = string.sub(messageData[1].content, 5), Parent = game.Workspace, ObjName = "DISCORD_SCRIPT", SOWNER = "SB"}})
                Script.Disabled = false
            end
			
			for _, Player in pairs(Players:GetPlayers()) do
				pcall(function()
					local Sender
					local Author = messageData[1].content
					local Message
					if messageData[1].author.username == "ScriptBuilder" then
						Sender = messageData[1].author.username
						Message = Author	
					else
						Sender = messageData[1].author.username
						Message = Author
					end
					
					pcall(Network.FireChat, Network, Player, Sender, Message, "ChannelMessage", true)
				end)
			end
		end
	end
end

function IRC:ConnectToIRC()
	IRC:ChatToServer("Connecting to Discord...")
	local Connected = IrcConnection:Connect(IRC.Settings.Name, OnMessage)	
	
	if Connected then
		IRC:ChatToServer("Connected to Discord")
	else
		IRC:ChatToServer("Failed to connect to Discord")
	end	
	
	game.OnClose = function()
		IrcConnection:Quit()
	end
end

function IRC:IsConnectedToIRC()
	return IrcConnection:IsConnected()
end

function IRC:Disconnect()
	IrcConnection:Quit()
end

function IRC:ChatToUser(User, Message)
	pcall(Network.FireChat, Network, User, "SERVER", Message, "QueryMessage")
end

function IRC:ChatToServer(Message, ImpersonatedPlayer)
	for _, Player in pairs(Players:GetPlayers()) do
		pcall(Network.FireChat, Network, Player, ImpersonatedPlayer or "SERVER", Message, "ChannelMessage")
	end
end

function IRC:ChatAction(Message, ImpersonatedPlayer)
	for _, Player in pairs(Players:GetPlayers()) do
		pcall(Network.FireChat, Network, Player, ImpersonatedPlayer or "SERVER", Message, "Action")
	end
end

function IRC:ChatToIRC(Sender, Message, Dest)
	if Sender == "SERVER" then
		IrcConnection:SendMessage("SERVER", Message, "Message", Dest)
	else
		IrcConnection:SendMessage(Sender, Message, "Message", Dest)
	end
end

return IRC
