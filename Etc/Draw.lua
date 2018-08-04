me = game.Players.LocalPlayer
char = me.Character
hold = false
thickness = 0.1
maxt = 10
bricks = {}

color = BrickColor.new("Really black")
colors = {}
for i=0,63,1 do
	table.insert(colors, BrickColor.palette(i))
end

function checkt()
	if thickness < 0.1 then
		thickness = 0.1
	end
	if thickness > maxt then
		thickness = maxt
	end
end

function makegui()
	local maxx = 200
	local x = 0
	local y = 0
	local g = Instance.new("ScreenGui")
	g.Name = "Colors"
	local fr = Instance.new("Frame",g)
	fr.Position = UDim2.new(0, 10, 0.3, 0)
	fr.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
	fr.BorderColor3 = Color3.new(0,0,0)
	local txt = nil
	local txt2 = nil
	local txt3 = nil
	for i,v in pairs(colors) do
		local gah = Instance.new("TextButton",fr)
		gah.Position = UDim2.new(0, x + 3, 0, y + 3)
		gah.Size = UDim2.new(0, 25, 0, 25)
		gah.BackgroundColor = v
		gah.BorderColor3 = Color3.new(0,0,0)
		gah.Text = ""
		gah.MouseButton1Down:connect(function()
			color = v
			txt.Text = v.Name
		end)
		gah.MouseEnter:connect(function()
			txt2.Text = v.Name
		end)
		gah.MouseLeave:connect(function() txt2.Text = ""
		end)
		x = x + 28
		if x >= maxx then
			x = 0
			y = y + 28
		end
	end
	fr.Size = UDim2.new(0, maxx + 27, 0, y + 40)
	txt = Instance.new("TextLabel",fr)
	txt.Size = UDim2.new(0.95, 0, 0, 35)
	txt.Position = UDim2.new(0.025, 0, 0, y + 3)
	txt.Text = color.Name
	txt.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
	txt.BorderColor3 = Color3.new(0, 0, 0)
	txt.TextColor3 = Color3.new(1, 1, 1)
	txt.FontSize = "Size24"
	txt.Font = "ArialBold"
	txt.TextYAlignment = "Bottom"
	txt.TextXAlignment = "Left"
	txt2 = Instance.new("TextLabel",txt)
	txt2.Size = UDim2.new(1, 0, 0, 0)
	txt2.Text = color.Name
	txt2.BackgroundTransparency = 1
	txt2.TextColor3 = Color3.new(1, 1, 1)
	txt2.FontSize = "Size12"
	txt2.TextYAlignment = "Top"
	txt2.TextXAlignment = "Right"
	txt3 = Instance.new("TextLabel",fr)
	txt3.Size = UDim2.new(0.5, 0, 0, 25)
	txt3.Position = UDim2.new(0.25, 0, 1, 0)
	txt3.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
	txt3.BorderColor3 = Color3.new(0,0,0)
	txt3.TextColor3 = Color3.new(1,1,1)
	txt3.FontSize = "Size12"
	txt3.Text = thickness
	g.Parent = me.PlayerGui
	coroutine.resume(coroutine.create(function()
		while g.Parent ~= nil do
			txt3.Text = thickness
			wait()
		end
	end))
end

function remgui()
	for i,v in pairs(me.PlayerGui:children()) do
		if v.Name == "Colors" then v:remove() end
	end
end

bin = Instance.new("HopperBin")
bin.Parent = me.Backpack

function weld(p1, p2)
	local w = Instance.new("Weld")
	w.Part0 = p2
	w.Part1 = p1
	w.C0 = p2.CFrame:toObjectSpace(p1.CFrame)
	w.Parent = p2
end

function B1D(mouse)
	hold = true
	coroutine.resume(coroutine.create(function()
		mouse.Button1Up:wait()
		hold = false
	end))
	local p = Instance.new("Part",char)
	p.formFactor = "Custom"
	p.TopSurface = "SmoothNoOutlines"
	p.Size = Vector3.new(1,0.5,0.5)
	p.Anchored = true
	p.TopSurface = 0
	p.BottomSurface = 0
	p.CanCollide = false
	p.BrickColor = color
	p.Locked = true
	local m = Instance.new("BlockMesh",p)
	local targ = mouse.Target
	table.insert(bricks, p)
	local pos = mouse.Hit.p
	while hold do
		local mag = (pos - mouse.Hit.p).magnitude
		m.Scale = Vector3.new(thickness, 0.4, (mag+(thickness/3))*2)
		p.CFrame = CFrame.new(pos, mouse.Hit.p) * CFrame.new(0, 0, -mag/2 - thickness/5)
		if mag > thickness/2+0.1 then
			B1D(mouse)
			if targ ~= nil then
				if targ.Anchored == false then
					p.Anchored = false
					weld(p, targ)
				end
			end
			break
		end
		wait()
	end
end

bin.Selected:connect(function(mouse)
	makegui()
	mouse.KeyDown:connect(function(key)
		key = key:lower()
		local kh = true
		coroutine.resume(coroutine.create(function()
			mouse.KeyUp:wait()
			kh = false
		end))
		if key == "q" then
			while kh do
				thickness = thickness - 0.1
				checkt()
				wait()
			end
		elseif key == "e" then
			while kh do
				thickness = thickness + 0.1
				checkt()
				wait()
			end
		elseif key == "z" then
			while kh do
				if #bricks > 0 then
					bricks[#bricks]:remove()
					table.remove(bricks, #bricks)
				end
				wait()
			end
		elseif key == "f" then
			for i = #bricks, 1, -1 do
				bricks[i]:remove()
				table.remove(bricks, i)
			end
		end
	end)
	mouse.Button1Down:connect(function()
		B1D(mouse)
	end)
end)

bin.Deselected:connect(function()
	remgui()
end) 
