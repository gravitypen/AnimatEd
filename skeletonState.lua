


skeletonState = {
	shortcuts = {},
	skeletons = {},
	currentID = 0,
	currentSkeleton = test.skel,
	zoomLevel = 0,
	zoom = 1.0,
	modes = {bones = 1, images = 2},
	mode = 1,
	hoveredElement = nil,
	selectedElement = nil,
	editing = false,
	camX = 0,
	camY = 0,
}


function skeletonState.load()
	-- Load Skeletons
end


function skeletonState.enter()
	skeletonState.skeletons[1] = test.skel
	--skeletonState.skeletons[1].defaultPose = animator.newPose(skeletonState.skeletons[1])
	skeletonState.mode = skeletonState.modes.bones
	skeletonState.selectedElement = nil
	skeletonState.hoveredElement = nil
	--questionDialog("Test Question", function() print("It worked!") end, function() print("No was clicked") end)
end

function skeletonState.keypressed(key)
	if key == "tab" then
		-- Switch Mode
		skeletonState.mode = 3 - skeletonState.mode
	elseif key == "delete" then
		if skeletonState.selectedElement then
			local element = skeletonState.selectedElement
			if element.name ~= "ROOT" then
				questionDialog("Do you really want to delete '" .. element.name .. "' and all its childs?", 
					function() animator.deleteElement(element); skeletonState.hoveredElement = nil; skeletonState.selectedElement = nil; end, nil)
			else
				infoDialog("Can't delete root bone!")
			end
		end
	elseif key == "pageup" then
		if skeletonState.selectedElement and skeletonState.selectedElement.tp == "bone" then
			skeletonState.selectedElement.drawOverParent = true
		end
	elseif key == "pagedown" then
		if skeletonState.selectedElement and skeletonState.selectedElement.tp == "bone" then
			skeletonState.selectedElement.drawOverParent = false
		end
	end
end

function skeletonState.update()

	-- Mousewheel
	if states.mouse.mz ~= 0 then
		if states.getKeyDown("lctrl") then
			-- Zoom
			skeletonState.zoomLevel = clamp(skeletonState.zoomLevel + states.mouse.mz, -32, 32)
			skeletonState.zoom = math.pow(1.1, skeletonState.zoomLevel)
		else
			-- Transform Image
			if skeletonState.mode == skeletonState.modes.images then
				if skeletonState.selectedElement and skeletonState.selectedElement.tp == "img" then 
					local pose = skeletonState.currentSkeleton.defaultPose
					local img = skeletonState.selectedElement
					local xpressed = states.getKeyDown("x")
					local ypressed = states.getKeyDown("y")
					local nonepressed = (not xpressed and not ypressed)
					if states.getKeyDown("lalt") or xpressed or ypressed then
						-- Scale Image
						local fac = math.pow((states.getKeyDown("lshift") and 1.01 or 1.1), states.mouse.mz)
						local xsc = pose.state[img.id][5] or 1.0
						local ysc = pose.state[img.id][6] or 1.0
						if xpressed or nonepressed then
							-- Scale X 
							xsc = fac*xsc
						end
						if ypressed or nonepressed then
							-- Scale Y 
							if ysc == true then ysc = xsc end
							ysc = fac*ysc
						end
						animator.setPoseImage(pose, img, nil, nil, nil, xsc, ysc)
					else
						-- Rotate Image
						local dA = states.mouse.mz * (states.getKeyDown("lshift") and 1.0 or 12.0)
						local newAngle = wrapAngle(skeletonState.selectedElement.angle + dA*math.pi/180.0)
						animator.setPoseImage(pose, img, nil, nil, newAngle)
					end
				end
			end
		end
	end

	-- Mouse Selection
	local ctrl = states.getKeyDown("lctrl")
	if skeletonState.editing then 

		local hover, selTrg
		if skeletonState.currentSkeleton then
			if skeletonState.mode == skeletonState.modes.bones then
				-- Bone Selection
				hover, selTrg = skeletonState.pickBone(skeletonState.currentSkeleton, states.mouse.skelx, states.mouse.skely)
			else
				-- Image Selection
				hover = skeletonState.pickImage(skeletonState.currentSkeleton, states.mouse.skelx, states.mouse.skely)
			end
			-- Apply
			if hover then
				skeletonState.hoveredElement = hover
			else
				if states.mouse.leftclick == 2 then
					-- Deselect, but only if mouse not on GUI .. evil evil hack
					if states.mouse.x > 220 and states.mouse.x < states.windowW - 220 then
						skeletonState.selectElement(nil)
					end
				end
			end
		end

		-- Drag & Drop
		if not ctrl then
			if states.mouse.dragJustStarted then
				-- Drag Bone or Image
				if hover then
					if skeletonState.mode == skeletonState.modes.bones then
						-- Bone Editing
						if selTrg == 1 then states.mouse.dragCallback = function(dx,dy) skeletonState.moveBone(hover, dx, dy, true, false) end end
						if selTrg == 2 then states.mouse.dragCallback = function(dx,dy) skeletonState.moveBone(hover, dx, dy, false, true) end end
						if selTrg == 3 then states.mouse.dragCallback = function(dx,dy) skeletonState.moveBone(hover, dx, dy, true, true) end end
						states.mouse.dropCallback = nil
						skeletonState.selectElement(hover)
					else
						-- Image Editing
						states.mouse.dragCallback = function(dx,dy) skeletonState.moveImage(hover, dx, dy) end
						states.mouse.dropCallback = nil
						skeletonState.selectElement(hover)
					end
				end
			end
		end
	end

	if ctrl and states.mouse.dragJustStarted then
		-- Move Camera
		states.mouse.dragCallback = function(dx,dy) 
			skeletonState.camX = skeletonState.camX - states.mouse.mx/skeletonState.zoom --dx/skeletonState.zoom
			skeletonState.camY = skeletonState.camY - states.mouse.my/skeletonState.zoom --dy/skeletonState.zoom
			print("Dragging by dif " .. dx .. "," .. dy) 
		end
		states.mouse.dropCallback = nil
	end

	-- Clamp Camera Position
	skeletonState.camX = clamp(skeletonState.camX, -8192, 8192)
	skeletonState.camY = clamp(skeletonState.camY, -8192, 8192)

