


animationState = {
	skel = nil,
	blender = nil,
	pose = nil,
	zoomLevel = 0,
	zoom = 1.0,
}


function animationState.load()
end


function animationState.checkEnter()
	return animationsState.playAni ~= nil
end

function animationState.enter()
	animationState.skel = animationsState.skel
	animationState.pose = animator.newPose(animationState.skel, "animationPose")
	animationState.blender = blender.newAniBlender(animationState.pose, animationState.skel.defaultPose)
end


function animationState.update()
	-- Zoom
	if states.mouse.mz ~= 0 then
		animationState.zoomLevel = clamp(animationState.zoomLevel + states.mouse.mz, -32, 32)
		animationState.zoom = math.pow(1.1, animationState.zoomLevel)
	end
end

function animationState.draw()
	love.graphics.setColor(editor.backColor)
	love.graphics.rectangle("fill", 0, 0, states.windowW, states.windowH)
	-- Title
	states.drawTitle("Animation Editing")
	-- Skeleton
	if animationState.blender then blender.update(animationState.blender) end
	animator.drawPose(animationState.pose, states.windowW*0.5, states.windowH*0.5, 0.0, animationState.zoom, animationState.zoom, 1.0, states.getKeyDown("d"))

	-- Bones of Current Skeleton
	local sel, hover = treeview(32,1,220,states.windowH-200, animationState.skel.rootChild.childs[1], 
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
		-- Draw Bone
		if hover.tp == "bone" then
			animator.reapplyPreviousPoseTransformation()
			animator.drawSingleDebugBone(hover)
			animator.drawDebugBoneImages(hover)
			animator.undoPoseTransformation()
		end
	end
	if sel then 
		-- Select Bone
	end

	-- Global Animation Properties

	-- Selected Keyframe Properties

	-- Timeline

end
