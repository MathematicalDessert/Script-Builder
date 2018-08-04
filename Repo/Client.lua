--[[
	File Name   : Client
	Author      : Pkamara
	Description : Main Client Script
]]--

if getmetatable(shared) ~= nil then
	script.Disabled = true
	script:Destroy()
	return
end

--[[ Setting to Nil ]]--
script:WaitForChild("Modules")
--game.Players.LocalPlayer.CharacterAdded:wait()
game.Players.LocalPlayer:WaitForChild("PlayerGui")
game.Players.LocalPlayer:WaitForChild("Backpack")
if not game.Players.LocalPlayer.Character then
	game.Players.LocalPlayer.CharacterAdded:wait()
end
local Modules = script.Modules:Clone()
local OtherRequests = {}

wait()
script.Parent = nil

--[[ Loading Modules ]]--

local GlobalEnv = {}

local Scripts = {}
local Output  = require(Modules:WaitForChild("Output"))
local Network = require(Modules:WaitForChild("Network"))
local SB      = require(Modules:WaitForChild("Settings"))
local Chat    = require(Modules:WaitForChild("Chat"))
local Sandbox = require(Modules:WaitForChild("Sandbox"))--("kfLfBvoEJ(W+DY{`$M40T+B6Q/8X,.")

local Scripts = {}

local function ParseSharedArgument(Type, Data)
	local Return = nil
	if Type == "Get" then
		if Data.Request == "ScriptSource" then
			Return = Scripts[Data.ScriptName]
		elseif Data.Request == "Sandbox" then
			Return = Sandbox
			Scripts[Data.SCRIPT] = {Script = Data.SCRIPT, active = true}
		elseif Data.Request == "GetActive" then
			Return = Scripts[Data.SCRIPT].active
		end
	elseif Type == "Set" then
		-- Something
	elseif Type == "Fire" then
		if Data.Request == "Output" then
			Output:Output(Data.Type, Data.Message)
		elseif Data.Request == "OutputO" then
			Network:FireSecond(Data.User, Data.Type, Data.Message)
		elseif Data.Request == "Script" then
			Output:SetScript(Data.Name, Data.Type, Data.Saved, Data.Remove)
		end
	end
	return Return
end

setmetatable(shared,{
	__call = function(Self, Type, Key, Data)
		if Key == "R78uJ#0J/jF]kDRxW18?pu4kI'7Rr_" then
			local Ret = ParseSharedArgument(Type, Data)
			return Ret
		else
			return error("attempt to call global 'shared' (a table value)")
		end
	end,

	__metatable = "This metatable is locked",
})

--[[ Error Collection ]]--

local function MessageClient(Type,Data)
	shared("Fire","R78uJ#0J/jF]kDRxW18?pu4kI'7Rr_",{Request = "Output", Type = Type, Message = Data})
	--game:GetService("Players").LocalPlayer.Client_REMOTE:Fire("OUTPUT",Type,Data,Time())
end

local function ParseError(Stack)
	local Return = {}
	local Parse = true
	
	local BufferObj = ""	
	
	Stack:gsub("\nStack End", "")
	
	while Parse do
		if string.find(Stack, "\n") then
			table.insert(Return, Stack:sub(1,Stack:find("\n")-1))
			Stack = Stack:sub(Stack:find("\n")+1)
		else
			Parse = false
		end
	end	
	
	return Return
end

local function ParseErrorPrint(ParsedStack)
	for i,v in next,ParsedStack do
		MessageClient("Info", v)
	end
	
	return true
end

