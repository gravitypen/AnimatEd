

blender = {}


function blender.load()
	blender.td = 0.0
end



-- Creates an AnimationBlender for a given skeleton
function blender.newAniBlender(pose, defaultAni)
	local b = {
		skel = pose.skel,
		pose = pose,
		tempPose = animator.newPose(pose.skel),
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
		if aniBlender.anis[i].animation == ani then index = i; break end
	end

	if index > 0 then

		-- ani already running, only update values
		local a = aniBlender.anis[index]
		if loops then a.loopsRemaining = loops end
		if fadeInTime then a.fadeStep = 1.0/fadeInTime end
		if speedFactor then a.step = speedFactor/ani.duration end
		if priority then a.priority = priority end
		-- move to top of animation list
		blender.resort(aniBlender, index)

	else

		-- ani not yet running, so add to list
		loops = loops or 1
		fadeInTime = fadeInTime or 0.5
		speedFactor = speedFactor or 1.0
		priority = priority or 0
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
					ani.fadeStep = -1.5*math.abs(ani.fadeStep) ---2.0/blender.td
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

	-- Blend between multiple animations and apply them to Pose
	if #aniBlender.anis >= 1 then
		-- For each running animation, first apply it to tempPose, then blend changed bone values for actual Pose
		for i = 1,#aniBlender.anis do
			-- Apply Animation
			animator.applyAnimation(aniBlender.tempPose, aniBlender.anis[i].animation, aniBlender.anis[i].progress)
			-- Blend into actual Pose
			for id,element in pairs(aniBlender.anis[i].animation.keyframes) do
				-- Get list of keyframes for a single bone or image that is affected by this animation
				local keyframes = aniBlender.anis[i].animation.keyframes[id]
				-- Only update affected attributes
				local poseState = aniBlender.pose.state[id]
				local tempPoseState = aniBlender.tempPose.state[id]
				for k = 1,#keyframes.affects do
					if keyframes.affects[k] then
						if aniBlender.anis[i].opacity >= 1.0 then
							-- Simply apply value
							poseState[k] = tempPoseState[k]
						else
							-- Blend onto existing value
							poseState[k] = aniBlender.anis[i].opacity*tempPoseState[k] + (1.0 - aniBlender.anis[i].opacity)*poseState[k]
						end
					end
				end
			end
		end
	end


end




function blender.debug(aniBlender)
	local y = 0
	for i = 1,#aniBlender.anis do
		love.graphics.print(i .. ". " .. aniBlender.anis[i].animation.name .. ", " .. aniBlender.anis[i].loopsRemaining .. ", " .. math.floor(100*aniBlender.anis[i].progress), 0, y)
		y = y + 20
	end
end