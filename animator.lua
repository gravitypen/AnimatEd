

animator = {}

function animator.load()
    animator.boneCount = 0
    animator.imgCount = 0
    animator.boneMap = {}
    animator.imgMap = {}
    animator.elementMap = {}
end


function animator.newSkeleton(name, path)
    local skel = {
        tp="skeleton",
        name=name, 
        projectPath=path, 
        animations={}
    }
    skel.rootChild = animator.newBone("#root", skel)
    return skel
end

function animator.newPose(skel)

end

function animator.newBone(name, parent)
    animator.boneCount = animator.boneCount + 1
    -- Create Bone
    local node = {
        tp="bone",
        name=name, 
        id="b" .. animator.boneCount,
        parent=parent, 
        images={}, 
        childs={}, 
        drawOverParent = true,
        -- stored values
        __x = 0, -- absolute position after applying (x,y) to base values provided by parent
        __y = 0,
        __angle = 0,
        __alpha = 1.0,
        __scX = 0,
        __scY = 0,
        -- values influencing own appearance as well as children
        x=0, -- relative position to parent based on base system provided by parent 
        y=0, 
        alpha = 1.0,
        angle = 0,
        -- base system for children
        baseDX = 1.0, 
        baseDY = 1.0
    }
    if parent.tp == "bone" then
        -- Child of other Node
        parent.childs[#parent.childs+1] = node
        node.skel = parent.skel
    else
        -- is Root Node
        node.skel = parent
    end
    animator.boneMap[node.id] = node
    animator.elementMap[node.id] = node
    return node
end

function animator.newImage(imgName, bone)
    animator.imgCount = animator.imgCount + 1
    -- Create new instance of existing image as child of Bone
    local img = {
        tp="img",
        name=imgName, 
        id = "i" .. animator.imgCount
        bone=bone, 
        scaleX=1.0, 
        scaleY=1.0, 
        x = 0,
        y = 0,
        offX = 0.5, 
        offY = 0.5,
        angle = 0,
        alpha = 1.0
    }
    -- Append to bone
    bone.images[#bone.images+1] = img
    animator.imgMap[img.id] = img
    animator.elementMap[img.id] = img
    return img
end

function animator.newAnimation(name, skel)
    local ani = {
        tp="ani",
        name = name,
        skeleton = skel,
        duration = 1.0,
        keyframes = {}
    }
    -- Keyframe List per Bone and Image Instance
    for b = 1,#skel.bones do
        keyframes[skel.bones[b].id] = {}
        for i = 1,#skell.bones[b].images do
            keyframes[skell.bones[b].images[i].id] = {}
        end
    end
    return ani
end

function animator.newKeyframe(ani, p, elementID, xpos, ypos, angle, xscale, yscale, alpha)
    local keyframe = {
        tp="keyframe",
        ani = ani,
        p = p,
        elementID = elementID,
        element = animator.elementMap[elementID],
        x = xpos,
        y = ypos,
        angle = angle,
        xscale = xscale,
        yscale = yscale,
        alpha = alpha
    }
    -- Apply to Ani
    ani.keyframes[elementID][#ani.keyframes[elementID] + 1] = keyframe
    animator.sortKeyframes(elementID)
    return keyframe
end

-- Sorts keyframes of a bone or image according to their position within the timeline
function ani.sortKeyframes(id)
    local list = ani.keyframes[id]
    table.sort(list, function(a,b) return a.p < b.p end)
end


function animator.getTimedPose(ani, p)
    -- Create new Pose to store bone and image transformations
    local pose = animator.newPose(ani.skeleton)
    -- Apply Animation based on keyframes
    function applyToPose(element)
        local keyframes = ani.keyframes[element.id]
        -- Find near keyframes
        if #keyframes == 0 then
            -- this bone is not animated
        elseif #keyframes == 1 then
        else
        end    
    end
    -- Call apply function for all bones and images
    for _,bone in ipairs(ani.skeleton.bones) do
        applyToPose(bone)
        for i = 1,#bone.images do
            applyToPose(bone.images[i])
        end
    end
    -- Return
    return pose
end


function animator.drawSkeleton(skel, x, y, angle, scalex, scaley, alpha)
    -- Default Values
    angle = angle or 0
    scalex = scalex or 1
    scaley = scaley or scalex
    alpha = alpha or 1
    -- Apply Values
    local bone = skel.rootChild
    bone.__x = x
    bone.__y = y
    bone.__angle = angle
    bone.__alpha = alpha
    bone.__scX = scalex
    bone.__scY = scaley
    bone.baseDX = scalex * math.cos(angle) - scaley * math.sin(angle)
    bone.baseDY = scalex * math.sin(angle) + scaley * math.cos(angle)
    -- Recursive Drawing
    for i = 1,#bone.childs do
        animator.drawBone(bone.childs[i])
    end
end

function animator.drawBone(bone)
    -- Update values
    local p = bone.parent
    bone.__x = p.__x + bone.x * p.baseDX
    bone.__y = p.__y + bone.y * p.baseDY
    bone.__angle = p.__angle + bone.angle
    bone.__alpha = p.__alpha * bone.alpha
    bone.__scX = p.__scX
    bone.__scY = p.__scY
    -- Rotate Base
    local s = math.sin(bone.angle)
    local c = math.cos(bone.angle)
    bone.baseDX = c * p.baseDX - s * p.baseDY
    bone.baseDY = s * p.baseDX + c * p.baseDY
    -- Children under bone    
    for i = 1,#bone.childs do
        if not bone.childs[i].drawOverParent then animator.drawBone(bone.childs[i]) end
    end
    -- Itself
    for i = 1,#bone.images do
        animator.drawImage(bone.images[i])
    end
    -- Children over bone
    for i = 1,#bone.childs do
        if bone.childs[i].drawOverParent then animator.drawBone(bone.childs[i]) end
    end
end

function animator.drawImage(img)
    -- Update
    local image = animator.imageList[img.name].image
    local bone = img.bone
    -- Draw
    love.graphics.setColor(255,255,255, 255*bone.__alpha * img.alpha)
    love.graphics.draw(
        image, 
        bone.__x + img.x * bone.baseDX, 
        bone.__y + img.y * bone.baseDY, 
        bone.__angle + img.angle, 
        img.scaleX*bone.__scX, 
        img.scaleY*bone.__scY, 
        img.offX * image:getWidth(), 
        img.offY * image:getHeight()
    )
end






