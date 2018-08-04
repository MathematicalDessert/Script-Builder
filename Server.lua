--[[
	File Name   : Server
	Author      : Pkamara
	Description : Main Server Script
]]--

--[[ Setting Script to nil ]]--

wait()
script.Parent = nil

--[[ Loading Required Modules ]]--

local BannedNames = {"Pelanyo_Kamara", "Kamara_Pelanyo", "Pkamara_", "_Pkamara"}

local Modules = script.Modules

local LUNQ     = require(Modules.LUNQ)
local Encrypt  = require(Modules.Encrypt)
local Network  = require(Modules.Network)
local Logging  = require(Modules.Logging)
local SB       = require(Modules.Settings)
local Chat     = require(Modules.Chat)
local Minify   = require(Modules.Minify)
local Sandbox  = require(Modules.Sandbox)("BT5ERGW23FAIPg6oPns4FYjuNaMcnYlQ")
local SHA      = require(Modules.SHA)

local game = Game
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

Logging.DEBUG_ENABLED = false

--[[ Register Core Methods ]]--

function SB:GetBans()
	local Link = "http://pkamarasb.azurewebsites.net/BanAPI/GetBanList"
	local Check, Data = pcall(function() return HttpService:GetAsync(Link, false) end)
	
	if Check then
		return HttpService:JSONDecode(Data)
	end
	
	return {}
end

function SB:UpdateBans()
	for i,v in next, SB:GetBans() do
		SB.ServerData.BannedUsers[v.UserId] = {Username = v.Username, Reason = v.Reason}
	end
end

function SB:CheckUser(Player)
	if self.ServerData.Settings.Private then
		if not self.ServerData.AllowedPriv[Player.userId] then
			return true
		end
	end
	if self.ServerData.BannedUsers[Player.userId] then
		return true
	end
	return false
end

function SB:GetSandbox()
	return self.Sandbox.Data.Module
end

