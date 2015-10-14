

animator = {}

function animator.load()
    animator.boneCount = 0
    animator.imgCount = 0
    animator.pi = math.pi
    animator.piTimes2 = math.pi*2.0
    animator.piBy2 = math.pi*0.5
    animator.newestBone = nil
    animator.newestImage = nil
end




-- Skeletons are the basis of bone animations, a skeleton is basically just a set of bones and images with a predefined, static hierarchy
function animator.newSkeleton(name, path)
    local skel = {
        tp="skeleton",
        name=name, 
        projectPath=path, 
        defaultPose = nil,
        animations={},
        boneCount = 0,
        imgCount = 0,
        elementMap = {},
        imageList = {}
    }
    skel.rootChild = animator.newBone("#root", skel)
    animator.refreshImages(skel)
    return skel
end



-- Poses are current configurations of a specific skeleton; they've got a state list, assigning a list of transformations to each bone or image
-- transformation list contains a list of values which will be assigned to an attribute (like x, y, angle, scale..) 
function animator.newPose(skel)
    local pose = {
        skel = skel, 
        state = {}
    }
    for id,element in pairs(skel.elementMap) do
        pose.state[id] = {element.x, element.y, element.angle, element.alpha, element.scaleX, element.scaleY}
    end
    return pose
end



