--[[
    File Name   : Network
    Author      : Pkamara
    Description : Main Networking Script
]]--

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
            [1] = true, -- Print
            [2] = true, -- Info
            [3] = true, -- Warn
            [4] = true, -- Error
			[5] = true, -- Get
        }
    },

    Private = {},
}

function Module:Start(MainCapture)
    local Folder = Instance.new("Folder", game:GetService("ReplicatedStorage"))
    Folder.Name  = "Networking"
    
    local Router = Instance.new("RemoteEvent", Folder)
    Router.Name  = "Router"
    
    self.Public.Router = Router
    
    Module:Capture(Router, MainCapture)
end

function Module:UnpackPacket(User, Packet)
	local SBUser = SB:GetUser(User)
	--local Packet = Encrypt:Decode(GetNumbers(SBUser:GetProperty("Key")),GetNumbers(SB.ServerData.Data.Security.ServerKey), Packet)
	local JSON  = game:GetService("HttpService"):JSONDecode(Packet)
	
	--SBUser:SetProperty("PacketCount", SBUser:GetProperty("PacketCount") + 1)
	
	return JSON
end

function Module:Capture(Object, Function)
    Object.OnServerEvent:connect(Function)
end

function GetNumbers(Char)
	local num = ""
	for i = 1, #Char do
		num = num..string.byte(Char:sub(i,i))
	end
	
	return tonumber(num)
end

function Module:NewPacket(User, Data)
    local SBUser    = SB:GetUser(User)
    local RawPacket = game:GetService("HttpService"):JSONEncode(Data)
    --local EncPacket = Encrypt:Encode(GetNumbers(SBUser:GetProperty("Key")),GetNumbers(SB.ServerData.Data.Security.ServerKey), RawPacket)
	--print(Encrypt:Decode(GetNumbers(SBUser:GetProperty("Key")),GetNumbers(SB.ServerData.Data.Security.ServerKey), EncPacket))

    --return EncPacket
	return RawPacket
end

function Module:FirePacket(User, Type,Packet)
	if self.Public.Router then
		self.Public.Router:FireClient(User, Type, Packet) 
	end
end

function Module:FireOutput(User, Type, Message)
    local SBUser   = SB:GetUser(User)
    
    local Packet = Module:NewPacket(User,{
        PacketId = SBUser:GetProperty("PacketCount") + 1,
        
        OutputData = {
            Type = Type,
            Message = Message,
        },
    })

    SBUser:SetProperty("PacketCount", SBUser:GetProperty("PacketCount") + 1)
    Module:FirePacket(User, 1, Packet)
    
    return
end

function Module:FireNOL(User)
    local SBUser   = SB:GetUser(User)
    
    local Packet = Module:NewPacket(User,{
        PacketId = SBUser:GetProperty("PacketCount") + 1,
    })

    SBUser:SetProperty("PacketCount", SBUser:GetProperty("PacketCount") + 1)
    Module:FirePacket(User, 9, Packet)
    
    return
end

function Module:FireChat(User, PeerName, Message, MessageType, IsRemote)
    local SBUser = SB:GetUser(User)
	
	if not SBUser then
		return
	end
    
    local Packet = Module:NewPacket(User,{
        PacketId = SBUser:GetProperty("PacketCount") + 1,
        
        ChatData = {
            PeerName = PeerName,
			Message = Message,
			MessageType = MessageType,
			IsRemote = IsRemote
        },
    })

    SBUser:SetProperty("PacketCount", SBUser:GetProperty("PacketCount") + 1)
    Module:FirePacket(User, 6, Packet)
    
    return
end

function Module:FireScriptPanel(User, Name, Type, Saved, Remove)
    local SBUser = SB:GetUser(User)
	
	if not SBUser then
		return
	end
    
    local Packet = Module:NewPacket(User,{
        PacketId = SBUser:GetProperty("PacketCount") + 1,
        
        ScriptData = {
            Name = Name,
			Type = Type,
			Saved = Saved,
			Remove = Remove
        },
    })

    SBUser:SetProperty("PacketCount", SBUser:GetProperty("PacketCount") + 1)
    Module:FirePacket(User, 7, Packet)
    
    return
end

function Module:FireScriptSource(User, Script, Source)
	    local SBUser   = SB:GetUser(User)
    
    local Packet = Module:NewPacket(User,{
        PacketId = SBUser:GetProperty("PacketCount") + 1,
        
        ScriptData = {
            Script = Script,
            Source = Source,
        },
    })

    SBUser:SetProperty("PacketCount", SBUser:GetProperty("PacketCount") + 1)
    Module:FirePacket(User, 5, Packet)
    
    return
end

function Module:FireNewKey(User, Key)
    local SBUser   = SB:GetUser(User)
    
    local Packet = Module:NewPacket(User, {
        PacketId = SBUser:GetProperty("PacketCount") + 1,
        
        OutputData = {
            NewKey = Key,
        },
    })

    SBUser:SetProperty("PacketCount", SBUser:GetProperty("PacketCount") + 1)
    Module:FirePacket(User, 2, Packet)
end

return Module
