script:WaitForChild("GUIs")

local Chat = { PreviousChatter = nil }

local NameLengthCache = { }

local Player  = game.Players.LocalPlayer
local RbxUtil = LoadLibrary("RbxUtility")
local MainFrame

local MessageQueue = { }

local GetColor, GetId do 
	local ChatColors =
	{
	 {Color = Color3.new(253/255, 41/255, 67/255)},
	 {Color = Color3.new(1/255, 162/255, 255/255)},
	 {Color = Color3.new(2/255, 184/255, 87/255)},
	 {Color = Color3.new(226/255, 0/255, 170/255)},
	 BrickColor.new("Bright orange"),
	 BrickColor.new("Bright yellow"),
	 {Color = Color3.new(255/255, 170/255, 255/255)},
	 BrickColor.new("Brick yellow"),
	}
	function GetColor(Name)
		return ChatColors[GetId(Name)+1]
	end
	function GetId(Name)
		local Length = #Name
		local Modifier = (Length % 2 == 0) and 1 or 0
		local value = 0
		for i = 1, Length do
			if (Length - i + Modifier) % 4 < 2 then
				value = value + string.byte(Name, i)
			else
				value = value - string.byte(Name, i)
			end
		end
		return value % 8
	end
end

function Chat:NewFrame()
	local ScreenGui = Instance.new("ScreenGui")
	ScreenGui.Parent = Player.PlayerGui
	ScreenGui.Name   = "ChatGUI"
	
	MainFrame = Instance.new("Frame", ScreenGui)
	MainFrame.ZIndex = 8
	MainFrame.Name = "Main"
	--MainFrame.Size = UDim2.new(0, 510, 0, 138)
	MainFrame.Size = UDim2.new(1, 0, 0, 138)
	MainFrame.Position = UDim2.new(0, 0, 1, -420)
	--MainFrame.Position = UDim2.new(0, 0, 0, 0)
	MainFrame.BackgroundTransparency = 1
	MainFrame.ClipsDescendants = true
	
	ScreenGui.AncestryChanged:connect(function()
		repeat
			wait()
		until Player:FindFirstChild("PlayerGui") and Player:FindFirstChild("PlayerGui").ClassName == "PlayerGui"
		pcall(function()
			ScreenGui.Parent = Player.PlayerGui
		end)
	end)
end

function Chat:PushMessage(messageLabel)
	wait()
	MessageQueue[#MessageQueue + 1] = {
		Pos = 0,
		Gui = messageLabel
	}
	local i = #MessageQueue
	while i > 0 do
		local pos = i
		local item = MessageQueue[i]
		item.Pos = item.Pos + messageLabel.AbsoluteSize.Y
		
		if item.Gui.Parent then
			item.Gui:TweenPosition(UDim2.new(0, 0, 1, -item.Pos), "Out", "Sine", 0.1, true, function()
				if item.Pos - item.Gui.AbsoluteSize.Y > MainFrame.AbsoluteSize.Y then -- Are we entirely off-screen?
					item.Gui:Destroy()
					item.Done = true
					
					if MessageQueue[pos+1] and not MessageQueue[pos+1].Done then
						MessageQueue[pos+1].Gui.Player.Visible = true
					end
					
					-- Go through the table and remove the correct element 
					for j = #MessageQueue, 1, -1 do
						if MessageQueue[j].Gui == item.Gui then
							MessageQueue[j].Done = true
							MessageQueue[j].Gui:Destroy()
							table.remove(MessageQueue, j)
							break
						end
					end
				end
			end)
		end
		
		i = i - 1
	end
end

