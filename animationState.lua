
do




animationState = {
	skel = nil,
	pose = nil,
	zoomLevel = 0,
	zoom = 1.0,
	showTreeview = false,
	animation = nil,
	durationString = "",
	mode = 1,
	modes = {bones = 1, images = 2},
	camX = 0,
	camY = 0,
	hoveredElement = nil,
	selectedElement = nil,
	boundingKeyframeMode = false,
	helpText = {"V", "Show full Character",   "TAB", "Bone/Img Mode",   "CTRL", "Camera",   "MWheel", "Rotate Image", "Alt/X/Y/R+Wheel", "        Image Scale",
		"CTRL","Bone Length",   "Shift/R","Bone Scale",   "Alt+Click", "Select Below",   "F1","First->Last",   "F2","First<-Last",   "T","Image Transparency",
		"Shift+Drag","Move Keyframe",  "C+Click","Copy Current Keyframe",   "Space","Play/Pause",   "CTRL","Unsnap Keyframes"},
	-- Timeline related
	timeline = {
		playing = false,
		t = 0.0,
		offset = 0.0,
		starttime = love.timer.getTime(),
		x1 = 0,
		w = 1,
	},
	storeX = {},
	-- Keyframe related
	createDefaultKeyframes = false,
	keyframes = {}, -- list of keyframe lists - each list contains actual keyframes for all bones and a single timestamp
	currentKeyframe = nil,
}


local state = animationState


function animationState.load()

end


function animationState.checkEnter()
	return animationsState.playAni ~= nil
end

function animationState.enter()
	state.skel = animationsState.skel
	state.pose = animator.newPose(animationState.skel, "animationPose")
	state.animation = animationsState.playAni
	state.setDuration()
	-- Add two meta keyframes when animation is empty
	if state.createDefaultKeyframes then
		state.addKeyframe(0.0, true)
		state.addKeyframe(1.0, true)
	else
		-- Read existing keyframes, traverse over bones/images
		for id,keyframe in pairs(state.animation.keyframes) do
			-- Check all keyframes for each bone
			for i = 1,#keyframe do
				local kf = keyframe[i]
				-- Add
				state.addKeyframe(kf.p, kf)
			end
		end
	end
end

function animationState.setDuration(dur)
	-- Change Duration
	if dur then
		if dur < 0.1 then dur = 0.1 end
		state.animation.duration = dur
	end
	-- Update String
	local secs = math.floor(state.animation.duration)
	local msecs = math.floor(100*(state.animation.duration - secs))
	state.durationString = secs .. "." .. ((msecs < 10) and "0" .. msecs or msecs)
end


