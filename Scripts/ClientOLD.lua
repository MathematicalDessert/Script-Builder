script:WaitForChild("Parser")
script:WaitForChild("EncryptedName")

local Sandbox = require(script.Sandbox)("x6-lpv6{=]Mx8RGKz~DK7if`71s<G9")
local Owner   = game.Players.LocalPlayer
local Parser  = require(script.Parser)
local Source  = shared("Get",{Request = "ScriptSource", ScriptName = script.EncryptedName.Value})
local T_STR   = tostring
script.EncryptedName:Destroy()

local function MessageClient(Type,Data)
	shared("Fire",{Request = "Output", Type = Type, Message = Data})
	--game:GetService("Players").LocalPlayer.Client_REMOTE:Fire("OUTPUT",Type,Data,Time())
end


game:GetService("ScriptContext").Error:connect(function(ErrorMessage,StackTrace,ScriptInstance)	
	--[[if ScriptInstance == script then
		if string.find(ErrorMessage,"ServerScriptService.SB_SANDBOX") ~= nil then
			MessageClient("Error","["..script.Name.."] :"..ErrorMessage:sub(59))
		elseif ErrorMessage == nil then
			MessageClient("Error","["..script.Name.."] : An error occured!")
		elseif ErrorMessage == "" then
			MessageClient("Error","["..script.Name.."] : An error occured!")
		elseif string.find(ErrorMessage,"An error occured") then
			MessageClient("Error","["..script.Name.."] : An error occured!")
		else
			MessageClient("Error","["..script.Name.."] :"..ErrorMessage:sub(45))
		end
		--print(string.sub(ErrorMessage,string.find(ErrorMessage,script:GetFullName())))

		MessageClient("Run","Stack Begin")
		MessageClient("Run",StackTrace)
		MessageClient("Run","Stack End")
		--print(ErrorMessage,StackTrace,ScriptInstance)
	end]]--
end)

local Code,Error = pcall(function() return Parser.new():src_to_function(Source) end)
if not Code then
	script:ClearAllChildren()
	return error(Error)
else
	Code = Error
end

local GlobalEnv = {print = print}
local S = Sandbox:NewSandbox(GlobalEnv)

Sandbox:RegisterSandboxItem(GlobalEnv,"print",setfenv(function(...)
    local args = {...}
    for i = 1, select("#",...) do
        args[i] = tostring(args[i])
    end

    MessageClient("Print", (table.concat(args,"\t")))
end,{select = select, tostring = T_STR}))

Sandbox:RegisterSandboxItem(GlobalEnv,"warn",setfenv(function(...)
    local args = {...}
    for i = 1, select("#",...) do
        args[i] = tostring(args[i])
    end

    MessageClient("Warn", (table.concat(args,"\t")))
end,{select = select, tostring = T_STR}))

Sandbox:RegisterSandboxItem(GlobalEnv,"Game",game)
Sandbox:RegisterSandboxItem(GlobalEnv,"game",game)
Sandbox:RegisterSandboxItem(GlobalEnv,"workspace",workspace)
Sandbox:RegisterSandboxItem(GlobalEnv,"Workspace",workspace)
Sandbox:RegisterSandboxItem(GlobalEnv,"script",script)

local SE = Sandbox:SetupSandbox(GlobalEnv, {TERMINATOR = function() return true end, USE_GLOBALS_ENV = true, FULL_CUSTOM_ENV = false, USE_G_VARIABLES = true}, game.Players.LocalPlayer, script)

MessageClient("Info","Running ["..script.Name.."]")
setfenv(0,SE)
setfenv(1,SE)
setfenv(Code,SE)
--[[
setfenv(Code,getfenv(0))
setfenv(0,getfenv(1))
setfenv(1,getfenv(0))

getfenv(Code).print = function(...)
    local args = {...}
    for i = 1, select("#",...) do
        args[i] = tostring(args[i])
    end

    MessageClient("Print", (table.concat(args,"\t")))
end

getfenv(Code).warn = function(...)
    local args = {...}
    for i = 1, select("#",...) do
        args[i] = tostring(args[i])
    end

    MessageClient("Warn", (table.concat(args,"\t")))
end
]]--
script:ClearAllChildren()
Code()
--script:ClearAllChildren()
--Code(getfenv(Code))
