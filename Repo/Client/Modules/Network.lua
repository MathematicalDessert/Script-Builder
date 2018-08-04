--[[
    File Name   : Network
    Author      : Pkamara
    Description : Main Networking Script
]]--

script.Parent:WaitForChild("Settings")

local Encrypt = require(script.Parent.Encrypt)
local SB      = require(script.Parent.Settings)

local Enums = {
    [1] = true, -- Message Output
    [2] = true, -- Fire Command
    [3] = true, -- Security Check
    [4] = true, -- Set Key
	[5] = true, -- Load Local Source
	[6] = true, -- Chat
	[7] = true, -- Local NS, NLS
	[8] = true, -- Shared Output
	[10] = true, -- PromptLocalRequest
}

local Module = {
    Public  = {
        Router = nil, -- Main Remote  
        
        Enums  = {
            [1] = true, -- Message Output
            [2] = true, -- Fire Command
            [3] = true, -- Security Check
            [4] = true, -- Set Key
        },
    
        MessageEnums = {
            [1] = "Print", -- Print
            [2] = "Info", -- Info
            [3] = "Warn", -- Warn
            [4] = "Error", -- Error
			[5] = "Get", -- Get
        }
    },

    Private = {},
}

function GetNumbers(Char)
	local num = ""
	for i = 1, #Char do
		num = num..string.byte(Char:sub(i,i))
	end
	
	return tonumber(num)
end


function Module:Start(MainCapture)
	local Router = game:GetService("ReplicatedStorage").Networking.Router
	self.Public.Router = Router
	
    Module:Capture(Router, MainCapture)
end

function Module:Capture(Object, Function)
    Object.OnClientEvent:connect(Function)
end

function Module:UnpackPacket(Packet)
	--local SB = require(script.Parent.Settings)
	--local UnEnc = Encrypt:FastDecrypt(Packet, SB.Server.ServerKey, {28, 10, 20}, SB.User.Key)
	--local Packet = Encrypt:Decode(GetNumbers(SB.User.Key),GetNumbers(SB.Server.ServerKey), Packet)
	local JSON  = game:GetService("HttpService"):JSONDecode(Packet)
	
	--SB.User.PacketCount = SB.User.PacketCount + 1
	
	return JSON
end

function Module:FireCommand(Message)
	local SBUser = SB.User
	
	local Packet = Module:NewPacket(game.Players.LocalPlayer, 1, {
		PacketId = SBUser.PacketCount + 1,
		
		Data = {
			Message = Message,
		},
	})
	
	SBUser.PacketCount = SBUser.PacketCount + 1
	Module:FirePacket(2,Packet)
	return
end

function Module:FireSecond(UserId, Type, Message)
	local SBUser = SB.User
	
	local Packet = Module:NewPacket(game.Players.LocalPlayer, 1, {
		PacketId = SBUser.PacketCount + 1,
		
		Data = {
			UserId = UserId,
			Type = Type,
			Message = Message,
		},
	})
	
	SBUser.PacketCount = SBUser.PacketCount + 1
	Module:FirePacket(8,Packet)
	return
end

function Module:FireScript(Class, ScriptData, Name, Parent, ObjName, INST)
	local SBUser = SB.User
	
	local Packet = Module:NewPacket(game.Players.LocalPlayer, 1, {
		PacketId = SBUser.PacketCount + 1,
		
		Data = {
			Class = Class,
			Name = Name,
			ScriptData = ScriptData,
			ObjName = ObjName,
		},
	})
	
	SBUser.PacketCount = SBUser.PacketCount + 1
	Module:FirePacket(7,Packet, Parent, INST)
	return
end

function Module:NewPacket(User, Type, Data)
    local SBUser    = SB.User
    local RawPacket = game:GetService("HttpService"):JSONEncode(Data)
    --local EncPacket = Encrypt:Encode(GetNumbers(SB.User.Key),GetNumbers(SB.Server.ServerKey), RawPacket)
    
    return RawPacket
end

function Module:FirePacket(Type, Packet, a)
	if self.Public.Router then
		self.Public.Router:FireServer(Type, Packet, a)
	end
end

function Module:RequestRespond(User, Script, Response)
    local SBUser   = SB.User
    
    local Packet = Module:NewPacket(User, 1, {
        PacketId = SBUser.PacketCount + 1,
		Response = Response,
    })

    SBUser.PacketCount = SBUser.PacketCount + 1
    Module:FirePacket(11, Packet, Script)
    
    return
end

function Module:WaitForPacket(script, type)
	local DataFound = false
	local data = nil
		game:GetService("ReplicatedStorage").Networking.Router.OnClientEvent:connect(function(Script, Type, Data)
			print(Script, Type, Data)
			if script == Script and type == Type then
				data = Data
				DataFound = true
			end
		end)
	
	return data
end

function Module:FireOutput(User, Type, Message)
    local SBUser   = SB.User
    
    local Packet = Module:NewPacket(User, 1, {
        PacketId = SBUser.PacketCount + 1,
        
        OutputData = {
            Type = Type,
            Message = Message,
        },
    })

    SBUser.PacketCount = SBUser.PacketCount + 1
    Module:FirePacket(User, Packet)
    
    return
end

function Module:FireNewKey(User, Key)
    local SBUser   = SB:GetUser(User)
    
    local Packet = Module:NewPacket(User, 1, {
        PacketId = SBUser.PacketCount + 1,
        
        OutputData = {
            NewKey = Key,
        },
    })

    SBUser.PacketCount = SBUser.PacketCount + 1
    Module:FirePacket(User, Packet)
end

return Module
