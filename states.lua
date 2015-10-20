
states = {
	current = 1,
	-- Three States
	skeleton = 1,
	animations = 2,
	animation = 3,
	objects = {nil, nil, nil},
	-- Transition
	transitionActive = false,
	transitionFrom = 0,
	transitionTo = 0,
	transitionProgress = 0.0,
	transitionStarttime = 0,
	transitionEndtime = 0,
	transitionDuration = 1,
	-- Mouse interaction
	inactiveMouse = {active = false, x = -9999, y = -9999, z = 0, mx = 0, my = 0, mz = 0, leftclick = 0, rightclick = 0, skelx = -9999, skely = -9999, dragging = false, dragJustStarted = false},
	activeMouse = {
		active = true, 
		x = 0, y = 0, z = 0, mx = 0, my = 0, mz = 0, 
		leftclick = 0, rightclick = 0, 
		skelx = 0, skely = 0,
		dragging = false, dragFromX = 0, dragFromY = 0, dragDifX = 0, dragDifY = 0, dragJustStarted = false, dragCallback = nil, dropCallback = nil,
	},
	mouse = inactiveMouse,
	transformation = {0,0, 0, 1,1},
	-- Misc
	scissorX1 = 0,
	scissorX2 = love.window.getWidth(),
	windowW = 1,
	windowH = 1,
}


function states.load()
	states.mouse = states.inactiveMouse
	for i = 1,#states.objects do states.objects[i].load() end
	states.current = states.skeleton
	states.objects[1] = skeletonState
	states.objects[2] = animationsState
	states.objects[3] = animationState
	states.objects[states.current].enter()
end




function states.transition(trg)
	-- Valid target state?
	if (trg == states.current-1 or trg == states.current+1) and trg >= 1 and trg <= 3 then
		if states.objects[trg].checkEnter then if not states.objects[trg].checkEnter() then return false end end
		states.transitionActive = true
		states.transitionFrom = states.current
		states.transitionTo = trg
		states.current = trg
		states.transitionProgress = 0.0
		states.transitionStarttime = love.timer.getTime()
		states.transitionDuration = 1.0
		states.transitionEndtime = states.transitionStarttime + states.transitionDuration
		states.objects[trg].enter()
		return true
	end
	return false
end

function states.mousepressed(x, y, btn)
	if btn == "wd" then 
		states.mouse.z = states.mouse.z - 1
		states.mouse.mz = -1
	elseif btn == "wu" then
		states.mouse.z = states.mouse.z + 1
		states.mouse.mz = 1
	end
end

function states.keypressed(key)
	-- Propagate to current state
	if states.objects[states.current].keypressed then states.objects[states.current].keypressed(key) end
end




