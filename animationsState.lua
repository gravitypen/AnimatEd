


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
	print("Entering State")
	if states.transitionFrom == states.skeleton then
		animationsState.skel = skeletonState.currentSkeleton
		animationsState.pose = animator.newPose(animationsState.skel)
		animationsState.blender = blender.newAniBlender(animationsState.pose, animationsState.skel.defaultPose)
		animationsState.anis = {test.ani, test.ani2}
		animationsState.updateAnimationList()
		print("Setup done!")
	end
end


function animationsState.update()
	-- Zoom
	if states.mouse.mz ~= 0 then
		animationsState.zoomLevel = clamp(animationsState.zoomLevel + states.mouse.mz, -32, 32)
		animationsState.zoom = math.pow(1.1, animationsState.zoomLevel)
	end
end

function animationsState.draw()
	if not animationsState.skel then return end
	love.graphics.setColor(editor.backColor)
	love.graphics.rectangle("fill", 0, 0, states.windowW, states.windowH)
	-- Title
	states.drawTitle("Animation Overview")
	-- Skeleton
	if animationsState.blender then blender.update(animationsState.blender) end
	animator.drawPose(animationsState.pose, states.windowW*0.5, states.windowH*0.5, 0.0, animationsState.zoom, animationsState.zoom, 1.0, states.getKeyDown("d"))
	-- List of Animations
	local sel, hover = listview(21,1,200,states.windowH, animationsState.anis, function(a) return a.name end)
	if sel then
		if animationsState.anis[sel] ~= animationsState.playAni then
			if sel > 0 then
				animationsState.playAni = animationsState.anis[sel]
				blender.stopAllAnis(animationsState.blender)
				blender.playAni(animationsState.blender, animationsState.playAni, -1, 0)
			else
				print("Stopping all Animations")
				animationsState.playAni = nil
				blender.stopAllAnis(animationsState.blender)
			end
		end
	else
		print("Stopping all Animations")
		animationsState.playAni = nil
		blender.stopAllAnis(animationsState.blender)		
	end
	-- Debug
	love.graphics.setColor(0,0,0,255)
	blender.debug(animationsState.blender, 100,10)
end







-- Refreshes the list of animations for the currently selected skeleton by reading them fron its
-- root directory
function animationsState.updateAnimationList()
	print("Setting up animation list")
end