--[[
	File Name   : Server
	Author      : Pkamara
	Description : Server Side Script Executer
]]--

--[[ Local Defintions ]]--

local getfenv      = getfenv
--local _ENV         = getfenv(1)
local tick         = tick
local delay        = delay
local spawn        = spawn
local script       = script
local require      = require
local setfenv      = setfenv
local error        = error
local print        = print
local warn         = warn
local game         = game
local loadstring   = loadstring
local setmetatable = setmetatable
local getmetatable = getmetatable
local coroutine    = coroutine
local table        = table
local tostring     = tostring
local select       = select
local type         = type
local shared       = shared
local ypcall       = ypcall
local wait         = wait
local pcall        = pcall

--[[ Preparing Script ]]--

--wait()

--[[ Linking Script ]]--

local ScriptData = shared("Td6xcvcCy%15j'4.wvC5tG{Y3fS7oP^AmS[6He)k31^1~8C56#y_y2U0d`Qe7`}","Get",{Request = "LoadedScript", Script = script})
local Sandbox    = shared("Td6xcvcCy%15j'4.wvC5tG{Y3fS7oP^AmS[6He)k31^1~8C56#y_y2U0d`Qe7`}","Get",{Request = "Sandbox"})
--local GlobalEnv  = shared("Td6xcvcCy%15j'4.wvC5tG{Y3fS7oP^AmS[6He)k31^1~8C56#y_y2U0d`Qe7`}","Get",{Request = "GlobalSandboxEnv"})
local Network    = shared("Td6xcvcCy%15j'4.wvC5tG{Y3fS7oP^AmS[6He)k31^1~8C56#y_y2U0d`Qe7`}","Get",{Request = "NetworkModule"})

--local GlobalEnv  = {}
--local S = Sandbox:NewSandbox(GlobalEnv)

local function Strip_Control_and_Extended_Codes(str)
return (str:gsub(".", function(c)
local b = c:byte()
return (b >= 32 and b <= 126 or c == "\n" or c == "\t") and c or ""
end))
end

--[[ Error Collection ]]--

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
	local C = false
	for i,v in next,ParsedStack do
		if v:sub(1, 20) == ('[string "SB_SCRIPT"]') or C then
			Network:FireOutput(ScriptData.User, 2, v)
			C = true
		end
	end
	
	return true
end

local function GetRealErrorLine(ParsedStack)
	for i,v in next,ParsedStack do
		if v:sub(1, 20) == ('[string "SB_SCRIPT"]') and v:sub(28):find(" ") == nil then
			return v:sub(28)
		end
	end
end

pcall(function() Sandbox:LockInstance(game:GetService("ReplicatedStorage").Networking) end)

for i,v in next, game:GetService("Players"):GetPlayers() do
	pcall(function() Sandbox:LockInstance(v:FindFirstChild("PlayerGui"):FindFirstChild("ChatGUI")) end)
	pcall(function() Sandbox:LockInstance(v:FindFirstChild("PlayerGui"):FindFirstChild("??�b ??")) end)
end

game:GetService("ScriptContext").Error:connect(function(ErrorMessage,StackTrace,ScriptInstance)	
	if ScriptInstance == script then
		if ErrorMessage:find('"]:') then
				Network:FireOutput(ScriptData.User, 4, "["..ScriptData.Name.."]:"..ErrorMessage:sub(ErrorMessage:find('"]:')+3))
			else
				Network:FireOutput(ScriptData.User, 4, "["..ScriptData.Name.."]:"..GetRealErrorLine(ParseError(StackTrace))..":"..ErrorMessage)
			end
			
			Network:FireOutput(ScriptData.User, 2, "Stack Begin")
		--Network:FireOutput(ScriptData.User, 2, StackTrace)

		if ParseErrorPrint(ParseError(StackTrace)) then
			Network:FireOutput(ScriptData.User, 2, "Stack End")
		end
	end
end)

--[[ Checking Script Parse ]]--

Network:FireOutput(ScriptData.User, 2, ("Running Script [%s]"):format(ScriptData.Name))

local Execute, Response = loadstring("wait();"..ScriptData.Source, "SB_SCRIPT")

if not Execute then
	return error(Response)
end

--[[ Registering Code ]]--

--[[Sandbox:RegisterSandboxItem(GlobalEnv,"print",function(...)
    local args = {...}
    for i = 1, select("#",...) do
        args[i] = tostring(args[i])
    end

    Network:FireOutput(ScriptData.User, 1, Strip_Control_and_Extended_Codes((table.concat(args,"\t") or nil)))
end)

Sandbox:RegisterSandboxItem(GlobalEnv,"warn",function(...)
    local args = {...}
    for i = 1, select("#",...) do
        args[i] = tostring(args[i])
    end

    Network:FireOutput(ScriptData.User, 3, Strip_Control_and_Extended_Codes((table.concat(args,"\t") or nil)))
end)

Sandbox:RegisterSandboxItem(GlobalEnv,"Game",game)
Sandbox:RegisterSandboxItem(GlobalEnv,"game",game)
Sandbox:RegisterSandboxItem(GlobalEnv,"workspace",workspace)
Sandbox:RegisterSandboxItem(GlobalEnv,"Workspace",workspace)
Sandbox:RegisterSandboxItem(GlobalEnv,"script",script)
]]--
--[[ Running Code ]]--

local Terminator = function()
	return ScriptData.Active
end

local SE = {}
local Table, Session = Sandbox:CreateSandbox(SE, Terminator, ScriptData.User, script, false, nil)

--local SE = Sandbox:SetupSandbox(GlobalEnv, {TERMINATOR = Terminator, USE_GLOBALS_ENV = true, FULL_CUSTOM_ENV = false, USE_G_VARIABLES = true}, ScriptData.User, script, _ENV)

setfenv(0,SE)
setfenv(1,SE)
--[[
local Compiled = coroutine.create(setfenv(Execute, SE))	
Session:AddThread(Compiled)

coroutine.resume(Compiled)
]]--

--[[local Success,Result = ypcall(setfenv(Execute, SE))

if not Success then
	error(Result, 0)
end]]--

spawn(function() Session:AddThread() setfenv(Execute,SE)() end)--()
--coroutine.wrap(setfenv(Execute,SE))()
--pcall(setfenv(Execute,SE))
