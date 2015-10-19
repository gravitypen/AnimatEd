


animationsState = {
	blender = nil,
	skel = nil,
	pose = nil,
	anis = {},
	playAni = nil,
	zoomLevel = 0,
	zoom = 1.0,
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
		animationsState.anis = {test.ani, test.ani2}
		animationsState.updateAnimationList()
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
end