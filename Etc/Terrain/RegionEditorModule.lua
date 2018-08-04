while not game.Workspace:WaitForChild("Terrain").IsSmooth do
	game.Workspace.Terrain.Changed:wait()
end

local on = false
local setup = false
local currentTool = "Create"
local player = game.Players.LocalPlayer

function FirstTimeSetUp()
	setup = true
	local terrain = game.Workspace.Terrain
	local coreGui = player:WaitForChild("PlayerGui")
	local gui = script.Parent:WaitForChild("TerrainRegionGui")
	local guiFrame = gui:WaitForChild("Frame")
	local closeButton = guiFrame:WaitForChild("CloseButton")
	local buttonFillAir = guiFrame:WaitForChild("ButtonFillAir")
	local buttonFillWater = guiFrame:WaitForChild("ButtonFillWater")
	local buttonSelect = guiFrame:WaitForChild("ButtonSelect")
	local buttonMove = guiFrame:WaitForChild("ButtonMove")
	local buttonResize = guiFrame:WaitForChild("ButtonResize")
	local buttonRotate = guiFrame:WaitForChild("ButtonRotate")
	local buttonCopy = guiFrame:WaitForChild("ButtonCopy")
	local buttonPaste = guiFrame:WaitForChild("ButtonPaste")
	local buttonDelete = guiFrame:WaitForChild("ButtonDelete")
	local library = assert(LoadLibrary("RbxGui"))
	local mode = "Select"
	local tool = "None"
	local button = "Select"
	local fillAir = true
	local fillWater = true
	local resolution = 4
	local textSelectColor = Color3.new(72/255,145/255,212/255)
	local white = Color3.new(238/255,238/255,238/255)
	local editColor1 = "Institutional white"
	local editColor2 = "Light stone grey"
	local rotationInterval = math.pi*.5
	local regionLengthLimit = 125
	local faceToNormal = {
		[Enum.NormalId.Top] = Vector3.new(0,1,0),
		[Enum.NormalId.Bottom] = Vector3.new(0,-1,0),
		[Enum.NormalId.Left] = Vector3.new(-1,0,0),
		[Enum.NormalId.Right] = Vector3.new(1,0,0),
		[Enum.NormalId.Front] = Vector3.new(0,0,-1),
		[Enum.NormalId.Back] = Vector3.new(0,0,1),
	}
	local undefined=0/0
	local selectionStart = nil
	local selectionEnd = nil
	local selectionPart = nil
	local selectionObject = nil
	local selectionHandles = nil
	local downLoop = nil
	local clickStart = Vector3.new(0,0,0)
	local dragVector = nil
	local dragStart = true
	local lockedMaterials,lockedOccupancies = nil,nil
	local lockedRegion = nil
	local behindThis = nil
	local axis = "X"
	local materialAir = Enum.Material.Air
	local materialWater = Enum.Material.Water
	local floor = math.floor
	local ceil = math.ceil
	function setButton(newButton)
		lockInMap()
		buttonSelect.Style = newButton == "Select" and Enum.ButtonStyle.RobloxRoundDropdownButton or Enum.ButtonStyle.RobloxRoundDefaultButton
		buttonSelect.TextColor3 = newButton == "Select" and textSelectColor or white
		buttonMove.Style = newButton == "Move" and Enum.ButtonStyle.RobloxRoundDropdownButton or Enum.ButtonStyle.RobloxRoundDefaultButton
		buttonMove.TextColor3 = newButton == "Move" and textSelectColor or white
		buttonResize.Style = newButton == "Resize" and Enum.ButtonStyle.RobloxRoundDropdownButton or Enum.ButtonStyle.RobloxRoundDefaultButton
		buttonResize.TextColor3 = newButton == "Resize" and textSelectColor or white
		buttonRotate.Style = newButton == "Rotate" and Enum.ButtonStyle.RobloxRoundDropdownButton or Enum.ButtonStyle.RobloxRoundDefaultButton
		buttonRotate.TextColor3 = newButton == "Rotate" and textSelectColor or white
		if newButton == "Select" then
			mode = "Select"
			tool = "Resize"
		elseif newButton == "Move" then
			mode = "Edit"
			tool = "Move"
		elseif newButton == "Resize" then
			mode = "Edit"
			tool = "Resize"
		elseif newButton == "Rotate" then
			mode = "Edit"
			tool = "Rotate"
		end
		button = newButton
		renderSelection()
	end
	buttonSelect.MouseButton1Down:connect(function()
		setButton("Select")
	end)
	buttonMove.MouseButton1Down:connect(function()
		setButton("Move")
	end)
	buttonResize.MouseButton1Down:connect(function()
		setButton("Resize")
	end)
	buttonRotate.MouseButton1Down:connect(function()
		setButton("Rotate")
	end)
	buttonFillAir.MouseButton1Down:connect(function()
		fillAir = not fillAir
		buttonFillAir.Text = fillAir and "X" or ""
		if button=="Move" or button=="Resize" then
			updateDragOperation()
		elseif button=="Rotate" then
			updateRotateOperation()
		end
	end)
	buttonFillWater.MouseButton1Down:connect(function()
		fillWater = not fillWater
		buttonFillWater.Text = fillWater and "X" or ""
		if button=="Move" or button=="Resize" then
			updateDragOperation()
		elseif button=="Rotate" then
			updateRotateOperation()
		end
	end)
	function lockInMap()
		if selectionStart and selectionEnd then
			local region = Region3.new((selectionStart-Vector3.new(1,1,1))*resolution,selectionEnd*resolution)
			lockedRegion = region
			lockedMaterials,lockedOccupancies = terrain:ReadVoxels(region,resolution)
		end
	end
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
		if selectionArcHandles then
			selectionArcHandles:Destroy()
			selectionArcHandles = nil
		end
		if selectionHandles then
			selectionHandles:Destroy()
			selectionHandles = nil
		end
		if selectionObject then
			selectionObject:Destroy()
			selectionObject = nil
		end
		if selectionPart then
			selectionPart:Destroy()
			selectionPart = nil
		end
	end
	local function round(n)
		return n+.5-((n+.5)%1)
	end
	local function positionWorldToVoxel(pos)
		return Vector3.new(ceil(pos.x/resolution),ceil(pos.y/resolution),ceil(pos.z/resolution))
	end
	local function make3DTable(size,fill)
		local size = size or Vector3.new(1,1,1)
		local newTable = {}
		for x = 1,size.x do
			local xt = {}
			for y = 1,size.y do
				local yt = {}
				for z = 1,size.z do
					yt[z] = fill
				end
				xt[y] = yt
			end
			newTable[x] = xt
		end
		return newTable
	end
	local function linInterp(a,b,p)
		return a+(b-a)*p
	end
	local function exaggerate(n,exaggeration)
		return (n-.5)*exaggeration+.5
	end
	local function exaggeratedLinInterp(a,b,p,exaggeration)
		local unclamped = (a+(b-a)*p-.5)*exaggeration+.5
		return (unclamped < 0 and 0) or (unclamped > 1 and 1) or unclamped
	end
	function updateDragOperation()
		local dragVector = dragVector or Vector3.new(0,0,0)
		local temporaryStart = selectionStart
		local temporaryEnd = selectionEnd
		if tool == "Resize" then
			if dragStart then
				temporaryStart = Vector3.new(
					math.min(
						math.max(temporaryStart.x+dragVector.x,temporaryEnd.x-regionLengthLimit),
						temporaryEnd.x),
					math.min(
						math.max(temporaryStart.y+dragVector.y,temporaryEnd.y-regionLengthLimit),
						temporaryEnd.y),
					math.min(
						math.max(temporaryStart.z+dragVector.z,temporaryEnd.z-regionLengthLimit),
						temporaryEnd.z)
				)
			else
				temporaryEnd = Vector3.new(
					math.max(
						math.min(temporaryEnd.x+dragVector.x,temporaryStart.x+regionLengthLimit),
						temporaryStart.x),
					math.max(
						math.min(temporaryEnd.y+dragVector.y,temporaryStart.y+regionLengthLimit),
						temporaryStart.y),
					math.max(
						math.min(temporaryEnd.z+dragVector.z,temporaryStart.z+regionLengthLimit),
						temporaryStart.z)
				)
			end
			if mode == "Edit" then
				local region = Region3.new((temporaryStart-Vector3.new(1,1,1))*resolution,temporaryEnd*resolution)
				if behindThis then
					terrain:WriteVoxels(behindThis.region,resolution,behindThis.materials,behindThis.occupancies)
				else
					if selectionStart and selectionEnd then
						local region = Region3.new((selectionStart-Vector3.new(1,1,1))*resolution,selectionEnd*resolution)
						local regionSize = region.Size/resolution
						terrain:WriteVoxels(region,resolution,make3DTable(regionSize,materialAir),make3DTable(regionSize,0))
					end
				end
				behindThis = {}
				behindThis.region = region
				behindThis.materials,behindThis.occupancies = terrain:ReadVoxels(region,resolution)
				local behindMaterials,behindOccupancies = behindThis.materials,behindThis.occupancies
				local loopx = #lockedMaterials-1
				local loopy = #lockedMaterials[1]-1
				local loopz = #lockedMaterials[1][1]-1
				local tempRegionSize = Vector3.new(1,1,1)+temporaryEnd-temporaryStart
				local tempSizeX = tempRegionSize.x
				local tempSizeY = tempRegionSize.y
				local tempSizeZ = tempRegionSize.z
				local newMat = {}
				local newOcc = {}
				for x=1,tempSizeX do
					local scalex = (x-1)/(tempSizeX-1)*loopx
					if scalex ~= scalex then
						scalex = 0
					end
					local startx = floor(scalex)+1
					local endx = startx+1
					local interpScalex = scalex-startx+1
					if startx > loopx then
						endx = startx
					end
					local xtm = {}
					local xto = {}
					for y=1,tempSizeY do
						local scaley = (y-1)/(tempSizeY-1)*loopy
						if scaley ~= scaley then
							scaley = 0
						end
						local starty = floor(scaley)+1
						local endy = starty+1
						local interpScaley = scaley-starty+1
						if starty > loopy then
							endy = starty
						end
						local ytm = {}
						local yto = {}
						for z=1,tempSizeZ do
							local scalez = (z-1)/(tempSizeZ-1)*loopz
							if scalez ~= scalez then
								scalez = 0
							end
							local startz = floor(scalez)+1
							local endz = startz+1
							local interpScalez = scalez-startz+1
							if startz > loopz then
								endz = startz
							end
							local interpz1 = exaggeratedLinInterp(lockedOccupancies[startx][starty][startz],lockedOccupancies[startx][starty][endz],interpScalez,tempSizeZ/(loopz+1))
							local interpz2 = exaggeratedLinInterp(lockedOccupancies[startx][endy][startz],lockedOccupancies[startx][endy][endz],interpScalez,tempSizeZ/(loopz+1))
							local interpz3 = exaggeratedLinInterp(lockedOccupancies[endx][starty][startz],lockedOccupancies[endx][starty][endz],interpScalez,tempSizeZ/(loopz+1))
							local interpz4 = exaggeratedLinInterp(lockedOccupancies[endx][endy][startz],lockedOccupancies[endx][endy][endz],interpScalez,tempSizeZ/(loopz+1))
							local interpy1 = exaggeratedLinInterp(interpz1,interpz2,interpScaley,tempSizeY/(loopy+1))
							local interpy2 = exaggeratedLinInterp(interpz3,interpz4,interpScaley,tempSizeY/(loopy+1))
							local interpx1 = exaggeratedLinInterp(interpy1,interpy2,interpScalex,tempSizeX/(loopx+1))
							local newMaterial = lockedMaterials[round(scalex)+1][round(scaley)+1][round(scalez)+1]
							if fillAir and newMaterial == materialAir then
								ytm[z]=behindMaterials[x][y][z]
								yto[z]=behindOccupancies[x][y][z]
							elseif fillWater and newMaterial == materialWater and behindMaterials[x][y][z] ~= materialAir then
								ytm[z]=behindMaterials[x][y][z]
								yto[z]=behindOccupancies[x][y][z]
							else
								ytm[z]=newMaterial
								yto[z]=interpx1
							end
						end
						xtm[y] = ytm
						xto[y] = yto
					end
					newMat[x] = xtm
					newOcc[x] = xto
				end
				terrain:WriteVoxels(region,resolution,newMat,newOcc)
			else
				behindThis = nil
			end
		elseif tool == "Move" then
			temporaryStart = temporaryStart+dragVector
			temporaryEnd = temporaryEnd+dragVector
			if mode == "Edit" then
				local region = Region3.new((temporaryStart-Vector3.new(1,1,1))*resolution,temporaryEnd*resolution)
				if behindThis then
					terrain:WriteVoxels(behindThis.region,resolution,behindThis.materials,behindThis.occupancies)
				else
					if selectionStart and selectionEnd then
						local region = Region3.new((selectionStart-Vector3.new(1,1,1))*resolution,selectionEnd*resolution)
						local regionSize = region.Size/resolution
						terrain:WriteVoxels(region,resolution,make3DTable(regionSize,materialAir),make3DTable(regionSize,0))
					end
				end
				behindThis = {}
				behindThis.region = region
				behindThis.materials,behindThis.occupancies = terrain:ReadVoxels(region,resolution)
				local behindMaterials,behindOccupancies = behindThis.materials,behindThis.occupancies
				if not (fillAir or fillWater) then
					terrain:WriteVoxels(region,resolution,lockedMaterials,lockedOccupancies)
				else
					local newMat = {}
					local newOcc = {}
					for x,xv in ipairs(lockedMaterials) do
						local xtm = {}
						local xto = {}
						for y,yv in ipairs(xv) do
							local ytm = {}
							local yto = {}
							for z,zv in ipairs(yv) do
								if fillAir and zv == materialAir then
									ytm[z]=behindMaterials[x][y][z]
									yto[z]=behindOccupancies[x][y][z]
								elseif fillWater and zv == materialWater and behindMaterials[x][y][z] ~= materialAir then
									ytm[z]=behindMaterials[x][y][z]
									yto[z]=behindOccupancies[x][y][z]
								else
									ytm[z]=lockedMaterials[x][y][z]
									yto[z]=lockedOccupancies[x][y][z]
								end
							end
							xtm[y] = ytm
							xto[y] = yto
						end
						newMat[x] = xtm
						newOcc[x] = xto
					end
					terrain:WriteVoxels(region,resolution,newMat,newOcc)
				end
			end
		end
		renderSelection(temporaryStart,temporaryEnd)
	end
	function dragHandles(face,delta)
		local normal = faceToNormal[face]
		local delta = delta
		local newDragVector = normal*floor((delta+.5)/resolution)
		dragStart = normal.x < 0 or normal.y < 0 or normal.z < 0
		if newDragVector ~= dragVector then
			dragVector = newDragVector
			updateDragOperation()
		end
	end
	local function rotate(mx,x,my,y,rotation)
		if rotation == 1 then
			return my+1-y,x 
		elseif rotation == 2 then
			return mx+1-x,my+1-y
		elseif rotation == 3 then
			return y,mx+1-x
		end
		return x,y
	end
	function updateRotateOperation()
		local dragAngle = dragAngle or 0
		local rotationCFrame = CFrame.Angles(
			axis ~= "X" and 0 or dragAngle*rotationInterval,
			axis ~= "Y" and 0 or dragAngle*rotationInterval,
			axis ~= "Z" and 0 or dragAngle*rotationInterval
		)
		local temporarySize = Vector3.new(1,1,1)+selectionEnd-selectionStart
		local centerOffset = Vector3.new(ceil(temporarySize.x*.5),ceil(temporarySize.y*.5),ceil(temporarySize.z*.5))
		temporarySize = rotationCFrame*temporarySize
		local temporarySizeX = round(math.abs(temporarySize.x))
		local temporarySizeY = round(math.abs(temporarySize.y))
		local temporarySizeZ = round(math.abs(temporarySize.z))
		centerOffset = centerOffset-Vector3.new(ceil(temporarySizeX*.5),ceil(temporarySizeY*.5),ceil(temporarySizeZ*.5))
		local temporaryEnd = selectionStart+centerOffset+Vector3.new(temporarySizeX,temporarySizeY,temporarySizeZ)-Vector3.new(1,1,1)
		local temporaryStart = selectionStart+centerOffset
		if mode == "Edit" then
		local region = Region3.new((temporaryStart-Vector3.new(1,1,1))*resolution,temporaryEnd*resolution)
			if behindThis then
				terrain:WriteVoxels(behindThis.region,resolution,behindThis.materials,behindThis.occupancies)
			else
				if selectionStart and selectionEnd then
					local region = Region3.new((selectionStart-Vector3.new(1,1,1))*resolution,selectionEnd*resolution)
					local regionSize = region.Size/resolution
					terrain:WriteVoxels(region,resolution,make3DTable(regionSize,materialAir),make3DTable(regionSize,0))
				end
			end
			behindThis = {}
			behindThis.region = region
			behindThis.materials,behindThis.occupancies = terrain:ReadVoxels(region,resolution)
			local newMat = {}
			local newOcc = {}
			for x=1,temporarySizeX do
				local xtm = {}
				local xto = {}
				for y=1,temporarySizeY do
					local ytm = {}
					local yto = {}
					for z=1,temporarySizeZ do
						local targetx = x
						local targety = y
						local targetz = z
						if axis == "Y" then
							targetx,targetz = rotate(temporarySizeX,x,temporarySizeZ,z,dragAngle)
						elseif axis == "X" then
							targetz,targety = rotate(temporarySizeZ,z,temporarySizeY,y,dragAngle)
						elseif axis == "Z" then
							targety,targetx = rotate(temporarySizeY,y,temporarySizeX,x,dragAngle)
						end
						local newMaterial = lockedMaterials[targetx][targety][targetz]
						if fillAir and newMaterial == materialAir then
							ytm[z]=behindThis.materials[x][y][z]
							yto[z]=behindThis.occupancies[x][y][z]
						elseif fillWater and newMaterial == materialWater and behindThis.materials[x][y][z] ~= materialAir then
							ytm[z]=behindThis.materials[x][y][z]
							yto[z]=behindThis.occupancies[x][y][z]
						else
							ytm[z]=newMaterial
							yto[z]=lockedOccupancies[targetx][targety][targetz]
						end
					end
					xtm[y] = ytm
					xto[y] = yto
				end
				newMat[x] = xtm
				newOcc[x] = xto
			end
			terrain:WriteVoxels(region,resolution,newMat,newOcc)
		end
		renderSelection(temporaryStart,temporaryEnd,rotationCFrame)
	end
	function dragArcHandles(rotationAxis,relativeAngle,deltaRadius)
		axis = rotationAxis.Name
		local newDragAngle = round(relativeAngle/rotationInterval)%4
		if newDragAngle ~= dragAngle then
			dragAngle = newDragAngle
			updateRotateOperation()
		end
	end
	buttonCopy.MouseButton1Down:connect(function()
		if selectionStart and selectionEnd then
			local selectionStartInt16=Vector3int16.new(selectionStart.x-1,selectionStart.y-1,selectionStart.z-1)
			local selectionEndInt16=Vector3int16.new(selectionEnd.x-1,selectionEnd.y-1,selectionEnd.z-1)
			local region = Region3int16.new(selectionStartInt16,selectionEndInt16)
			copyRegion = terrain:CopyRegion(region)
			selectionEffect(nil,nil,"New Yeller",1,1.2,.5)
		end
	end)
	buttonPaste.MouseButton1Down:connect(function()
		if copyRegion then
			selectionEnd=selectionStart+copyRegion.SizeInCells-Vector3.new(1,1,1)
			local region = Region3.new((selectionStart-Vector3.new(1,1,1))*resolution,selectionEnd*resolution)
			behindThis = {}
			behindThis.region = region
			behindThis.materials,behindThis.occupancies = terrain:ReadVoxels(region,resolution)
			terrain:PasteRegion(copyRegion,Vector3int16.new(selectionStart.x-1,selectionStart.y-1,selectionStart.z-1),true)
			setButton("Move")
			selectionEffect(nil,nil,"Lime green",1.2,1,.5)
		end
	end)
	buttonDelete.MouseButton1Down:connect(function()
		if selectionStart and selectionEnd then
			local region = Region3.new((selectionStart-Vector3.new(1,1,1))*resolution,selectionEnd*resolution)
			local regionSize = region.Size/resolution
			local emptyMaterialMap = make3DTable(regionSize,materialAir)
			local emptyOccupancyMap = make3DTable(regionSize,0)
			if behindThis then
				terrain:WriteVoxels(behindThis.region,resolution,behindThis.materials,behindThis.occupancies)
			else
				if selectionStart and selectionEnd then
					terrain:WriteVoxels(region,resolution,emptyMaterialMap,emptyOccupancyMap)
				end
			end
			behindThis = {}
			behindThis.region = region
			behindThis.materials,behindThis.occupancies = terrain:ReadVoxels(region,resolution)
			local oldStart,oldEnd = selectionStart,selectionEnd
			selectionStart,selectionEnd = nil,nil
			setButton("Select")
			selectionEffect(oldStart,oldEnd,"Really red",1,1.2,.5)
		end
	end)
	function selectionEffect(temporaryStart,temporaryEnd,color,sizeFrom,sizeTo,effectTime)
		local temporaryStart = temporaryStart or selectionStart
		local temporaryEnd = temporaryEnd or selectionEnd
		local effectPart = Instance.new("Part")
		effectPart.Name = "EffectPart"
		effectPart.Transparency = 1
		effectPart.TopSurface = "Smooth"
		effectPart.BottomSurface = "Smooth"
		effectPart.Anchored = true
		effectPart.CanCollide = false
		effectPart.formFactor = "Custom"
		effectPart.Parent = gui
		local selectionEffectObject = Instance.new("SelectionBox")
		selectionEffectObject.Name = "SelectionObject"
		selectionEffectObject.Transparency = 1
		selectionEffectObject.SurfaceTransparency = .75
		selectionEffectObject.SurfaceColor = BrickColor.new(color)
		selectionEffectObject.Adornee = effectPart
		selectionEffectObject.Parent = effectPart
		local baseSize = ((temporaryEnd-temporaryStart+Vector3.new(1,1,1))*resolution+Vector3.new(.21,.21,.21))
		effectPart.CFrame = CFrame.new((temporaryStart+temporaryEnd-Vector3.new(1,1,1))*.5*resolution)
		effectPart.Size = baseSize*sizeFrom
		local endTick=tick()+effectTime
		while endTick>tick() do
			local percent=1-(endTick-tick())/effectTime
			selectionEffectObject.SurfaceTransparency = .75+percent*.25
			effectPart.Size = baseSize*(sizeFrom+(sizeTo-sizeFrom)*percent)
			wait()
		end
		effectPart:Destroy()
	end
	function renderSelection(temporaryStart,temporaryEnd,rotation)
		local temporaryStart = temporaryStart or selectionStart
		local temporaryEnd = temporaryEnd or selectionEnd
		local seeable = false
		if temporaryStart and temporaryEnd and selectionPart then
			seeable = true
			local temporarySize = ((temporaryEnd-temporaryStart+Vector3.new(1,1,1))*resolution+Vector3.new(.2,.2,.2))
			if rotation then
				local rotatedSize = rotation*temporarySize
				temporarySize = Vector3.new(math.abs(rotatedSize.x),math.abs(rotatedSize.y),math.abs(rotatedSize.z))
			end
			selectionPart.Size = temporarySize
			selectionPart.CFrame = CFrame.new((temporaryStart+temporaryEnd-Vector3.new(1,1,1))*.5*resolution)*(rotation or CFrame.new(0,0,0))
		end
		if selectionObject then
			selectionObject.Visible = seeable
			selectionObject.Color = BrickColor.new(mode == "Select" and "Toothpaste" or editColor1)
			selectionObject.SurfaceColor = BrickColor.new(mode == "Select" and "Toothpaste" or editColor1)
		end
		if selectionHandles then
			selectionHandles.Visible = seeable and (tool == "Move" or tool == "Resize")
			selectionHandles.Color = BrickColor.new(mode == "Select" and "Cyan" or editColor2)
			selectionHandles.Style = tool == "Move" and Enum.HandlesStyle.Movement or Enum.HandlesStyle.Resize
		end
		if selectionArcHandles then
			selectionArcHandles.Visible = seeable and tool == "Rotate"
			selectionArcHandles.Color = BrickColor.new(mode == "Select" and "Cyan" or editColor2)
		end
	end
	function Selected()
		on = true
		gui.Parent = coreGui
		if not selectionPart then
			selectionPart = Instance.new("Part")
			selectionPart.Name = "SelectionPart"
			selectionPart.Transparency = 1
			selectionPart.TopSurface = "Smooth"
			selectionPart.BottomSurface = "Smooth"
			selectionPart.Anchored = true
			selectionPart.CanCollide = false
			selectionPart.formFactor = "Custom"
			selectionPart.Parent = gui
		end
		if not selectionObject then
			selectionObject = Instance.new("SelectionBox")
			selectionObject.Name = "SelectionObject"
			selectionObject.Color = BrickColor.new(mode == "Select" and "Toothpaste" or editColor1)
			selectionObject.SurfaceTransparency = .85
			selectionObject.SurfaceColor = BrickColor.new(mode == "Select" and "Toothpaste" or editColor1)
			selectionObject.Adornee = selectionPart
			selectionObject.Visible = false
			selectionObject.Parent = selectionPart
		end
		if not selectionHandles then
			selectionHandles = Instance.new("Handles")
			selectionHandles.Name = "SelectionHandles"
			selectionHandles.Color = BrickColor.new(mode == "Select" and "Toothpaste" or editColor2)
			selectionHandles.Adornee = selectionPart
			selectionHandles.Visible = false
			selectionHandles.Parent = coreGui
			selectionHandles.MouseDrag:connect(dragHandles)
		end
		if not selectionArcHandles then
			selectionArcHandles = Instance.new("ArcHandles")
			selectionArcHandles.Name = "SelectionArcHandles"
			selectionArcHandles.Color = BrickColor.new(mode == "Select" and "Toothpaste" or editColor2)
			selectionArcHandles.Adornee = selectionPart
			selectionArcHandles.Visible = false
			selectionArcHandles.Parent = coreGui
			selectionArcHandles.MouseDrag:connect(dragArcHandles)
		end
		renderSelection()
		setButton(button)
	end
	function Deselected()
		setButton("Select")
		gui.Parent = script.Parent
		clearSelection()
		behindThis = nil
		on = false
		if turnOff then
			turnOff()
		end
	end
	mouse.Button1Down:connect(function()
		if on and mode == "Select" then
			mouseDown = true
			behindThis = nil
			local mousePos = mouse.Hit.p+mouse.UnitRay.Direction*.05
			if mouse.Target == nil then
				mousePos = game.Workspace.CurrentCamera.CoordinateFrame.p+mouse.UnitRay.Direction*1000
			end
			clickStart = positionWorldToVoxel(mousePos)
			local thisDownLoop = {}
			downLoop = thisDownLoop
			while thisDownLoop == downLoop and mouseDown and on and mode == "Select" do
				local mousePos = mouse.Hit.p+mouse.UnitRay.Direction*.05
				if mouse.Target == nil then
					mousePos = game.Workspace.CurrentCamera.CoordinateFrame.p+mouse.UnitRay.Direction*1000
				end
				local voxelCurrent = positionWorldToVoxel(mousePos)
				voxelCurrent = Vector3.new(
					math.max(math.min(voxelCurrent.x,clickStart.x+regionLengthLimit),clickStart.x-regionLengthLimit),
					math.max(math.min(voxelCurrent.y,clickStart.y+regionLengthLimit),clickStart.y-regionLengthLimit),
					math.max(math.min(voxelCurrent.z,clickStart.z+regionLengthLimit),clickStart.z-regionLengthLimit))
				selectionStart = Vector3.new(math.min(clickStart.x,voxelCurrent.x),math.min(clickStart.y,voxelCurrent.y),math.min(clickStart.z,voxelCurrent.z))
				selectionEnd = Vector3.new(math.max(clickStart.x,voxelCurrent.x),math.max(clickStart.y,voxelCurrent.y),math.max(clickStart.z,voxelCurrent.z))
				renderSelection()
				quickWait()
			end
		end
	end)
	mouse.Button1Up:connect(function()
		mouseDown = false
		if dragVector and dragVector.magnitude > 0 then
			if tool == "Resize" then
				if dragStart then
					selectionStart = Vector3.new(
						math.min(
							math.max(selectionStart.x+dragVector.x,selectionEnd.x-regionLengthLimit),
							selectionEnd.x),
						math.min(
							math.max(selectionStart.y+dragVector.y,selectionEnd.y-regionLengthLimit),
							selectionEnd.y),
						math.min(
							math.max(selectionStart.z+dragVector.z,selectionEnd.z-regionLengthLimit),
							selectionEnd.z)
					)
				else
					selectionEnd = Vector3.new(
						math.max(
							math.min(selectionEnd.x+dragVector.x,selectionStart.x+regionLengthLimit),
							selectionStart.x),
						math.max(
							math.min(selectionEnd.y+dragVector.y,selectionStart.y+regionLengthLimit),
							selectionStart.y),
						math.max(
							math.min(selectionEnd.z+dragVector.z,selectionStart.z+regionLengthLimit),
							selectionStart.z)
					)
				end
			elseif tool == "Move" then
				selectionStart = selectionStart+dragVector
				selectionEnd = selectionEnd+dragVector
			end
		end
		if dragAngle and dragAngle ~= 0 then
			local rotationCFrame = CFrame.Angles(
				axis ~= "X" and 0 or dragAngle*rotationInterval,
				axis ~= "Y" and 0 or dragAngle*rotationInterval,
				axis ~= "Z" and 0 or dragAngle*rotationInterval
			)
			local temporarySize = Vector3.new(1,1,1)+selectionEnd-selectionStart
			local centerOffset = Vector3.new(ceil(temporarySize.x*.5),ceil(temporarySize.y*.5),ceil(temporarySize.z*.5))
			temporarySize = rotationCFrame*temporarySize
			local temporarySizeX = round(math.abs(temporarySize.x))
			local temporarySizeY = round(math.abs(temporarySize.y))
			local temporarySizeZ = round(math.abs(temporarySize.z))
			centerOffset = centerOffset-Vector3.new(ceil(temporarySizeX*.5),ceil(temporarySizeY*.5),ceil(temporarySizeZ*.5))
			
			selectionEnd = selectionStart+centerOffset+Vector3.new(temporarySizeX,temporarySizeY,temporarySizeZ)-Vector3.new(1,1,1)
			selectionStart = selectionStart+centerOffset
			lockInMap()
		end
		dragVector = nil
		dragAngle = nil
		renderSelection()
	end)
	closeButton.MouseButton1Down:connect(Deselected)
end

function On(mouseHandMeDown,turnOffHandMeDown)
	mouse = mouseHandMeDown
	turnOff = turnOffHandMeDown
	if not setup then
		FirstTimeSetUp()
	end
	Selected()
end

function Off()
	if Deselected then
		Deselected()
	end
end

return {
	["On"] = On,
	["Off"] = Off,
}
