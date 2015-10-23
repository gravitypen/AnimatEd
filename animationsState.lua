


animationsState = {
	blender = nil,
	skel = nil,
	pose = nil,
	anis = {},
	playAni = nil,
	zoomLevel = 0,
	zoom = 1.0,
	selectedElement = nil,
}


function animationsState.load()
end

function animationsState.checkEnter()
	return skeletonState.currentSkeleton ~= nil
end

function animationsState.enter()
	if states.transitionFrom == states.skeleton then
		animationsState.skel = skeletonState.currentSkeleton
		animationsState.pose = animator.newPose(animationsState.skel, "aniOverviewPose")
		animationsState.blender = blender.newAniBlender(animationsState.pose, animationsState.skel.defaultPose)
		animationsState.anis = {}
		animationsState.updateAnimationList()
	else
		animationsState.playAni = nil
	end
end


function animationsState.update()
	-- Zoom
	if states.mouse.mz ~= 0 then
		animationsState.zoomLevel = clamp(animationsState.zoomLevel + states.mouse.mz, -32, 32)
		animationsState.zoom = math.pow(1.1, animationsState.zoomLevel)
	end
	-- Animation
	if animationsState.blender then blender.update(animationsState.blender) end
end

function animationsState.draw()
	if not animationsState.skel then return end
	love.graphics.setColor(editor.backColor)
	love.graphics.rectangle("fill", 0, 0, states.windowW, states.windowH)

	-- Title
	states.drawTitle("Animation Overview")

	-- Skeleton
	animator.drawPose(animationsState.pose, states.windowW*0.5, states.windowH*0.5, 0.0, animationsState.zoom, animationsState.zoom, 1.0, states.getKeyDown("d"))

	-- List of Animations
	local sel, hover = listview(21,1,200,states.windowH-200, animationsState.anis, function(a) return a.name end)
	if sel then
		if animationsState.anis[sel] ~= animationsState.playAni then
			if sel > 0 then
				animationsState.playAni = animationsState.anis[sel]
				animator.completeAnimation(animationsState.playAni) -- make sure any added bones/keyframes are taken into account by that animation
				blender.stopAllAnis(animationsState.blender)
				blender.playAni(animationsState.blender, animationsState.playAni, -1, 0)
			else
				animationsState.playAni = nil
				blender.stopAllAnis(animationsState.blender)
			end
		end
	else
		animationsState.playAni = nil
		blender.stopAllAnis(animationsState.blender)		
	end
	
	-- New
	if button(110, states.windowH-170, 160,25, "New Ani") then
		textInput("New Animation's Name:", "", function(name)
			if string.len(name) > 0 then
				numberInput("Duration in Seconds:", "", function(dur)
					if dur < 0.01 then dur = 0.01 end
					-- Create and Add to List
					local ani = animator.newAnimation(name, animationsState.skel, dur)
					table.insert(animationsState.anis, ani)
					-- Select and "Play" (albeit doing nothing)
					animationsState.playAni = ani
					blender.stopAllAnis(animationsState.blender)
					blender.playAni(animationsState.blender, animationsState.playAni, -1, 0)
					-- Edit Animation
					animationState.createDefaultKeyframes = true
					states.transition(states.animation)
				end, nil, nil)
			end
		end, nil, nil)
	end

	-- Debug
	love.graphics.setColor(0,0,0,255)
	blender.debug(animationsState.blender, 240,10)
end







-- Refreshes the list of animations for the currently selected skeleton by reading them fron its
-- root directory
function animationsState.updateAnimationList()
	print("Updating Animations")
	local skel = animationsState.skel
	animationsState.anis = {}
	lfs.chdir(skel.projectPath) -- not neccessary, as we always stay in current skeleton's path?
	for file in lfs.dir("animations") do
		if file:sub(-4) == ".ani" then
			print("Loading animation " .. file .. "...")
			local ani = animationsState.loadAnimation(file)
			table.insert(animationsState.anis, ani)
		end
	end
end




function animationsState.loadAnimation(file)
	local skel = animationsState.skel
	local table = loadTable(skel.projectPath .. "/animations/" .. file)
	if table then
		print("  Table read, creating animation object with name " .. table.name)
		-- Create Animation and apply values
		local ani = animator.newAnimation(table.name, skel, table.duration)
		ani.saveList = animator.saveLists.animation
		applyTable(table, ani)

		-- Complete/fix values where needed
		ani.skel = skel
		-- Fix Keyframes (ani, element)
		for id,elementAni in pairs(ani.keyframes) do
			print("  Ani has keyframes for element " .. id)
			for i = 1,#elementAni do
				print("    Affects: " .. #elementAni.affects)
				local keyframe = elementAni[i]
				keyframe.ani = ani
				keyframe.saveList = animator.saveLists.keyframe
				keyframe.element = skel.elementMap[keyframe.elementID]
				keyframe[1] = keyframe.x
				keyframe[2] = keyframe.y
				keyframe[3] = keyframe.angle
				keyframe[4] = keyframe.alpha
				keyframe[5] = keyframe.xscale
				keyframe[6] = keyframe.yscale
			end
		end

		return ani

	else
		print("  Could not load Animation " .. file .. "!")
	end
	return nil
end


function animationsState.saveAnimation(ani)
	local file = ani.name .. ".ani"
	local path = animationsState.skel.projectPath .. "/animations/"

    file, err = io.open(path .. file, "w")
    if file == nil then
    	infoDialog("Could not open file! See console for details.")
        print("Error while opening file: " .. tostring(err) .. ". Animation has not been saved!")
    else

        file:write("return {\n")
        writeTable(file, ani, 1)
        file:write("}\n")
        file:close()
       
    end
end