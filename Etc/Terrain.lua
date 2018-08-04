if not game.Workspace:WaitForChild("Terrain").IsSmooth then
	error("Terrain must be smooth in order to use Smooth Terrain in-game tools.")
end

local on = false
local setup = false
local localGrid = true
local currentTool = "Create"

local modules = {
	["Smooth"] = require(script:WaitForChild("SmootherModule")),
	["Region Editor"] = require(script:WaitForChild("RegionEditorModule")),
}

local player = game.Players.LocalPlayer
local backpack = player:WaitForChild("Backpack")
local util = LoadLibrary("RbxUtility")

function makeFakeToolbar()
	local t = {}
	function t:CreateButton(name,tooltip,icon)
		local button = Instance.new("Tool")
		button.Name = name
		button.ToolTip = tooltip
		button.TextureId = icon
		button.CanBeDropped = false
		local miscHandle = Instance.new("Part",button)
		miscHandle.Name = "Handle"
		miscHandle.Size = Vector3.new(2,1.2,1)
		local miscMesh = Instance.new("SpecialMesh",miscHandle)
		miscMesh.Scale = Vector3.new(0.4,0.4,0.4)
		miscMesh.MeshId = "http://www.roblox.com/asset?id=15954259"
		miscMesh.TextureId = "http://www.roblox.com/asset?id=15958837"
		local b = {}
		b.Click = util.CreateSignal()
		local function doClick()
			b.Click:fire()
		end
		button.Equipped:connect(doClick)
		button.Unequipped:connect(doClick)
		function b:SetActive(active)
		end
		button.Parent = backpack
		return b
	end
	return t
end

function getPlayerBin()
	local partBin = player.Character:FindFirstChild("PartBin")
	if not partBin then
		if localGrid then
			partBin = Instance.new("Message",player.Character)
			partBin.Name = "PartBin"
		else
			partBin = Instance.new("Model",player.Character)
			partBin.Name = "PartBin"
		end
	end
	local playerBin = partBin:FindFirstChild(player.Name)
	if not playerBin then
		playerBin = Instance.new("Model",partBin)
		playerBin.Name = player.Name
		game.Players.ChildRemoved:connect(function(child)
			if child.Name == playerBin.Name then
				playerBin:Destroy()
			end
		end)
	end
	return playerBin
end

local toolBar = makeFakeToolbar()

local pluginButtons = {
	["Add"] = toolBar:CreateButton(
		"Add",
		"Click and hold to add terrain.",
		"http://www.roblox.com/asset?id=225328572"
	),
	["Subtract"] = toolBar:CreateButton(
		"Subtract",
		"Click and hold to remove terrain.",
		"http://www.roblox.com/asset?id=225328818"
	),
	["Paint"] = toolBar:CreateButton(
		"Paint",
		"Paint the material of the terrain.",
		"http://www.roblox.com/asset?id=225328954"
	),
	["Grow"] = toolBar:CreateButton(
		"Grow",
		"Click and hold to grow and expand terrain.",
		"http://www.roblox.com/asset?id=225329153"
	),
	["Erode"] = toolBar:CreateButton(
		"Erode",
		"Click and hold to erode and remove terrain.",
		"http://www.roblox.com/asset?id=225329301"
	),
	["Smooth"] = toolBar:CreateButton(
		"Smooth",
		"Brush to smooth out rough or jagged terrain.",
		"http://www.roblox.com/asset?id=225329641"
	),
	["Region Editor"] = toolBar:CreateButton(
		"Regions",
		"Manipulate regions of smooth terrain.",
		"http://www.roblox.com/asset?id=240631063"
	),
}

for name,button in pairs(pluginButtons) do
	button.Click:connect(function()
		if not on or (currentTool ~= nil and name ~= currentTool) then
			if not setup then
				FirstTimeSetUp()
			end
			Selected(button,name)
		else
			Deselected()
		end
	end)
end

