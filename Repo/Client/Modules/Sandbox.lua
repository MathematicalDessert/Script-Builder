--[[
    File Name: Sandbox.lua
    Author: Pkamara
    Description: Easy to use sandbox module for stopping arb code

    ChangeLog -
        26/02/2016 - Started writing the sandbox

    Future Ideas -
        - An address checker
        - Stop leaking environments
]]--

--[[ Internal Definitions ]]--

local InternalSandbox = {
    FakeObjects = {},
    RealObjects = {},
    Environments = {},
    LockedObjects = {},
}

local SessionFromThread = setmetatable({},{__mode="k"})

local NewSession do
	local sessionMeta = {}
	sessionMeta.__index = sessionMeta
	function sessionMeta:AddThread(co)
		co = co or coroutine.running()
		SessionFromThread[co] = self
	end
	function NewSession(owner, func, env, scr, irc, chan)
		return setmetatable({Owner=owner, Alive = func, Environment = env, Script = scr, IsIrc = irc, Channel = chan},sessionMeta)
	end
end

local function GetSession(co)
	return SessionFromThread[co or coroutine.running()]
end

local Sandbox = {}

local DangerousObjects = { -- Objects that are secured
    ["Players"] = true,
    ["Player"] = true,
}

local FakeObjects, RealObjects, LockedObjects = InternalSandbox.FakeObjects, InternalSandbox.RealObjects, InternalSandbox.LockedObjects

--[[ Settings ]]--

local DEBUG_MODE = false -- Outputs debug messages
local KEY_LOCKED = true  -- Locks the script to a certain key
local PLACE_LOCK = true  -- Locks the script to only load in certain places
local LOCAL_MODE = true  -- Is it a local script

local PRE_LD_KEY = "Some Key" -- For the Load if KEY_LOCKED is enabled

local PLACES_IDS = {
    [314145399] = true,
    [191240586] = true
}

--[[ Upvalues ]]--

local Environment = getfenv(0)
local tostring = tostring
local error = error
local print = print
local warn = warn
local wait = wait
local getfenv = getfenv
local setfenv = setfenv
local select = select
local unpack = unpack
local xpcall = xpcall
local type = type
local ypcall = ypcall
local setmetatable = setmetatable
local getmetatable = getmetatable
local newproxy = newproxy
local require = require
local next = next
local Instance = Instance
local game = game
local Game = game
local workspace = workspace
local Workspace = workspace
local pcall = pcall
local loadstring = loadstring
local rawset = rawset
local rawget = rawget
local tostring = tostring
local shared = shared
local LoadLibrary = LoadLibrary
local Spawn = spawn
local spawn = spawn
local coroutine = coroutine
local delay = delay
local Delay = delay
local Chat = require(script.Parent.Chat)
local SB = require(script.Parent.Settings)

local RealObject, FakeObject, FakeInstance, Network, Libraries

--[[ Custom Metatables ]]--

local INTERNAL_PROXY = newproxy()
local Metatables = {}

local function GetField(Metatable, Index)
    return Metatable[Index]
end

local function Getmetatable(Table)
    if Metatables[Table] then
        if Metatables[Table].__metatable ~= nil then
            if Metatables[Table].__metatable == INTERNAL_PROXY then
                return nil
            end
            return Metatables[Table].__metatable
        end
    else
        return Metatables[Table]
    end
    return getmetatable(Table)
end

local function Setmetatable(Table, Metatable)
    local Meta = Metatables[Table]

    if Meta ~= nil then
        if GetField(Meta, "__metatable") == INTERNAL_PROXY then
            return error("Attempt to modify readonly table",0)
        elseif GetField(Meta, "__metatable") ~= nil then
            return error("cannot change a protected metatable",0)
        else
            Metatables[Table] = nil
        end
    elseif getmetatable(Table) ~= nil then
        return error("cannot change a protected metatable",0)
    end

    local NewMeta = {}

    for i,v in next, Metatable do
        NewMeta[i] = v
    end

    local Buffer = {}

    for i,v in next, NewMeta do
        if i ~= "__metatable" then
            Buffer[i] = v
        end
    end

    Metatables[Table] = NewMeta

    return setmetatable(Table, Buffer)
end

--[[ End of Custom Metatables ]]--