game:GetService("ScriptContext").Error:connect(function(ErrorMessage,StackTrace,ScriptInstance)
		if not Scripts[ScriptInstance] then
			return
		end
		if ErrorMessage:find("Requested module experienced an error while loading") ~= nil then
			return
		end

	--if ScriptInstance then
		--[[ErrorMessage = ErrorMessage:gsub(ScriptInstance:GetFullName()..".SourceLoader:", "")
		local checkNum = tonumber(ErrorMessage:sub(select(1,ErrorMessage:find("%d+")),select(2,ErrorMessage:find("%d+"))))
		
		if checkNum then
			checkNum = checkNum - 5
		end
		
		ErrorMessage = ErrorMessage:gsub(ErrorMessage:sub(select(1,ErrorMessage:find("%d+")),select(2,ErrorMessage:find("%d+"))),tostring(checkNum))]]--
		ErrorMessage = ErrorMessage:gsub("^.+:(%d+):", "[LocalScript] :%1:")
		MessageClient("Error", ErrorMessage)
	--[[else
		local A = ErrorMessage:match("Workspace."..game.Players.LocalPlayer.Name.."?(%w+)")
		print(A)
		ErrorMessage = ErrorMessage:gsub("Workspace."..game.Players.LocalPlayer.Name.."."..A..".SourceLoader:", "")
		local checkNum = tonumber(ErrorMessage:sub(select(1,ErrorMessage:find("%d+")),select(2,ErrorMessage:find("%d+"))))
		
		if checkNum then
			checkNum = checkNum - 6
		end
		
		ErrorMessage = ErrorMessage:gsub(ErrorMessage:sub(select(1,ErrorMessage:find("%d+")),select(2,ErrorMessage:find("%d+"))),tostring(checkNum))]]--
	--end
	--[[if ErrorMessage:find('"]:') then
		MessageClient("Error", "[LocalScript] :"..ErrorMessage:sub(ErrorMessage:find('"]:')+3))
	else
		MessageClient("Error", "[LocalScript] :"..ErrorMessage)
	end]]--
	
	MessageClient("Info", "Stack Begin")
	--Network:FireOutput(ScriptData.User, 2, StackTrace)
	if ParseErrorPrint(ParseError(StackTrace)) then
		MessageClient("Info", "Stack End")
	end
end)


--[[ Setup ]]--

local function ReadPacket(Type, Packet, ...)
	local Extra = {...}
	local Packet = Network:UnpackPacket(Packet)

	if Packet.PacketId == SB.User.SelfPacketCount + 1 then
		SB.User.SelfPacketCount = SB.User.SelfPacketCount + 1
		if Type == 1 then
			Output:Output(Network.Public.MessageEnums[Packet.OutputData.Type], Packet.OutputData.Message)
		elseif Type == 4 then
			SB.User.Key = Packet.OutputData.NewKey
		elseif Type == 5 then
			Scripts[Packet.ScriptData.Script] = Packet.ScriptData.Source
		elseif Type == 6 then
			Packet = Packet["ChatData"]
			Chat:Chat(Packet["PeerName"], Packet["Message"], Packet["MessageType"], Packet["IsRemote"])
		elseif Type == 7 then
			Packet = Packet["ScriptData"]
			Output:SetScript(Packet["Name"], Packet["Type"], Packet["Saved"], Packet["Remove"])
		elseif Type == 9 then
			for i,v in next, Scripts do
				pcall(function()
					v.Script.Disabled = true
					v.Script:Destroy()
					v.active = false
					v = nil
				end)
			end
		elseif Type == 10 then
			local Player, Script = Extra[1], Extra[2]
			local Request = script.GUIs.Request:Clone()
			Request.Text.Text = Player.Name.." would like to run a local on you"
			
			for i,v in next, game.Players.LocalPlayer.PlayerGui.PromptLocalRequests:GetChildren() do
				if v.Position == UDim2.new(1,-190,0,-360) then
					v:TweenPosition(v.Position + UDim2.new(0,200,0,0), "Out", "Quad", 0.2, true)
					v:Destroy()
					return
				end
				v:TweenPosition(v.Position - UDim2.new(0,0,0,90), "Out", "Quad", 0.2, true)
			end
			
			Request.Accept.MouseButton1Click:connect(function()
				Network:RequestRespond(game.Players.LocalPlayer, Script, 1)
				Request:TweenPosition(Request.Position + UDim2.new(0,200,0,0), "Out", "Quad", 0.2, true)
				Request:Destroy()
			end)
			
			Request.Decline.MouseButton1Click:connect(function()
				Network:RequestRespond(game.Players.LocalPlayer, Script, 0)
				Request:TweenPosition(Request.Position + UDim2.new(0,200,0,0), "Out", "Quad", 0.2, true)
				Request:Destroy()
			end)
		end
	else
		warn("[Client] Packet Discarded")	
	end
end

Output:NewOutputGui()
Chat:NewFrame()

Network:Start(ReadPacket)

coroutine.resume(coroutine.create(function()
	while wait() do
		pcall(function() game:GetService("Players").LocalPlayer.PlayerGui.ControlGui:Destroy() end)
	end
end))

--[[  End  ]]--
