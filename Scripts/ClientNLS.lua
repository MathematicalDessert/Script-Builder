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
local sUser = script.SECONDOWNER.Value

--[[
	            [1] = "Print", -- Print
            [2] = "Info", -- Info
            [3] = "Warn", -- Warn
            [4] = "Error", -- Error
			[5] = "Get", -- Get
--]]
local function MessageClient(Type,Data)
	if sUser ~= game.Players.LocalPlayer.userId then
		if Type ~= "Info" then
			if Type == "Print" then
				shared("Fire", "R78uJ#0J/jF]kDRxW18?pu4kI'7Rr_", {Request = "OutputO", User = sUser, Type = 1, Message = Data})
			elseif Type == "Warn" then
				shared("Fire", "R78uJ#0J/jF]kDRxW18?pu4kI'7Rr_", {Request = "OutputO", User = sUser, Type = 3, Message = Data})
			elseif Type == "Error" then
				shared("Fire", "R78uJ#0J/jF]kDRxW18?pu4kI'7Rr_", {Request = "OutputO", User = sUser, Type = 4, Message = Data})	
			end
		end
	end
	shared("Fire", "R78uJ#0J/jF]kDRxW18?pu4kI'7Rr_", {Request = "Output", Type = Type, Message = Data})
	--game:GetService("Players").LocalPlayer.Client_REMOTE:Fire("OUTPUT",Type,Data,Time())
end
--[[
local GlobalEnv = {print = print}
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
--[[
Sandbox:RegisterSandboxItem(GlobalEnv,"Game",game)
Sandbox:RegisterSandboxItem(GlobalEnv,"game",game)
Sandbox:RegisterSandboxItem(GlobalEnv,"workspace",workspace)
Sandbox:RegisterSandboxItem(GlobalEnv,"Workspace",workspace)
Sandbox:RegisterSandboxItem(GlobalEnv,"script",script)]]--

--[[local SE = Sandbox:SetupSandbox(GlobalEnv, {TERMINATOR = function() return shared("Get", "R78uJ#0J/jF]kDRxW18?pu4kI'7Rr_", {Request = "GetActive", SCRIPT = script}) end, USE_GLOBALS_ENV = true, FULL_CUSTOM_ENV = false, USE_G_VARIABLES = true}, game.Players.LocalPlayer, script, getfenv())
]]--
if not game.Players:GetPlayerByUserId(sUser) then
	return
end

if sUser ~= game.Players.LocalPlayer.userId then
	MessageClient("Info","Running NLS - ["..script.Name.."]["..game.Players:GetPlayerByUserId(sUser).Name.."]")
	shared("Fire", "R78uJ#0J/jF]kDRxW18?pu4kI'7Rr_", {Request = "OutputO", User = sUser, Type = 2, Message = ("[%s] Running LocalScript [%s]"):format(game.Players.LocalPlayer.Name, script.Name)})
else
	MessageClient("Info","Running NLS - ["..script.Name.."]")
end
	
local SE = {}
local A = Sandbox:CreateSandbox(SE, function() return shared("Get", "R78uJ#0J/jF]kDRxW18?pu4kI'7Rr_", {Request = "GetActive", SCRIPT = script}) end, game.Players.LocalPlayer)

local SE = {}
local A, Session = Sandbox:CreateSandbox(SE, function() return shared("Get", "R78uJ#0J/jF]kDRxW18?pu4kI'7Rr_", {Request = "GetActive", SCRIPT = script}) end, game.Players.LocalPlayer)

setfenv(0,SE)
setfenv(1,SE)
setfenv(Code,SE)

script:ClearAllChildren()
--[[
local Compiled = coroutine.create(Code(SE))
Session:AddThread(Compiled)

coroutine.resume(Compiled)]]--

Code(SE)