if not LOCAL_MODE then
    Libraries = {
        ["RbxUtility"] = ({pcall(function() return game:GetService("HttpService"):GetAsync("https://raw.githubusercontent.com/CoolDoctorWho/Enceladus/master/ExternalHandles/Libraries/RbxUtility.lua",true) end)})[2],
        ["RbxStamper"] = ({pcall(function() return game:GetService("HttpService"):GetAsync("https://raw.githubusercontent.com/CoolDoctorWho/Enceladus/master/ExternalHandles/Libraries/RbxStamper.lua",true) end)})[2],
        ["RbxGui"] = ({pcall(function() return game:GetService("HttpService"):GetAsync("https://raw.githubusercontent.com/CoolDoctorWho/Enceladus/master/ExternalHandles/Libraries/RbxGui.lua",true) end)})[2],
        ["RbxGear"] = ({pcall(function() return game:GetService("HttpService"):GetAsync("https://raw.githubusercontent.com/CoolDoctorWho/Enceladus/master/ExternalHandles/Libraries/RbxGear.lua") end)})[2],
    }
end

local LockedEvents = {
    ["MessageOut"] = true,
}

--[[ Instance Indexes ]]--

local function IsRealObject(Instance)
    if Instance == nil then
        return false
    end

    if not pcall(function() return game.IsA(Instance, "Instance") end) then
        return false
    end

    if not game.IsA(Instance, "Instance") then
        return false
    else
        return true
    end
end

local function IsObjectDangerous(Object)
    if DangerousObjects[Object.className] then
        return true
    else
        return false
    end
end

local function GetResult(Function, ...)
    local Check, Result = pcall(Function, ...)

    return Check, Result
end

local function GetRandomPlayer()
    return game:GetService("Players"):GetPlayers()[1]
end

local function CheckPacketObject(Object, NumArgs)
    local Return
    Object = RealObject(Object)
    local ObjectType = type(Object)
    
    if ObjectType == "string" then
        if Object:len() >= 2e5 then
            Return = Object:sub(1, 2e5-(100*NumArgs))
        end
    elseif ObjectType == "userdata" then
        Return = RealObject(Object)
    elseif ObjectType == "table" then
        local newTable = {}
        for i,v in next, Object do
            newTable[i] = CheckPacketObject(v)
        end
    else
        Return = Object
    end
    
    return Return
end

