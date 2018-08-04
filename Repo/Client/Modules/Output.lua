script.Parent:WaitForChild("Network")
local Network = require(script.Parent.Network)
local Scripts = {}
local LastPos = UDim2.new( 0,-617,1,-250 )
	local completelyVisible = false

local Output = {
	MainOutput = nil,
	Previous   = nil,
	Anchored   = false
}

local function LerpC3(Object, Property, Start, End, Time)
 local RunService = game:GetService("RunService")
 
 local StartR, StartG, StartB = Start.r, Start.g, Start.b
 local EndR, EndG, EndB = End.r, End.g, End.b
 
 local StartTime = tick()
 
 local function lerp(Start, End, Alpha)
  return Start + (End - Start)*Alpha
 end
 
 while true do
  local PassedTime = tick()-StartTime
  if PassedTime > Time then
   PassedTime = Time
  end
  local LerpValue = 1/Time*PassedTime
  Object[Property] = Color3.new(lerp(StartR, EndR, LerpValue), lerp(StartG, EndG, LerpValue), lerp(StartB, EndB, LerpValue))
  if PassedTime == Time then
   break
  end
  RunService.RenderStepped:wait()
 end
end

function Output:NewOutputGui()
	local NewOutput
	local NewCMDBar
	local NewClearButton
	if self.Previous and game.Players.LocalPlayer.PlayerGui ~= nil then
		NewOutput = self.Previous
		NewOutput.Parent = game.Players.LocalPlayer.PlayerGui
		NewCMDBar = NewOutput.OutputContainer.ContentFrame.CommandBar.CmdBarInput
		NewClearButton = NewOutput.OutputContainer.ContentFrame.ClearButton
	elseif game.Players.LocalPlayer.PlayerGui ~= nil then
		NewOutput = script.GUIs.Output:Clone()
		NewOutput.Name = "??�b ??"
		NewCMDBar = NewOutput.OutputContainer.ContentFrame.CommandBar.CmdBarInput
		NewClearButton = NewOutput.OutputContainer.ContentFrame.ClearButton
		NewOutput.Parent = game.Players.LocalPlayer.PlayerGui
	end
	
	self.MainOutput = NewOutput
	
	for i,v in next, NewOutput.OutputContainer.ContentFrame.OutputExplorer:GetChildren() do
		local txt = v.Text
		txt = txt:gsub("%[S%] ", "")
		Scripts[txt].Label = v
	end
	
	local outputContainer = NewOutput:WaitForChild( "OutputContainer" )
	local outputPulley = outputContainer:WaitForChild( "OutputPulley" )
	local inPosition = UDim2.new( 0,-617,1,-250 )	--	~	Closed
	local outPosition = UDim2.new( 0,0,1,-250 )	--	~	Clicked <
	local hoverPosition = UDim2.new( 0,-153,1,-250 )	--	~	Hovered <
	outputContainer.Position = inPosition
	local chevronLeft = "rbxassetid://367228726"
	local chevronRight = "rbxassetid://367216385"
	
	if completelyVisible then
		outputContainer:TweenPosition( outPosition,"Out","Quad",.5,true )
	end	
	
	outputContainer.MouseEnter:connect( function()
		if completelyVisible then return; end;
		outputPulley.PulleyChevron.Image = chevronLeft;
		LastPos = hoverPosition
		outputContainer:TweenPosition( hoverPosition,"Out","Quad",.5,true );
	end )
	
	outputContainer.MouseLeave:connect( function()
		if completelyVisible then return end
		outputPulley.PulleyChevron.Image = chevronRight
		outputContainer:TweenPosition( inPosition,"Out","Quad",.5,true )
		LastPos = inPosition
	end )
	
	outputPulley.MouseButton1Click:connect( function()
		if not completelyVisible then
			completelyVisible = true
			outputContainer:TweenPosition( outPosition,"Out","Quad",.5,true )
			LastPos = inPosition
		else
			completelyVisible = false
			outputPulley.PulleyChevron.Image = chevronRight
			outputContainer:TweenPosition( inPosition,"Out","Quad",.5,true )
			LastPos = inPosition
		end
	end )
	
	outputContainer.AncestryChanged:connect(function()
		Output.Previous = NewOutput:Clone()
		Output:NewOutputGui()
	end)
	
	NewCMDBar.MouseEnter:connect(function()
		coroutine.resume(coroutine.create(function() LerpC3(NewCMDBar, "BackgroundColor3", Color3.new(205, 205, 205), Color3.new(185, 185, 185), .5) end))
	end)

	NewCMDBar.MouseLeave:connect(function()
		coroutine.resume(coroutine.create(function() LerpC3(NewCMDBar, "BackgroundColor3", Color3.new(185, 185, 185), Color3.new(205, 205, 205), .5) end))
	end)
	
	NewCMDBar.FocusLost:connect(function(Finished)
		if not completelyVisible then
			completelyVisible = false
			outputPulley.PulleyChevron.Image = chevronRight
			outputContainer:TweenPosition( inPosition,"Out","Quad",.5,true )
			LastPos = inPosition
		end		
		
		if string.gsub(NewCMDBar.Text," ","") == "" then
			NewCMDBar.Text = "Click here or press (') to execute command"
			return
		end
		
		if Finished then
			Network:FireCommand(NewCMDBar.Text)
			NewCMDBar.Text = "Click here or press (') to execute command"
		end
	end)	
	
	NewCMDBar.Focused:connect(function()
		coroutine.resume(coroutine.create(function() LerpC3(NewCMDBar, "BackgroundColor3", Color3.new(NewCMDBar.BackgroundColor3), Color3.new(143, 143, 143), .5) end))
		if NewCMDBar.Text == "Click here or press (') to execute command" then
			NewCMDBar.Text = ""
		end
	end)
	
	NewClearButton.MouseButton1Down:connect(function()
		for i,v in next, NewOutput.OutputContainer.ContentFrame.Output:GetChildren() do
			v:Destroy()
		end
		NewOutput.OutputContainer.ContentFrame.Output.CanvasSize = UDim2.new(0,0,0,0)
	end)
	
	game:GetService("Players").LocalPlayer:GetMouse().KeyDown:connect(function(Key)
		if Key:byte() == 39 then
			if not completelyVisible then
			outputPulley.PulleyChevron.Image = chevronLeft;
			outputContainer:TweenPosition( hoverPosition,"Out","Quad",.5,true );
			end;
			if NewCMDBar.Text == " Click here or press (') to execute" then
				NewCMDBar.Text = ""
				NewCMDBar:CaptureFocus()
			else
				NewCMDBar:CaptureFocus()
			end
		end
	end)