function animationState.keypressed(key)
	if key == "tab" then
		-- Switch Mode
		state.mode = 3 - state.mode
	elseif key == "f1" then
		-- Copy Left keyframe to right one
		questionDialog("Overwrite right keyframe with left one?", function()
			animationState.copyKeyframe(1, #state.keyframes)
		end, nil)
	elseif key == "f2" then
		-- Copy right keyframe to left one
		questionDialog("Overwrite left keyframe with right one?", function()
			animationState.copyKeyframe(#state.keyframes, 1)
		end, nil)
	elseif key == "delete" then
		if animationState.currentKeyframe then
			local toDelete = animationState.currentKeyframe
			questionDialog("Delete selected keyframe?", function()
				animationState.deleteKeyframe(toDelete) 
			end, nil)
		end
	elseif key == " " then
		-- Space to start/stop animation looping
		if state.timeline.playing then
			state.timeline.playing = false
		else
			state.timeline.playing = true
			state.timeline.starttime = love.timer.getTime()
			state.timeline.offset = state.timeline.t
			state.currentKeyframe = nil
		end			
	end
end


function animationState.update()
	-- Mousewheel
	local ctrl = states.getKeyDown("lctrl")
	if states.mouse.mz ~= 0 then
		if ctrl then
			-- Zoom
			state.zoomLevel = clamp(state.zoomLevel + states.mouse.mz, -32, 32)
			state.zoom = math.pow(1.1, state.zoomLevel)
		else
			-- Transform Image
			if state.currentKeyframe then
				if state.mode == state.modes.images then
					if state.selectedElement and state.selectedElement.tp == "img" then 
						local pose = state.skel.defaultPose
						local img = state.selectedElement
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
							state.applyToKeyframe(img, nil, nil, nil, xsc, ysc)
						else
							if states.getKeyDown("t") then
								-- Transparency
								local dA = states.mouse.mz * (states.getKeyDown("lshift") and 1/256.0 or 1/16.0)
								local oldValue = pose.state[state.selectedElement.id][4] or 1.0
								local newAlpha = clamp(oldValue + dA, 0.0, 1.0)
								print("Changing transparency from " .. oldValue .. " to " .. newAlpha)
								animator.setPoseImage(pose, img, nil, nil, nil, nil, nil, newAlpha)
								state.applyToKeyframe(img, nil, nil, nil, nil, nil, newAlpha)
							else
								-- Rotate Image
								local dA = states.mouse.mz * (states.getKeyDown("lshift") and 1.0 or 12.0)
								local newAngle = state.selectedElement.angle + dA*math.pi/180.0 --wrapAngle(state.selectedElement.angle + dA*math.pi/180.0)
								animator.setPoseImage(pose, img, nil, nil, newAngle)
								state.applyToKeyframe(img, nil, nil, newAngle)
							end
						end
					end
				end
			end
		end
	end
	-- Mouse Selection

	state.previousKeyframe = nil
	local hover, selTrg
	if state.currentKeyframe then
		if state.mode == state.modes.bones then
			-- Bone Selection
			hover, selTrg = skeletonState.pickBone(state.skel, states.mouse.skelx, states.mouse.skely)
		else
			-- Image Selection
			hover = skeletonState.pickImage(state.skel, states.mouse.skelx, states.mouse.skely)
		end
		-- Apply
		if hover then
			state.hoveredElement = hover
			if states.mouse.leftclick == 2 then
				state.selectElement(hover)
			end
		else
			if states.mouse.leftclick == 2 then
				-- Deselect, but only if mouse not on GUI .. evil evil hack
				if states.mouse.x > 220 and states.mouse.x < states.windowW - 220 then
					if states.mouse.y < states.windowH - 200 then
						state.selectElement(nil)
					else
						state.previousKeyframe = state.currentKeyframe
						state.currentKeyframe = nil
					end
				end
			end
		end
	end

	-- Drag & Drop
	if state.currentKeyframe and not ctrl then
		if states.mouse.dragJustStarted then
			-- Drag Bone or Image
			if hover then
				if state.mode == state.modes.bones then
					-- Bone Editing
					if selTrg == 1 then states.mouse.dragCallback = function(dx,dy) skeletonState.moveBone(hover, dx, dy, true, false) end end
					if selTrg == 2 then states.mouse.dragCallback = function(dx,dy) skeletonState.moveBone(hover, dx, dy, false, true) end end
					if selTrg == 3 then states.mouse.dragCallback = function(dx,dy) skeletonState.moveBone(hover, dx, dy, true, true) end end
					states.mouse.dropCallback = nil
					state.selectElement(hover)
				else
					-- Image Editing
					states.mouse.dragCallback = function(dx,dy) skeletonState.moveImage(hover, dx, dy) end
					states.mouse.dropCallback = nil
					state.selectElement(hover)
				end
			end
		end
	end


	if ctrl and states.mouse.dragJustStarted then
		-- Move Camera
		states.mouse.dragCallback = function(dx,dy) 
			state.camX = state.camX - states.mouse.mx/state.zoom 
			state.camY = state.camY - states.mouse.my/state.zoom 
		end
		states.mouse.dropCallback = nil
	end

	-- Clamp Camera Position
	state.camX = clamp(state.camX, -8192, 8192)
	state.camY = clamp(state.camY, -8192, 8192)


	-- Update Timeline
	if state.timeline.playing then
		local progress = state.timeline.offset + (love.timer.getTime() - state.timeline.starttime) / state.animation.duration
		state.setTimeline(progress - math.floor(progress))
	end

end


	function animationState.selectElement(e)
		if state.skel then
			if e then print("Selecting Element " .. e.name) else print("Deselecting Element") end
			state.selectedElement = e
			state.skel.rootChild.childs[1].__treeview_selected = e
		end
	end





function animationState.draw()
	--love.graphics.setColor(editor.backColor)
	--love.graphics.rectangle("fill", 0, 0, states.windowW, states.windowH)
	drawGrid(state.camX, state.camY, state.zoom)
	states.helpText(state.helpText, states.windowH-260)

	-- Title
	states.drawTitle("Animation Editing")

	-- Skeleton
	local skel = state.skel
	local sx = states.windowW*0.5 - state.camX*state.zoom
	local sy = states.windowH*0.5 - state.camY*state.zoom
	--animator.drawPose(state.pose, states.windowW*0.5, states.windowH*0.5, 0.0, state.zoom, state.zoom, 1.0, states.getKeyDown("d"))
	if states.getKeyDown("v") then
		-- Press V to see character fully
		animator.drawPose(state.pose, sx, sy, 0.0, state.zoom, state.zoom, 1.0, states.getKeyDown("d"))			
	else
		if state.mode == state.modes.bones then
			-- Bone Editing
			animator.drawPose(state.pose, sx, sy, 0.0, state.zoom, state.zoom, 0.3, false)
			animator.reapplyPreviousPoseTransformation()
			animator.drawDebugSkeleton(skel)
			animator.drawDebugCross(skel.rootChild.childs[1].__x, skel.rootChild.childs[1].__y)
			animator.undoPoseTransformation()
		else
			-- Image Editing
			animator.drawBoundingBoxes = true
			animator.drawPose(state.pose, sx, sy, 0.0, state.zoom, state.zoom, 1.0, false)
			animator.reapplyPreviousPoseTransformation()
			animator.drawDebugCross(skel.rootChild.childs[1].__x, skel.rootChild.childs[1].__y)
			animator.undoPoseTransformation()
			animator.drawBoundingBoxes = false
		end
	end
	states.registerTransformation()

	-- Bones of Current Skeleton
	if state.showTreeview then
		local sel, hover = treeview(32,1,220,states.windowH-222, state.skel.rootChild.childs[1], 
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
			function(c,p) end
		)
		if hover then
			state.hoveredElement = hover
			-- Draw Bone
			if hover.tp == "bone" then
				animator.reapplyPreviousPoseTransformation()
				animator.drawSingleDebugBone(hover)
				animator.drawDebugBoneImages(hover)
				animator.undoPoseTransformation()
			end
		end
		state.selectedElement = sel
		if button(142,states.windowH-210, 218,20, "Hide Treeview") then
			state.showTreeview = false
		end
	else
		if button(142,10,218,20, "Show Treeview") then 
			state.showTreeview = true
		end
	end

	-- Highlight whatever is hovered
	state.highlight(state.hoveredElement)
	state.highlight(state.selectedElement)


	-- Global Animation Properties
	if button(states.windowW - 120, 13, 240, 25, "Duration: " .. state.durationString .. "s") then
		numberInput("Duration in Seconds:", state.durationString, function(dur) animationState.setDuration(dur) end)
	end

	-- Save Animation
	if button(360,12,100,25, "Save") then
		animationsState.saveAnimation(state.animation)
	end

	-- Make sure no element stays hovered
	state.hoveredElement = nil




	-- Selected Keyframe Properties



	-- Timeline
	-- Container
	local h = 200
	local y1 = states.windowH-h
	love.graphics.setColor(80,80,80,255)
	love.graphics.rectangle("fill", 0, y1, states.windowW, h)
	love.graphics.setColor(0,0,0,255)
	love.graphics.rectangle("fill", 0, y1, states.windowW, 2)
	-- Actual Timeline
	local x1 = 180
	state.timeline.x1 = x1
	local x2 = states.windowW-260
	local tw = x2 - x1
	state.timeline.w = tw
	love.graphics.rectangle("fill", x1-3, y1, 2, h)
	love.graphics.rectangle("fill", x2+1, y1, 2, h)
	-- Time Bar
	local ty = y1 + 16
	love.graphics.rectangle("fill", x1, ty, tw, 1)
	-- 50 small markers
	for i = 1,99 do
		local p = i/100.0
		local x = x1 + tw*p
		if i % 5 == 0 then
			love.graphics.setColor(0,0,0,128)
		else
			love.graphics.setColor(0,0,0,64)
		end
		love.graphics.rectangle("fill",x,ty,1,h)		
	end
	-- Markers
	love.graphics.setColor(0,0,0,220)
	for i = 1,3 do
		local p = i/4.0
		local x = x1 + tw*p
		love.graphics.rectangle("fill",x,y1,1,h)
		state.storeX[i] = x
	end
	-- Time Captions
	love.graphics.setColor(0,0,0,255)
	love.graphics.print("0.0", x1, y1+2)
	love.graphics.print("0.25", state.storeX[1]-9, y1+2)
	love.graphics.print("0.5", state.storeX[2]-9, y1+2)
	love.graphics.print("0.75", state.storeX[3]-9, y1+2)
	love.graphics.print("1.0", x2-24, y1+2)
	-- Current Time
	local curx = x1 + tw*state.timeline.t
	love.graphics.setColor(0,0,255,180)
	love.graphics.rectangle("fill", curx-1, ty+1, 2, h)
	-- Hover Line
	if states.mouse.y >= y1 and states.mouse.x >= x1 and states.mouse.x <= x2 then		
		love.graphics.setColor(0,0,255,64)
		love.graphics.rectangle("fill", states.mouse.x-1, ty+1, 2, h)
		if states.mouse.leftclick > 0 then
			local p = (states.mouse.x - x1)/tw
			if states.mouse.leftclick == 2 and states.getKeyDown("c") and state.previousKeyframe then
				-- Copy current keyframe
				local index = 0
				for i = 1,#state.keyframes do if state.keyframes[i] == state.previousKeyframe then index = i; break; end end
				if index > 0 then 
					local newkf = state.addKeyframe(p)
					local newindex = 0
					for i = 1,#state.keyframes do if state.keyframes[i] == newkf then newindex = i; break; end end
					if newindex > 0 then 
						state.copyKeyframe(index, newindex)
					end
				end
			end
			state.timeline.playing = false
			state.setTimeline(p)
		end
	end

	-- Draw Keyframes
	local kx
	local ky = ty+5
	for k = 1,#state.keyframes do
		kx = x1 + tw*state.keyframes[k].t
		state.drawKeyframe(k, kx, ky)
	end


	-- Buttons
	local bx = x1/2
	local by = y1 + 40
	if state.timeline.playing then 
		if button(bx,by,100,25, "Pause") then
			state.timeline.playing = false
		end
	else
		if button(bx,by,100,25, "Play") then
			state.timeline.playing = true
			state.timeline.starttime = love.timer.getTime()
			state.timeline.offset = state.timeline.t
			state.currentKeyframe = nil
		end
		-- Create new Keyframe
		if not state.currentKeyframe then
			if button(bx, by+60, 100, 25, "Add Keyframe") then
				local kf = state.addKeyframe(state.timeline.t, false)
				state.currentKeyframe = kf
			end
		else
			if button(bx, by+92, 100, 25, "Delete Keyframe") then
				questionDialog("Really delete keyframe?", function()
					state.deleteKeyframe()
				end, nil)
			end
		end
	end


	-- Interpolation
	local ix1 = x2+2
	local iy1 = y1
	if state.selectedElement and state.currentKeyframe then
		love.graphics.setColor(0,0,0,255)
		love.graphics.print("Interpolation at Keyframe for " .. state.selectedElement.name, ix1+5, iy1+5)
		-- Single value or multiple?
		local kf = nil
		for i = 1,#state.currentKeyframe.keyframes do
			if state.currentKeyframe.keyframes[i].element == state.selectedElement then
				kf = state.currentKeyframe.keyframes[i]
				break
			end
		end
		-- Found keyframe?
		if kf then
			local x = ix1 + 12
			local y = iy1 + 36
			local ystp = 24
			if kf.interpolation[5] then
				-- Interpolation per Attribute
				state.interpolationButton(x, y, "Position:", kf.interpolation[1], function(i) kf.interpolation[1] = i; kf.interpolation[2] = i end); y = y + ystp
				state.interpolationButton(x, y, "Angle:", kf.interpolation[3], function(i) kf.interpolation[3] = i end); y = y + ystp
				state.interpolationButton(x, y, "Scale:", kf.interpolation[5], function(i) kf.interpolation[5] = i; kf.interpolation[6] = i end); y = y + ystp
				state.interpolationButton(x, y, "Alpha:", kf.interpolation[4], function(i) kf.interpolation[4] = i end); y = y + ystp
				if button(states.windowW-24, states.windowH-24, 32,20,"-") then 
					questionDialog("Are you sure? Interpolations will be lost", function() kf.interpolation = kf.interpolation[1] end, nil)
				end
			else
				-- Single interpolation for all Attributes
				state.interpolationButton(x, y, "Interpolation:", kf.interpolation, function(interp) kf.interpolation = interp end)
				if button(states.windowW-24, states.windowH-24, 32,20,"+") then 
					local i = kf.interpolation
					kf.interpolation = {i,i,i,i,i,i}
				end
			end
		end
		-- Custom Curve
		if animationState.customCurveOpen then
			local ex = ix1
			local ew = states.windowW - ex
			local eh = ew
			local ey = iy1 - eh - 20
			-- Update Curve Editor
			curveEditor.position[1] = ex
			curveEditor.position[2] = ey
			curveEditor.size[1] = ew
			curveEditor.size[2] = eh
			-- Editor
			curveEditor.draw()
			state.customCurve[1] = curveEditor.startMarker[1]
			state.customCurve[2] = curveEditor.startMarker[2]
			state.customCurve[3] = curveEditor.endMarker[1]
			state.customCurve[4] = curveEditor.endMarker[2]
			-- Apply
			if button(ex+0.5*ew, ey+eh+10, ew, 20, "\\ Apply /") then
				animationState.customCurveApplyFunction(animationState.customCurve)
				animationState.customCurveOpen = false
			end
		end
	else
		-- close curve editor when different bone or keyframe is selected
		if (state.selectedElement and state.selectedElement ~= state.customCurveTargetElement) or (state.currentKeyframe and state.currentKeyframe ~= state.customCurveTargetKeyframe) then
			state.closeCustomInterpolation()
		end
	end




end




function animationState.interpolationButton(x, y, caption, interp, applyFunction)
	-- Caption
	love.graphics.setColor(255,255,255,180)
	love.graphics.print(caption, x, y)
	-- Button
	local s = (type(interp) == "string") and interp or "Custom"
	if button(x+160,y+10,100,20,s) then
		local buttons = {}
		local rows = 0
		local function addInterp(name)
			rows = rows + 1
			table.insert(buttons, {caption=name, callback=function() applyFunction(name) end, row = rows})
		end
		addInterp("linear")
		addInterp("step")
		addInterp("floor")
		addInterp("cos")
		addInterp("cos2")
		addInterp("sqr")
		addInterp("sqrt")
		addInterp("sphere")
		addInterp("invsphere")
		table.insert(buttons, {caption="Custom", callback=function() animationState.openCustomInterpolation(interp, applyFunction) end, row = rows+1})
		createDialog("Old interpolation:" .. s, buttons)
	end
end

animationState.customCurveOpen = false
function animationState.openCustomInterpolation(oldValue, applyFunction)
	animationState.customCurveOpen = true
	if oldValue[4] and not oldValue[5] then
		animationState.customCurve = oldValue
	else
		animationState.customCurve = {0.3,0.3, 0.7,0.7}
	end
	animationState.customCurveApplyFunction = applyFunction
	curveEditor.startMarker[1] = state.customCurve[1]
	curveEditor.startMarker[2] = state.customCurve[2]
	curveEditor.endMarker[1] = state.customCurve[3]
	curveEditor.endMarker[2] = state.customCurve[4]
	animationState.customCurveTargetElement = state.selectedElement
	animationState.customCurveTargetKeyframe = state.currentKeyframe
end

function animationState.closeCustomInterpolation()
	if state.customCurveOpen then
		state.customCurveOpen = false
		curveEditor.position = {states.windowW+1000,0}
	end
end


function animationState.setTimeline(t)
	if t then
		state.timeline.t = t
	end
	-- Update Skeleton
	animator.applyAnimation(state.pose, state.animation, state.timeline.t)	
end


function state.drawKeyframe(num, sx, sy)
	local obj = state.keyframes[num]
	-- Bounds
	local w = 12
	local h = 32
	local x1 = sx - w/2
	local y1 = sy
	-- Interaction
	local hover = false
	if states.mouse.x >= x1 and states.mouse.x <= x1+w then
		if states.mouse.y >= y1 and states.mouse.y <= y1+h then
			hover = true
			if states.mouse.leftclick == 2 then
				state.currentKeyframe = state.keyframes[num]
				state.setTimeline(state.currentKeyframe.t)
				-- Press Shift to move keyframe
				local trgKeyframe = state.currentKeyframe
				if states.getKeyDown("lshift") then
					state.keyframeDragOffX = sx - states.mouse.x
					states.mouse.dragCallback = function() 
						local t = (states.mouse.x + state.keyframeDragOffX - state.timeline.x1)/state.timeline.w
						if not states.getKeyDown("lctrl") then t = math.floor(t*100)/100 end
						state.setKeyframe(trgKeyframe, t)
						state.setTimeline(trgKeyframe.t)
					end
					states.mouse.dropCallback = function() state.currentKeyframe = state.keyframes[num]; state.setTimeline(trgKeyframe.t) end
				else
					states.mouse.dragCallback = function() state.setTimeline(trgKeyframe.t) end
					states.mouse.dropCallback = states.mouse.dragCallback
				end
			end
		end
	end
	-- Draw
	love.graphics.setColor(255,255,255,255)
	love.graphics.rectangle("fill", x1, y1, w, h)
	if obj == state.currentKeyframe then
		love.graphics.setColor(255, hover and 255 or 180, 0, 255)
	else
		love.graphics.setColor(hover and 255 or 128, 0, 0, 255)
	end
	love.graphics.rectangle("fill", x1+1, y1+1, w-2, h-2)
end

function state.setKeyframe(metakeyframe, t)
	-- Allowed? Make sure outer keyframes stay where they are
	if metakeyframe.t > 0 and metakeyframe.t < 1 then
		t = clamp(t, 0.02, 0.98)
		metakeyframe.t = t
		-- Apply actual keyframes
		for k = 1,#metakeyframe.keyframes do
			metakeyframe.keyframes[k].p = t			
    		animator.sortKeyframes(state.animation, metakeyframe.keyframes[k].elementID)
		end
	end
end


function animationState.highlight(e) 
	skeletonState.highlight(e)
end


function animationState.addKeyframe(t, forAllBones)
	t = clamp(t,0,1)
	-- make sure such a keyframe doesn't exist yet
	local found = false
	for k = 1,#state.keyframes do
		if state.keyframes[k].t == t then 
			found = k
			break
		end
	end
	-- create meta keyframe
	local entry
	if not found then
		entry = {
			t = t,
			keyframes = {}
		}
		-- add to state's list of all meta-keyframes
		table.insert(state.keyframes, entry)
		table.sort(state.keyframes, function(a,b) return a.t < b.t end)
	else
		entry = state.keyframes[found]
	end
	-- Usually just for two outer keyframes, all bones and images are set, apply default values of skeleton's default pose
	if forAllBones then
		if forAllBones == true then
			for id,element in pairs(state.skel.elementMap) do
				local st = state.skel.defaultPose.state[id]
				local keyframe = animator.newKeyframe(state.animation, t, element, "linear", st[1], st[2], st[3], st[5], st[6], st[4])
				table.insert(entry.keyframes, keyframe)
			end
		else
			-- Add single keyframe to list
			table.insert(entry.keyframes, forAllBones)
		end
	end
	return entry
end

function state.deleteKeyframe(keyframe)
	keyframe = keyframe or state.currentKeyframe
	if keyframe then
		-- make sure not to delete outer keyframes
		if keyframe.t > 0.0 and keyframe.t < 1.0 then
			-- Delete animation keyframes of meta keyframe
			for k = 1,#keyframe.keyframes do
				animator.deleteKeyframe(keyframe.keyframes[k])
			end
			-- Delete meta keyframe
			for i = 1,#state.keyframes do
				if state.keyframes[i] == keyframe then
					table.remove(state.keyframes, i)
					break
				end
			end
			-- Deselect
			if keyframe == state.currentKeyframe then state.currentKeyframe = nil end
		end
	end
end


function animationState.copyKeyframe(src, trg)
	print("Copying keyframe from " .. state.keyframes[src].t .. " to " .. state.keyframes[trg].t .. " - subframes: " .. #state.keyframes[trg].keyframes)
	-- Copy existing keyframes from src list to trg
	for k = 1,#state.keyframes[src].keyframes do
		print("  Copying " .. k .. "/" .. #state.keyframes[src] .. " for element " .. state.keyframes[src].keyframes[k].element.name)
		-- cycle through all real keyframes of metakeyframe
		local srcKf = state.keyframes[src].keyframes[k]
		local trgKf = state.keyframes[trg].keyframes[k]
		if not trgKf or trgKf.elementID ~= srcKf.elementID then
			-- find according keyframe
			trgKf = nil
			for j = 1,#state.keyframes[trg].keyframes do
				if state.keyframes[trg].keyframes[j].elementID == srcKf.elementID then trgKf = state.keyframes[trg].keyframes[j]; break end
			end
		end
		if trgKf then
			-- matching source and target keyframes found -> apply values
			for i = 1,6 do
				trgKf[i] = srcKf[i]
			end
			trgKf.x = trgKf[1]
			trgKf.y = trgKf[2]
			trgKf.angle = trgKf[3]
			trgKf.alpha = trgKf[4]
			trgKf.xscale = trgKf[5]
			trgKf.yscale = trgKf[6]
		else
			-- no target keyframe found for source keyframe -> create
			trgKf = animator.newKeyframe(state.animation, state.keyframes[trg].t, srcKf.element, "linear", srcKf[1], srcKf[2], srcKf[3], srcKf[5], srcKf[6], srcKf[4])
		end
	end
end



function state.applyToKeyframe(element, x, y, angle, xsc, ysc, alpha, metakeyframe)
	metakeyframe = metakeyframe or state.currentKeyframe
	if metakeyframe then 
		-- find actual keyframe for element
		local kf = nil
		for k = 1,#metakeyframe.keyframes do
			if metakeyframe.keyframes[k].element == element then kf = metakeyframe.keyframes[k]; break; end 
		end
		if kf then
			-- keyframe found, apply values
			if x then kf[1] = x; kf.x = x end
			if y then kf[2] = y; kf.y = y end
			if angle then kf[3] = angle; kf.angle = angle end
			if xsc then kf[5] = xsc; kf.xscale = xsc end
			if ysc then kf[6] = ysc; kf.yscale = ysc end
			if alpha then kf[4] = alpha; kf.alpha = alpha end
		else
			-- no keyframe found, create one
			kf = animator.newKeyframe(state.animation, metakeyframe.t, element, "linear", x, y, angle, xsc, ysc, alpha)
			table.insert(metakeyframe.keyframes, kf)
		end
		state.setTimeline()
	end
end



end