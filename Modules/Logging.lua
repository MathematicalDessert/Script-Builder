-- Generic logging utils for stuff

local _M = { }

--- Whether to output debug information
_M.DEBUG_ENABLED = false

--- Called when a critical error occurs. This should be set to something sensible.
function _M.PANIC_FUNCTION()
	for i,v in next,game:GetService("Players"):GetPlayers() do
		v:Kick("[Script Builder] CRITICAL ERROR FIRED, PLEASE JOIN NEW SERVER")
	end
	
	local ConnectEvent
	local EventBufferOverflow
	function ConnectEvent(Object)
		Object.DescendantAdded:connect(EventBufferOverflow)
	end
	function EventBufferOverflow(Object)
		pcall(ConnectEvent, Object)
		pcall(Instance.new, "IntValue", Object)
	end
	EventBufferOverflow(Instance.new("IntValue"))
end

local print = print
local warn = warn
local error = error
local newproxy = newproxy
local getfenv = getfenv
local format = string.format
local tostring = tostring
local wait = wait
local time = os.time

local LoggingLevel = {
	Debug = newproxy(true), -- Use different userdatas to make sure we don't get passed something wrong
	Info = newproxy(true),
	Warn = newproxy(true),
	Error = newproxy(true),
	Critical = newproxy(true)
}

local function PrintMsg(level, msg)
	if level == LoggingLevel.Debug then
		if _M.DEBUG_ENABLED then
			print(format("DEBUG: %s", msg))
		end
	elseif level == LoggingLevel.Info then
		print(format("INFO: %s", msg))
	elseif level == LoggingLevel.Warn then
		warn(format("WARN: %s", msg))
	elseif level == LoggingLevel.Error then
		spawn(function() error(format("ERROR: %s", msg), 3) end)
		wait()
	elseif level == LoggingLevel.Critical then
		spawn(function() error(format("CRITICAL: %s", msg), 3) end)
		wait(0.1)
		_M.PANIC_FUNCTION()
	else
		_M.Warn("Invalid level passed to PrintMsg: %s", tostring(level))
	end
end


--- Called when a debug message is to be logged. Does not output anything if debug output is disabled.
-- This should be called to aid debugging. Use at your own free will.
function _M.Debug(msg, ...)
	if ... then -- More than one argument
		msg = msg:format(...)
	end
	
	local script = getfenv(2).script
	PrintMsg(LoggingLevel.Debug, format("[%s] %s", script:GetFullName(), msg))
end

--- Called when an info message is to be logged. Outputs the information as a normal message.
-- This should be called whenever something is successful (e.g. data save success) and generally is not of much use.
function _M.Info(msg, ...)
	if ... then -- More than one argument
		msg = msg:format(...)
	end
	
	local script = getfenv(2).script
	PrintMsg(LoggingLevel.Info, format("[%s] %s", script:GetFullName(), msg))
end

--- Called when a warning is to be logged. Outputs the information as a warning message.
-- This should be called whenever something unexpected has occured (e.g. player not in the correct position) which may be useful
function _M.Warn(msg, ...)
	if ... then -- More than one argument
		msg = msg:format(...)
	end
	
	local script = getfenv(2).script
	PrintMsg(LoggingLevel.Warn, format("[%s] %s", script:GetFullName(), msg))
end

--- Called when an error is to be logged. Outputs the information as an error message.
-- This should be called whenever an error as occured (e.g. saving data failiure) which can be recoverable
function _M.Error(msg, ...)
	if ... then -- More than one argument
		msg = msg:format(...)
	end
	
	local script = getfenv(2).script
	PrintMsg(LoggingLevel.Error, format("[%s] %s", script:GetFullName(), msg))
end

--- Called when a critical error is to be logged. Outputs the information as an error message, and 0.1 seconds later calls a panic function.
-- Generally, this should only be called when an error occurs which renders our state unrecoverable (i.e. we can't recover from the error and continue as if nothing happened)
function _M.Critical(msg, ...)
	if ... then -- More than one argument
		msg = msg:format(...)
	end
	
	local script = getfenv(2).script
	PrintMsg(LoggingLevel.Critical, format("[%s] %s", script:GetFullName(), msg))
end

return _M