function Chat:Chat(OriginName, Message, MessageType, IsRemote)
	wait()
	local Color = GetColor(OriginName).Color
	local Name = OriginName
	local isIrc = false	

	if OriginName:sub(1,5) == "PkaSB" or OriginName == "SERVER" then
		if not Message then
			return
		end
		local name, message = Message:match("^(.-): (.+)$")
		if name == "SCRIPT_RESPONSE" then
			return
		end
		if Name == "SERVER" then
			Color = Color3.new(1/255, 162/255, 255/255)
			Name = "[SERVER]"
		end
		if name and message then
			Name = name
			Message = message
			if name == "SERVER" then
				Name = "[SERVER]"
				Color = Color3.new(1/255, 162/255, 255/255)
			else
				Color = GetColor(Name).Color
			end
			if #message == 0 then
				MessageType = "ChannelAction"
				Name = ""
				Message = "\1ACTION "..name.."\1"
			end
		end
	elseif OriginName:sub(1, 5) == "PubSB" or OriginName == "voxehBridge" or OriginName:sub(1, 8) == "MasterSB" then
		local name, message = Message:match("^(.-):(.*)$")
		if name == "SCRIPT_RESPONSE" then
			return
		end
		if name and message then
			Name = name
			Message = message
			if name == "SERVER" or name == "Server" then
				Name = "[SERVER]"
				Color = Color3.new(1/255, 162/255, 255/255)
			else
				Color = GetColor(Name).Color
			end
			if #message == 0 then
				MessageType = "ChannelAction"
				Name = ""
				Message = "\1ACTION "..name.."\1"
			end	
		else
			Name = "[SERVER]"
			Color = Color3.new(1/255, 162/255, 255/255)
		end
	elseif OriginName:sub(1, 13) == "ScriptBuilder" or OriginName == "antehBridge" or OriginName:sub(1, 8) == "MasterSB" then
		local name, message = Message:match("^(.-):(.*)$")
		if name == "SCRIPT_RESPONSE" then
			return
		end
		if name and message then
			Name = name
			Message = message
			if name == "SERVER" then
				Name = "[SERVER]"
				Color = Color3.new(1/255, 162/255, 255/255)
			else
				Color = GetColor(Name).Color
			end
			if #message == 0 then
				MessageType = "ChannelAction"
				Name = ""
				Message = "\1ACTION "..name.."\1"
			end
		else
			Name = "[SERVER]"
			Color =  Color3.new(1/255, 162/255, 255/255)
		end
	elseif IsRemote then
		if IsRemote then
			Name = "[DISCORD] "..OriginName
			Color = GetColor(OriginName).Color
			isIrc = true
		end
	else
		Name = OriginName
		Color = GetColor(OriginName).Color
	end
	
	if IsRemote and not isIrc then
		if OriginName:sub(1,5) == "PkaSB" then
			Name = "~[O] "..Name
		elseif OriginName:sub(1, 5) == "PubSB" or OriginName == "antehBridge" or OriginName:sub(1, 13) == "ScriptBuilder" or OriginName == "voxehBridge" or OriginName:sub(1, 8) == "MasterSB" then
			Name = "~ "..Name
		else
			Name = "~ "..Name
		end
	end
	
	if MessageType == "ChannelAction" then
		Message = Message:sub(8, -2)
	end
	
	local Text = Message-- and Message--:gsub("(.)", "\28%1") -- Filter bypass :)
	
	
	if MessageType == "ChannelMessage" or MessageType == "ChannelNotice" then
		local TextType = "Default"
	
		if Text:sub(1,1) == "*" then
			if Text:sub(#Text) == "*" then
				Text = Text:sub(2, #Text - 1)
				TextType = "Bold"
				print'bold'
			end
		elseif Text:sub(1,1) == "_" then
			if Text:sub(#Text) == "_" then
				Text = Text:sub(2, #Text - 1)
				TextType = "Italic"
				print'ital'
			end
		end
		
		local typeLabel = script.GUIs:FindFirstChild(MessageType)
		local ONAME = Name
		Name = Name..": "
		local MessageLabel = typeLabel:Clone()		
		MessageLabel.Parent = MainFrame
		
		MessageLabel.Player.Text = Name--:gsub("(.)", "\28%1")
		if Name == "SERVER" then
			Color = Color3.new(1/255, 162/255, 255/255)
		end
		MessageLabel.Player.TextColor3 = Color
		
		if ONAME == "MathematicalPie" then
			MessageLabel.Message.TextColor3 = BrickColor.new("New Yeller").Color
		end		
		
		if Chat.PreviousChatter ~= Name then
			MessageLabel.Player.Size = UDim2.new(0, MessageLabel.Player.TextBounds.X, 0, 20)
			NameLengthCache[Name] = MessageLabel.Player.TextBounds.X
		else
			MessageLabel.Player.Visible = false
			MessageLabel.Player.Size = UDim2.new(0, NameLengthCache[Name], 0, 20)
		end
		
		MessageLabel.Message.Position = UDim2.new(0, 3 + MessageLabel.Player.AbsoluteSize.X, 0, 0)	
		
		MessageLabel.Message.Text = Text
		if TextType == "Bold" then
			MessageLabel.Message.Font = "SourceSansBold"
		elseif TextType == "Italic" then
			MessageLabel.Message.Font = "SourceSansItalic"
		end
		
		-- Set size in two steps to allow TextBounds to update correctly
		MessageLabel.Message.Size = UDim2.new(0, MainFrame.AbsoluteSize.X - (MessageLabel.Player.AbsoluteSize.X + 3), 0, 500)
		coroutine.yield()
		MessageLabel.Message.Size = UDim2.new(0, MainFrame.AbsoluteSize.X - (MessageLabel.Player.AbsoluteSize.X + 3), 0, MessageLabel.Message.TextBounds.Y + 2)
		
		MessageLabel.Size = UDim2.new(1, 0, 0, math.max(20, MessageLabel.Message.AbsoluteSize.Y))
		
		Chat.PreviousChatter = Name
				
		if MessageType == "ChannelNotice" or Message:find(Player.Name) and Name ~= Player.Name then
			MessageLabel.Message.Font = "SourceSansBold"
			MessageLabel.Message.Position = MessageLabel.Message.Position + UDim2.new(0,2,0,0)
			MessageLabel.Player.Font = "SourceSansBold"
			local Sound = Instance.new("Sound")
			Sound.SoundId = "rbxassetid://180877191"
			Sound.Looped = false
			Sound.Parent=game:GetService("SoundService")
			Sound:Play()
			Sound:Destroy()
		end
		Chat:PushMessage(MessageLabel)
	elseif MessageType == "ChannelAction" or MessageType == "Action" then
		local typeLabel = script.GUIs:FindFirstChild("ChannelAction")
		Name = Name.." "..Text
		local MessageLabel = typeLabel:Clone()		
		MessageLabel.Parent = MainFrame
		
		MessageLabel.Player.Text = Name
		MessageLabel.Player.TextColor3 = Color
		
		MessageLabel.Size = UDim2.new(1, 0, 0, math.max(20, MessageLabel.Player.AbsoluteSize.Y))
		
		Chat.PreviousChatter = Name
				
		if Message:find(Player.Name) and Name ~= Player.Name then
			MessageLabel.Message.Font = "SourceSansBold"
			MessageLabel.Message.Position = MessageLabel.Message.Position + UDim2.new(0,2,0,0)
			MessageLabel.Player.Font = "SourceSansBold"
			local Sound = Instance.new("Sound")
			Sound.SoundId = "rbxassetid://180877191"
			Sound.Looped = false
			Sound.Parent=game:GetService("SoundService")
			Sound:Play()
			Sound:Destroy()
		end
		Chat:PushMessage(MessageLabel)
	end
end

return Chat
