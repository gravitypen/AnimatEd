


skeletonState = {
	shortcuts = {},
	skeletons = {},
	currentID = 0,
	currentSkeleton = test.skel,
	zoomLevel = 0,
	zoom = 1.0,
}


function skeletonState.load()
	-- Load Skeletons
end


function skeletonState.enter()
	skeletonState.skeletons[1] = test.skel
	--skeletonState.skeletons[1].defaultPose = animator.newPose(skeletonState.skeletons[1])
end


function skeletonState.update()
	-- Zoom
	if states.mouse.mz ~= 0 then
		skeletonState.zoomLevel = clamp(skeletonState.zoomLevel + states.mouse.mz, -32, 32)
		skeletonState.zoom = math.pow(1.1, skeletonState.zoomLevel)
	end
end

function skeletonState.draw()
	-- Back
	love.graphics.setColor(editor.backColor)
	love.graphics.rectangle("fill", 0, 0, states.windowW, states.windowH)
	-- Selected Skeleton
	local skel = skeletonState.currentSkeleton
	if skel then
		animator.drawPose(skel.defaultPose, states.windowW*0.5, states.windowH*0.5, 0.0, skeletonState.zoom, skeletonState.zoom, 1.0, states.getKeyDown("d"))
	end
	-- Title
	states.drawTitle("Skeletons")
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
			-- Draw Bone
			if hover.tp == "bone" then
				animator.reapplyPreviousPoseTransformation()
				animator.drawSingleDebugBone(hover)
				animator.drawDebugBoneImages(hover)
				animator.undoPoseTransformation()
				for i = 1,#hover.images do
					hover.images[i].__highlight = 1 
				end
			end
		end
		if sel then 
			-- Select Bone
		end
		-- Images of this Skeleton
		listview(states.windowW-220,1,220,states.windowH, skel.imageList)
	end
end