end

	function skeletonState.selectElement(e)
		if e then print("Selecting Element " .. e.name) else print("Deselecting Element") end
		if skeletonState.currentSkeleton then
			skeletonState.selectedElement = e
			skeletonState.currentSkeleton.rootChild.childs[1].__treeview_selected = e
		end
	end

	function skeletonState.moveBone(bone, dx, dy, moveStartPos, moveEndPos)
		local pose = skeletonState.currentSkeleton.defaultPose
		-- Transform dx,dy to make sure bone moves relative to screen
		-- Rotate by -bone.angle 
		local s, c, ang, newdx, newdy
		ang = -bone.parent.__angle
		s = math.sin(ang)
		c = math.cos(ang)
		newdx = c*dx - s*dy
		newdy = -s*dx - c*dy
		-- Get Values
		local state = pose.state[bone.id]
		local x1 = moveStartPos and state[1]+newdx or state[1]
		local y1 = moveStartPos and state[2]+newdy or state[2]
		local newAngle = state[3]
		local newScale = state[6]
		if moveEndPos and not moveStartPos then 
			local difx = bone.length * state[6] * math.sin(state[3]) + newdx
			local dify = bone.length * state[6] * math.cos(state[3]) + newdy
			newAngle = getAngle(-difx, -dify)
			if states.getKeyDown("lshift") then 
				-- Press Shift to change scaling
				newScale = math.sqrt(difx*difx + dify*dify)/bone.length 
			else
				-- Press CTRL to change bone length without affecting scale
				if states.getKeyDown("lctrl") then bone.length = math.sqrt(difx*difx + dify*dify)/state[6] end
			end
			if states.getKeyDown("r") then newScale = 1.0 end
		end
		-- Apply
		animator.setPoseBone(pose, bone,
			x1,
			y1,
			newAngle,
			nil,
			newScale
		)
	end

	function skeletonState.moveImage(img, dx, dy)
		local pose = skeletonState.currentSkeleton.defaultPose
		-- Transform dx,dy to make sure bone moves relative to screen
		-- Rotate by -bone.angle 
		local parent = img.bone
		local ang = -parent.__angle
		local s = math.sin(ang)
		local c = math.cos(ang)
		local newdx = c*dx - s*dy
		local newdy = -s*dx - c*dy
		-- Get Values
		local state = pose.state[img.id]
		local x1 = state[1]+newdx 
		local y1 = state[2]+newdy
		local newAngle = state[3]
		local newScale = state[6]
		-- Apply
		animator.setPoseImage(pose, img,
			x1,
			y1,
			newAngle,
			nil,
			newScale,
			state[4]
		)
	end