-- Bones are invisible elements of a skeleton and are usually bound to other bones (i.e. have one parent and 0..n children)
-- Bones can be animated using animations and keyframes, affecting position, rotation and alpha
function animator.newBone(name, parent)
    --print("Adding ".. name .. " to " .. parent.name)
    local skel
    if parent.tp ~= "bone" and parent.rootChild then parent = parent.rootChild end
    if parent.tp == "bone" then
        -- Child of other Node
        skel = parent.skel
    else
        -- is Root Node
        skel = parent
    end
    skel.boneCount = skel.boneCount + 1
    -- Create Bone
    local node = {
        tp="bone",
        skel=skel,
        name=name, 
        id="b" .. skel.boneCount,
        parent=parent, 
        images={}, 
        childs={}, 
        drawOverParent = false,
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
        scaleX = 1.0,
        scaleY = 1.0,
        length = 40, --doesn't affect anything, just for editor/debug rendering
        -- base system for children
        baseRx = 1.0, -- "right" vector 
        baseRy = 0.0,
        baseFx = 0.0, -- "forward" vector
        baseFy = 1.0
    }
    if parent.tp == "bone" then parent.childs[#parent.childs+1] = node end
    node.skel.elementMap[node.id] = node
    animator.newestBone = node
    return node
end



-- Images can be attached to bones and are the only part of the skeleton that is drawn within the game
-- Images can be animated as well (position, scale and alpha), offset is initialized as the image's center
-- but doesn't need to be changed, since images themselves are not rotated, but the respective bone they're
-- attached to
function animator.newImage(imgName, bone)
    bone.skel.imgCount = bone.skel.imgCount + 1
    -- Create new instance of existing image as child of Bone
    local img = {
        tp="img",
        name=imgName, 
        id = "i" .. bone.skel.imgCount,
        bone=bone, 
        skel=bone.skel,
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
    print("Added image " .. imgName .. " to " .. bone.name)
    img.skel.elementMap[img.id] = img
    animator.newestImage = img
    return img
end



-- An animation (e.g. "run", "idle", "attack", ...) defines the transformations for a skeleton within a certain fixed
-- time frame; it contains a list of keyframes, each of which influences one or more attributes of a bone at a
-- certain point in time
function animator.newAnimation(name, skel, duration)
    local ani = {
        tp="ani",
        name = name,
        skel = skel,
        duration = duration or 1.0,
        keyframes = {}        
    }
    -- Keyframe List per Bone and Image Instance
    for id,element in pairs(skel.elementMap) do
        ani.keyframes[id] = {
            affects = {false, false, false, false, false, false} -- denotes, which attributes the keyframes of an animation affect (x, y, angle, alpha, xsc, ysc)
        }
    end
    return ani
end



-- Keyframes are part of an animation and bound to a single bone, they're used to animate one or more 
-- attributes of that bone; when using nil values for attributes, they are ignored in this keyframe and
-- instead interpolated between different, appropriate keyframes
function animator.newKeyframe(ani, p, elementID, interpolation, xpos, ypos, angle, xscale, yscale, alpha)
    interpolation = interpolation or "linear"
    local element = nil
    if type(elementID) == "string" then
        element = ani.skel.elementMap[elementID]
    else
        element = elementID
        elementID = element.id
    end
    local keyframe = {
        tp="keyframe",
        ani = ani,
        p = p,
        elementID = elementID,
        element = element,
        interpolation = interpolation,
        x = xpos,
        y = ypos,
        angle = angle,
        xscale = xscale,
        yscale = yscale,
        alpha = alpha
    }
    -- list format: {element.x, element.y, element.angle, element.alpha, element.scaleX, element.scaleY}
    keyframe[1] = xpos
    keyframe[2] = ypos
    keyframe[3] = angle
    keyframe[4] = alpha
    keyframe[5] = xscale
    keyframe[6] = yscale
    -- Tell Bone related Keyframe list which attributes the animation affects
    local list = ani.keyframes[elementID]
    if xpos then list.affects[1] = true end
    if ypos then list.affects[2] = true end
    if angle then list.affects[3] = true end
    if alpha then list.affects[4] = true end
    if xscale then list.affects[5] = true end
    if yscale then list.affects[6] = true end
    -- Apply to Ani
    ani.keyframes[elementID][#ani.keyframes[elementID] + 1] = keyframe
    print("Added keyframe to ani, bone " .. elementID .. " now has " .. #ani.keyframes[elementID] .. " new one included")
    animator.sortKeyframes(ani, elementID)
    return keyframe
end










-- Checks the images folder within the skeleton's assigned directory and reloads any images that weren't
-- previously loaded
function animator.refreshImages(skel)
    if true then return end -- integrate love file system and replace getListOfFiles with something appropriate
    local files = getListOfFiles(skel.projectPath .. "/images")
    for i = 1,#files do
        local file = string.lower(files[i]) 
        if not skel.imageList[file] then
            local ext = string.sub(file, -4)
            if ext == ".png" or ext == ".jpg" or ext == ".bmp" then
                animator.addImageFile(skel, file)
            end
        end
    end
end

-- adds a single image file to the skeleton's image list and loads it
function animator.addImageFile(skel, file)
    local fullPath = skel.projectPath .. "/images/" .. file
    skel.imageList[file] = love.graphics.newImage(fullPath)
    print("Loaded image '" .. file .. "' from " .. fullPath)
end 



function animator.setPoseBone(pose, bone, x, y, angle, alpha)
    -- list format: {element.x, element.y, element.angle, element.alpha, element.scaleX, element.scaleY}
    local list = pose.state[bone.id]
    if x then list[1] = x end
    if y then list[2] = y end
    if angle then list[3] = angle end
    if alpha then list[4] = alpha end
end

function animator.setPoseImage(pose, image, x, y, angle, scx, scy, alpha) 
    local list = pose.state[image.id]
    if x then list[1] = x end
    if y then list[2] = y end
    if angle then list[3] = angle end
    if alpha then list[4] = alpha end
    if scx then list[5] = scx end
    if scy == true then scy = scx end
    if scy then list[6] = scy end
end

function animator.setBone(bone, x, y, angle, drawOverParent)
    if not bone then bone = animator.newestBone end
    if x then bone.x = x end
    if y then bone.y = y end
    if angle then bone.angle = angle end
    if drawOverParent ~= nil then bone.drawOverParent = drawOverParent end
end

function animator.setImage(img, x, y, angle, scx, scy)
    if not img then img = animator.newestImage end
    if x then img.x = x end
    if y then img.y = y end
    if angle then img.angle = angle end
    if scx then img.scaleX = scx end
    if scy == true then scy = scx end
    if scy then img.scaleY = scy end
end 


-- Sorts keyframes of a bone or image according to their position within the timeline
function animator.sortKeyframes(ani, id)
    local list = ani.keyframes[id]
    table.sort(list, function(a,b) return a.p < b.p end)
end

function animator.getBoneByName(skel, name)
    for id,element in pairs(skel.elementMap) do
        if element.name == name then return element end
    end
    return nil
end









-- Applies an animation with a given timestamp to a pose
function animator.applyAnimation(pose, ani, p)

    function getState(keyframes, attr)
        local affectingKeyframes = {}
        -- Find subset of keyframes that influence current attribute
        for i = 1,#keyframes do
            if keyframes[i][attr] ~= nil then affectingKeyframes[#affectingKeyframes + 1] = keyframes[i] end
        end
        if love.keyboard.isDown("lctrl") then print("  " .. attr .. "-affecting Keyframes: " .. #affectingKeyframes) end
        -- Blend between affecting keyframes
        if #affectingKeyframes <= 1 then
            -- exactly one keyframe -> apply attribute
            if #affectingKeyframes == 1 then
                return affectingKeyframes[1][attr]
            end
        else
            -- multiple keyframes -> find those that surround p
            local iR = 0
            for i = 1,#affectingKeyframes do
                if affectingKeyframes[i].p >= p then iR = i; break end
            end
            local iL
            if iR == 0 then 
                -- p > highest p of all affecting keyframes -> take rightmost keyframe
                iR = #affectingKeyframes
                iL = iR
            else
                -- suitable index found
                iL = iR - 1
                if iL < 1 then iL = 1 end --avoid out of bounds error
            end
            -- Interpolate
            if iL == iR then
                -- no interpolation required
                return affectingKeyframe[iL][attr]
            else
                -- Interpolate between both keyframes
                local blend = (p - affectingKeyframes[iL].p)/(affectingKeyframes[iR].p - affectingKeyframes[iL].p)
                return animator.interpolate(affectingKeyframes[iL].interpolation, affectingKeyframes[iL][attr], affectingKeyframes[iR][attr], blend)
            end
        end
        -- no keyframe at all that influences attribute -> don't change attribute
        return nil
    end

    -- Apply Animation based on keyframes
    function applyToPose(element)
        local keyframes = ani.keyframes[element.id]
        -- Apply all attributes
        local poseState = pose.state[element.id]
        if love.keyboard.isDown("lctrl") then print("\nUpdating element " .. element.id .. " with " .. #poseState .. " attributes, keyframes: " .. #keyframes) end
        for i = 1,#poseState do
            local newValue = getState(keyframes, i)
            if newValue ~= nil then poseState[i] = newValue; end
        end  
    end

    -- Call apply function for all bones and images
    for id,element in pairs(ani.skel.elementMap) do
        applyToPose(element)
    end

    -- Return
    return pose
end

function animator.interpolate(interpolation, v1, v2, p)
    local v = v1
    if type(interpolation) == "string" then
        -- one of several templates
        if interpolation == "step" then
            v = (p < 0.5) and v1 or v2
        elseif interpolation == "floor" then
            v = (p < 1.0) and v1 or v2
        elseif interpolation == "linear" then
            v = p*v2 + (1.0-p)*v1
        elseif interpolation == "cos" then
            p = 0.5 - 0.5*math.cos(math.pi*p)
            v = p*v2 + (1.0-p)*v1
        elseif interpolation == "cos2" then
            p = 0.5 - 0.5*math.cos(math.pi*p)
            p = 0.5 - 0.5*math.cos(math.pi*p)
            v = p*v2 + (1.0-p)*v1
        elseif interpolation == "sqr" then
            p = p*p
            v = p*v2 + (1.0-p)*v1
        elseif interpolation == "sqrt" then
            p = math.sqrt(p)
            v = p*v2 + (1.0-p)*v1
        elseif interpolation == "sphere" then
            p = math.sqrt(2*p - p*p)
            v = p*v2 + (1.0-p)*v1
        elseif interpolation == "invsphere" then
            p = 1.0 - math.sqrt(1 - p*p)
            v = p*v2 + (1.0-p)*v1
        end        
    else
        -- custom interpolation (using curveEditor)
        v = curveEditor.interpolate(p, {interpolation[1], interpolation[2]}, {interpolation[3], interpolation[4]})
    end
    return v
end







-- Draws a skeleton with the given pose and transformations
function animator.drawPose(pose, x, y, angle, scalex, scaley, alpha)
    animator.applyPose(pose)
    animator.drawSkeleton(pose.skel, x, y, angle, scalex, scaley, alpha)
end

-- Applies a given pose to its skeleton by applying all bones
function animator.applyPose(pose)
    for id,element in pairs(pose.skel.elementMap) do
        -- values stored this way: {element.x, element.y, element.angle, element.alpha, element.scaleX, element.scaleY}
        local values = pose.state[id]
        if element.tp == "bone" then
            -- Bone
            element.x = values[1]
            element.y = values[2]
            element.angle = values[3]
            element.alpha = values[4]
        else
            -- Image
            element.x = values[1]
            element.y = values[2]
            element.angle = values[3]
            element.alpha = values[4]
            element.scaleX = values[5]
            element.scaleY = values[6]
        end
    end
end

-- Draws the skeleton with given transformations in its current state -- usually you should call drawPose instead
-- as poses describe a well defined state the skeleton is in
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
    local bx = scalex
    local by = scaley
    local c = math.cos(-angle)
    local s = math.sin(-angle)
    bone.baseRx = scalex * c
    bone.baseRy = -scalex * s
    bone.baseFx = scaley * s
    bone.baseFy = -scaley * c
    -- Recursive Drawing
    for i = 1,#bone.childs do
        animator.drawBone(bone.childs[i])
    end
end

function animator.updateBone(bone)
    -- Update values
    local p = bone.parent
    bone.__x = p.__x + bone.x * p.baseRx + bone.y * p.baseFx
    bone.__y = p.__y + bone.x * p.baseRy + bone.y * p.baseFy
    bone.__angle = p.__angle + bone.angle
    bone.__alpha = p.__alpha * bone.alpha
    bone.__scX = p.__scX * bone.scaleX
    bone.__scY = p.__scY * bone.scaleY
    -- Rotate Base
    local s = math.sin(bone.angle)
    local c = math.cos(bone.angle)
    bone.baseRx = bone.scaleX * (c * p.baseRx - s * p.baseRy)
    bone.baseRy = bone.scaleX * (s * p.baseRx + c * p.baseRy)
    bone.baseFx = bone.scaleY * (c * p.baseFx - s * p.baseFy)
    bone.baseFy = bone.scaleY * (s * p.baseFx + c * p.baseFy)
end

-- called by animator.drawSkeleton, should not be called manually
function animator.drawBone(bone)
    -- Update Transformations
    animator.updateBone(bone)
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


-- called by animator.drawSkeleton, should not be called manually
function animator.drawImage(img)
    -- Update
    local image = img.skel.imageList[img.name]
    local bone = img.bone
    -- Draw
    love.graphics.setColor(255,255,255, 255*bone.__alpha * img.alpha)
    love.graphics.draw(
        image, 
        bone.__x + img.x * bone.baseRx + img.y * bone.baseFx, 
        bone.__y + img.x * bone.baseRy + img.y * bone.baseFy, 
        bone.__angle + img.angle, 
        img.scaleX*bone.__scX, 
        img.scaleY*bone.__scY, 
        img.offX * image:getWidth(), 
        img.offY * image:getHeight()
    )
end


-- always call animator.drawSkeleton() (or drawPose()) beforehand to make sure all bone transformations are
-- updated and propagated accordingly!
function animator.drawDebugSkeleton(skel)
    local bone = skel.rootChild
    -- Recursive Drawing
    for i = 1,#bone.childs do
        animator.drawDebugBone(bone.childs[i])
    end
end

function animator.drawDebugBone(bone)
    -- Children  
    for i = 1,#bone.childs do
        animator.drawDebugBone(bone.childs[i])
    end
    -- Itself
    --print("Drawing " .. bone.name .. " to " .. bone.__x .. "," .. bone.__y)
    animator.drawDebugTriangle(bone.__x, bone.__y, bone.__angle, bone.length)
end

function animator.drawDebugTriangle(x, y, angle, length)
    local angle2 = angle + animator.piBy2
    local length2 = 4
    -- Get Triangle Coordinates
    local x1,y1 = x + length2*math.sin(angle2), y - length2*math.cos(angle2)
    local x2,y2 = 2*x-x1, 2*y-y1
    local x3,y3 = x + length*math.sin(angle), y - length*math.cos(angle)
    -- Draw Triangle
    love.graphics.setColor(0,255,0,128)
    love.graphics.polygon("line", x1,y1, x2,y2, x3,y3)
end
