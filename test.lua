
require "animator"
require "animatorBlender"


test = {}

function degree(deg)
	return math.pi*deg/180.0
end


function test.init()
	-- Create Skeleton
	local skel = animator.newSkeleton("Test Wolf", 'test/testSkeleton')
	-- Temporary, as file system access isn't integrated
	animator.addImageFile(skel, "torso.png")
	animator.addImageFile(skel, "head1.png")
	animator.addImageFile(skel, "head2.png")
	animator.addImageFile(skel, "arm1.png")
	animator.addImageFile(skel, "arm2.png")
	animator.addImageFile(skel, "foot.png")
	animator.addImageFile(skel, "hand.png")

	-- Add Bones and Images
	local torso
	local head
	local arm
	local leg
	torso = animator.newBone("Torso", skel); animator.setBone(torso, 0, 0, degree(0)); torso.length = 80; animator.newImage("torso.png", torso); animator.setImage(nil, 0, 20, 0, 0.1, true)
		head = animator.newBone("Head", torso); animator.setBone(head, 0, 70, degree(0)); animator.newImage("head1.png", head); animator.setImage(nil, 20,18,0,0.1,true)
			head = animator.newBone("Head 2", head); animator.setBone(head, 20, 10, degree(0)); animator.newImage("head2.png", head); animator.setImage(nil, -5,8,0,0.1,true)
		-- Left Arm
		arm = animator.newBone("Left Arm", torso); animator.setBone(arm, -25, 40, degree(210), true); animator.newImage("arm1.png", arm); animator.setImage(nil, 0,20,0,0.06,true)
			arm = animator.newBone("Left Arm 2", arm); animator.setBone(arm, 0, 35, degree(-10)); animator.newImage("arm2.png", arm); animator.setImage(nil, 0,20,0,0.06,true)
				arm = animator.newBone("Left Hand", arm); animator.setBone(arm, 0, 30, degree(0)); animator.newImage("hand.png", arm); animator.setImage(nil, 0,20,math.pi,0.06,true)
		-- Right Arm
		arm = animator.newBone("Right Arm", torso); animator.setBone(arm, 30, 30, degree(150)); animator.newImage("arm1.png", arm); animator.setImage(nil, 0,20,0,0.06,true)
			arm = animator.newBone("Right Arm 2", arm); animator.setBone(arm, 0, 35, degree(-30)); animator.newImage("arm2.png", arm); animator.setImage(nil, 0,20,0,0.06,true)
				arm = animator.newBone("Right Hand", arm); animator.setBone(arm, 0, 30, degree(0)); animator.newImage("hand.png", arm); animator.setImage(nil, 0,20,math.pi,0.06,true)
		-- Left Leg
		leg = animator.newBone("Left Leg", torso); animator.setBone(leg, -20, -22, degree(195)); animator.newImage("arm1.png", leg); animator.setImage(nil, 0,20,0,0.08,true)
			leg = animator.newBone("Left Leg 2", leg); animator.setBone(leg, 0, 48, degree(7)); animator.newImage("arm2.png", leg); animator.setImage(nil, 0,20,0,0.07,true)
				leg = animator.newBone("Left Foot", leg); animator.setBone(leg, 0, 35, degree(-20)); animator.newImage("foot.png", leg); animator.setImage(nil, 0,20,math.pi,0.07,true)
		-- Right Leg
		leg = animator.newBone("Right Leg", torso); animator.setBone(leg, 8, -22, degree(170)); animator.newImage("arm1.png", leg); animator.setImage(nil, 0,20,0,0.08,true)
			leg = animator.newBone("Right Leg 2", leg); animator.setBone(leg, 0, 48, degree(20)); animator.newImage("arm2.png", leg); animator.setImage(nil, 0,20,0,0.07,true)
				leg = animator.newBone("Right Foot", leg); animator.setBone(leg, 0, 35, degree(-10)); animator.newImage("foot.png", leg); animator.setImage(nil, 0,20,math.pi,0.07,true)


	-- Create Poses
	local pose = animator.newPose(skel)

	-- Create Animations
	local ani = animator.newAnimation("Idle", skel)
		head = animator.getBoneByName(skel, "Head")
		animator.newKeyframe(ani, 0.0, head, "sqrt", nil, nil, degree(-20), 1.0, 1.0, 1.0)
		animator.newKeyframe(ani, 0.5, head, "sqrt", nil, nil,   degree(5), 1.0, 1.0, 1.0)
		animator.newKeyframe(ani, 1.0, head, "", nil, nil, degree(-20), 1.0, 1.0, 1.0)
		arm = animator.getBoneByName(skel, "Left Arm")
		animator.newKeyframe(ani, 0.0, arm, "linear", nil, nil, degree(210))
		animator.newKeyframe(ani, 1.0, arm, "", nil, nil, degree(360+210))
		arm = animator.getBoneByName(skel, "Left Arm 2")
		animator.newKeyframe(ani, 0.0, arm, "linear", nil, nil, degree(-10))
		animator.newKeyframe(ani, 0.3, arm, "linear", nil, nil, degree(-90))
		animator.newKeyframe(ani, 0.7, arm, "linear", nil, nil, degree(60))
		animator.newKeyframe(ani, 1.0, arm, "", nil, nil, degree(-10))
	local ani2 = animator.newAnimation("Walk", skel)
		leg = animator.getBoneByName(skel, "Left Leg")
		animator.newKeyframe(ani2, 0.0, leg, "cos", nil, nil, degree(220), nil, nil, nil)
		animator.newKeyframe(ani2, 0.45, leg, "cos", nil, nil, degree(160), nil, nil, nil)
		animator.newKeyframe(ani2, 1.0, leg, "", nil, nil, degree(220), nil, nil, nil)
		leg = animator.getBoneByName(skel, "Right Leg")
		animator.newKeyframe(ani2, 0.0, leg, "linear", nil, nil, degree(140), nil, nil, nil)
		animator.newKeyframe(ani2, 0.45, leg, "linear", nil, nil, degree(190), nil, nil, nil)
		animator.newKeyframe(ani2, 1.0, leg, "", nil, nil, degree(140), nil, nil, nil)


	-- Blender
	local blender = blender.newAniBlender(pose, ani)


	-- Store for later use
	test.skel = skel
	test.pose = pose
	test.pose2 = animator.newPose(skel)
	test.ani = ani
	test.ani2 = ani2
	test.arm = animator.getBoneByName(skel, "Right Arm")
	test.leg = animator.getBoneByName(skel, "Left Leg")
	test.leg2 = animator.getBoneByName(skel, "Left Foot")

	print("- - - - - - - - - - ")
	animator.drawPose(test.pose, 400, 400, 0.0, 1.0, 1.0, 1.0)
	animator.drawDebugSkeleton(test.skel, 400, 400, 0.0, 1.0, 1.0, 1.0)