end

function Output:Output(Type, Message)
	local function Time()
		local time = tick()
		local hours = math.floor(time / 3600) % 24
		local minutes = math.floor(time / 60) % 60
		local seconds = math.floor(time) % 60
		local time=string.format("%.2d:%.2d:%.2d",hours, minutes, seconds)
		return time
	end
	
	local NewLineCheck = Message:find("\n")
	if NewLineCheck then
		Output:Output(Type, Message:sub(1, NewLineCheck - 1))
		return Output:Output(Type, Message:sub(NewLineCheck + 1))
	end	
	local MainFrame = self.MainOutput.OutputContainer.ContentFrame.Output
	
	
	if #MainFrame:GetChildren() > 200 then
		for i,v in next, MainFrame:GetChildren() do
			v:Destroy()
		end
		MainFrame.CanvasSize = UDim2.new(0,0,0,0)
	end
	
	local NewLine = script.GUIs.OutputTypes:FindFirstChild(Type):Clone()
	NewLine.Name     = "Output"
	NewLine.Parent   = self.MainOutput.OutputContainer.ContentFrame.Output
	NewLine.Position = UDim2.new(0,1,0,((#MainFrame:GetChildren())*14)-14)
	NewLine.Text     = Time().." - "..Message--:gsub("(.)", "\28%1")
	
	if not NewLine.TextFits then
		if NewLine.TextBounds.X > MainFrame.AbsoluteWindowSize.X then
			MainFrame.CanvasSize = UDim2.new(0,NewLine.TextBounds.X,0,MainFrame.AbsoluteWindowSize.Y)
		end
	end
	
	if #MainFrame:GetChildren() > 13 then
		MainFrame.CanvasSize = UDim2.new(0,MainFrame.CanvasSize.X.Offset,0,(#MainFrame:GetChildren()*14))
		if MainFrame.CanvasSize.X.Offset > 0 then
			MainFrame.CanvasPosition = Vector2.new(MainFrame.AbsoluteWindowSize.X-454,((#MainFrame:GetChildren())*14)-168)
		else
			MainFrame.CanvasPosition = Vector2.new(0,((#MainFrame:GetChildren())*14)-172)
		end
	else
		MainFrame.CanvasPosition = Vector2.new(0,0)
	end
end

function Output:UpdateScriptPanel()
	self.MainOutput.OutputContainer.ContentFrame.OutputExplorer:ClearAllChildren()	
	table.sort(Scripts)
	for i,v in next, Scripts do
		Output:SetScript(i, v.Type, v.Saved, false, true)
	end
end

function Output:SetScript(Name, Type, Saved, Remove, ReBuild)
	local Scripts = Scripts
	Name = Name--:gsub("(.)", "\28%1")
	local C, Last = pcall(function() return Scripts[Name].Label end)
	if Scripts[Name] and Scripts[Name].Label ~= nil and not Remove then
		local NameA = Name
		if Type == nil then
			Type = Scripts[Name].Type
		end
		local NewOutput    = script.GUIs.ScriptTypes[Type]:Clone()
		if Saved then
			NameA = "[S] "..Name
		end
		
		NewOutput.Text     = NameA
		if ReBuild then
			NewOutput.Position = UDim2.new(0,0,0,#self.MainOutput.OutputContainer.ContentFrame.OutputExplorer:GetChildren()*11)
		else
			NewOutput.Position = Last.Position or UDim2.new(0,0,0,#self.MainOutput.OutputContainer.ContentFrame.OutputExplorer:GetChildren()*11)
		end
		Last.Parent = nil
		Last:Destroy()
		NewOutput.Parent   = self.MainOutput.OutputContainer.ContentFrame.OutputExplorer
		pcall(function() Scripts[Name].Label = NewOutput end)
		--Output:UpdateScriptPanel()
	elseif Remove then
		Scripts[Name] = nil
		Output:UpdateScriptPanel()
	else
		local NewOutput    = script.GUIs.ScriptTypes[Type]:Clone()
		if Saved then
			NewOutput.Text = "[S] "..Name
		else
			NewOutput.Text = Name
		end
		NewOutput.Position = UDim2.new(0,0,0,#self.MainOutput.OutputContainer.ContentFrame.OutputExplorer:GetChildren()*11)
		NewOutput.Parent   = self.MainOutput.OutputContainer.ContentFrame.OutputExplorer
		
		Scripts[Name] = {Label = NewOutput, Type = Type, Saved = Saved, META = #self.MainOutput.OutputContainer.ContentFrame.OutputExplorer:GetChildren() + 1}
	end
end

return Output
