


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
}


function skeletonState.load()
	-- Load Skeletons
end


function skeletonState.enter()
	skeletonState.skeletons[1] = test.skel
	--skeletonState.skeletons[1].defaultPose = animator.newPose(skeletonState.skeletons[1])
	skeletonState.mode = skeletonState.modes.bones
end

function skeletonState.keypressed(key)
	if key == "tab" then
		-- Switch Mode
		skeletonState.mode = 3 - skeletonState.mode
	end
end

function skeletonState.update()

	-- Zoom
	if states.mouse.mz ~= 0 then
		skeletonState.zoomLevel = clamp(skeletonState.zoomLevel + states.mouse.mz, -32, 32)
		skeletonState.zoom = math.pow(1.1, skeletonState.zoomLevel)
	end

	-- Mouse Selection
	local hover, selTrg
	if skeletonState.currentSkeleton then
		if skeletonState.mode == skeletonState.modes.bones then
			-- Bone Selection
			hover, selTrg = skeletonState.pickBone(skeletonState.currentSkeleton, states.mouse.skelx, states.mouse.skely)
			if hover then
				skeletonState.hoveredElement = hover
			end
		else
			-- Image Selection
			-- ...
		end
	end

	-- Drag & Drop
	if states.mouse.dragJustStarted then
		if hover then
			if skeletonState.mode == skeletonState.modes.bones then
				-- Bone Editing
				if selTrg == 1 then states.mouse.dragCallback = function(dx,dy) skeletonState.moveBone(hover, dx, dy, true, false) end end
				if selTrg == 2 then states.mouse.dragCallback = function(dx,dy) skeletonState.moveBone(hover, dx, dy, false, true) end end
				if selTrg == 3 then states.mouse.dragCallback = function(dx,dy) skeletonState.moveBone(hover, dx, dy, true, true) end end
				states.mouse.dropCallback = nil
			else
				-- Image Editing
			end
		end
	end


end

	function skeletonState.moveBone(bone, dx, dy, moveStartPos, moveEndPos)
		local pose = skeletonState.currentSkeleton.defaultPose
		-- Transform dx,dy to make sure bone moves relative to screen
		-- Rotate by -bone.angle 
		local ang = -bone.parent.__angle
		local s = math.sin(ang)
		local c = math.cos(ang)
		local newdx = c*dx - s*dy
		local newdy = -s*dx - c*dy
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
			if states.getKeyDown("lshift") then newScale = math.sqrt(difx*difx + dify*dify)/bone.length end
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


function skeletonState.draw()

	-- Back
	love.graphics.setColor(editor.backColor)
	love.graphics.rectangle("fill", 0, 0, states.windowW, states.windowH)

	-- Selected Skeleton
	local skel = skeletonState.currentSkeleton
	if skel then
		-- Mode
		if skeletonState.mode == skeletonState.modes.bones then
			-- Bone Editing
			animator.drawPose(skel.defaultPose, states.windowW*0.5, states.windowH*0.5, 0.0, skeletonState.zoom, skeletonState.zoom, 0.3, false)
			animator.reapplyPreviousPoseTransformation()
			animator.drawDebugSkeleton(skel)
			animator.undoPoseTransformation()
		else
			-- Image Editing
			animator.drawPose(skel.defaultPose, states.windowW*0.5, states.windowH*0.5, 0.0, skeletonState.zoom, skeletonState.zoom, 1.0, states.getKeyDown("d"))
		end
		states.registerTransformation()
	end

	-- Title
	local title = "Skeletons"
	if skel then
		title = title .. ((skeletonState.mode == skeletonState.modes.bones) and " - Bones" or " - Images")
	end
	states.drawTitle(title)

	-- List of Skeletons
	local sel, hover = listview(1, 1, 220, 300, skeletonState.skeletons, function(skel) return skel.name end )
	if sel then
		-- Select Skeleton
		skeletonState.currentID = sel
		skeletonState.currentSkeleton = skeletonState.skeletons[sel]
	end

	-- Bones of Current Skeleton
	if skel then
		local sel, hover = treeview(1,302,220,900, skel.rootChild.childs[1], 
			function(e) return e.name end,
			function(e) return (e.childs and e.childs[1]) or (e.images and e.images[1]) end,
			function(e) 
				if e.tp == "img" then
					for i =1,#e.bone.images do
						if e.bone.images[i] == e then return e.bone.images[i+1] end
					end
				else
					for i=1,#e.parent.childs-1 do
						if e.parent.childs[i] == e then return e.parent.childs[i+1] end
					end
					return e.parent.images[1]
				end
				return nil
			end,
			function(c,p) animator.reorderBones(c, p) end
		)
		if hover then
			skeletonState.hoveredElement = hover
		end
		if sel then 
			-- Select Bone
		end

		-- Highlight whatever is hovered
		if skeletonState.hoveredElement then
			local hover = skeletonState.hoveredElement
			-- Draw Bone
			if hover.tp == "bone" then
				animator.reapplyPreviousPoseTransformation()
				animator.drawSingleDebugBone(hover)
				--animator.drawDebugBoneImages(hover)
				animator.undoPoseTransformation()
				for i = 1,#hover.images do
					hover.images[i].__highlight = 1 
				end
				hover.__highlight = 1
			else
				hover.__highlight = 1
			end			
		end

		-- Images of this Skeleton
		listview(states.windowW-220,1,220,states.windowH, skel.imageList)
	end


	-- Make sure no element stays hovered
	skeletonState.hoveredElement = nil
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