function skeletonState.draw()

	-- Back
	--love.graphics.setColor(editor.backColor)
	--love.graphics.rectangle("fill", 0, 0, states.windowW, states.windowH)
	drawGrid(skeletonState.camX, skeletonState.camY, skeletonState.zoom)

	-- Selected Skeleton
	local skel = skeletonState.currentSkeleton
	if skel then
		-- Mode
		local sx = states.windowW*0.5 - skeletonState.camX*skeletonState.zoom
		local sy = states.windowH*0.5 - skeletonState.camY*skeletonState.zoom
		if states.getKeyDown("v") then
			-- Press V to see character fully
			animator.drawPose(skel.defaultPose, sx, sy, 0.0, skeletonState.zoom, skeletonState.zoom, 1.0, states.getKeyDown("d"))			
		elseif skeletonState.editing then
			if skeletonState.mode == skeletonState.modes.bones then
				-- Bone Editing
				animator.drawPose(skel.defaultPose, sx, sy, 0.0, skeletonState.zoom, skeletonState.zoom, 0.3, false)
				animator.reapplyPreviousPoseTransformation()
				animator.drawDebugSkeleton(skel)
				animator.drawDebugCross(skel.rootChild.childs[1].__x, skel.rootChild.childs[1].__y)
				animator.undoPoseTransformation()
			else
				-- Image Editing
				animator.drawBoundingBoxes = true
				animator.drawPose(skel.defaultPose, sx, sy, 0.0, skeletonState.zoom, skeletonState.zoom, 1.0, false)
				animator.reapplyPreviousPoseTransformation()
				animator.drawDebugCross(skel.rootChild.childs[1].__x, skel.rootChild.childs[1].__y)
				animator.undoPoseTransformation()
				animator.drawBoundingBoxes = false
			end
		else
			-- Overview
			animator.drawPose(skel.defaultPose, sx, sy, 0.0, skeletonState.zoom, skeletonState.zoom, 1.0, false)
			animator.reapplyPreviousPoseTransformation()
			animator.drawDebugSkeleton(skel)
			animator.drawDebugCross(skel.rootChild.childs[1].__x, skel.rootChild.childs[1].__y)
			animator.undoPoseTransformation()
		end
		states.registerTransformation()
	end



	-- Title
	local title = "Skeleton"
	if skeletonState.editing then
		title = "Skeleton" .. ((skeletonState.mode == skeletonState.modes.bones) and " - Bones" or " - Images")
	else
		title = "Skeletons"
	end
	states.drawTitle(title)



	-- List of Skeletons
	if not skeletonState.editing then
		local sel, hover = listview(1, 1, 220, 600, skeletonState.skeletons, function(skel) return skel.name end )
		if sel then
			-- Select Skeleton
			skeletonState.currentID = sel
			skeletonState.currentSkeleton = skeletonState.skeletons[sel]
		end
		-- New Skeleton
		if button(110, 670, 160, 25, "Create New") then
			textInput("Name of new Skeleton:", "", function(name)
				if string.len(name) > 2 then
					textInput("Root Path for '" .. name .. "' Skeleton:", "", function(path) 
						if string.len(path) > 5 then
							-- Create
							local skel = animator.newSkeleton(name, path)
							table.insert(skeletonState.skeletons, skel)
							-- Apply as currently edited skeleton
							skeletonState.currentSkeleton = skel
							skeletonState.editing = true
							animator.newBone("ROOT", skel)
							print("New Skeleton's Path: " .. skel.projectPath)
						end
					end, nil, nil)
				end
			end, nil, nil)
		end
		-- Start Editing
		if skeletonState.currentSkeleton then
			if button(110, 630, 160, 25, "Edit") then 
				skeletonState.editing = true
			end
		end
	end



	-- Bones of Current Skeleton
	if skeletonState.editing then
		local sel, hover = treeview(1,1,220,700, skel.rootChild.childs[1], 
			function(e) return e.name end,
			function(e) return (e.childs and e.childs[1]) or (e.images and e.images[1]) end,
			function(e) 
				if e.tp == "img" then
					for i =1,#e.bone.images do
						if e.bone.images[i] == e then return e.bone.images[i+1] end
					end
				else
					if not e.parent.childs then return nil end --root bone has no siblings 
					for i=1,#e.parent.childs-1 do
						if e.parent.childs[i] == e then return e.parent.childs[i+1] end
					end
					return e.parent.images[1]
				end
				return nil
			end,
			function(c,p) 
				animator.reorderBones(c, p, true) 
				-- apply transformation stuff to pose (since images are being retransformed to keep their absolute position and angle)
				if c.tp == "img" then
					animator.setPoseImage(skeletonState.currentSkeleton.defaultPose, c, c.x, c.y, c.angle)
				end
			end
		)
		if hover then
			skeletonState.hoveredElement = hover
		end
		skeletonState.selectedElement = sel

		-- Highlight whatever is hovered
		skeletonState.highlight(skeletonState.hoveredElement)
		skeletonState.highlight(skeletonState.selectedElement)

		-- Images of this Skeleton
		local sel, hover = listview(states.windowW-220,1,220,states.windowH-100, skel.imageList)
		skeletonState.selectedImage = sel

		-- Add Bone
		if button(110,730,100,25, "Add Bone") then
			-- Apply State
			skeletonState.mode = skeletonState.modes.bones
			-- Create Bone
			local parent = skeletonState.selectedElement
			if not parent or parent.tp ~= "bone" then parent = skeletonState.currentSkeleton.rootChild.childs[1] end
			textInput("Bone Name", "", function(s)
				skeletonState.selectedElement = animator.newBone(s, parent)
			end)
		end
		-- Add Image
		if skeletonState.selectedImage and skeletonState.selectedElement and skeletonState.selectedElement.tp == "bone" then
			if button(states.windowW-110,states.windowH-25, 140,25, "Add to Bone") then
				-- Apply State
				skeletonState.mode = skeletonState.modes.images
				-- Create Image
				local img = animator.newImage(skel.imageList[skeletonState.selectedImage], skeletonState.selectedElement)
				skeletonState.selectElement(img)
			end
		end

		-- Update Images
		if button(states.windowW-110, states.windowH-75, 140, 25, "Refresh") then
			animator.refreshImages(skel)
		end

		-- Make sure no element stays hovered
		skeletonState.hoveredElement = nil

	end

