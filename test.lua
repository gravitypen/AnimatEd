
require "animator"


test = {}

function testInit()
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
	torso = animator.newBone("Torso", skel); animator.setBone(torso, 0, 0, 0)
		head = animator.newBone("Head", torso); animator.setBone(head, 0, -50, 0)
			animator.newBone("Head 2", head); animator.setBone(torso, 20, -10, 0) 
		-- Left Arm
		arm = animator.newBone("Left Arm", torso); animator.setBone(arm, -40, -30, 30, true)
			arm = animator.newBone("Left Arm 2", arm); animator.setBone(arm, 0, 50, 20)
				arm = animator.newBone("Left Hand", arm); animator.setBone(arm, 0, 35, 0)
		-- Right Arm
		arm = animator.newBone("Right Arm", torso); animator.setBone(arm, 30, -30, -20)
			arm = animator.newBone("Right Arm 2", arm); animator.setBone(arm, 0, 50, -40)
				arm = animator.newBone("Right Hand", arm); animator.setBone(arm, 0, 35, 0)
		-- Left Leg
		leg = animator.newBone("Left Leg", torso); animator.setBone(leg, -25, 30, 15, true)
			leg = animator.newBone("Left Leg 2", leg); animator.setBone(leg, 0, 60, 7)
				leg = animator.newBone("Left Foot", leg); animator.setBone(leg, 0, 50, -20)
		-- Right Leg
		leg = animator.newBone("Right Leg", torso); animator.setBone(leg, 20, 30, -10)
			leg = animator.newBone("Right Leg 2", leg); animator.setBone(leg, 0, 60, 20)
				leg = animator.newBone("Right Foot", leg); animator.setBone(leg, 0, 50, -10)


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
end



function test.draw()

end
