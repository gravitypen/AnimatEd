
require "animator"
require "animatorBlender"


test = {}

function degree(deg)
	return math.pi*deg/180.0
end


function test.init()
	-- Create Skeleton
	local skel = animator.newSkeleton("skelWolf", 'D:/programming/love-0.9.2-win32/AnimatEd/test/testSkeleton')
	-- Temporary, as file system access isn't integrated
	--animator.addImageFile(skel, "torso.png")
	--animator.addImageFile(skel, "head1.png")
	--animator.addImageFile(skel, "head2.png")
	--animator.addImageFile(skel, "arm1.png")
	--animator.addImageFile(skel, "arm2.png")
	--animator.addImageFile(skel, "foot.png")
	--animator.addImageFile(skel, "hand.png")

	-- Add Bones and Images
	local torso
	local head
	local arm
	local leg
	torso = animator.newBone("Torso", skel); animator.setBone(torso, 0, 0, degree(0)); animator.newImage("torso.png", torso); animator.setImage(nil, 0, 20, 0, 0.1, true); local iTorso = animator.newestImage
		head = animator.newBone("Head", torso); animator.setBone(head, 4, 27, degree(0), true); animator.newImage("head1.png", head); animator.setImage(nil, 20,18,0,0.1,true)
			head = animator.newBone("Head 2", head); animator.setBone(head, 20, -30, degree(0)); animator.newImage("head2.png", head); animator.setImage(nil, -5,8,0,0.1,true)
		-- Left Arm
		arm = animator.newBone("Left Arm", torso); animator.setBone(arm, -16, 0, degree(210), true); animator.newImage("arm1.png", arm); animator.setImage(nil, 0,20,math.pi,0.06,true)
			arm = animator.newBone("Left Arm 2", arm); animator.setBone(arm, 0, -5, degree(-10)); animator.newImage("arm2.png", arm); animator.setImage(nil, 0,20,math.pi,0.06,true)
				arm = animator.newBone("Left Hand", arm); animator.setBone(arm, 0, -10, degree(0)); animator.newImage("hand.png", arm); animator.setImage(nil, 0,20,math.pi,0.06,true)
		-- Right Arm
		arm = animator.newBone("Right Arm", torso); animator.setBone(arm, 30, -10, degree(150)); animator.newImage("arm1.png", arm); animator.setImage(nil, 0,20,math.pi,0.06,true)
			arm = animator.newBone("Right Arm 2", arm); animator.setBone(arm, 0, -5, degree(-30)); animator.newImage("arm2.png", arm); animator.setImage(nil, 0,20,math.pi,0.06,true)
				arm = animator.newBone("Right Hand", arm); animator.setBone(arm, 0, -10, degree(0)); animator.newImage("hand.png", arm); animator.setImage(nil, 0,20,math.pi,0.06,true)
		-- Left Leg
		leg = animator.newBone("Left Leg", torso); animator.setBone(leg, -16, -62, degree(195)); animator.newImage("arm1.png", leg); animator.setImage(nil, 0,20,math.pi,0.08,true)
			leg = animator.newBone("Left Leg 2", leg); animator.setBone(leg, 0, 8, degree(7)); animator.newImage("arm2.png", leg); animator.setImage(nil, 0,20,math.pi,0.07,true)
				leg = animator.newBone("Left Foot", leg); animator.setBone(leg, 0, -5, degree(-20)); animator.newImage("foot.png", leg); animator.setImage(nil, 0,20,math.pi,0.07,true)
		-- Right Leg
		leg = animator.newBone("Right Leg", torso); animator.setBone(leg, 8, -62, degree(170)); animator.newImage("arm1.png", leg); animator.setImage(nil, 0,20,math.pi,0.08,true)
			leg = animator.newBone("Right Leg 2", leg); animator.setBone(leg, 0, 8, degree(20)); animator.newImage("arm2.png", leg); animator.setImage(nil, 0,20,math.pi,0.07,true)
				leg = animator.newBone("Right Foot", leg); animator.setBone(leg, 0, -5, degree(-10)); animator.newImage("foot.png", leg); animator.setImage(nil, 0,20,math.pi,0.07,true)


	-- Create Poses
	local pose = animator.newPose(skel, "TestPose")

	-- Create Animations
	local ani = animator.newAnimation("aniIdle", skel, 1.6)
		head = animator.getBoneByName(skel, "Head")
			animator.newKeyframe(ani, 0.0, head, {0.5,-0.5, 0.5,1.5}, nil, nil, degree(-20), 1.0, 1.0, 1.0)
			animator.newKeyframe(ani, 0.5, head, {0.5,-0.5, 0.5,1.5}, nil, nil,   degree(5), 1.0, 1.0, 1.0)
			animator.newKeyframe(ani, 1.0, head, "", nil, nil, degree(-20), 1.0, 1.0, 1.0)
		arm = animator.getBoneByName(skel, "Left Arm")
			animator.newKeyframe(ani, 0.0, arm, "linear", nil, nil, degree(210))
			animator.newKeyframe(ani, 1.0, arm, "", nil, nil, degree(360+210))
		arm = animator.getBoneByName(skel, "Left Arm 2")
			animator.newKeyframe(ani, 0.0, arm, "linear", nil, nil, degree(-10))
			animator.newKeyframe(ani, 0.3, arm, "linear", nil, nil, degree(-90))
			animator.newKeyframe(ani, 0.7, arm, "linear", nil, nil, degree(60))
			animator.newKeyframe(ani, 1.0, arm, "", nil, nil, degree(-10))
		arm = animator.getBoneByName(skel, "Right Arm")
			animator.newKeyframe(ani, 0.0,  arm, "cos", nil, nil, degree(150))
			animator.newKeyframe(ani, 0.64, arm, "cos", nil, nil, degree(110))
			animator.newKeyframe(ani, 1.0,  arm, "", nil, nil, degree(150))
		leg = animator.getBoneByName(skel, "Left Leg")
			animator.newKeyframe(ani, 0.0, leg, "sqrt", nil, nil, degree(170), 1.0, 1.0, 1.0)
			animator.newKeyframe(ani, 0.5, leg, "sqrt", nil, nil,   degree(215), 1.0, 1.0, 1.0)
			animator.newKeyframe(ani, 1.0, leg, "", nil, nil, degree(170), 1.0, 1.0, 1.0)
		leg = animator.getBoneByName(skel, "Right Leg")
			animator.newKeyframe(ani, 0.0, leg, "sqrt", nil, nil, degree(150), 1.0, 1.0, 1.0)
			animator.newKeyframe(ani, 0.5, leg, "sqrt", nil, nil,   degree(195), 1.0, 1.0, 1.0)
			animator.newKeyframe(ani, 1.0, leg, "", nil, nil, degree(150), 1.0, 1.0, 1.0)
		leg = animator.getBoneByName(skel, "Right Leg 2")
			animator.newKeyframe(ani, 0.0, leg, "cos", nil, nil, degree(20), nil, nil, nil)
		leg = animator.getBoneByName(skel, "Left Leg 2")
			animator.newKeyframe(ani, 0.0, leg, "cos", nil, nil, degree(7), nil, nil, nil)
		-- Torso Image animation
			animator.newKeyframe(ani, 0.0, iTorso, "sqrt", 0, 20)
			animator.newKeyframe(ani, 0.5, iTorso, "sqrt", 0, 25)
			animator.newKeyframe(ani, 1.0, iTorso, "", 0, 20)
	local ani2 = animator.newAnimation("aniWalk", skel, 0.7)
		leg = animator.getBoneByName(skel, "Left Leg")
			animator.newKeyframe(ani2, 0.0, leg, {0.3,0.0, 0.7,1.0}, -16, -62, degree(240), nil, 1.0, nil)		
			--animator.newKeyframe(ani2, 0.0, leg, "cos", nil, nil, degree(220), nil, nil, nil)
			animator.newKeyframe(ani2, 0.55, leg, "linear", -16, -62, degree(130), nil, 1.8, nil)
			animator.newKeyframe(ani2, 1.0, leg, "", -16, -62, degree(240), nil, 1.0, nil)
		leg = animator.getBoneByName(skel, "Right Leg")
			animator.newKeyframe(ani2, 0.0, leg, "cos", nil, nil, degree(120), nil, nil, nil)
			animator.newKeyframe(ani2, 0.45, leg, "cos", nil, nil, degree(220), nil, nil, nil)
			animator.newKeyframe(ani2, 1.0, leg, "", nil, nil, degree(120), nil, nil, nil)
		leg = animator.getBoneByName(skel, "Right Leg 2")
			animator.newKeyframe(ani2, 0.0, leg, "cos", nil, nil, degree(70), nil, nil, nil)
		leg = animator.getBoneByName(skel, "Left Leg 2")
			animator.newKeyframe(ani2, 0.0, leg, "cos", nil, nil, degree(90), nil, nil, nil)
			animator.newKeyframe(ani2, 0.5, leg, "cos", nil, nil, degree(40), nil, nil, nil)
			animator.newKeyframe(ani2, 1.0, leg, "cos", nil, nil, degree(90), nil, nil, nil)



	-- Blender
	local aniBlender = blender.newAniBlender(pose, ani)


	-- Store for later use
	test.skel = skel
	test.pose = pose
	test.pose2 = animator.newPose(skel)
	test.ani = ani
	test.ani2 = ani2
	test.root = skel.rootChild
	test.arm = animator.getBoneByName(skel, "Right Arm")
	test.leg = animator.getBoneByName(skel, "Left Leg")
	test.leg2 = animator.getBoneByName(skel, "Left Foot")
	test.blender = aniBlender

	print("- - - - - - - - - - ")
	animator.drawPose(test.pose, 400, 400, 0.0, 1.0, 1.0, 1.0)
	animator.drawDebugSkeleton(test.skel, 400, 400, 0.0, 1.0, 1.0, 1.0)