end


function skeletonState.highlight(e)
	if e then
		if e.tp == "bone" then
			if e.name ~= "#root" then
				animator.reapplyPreviousPoseTransformation()
				animator.drawSingleDebugBone(e)
				animator.undoPoseTransformation()
				e.__highlight = 1
			end
			for i = 1,#e.images do
				e.images[i].__highlight = 1 
			end
		else
			animator.reapplyPreviousPoseTransformation()
			animator.drawSingleDebugBone(e.bone)
			animator.undoPoseTransformation()
			e.__highlight = 1
		end			
	end
end


function skeletonState.mouseNearPoint(x,y,dis)
	local dx = x - states.mouse.skelx
	local dy = y - states.mouse.skely
	return dx*dx + dy*dy <= dis*dis
end

function skeletonState.pointNearPoint(x1,y1, x2,y2, dis)
	local dx = x2 - x1
	local dy = y2 - y1
	return dx*dx + dy*dy <= dis*dis
end

function skeletonState.pointInBox(x,y, x1,y1,x2,y2, checkBoxInversion, tolerance)
	if checkBoxInversion then
		if x2 < x1 then x1,x2 = x2,x1 end
		if y2 < y1 then y1,y2 = y2,y1 end
	end
	if tolerance then
		x1 = x1 - tolerance
		y1 = y1 - tolerance
		x2 = x2 + tolerance
		y2 = y2 + tolerance
	end
	return x >= x1 and x <= x2 and y >= y1 and y <= y2
end

function skeletonState.pointInRotatedBox(px,py, x,y,w,h,a)
	-- get point relative to box
	px = px - x
	py = py - y
	-- rotate by -angle
	local s = math.sin(-a)
	local c = math.cos(-a)
	local nx = c*px - s*py
	local ny = s*px + c*py
	-- offset
	nx = nx + 0.5*w
	ny = ny + 0.5*h
	return nx >= 0 and ny >= 0 and nx <= w and ny <= h
end


function skeletonState.pickBone(skel,x,y)
	for id,element in pairs(skel.elementMap) do
		if element.tp == "bone" and element.name ~= "#root" then
			-- Start Point
			if skeletonState.pointNearPoint(x, y, element.__x, element.__y, 5) then
				return element, 1
			end
			-- End Point
			if skeletonState.pointNearPoint(x, y, element.__x2, element.__y2, 4) then
				return element, 2
			end
			-- in between
			if skeletonState.pointInBox(x,y, element.__x, element.__y, element.__x2, element.__y2, true, 3) then
				local steps = math.floor((element.length*element.scaleY)/2)
				local p
				local f = 1.0/steps
				local dx = element.__x2 - element.__x
				local dy = element.__y2 - element.__y
				for i = 0,steps do
					p = i*f
					if skeletonState.pointNearPoint(x,y, element.__x + p*dx, element.__y + p*dy, 2) then
						return element, 3
					end
				end
			end
		end
	end
	return nil
end


function skeletonState.pickImage(skel, x, y)
	local layeredCheck = false
	if skeletonState.selectedElement and skeletonState.selectedElement.tp == "img" then
		-- Hold ALT to select bone below current one
		if states.getKeyDown("lalt") then
			layeredCheck = true
		else
			-- Pick selected one first
			if skeletonState.pickSingleImage(skeletonState.selectedElement, x, y) then return skeletonState.selectedElement end
		end
	end
	for id,element in pairs(skel.elementMap) do
		if element.tp == "img" then
			if not layeredCheck or element.idNum > skeletonState.selectedElement.idNum then
				if skeletonState.pickSingleImage(element, x, y) then return element end
			end
		end
	end
	return nil
end

	function skeletonState.pickSingleImage(img, x, y)		
		local image = img.object
		if skeletonState.pointInRotatedBox(x, y, img.__x, img.__y, image:getWidth()*img.__scX, image:getHeight()*img.__scY, img.__angle) then
			return true
		end
		return false
	end