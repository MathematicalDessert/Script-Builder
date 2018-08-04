local Logging = require(script.Parent.Parent.Logging)
local Network = require(script.Parent.Parent.Network)

local HttpService = game:GetService("HttpService")
local IrcConnection = {}

local BASE_URL = "[REDACTED]"
local MAX_CONNECTION_ATTEMPTS = 20
local SESSION_ID = ""
local THREAD_RUNNING = false
local NICK = ""
local MESSAGE_HANDLER
local CONNECTION_ATTEMPTS = 0
local LISTENING = false
local CONNECTED = false
local RECONNECTING = false

local N_NICK = game.JobId
if N_NICK == "" then
	N_NICK = "PK_SB_STUDIO"
end


local StartListenThread
local function reconnect()
	local reqSuccess, connData = pcall(function()
		local str = ""
		for i,v in next, game:GetService("Players"):GetPlayers() do
			if not i == #game:getService("Players"):GetPlayers() then
				str = str..v.Name..", "
			else
				str = str..v.Name
			end
		end
		local data = HttpService:PostAsync(BASE_URL .. "get?self="..HttpService:UrlEncode(N_NICK).."&users="..str,"ImTotallyASecretKeyMadeForPeeka")
		return HttpService:JSONDecode(data)
	end)
	
	if not reqSuccess then
		if CONNECTION_ATTEMPTS < MAX_CONNECTION_ATTEMPTS then
			Logging.Debug("Connection Failiure: %s", connData)
			Logging.Info("Connection attempt failed. Trying again...")
			for _, Player in pairs(game:GetService("Players"):GetPlayers()) do
				pcall(Network.FireChat, Network, Player,"SERVER", "Failed to connect to Discord!", "ChannelMessage")
			end
			wait(1)
			CONNECTION_ATTEMPTS = CONNECTION_ATTEMPTS + 1
			reconnect()
		else
			Logging.Error("Too many failed connection attempts")
			for _, Player in pairs(game:GetService("Players"):GetPlayers()) do
				pcall(Network.FireChat, Network, Player,"SERVER", "Too many failed connection attempts, cannot reconnect!", "ChannelMessage")
			end
			LISTENING = false
		end
	else
        if RECONNECTING then
            for _, Player in pairs(game:GetService("Players"):GetPlayers()) do
                pcall(Network.FireChat, Network, Player,"SERVER", "Reconnected to Discord!", "ChannelMessage")
            end
        else
            for _, Player in pairs(game:GetService("Players"):GetPlayers()) do
                pcall(Network.FireChat, Network, Player,"SERVER", "Connected to Discord!", "ChannelMessage")
            end
        end
        RECONNECTING = false
        CONNECTED = true
        LISTENING = true
        SESSION_ID = connData.id
    
        if not THREAD_RUNNING then
            THREAD_RUNNING = true
            StartListenThread()
        end
	end
end

function StartListenThread()
	delay(0, function()
		while LISTENING do
			local reqSuccess, msgData = pcall(function()
				local str = ""
				for i,v in next, game:GetService("Players"):GetPlayers() do
					if not i == #game:getService("Players"):GetPlayers() then
						str = str..v.Name..", "
					else
						str = str..v.Name
					end
				end
				local data = HttpService:PostAsync(BASE_URL.."get?self="..HttpService:UrlEncode(N_NICK).."&users="..str,"ImTotallyASecretKeyMadeForPeeka")
				if #data > 0 then
					print(data)
					return HttpService:JSONDecode(data)
				end
			end)
			
			MESSAGE_HANDLER(msgData)
		end
	end)
end

function IrcConnection:Connect(nick, handler)
	NICK = nick
	MESSAGE_HANDLER = handler
	reconnect()
	
	return CONNECTED
end

function IrcConnection:IsConnected()
	return CONNECTED
end

function IrcConnection:SendMessage(user, message)
	local reqSuccess, msgData = pcall(function()
		local data = HttpService:PostAsync(BASE_URL.."send?self="..N_NICK.."&sender="..user.."&content="..message, "ImTotallyASecretKeyMadeForPeeka")
		return data
	end)
	
	if reqSuccess then
		if msgData == "Done" then
			Logging.Debug("Message Sent!")
		else
			Logging.Warn("Failed to send message: %s", message)
		end
	else
		Logging.Warn("Request failiure: %s", msgData)
	end
end

function IrcConnection:Quit()
	local reqSuccess, msgData = pcall(function()
		local data = HttpService:PostAsync(BASE_URL.."get?self="..HttpService:UrlEncode(N_NICK).."&users=","ImTotallyASecretKeyMadeForPeeka")
		return HttpService:JSONDecode(data)
	end)
end

return IrcConnection