end



function test.update(td)
	if love.keyboard.isDown(" ") then blender.playAni(test.blender, test.ani2, 5, 1) end
	blender.updateTime(td)
	blender.update(test.blender)
	-- Animate bones - note: this does not work when animator.applyPose (or drawPose) is executed afterwards as they'll overwrite bone transformations
	--animator.setPoseBone(test.pose, test.arm, nil, nil, degree(150+20*math.sin(love.timer.getTime()*5)))
	--animator.setPoseBone(test.pose, test.leg, nil, nil, degree(195+20*math.sin(love.timer.getTime()*3)))
	--animator.setPoseBone(test.pose, test.leg2, nil, nil, degree(-20+15*math.sin(love.timer.getTime()*5.6)))
	animator.setPoseBone(test.pose2, animator.getBoneByName(test.skel, "Torso"), nil, nil, 0.15*love.timer.getTime())
	--local p = love.timer.getTime()*0.5
	--animator.applyAnimation(test.pose, test.ani, p - math.floor(p))
	--p = p*3
	--animator.applyAnimation(test.pose, test.ani2, p - math.floor(p))
end

function test.draw()
	if love.keyboard.isDown("lshift") then scx = -1 else scx = 1 end
	if love.keyboard.isDown("h") then animator.getBoneByName(test.skel, "Head").scaleX = -1.0 else animator.getBoneByName(test.skel, "Head").scaleX = 1.0 end
	-- Note: Drawing Pose will overwrite all bone transformations previously applied, as they're fixed within the pose
	animator.drawPose(test.pose, 400, 400, 0.0, scx*2, 2.0, 1.0, love.keyboard.isDown("d"))
	-- drawSkeleton updates all bone transformations recursively and draws all images bound to bones of the skeleton
	--animator.drawSkeleton(test.skel, 400, 400, 0.0, scx, 1.0, 1.0)
	-- Alternative Pose
	animator.drawPose(test.pose2, 1100, 400, 0.0, scx*1.5, 1.5, 1.0, false)
	love.graphics.setColor(255,255,255,255)
	blender.debug(test.blender)
	love.graphics.print("Press Space to trigger Run Animation, LShift to flip wolf, H to flip head, D for debug", 400, 8)

	treeview(33,50,200,600, test.root.childs[1], 
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
	listview(1400,50,200,600, test.skel.imageList)
end