function states.update()
	-- Misc
	states.windowW = love.window.getWidth()
	states.windowH = love.window.getHeight()
	-- Mouse
	local oldx, oldy = states.activeMouse.x, states.activeMouse.y
	states.activeMouse.x, states.activeMouse.y = love.mouse.getPosition()
	states.activeMouse.mx, states.activeMouse.my = states.activeMouse.x - oldx, states.activeMouse.y - oldy
	states.activeMouse.leftclick = states.getKeyChange(states.activeMouse.leftclick, love.mouse.isDown("l"))
	states.activeMouse.rightclick = states.getKeyChange(states.activeMouse.rightclick, love.mouse.isDown("r"))
	-- Mouse Coordinates in Skeleton Space (so far neglecting angle, as it's always 0.0)
	states.activeMouse.skelx = (states.activeMouse.x - states.transformation[1]) / states.transformation[4]
	states.activeMouse.skely = (states.activeMouse.y - states.transformation[2]) / states.transformation[5]
	-- Dragging
	states.activeMouse.dragJustStarted = false
	if states.mouse.active then
		if states.activeMouse.leftclick == 2 then
			-- start dragging
			states.activeMouse.dragging = true
			states.activeMouse.dragJustStarted = true
			states.activeMouse.dragFromX = states.activeMouse.skelx
			states.activeMouse.dragFromY = states.activeMouse.skely
			states.activeMouse.dragDifX = 0
			states.activeMouse.dragDifY = 0
			states.activeMouse.dragDifDX = 0
			states.activeMouse.dragDifDY = 0
		else
			if states.activeMouse.leftclick == 1 then
				-- currently dragging
				local oldx = states.activeMouse.dragDifX
				local oldy = states.activeMouse.dragDifY
				states.activeMouse.dragDifX = states.activeMouse.skelx - states.activeMouse.dragFromX
				states.activeMouse.dragDifY = states.activeMouse.skely - states.activeMouse.dragFromY
				states.activeMouse.dragDifDX = states.activeMouse.dragDifX - oldx
				states.activeMouse.dragDifDY = states.activeMouse.dragDifY - oldy
				if states.activeMouse.dragCallback then states.activeMouse.dragCallback(states.activeMouse.dragDifDX, states.activeMouse.dragDifDY) end
			else
				-- stop dragging
				states.activeMouse.dragging = false
				if states.activeMouse.dropCallback then states.activeMouse.dropCallback(states.activeMouse.dragDifX, states.activeMouse.dragDifY) end
				states.activeMouse.dragCallback = nil
				states.activeMouse.dropCallback = nil
			end
		end
	else
		states.activeMouse.dragging = false
		states.activeMouse.dragCallback = nil
		states.activeMouse.dropCallback = nil
	end
	-- Transition?
	if states.transitionActive then
		-- Handle Transition
		states.mouse = states.inactiveMouse
		states.transitionProgress = (love.timer.getTime() - states.transitionStarttime) / states.transitionDuration
		if states.transitionProgress >= 1.0 then
			states.transitionActive = false
		end
	else
		-- No Transition -> let states update
		if textInputHandler.active or dialogHandler.active then
			states.mouse = states.inactiveMouse
		else
			states.mouse = states.activeMouse
		end
		states.objects[states.current].update()
	end
	states.mouse.mz = 0
end




function states.draw()
	-- Draw Transition or simple State
	if states.transitionActive then
		-- Draw both States with scissor
		local p
		local leftState
		local rightState
		if states.transitionTo > states.transitionFrom then
			p = 1.0 - states.transitionProgress
			leftState = states.transitionFrom
			rightState = states.transitionTo
		else
			p = states.transitionProgress
			leftState = states.transitionTo
			rightState = states.transitionFrom
		end
		-- Draw Left and Right State
		local seamX = love.window.getWidth() * (0.5 - 0.5*math.cos(math.pi*p)) -- position of slider, cos interpolated for neat animation
		love.graphics.setScissor(0,0,seamX,love.window.getHeight()); states.scissorX1 = 0; states.scissorX2 = seamX
		states.objects[leftState].draw()
		love.graphics.setScissor(seamX,0,love.window.getWidth(), love.window.getHeight()); states.scissorX1 = seamX; states.scissorX2 = love.window.getWidth()
		states.objects[rightState].draw()
		love.graphics.setScissor(); states.scissorX1 = 0; states.scissorX2 = love.window.getWidth()
		-- Border
		states.drawTransitionBar(seamX, nil)
	else
		-- Draw only current state, full screen
		states.objects[states.current].draw()
		-- Transition Buttons
		if states.current > 1 then 
			states.drawTransitionBar(0, states.current-1)
		end
		if states.current < 3 then
			states.drawTransitionBar(love.window.getWidth(), states.current+1)
		end
		states.handleShortcuts()
	end
end


function states.drawTransitionBar(x, targetState)
	-- Bounds
	w = 20
	local winw = love.window.getWidth()
	local x1 = x - w
	local x2 = x + w
	local y1 = 0
	local y2 = love.window.getHeight()
	-- Interaction
	local hover = false
	if states.mouse.active and targetState then
		if states.mouse.x >= x1 and states.mouse.x <= x2 and states.mouse.y >= y1 and states.mouse.y <= y2 then
			hover = true
			if states.mouse.leftclick == 2 then
				states.transition(targetState)
			end
		end
	end
	-- Draw
	love.graphics.setColor(hover and {40,40,40,255} or {60,60,60,255})
	love.graphics.rectangle("fill", x1,y1,x2-x1,y2-y1)
	-- Arrows depend on position on screen?
	-- ...
	love.graphics.setColor(255,255,255, hover and 255 or 220)
	local y = (y1+y2)/2
	-- Arrow to Left on Right side
	love.graphics.line(x+5,y, x+w-5,y-20)
	love.graphics.line(x+5,y, x+w-5,y+20)
	-- Arrow to Right on Left side
	love.graphics.line(x-5,y, x-w+5,y-20)
	love.graphics.line(x-5,y, x-w+5,y+20)
end

function states.drawTitle(s)
	love.graphics.setColor(0,0,0,220)
	love.graphics.print(s, states.windowW*0.35, 24, 0, 2.5, 2.5)
end



function states.getKeyChange(old, new)
	local r = old
	if new then
		if old > 0 then r = 1 else r = 2 end
	else
		if old > 0 then r = -1 else r = 0 end
	end
	return r
end

function states.getKeyDown(key)
	if states.transitionActive then
		return false
	else
		return love.keyboard.isDown(key)
	end
end

-- Obtains the previous skeleton transformation used by the animation system, later uses
-- it to reverse mouse coordinates to get them in skeleton space
function states.registerTransformation()
	if animator.previousPoseTransformation then
		for i = 1,5 do
			states.transformation[i] = animator.previousPoseTransformation[i]
		end
	end
end

function states.handleShortcuts()
	if not states.transitionActive then
		if states.objects[states.current].shortcuts then
			-- ...
		end
	end
end


function states.setScissor(x,y,w,h)
	x = math.max(x, states.scissorX1)
	w = math.min(w, states.scissorX2)
	love.graphics.setScissor(x,y,w,h)
end

function states.resetScissor()
	if states.transitionActive then
		love.graphics.setScissor(states.scissorX1, 0, states.scissorX2, love.window.getHeight())
	else
		love.graphics.setScissor()
	end
end