local ReplacementFunctions = {
    Destroy = function(self)
        self = RealObject(self)
        if IsRealObject(self) and IsObjectDangerous(self) then
            return error("You cannot use the method 'Destroy' on this Instance",0)
        else
            return game.Destroy(self)
        end
    end,

    Remove = function(self)
        self = RealObject(self)
        if IsRealObject(self) and IsObjectDangerous(self) then
            return error("You cannot use the method 'Remove' on this Instance",0)
        else
            return game.Destroy(self)
        end
    end,

    Kick = function(self)
        self = RealObject(self)
        if IsRealObject(self) and IsObjectDangerous(self) then
            return error("You cannot use the method 'Kick' on this Instance", 0)
        else
            local Player = self

            if not Player then
                return nil
            end

            local Check, Response = GetResult(Player.Kick, self)
            
            return Player.Kick(self)
        end
    end,
    
    AddItem = function(self, item, lifetime)
        self, item = RealObject(self), RealObject(item)
        
        if IsRealObject(item) and IsObjectDangerous(item) then
            return error("You cannot add this item to debris", 0)
        else
            return game:GetService("Debris").AddItem(self, item, lifetime)
        end
    end,
    
    Chat = function(self, argument)
        self = RealObject(self)
        if not IsRealObject(self) or not self:IsA("Players") then
            return error("Chat is not a valid memeber of "..self, 0)
        end
        
        if type(argument) ~= "string" then
            return error("Message must be a string!", 0)
        end
        local Owner = RealObject(GetSession().Owner)
        
        return Chat:ChatToServer(argument, Owner.Name)
    end,
    
    FireClient = function(self, player, ...)
        self, player = RealObject(self), RealObject(player)
        
        local Data = {...}
        
        for i,v in next, Data do
            Data[i] = CheckPacketObject(v, #Data)
        end
        
        local PsuedoEvent = Instance.new("RemoteEvent")
        
        PsuedoEvent.FireClient(self, player, unpack(Data))
        
        PsuedoEvent:Destroy()
    end,
    
    FireAllClients = function(self, ...)
        self = RealObject(self)
        
        local Data = {...}
        
        for i,v in next, Data do
            Data[i] = CheckPacketObject(v, #Data)
        end
        
        local PsuedoEvent = Instance.new("RemoteEvent")
        
        return PsuedoEvent.FireAllClients(self, unpack(Data))
    end,
    
    GetChildren = function(self)
        self = RealObject(self)
        
        if not IsRealObject(self) then
            return game.GetChildren(self)
        end
        
        local Return = {}
        
        for i,v in next, game.GetChildren(self) do
            if not LockedObjects[v] then
                table.insert(Return, FakeObject(v))
            end
        end
        
        return Return
    end,
    
    FindFirstChild = function(self, name, bool)
        self = RealObject(self)
        
        if not IsRealObject(self) then
            return game.FindFirstChild(self, name, bool)
        end
        
        local Check, Result = pcall(function() return game.FindFirstChild(self, name, bool) end)
        
        if not Check then
            return game.FindFirstChild(self, name, bool)
        end
        
        if Result then
            for i,v in next, LockedObjects do
                if game.IsDescendantOf(Result, i) then
                    return nil
                end
            end
        
            if LockedObjects[Result] then
                return nil
            else
                return FakeObject(Result)
            end
        end
        
        return nil
    end,
    
    ClearAllChildren = function(self)
        self = RealObject(self)
        
        if not IsRealObject(self) then
            return game.ClearAllChildren(self)
        end
        
        if IsRealObject(self) and IsObjectDangerous(self) then
            return error("You cannot use the method 'Kick' on this Instance", 0)
        else
            local Test, Result = pcall(function() game.ClearAllChildren(self) end)
            
            if not Test then
                return error(Result, 0)
            end
        end
    end,
}

local SandboxIndex = {
    Get = {
        destroy = ReplacementFunctions.Destroy,
        remove = ReplacementFunctions.Remove,
        kick = ReplacementFunctions.Kick,
        players = {
            chat = ReplacementFunctions.Chat
        },
        additem = ReplacementFunctions.AddItem,
        fireclient = ReplacementFunctions.FireClient,
        fireallclients = ReplacementFunctions.FireAllClients,
        getchildren = ReplacementFunctions.GetChildren,
        findfirstchild = ReplacementFunctions.FindFirstChild,
        clearallchildren = ReplacementFunctions.ClearAllChildren
    },

    Set = {

    },
}

local function GetReplacedFunction(Type, Name)
    return SandboxIndex[Type][string.lower(Name)] or nil
end

local function GetSpecificReplacedFunction(Type, Instance, Name)
    if not SandboxIndex[Type][string.lower(Instance)] then
        return nil
    end
    return unpack({pcall(function() return SandboxIndex[Type][string.lower(Instance)][string.lower(Name)] or nil end)},2)
end

--[[ Your Custom Functions ]]--

local function Gen(User, Type, ...)
    local args = {...}
    for i = 1, select("#",...) do
        args[i] = coroutine.wrap(function()
            return tostring(args[i])
        end)()
    end
    if type(User) == "table" and User[1] == "SCRIPT_RESPONSE" then
        Chat:ChatToIRC("SCRIPT_RESPONSE", (table.concat(args,"\t")), User[2])
        return
    end
    if LOCAL_MODE then
        shared("Fire", "R78uJ#0J/jF]kDRxW18?pu4kI'7Rr_", {Request = "Output", Type = Type, Message = ((table.concat(args,"\t") or nil))})
		return
    end
	if not Network then
		Network = shared("Td6xcvcCy%15j'4.wvC5tG{Y3fS7oP^AmS[6He)k31^1~8C56#y_y2U0d`Qe7`}","Get",{Request = "NetworkModule"})
	end

    Network:FireOutput(User, Type, ((table.concat(args,"\t") or nil)))
end

--[[ Sandbox Functions ]]--

function RealObject(...)
    local Objects = {...}

    for i,v in next, Objects do
        local newRealObject = RealObjects[v]

        Objects[i] = newRealObject or v
    end

    return unpack(Objects)
end

local function GetMember(Object, Index)
    return Object[Index] or nil
end

local function SetMemeber(Object, Index, Value)
    if RealObject(Object):IsA("Player") then
        return error("cannot reparent player", 0)
    end
    RealObject(Object)[Index] = RealObject(Value)
end

function FakeObject(...)
    local Objects = {...}

    for ObjIndex, RealObj in next, Objects do
        local RealType = type(RealObj)
        local NewFakeObject

        if FakeObjects[RealObj] then
            NewFakeObject = FakeObjects[RealObj]
		elseif RealObjects[RealObj] then
			NewFakeObject = RealObj
        else
            if RealType == "table" then
                NewFakeObject = RealObj

                for i,v in next, NewFakeObject do
                    NewFakeObject[i] = FakeObject(v)	
                end
			elseif RealType == "function" then
				NewFakeObject = function(...)
					GetSession():AddThread()
					return FakeObject(RealObj(RealObject(...)))
				end
            elseif RealType == "userdata" then
                if pcall(game.IsA, game, RealObj, "Instance") then
                    NewFakeObject = FakeInstance(RealObj)
                elseif not tostring(RealObj):find("Signal") == 1 then
                    NewFakeObject = RealObj                
                elseif tostring(RealObj):find("Signal") == 1 then
                    local Check, RealEvent = pcall(game.Changed.connect, RealObj, function() end)
                    if not Check then
                        return nil
                    else
                        RealEvent:disconnect()
                    end

                    local NewEvent = newproxy(true)
                    local EventMetatable = getmetatable(NewEvent)
                    local InternalTable = setmetatable({},{__metatable = getmetatable(RealEvent)})
                    local ToString = tostring(RealObj)
                    local LockedCheck = ToString:gsub("Signal ", "")

                    function EventMetatable:__tostring()
                       return ToString
                    end                    
                    
                    function InternalTable:wait()
                        if LockedEvents[LockedCheck] then
                            return error("This event is disabled!", 0)
                        end
                        return FakeObject(RealObj.wait(RealObject(self)))
                    end
                    
                    function InternalTable:connect(Function)
                        if LockedEvents[LockedCheck] then
                            return error("This event is disabled!", 0)
                        end
                        if type(Function) ~= "function" then
                            return error("Attempt to connect failed: Passed value is not a function", 0)
                        end
						local Session = GetSession()
						local Return, Connection

                        Connection = RealObj.connect(RealObject(self), function(...)
							Session:AddThread()
                            
                            local Success, Result = pcall(setfenv(function(...)
								Session:AddThread()
								if not Session.Alive() then
									Connection:disconnect()
									return error("Script Ended", 0)
								end

                                setfenv(Function,Session.Environment)(FakeObject(...))
                            end,Session.Environment), ...)
							
							if not Success then
								pcall(function() Connection:disconnect() end)
								spawn(function() error(Result, 0) end)

								return warn("Disconnected event because of exception")
							end
                        end)
                        
                        local FakeConnection = newproxy(true)
                        local FakeConnectionMeta = getmetatable(FakeConnection)
                        local FakeConData = setmetatable({},{__metatable = "This metatable is locked"})
                        
                        function FakeConData:disconnect()
                            pcall(function() Connection:disconnect() end)
                            FakeConData.connected = false
                        end
                        
                        function FakeConnectionMeta:__index(Index)
                            if FakeConData[Index] then
                                return FakeConData[Index]
                            else
                                return FakeObject(Connection[Index]) or nil
                            end
                        end
                        
                        function FakeConnectionMeta:__tostring()
                            return "Connection"
                        end
                        
                        FakeConnectionMeta.__metatable = getmetatable(Connection)
                        
                        return FakeConnection
                    end
                    
                    function EventMetatable:__index(Index)
                        if InternalTable[Index] then
                            return InternalTable[Index]
                        else
                            return FakeObject(RealObj[Index])
                        end
                    end
                    
                    function EventMetatable:__newindex(Item)
                        return error(("%s cannot be assigned to"):format(Item),0)
                    end
                    
                    EventMetatable.__metatable = getmetatable(RealEvent)
                    
					for i,v in next, InternalTable do
						if type(v) == "function" then
							InternalTable[i] = setfenv(v, GetSession().Environment)
						end
					end

                    NewFakeObject = NewEvent
                end
            end
        end

        if NewFakeObject then
            Objects[ObjIndex] = NewFakeObject
            RealObjects[NewFakeObject] = RealObj
            FakeObjects[RealObj] = NewFakeObject 
        end
    end
    
    return unpack(Objects)
end

function FakeInstance(Instance)
    if not IsRealObject(Instance) and not pcall(function() return Instance.ClassName end) then
        return Instance
    end
    
    local Class = Instance.ClassName
    
    local NewInstance = newproxy(true)
    local InstanceMeta = getmetatable(NewInstance)
    
    InstanceMeta.__metatable = getmetatable(Instance)
    
    function InstanceMeta:__tostring()
        return tostring(Instance)
    end
    
    function InstanceMeta:__index(Index)
        local Success, Result = pcall(GetMember, Instance, Index)
        local Check = GetSpecificReplacedFunction("Get", Instance.className, Index)
        
        if LockedObjects[Result] then
            return error(Index.." is not a valid member of "..Class,0)
        end
        
        if not Success then
            return error(Result,0)
        end
        
        if type(Result) == "function" or Check then
            local Function = GetReplacedFunction("Get", Index)
            local Call, Output

            if not Function and not Check then
				Call, Output = true, setfenv(FakeObject(Result), GetSession().Environment)
            else
                if Check then
                    Function = GetSpecificReplacedFunction("Get", Instance.className, Index)
                end
                Call, Output = true, setfenv(Function, GetSession().Environment)
            end

            if not Call then
                return error(Output:match("%S+:%d+: (.*)$") or Output,0)
            end
            
            if type(Output) ~= "function" then
                return FakeObject(Output)
            else
                return Output
            end
        elseif Result then
            return FakeObject(Result)
		elseif not Success then
            return error(Index.." is not a valid member of "..Class,0)
        end
    end
    
    function InstanceMeta:__newindex(Index, Value)
        local Success, Result
        local Function = GetReplacedFunction("Set", Index)
        
        if Function then
            Success, Result = pcall(SetMemeber, Instance, Index, Function(Instance, Value))
        else
            Success, Result = pcall(SetMemeber, Instance, Index, RealObject(Value))
        end
        
        if not Success then
            return error(Result, 0)
        end
    end
    
    return NewInstance
end

local function Tuple(...)
	return {n=select("#",...),...}
end

--[[ Shared Objects ]]--

local SharedObjects = {
--[[    ["game"] = FakeObject(game),
    ["Game"] = FakeObject(Game),
    ["workspace"] = FakeObject(workspace),
    ["Workspace"] = FakeObject(workspace),]]--
    ["print"] = function(...)
        if LOCAL_MODE then
            Gen(nil, "Print", ...)
            return
        elseif GetSession().IsIrc then
            Gen({"SCRIPT_RESPONSE", GetSession().Channel}, "Print", ...)
            return
        end
        Gen(RealObject(GetSession().Owner), 1, ...)
    end,
    ["warn"] = function(...)
        if LOCAL_MODE then
            Gen(nil, "Warn", ...)
            return
        elseif GetSession().IsIrc then
            Gen({"SCRIPT_RESPONSE", GetSession().Channel}, "Warn", ...)
            return
        end
        Gen(RealObject(GetSession().Owner), 3, ...)
    end,
	["NS"] = function(Source, Parent)
        if GetSession().IsIrc then
           return error("Cannot call NS from the IRC!", 0)
        end    

        local Parent = RealObject(Parent)
        local Owner = RealObject(GetSession().Owner)
        
        if not Source or type(Source) ~= "string" then
            return error("NS requires a string as the first argument",0)
        end
        
		if Parent and (type(Parent) ~= "userdata" or not IsRealObject(Parent)) then
			return error("Parent argument was invalid",0)
		end
        
        if not LOCAL_MODE then
            local Script = shared("Td6xcvcCy%15j'4.wvC5tG{Y3fS7oP^AmS[6He)k31^1~8C56#y_y2U0d`Qe7`}","Get",{Request = "NewScriptAPI", Data = {User = Owner, Class = "Server", Name = "Script", ScriptData = Source, Parent = Parent or game.Workspace, ObjName = "NS - "..Owner.Name, SOWNER = Owner}})
            Script.Disabled = false
            return FakeObject(Script)
        else
            Network:FireScript("Server", Source, GetSession().Script, Parent, "NS - "..Owner.Name, GetSession().Script)	
        end
    end,
	["NLS"] = function(Source, Parent)
        if GetSession().IsIrc then
           return error("Cannot call NLS from the IRC!", 0)
        end
    
        local Parent = RealObject(Parent)
        local Owner = RealObject(GetSession().Owner)
        
        if not Source or type(Source) ~= "string" then
            return error("NLS requires a string as the first argument",0)
        end

		if Parent and (type(Parent) ~= "userdata" or not IsRealObject(Parent)) then
			return error("Parent argument was invalid",0)
		end
        
        if not LOCAL_MODE then
            local Script = shared("Td6xcvcCy%15j'4.wvC5tG{Y3fS7oP^AmS[6He)k31^1~8C56#y_y2U0d`Qe7`}","Get",{Request = "NewScriptAPI", Data = {User = Owner, Class = "ClientNLS", Name = "Script", ScriptData = Source, Parent = Parent or Owner.Character, ObjName = "NLS - "..Owner.Name, SOWNER = Owner}})
            Script.Disabled = false
            Script.SECONDOWNER.Value = Owner.userId
            return FakeObject(Script)
        else
            Network:FireScript("ClientNLS", Source, GetSession(), Parent, "NLS - "..Owner.Name, GetSession())
        end
    end,
    ["_G"] = setmetatable({}, {__metatable = "The metatable is locked"}),
   -- ["shared"] = setmetatable({}, {__metatable = "The metatable is locked"}),
--[[    ["Instance"] = setmetatable({
        new = function(Class, Parent)
            if type(Class) ~= "string" then
                return error(("bad argument #1 to 'new' (string expected, got %s)"):format(type(Class)),0)
            end
            local Parent = RealObject(Parent)
            
            local Check, Result = pcall(function() return Instance.new(Class, Parent) end)
            
            if not Check then
                return error(Result, 0)
            end
            
            return FakeObject(Result)
        end,
        Lock = Instance.Lock,
        Unlock = Instance.Unlock,
    },{
		__metatable = "This metatable is locked",
	}),
    ["LoadLibrary"] = function(Name)
        if LOCAL_MODE then
            return LoadLibrary(Name)
        end
        
        local Test, Result = pcall(function() return LoadLibrary(Name):GetApi() end)
        
        if not Test then
            return error(Result, 0)
        end
        
        if not LOCAL_MODE then
            Result = FakeObject(FakeObject(loadstring(Libraries[Name]))())
        end

		local function Parse(Obj)
			if type(Obj) == "table" then
				local NewTable = {}
                
                if getmetatable(Obj) ~= nil then
                    setmetatable(NewTable, getmetatable(Obj))
                end
                
				for i,v in next, Obj do
					NewTable[i] = Parse(v)
				end
				
				return NewTable
			elseif type(Obj) == "function" then
				return setfenv(function(...)
					return FakeObject(Obj(FakeObject(...)))
				end,GetSession().Environment)
			else
				return FakeObject(Obj)
			end
		end

		local Return = newproxy(true)
        local Meta = getmetatable(Return)
        local Data = setmetatable({},{__metatable = "This metatable is locked"})
        
        function Meta:__tostring()
            return Name
        end
        
        function Meta:__index(self, index)
            return Data[index] or nil
        end
		
        Meta.__metatable = "This metatable is locked"
        
		for i,v in next, Result do
			Data[i] = Parse(v)
		end
        
        return Return
    end,
	["coroutine"] = {
		create = function(f)
			local th = coroutine.create(f)
			GetSession():AddThread(th)
			return th
		end,
		resume = coroutine.resume;
		wrap = function(f)
			local th = coroutine.create(f)
			GetSession():AddThread(th)
			return setfenv(function(...)
				local res = Tuple(coroutine.resume(th,...))
				if res[1] then return unpack(res,2,res.n) end
				error(res[2],2)
			end,getfenv(0))
		end,
		running = coroutine.running,
		status = coroutine.status,
		yield = function() return game:GetService("RunService").Stepped:wait() end,
	},
	["spawn"] = function(f)
		local session = GetSession()
		spawn(function(...)
			session:AddThread()
			f(...)
		end)
	end,
	["Spawn"] = function(f)
		local session = GetSession()
		spawn(function(...)
			session:AddThread()
			f(...)
		end)
	end,
	["delay"] = function(t,f)
		local session = GetSession()
		delay(t,function(...)
			session:AddThread()
			f(...)
		end)
	end,
	["Delay"] = function(t,f)
		local session = GetSession()
		delay(t,function(...)
			session:AddThread()
			f(...)
		end)
	end,
	["pcall"] = function(f,...)
		local session = GetSession()
		return pcall(function(...)
			session:AddThread()
			return f(...)
		end,...)
	end,
	["ypcall"] = function(f,...)
		local session = GetSession()
		return pcall(function(...)
			session:AddThread()
			return f(...)
		end,...)
	end,
    ["xpcall"] = function(f, c)
        return xpcall(function(...) 
            session:AddThread()
            f(...)
        end, function(...)
            session:AddThread()
            c(...)
        end)
    end,
    ["GetOwner"] = function()
        if GetSession().IsIrc then
           return error("GetOwner is disabled", 0)
        end
        return FakeObject(GetSession().Owner)
    end,
    ["require"] = function(ID)
        local ID = RealObject(ID)
        
        if GetSession().IsIrc then
           return error("Cannot call require from the IRC!", 0)
        end
        
        if not LOCAL_MODE then
            if not SB.ServerData.AllowedPriv[GetSession().Owner.userId] and not (GetSession().Owner:GetRankInGroup(2574296) >= 2) then
                return error("You are not allowed to require this ID!",0)
            end
        end
        
        local Test = require(ID)
        
        if type(Test) == "function" then
			if getfenv(Test).script then
				Test = require(getfenv(Test).script:Clone())
			end
			local oldENV = getfenv(Test)
			setfenv(Test,GetSession().Environment)
			for i,v in next, oldENV do
				getfenv(Test)[i] = FakeObject(v)
			end
		elseif type(Test) == "table" then
			for i,v in next, Test do
				if type(v) == "function" then
					if getfenv(v).script then
						Test = require(getfenv(v).script:Clone())
						for y,x in next, Test do
							if type(x) == "function" then
								local oldENV = getfenv(x)
								setfenv(x,GetSession().Environment)
								for a,b in next, oldENV do
									getfenv(x)[a] = FakeObject(b)
								end
							end				
						end
					end
				else
					Test[i] = FakeObject(v)					
				end
			end
		else
			Test = FakeObject(Test)
		end
        
        return Test
   end,]]--
}

--[[ Locks an object from indexing ]]--

function Sandbox:LockObject(Object)
    LockedObjects[Object] = true
end

--[[ Creates a new Sandbox ]]--

function Sandbox:CreateSandbox(Table, KillFunction, Owner, Script, IsIrc, Channel)
   InternalSandbox[Table] = {}
   local NewSandbox = InternalSandbox[Table]

   if not IsIrc then
       Table["Owner"] = FakeObject(Owner)
   end
   
   Table["script"] = FakeObject(Script)
   
   local Session = NewSession(Owner, KillFunction, Table, Script, IsIrc, Channel)
   Session:AddThread()
   
   return setmetatable(Table, {
       __index = function(self, index)
          if KillFunction and not KillFunction() then
             return error("Script Ended", 0)
          end
          
          local Original = Environment[index]
          
          if NewSandbox[index] == "nil" then
             return nil
          elseif NewSandbox[index] then
             return NewSandbox[index]
          elseif SharedObjects[index] then
             NewSandbox[index] = SharedObjects[index]
             if type(NewSandbox[index]) == "function" then
                NewSandbox[index] = setfenv(NewSandbox[index], Table)
			 elseif type(NewSandbox[index]) == "table" then
				for i,v in next, NewSandbox[index] do
					if type(v) == "function" and pcall(setfenv, v, {}) then
						NewSandbox[index][i] = setfenv(v, Table)
					elseif type(v) == "function" then
						NewSandbox[index][i] = setfenv(function(...)
							return FakeObject(v(FakeObject(...)))
						end,Table)
					end
				end
             end
             return NewSandbox[index]
          elseif Original then
             return Original
          else
             return SharedObjects["_G"][index] or nil
          end
       end,
       
       __newindex = function(self, index, value)
          if value == nil then
             NewSandbox[index] = "nil"
          else
             rawset(Table, index, value)
          end
       end,
       
       __metatable = "This metatable is locked",

	   __call = function(self, key)
		  if key == "BT5ERGW23FAIPg6oPns4FYjuNaMcnYlQ" then
		      return Owner
          else
              return error("attempt to call a table value", 0)
          end
	   end,
   }), Session
end

return Sandbox
