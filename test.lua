
require "animator"


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

	-- Add Bones and Images
	local torso
	local head
	local arm
	local leg
	torso = animator.newBone("Torso", skel); animator.setBone(torso, 0, 0, degree(0)); torso.length = 80
		head = animator.newBone("Head", torso); animator.setBone(head, 0, 70, degree(0))
			head = animator.newBone("Head 2", head); animator.setBone(head, 20, 10, degree(0))
		-- Left Arm
		arm = animator.newBone("Left Arm", torso); animator.setBone(arm, -35, 40, degree(210), true)
			arm = animator.newBone("Left Arm 2", arm); animator.setBone(arm, 0, 35, degree(-10))
				arm = animator.newBone("Left Hand", arm); animator.setBone(arm, 0, 30, degree(0))
		-- Right Arm
		arm = animator.newBone("Right Arm", torso); animator.setBone(arm, 30, 30, degree(150))
			arm = animator.newBone("Right Arm 2", arm); animator.setBone(arm, 0, 35, degree(-30))
				arm = animator.newBone("Right Hand", arm); animator.setBone(arm, 0, 30, degree(0))
		-- Left Leg
		leg = animator.newBone("Left Leg", torso); animator.setBone(leg, -25, -22, degree(195), true)
			leg = animator.newBone("Left Leg 2", leg); animator.setBone(leg, 0, 48, degree(7))
				leg = animator.newBone("Left Foot", leg); animator.setBone(leg, 0, 35, degree(-20))
		-- Right Leg
		leg = animator.newBone("Right Leg", torso); animator.setBone(leg, 20, -22, degree(170))
			leg = animator.newBone("Right Leg 2", leg); animator.setBone(leg, 0, 48, degree(20))
				leg = animator.newBone("Right Foot", leg); animator.setBone(leg, 0, 35, degree(-10))


	-- Create Poses
	local pose = animator.newPose(skel)

	-- Create Animations
	local ani = animator.newAnimation("Idle", skel)
		animator.newKeyframe(ani, 0.0, head, 0, 0, -20, 1.0, 1.0, 1.0)
		animator.newKeyframe(ani, 0.5, head, 0, 0,   5, 1.0, 1.0, 1.0)
		animator.newKeyframe(ani, 1.0, head, 0, 0, -20, 1.0, 1.0, 1.0)


	-- Store for later use
	test.skel = skel
	test.pose = pose
	test.ani = ani
	test.arm = animator.getBoneByName(skel, "Right Arm")
	test.leg = animator.getBoneByName(skel, "Left Leg")
	test.leg2 = animator.getBoneByName(skel, "Left Foot")

	print("- - - - - - - - - - ")
	animator.drawPose(test.pose, 400, 400, 0.0, 1.0, 1.0, 1.0)
	animator.drawDebugSkeleton(test.skel, 400, 400, 0.0, 1.0, 1.0, 1.0)
end



function test.update()
	-- Animate bones - note: this does not work when animator.applyPose (or drawPose) is executed afterwards as they'll overwrite bone transformations
	animator.setBone(test.arm, nil, nil, degree(150+20*math.sin(love.timer.getTime()*5)))
	animator.setBone(test.leg, nil, nil, degree(195+20*math.sin(love.timer.getTime()*3)))
	animator.setBone(test.leg2, nil, nil, degree(-20+15*math.sin(love.timer.getTime()*5.6)))
end

function test.draw()
	-- Note: Drawing Pose will overwrite all bone transformations previously applied, as they're fixed within the pose
	--animator.drawPose(test.pose, 400, 400, 0.0, 1.0, 1.0, 1.0)
	-- drawSkeleton updates all bone transformations recursively and draws all images bound to bones of the skeleton
	animator.drawSkeleton(test.skel, 400, 400, 0.0, 1.0, 1.0, 1.0)
	-- draws bone debug triangles
	animator.drawDebugSkeleton(test.skel, 400, 400, 0.0, 1.0, 1.0, 1.0)
end