function SB:RegisterNewUser(Player)
	coroutine.resume(coroutine.create(function() SB:GetBans() end))
	if SB.ServerData.Settings.PrivSB then
		if not SB.ServerData.AllowedPriv[Player.userId] and not Player:GetRankInGroup(2574296) >= 2 then
			Instance.new("Message", Player.PlayerGui).Text = "You are not allowed here! Teleporting you to public SB"
			wait()
			game:GetService("TeleportService"):Teleport(191240586, Player)
		end
	end

	for i,v in next, BannedNames do
		local a = string.lower(v)
		if string.match(Player.Name, a) then
			v:Kick("You are not allowed this username")
		end
	end

	--[[ Checking User ]]--

	if SB:CheckUser(Player) then
		Logging.Warn(("Player tried to join, Not allowed. [%s : %s]"):format(Player.Name, Player.userId))
		return Player:Kick("[Script Builder] You are not allowed in this place")
	end
	
	if SB.ServerData.Settings.Updating then
		return Player:Kick("We're updating the SB!")
	end

	Logging.Info(("Player join, passed trust check [%s : %s]"):format(Player.Name, Player.userId))

	--[[ Making Player Table ]]--

	local PlayerTable = self.UserData[Player.userId]	
	
	if not self.UserData[Player.userId] then
		self.UserData[Player.userId] = {} -- Registered the table
	
		PlayerTable = self.UserData[Player.userId]
		PlayerTable.ScriptingDisabled = false
	
		PlayerTable.Data = setmetatable({
			Settings = {      -- User Settings
				Sandbox = {}, -- Sandbox Settings
				Builder = {   -- Script Builder Settings
				    Key  = "DefaultKey",
					Editing = false,
					PacketCount = 0,
					ClientPacketCount = 0,
					Loaded = false,
                    Muted = false,
				},
			},
			Scripts  = {},  -- Script Data
			Buffer   = {    -- Temporary Data
				Scripts = { -- Running scripts and so forth
					Server = {},
					Client = {},
				},
			},
		},{
			__metatable = "This metatable is Locked",
		})
	
		--[[ Registering Player Table Methods ]]--
	
		function PlayerTable:SaveData()
			Logging.Debug(("Trying to save Script Builder Data [%s : %s]"):format(Player.Name, Player.userId))
	
			local JSONENCODE = HttpService.JSONEncode
			local DataStore  = game:GetService("DataStoreService"):GetDataStore(("%s_%s"):format(Player.userId, SB.ServerData.Data.DataStore.UserStorePrefix))
			
			self.Buffer = {
				Scripts = { -- Running scripts and so forth
					Server = {},
					Client = {},
				},
			}
				
			local UserData   = HttpService:JSONEncode(self)

			DataStore:SetAsync("USERDATA", UserData)
		end
	
		function PlayerTable:LoadData()
			coroutine.resume(coroutine.create(function()
				Logging.Debug(("Trying to load Script Builder Data [%s : %s]"):format(Player.Name, Player.userId))
		
				local JSONDECODE = HttpService.JSONDecode
				local DataStore  = game:GetService("DataStoreService"):GetDataStore(("%s_%s"):format(Player.userId, SB.ServerData.Data.DataStore.UserStorePrefix))
				local UserData   = nil
				local NewUData
				
				local succ, err = pcall(function()
					NewUData   = DataStore:GetAsync("USERDATA")
				end)
				if not succ then
					Logging.Warn("Could not load data for user [%s : %s] (%s)", Player.Name, Player.userId, err)
					return
				end
		
				if not NewUData then
				   Logging.Info("No data to load for user [%s : %s]", Player.Name, Player.userId)
				   return
				end
		
				UserData   = JSONDECODE(HttpService, NewUData)
		
				for i,v in next,UserData.Data.Scripts do
					if v.Saved then
						PlayerTable.Data.Scripts[i] = v
						Network:FireScriptPanel(PlayerTable:GetPlayer(), i, "NotRunning", true, false)				
					end
				end
				Logging.Info("Successfully loaded data for[%s : %s]", Player.Name, Player.userId)	
			end))
		end
	
		function PlayerTable:IsEditing()
			return PlayerTable:GetProperty("Editing")
		end
	
		function PlayerTable:GetProperty(Name)
			return self.Data.Settings.Builder[Name]
		end
	
		function PlayerTable:SetProperty(Name, Object)
			self.Data.Settings.Builder[Name] = Object
			return
		end
		
		function PlayerTable:SetBufferObject(Name, Object)
			self.Data.Buffer[Name] = Object
			return
		end
		
		function PlayerTable:GetBufferObject(Name)
			return self.Data.Buffer[Name]
		end
		
		function PlayerTable:GetPlayer()
			return Player
		end
		
		function PlayerTable:SetScriptBuffer(Script, Data)
			if Script:IsA("LocalScript") then
				self.Data.Buffer.Scripts.Client[Script] = Data
				return
			end
			self.Data.Buffer.Scripts.Server[Script] = Data
			return
		end
	
		function PlayerTable:GetScriptCount(Class)
			local cnt = 0
			if Class == "Server" then
				for i,v in next, self.Data.Buffer.Scripts.Server do
					cnt = cnt + 1
				end
			elseif Class == "Client" then
				for i,v in next, self.Data.Buffer.Scripts.Client do
					cnt = cnt + 1
				end
			end
			
			return cnt
		end
	
		function PlayerTable:GetScriptBuffer(Script)
			return self.Data.Buffer.Scripts.Client[Script] or self.Data.Buffer.Scripts.Server[Script]
		end
	
		function PlayerTable:SetScriptData(Script, Data)
			local Script = self.Data.Scripts[Script]
	
			for i,v in next,Data do
				Script[i] = v
			end
		end
	
		function PlayerTable:GetScriptData(Script, Index)
			local Script = self.Data.Scripts[Script]
	
			return Script[Index]
		end
	
		function PlayerTable:ParseEdit(String)
			if String == "exit/" then
				PlayerTable:SetScriptData(PlayerTable:GetProperty("EditScript"), {Edit = false})
				Network:FireScriptPanel(PlayerTable:GetPlayer(), PlayerTable:GetProperty("EditScript"), "NotRunning", self.Data.Scripts[PlayerTable:GetProperty("EditScript")].Saved, false)
				Network:FireOutput(PlayerTable:GetPlayer(), 3, ("Stopped editing '%s'"):format(PlayerTable:GetProperty("EditScript")))
                PlayerTable:SetProperty("Editing", false)
			elseif String == "clear/" then
				PlayerTable:SetScriptData(PlayerTable:GetProperty("EditScript"), {Source = ""})
				Network:FireOutput(PlayerTable:GetPlayer(), 3, ("Cleared source in '%s'"):format(PlayerTable:GetProperty("EditScript")))
			else
				PlayerTable:SetScriptData(PlayerTable:GetProperty("EditScript"), {Source = PlayerTable:GetScriptData(PlayerTable:GetProperty("EditScript"), "Source")..String.."\n"})
				Network:FireOutput(PlayerTable:GetPlayer(), 3, ("'%s' appended to '%s'"):format(String, PlayerTable:GetProperty("EditScript")))			
			end
		end
		
		--[[ Setup ]]--
	
		PlayerTable:LoadData() -- Loading UserData
	else
		PlayerTable.Data.Settings.Builder.ClientPacketCount = 0
		PlayerTable.Data.Settings.Builder.PacketCount = 0		
		
		for i,v in next, PlayerTable.Data.Scripts do
			if v.Saved then
				Network:FireScriptPanel(Player, i, "NotRunning", true, false)
			else
				Network:FireScriptPanel(Player, i, "NotRunning", false, false)			
			end
		end
	end
	
	if type(Player) ~= "table" then
		if Player.Character == nil then
			Player.CharacterAdded:wait()
		end
	
		if not Player:FindFirstChild("PlayerGui") then
			Player:WaitForChild("PlayerGui")
		end
	
		if not Player:FindFirstChild("Backpack") then
			Player:WaitForChild("Backpack")
		end	
	
		for i,v in next,script.Repo:GetChildren() do
			if v.Name ~= "AutoRejoin" then
		 		local Clone    = v:Clone()
				Clone.Disabled = false	 		
				Clone.Parent   = Player:FindFirstChild("PlayerGui") or Player:FindFirstChild("Backpack")
		 		--Sandbox:LockInstance(v)
			end
	 	end
	
		if self.ServerData.HaxUsers[Player.userId] then
	 		local Clone    = script.Etc.BossHat:Clone()
	 		Clone.Parent   = Player:WaitForChild("PlayerGui")
	 		Clone.Disabled = false
	 		--Sandbox:LockInstance(Clone)
		end
		
		if self.ServerData.RBHats[Player.userId] then
	 		local Clone    = script.Etc.RBHat:Clone()
	 		Clone.Parent   = Player:WaitForChild("PlayerGui")
	 		Clone.Disabled = false
	 		--Sandbox:LockInstance(Clone)
		end
		
		local Chatted
		
		Chatted = function(Message)
	        if PlayerTable.Data.Settings.Builder.Muted then
	            return
	        end
			if Message:sub(1, 4) == "/me " then
				Chat:ChatToIRC(Player.Name.." "..Message:sub(5), ".")
				Chat:ChatAction(Message:sub(5), Player.Name)
			elseif Message:sub(1,3) == "/e " then
				local act = nil
				local sav = Message
				Message = Message:sub(4)
				if Message == "dance" or Message == "dance2" or Message == "dance3" then
					act = "dances"
				elseif Message == "laugh" then
					act = "laughs"
				elseif Message == "wave" then
					act = "waves"
				elseif Message == "cheer" then
					act = "cheers"
				end
				if act ~= nil then
					Chat:ChatToIRC(Player.Name.." "..act, ".")
					Chat:ChatAction(act, Player.Name)
				end
				Message = sav
			end
			
		    SB:RegisterCaptureFunction(Player, Message)
			for i,v in pairs(Chat.Settings.MutedCommands) do
				if string.sub(string.lower(Message),1,#i) == i then
					return
				end
			end
			
			local WrappedUser = SB:GetUser(Player)
			local IsEdit = WrappedUser:IsEditing()
		
			if (IsEdit and Message:sub(1, 5) == "exit/") then
				PlayerTable.Data.Settings.Builder.Editing = false
				return
			elseif IsEdit then
				return
			end
	
			Chat:ChatToServer(Message, Player.Name)
			Chat:ChatToIRC(Player.Name, Message, "#PkamaraSB")
		end
		
		Player.Chatted:connect(Chatted)
		
		if not SB.ServerData.Settings.PrivSB then
			Network:FireOutput(Player, 5, ("Welcome to MathematicalPie's Public SB!"))
			Chat:ChatToUser(Player, "Welcome to MathematicalPie's Public SB!")
		else
			Network:FireOutput(Player, 5, ("Welcome to MathematicalPie's Private SB!"))
			Chat:ChatToUser(Player, "Welcome to MathematicalPie's Private SB!")
		end
		Network:FireOutput(Player, 5, ("Say g/help for help!"))
		Chat:ChatToServer(Player.Name.." has joined the SB!")
		
		if Chat:IsConnectedToIRC() then
			Logging.Debug("Connected to IRC")
			Chat:ChatToUser(Player, "Connected to #PkamaraSB and #ScriptBuilder")
		else
			Logging.Debug("Not connected to IRC")
			Chat:ChatToUser(Player, "Not connected to IRC")
		end
		Chat:ChatToIRC("SERVER", Player.Name.." has joined the SB!")
		
		for i,v in next, Players:GetPlayers() do
			if v.userId ~= Player.userId then
				pcall(function() Network:FireOutput(v, 5, Player.Name.." has joined the SB!") end)
			end
		end
	end
	
	return PlayerTable
end

function SB:DisconnectUser(Player)
	local User = SB:GetUser(Player)
	pcall(function() User:SaveData() end)
	Logging.Debug(("User Disconnecting [%s : %s]"):format(Player.Name, Player.userId))
	Chat:ChatToServer(Player.Name.." has left the SB!")
	
	Chat:ChatToIRC("SERVER", Player.Name.." has left the SB!")
	
	for i,v in next, Players:GetPlayers() do
		if v.userId ~= Player.userId then
			Network:FireOutput(v, 5, Player.Name.." has left the SB!")
		end
	end
end

function SB:GetCacheSource(Source)
	local Sha = SHA(Source)
	
	local DataStore = game:GetService("DataStoreService"):GetDataStore("CLIENT_CACHE")
	local Sources   = DataStore:GetAsync(Sha)
	
	if not Sources then
		return nil
	else
		return Sources
	end
end

function SB:SetCacheSource(Source, ID)
	local Sha = SHA(Source)
	
	local DataStore = game:GetService("DataStoreService"):GetDataStore("CLIENT_CACHE")
	
	DataStore:SetAsync(Sha, ID)
end

function SB:GetUser(User)
	if not User then
		return error("[Script Builder] Tried to get non-existant player")
	end
	return self.UserData[User.userId]
end

function SB:LoadHttpSource(User, Link)
	local Success, Result = ypcall(function() return HttpService:GetAsync(Link, false) end)

	if self.Cache.Source[Link] and (Result == [[error("NOLIGATE: No key was specified.")]] or Result == [[error("NOLIGATE: Could not find any script with the specified id.")]]) then
		return self.Cache.Source[Link]
	end

	if not Success then
		if self.Cache.Source[Link] then
			return self.Cache.Source
		else
			return Network:FireOutput(User, 4, ("[Script Builder] Internal Source Error, your script failed to load more than twice."):format(Result))
		end
		Logging.Warn(("Failed to load script source [%s : %s : %s]\nReason : %s"):format(User.Name, User.userId, Link, Result))
		Network:FireOutput(User, 4, ("[Script Builder] Failed to load Http Source : %s"):format(Result))
		return 0
	end
	
	self.Cache.Source[Link] = Result

	return Result
end

function Strip_Control_Codes( str )
    local s = ""
    for i in str:gmatch( "%C+" ) do
 	s = s .. i
    end
    return s
end
 
function Strip_Control_and_Extended_Codes(str)
return (str:gsub(".", function(c)
local b = c:byte()
return (b >= 32 and b <= 126 or c == "\n" or c == "\t") and c or ""
end))
end

function SB:LoadLocalSource(User, Source)
	for i,v in next,self.Cache.Client do
		if v.Source == Source then
			return v.Script:Clone()
		end
	end

	--[[local CacheTest = SB:GetCacheSource(Source)
	
	if CacheTest then
		return game:GetService("InsertService"):LoadAssetVersion(tonumber(CacheTest)):FindFirstChild("SourceLoader"):Clone()
	end]]--
	
	Source = Strip_Control_and_Extended_Codes(Source):gsub("[<>]", {["<"]="&lt;",[">"]="&gt;"})

	local ObjectData = [[<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="http://www.roblox.com/roblox.xsd" version="4"> <External>null</External> <External>nil</External> <Item class="ModuleScript" referent="RBX0"> <Properties> <bool name="Disabled">false</bool> <string name="Name">SourceLoader</string> <string name="Source">function Run(Obj) setfenv(0,Obj) setfenv(1,Obj) setfenv(2,Obj) %s end return Run</string> <bool name="archivable">true</bool> </Properties> </Item> </roblox>]]
	
	local Post = {
		["Request"] = "UploadAsset",
		["Data"] = {
			["Username"] = "",
			["Password"] = "",
			["AssetId"] = 492468618,
			["ObjectData"] = tostring(ObjectData:format(tostring(Source)))--:gsub("\n\t", "")
		}
	}	
	
	local OutBox = HttpService:JSONEncode(Post)
	local Query  = HttpService:PostAsync("http://pkamara.azurewebsites.net/API/ROBLOXAction", OutBox, Enum.HttpContentType.ApplicationJson)
	
	local Parse, Result = pcall(function() return HttpService:JSONDecode(Query) end)
	
	if not Parse then
		return SB:LoadLocalSource(User, Source)
	end
	
	local Check = tonumber(HttpService:JSONDecode(Query).AssetVersionId)	

	if type(Check) ~= "number" then
		Logging.Warn(("Failed to load local source [%s : %s]\nReason : %s"):format(User.Name, User.userId, Query))
		Network:FireOutput(User, 4, "[Script Builder] Failed to load LocalScript")
	else
		Logging.Info(("Successfully loaded local source [%s : %s : %s]"):format(User.Name, User.userId, Check))
	end
	
	Check = game:GetService("InsertService"):LoadAssetVersion(Check):FindFirstChild("SourceLoader"):Clone()
	
	--coroutine.resume(coroutine.create(function() SB:SetCacheSource(Source, HttpService:JSONDecode(Query).AssetVersionId) end))

	table.insert(self.Cache.Client, {Source = Source, Script = Check})

	return Check
end

do
	local function ParseGetCommand(self, CommandsStr, User)
		local CommandInfos = { }
		local NextIsConcat = false
		
		for Segment in CommandsStr:gmatch("%S+") do
			local WithoutLast = Segment:sub(1, -2)
			local LastChar = Segment:sub(-1)
			
			local LastIsSlash = LastChar == "\\"
			
			if NextIsConcat then
				NextIsConcat = false
				CommandInfos[#CommandInfos] = CommandInfos[#CommandInfos].." "..(LastIsSlash and WithoutLast or Segment)
			else
				CommandInfos[#CommandInfos+1] = LastIsSlash and WithoutLast or Segment
			end
			
			NextIsConcat = LastIsSlash
		end
		
		for pos = 1, #CommandInfos do
			local CommandInfo = CommandInfos[pos]
			
			Logging.Debug("Parsing command `%s` for user [%s : %s]", CommandInfo, User.Name, User.userId)
			
			local Command, ArgStr = CommandInfo:match("^(.-)/(.*)$")
			local Args
			
			if not Command then
				Command = CommandInfo
			end
			
			if ArgStr then
				Args = { }
				for Argument in ArgStr:gmatch("[^/]+") do
					Args[#Args+1] = Argument
				end
			end
			
			Logging.Debug("Command: `%s` Args: %s (user [%s : %s])", Command, Args and #Args or 0, User.Name, User.userId)
			
			local CommandStruct = LUNQ.FirstOrDefault(self.Buffer.Commands.Get, function(CommandStruct)
				return LUNQ.Any(CommandStruct.Calls, function(call)
					return call == Command
				end)
			end)
		
			if CommandStruct == nil then
			    Logging.Warn("Could not find command `%s` for user [%s : %s]", Command, User.Name, User.userId)
				-- TODO: alert user that the given command could not be found
			else
				local InvokeThread = coroutine.create(CommandStruct.Function)
				local Success, ErrorMessage = coroutine.resume(InvokeThread, User, Args)
				
				if not Success then
					local StackTrace = debug.traceback(InvokeThread)
					Logging.Warn("Could not invoke command `%s` for user [%s : %s]: %s\n%s", Command, User.Name, User.userId, ErrorMessage, StackTrace)
				end
			end
		end
	end
	
	function SB:RegisterCaptureFunction(User, Text)
		wait()
		Logging.Debug("Received chat for user [%s : %s]", User.Name, User.userId)
		
		local WrappedUser = SB:GetUser(User)
		local IsChatting  = WrappedUser:IsEditing()
	
        if WrappedUser.Data.Settings.Builder.Muted then
            return
        end
    
		if IsChatting then
			WrappedUser:ParseEdit(Text)
		end
	
		if not Text or type(Text) ~= "string" then
		    Logging.Warn("Chatted text was nil or not a string for user [%s : %s]", User.Name, User.userId)
			return
		end
	
		Text = Text:gsub("^/e%s*", "") -- Remove "/e" if present
		
		local BaseCommand, CommandsStr = Text:match("^(.-)/(.+)$")
		
		if BaseCommand and CommandsStr then
			Logging.Debug("Found base command `%s` for user [%s : %s]", BaseCommand, User.Name, User.userId)
			local BaseCommandLower = BaseCommand:lower()
			if BaseCommandLower == "get" or BaseCommandLower == "g" then
				ParseGetCommand(self, CommandsStr, User)
			else
				Logging.Debug("Command: `%s` Args: `%s` (user [%s : %s])", BaseCommand, CommandsStr, User.Name, User.userId)
				local CommandStruct = LUNQ.FirstOrDefault(self.Buffer.Commands.Gen, function(CommandStruct)
					return LUNQ.Any(CommandStruct.Calls, function(call)
						return call == BaseCommandLower
					end)
				end)
			
				if CommandStruct == nil then
					Logging.Warn("Could not find command `%s` for user [%s : %s]", BaseCommand, User.Name, User.userId)
				else
					local InvokeThread = coroutine.create(CommandStruct.Function)
					local Success, ErrorMessage = coroutine.resume(InvokeThread, User, CommandsStr)
					
					if not Success then
						local StackTrace = debug.traceback(InvokeThread)
						Logging.Warn("Could not invoke command `%s` for user [%s : %s]: %s\n%s", BaseCommand, User.Name, User.userId, ErrorMessage, StackTrace)
					end
				end
			end
		else
			Logging.Debug("Could not parse message `%s` into command for user [%s : %s]", Text, User.Name, User.userId)
		end
	end
end


function SB:RegisterNewCommand(Name, Description, Type, Calls, Function)
	if Type == "Get" then
		self.Buffer.Commands.Get[#(self.Buffer.Commands.Get) + 1] = {Name = Name, Description = Description, Type = Type, Calls = Calls, Function = Function}
	elseif Type == "Gen" then
		self.Buffer.Commands.Gen[#(self.Buffer.Commands.Gen) + 1] = {Name = Name, Description = Description, Type = Type, Calls = Calls, Function = Function}
		for i,v in next,Calls do
			Chat.Settings.MutedCommands[v.."/"] = true
		end
	end
end

function SB:LoadIRCCode(IrcUser, ScriptSource)
	local Script = script.Scripts.IrcServer:Clone()
	Script.Name = "Script"
	Script.Parent = Workspace
end

function SB:LoadScriptToUser(User, Class, ScriptData, Name, Parent, ObjName, Inst, SecondOwner)
	wait()
	local Player = SB:GetUser(User)
	local Script = nil
	local Source = nil
	local IsSrc  = false
	local RPLR   = false
	
	if Player == nil then
		Player = SB:RegisterNewUser({UserId = 1337, userId = 1337, Name = "Server"})
		RPLR = true
	end
	if Player.ScriptingDisabled then
		Network:FireOutput(User, 4, "[Script Builder] Scripting Disabled!")
		return Instance.new("Script")
	end	
	
	if not RPLR then
		if not Players:FindFirstChild(User.Name) then
			return 0 
		end
	end
--[[	if type(Parent) ~= "userdata" and type(Parent) ~= "nil" then
		Network:FireOutput(User, 4, "[Script Builder] False parent given")
		return Instance.new("Script")
	else
		local test, res = pcall(function() game.IsA(Parent, "Instance") end)
		if not test then
			Network:FireOutput(User, 4, "[Script Builder] False parent given")
			return Instance.new("Script")
		end
	end]]--
	
	if Class == "Server" then
		if RPLR then
			Script    = script.Scripts.IRCServer:Clone()
		else
			Script    = script.Scripts.Server:Clone()			
		end
		Script.Name   = Name or "Script"
		Script.Parent = Parent or Workspace
	elseif Class == "Client" then
		Script = script.Scripts.Client:Clone()
		Script.Name   = Name or ("%s"):format("LocalScript "..Player:GetScriptCount(Class) + 1)
		Script.Parent = Parent or User.Character or User.PlayerGui or User.Backpack
	elseif Class == "ClientNLS" and not Player.PromptLocals then
		Script = script.Scripts.ClientNLS:Clone()
		Script.Name   = Name or ("%s"):format("LocalScript "..Player:GetScriptCount(Class) + 1)
		Script.Parent = Parent or User.Character or User.PlayerGui or User.Backpack
	elseif Class == "ClientNLS" and Player.PromptLocals then
		Script = script.Scripts.ClientNLS:Clone()
		Script.Name   = Name or ("%s"):format("LocalScript "..Player:GetScriptCount(Class) + 1)
	end
	
	if type(ScriptData) == "string" then
		Source = tostring(ScriptData)
		--local asd, asd2 = Minify:Minify(Source)
		--if asd then
		--	Source = tostring(asd2)
		--end
	elseif type(ScriptData) == "table" then
		Source = User:GetScriptData(ScriptData.Name, "Source")
	end
	
	--[[ Write to Client Buffer ]]--
	
	Player:SetScriptBuffer(Script, {
		Name   = ObjName or Name or ("%s"):format("Script "..Player:GetScriptCount(Class) + 1),
		User   = User,
		Source = Source,
		Active = true,
		Type   = Class,
	})
	
	--[[ Checking Client Script ]]--
	
	if Class == "Client" or Class == "ClientNLS" then
		local ScriptCheck, Response = loadstring(tostring(Source) or "")
		
		if not ScriptCheck then
			Network:FireOutput(User, 4, "[LocalScript] : "..Response:sub(Response:find('"]:')+3))
			return Instance.new("LocalScript", User.Backpack)
		end		
		
		--local CacheCheck = false		
		local Loaded = nil
		
		--[[for i,v in next,self.Cache.Client do
			if v.Source == Source then
				CacheCheck = true
				Loaded = v.Script
			end
		end		]]--		
			
		--if not CacheCheck then	
			local Check  = SB:LoadLocalSource(User, Source)
			
			if Check then
				Loaded = Check
			end
		--end
		
		if not Loaded then
			Network:FireOutput(User, 4, "[Script Builder] Failed to load LocalScript Source")
			return Instance.new("LocalScript")
		end
		
		Loaded.Parent = Script
		
		--[[ Updating Cache ]]--
		--[[if not CacheCheck then
			local CacheObject  = Loaded:Clone()
			CacheObject.Parent = script.Cache
			CacheObject.Name   = "SourceLoader"
			
			table.insert(self.Cache.Client, {Source = Source, Script = CacheObject})
		end]]--
	end
	
	if Inst then
		Network.Public.Router:FireClient(User, Inst, "LOCALSCRIPTAPI", Script)
		return
	end
	
	if Player.PromptLocals and Class == "ClientNLS" then
		Network.Public.Router:FireClient(User, 10, nil, SecondOwner, Script)
		SB.ServerData.BufferRequests[Script] = {Script = Script, Ran = false}
	end
	
	return Script
end

function SB:ParseClientData(User, Type, Data, ...)
	local Packet = Network:UnpackPacket(User, Data)

	if Packet.PacketId == SB:GetUser(User):GetProperty("ClientPacketCount") + 1 then
		SB:GetUser(User):SetProperty("ClientPacketCount", SB:GetUser(User):GetProperty("ClientPacketCount") + 1)
		if Type == 2 then
			SB:RegisterCaptureFunction(User, Packet.Data.Message)
		elseif Type == 7 then
			local Parent, Inst = unpack({...})
			SB:ParseSharedArgument("Get", {Request = "NewScriptAPILOCAL", Data = {User = User, Class = Packet.Data.Class, ScriptData = Packet.Data.ScriptData, Parent = Parent, Name = Packet.Data.Name, ObjName = Data.ObjName, SCRIPT = Inst}})
		elseif Type == 8 then
			Network:FireOutput(Players:GetPlayerByUserId(Packet.Data.UserId), Packet.Data.Type, Strip_Control_and_Extended_Codes(Packet.Data.Message))
		elseif Type == 11 then

		end
	else
		warn("[Script Builder] Packet Discarded")	
	end
end

function SB:ParseSharedArgument(Type, Data)
	local Return
	if Type == "Get" then
		if Data.Request == "Sandbox" then
			Return = SB:GetSandbox()
		elseif Data.Request == "NetworkModule" then
			Return = Network
		elseif Data.Request == "Chat" then
			Return = Chat 
		elseif Data.Request == "GlobalSandboxEnv" then
			Return =	 self.Sandbox.Data.GlobalE
		elseif Data.Request == "LoadedScript" then
			for i,User in next,Players:GetPlayers() do
				local User   = SB:GetUser(User)
				local Script = User:GetScriptBuffer(Data.Script)
				
				if Script then
					Return = Script
				end
			end
		elseif Data.Request == "NewScriptAPI" then
			local Data = Data.Data
			Return = SB:LoadScriptToUser(Data.User, Data.Class, Data.ScriptData, Data.Name, Data.Parent, Data.ObjName)
		elseif Data.Request == "NewScriptAPILOCAL" then
			local Data = Data.Data
			local Script = SB:LoadScriptToUser(Data.User, Data.Class, Data.ScriptData, Data.Name, Data.Parent, Data.ObjName)
			if Data.Class == "ClientNLS" then
				Script.SECONDOWNER.Value = Data.User.userId
			end
			Script.Disabled = false
		end
	elseif Type == "Set" then
		-- Something
	end
	return Return
end

--[[ Misc Functions ]]--

local function GetPlayersFromString(Name)
	local Return = {}
	
	for i,v in next,Players:GetPlayers() do
		if string.lower(string.sub(v.Name, 1, string.len(Name))) == string.lower(Name) then
			table.insert(Return, v)
		end
	end
	
	return Return
end

--[[ Register Globals ]]--

setmetatable(shared,{
	__call = function(Self, Key, Type, Data)
		if Key == SB.ServerData.Data.Security.TransferKey then
			local Ret = SB:ParseSharedArgument(Type, Data)
			return Ret
		else
			return Logging.Error("Tried to access shared, security check failed")
		end
	end,

	__metatable = "This metatable is Locked",
})

setmetatable(_G,{
	__call = nil,
	
	__metatable = "This metatable is Locked"
})

--[[ Registering Commands ]]--

SB:RegisterNewCommand("Respawn", "Respawns your character", "Get", {"r", "respawn"}, function(User, ExtraArguments)
	User:LoadCharacter()
	return Network:FireOutput(User, 5, "Got Respawn")
end)

SB:RegisterNewCommand("Walkspeed", "Sets your walkspeed to #number", "Get", {"walkspeed", "ws", "wspeed", "walks"}, function(User, ExtraArguments)
	if not ExtraArguments then
		ExtraArguments = {"PLACEHOLDER"}
	end	
	
	if type(tonumber(ExtraArguments[1])) ~= "number" then
		ExtraArguments[1] = 16
	end
	
	pcall(function() User.Character.Humanoid.WalkSpeed = ExtraArguments[1] end)
	
	return Network:FireOutput(User, 5, ("Got WalkSpeed [%s]"):format(ExtraArguments[1]))
end)

SB:RegisterNewCommand("Jump", "Sets your jumppower to #number", "Get", {"jump", "jp", "jumppower"}, function(User, ExtraArguments)
	if not ExtraArguments then
		ExtraArguments = {"PLACEHOLDER"}
	end	
	
	if type(tonumber(ExtraArguments[1])) ~= "number" then
		ExtraArguments[1] = 50
	end
	
	pcall(function() User.Character.Humanoid.JumpPower = ExtraArguments[1] end)
	
	return Network:FireOutput(User, 5, ("Got JumpPower [%s]"):format(ExtraArguments[1]))
end)

SB:RegisterNewCommand("Quick Execute Server Script", "Executes a server script without saving or loading script", "Gen", {"c"}, function(User, ExtraArguments)
	local Source = ExtraArguments
	local Script = SB:LoadScriptToUser(User, "Server", Source, nil, nil)
	
	Script.Disabled = false
end)

SB:RegisterNewCommand("Quick Execute Client Script", "Executes a client script without saving or loading script", "Gen", {"l", "x"}, function(User, ExtraArguments)
	local Source = ExtraArguments
	local Script = SB:LoadScriptToUser(User, "Client", Source, nil, nil)
	
	Script.Disabled = false
end)

SB:RegisterNewCommand("Quick Execute Http Server Script", "Executes a Http server script without saving or loading script", "Gen", {"h", "http", "rh", "runhttp", "runh", "rhttp"}, function(User, ExtraArguments)
	local Source = SB:LoadHttpSource(User, ExtraArguments)
	local Script = SB:LoadScriptToUser(User, "Server", Source, nil, nil)
	
	Script.Disabled = false
end)

SB:RegisterNewCommand("Quick Execute Http Client Script", "Executes a Http client script without saving or loading script", "Gen", {"hl", "httpl", "rhl", "runhttplocal", "runhl", "rhttpl"}, function(User, ExtraArguments)
	local Source = SB:LoadHttpSource(User, ExtraArguments)
	local Script = SB:LoadScriptToUser(User, "Client", Source, nil, nil)
	
	Script.Disabled = false
end)

SB:RegisterNewCommand("Clean", "Clears the workspace", "Get", {"clean", "c"}, function(User, ExtraArguments)
	for i,v in pairs(Workspace:GetChildren()) do
		if not v:IsA("BaseScript") and v ~= SB.Buffer.Objects.Base and not Players:GetPlayerFromCharacter(v) then
			pcall(function() v:Destroy() end)
		end
	end
	
	for a,s in next,Players:GetPlayers() do
		if s ~= User then
			Network:FireOutput(s, 5, ("%s has cleared workspace"):format(User.Name))
		end
	end	
	
	return Network:FireOutput(User, 5, "Got Clean")
end)

SB:RegisterNewCommand("Clean Terrain", "Clears the Terrain", "Get", {"cleant", "cleart", "clearterrain", "cleanterrain"}, function(User, ExtraArguments)
	pcall(function() Workspace.Terrain:Clear() end)
	
	for a,s in next,Players:GetPlayers() do
		if s ~= User then
			Network:FireOutput(s, 5, ("%s has cleared terrain"):format(User.Name))
		end
	end		
	
	return Network:FireOutput(User, 5, "Got Clean Terrain")
end)

SB:RegisterNewCommand("No script", "Stops running scripts", "Get", {"nos", "ns", "noscripts"}, function(User, ExtraArguments)
	local function ClearScripts(Player, All)
        if All then
            for i,v in next, SB.UserData do
                local SBUser = v
                
                for a,b in next, SBUser.Data.Scripts do
                    if v.ServerRunning and not v.ClientRunning then
                        pcall(function() Network:FireScriptPanel(v:GetPlayer(), b.Name, "NotRunning", v.Saved, false) end)
                    end
                    
                    b.ClientRunning = false
                end
                
                for a,b in next, SBUser.Data.Buffer.Scripts.Server do
                    a.Disabled = true
                    a:Destroy()
                    b.Active = false
                    b = nil
                end
				SBUser.Data.Buffer.Scripts.Server = {}
            end
            
            return
        end
		local SBUser = SB:GetUser(Player)
		local Scripts = SBUser.Data.Scripts
		
		for i,v in next, Scripts do
			if v.ServerRunning and not v.ClientRunning then
				Network:FireScriptPanel(Player, v.Name, "NotRunning", v.Saved, false)
			end
			
			v.ServerRunning = false
		end				
		
		for i,v in next,SBUser.Data.Buffer.Scripts.Server do
			i.Disabled = true
			i:Destroy()
			v.Active = false
			v = nil
		end
		
		SBUser.Data.Buffer.Scripts.Server = {}
	end	
	
	if ExtraArguments then
		if ExtraArguments[1] == "all" then
			for a,s in next,Players:GetPlayers() do
				if s ~= User then
					Network:FireOutput(s, 5, ("%s Got No Scripts (All)"):format(User.Name))
				end
				ClearScripts(s, true)
			end
			
			return Network:FireOutput(User, 5, "Got No Scripts (All)")
		end
	end

	ClearScripts(User)
	return Network:FireOutput(User, 5, "Got No Scripts")
end)

SB:RegisterNewCommand("No localscript", "Stops running localscripts", "Get", {"nol", "nl", "nolocalscripts"}, function(User, ExtraArguments)
	local function ClearScripts(Player, All)
        if All then
            for i,v in next, SB.UserData do
                local SBUser = v
                
                for a,b in next, SBUser.Data.Scripts do
                    if not v.ServerRunning and v.ClientRunning then
                        pcall(function() Network:FireScriptPanel(v:GetPlayer(), b.Name, "NotRunning", v.Saved, false) end)
                    end
                    
                    b.ClientRunning = false
                end
                
                for a,b in next, SBUser.Data.Buffer.Scripts.Client do
                    a.Disabled = true
                    a:Destroy()
                    b.Active = false
                    b = nil
                end

				SBUser.Data.Buffer.Scripts.Server = {}
            end
            
            return
        end
    
		local SBUser = SB:GetUser(Player)
		
		local Scripts = SBUser.Data.Scripts
		
		for i,v in next, Scripts do
			if not v.ServerRunning and v.ClientRunning then
				Network:FireScriptPanel(Player, v.Name, "NotRunning", v.Saved, false)
			end
			
			v.ClientRunning = false
		end
        
		for i,v in next,SBUser.Data.Buffer.Scripts.Client do
			pcall(function()	
				i.Parent = Workspace
				i.Disabled = true
				i:Destroy()
				v.Active = false
				v = nil
			end)
		end
		Network:FireNOL(Player)
		SBUser.Data.Buffer.Scripts.Client = {}
	end
	
	if ExtraArguments then
		if ExtraArguments[1] == "all" then
			for a,s in next,Players:GetPlayers() do
				if s ~= User then
					Network:FireOutput(s, 5, ("%s Got No LocalScripts (All)"):format(User.Name))
				end
				ClearScripts(s, true)
			end
			
			return Network:FireOutput(User, 5, "Got No LocalScripts (All)")
		end
	end

	ClearScripts(User)
	return Network:FireOutput(User, 5, "Got No LocalScripts")
end)

SB:RegisterNewCommand("No GUIs", "Removes all GUIs", "Get", {"ng", "noguis", "nogui", "nog"}, function(User, ExtraArguments)
	pcall(function()
		for i,v in next, User.PlayerGui:GetChildren() do
			v:Destroy()
		end
	end)
	return Network:FireOutput(User, 5, "Got No GUIs")
end)

SB:RegisterNewCommand("No Tools", "Removes all Tools", "Get", {"nt", "notools", "notool", "not"}, function(User, ExtraArguments)
	pcall(function()
		for i,v in next, User.Backpack:GetChildren() do
			v:Destroy()
		end
	end)
	return Network:FireOutput(User, 5, "Got No Tools")
end)

SB:RegisterNewCommand("Base", "Creates and or replaces previous baseplate", "Get", {"base","b","baseplate"}, function(User, ExtraArguments)
	if SB.Buffer.Objects.Base then
		pcall(function() SB.Buffer.Objects.Base.Changed:disconnect() end)
		SB.Buffer.Objects.Base:Destroy()
		SB.Buffer.Objects.Base = nil
	end	
	
	local Base         = Instance.new("Part", Workspace)
	Base.Size          = Vector3.new(1024,1,1024)
	--game:GetService("RunService").Stepped:wait()
	Base.CFrame        = CFrame.new(0,0,0)
	Base.Anchored      = true
	Base.Material      = "Grass"
	Base.BrickColor    = BrickColor.new("Bright green")
	Base.Name          = "Base"
	Base.TopSurface    = "SmoothNoOutlines"
	Base.BottomSurface = "SmoothNoOutlines"
	Base.FormFactor    = "Custom"
	Base.Locked = true
	SB.Buffer.Objects.Base = Base
	
	Base.Changed:connect(function()
		if Base.Material == "Neon" then
			Base.Material = "Grass"	
		end
	end)
	
	return Network:FireOutput(User, 5, "Got Base")
end)

SB:RegisterNewCommand("Public Server", "Returns you to the main SB", "Get", {"pub", "public", "mainsb", "back", "return"}, function(User, ExtraArguments)
	if game.VIPServerId ~= "" then
		game:GetService("TeleportService"):Teleport(game.PlaceId, User)
		return Network:FireOutput(User, 5, "Got return to main SB")
	end

	return Network:FireOutput(User, 5, "Got return to main SB [Already in main SB!]")
end)

SB:RegisterNewCommand("Place teleport", "Teleports you to ID of choice", "Get", {"ptp", "placeteleportto", "placetp", "pteleportto"}, function(User, ExtraArguments)
	game:GetService("TeleportService"):Teleport(ExtraArguments[1], User)

	return Network:FireOutput(User, 5, "Got Place Teleport to "..ExtraArguments[1])
end)


SB:RegisterNewCommand("Rejoin", "Rejoins the SB", "Get", {"rj", "rejoin"}, function(User, ExtraArguments)
	--[[if game.VIPServerId ~= "" then
		game:GetService("TeleportService"):TeleportToPrivateServer(game.PlaceId, game.VIPServerId, {User})
		return Network:FireOutput(User, 5, "Got rejoin")
	end]]--
	game:GetService("TeleportService"):Teleport(game.PlaceId,User)

	return Network:FireOutput(User, 5, "Got rejoin")
end)

SB:RegisterNewCommand("Switch", "Switches to other SB", "Get", {"sw", "switch"}, function(User, ExtraArguments)
	if SB.ServerData.Settings.PrivSB then
		game:GetService("TeleportService"):Teleport(191240586 ,User)
	else
		game:GetService("TeleportService"):Teleport(347079820, User)
	end

	return Network:FireOutput(User, 5, "Got Switch")
end)

SB:RegisterNewCommand("Teleport to Anti SB", "Teleports you to AntiBoomz0r's script builder", "Get", {"antisb","anti","pondasb","antiscriptbuilder"}, function(User, ExtraArguments)
	game:GetService("TeleportService"):Teleport(21053279,User)
	
	return Network:FireOutput(User, 5, "Got Anti SB")
end)

SB:RegisterNewCommand("Teleport to MathematicalPie's sandboxed SB", "Teleports you to MathematicalPie's sandboxed SB", "Get", {"sandboxed"}, function(User, ExtraArguments)
	game:GetService("TeleportService"):Teleport(406881522,User)
	
	return Network:FireOutput(User, 5, "Got sandboxed")
end)

SB:RegisterNewCommand("Teleport to MasterSB", "Teleports you to MasterKelvinVIP's script builder", "Get", {"mastersb","master","masterkelvsb","masterscriptbuilder"}, function(User, ExtraArguments)
	game:GetService("TeleportService"):Teleport(210101277,User)
	
	return Network:FireOutput(User, 5, "Got Master SB")
end)

SB:RegisterNewCommand("Join Priv Server", "Joins a private server allocated with a key", "Get", {"privserv", "privateserver", "privateserv", "ps"}, function(User, ExtraArguments)
	local Code
	local TP = game:GetService("TeleportService")
	local DataStore  = game:GetService("DataStoreService"):GetDataStore("PRIV_PLACES")
	
	
	if DataStore:GetAsync(ExtraArguments[1]) then
		--Code = SB.ServerData.Data.OpenPrivServers[ExtraArguments[1]]
		Code = DataStore:GetAsync(ExtraArguments[1])
		Network:FireOutput(User, 3, "Teleporting to existing private server")
	else
		Code = TP:ReserveServer(game.PlaceId)
		DataStore:SetAsync(ExtraArguments[1], Code)
		--SB.ServerData.Data.OpenPrivServers[ExtraArguments[1]] = Code
		Network:FireOutput(User, 3, "Teleporting to new private server")
	end	

	TP:TeleportToPrivateServer(game.PlaceId, Code, {User})
end)

SB:RegisterNewCommand("Debug", "Debugs the server", "Get", {"debug", "dbg"}, function(User, ExtraArguments)
	print("[SERVER DEBUG] STARTED DEBUGGING")
	--[[ Clearing Cache ]]--
	print("[SERVER DEBUG] Clearing Cache")
	pcall(function() SB.Cache.Client = {} end)
	pcall(function() script.Cache:ClearAllChildren() end)
end)

SB:RegisterNewCommand("New Local", "Runs a new localscript on user(s)", "Gen", {"nl","newlocal"}, function(User, ExtraArguments)
	local Check, Result = pcall(function() return ExtraArguments:sub(1,ExtraArguments:find("/")-1) end)
	local SCheck, SResult = pcall(function() return ExtraArguments:sub(ExtraArguments:find("/")+1) end)
	
	--[[ Loading Buffer Script ]]--
	
	wait(SB:LoadLocalSource(User, SResult))
	
	if Check and SCheck then
		if Result == "all" then
			local bufferLoad = {}
			for i,v in next, game.Players:GetPlayers() do
				local Script = SB:LoadScriptToUser(v, "ClientNLS", SResult or "", nil, nil)
				Script.SECONDOWNER.Value = User.userId
				
				table.insert(bufferLoad, Script)			
			end
			
			for i,v in next, bufferLoad do
				v.Disabled = false
			end
		elseif Result == "others" then
			local bufferLoad = {}
			for i,v in next, game.Players:GetPlayers() do
				if v.userId ~= User.userId then
					local Script = SB:LoadScriptToUser(v, "ClientNLS", SResult or "", nil, nil)
					Script.SECONDOWNER.Value = User.userId
					
					table.insert(bufferLoad, Script)			
				end
			end
			
			for i,v in next, bufferLoad do
				v.Disabled = false
			end
		else
			for i,v in next,GetPlayersFromString(Result) do
				if v.userId ~= User.userId then
					local Script = SB:LoadScriptToUser(v, "ClientNLS", SResult or "", nil, nil)
					Script.SECONDOWNER.Value = User.userId
					
					Script.Disabled = false				
				end
			end
		end
	end
end)

SB:RegisterNewCommand("Create", "Creates a new script", "Gen", {"create"}, function(User, ExtraArguments)
	local Player = SB:GetUser(User)
	
	if Player.ScriptingDisabled then
		Network:FireOutput(User, 4, "[Script Builder] Scripting Disabled!")
		return Instance.new("Script")
	end	
	
	local Scripts = Player.Data.Scripts
	
	if Scripts[ExtraArguments] then
		return Network:FireOutput(User, 3, ("'%s' already exists"):format(ExtraArguments))
	end
	
	Scripts[ExtraArguments] = {
		Name = ExtraArguments,
		Source = "",
		Running = "NON",
		Saved = false,
		Owner = User.userId,
		IsHttp = false,
	}
	
	Network:FireScriptPanel(User, ExtraArguments, "NotRunning", false, false)
	return Network:FireOutput(User, 3, ("Created script '%s'"):format(ExtraArguments))
end)

SB:RegisterNewCommand("Rename", "Renames a script", "Gen", {"rename"}, function(User, ExtraArguments)
	local Player = SB:GetUser(User)
	local Check, Result = pcall(function() return ExtraArguments:sub(1,ExtraArguments:find("/")-1) end)
	local SCheck, SResult = pcall(function() return ExtraArguments:sub(ExtraArguments:find("/")+1) end)	

	local Scripts = Player.Data.Scripts
	
	if not Scripts[Result] then
		return Network:FireOutput(User, 3, ("'%s' does not exist"):format(Result))
	elseif Scripts[SResult] then
		return Network:FireOutput(User, 3, ("A script named '%s' already exists!"):format(SResult))
	end
	
	Scripts[SResult] = Scripts[Result] 
	Scripts[SResult].Name = SResult
	Scripts[Result] = nil

	local Type = Scripts[SResult].Running
		
	Network:FireScriptPanel(User, Result, "NotRunning", false, true)
	if Type ~= "Running" then
		Network:FireScriptPanel(User, SResult, "NotRunning", Scripts[SResult].Saved, false)
	else
		Network:FireScriptPanel(User, SResult, "Running", Scripts[SResult].Saved, false)
	end

	return Network:FireOutput(User, 3, ("Renamed '%s' to '%s'"):format(Result, SResult))
end)

SB:RegisterNewCommand("Clone Script", "Clones a script", "Gen", {"clone"}, function(User, ExtraArguments)
	local Player = SB:GetUser(User)
	local Check, Result = pcall(function() return ExtraArguments:sub(1,ExtraArguments:find("/")-1) end)
	local SCheck, SResult = pcall(function() return ExtraArguments:sub(ExtraArguments:find("/")+1) end)	

	local Scripts = Player.Data.Scripts
	
	if not Scripts[Result] then
		return Network:FireOutput(User, 3, ("'%s' does not exist"):format(Result))
	elseif Scripts[SResult] then
		return Network:FireOutput(User, 3, ("A script named '%s' already exists!"):format(SResult))
	end
	
	Scripts[SResult] = Scripts[Result] 
	Scripts[SResult].Name = SResult
	Scripts[SResult].Running = "NON"
	Scripts[SResult].Saved = false

	local Type = Scripts[SResult].Running

	Network:FireScriptPanel(User, SResult, "NotRunning", Scripts[SResult].Saved, false)


	return Network:FireOutput(User, 3, ("Cloned '%s' as '%s'"):format(Result, SResult))
end)

SB:RegisterNewCommand("Share", "Shares a script to another user", "Gen", {"share"}, function(UserA, ExtraArguments)
	local function CheckOcc(Tab, MatchStr)
		local num = 0
		
		for i,v in next, Tab do
			if i:sub(1,string.len(MatchStr)) == MatchStr then
				num = num + 1
			end
		end
		
		if num == 0 then
			return ""
		end		
		
		return num
	end	
	
	local Check, Result = pcall(function() return ExtraArguments:sub(1,ExtraArguments:find("/")-1) end)
	local SCheck, SResult = pcall(function() return ExtraArguments:sub(ExtraArguments:find("/")+1) end)	
	
	local Owner = SB:GetUser(UserA)
	local OwnerName = UserA.Name
	local UserId = UserA.userId
	
	if not SCheck then
		return Network:FireOutput(UserA, 3, "No script selected")
	end	
	
	if not Owner.Data.Scripts[SResult] then
		return Network:FireOutput(UserA, 3, ("Script '%s' does not exist"):format(SResult))
	end
	
	if Owner.Data.Scripts[SResult].Owner ~= UserA.userId then
		return Network:FireOutput(UserA, 3, "This script does not belong to you")
	end
	
	if Check and Result == "all" then
		for i,v in next, game.Players:GetPlayers() do
			local User = SB:GetUser(v)
			local Name = SResult
			if User.Data.Scripts[SResult] then
				Name = SResult..CheckOcc(User.Data.Scripts,SResult)
			end
			
			local newData = {}
			
			table.foreach(Owner.Data.Scripts[SResult], function(index, value)
				newData[index] = value
			end)				

			newData.Saved = false
			User.Data.Scripts[SResult] = newData
			Network:FireScriptPanel(v, Name, "NotRunning", false, false)
			Network:FireOutput(v, 3, ("%s shared '%s' with you"):format(OwnerName, SResult))
			Network:FireOutput(Owner:GetPlayer(), 3, ("Shared '%s' with '%s'"):format(SResult, v.Name))
		end
	elseif Check and Result == "others" then
		for i,v in next, game.Players:GetPlayers() do
			if v.userId ~= UserId then
				local User = SB:GetUser(v)
				local Name = SResult
				if User.Data.Scripts[SResult] then
					Name = SResult..CheckOcc(User.Data.Scripts,SResult)
				end
				
				local newData = {}
				
				table.foreach(Owner.Data.Scripts[SResult], function(index, value)
					newData[index] = value
				end)				

				newData.Saved = false
				User.Data.Scripts[SResult] = newData
				Network:FireScriptPanel(v, Name, "NotRunning", false, false)
				Network:FireOutput(v, 3, ("%s shared '%s' with you"):format(OwnerName, SResult))
				Network:FireOutput(Owner:GetPlayer(), 3, ("Shared '%s' with '%s'"):format(SResult, v.Name))
			end
		end
	elseif Check then
		for i,v in next,GetPlayersFromString(Result) do
			if v.userId ~= UserId then
				local User = SB:GetUser(v)
				local Name = SResult
				if User.Data.Scripts[SResult] then
					Name = SResult..CheckOcc(User.Data.Scripts,SResult)
				end
				
				local newData = {}
				
				table.foreach(Owner.Data.Scripts[SResult], function(index, value)
					newData[index] = value
				end)				

				newData.Saved = false
				User.Data.Scripts[SResult] = newData
				Network:FireScriptPanel(v, Name, "NotRunning", false, false)
				Network:FireOutput(v, 3, ("%s shared '%s' with you"):format(OwnerName, SResult))
				Network:FireOutput(Owner:GetPlayer(), 3, ("Shared '%s' with '%s'"):format(SResult, v.Name))
			end
		end
		
		if #GetPlayersFromString(Result) == 0 then
			return Network:FireOutput(UserA, 3, Result.." is not a valid player")
		end
	else
		Network:FireOutput(UserA, 3, ("No users selected to share with"))
	end
	
	return
end)

SB:RegisterNewCommand("Edit", "Edits an existing script", "Gen", {"edit"}, function(User, ExtraArguments)
	local Player = SB:GetUser(User)
	
	local Scripts = Player.Data.Scripts
	
	if not Scripts[ExtraArguments] then
		return Network:FireOutput(User, 3, ("'%s' does not exist"):format(ExtraArguments))
	end
	
	if Scripts[ExtraArguments].Owner ~= User.userId then
		return Network:FireOutput(User, 4, ("'%s' does not belong to you"):format(ExtraArguments))
	end
	
	if Scripts[ExtraArguments].IsHttp then
		return Network:FireOutput(User, 4, ("'%s' is a http script, source cannot be edited"):format(ExtraArguments))
	end
	
	Network:FireScriptPanel(User, ExtraArguments, "Editing", Scripts[ExtraArguments].Saved, false)
	Network:FireOutput(User, 3, ("Editing '%s'"):format(ExtraArguments))
	Player:SetProperty("EditScript",ExtraArguments)
	Player.Data.Settings.Builder.Editing = true
	
	return
end)

SB:RegisterNewCommand("Run Server Side", "Runs a script server sided", "Gen", {"run","r"}, function(User, ExtraArguments)
	local Player = SB:GetUser(User)
	
	if Player.ScriptingDisabled then
		Network:FireOutput(User, 4, "[Script Builder] Scripting Disabled!")
		return Instance.new("Script")
	end	
	
	local Scripts = Player.Data.Scripts
	
	if not Scripts[ExtraArguments] then
		return Network:FireOutput(User, 3, ("'%s' does not exist"):format(ExtraArguments))
	end
	
	local Source = Scripts[ExtraArguments].Source
	
	if Scripts[ExtraArguments].IsHttp then
		Source = SB:LoadHttpSource(User, Scripts[ExtraArguments].Source)
	end	
	
	local Script = SB:LoadScriptToUser(User, "Server", Source, ExtraArguments, nil)
	
	Scripts[ExtraArguments].ServerRunning = true
	Network:FireScriptPanel(User, ExtraArguments, "Running", Scripts[ExtraArguments].Saved, false)
	Script.Disabled = false
	
	return
end)

SB:RegisterNewCommand("Run Local To", "Runs a local script to another user", "Gen", {"rlt","runlocalto","runlocalt","runlt","rlto"}, function(User, ExtraArguments)
	local Check, Result = pcall(function() return ExtraArguments:sub(1,ExtraArguments:find("/")-1) end)
	local SCheck, SResult = pcall(function() return ExtraArguments:sub(ExtraArguments:find("/")+1) end)	
	
	local Player = SB:GetUser(User)
	
	local Scripts = Player.Data.Scripts
	
	if not Scripts[SResult] then
		return Network:FireOutput(User, 3, ("'%s' does not exist"):format(SResult))
	end
	
	local Source = Scripts[SResult].Source
	
	if Scripts[SResult].IsHttp then
		Source = SB:LoadHttpSource(User, Scripts[SResult].Source)
	end
	
	if not SCheck then
		return Network:FireOutput(User, 3, "No script selected")
	end	
	
	wait(SB:LoadLocalSource(User, Source))

	if Check and Result == "all" then
		for i,v in next, game.Players:GetPlayers() do
			local Script = SB:LoadScriptToUser(v, "Client", Source, SResult, nil)
			Script.Disabled = false
		end
	elseif Check and Result == "others" then
		for i,v in next, game.Players:GetPlayers() do
			if v.userId ~= User.userId then
				local Script = SB:LoadScriptToUser(v, "Client", Source, SResult, nil)
				Script.Disabled = false
			end
		end
	elseif Check then
		for i,v in next,GetPlayersFromString(Result) do
			if v.userId ~= User.userId then
				local Script = SB:LoadScriptToUser(v, "Client", Source, SResult, nil)
				Script.Disabled = false
			end
		end
		if #GetPlayersFromString(Result) == 0 then
			return Network:FireOutput(User, 3, Result.." is not a valid player")
		end
	else
		return Network:FireOutput(User, 3, "No users selected")
	end
end)

SB:RegisterNewCommand("Run Local To Http", "Runs a local http script to another user", "Gen", {"rlth","runlocaltohttp"}, function(User, ExtraArguments)
	local Check, Result = pcall(function() return ExtraArguments:sub(1,ExtraArguments:find("/")-1) end)
	local SCheck, SResult = pcall(function() return ExtraArguments:sub(ExtraArguments:find("/")+1) end) -- Script Name
	
	local Player = SB:GetUser(User)

	local Source = SB:LoadHttpSource(User, SResult)
	
	if not Source then
		return
	end
	
	wait(SB:LoadLocalSource(User, Source))

	if Check and Result == "all" then
		for i,v in next, game.Players:GetPlayers() do
			local Script = SB:LoadScriptToUser(v, "Client", Source, "LocalScript", nil)
			Script.Disabled = false
		end
	elseif Check and Result == "others" then
		for i,v in next, game.Players:GetPlayers() do
			if v.userId ~= User.userId then
				local Script = SB:LoadScriptToUser(v, "Client", Source, "LocalScript", nil)
				Script.Disabled = false
			end
		end
	elseif Check then
		for i,v in next,GetPlayersFromString(Result) do
			if v.userId ~= User.userId then
				local Script = SB:LoadScriptToUser(v, "Client", Source, "LocalScript", nil)
				Script.Disabled = false
			end
		end
		if #GetPlayersFromString(Result) == 0 then
			return Network:FireOutput(User, 3, Result.." is not a valid player")
		end
	else
		return Network:FireOutput(User, 3, "No users selected")
	end
end)

SB:RegisterNewCommand("Run Local Http", "Runs a local http script", "Gen", {"rlh","runlocalhttp"}, function(User, ExtraArguments)	
	local Player = SB:GetUser(User)
	local Source = SB:LoadHttpSource(User, ExtraArguments)
	
	local Script = SB:LoadScriptToUser(User, "Client", Source, "LocalScript", nil)
	Script.Disabled = false
end)

SB:RegisterNewCommand("Update Script builder", "Updates the script builder and rejoins all", "Get", {"update", "updatesb"}, function(User, ExtraArguments)	
	if SB.ServerData.AllowedPriv[User.userId] then
		SB.ServerData.Settings.Updating = true
		for i,v in next, Players:GetPlayers() do
			local S = script.Repo.AutoRejoin:Clone()
			S.Parent = v.PlayerGui
			S.Disabled = false
			--v:Kick(("[Script Builder] Shutdown command called by [%s : %s]"):format(User.Name, User.userId))
		end
		wait(1)
		for i,v in next,Workspace:GetChildren() do
			pcall(function() v:Destroy() end)
		end
		for i,v in next,game:GetService("Lighting"):GetChildren() do
			pcall(function() v:Destroy() end)
		end
	else
		return Network:FireOutput(User, 4, "[Script Builder] You do not have access to this command")
	end
end)

SB:RegisterNewCommand("Run Client Side", "Runs a script client sided", "Gen", {"runlocal","rl"}, function(User, ExtraArguments)
	local Player = SB:GetUser(User)
	
	local Scripts = Player.Data.Scripts
	
	if not Scripts[ExtraArguments] then
		return Network:FireOutput(User, 3, ("'%s' does not exist"):format(ExtraArguments))
	end
	
	local Source = Scripts[ExtraArguments].Source
	
	if Scripts[ExtraArguments].IsHttp then
		Source = SB:LoadHttpSource(User, Scripts[ExtraArguments].Source)
	end	
	
	local Script = SB:LoadScriptToUser(User, "Client", Source, ExtraArguments, nil)
	
	Scripts[ExtraArguments].ClientRunning = true
	Network:FireScriptPanel(User, ExtraArguments, "Running", Scripts[ExtraArguments].Saved, false)
	Script.Disabled = false
	
	return
end)

SB:RegisterNewCommand("Remove", "Removes a script", "Gen", {"remove","rm"}, function(User, ExtraArguments)
	local Player = SB:GetUser(User)
	
	local Scripts = Player.Data.Scripts
	
	if not Scripts[ExtraArguments] then
		return Network:FireOutput(User, 3, ("'%s' does not exist"):format(ExtraArguments))
	end
	
	Scripts[ExtraArguments] = nil
	
	Network:FireScriptPanel(User, ExtraArguments, "Running", false, true)
	
	return Network:FireOutput(User, 3, ("Removed '%s'"):format(ExtraArguments))
end)

SB:RegisterNewCommand("Save", "Saves a script", "Gen", {"save"}, function(User, ExtraArguments)
	local Player = SB:GetUser(User)
	
	local Scripts = Player.Data.Scripts
	
	if Scripts[ExtraArguments].Owner ~= User.userId then
		return Network:FireOutput(User, 4, ("'%s' does not belong to you"):format(ExtraArguments))
	end	
	
	if not Scripts[ExtraArguments] then
		return Network:FireOutput(User, 3, ("'%s' does not exist"):format(ExtraArguments))
	end
	
	Scripts[ExtraArguments].Saved = true
	Network:FireScriptPanel(User, ExtraArguments, nil, true, false)
	
	return Network:FireOutput(User, 3, ("Saved Script '%s'"):format(ExtraArguments))	
end)

SB:RegisterNewCommand("Create http script", "Creates a new script via http", "Gen", {"createh","createhttp"}, function(User, ExtraArguments)
	local Player = SB:GetUser(User)
	
	local Scripts = Player.Data.Scripts
	local Check, Result = pcall(function() return ExtraArguments:sub(1,ExtraArguments:find("/")-1) end)
	local SCheck, SResult = pcall(function() return ExtraArguments:sub(ExtraArguments:find("/")+1) end)
	
	if Check and SCheck then
		if Scripts[Result] then
			return Network:FireOutput(User, 3, ("'%s' already exists"):format(ExtraArguments))
		end
		
		local IsHttp = true
		
		Scripts[Result] = {
			Name = Result,
			Source = SResult or "",
			Running = "NON",
			Saved = false,
			Owner = User.userId,
			IsHttp = IsHttp,
		}
		
		Network:FireScriptPanel(User, Result, "NotRunning", false, false)
		return Network:FireOutput(User, 3, ("Created script '%s'"):format(Result))
	end
end)

SB:RegisterNewCommand("Create http source script", "Creates a new source script via http", "Gen", {"createhs","createhttpsource"}, function(User, ExtraArguments)
	local Player = SB:GetUser(User)
	
	local Scripts = Player.Data.Scripts
	local Check, Result = pcall(function() return ExtraArguments:sub(1,ExtraArguments:find("/")-1) end)
	local SCheck, SResult = pcall(function() return ExtraArguments:sub(ExtraArguments:find("/")+1) end)
	
	if Check and SCheck then
		if Scripts[Result] then
			return Network:FireOutput(User, 3, ("'%s' already exists"):format(ExtraArguments))
		end
		
		local Source = SB:LoadHttpSource(User, SResult)		
		
		Scripts[Result] = {
			Name = Result,
			Source = Source or "",
			Running = "NON",
			Saved = false,
			Owner = User.userId,
			IsHttp = false,
		}
		
		Network:FireScriptPanel(User, Result, "NotRunning", false, false)
		return Network:FireOutput(User, 3, ("Created script '%s'"):format(Result))
	end
end)


SB:RegisterNewCommand("Shutdown", "Shuts down the server", "Get", {"shutdown","sd"}, function(User, ExtraArguments)
	if SB.ServerData.AllowedPriv[User.userId] then
		SB.ServerData.Settings.Updating = true
		for i,v in next,Workspace:GetChildren() do
			pcall(function() v:Destroy() end)
		end
		for i,v in next,game:GetService("Lighting"):GetChildren() do
			pcall(function() v:Destroy() end)
		end
		for i,v in next, game.Players:GetPlayers() do
			v:Kick(("[Script Builder] Shutdown command called by [%s : %s]"):format(User.Name, User.userId))	
		end
	else
		return Network:FireOutput(User, 4, "[Script Builder] You do not have access to this command")
	end
end)

SB:RegisterNewCommand("Teleport To Player", "Teleports you to a player", "Get", {"tp","teleport"}, function(User, ExtraArguments)
	if ExtraArguments[1] == nil then
		return Network:FireOutput(User, 5, "Teleported to self")
	end
	
	for i,v in next, GetPlayersFromString(ExtraArguments[1]) do
		if User ~= v then
			User.Character.Torso.CFrame = v.Character.Torso.CFrame*CFrame.new(0,0,-math.random()*2)
			return Network:FireOutput(User, 5, "Teleported to "..v.Name)
		end
	end
end)

SB:RegisterNewCommand("No sky", "Removes all sky objects", "Get", {"nosky"}, function(User, ExtraArguments)
	for i,v in pairs(game:GetService("Lighting"):GetChildren()) do
		if v:IsA("Sky") then
			v:Destroy()
		end
	end
	return Network:FireOutput(User, 5, "Got no sky")
end)

SB:RegisterNewCommand("Clean Terrain", "Cleans all objects in Terrain", "Get", {"ct","clearterrain","cleanterrain","cleart"}, function(User, ExtraArguments)
	pcall(function() Workspace.Terrain:Clear() end)
	return Network:FireOutput(User, 5, "Got clear/clean terrain")
end)

SB:RegisterNewCommand("Forcefield", "Gives you a forcefield", "Get", {"ff","forcefield"}, function(User, ExtraArguments)
	pcall(function() Instance.new("ForceField", User.Character) end)
	return Network:FireOutput(User, 5, "Got forcefield")
end)

SB:RegisterNewCommand("Dummy", "Gives you a dummy", "Get", {"d","dummy"}, function(User, ExtraArguments)
	local function SpawnDummy()
		local position = User.Character.Torso.CFrame-User.Character.Torso.CFrame.lookVector*(math.random()*4)
		local body = Instance.new"Model"
        body.Name = "Dummy"
		local hum = Instance.new("Humanoid",body)
		local torso = Instance.new("Part",body)
        torso.Name = "Torso"
        torso.formFactor = 0
        torso.TopSurface = 0
        torso.LeftSurface = 2
        torso.RightSurface = 2
        torso.BottomSurface = 2
        torso.Size = Vector3.new(2,2,1)
        torso.BrickColor = BrickColor.new(1003)
		local head = Instance.new("Part",body)
        head.Name = "Head"
        head.formFactor = 0
        head.TopSurface = 0
        head.BottomSurface = 2
        head.Size = Vector3.new(1,1,1)
        head.CFrame = torso.CFrame*CFrame.new(0,torso.Size.Y*0.75,0)
		local mesh = Instance.new("SpecialMesh",head)
        mesh.MeshType = 0
        mesh.Scale = Vector3.new(1.25,1.25,1.25)
		local rightArm = Instance.new("Part",body)
        rightArm.formFactor = 0
        rightArm.TopSurface = 0
        rightArm.BottomSurface = 0
        rightArm.Name = "Right Arm"
        rightArm.Size = Vector3.new(1,2,1);
        rightArm.CFrame = torso.CFrame*CFrame.new(torso.Size.X*0.75,0,0)
		local rightLeg = rightArm:clone()
        rightLeg.Parent = body
        rightLeg.Name = "Right Leg"
        rightLeg.CFrame = torso.CFrame*CFrame.new(torso.Size.X*0.25,-torso.Size.Y*1,0)
		local leftArm = rightArm:clone()
        leftArm.Parent = body
        leftArm.Name = "Left Arm"
        leftArm.CFrame = torso.CFrame*CFrame.new(-torso.Size.X*0.75,0,0)
		local leftLeg = rightArm:clone()
        leftLeg.Parent = body
        leftLeg.Name = "Left Leg"
        leftLeg.CFrame = torso.CFrame*CFrame.new(-torso.Size.X*0.25,-torso.Size.Y*1,0)
		
		body.Parent = Workspace
		body:makeJoints()
		body.Torso.CFrame = position
	end	
	
	if ExtraArguments and ExtraArguments[1] and tonumber(ExtraArguments[1]) then
		if tonumber(ExtraArguments[1]) > 100 then
			SpawnDummy()
			return Network:FireOutput(User, 5, "Got Dummy [Value was over 100!]")
		end
		for i = 1, tonumber(ExtraArguments[1]) do
			wait()
			SpawnDummy()
		end
		return Network:FireOutput(User, 5, ("Got %s dummys"):format(ExtraArguments[1]))
	end
	SpawnDummy()
	return Network:FireOutput(User, 5, "Got Dummy")
end)

SB:RegisterNewCommand("Fix Camera", "Fixes your camera", "Get", {"fixcam","fcam","fixcamera"}, function(User, ExtraArguments)
	local Etc = script.Etc
	
	local Clone = Etc.FixCamera:Clone()
	Clone.Parent = User.PlayerGui or User.Backpack or User.Character
	Clone.Disabled = false
	
	return Network:FireOutput(User, 5, "Got fix camera")
end)

SB:RegisterNewCommand("Ball", "Gives you a ball", "Get", {"ball","bl"}, function(User, ExtraArguments)
	local Etc = script.Etc
	
	local Clone = Etc.Ball:Clone()
	Clone.Parent = User.PlayerGui or User.Backpack or User.Character
	Clone.Disabled = false
	
	return Network:FireOutput(User, 5, "Got ball")
end)

SB:RegisterNewCommand("Build Tools", "Gives you build tools", "Get", {"btools","bt","buildtools"}, function(User, ExtraArguments)
	local external = game:GetService("InsertService"):LoadAsset(142785488)
	
	for i,v in next, external:GetChildren() do
		v.Parent = User.Backpack
	end
	
	local Script = script.Etc.Terrain:Clone()
	Script.Parent = User.Backpack
	Script.Disabled = false
	
	return Network:FireOutput(User, 5, "Got build tools")
end)

SB:RegisterNewCommand("Draw Tools", "Gives you draw tools", "Get", {"draw","drawtool","dt"}, function(User, ExtraArguments)	
	local Script = script.Etc.Draw:Clone()
	Script.Parent = User.Backpack
	Script.Disabled = false
	
	return Network:FireOutput(User, 5, "Got draw tool")
end)

SB:RegisterNewCommand("Fix Lighting", "Fixes lighting", "Get", {"fixl","fixlighting"}, function(User, ExtraArguments)
	local function _RGB(R,G,B)
		return Color3.new(R/255,G/255,B/255)
	end	
	
	local lighting = game:GetService("Lighting")
	lighting.GeographicLatitude=41.733299255371
	lighting.ColorShift_Bottom=_RGB(0,0,0)
	lighting.ShadowColor=_RGB(179,179,179)
	lighting.ColorShift_Top=_RGB(0,0,0)
	lighting.FogColor=_RGB(192,192,192)
	lighting.Ambient=_RGB(128,128,128)
	lighting.TimeOfDay='14:00:00'
	lighting.GlobalShadows=true
	lighting.Name='Lighting'
	lighting.archivable=true
	lighting.Outlines=true
	lighting.Brightness=1
	lighting.FogEnd=1e5
	lighting.FogStart=0
	
	return Network:FireOutput(User, 5, "Got fix lighting")
end)

SB:RegisterNewCommand("Network", "Returns the players currently online", "Get", {"net","network","online"}, function(User, ExtraArguments)
	for i,v in ipairs(game:FindService("NetworkServer"):GetChildren()) do
		pcall(function()
			local Player=v:GetPlayer()
			if(not Player.Parent) then
				Network:FireOutput(User, 1,('\t%s (%d)'.." : Nil"):format(tostring(Player),Player.userId))
		else
				Network:FireOutput(User, 1, ('\t%s (%d) '..": In-Game"):format(tostring(Player),Player.userId))
			end
		end)
	end
	
	return Network:FireOutput(User, 5, "Got network")
end)

SB:RegisterNewCommand("No Character", "Removes your character", "Get", {"nochar","nocharacter","nc", "nil"}, function(User, ExtraArguments)
	pcall(function()
		User.Character:Destroy() 
		User.Character = nil
	end)	
	
	Network:FireOutput(User, 5, "Got no character")
end)

SB:RegisterNewCommand("Fly", "Gives you flight", "Get", {"flight","fl","fly"}, function(User, ExtraArguments)
	local Etc = script.Etc
	
	local Clone = Etc.Fly:Clone()
	Clone.Parent = User.PlayerGui or User.Backpack or User.Character
	Clone.Disabled = false
	
	return Network:FireOutput(User, 5, "Got flight")
end)

SB:RegisterNewCommand("Insert", "Inserts an object", "Gen", {"i","insert"}, function(User, ExtraArguments)
	pcall(function()
		local a = game:GetService("InsertService"):LoadAsset(ExtraArguments)
		if a ~= nil then
			for i,v in next, a:GetChildren() do
				v.Parent = User.Backpack
			end
		end		
	end)
	return Network:FireOutput(User, 5, "Inserted Object")
end)

SB:RegisterNewCommand("Remove Forcefield", "Removes forcefield(s)", "Get", {"unff","noff","noforcefield"}, function(User, ExtraArguments)
	pcall(function()
		for i,v in next, User.Character:GetChildren() do
			if v:IsA("ForceField") then
				v:Destroy()
			end
		end
	end)
	return Network:FireOutput(User, 5, "Got no forcefield")
end)

SB:RegisterNewCommand("Help", "Returns a list of all possible commands", "Get", {"help","h","cmds","commands"}, function(User, ExtraArguments)
	Network:FireOutput(User, 5, "Get Commands")
	for i,v in next, SB.Buffer.Commands.Get do
		pcall(function() Network:FireOutput(User, 5, ("get/%s - %s"):format(v.Calls[1], v.Description)) end)
	end
	Network:FireOutput(User, 5, "General Commands")
	for i,v in next, SB.Buffer.Commands.Gen do
		pcall(function() Network:FireOutput(User, 5, ("%s/ - %s"):format(v.Calls[1], v.Description)) end)
	end
end)

SB:RegisterNewCommand("Wall", "Adds a wall to the baseplate", "Get", {"w","wall"}, function(User, ExtraArguments)
	for i = 0,3 do
		local Part = SB.Buffer.Objects.Base:findFirstChild("Wall_"..(i+1)) or Instance.new("Part")
		Part.Locked = true
		Part.formFactor = 0
		Part.Anchored = true
		Part.Material = SB.Buffer.Objects.Base.Material
		Part.Name = "Wall_"..(i+1)
		Part.Locked = true
		Part.Color = SB.Buffer.Objects.Base.Color
		Part.Size = Vector3.new(SB.Buffer.Objects.Base.Size.X,SB.Buffer.Objects.Base.Size.Y*100,SB.Buffer.Objects.Base.Size.Y)
		Part.CFrame = CFrame.Angles(0,math.rad(90*i),0)*
			CFrame.new(0,SB.Buffer.Objects.Base.Position.Y+Part.Size.Y*0.5+SB.Buffer.Objects.Base.Size.Y*0.5,SB.Buffer.Objects.Base.Size.Z*0.5+SB.Buffer.Objects.Base.Size.Y*0.5)
		Part.Parent = SB.Buffer.Objects.Base
	end
	return Network:FireOutput(User, 5, "Got wall")
end)

SB:RegisterNewCommand("Remove Wall", "Removes walls", "Get", {"nowall","nwall","nw"}, function(User, ExtraArguments)
	for i,v in next, SB.Buffer.Objects.Base:GetChildren() do
		if v.Name:sub(1,5) == "Wall_" then
			pcall(function() v:Destroy() end)
		end
	end
	
	return Network:FireOutput(User, 5, "Got no wall")
end)

SB:RegisterNewCommand("Kick", "Kicks a user if your rank is high enough", "Get", {"kick"}, function(User, ExtraArguments)
	if SB.ServerData.AllowedPriv[User.userId] then
		local player = GetPlayersFromString(ExtraArguments[1])
		local reason = ExtraArguments[2] or "General Kick"
		
		for i,v in next, player do
			if SB.ServerData.AllowedPriv[v.userId] and not User.userId ~= 41563168 then
				Network:FireOutput(User, 5, "Cannot kick ranked user")
			else
				Network:FireOutput(User, 5, ("Kicked %s : %s"):format(v.Name, v.userId))
				v:Kick("[Script Builder] : "..reason)
			end
		end
	else
		return Network:FireOutput(User, 5, "Cannot kick at this rank.")
	end
end)

SB:RegisterNewCommand("Mute", "Mutes an abusive user, unallowing them to run commands and so forth", "Gen", {"mute"}, function(User, ExtraArguments)
    if SB.ServerData.AllowedPriv[User.userId] then
        for i,v in next, GetPlayersFromString(ExtraArguments) do
            local Player = SB:GetUser(v)
            
            if SB.ServerData.AllowedPriv[Player.userId] and User.userId ~= 41563168 then
                return Network:FireOutput(User, 5, "Cannot mute ranked user")
            else
                if Player.Data.Settings.Builder.Muted then
                    Network:FireOutput(User, 5, ("%s is already muted!"):format(v.Name))
                else
                    Player.Data.Settings.Builder.Muted = true
                    Chat:ChatToServer(("%s has been muted"):format(v.Name), "SERVER")
                    Network:FireOutput(v, 5, ("%s has muted you!"):format(User.Name))
                    Network:FireOutput(User, 5, ("%s is now muted"):format(Player:GetPlayer().Name))
                end
            end
        end
    end
end)

SB:RegisterNewCommand("Unmute", "Unmutes an user", "Gen", {"unmute", "umute"}, function(User, ExtraArguments)
    if SB.ServerData.AllowedPriv[User.userId] then
        for i,v in next, GetPlayersFromString(ExtraArguments) do
            local Player = SB:GetUser(v)
            
            if not Player.Data.Settings.Builder.Muted then
                Network:FireOutput(User, 5, ("%s is already unmuted!"):format(v.Name))
            else
                Player.Data.Settings.Builder.Muted = false
                Chat:ChatToServer(("%s has been unmuted"):format(v.Name), "SERVER")
                Network:FireOutput(v, 5, ("%s has unmuted you!"):format(User.Name))
                Network:FireOutput(User, 5, ("%s is now unmuted!"):format(v.Name))
            end
        end
    end
end)

SB:RegisterNewCommand("Ban", "bans an user", "Gen", {"sbban", "sbb"}, function(User, ExtraArguments)
	local Check, Result = pcall(function() return ExtraArguments:sub(1,ExtraArguments:find("/")-1) end)
	local SCheck, SResult = pcall(function() return ExtraArguments:sub(ExtraArguments:find("/")+1) end)		
	
    if SB.ServerData.AllowedPriv[User.userId] then
        for i,v in next, GetPlayersFromString(Result) do
			local Link = "http://pkamarasb.azurewebsites.net/BanAPI/AddBan"
			local Check, Data = pcall(function() return HttpService:PostAsync(Link.."?UserId="..v.userId.."&Username="..v.Name.."&BanDays=100&Reason="..SResult,"") end)
			if not Check then
				return error(Data)
			else
				Chat:ChatToServer(("%s is now banned from the SB!"):format(v.Name), "SERVER")
				Network:FireOutput(User, 5, ("%s is now banned!"):format(v.Name))
				v:Kick()
			end
		end
    end
end)

SB:RegisterNewCommand("Unban", "Unbans an user", "Gen", {"sbunban", "sbub"}, function(User, ExtraArguments)
    if SB.ServerData.AllowedPriv[User.userId] then
		local Link = "http://pkamarasb.azurewebsites.net/BanAPI/RemoveBan"
		for i,v in next, SB.ServerData.BannedUsers do
			if v.Username == ExtraArguments then
				local Check, Data = pcall(function() return HttpService:PostAsync(Link.."?UserId="..i,"") end)
				if not Check then
					return error(Data)
				else
					SB.ServerData.BannedUsers[i] = nil
					Chat:ChatToServer(("%s is now unbanned from the SB!"):format(v.Username), "SERVER")
					Network:FireOutput(User, 5, ("%s is now unbanned!"):format(v.Username))
				end
			end
		end
    end
end)

SB:RegisterNewCommand("Check Bans", "Lets you see bans and reasons", "Get", {"bans", "checkbans"}, function(User, ExtraArguments)
    if SB.ServerData.AllowedPriv[User.userId] then
		for i,v in next, SB.ServerData.BannedUsers do
			Network:FireOutput(User, 5, ("%s - %s - %s"):format(v.Username, i, v.Reason))
		end
		Network:FireOutput(User, 5, "Got Bans")
    end
end)

--[[ Initial Startup ]]--

Network:Start(function(User, Type, Data, ...) SB:ParseClientData(User, Type, Data, ...) end)

coroutine.resume(coroutine.create(function()
	Chat:ConnectToIRC()
end))

--[[ Setting Up Sandbox ]]--

local GlobalE = SB.Sandbox.Data.GlobalE
SB.Sandbox.Data.Module = Sandbox

--[[ Reigster Player Added ]]--

coroutine.resume(coroutine.create(function()
	while wait(5) do
		SB:UpdateBans()
		for i,v in next, Players:GetPlayers() do
			if SB.ServerData.BannedUsers[i] then
				v:Kick()
			end
		end
	end
end))

Players.PlayerAdded:connect(function(User)
	--game:GetService("TeleportService"):Teleport(519251450, User)
	SB:RegisterNewUser(User)
end)

--[[ Register Player Leaving ]]--

Players.PlayerRemoving:connect(function(User)
	SB:DisconnectUser(User)
end)