function FirstTimeSetUp()
	setup = true
	local terrain = game.Workspace.Terrain
	local coreGui = player:WaitForChild("PlayerGui")
	local gui = script:WaitForChild("TerrainBrushGui")
	local guiFrame = gui:WaitForChild("Frame")
	local closeButton = guiFrame:WaitForChild("CloseButton")
	local checkBox1 = guiFrame:WaitForChild("CheckBox1")
	local checkBox2 = guiFrame:WaitForChild("CheckBox2")
	local checkBox3 = guiFrame:WaitForChild("CheckBox3")
	local toolTip1 = guiFrame:WaitForChild("ToolTip1")
	local toolTip2 = guiFrame:WaitForChild("ToolTip2")
	local library = assert(LoadLibrary("RbxGui"))
	local mouse = player:GetMouse()
	local userInput = game:GetService("UserInputService")
	local selectionSize = 6
	local strength = .5
	local snapToGrid = false
	local planeLock = false
	local brushShape = "Sphere"
	local materialSelection = "Grass"
	local dynamicMaterial = false
	local resolution = 4
	local minSelectionSize = 1
	local maxSelectionSize = 16
	local materialSelections = {"Grass","Sand","Rock","Slate","Water","Wood Planks","Brick","Concrete","Glacier","Snow","Sandstone","Mud","Basalt","Ground","Cracked Lava", "Asphalt", "LeafyGrass", "Limestone", "Pavement", "Salt"}
	local clickThreshold = .1
	local toolTipShowTime = 3.5
	local brushShapes = {
		["Sphere"] = {
			name = "Sphere",
			button = guiFrame:WaitForChild("ShapeButton1"),
			image = "http://www.roblox.com/asset?id=225799533",
			selectedImage = "http://www.roblox.com/asset?id=225801914",
		},
		["Box"] = {
			name = "Box",
			button = guiFrame:WaitForChild("ShapeButton2"),
			image = "http://www.roblox.com/asset?id=225799696",
			selectedImage = "http://www.roblox.com/asset?id=225802254",
		},
	}
	local materialDictionary = {
		["Grass"] = Enum.Material.Grass,
		["Sand"] = Enum.Material.Sand,
		["Rock"] = Enum.Material.Rock,
		["Slate"] = Enum.Material.Slate,
		["Water"] = Enum.Material.Water,
		["Wood Planks"] = Enum.Material.WoodPlanks,
		["Brick"] = Enum.Material.Brick,
		["Concrete"] = Enum.Material.Concrete,
		["Glacier"] = Enum.Material.Glacier,
		["Snow"] = Enum.Material.Snow,
		["Sandstone"] = Enum.Material.Sandstone,
		["Mud"] = Enum.Material.Mud,
		["Basalt"] = Enum.Material.Basalt,
		["Ground"] = Enum.Material.Ground,
		["Cracked Lava"] = Enum.Material.CrackedLava,
		["Asphalt"] = Enum.Material.Asphalt,
		["LeafyGrass"] = Enum.Material.LeafyGrass,
		["Limestone"] = Enum.Material.Limestone,
		["Pavement"] = Enum.Material.Pavement,
		["Salt"] = Enum.Material.Salt,
	}
	local materialImageDictionary = {
		["Grass"] = "http://www.roblox.com/asset?id=225314676",
		["Concrete"] = "http://www.roblox.com/asset?id=225314983",
		["Rock"] = "http://www.roblox.com/asset?id=225315178",
		["Slate"] = "http://www.roblox.com/asset?id=225315290",
		["Brick"] = "http://www.roblox.com/asset?id=225315419",
		["Water"] = "http://www.roblox.com/asset?id=225315529",
		["Sand"] = "http://www.roblox.com/asset?id=225315607",
		["Wood Planks"] = "http://www.roblox.com/asset?id=225315705",
		["Glacier"] = "http://www.roblox.com/asset?id=254541572",
		["Snow"] = "http://www.roblox.com/asset?id=254541898",
		["Sandstone"] = "http://www.roblox.com/asset?id=254541350",
		["Mud"] = "http://www.roblox.com/asset?id=254541862",
		["Basalt"] = "http://www.roblox.com/asset?id=254542066",
		["Ground"] = "http://www.roblox.com/asset?id=254542189",
		["Cracked Lava"] = "http://www.roblox.com/asset?id=254541726",
		["Asphalt"] = "http://www.roblox.com/asset?id=254541726",
		["LeafyGrass"] = "http://www.roblox.com/asset?id=254541726",
		["Limestone"] = "http://www.roblox.com/asset?id=254541726",
		["Pavement"] = "http://www.roblox.com/asset?id=254541726",
		["Salt"] = "http://www.roblox.com/asset?id=254541726",		
	}
	local forcePlaneLock = false
	local forceSnapToGrid = false
	local forceDynamicMaterial = false
	local forceDynamicMaterialTo = true
	local forceMaterial = nil
	local selectionPart = nil
	local selectionObject = nil
	local gridLineParts = {}
	local currentLoopTag = nil
	local lastMainPoint = Vector3.new(0,0,0)
	local click = false
	local firstOperation = tick()
	local downKeys = {}
	local lastPlanePoint = Vector3.new(0,0,0)
	local lastNormal = Vector3.new(0,1,0)
	local lastCursorDistance = 300
	local toolTip1Change = nil
	local toolTip2Change = nil
	local materialAir = Enum.Material.Air
	local materialWater = Enum.Material.Water
	local ceil = math.ceil
	local floor = math.floor
	local abs = math.abs
	local min = math.min
	local max = math.max
	local sqrt = math.sqrt
	local sin = math.sin
	local cos = math.cos
	local pi = math.pi
	local selectionSizeSlider,selectionSizeValue = library.CreateSlider(maxSelectionSize,90,UDim2.new(1,-98,0,40))
	selectionSizeSlider.Parent = guiFrame
	selectionSizeValue.Changed:connect(function()
		selectionSize = selectionSizeValue.Value
		if selectionPart then
			selectionPart.Size = Vector3.new(1,1,1)*selectionSize*resolution+Vector3.new(.1,.1,.1)
		end
		toolTip1.Visible = true
		local currentToolTip1Change = {}
		toolTip1Change = currentToolTip1Change
		wait(toolTipShowTime)
		if toolTip1Change == currentToolTip1Change then
			toolTip1.Visible = false
		end
	end)
	selectionSizeValue.Value = selectionSize
	toolTip1.Visible = false
	local strengthslider,strengthValue = library.CreateSlider(101,90,UDim2.new(1,-98,0,65))
	strengthslider.Parent = guiFrame
	strengthValue.Changed:connect(function()
		strength = (strengthValue.Value-1)/100
		if selectionObject then
			selectionObject.SurfaceTransparency = .95-strength*.3
		end
		toolTip2.Visible = true
		local currentToolTip2Change = {}
		toolTip2Change = currentToolTip2Change
		wait(toolTipShowTime)
		if toolTip2Change == currentToolTip2Change then
			toolTip2.Visible = false
		end
	end)
	strengthValue.Value = strength*100
	toolTip2.Visible = false
	function setBrushShape(newBrushShape)
		brushShape = newBrushShape
		for _,v in pairs(brushShapes) do
			v.button.ImageTransparency = (newBrushShape == v.name) and 0 or .5
			v.button.ImageColor3 = (newBrushShape == v.name) and Color3.new(1,1,1) or Color3.new(.5,.5,.5)
		end
		clearSelection()
	end
	for _,v in pairs(brushShapes) do
		v.button.MouseButton1Down:connect(function()
			setBrushShape(v.name)
		end)
	end
	local function setMaterialSelection(newMaterialSelection)
		materialSelection = newMaterialSelection
		forceSnapToGrid = materialSelection == "Brick" or materialSelection == "Wood Planks"
		updateSnapToGrid()
		for _,v in pairs(guiFrame:GetChildren()) do
			if string.sub(v.Name,1,14) == "MaterialButton" then
				if string.sub(v.Name,15) == newMaterialSelection then
					v.BackgroundTransparency = .1
				else
					v.BackgroundTransparency = 1
				end
			end
		end
	end
	for i,materialName in pairs(materialSelections) do
		local newMaterialButton = Instance.new("ImageButton")
		newMaterialButton.Name = "MaterialButton"..materialName
		newMaterialButton.BorderSizePixel = 2
		newMaterialButton.BorderColor3 = Color3.new(.2,1,1)
		newMaterialButton.BackgroundColor3 = Color3.new(.2,1,1)
		newMaterialButton.BackgroundTransparency = 1
		newMaterialButton.Image = materialImageDictionary[materialName]
		newMaterialButton.Size = UDim2.new(0,35,0,35)
		newMaterialButton.Position = UDim2.new(0,5+((i-1)%4)*40,0,195+ceil(i/4)*40)
		newMaterialButton.MouseButton1Down:connect(function()
			setMaterialSelection(materialName)
		end)
		newMaterialButton.Parent = guiFrame
	end
	function updatePlaneLock()
		checkBox1.Style = forcePlaneLock and Enum.ButtonStyle.RobloxRoundButton or Enum.ButtonStyle.RobloxRoundDefaultButton
		checkBox1.Text = (planeLock or forcePlaneLock) and "X" or ""
		checkBox1.AutoButtonColor = not forcePlaneLock
		if not (planeLock or forcePlaneLock) then
			clearGrid()
		end
	end
	checkBox1.MouseButton1Down:connect(function()
		planeLock = not planeLock
		updatePlaneLock()
	end)
	function updateSnapToGrid()
		checkBox2.Style = forceSnapToGrid and Enum.ButtonStyle.RobloxRoundButton or Enum.ButtonStyle.RobloxRoundDefaultButton
		checkBox2.Text = (snapToGrid or forceSnapToGrid) and "X" or ""
		checkBox2.AutoButtonColor = not forceSnapToGrid
	end
	checkBox2.MouseButton1Down:connect(function()
		snapToGrid = not snapToGrid
		updateSnapToGrid()
	end)
	function updateDynamicMaterial()
		local isDynamic = dynamicMaterial
		if forceDynamicMaterial then
			isDynamic = forceDynamicMaterialTo
		end
		checkBox3.Style = forceDynamicMaterial and Enum.ButtonStyle.RobloxRoundButton or Enum.ButtonStyle.RobloxRoundDefaultButton
		checkBox3.AutoButtonColor = not forceDynamicMaterial
		checkBox3.Text =  isDynamic and "X" or ""
		local desiredSize = UDim2.new(0,180,0,245)
		if not isDynamic then
			desiredSize = desiredSize+UDim2.new(0,0,0,5+ceil(#materialSelections/4)*40)
		end
		guiFrame.Size = desiredSize
		for _,v in pairs(guiFrame:GetChildren()) do
			if string.sub(v.Name,1,14) == "MaterialButton" then
				v.Visible = not isDynamic
			end
		end
	end
	checkBox3.MouseButton1Down:connect(function()
		dynamicMaterial = not dynamicMaterial
		updateDynamicMaterial()
	end)
	do
		local runService = game:GetService("RunService").RenderStepped
		function quickWait(waitTime)
			if not waitTime then
				runService:wait()
			elseif waitTime < .033333 then
				local startTick = tick()
				runService:wait()
				local delta = tick()-startTick
				if delta <= waitTime*.5 then
					quickWait(waitTime-delta)
				end
			else
				wait(waitTime)
			end
		end
	end
	function clearSelection()
		if selectionObject then
			selectionObject:Destroy()
			selectionObject = nil
		end
		if selectionPart then
			selectionPart:Destroy()
			selectionPart = nil
		end
	end
	function clearGrid()
		for i,v in pairs(gridLineParts) do
			if v then
				v:Destroy()
			end
			gridLineParts[i] = nil
		end
	end
	function drawGrid(point,normal,transparency,color)
		local transparency = transparency or .95
		local color = BrickColor.new(color or "Institutional white")
		local gridCellSize = selectionSize*resolution
		local gridSize = 10
		local baseCframe = CFrame.new(point,point+normal)
		local normalSpase = CFrame.new(Vector3.new(0,0,0),normal):pointToObjectSpace(point)
		local roundedNormalOffset = (Vector3.new((normalSpase.x/gridCellSize)%1,(normalSpase.y/gridCellSize)%1,0)-Vector3.new(.5,.5,0))*-gridCellSize
		for u = 1,gridSize do
			local linePart = gridLineParts[u]
			if not linePart then
				linePart = Instance.new("Part")
				linePart.Transparency = 1
				linePart.TopSurface = "Smooth"
				linePart.BottomSurface = "Smooth"
				linePart.Anchored = true
				linePart.CanCollide = false
				linePart.formFactor = "Custom"
				local selectionBox = Instance.new("SelectionBox")
				selectionBox.Color = color
				selectionBox.Transparency = transparency
				selectionBox.Adornee = linePart
				selectionBox.Parent = linePart
				linePart.Parent = getPlayerBin()
				gridLineParts[u] = linePart
			elseif linePart.SelectionBox.Transparency ~= transparency or linePart.SelectionBox.Color ~= color then
				linePart.SelectionBox.Transparency = transparency
				linePart.SelectionBox.Color = color
			end
			local percent = (u-1)/(gridSize-1)
			linePart.Size = Vector3.new(gridCellSize*gridSize*sin(math.acos(percent*1.8-.9)),0,0)
			linePart.CFrame = baseCframe*CFrame.new(0,(percent-.5)*(gridSize-1)*gridCellSize,0)*CFrame.new(roundedNormalOffset)
		end
		for u = 1,gridSize do
			local linePart = gridLineParts[gridSize+u]
			if not linePart then
				linePart = Instance.new("Part")
				linePart.Transparency = 1
				linePart.TopSurface = "Smooth"
				linePart.BottomSurface = "Smooth"
				linePart.Anchored = true
				linePart.CanCollide = false
				linePart.formFactor = "Custom"
				local selectionBox = Instance.new("SelectionBox")
				selectionBox.Color = color
				selectionBox.Transparency = transparency
				selectionBox.Adornee = linePart
				selectionBox.Parent = linePart
				linePart.Parent = getPlayerBin()
				gridLineParts[gridSize+u] = linePart
			elseif linePart.SelectionBox.Transparency ~= transparency or linePart.SelectionBox.Color ~= color then
				linePart.SelectionBox.Transparency = transparency
				linePart.SelectionBox.Color = color
			end
			local percent = (u-1)/(gridSize-1)
			linePart.Size = Vector3.new(0,gridCellSize*gridSize*sin(math.acos(percent*1.8-.9)),0)
			linePart.CFrame = baseCframe*CFrame.new((percent-.5)*(gridSize-1)*gridCellSize,0,0)*CFrame.new(roundedNormalOffset)
		end
	end
	local function getCell(list,x,y,z)
		return list and list[x] and list[x][y] and list[x][y][z]
	end
	local function getNeighborOccupancies(list,x,y,z,includeSelf)
		local fullNeighbor = false
		local emptyNeighbor = false
		local neighborOccupancies = includeSelf and getCell(list,x,y,z) or 0
		local totalNeighbors = includeSelf and 1 or 0
		local nearMaterial = materialDictionary[materialSelection]
		for axis = 1,3 do
			for offset = -1,1,2 do
				local neighbor = nil
				if axis == 1 then
					neighbor = list[x+offset] and list[x+offset][y][z]
				elseif axis == 2 then
					neighbor = list[x][y+offset] and list[x][y+offset][z]
				elseif axis == 3 then
					neighbor = list[x][y][z+offset]
				end
				if neighbor then
					if neighbor >= 1 then
						fullNeighbor = true
					end
					if neighbor <= 0 then
						emptyNeighbor = true
					end
					totalNeighbors = totalNeighbors+1
					neighborOccupancies = neighborOccupancies+neighbor
				end
			end
		end
		return neighborOccupancies/(totalNeighbors ~= 0 and totalNeighbors or getCell(list,x,y,z)),fullNeighbor,emptyNeighbor
	end
	local function round(n)
		return floor(n+.5)
	end
	function findFace()
		local cameraLookVector = game.Workspace.CurrentCamera.CoordinateFrame.lookVector
		return Vector3.new(round(cameraLookVector.x),round(cameraLookVector.y),round(cameraLookVector.z)).unit
	end
	function lineToPlaneIntersection(linePoint,lineDirection,planePoint,planeNormal)
		local denominator = lineDirection:Dot(planeNormal)
		if denominator == 0 then
			return linePoint
		end
		local distance = ((planePoint-linePoint):Dot(planeNormal))/denominator
		return linePoint+lineDirection*distance
	end
	function operation(centerPoint)
		local isDynamic = dynamicMaterial
		if forceDynamicMaterial then
			isDynamic = forceDynamicMaterialTo
		end
		local nearMaterial
		local nearMaterial = nearMaterial
		local desiredMaterial = isDynamic and nearMaterial or materialDictionary[materialSelection]
		local radius = selectionSize*.5*resolution
		local minBounds = Vector3.new(floor((centerPoint.x-radius)/resolution),floor((centerPoint.y-radius)/resolution),floor((centerPoint.z-radius)/resolution))*resolution
		local maxBounds = Vector3.new(ceil((centerPoint.x+radius)/resolution),ceil((centerPoint.y+radius)/resolution),ceil((centerPoint.z+radius)/resolution))*resolution
		local region = Region3.new(minBounds,maxBounds)
		local materials,occupancies = terrain:ReadVoxels(region,resolution)
		if modules[currentTool] then
			if modules[currentTool]["operation"] then
				local middle = materials[ceil(#materials*.5)]
				if middle then
					local middle = middle[ceil(#middle*.5)]
					if middle then
						local middle = middle[ceil(#middle*.5)]
						if middle and middle ~= materialAir then
							nearMaterial = middle
							desiredMaterial = isDynamic and nearMaterial or materialDictionary[materialSelection]
						end
					end
				end
				modules[currentTool]["operation"](centerPoint,materials,occupancies,resolution,selectionSize,strength,desiredMaterial,brushShape,minBounds,maxBounds)
			end
		else
			for ix,vx in ipairs(occupancies) do
				local cellVectorX = minBounds.x+(ix-.5)*resolution-centerPoint.x
				for iy,vy in pairs(vx) do
					local cellVectorY = minBounds.y+(iy-.5)*resolution-centerPoint.y
					for iz,cellOccupancy in pairs(vy) do
						local cellVectorZ = minBounds.z+(iz-.5)*resolution-centerPoint.z
						local cellMaterial = materials[ix][iy][iz]
						local distance = sqrt(cellVectorX*cellVectorX+cellVectorY*cellVectorY+cellVectorZ*cellVectorZ)
						local magnitudePercent = 1
						local brushOccupancy = 1
						if brushShape == "Sphere" then
							magnitudePercent = cos(min(1,distance/(radius+resolution*.5))*pi*.5)
							brushOccupancy = max(0,min(1,(radius+.5*resolution-distance)/resolution))
						elseif brushShape == "Box" then
							if not (snapToGrid or forceSnapToGrid) then
								local xOutside = 1-max(0,abs(cellVectorX/resolution)+.5-selectionSize*.5)
								local yOutside = 1-max(0,abs(cellVectorY/resolution)+.5-selectionSize*.5)
								local zOutside = 1-max(0,abs(cellVectorZ/resolution)+.5-selectionSize*.5)
								brushOccupancy = xOutside*yOutside*zOutside
							end
						end
						if cellMaterial ~= materialAir and cellMaterial ~= nearMaterial then
							nearMaterial = cellMaterial
							if isDynamic then
								desiredMaterial = nearMaterial
							end
						end
						if currentTool == "Add" then
							if selectionSize <= 2 then
								if brushOccupancy >= .5 then
									if cellMaterial == materialAir or cellMaterial == materialWater or cellOccupancy <= 0 then
										materials[ix][iy][iz] = desiredMaterial
									end
									occupancies[ix][iy][iz] = 1
								end 
							else
								if brushOccupancy > cellOccupancy then
									occupancies[ix][iy][iz] = brushOccupancy
								end
								if brushOccupancy >= .5 and (cellMaterial == materialAir or cellMaterial == materialWater) then
									materials[ix][iy][iz] = desiredMaterial
								end
							end
						elseif currentTool == "Subtract" then
							if selectionSize <= 2 then
								if brushOccupancy >= .5 then
									occupancies[ix][iy][iz] = 0
									materials[ix][iy][iz] = materialAir
								end
							else
								local desiredOccupancy = 1-brushOccupancy
								if desiredOccupancy < cellOccupancy then
									occupancies[ix][iy][iz] = desiredOccupancy
								end
								if desiredOccupancy <= 0 then
									materials[ix][iy][iz] = materialAir
								end
							end
						elseif currentTool == "Grow" then
							if brushOccupancy >= .5 then
								local desiredOccupancy = cellOccupancy
								local neighborOccupancies,fullNeighbor ,emptyNeighbor = getNeighborOccupancies(occupancies,ix,iy,iz)
								if cellOccupancy > 0 or fullNeighbor then
									desiredOccupancy = desiredOccupancy+neighborOccupancies*(strength+.1)*.25*brushOccupancy*magnitudePercent
								end
								if cellMaterial == materialAir or cellOccupancy <= 0 and desiredOccupancy > 0 then
									materials[ix][iy][iz] = desiredMaterial
								end
								occupancies[ix][iy][iz] = desiredOccupancy
							end
						elseif currentTool == "Erode" then
							local flippedBrushOccupancy = 1-brushOccupancy
							if flippedBrushOccupancy <= .5 then
								local desiredOccupancy = cellOccupancy
								local emptyNeighbor = false
								local neighborOccupancies = 6
								for axis = 1,3 do
									for offset = -1,1,2 do
										local neighbor = nil
										if axis == 1 then
											neighbor = occupancies[ix+offset] and occupancies[ix+offset][iy][iz]
										elseif axis == 2 then
											neighbor = occupancies[ix][iy+offset] and occupancies[ix][iy+offset][iz]
										elseif axis == 3 then
											neighbor = occupancies[ix][iy][iz+offset]
										end
										if neighbor then
											if neighbor <= 0 then
												emptyNeighbor = true
											end
											neighborOccupancies = neighborOccupancies-neighbor
										end
									end
								end
								if cellOccupancy < 1 or emptyNeighbor then
									desiredOccupancy = desiredOccupancy-(neighborOccupancies/6)*(strength+.1)*.25*brushOccupancy*magnitudePercent
								end
								if cellMaterial == materialAir or cellOccupancy <= 0 and desiredOccupancy > 0 then
									materials[ix][iy][iz] = desiredMaterial
								end
								occupancies[ix][iy][iz] = desiredOccupancy
							end
						elseif currentTool == "Paint" then
							if brushOccupancy > 0 and cellOccupancy > 0 then
								materials[ix][iy][iz] = desiredMaterial
							end
						end
					end
				end
			end
		end
		terrain:WriteVoxels(region,resolution,materials,occupancies)
	end
	function Selected(toolButton,toolName)
		if toolButton then
			toolButton:SetActive(true)
			lastToolButton = toolButton
		end
		on = true
		currentTool = toolName
		if modules[toolName] and modules[toolName]["On"] then
			modules[toolName].On(mouse,Deselected)
		end
		if not modules[toolName] or modules[toolName]["operation"] then
			gui.Parent = coreGui
			forcePlaneLock = toolName == "Add" or toolName == "Subtract"
			updatePlaneLock()
			forceDynamicMaterial = toolName == "Subtract" or toolName == "Erode" or toolName == "Paint" or toolName == "Smooth" or toolName == "Smoother"
			forceDynamicMaterialTo = not (forceDynamicMaterial and toolName == "Paint")
			updateDynamicMaterial()
			local loopTag = {}
			currentLoopTag = loopTag
			while currentLoopTag and currentLoopTag == loopTag do
				local t = tick()
				local radius = selectionSize*.5*resolution
				local mainPoint = mouse.Hit.p
				if toolName == "Add" then
					mainPoint = mainPoint-mouse.UnitRay.Direction*.05
				elseif toolName == "Subtract" or toolName == "Paint" or toolName == "Grow" then
					mainPoint = mainPoint+mouse.UnitRay.Direction*.05
				end
				if mouse.Target == nil then
					mainPoint = game.Workspace.CurrentCamera.CoordinateFrame.p+mouse.UnitRay.Direction*lastCursorDistance
				end
				if not mouseDown or click then
					lastPlanePoint = mainPoint
					lastNormal = findFace()
				end
				if planeLock or forcePlaneLock then
					mainPoint = lineToPlaneIntersection(mouse.Hit.p,mouse.UnitRay.Direction,lastPlanePoint,lastNormal)
				end
				if snapToGrid or forceSnapToGrid then
					local snapOffset = Vector3.new(1,1,1)*(radius%resolution)
					local tempMainPoint = (mainPoint-snapOffset)/resolution+Vector3.new(.5,.5,.5)
					mainPoint = Vector3.new(floor(tempMainPoint.x),floor(tempMainPoint.y),floor(tempMainPoint.z))*resolution+snapOffset
				end
				if mouseDown then
					if click then
						firstOperation = t
						lastMainPoint = mainPoint
					end
					if click or t > firstOperation+clickThreshold then
						click = false
						local difference = mainPoint-lastMainPoint
						local dragDistance = (difference).magnitude
						local crawlDistance = radius*.5
						if dragDistance > crawlDistance then
							local differenceVector = difference.unit
							local dragDistance = min(dragDistance,crawlDistance*2+20)
							local samples=ceil(dragDistance/crawlDistance-.1)
							for i = 1,samples do
								operation(lastMainPoint+differenceVector*dragDistance*(i/samples))
							end
							mainPoint = lastMainPoint+differenceVector*dragDistance
						else
							operation(mainPoint)
						end
						lastMainPoint = mainPoint
					end
				end
				if not selectionPart then
					selectionPart = Instance.new("Part")
					selectionPart.Name = "SelectionPart"
					selectionPart.Transparency = 1
					selectionPart.TopSurface = "Smooth"
					selectionPart.BottomSurface = "Smooth"
					selectionPart.Anchored = true
					selectionPart.CanCollide = false
					selectionPart.formFactor = "Custom"
					selectionPart.Size = Vector3.new(1,1,1)*selectionSize*resolution+Vector3.new(.1,.1,.1)
					selectionPart.Parent = getPlayerBin()
					mouse.TargetFilter = getPlayerBin()
				end
				if not selectionObject then
					selectionObject = Instance.new(brushShape == "Sphere" and "SelectionSphere" or "SelectionBox")
					selectionObject.Name = "SelectionObject"
					selectionObject.Color = BrickColor.new("Toothpaste")
					selectionObject.SurfaceTransparency = .95-strength*.3
					selectionObject.SurfaceColor = BrickColor.new("Toothpaste")
					selectionObject.Adornee = selectionPart
					selectionObject.Parent = selectionPart
				end
				selectionPart.CFrame = CFrame.new(mainPoint)
				if planeLock or forcePlaneLock then
					local mainPointIntersect = lineToPlaneIntersection(mainPoint,mouse.UnitRay.Direction,lastPlanePoint,lastNormal)
					drawGrid(mainPointIntersect,lastNormal,mouseDown and .8)
				end
				lastCursorDistance = max(20+selectionSize*resolution*1.5,(mainPoint-game.Workspace.CurrentCamera.CoordinateFrame.p).magnitude)
				quickWait()
			end
		end
	end
	function Deselected()
		currentLoopTag = nil
		gui.Parent = script
		clearSelection()
		clearGrid()
		if lastToolButton then
			lastToolButton:SetActive(false)
		end
		mouseDown = false
		on = false
		local lastCurrentTool = currentTool
		currentTool = nil
		if modules[lastCurrentTool] and modules[lastCurrentTool]["Off"] then
			modules[lastCurrentTool].Off()
		end
	end
	function scrollwheel(change)
		if on then
			if downKeys[Enum.KeyCode.LeftShift] or downKeys[Enum.KeyCode.RightShift] then
				selectionSize = max(minSelectionSize,min(maxSelectionSize,selectionSize+change))
				selectionSizeValue.Value = selectionSize
			end
			if downKeys[Enum.KeyCode.LeftControl] or downKeys[Enum.KeyCode.RightControl] then
				strength = max(0,min(1,strength+change*(1/(maxSelectionSize-minSelectionSize))))
				strengthValue.Value = round(strength*100+1)
			end
		end
	end
	userInput.InputBegan:connect(function(event,soaked)
		downKeys[event.KeyCode] = true
		if event.UserInputType == Enum.UserInputType.MouseButton1 and not soaked and on then
			mouseDown = true
			click = true
		end
	end)
	userInput.InputEnded:connect(function(event,soaked)
		downKeys[event.KeyCode] = nil
		if event.UserInputType == Enum.UserInputType.MouseButton1 and mouseDown then
			mouseDown = false
		end
	end)
	mouse.WheelForward:connect(function()
		scrollwheel(1)
	end)
	mouse.WheelBackward:connect(function()
		scrollwheel(-1)
	end)
	closeButton.MouseButton1Down:connect(Deselected)
	setBrushShape(brushShape)
	setMaterialSelection(materialSelection)
	updatePlaneLock()
	updateSnapToGrid()
	updateDynamicMaterial()
end
