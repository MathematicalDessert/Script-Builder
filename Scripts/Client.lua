script:WaitForChild("SourceLoader")

local HeaderC, CheckC = pcall(function() require(script.SourceLoader) end)

if not HeaderC then
	return error(CheckC,0)
end

local script = script
local Sandbox = shared("Get", "R78uJ#0J/jF]kDRxW18?pu4kI'7Rr_", {Request = "Sandbox", SCRIPT = script})
local Owner   = game.Players.LocalPlayer
local Code    = require(script.SourceLoader)
local T_STR   = tostring
local tostring = tostring

local function MessageClient(Type,Data)
	shared("Fire", "R78uJ#0J/jF]kDRxW18?pu4kI'7Rr_", {Request = "Output", Type = Type, Message = Data})
end

--[[local GlobalEnv = {print = print}
local S = Sandbox:NewSandbox(GlobalEnv)

Sandbox:RegisterSandboxItem(GlobalEnv,"print",function(...)
    local args = {...}
    for i = 1, select("#",...) do
        args[i] = tostring(args[i])
    end

	MessageClient("Print", table.concat(args,"\t"))
end)

Sandbox:RegisterSandboxItem(GlobalEnv,"warn",function(...)
    local args = {...}
    for i = 1, select("#",...) do
        args[i] = tostring(args[i])
    end

    MessageClient("Warn", table.concat(args,"\t"))
end)]]--

--[[Sandbox:RegisterSandboxItem(GlobalEnv,"Game",game)
Sandbox:RegisterSandboxItem(GlobalEnv,"game",game)
Sandbox:RegisterSandboxItem(GlobalEnv,"workspace",workspace)
Sandbox:RegisterSandboxItem(GlobalEnv,"Workspace",workspace)
Sandbox:RegisterSandboxItem(GlobalEnv,"script",script)]]--

--local SE = Sandbox:SetupSandbox(GlobalEnv, {TERMINATOR = function() return shared("Get", "R78uJ#0J/jF]kDRxW18?pu4kI'7Rr_", {Request = "GetActive", SCRIPT = script}) end, USE_GLOBALS_ENV = true, FULL_CUSTOM_ENV = false, USE_G_VARIABLES = true}, game.Players.LocalPlayer, script, getfenv())

MessageClient("Info","Running LocalScript ["..script.Name.."]")
local SE = {}
local A, Session = Sandbox:CreateSandbox(SE, function() return shared("Get", "R78uJ#0J/jF]kDRxW18?pu4kI'7Rr_", {Request = "GetActive", SCRIPT = script}) end, game.Players.LocalPlayer)

setfenv(0,SE)
setfenv(1,SE)
setfenv(Code,SE)

script:ClearAllChildren()

--local Compiled = coroutine.create(Code,SE)
--Session:AddThread(Compiled)

--coroutine.resume(Compiled)

--script:ClearAllChildren()--]]--

--local Check, Response = pcall(function(a) Code(a) end,getfenv())

--[[if not Check then
	return error(Response, 0)
end]]--
spawn(function() Session:AddThread() setfenv(Code,SE)(SE) end)