end



function test.update()
	-- Animate bones - note: this does not work when animator.applyPose (or drawPose) is executed afterwards as they'll overwrite bone transformations
	animator.setPoseBone(test.pose, test.arm, nil, nil, degree(150+20*math.sin(love.timer.getTime()*5)))
	--animator.setPoseBone(test.pose, test.leg, nil, nil, degree(195+20*math.sin(love.timer.getTime()*3)))
	--animator.setPoseBone(test.pose, test.leg2, nil, nil, degree(-20+15*math.sin(love.timer.getTime()*5.6)))
	animator.setPoseBone(test.pose2, animator.getBoneByName(test.skel, "Torso"), nil, nil, 0.15*love.timer.getTime())
	local p = love.timer.getTime()*0.5
	animator.applyAnimation(test.pose, test.ani, p - math.floor(p))
	p = p*3
	animator.applyAnimation(test.pose, test.ani2, p - math.floor(p))
end

function test.draw()
	if love.keyboard.isDown("lshift") then scx = -1 else scx = 1 end
	-- Note: Drawing Pose will overwrite all bone transformations previously applied, as they're fixed within the pose
	animator.drawPose(test.pose, 400, 400, 0.0, scx*2, 2.0, 1.0)
	-- drawSkeleton updates all bone transformations recursively and draws all images bound to bones of the skeleton
	--animator.drawSkeleton(test.skel, 400, 400, 0.0, scx, 1.0, 1.0)
	-- draws bone debug triangles
	animator.drawDebugSkeleton(test.skel)
	-- Alternative Pose
	animator.drawPose(test.pose2, 800, 400, 0.0, scx*1.5, 1.5, 1.0)
	animator.drawDebugSkeleton(test.skel, 400, 400, 0.0, scx*1.5, 1.5, 1.0)
end
