

blender = {}


function blender.load()
	blender.td = 0.0
end



-- Creates an AnimationBlender for a given skeleton
function blender.newAniBlender(skel, defaultAni)
	local b = {
		skel = skel,
		anis = {}, -- current animations, will always contain whatever animation is currently being executed
		defaultAni = defaultAni
	}
	return b
end


-- Starts playing an animation for the given AnimationBlender, or refreshes it if it's already being played,
-- i.e. moves it to the top of the current animation stack
function blender.playAni(aniBlender, ani, loops, priority, fadeInTime, speedFactor)

	-- already running?
	local index = 0
	for i = 1,#aniBlender.anis do
		if aniBlender.anis[i].animation == ani then index = i; return end
	end

	if index > 0 then

		-- ani already running, only update values
		local a = aniBlender.anis[index]
		a.loopsRemaining = loops
		if fadeInTime then a.fadeStep = 1.0/fadeInTime end
		if speedFactor then a.step = speedFactor/ani.duration end
		if priority then a.priority = priority end
		-- move to top of animation list
		blender.resort(aniBlender, index)

	else

		-- ani not yet running, so add to list
		loops = loops or 1
		fadeInTime = fadeInTime or 0.2
		speedFactor = speedFactor or 1.0
		local aniObject = {
			animation = ani,
			loopsRemaining = loops,
			speedFactor = speedFactor,
			progress = 0.0,
			step = speedFactor/ani.duration,
			opacity = 0.0,
			fadeStep = 1.0/fadeInTime,
			priority = priority
		}
		table.insert(aniBlender.anis, aniObject)
		blender.resort(aniBlender, #aniBlender.anis)

	end

end


-- Resorts a single animation of an aniBlender object given by index; note: function assumes all indices except the given
-- one are in correct order; index will be on top of all current animations with same priority
function blender.resort(aniBlender, i)
	-- Move right? 
	if i < #aniBlender.anis then
		local j = i+1
		while aniBlender.anis[j].priority <= aniBlender.anis[j-1].priority do
			-- Swap
			local temp = aniBlender.anis[j]
			aniBlender.anis[j] = aniBlender.anis[j-1]
			aniBlender.anis[j-1] = temp
			-- Proceed and Check
			j = j+1
			if j > #aniBlender.anis then break end
		end
		-- Has been moved right -> Leave
		if j ~= i+1 then return end
	end
	-- Move left?
	if i > 1 then
		local j = i-1
		while aniBlender.anis[j].priority > aniBlender.anis[j+1].priority do
			-- Swap
			local temp = aniBlender.anis[j]
			aniBlender.anis[j] = aniBlender.anis[j+1]
			aniBlender.anis[j+1] = temp			
			-- Proceed and Check
			j = j-1
			if j < 1 then break end
		end
	end
end


-- Checks whether a given animation is currently being played within the aniBlender and begins the fade out
function blender.stopAni(aniBlender, ani, fadeOutTime)
	for i = 1,#aniBlender.anis do
		if aniBlender.anis[i].animation == ani then
			-- initialize fade out
			if fadeOutTime then
				if fadeOutTime <= 0 then
					-- stop immediately
					table.remove(aniBlender.anis, i)
				else
					-- custom fade out time
					aniBlender.anis[i].fadeStep = -1.0/fadeOutTime
				end
			else
				-- use fade in speed for fade out
				aniBlender.anis[i].fadeStep = -math.abs(aniBlender.anis[i].fadeStep)
			end
			-- leave loop, since there can't be more than a single instance of an animation in the current animation list of an AniBlender object
			break
		end
	end
end











function blender.updateTime(td)
	blender.td = td
end

-- Updates a single animation blender; should always be called immediately before drawing
-- an animated character using drawPose
function blender.update(aniBlender, applyToPose)

	-- only update when there's a time dif
	if blender.td <= 0 then return end

	-- no animation active -> play default animation
	if #aniBlender.anis == 0 then
		blender.playAni(aniBlender, aniBlender.defaultAni, -1)
	end

	-- Update current animations
	local ani
	for a = #aniBlender.anis,1,-1 do
		-- Time based progress
		ani = aniBlender.anis[a]
		ani.progress = ani.progress + blender.td * ani.step

		-- Animation completed a loop
		if ani.progress >= 1.0 then
			if ani.loopsRemaining > 0 then
				ani.loopsRemaining = ani.loopsRemaining - math.floor(ani.progress)
				ani.progress = ani.progress - math.floor(ani.progress)
				if ani.loopsRemaining <= 0 then
					-- Animation has run out
					ani.fadeStep = -2.0/blender.td
				end
			else
				-- Animation loops indefinitely, so simply reset progress
				ani.progress = ani.progress - math.floor(ani.progress)
			end
		end

		-- Fading in/out
		ani.opacity = ani.opacity + blender.td * ani.fadeStep
		if ani.opacity > 1.0 then
			-- fully faded in
			ani.opacity = 1.0
		elseif ani.opacity <= 0.0 then
			-- faded out
			table.remove(aniBlender.anis, a)
		end
	end

	-- Blend between multiple animations
	if #aniBlender.anis > 1 then
		-- ...
	end

	-- Apply Animation to Pose
	if applyToPose then
		-- ...
	end

end