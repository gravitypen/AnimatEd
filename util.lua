



function getAngle(dx, dy)
    if (dy == 0) then
        if dx < 0 then return math.pi*0.5 else return -math.pi*0.5 end
    else
        if dy > 0 then
            return math.atan(dx/dy) + math.pi
        else
            return math.atan(dx/dy)
        end
    end
end


function mouseInBox(x1,y1,x2,y2)
	return (states.mouse.x >= x1 and states.mouse.x <= x2 and states.mouse.y >= y1 and states.mouse.y <= y2)
end



function button(x,y,w,h, caption)
    x1 = x - w/2
    y1 = y - h/2
    x2 = x1 + w
    y2 = y1 + h
    alpha = 80
    r = false
    off = -5
    -- Interact
    if mouseInBox(x1,y1,x2,y2) then
        if states.mouse.leftclick == 2 then
            r = true
            off = 1
        else
            alpha = 120
        end
    end
    -- Draw Button
    love.graphics.setColor(0,0,0,alpha)
    love.graphics.rectangle("fill", x1,y1,w,h)
    love.graphics.setColor(255,255,255,255)
    love.graphics.rectangle("line", x1,y1,w,h)
    -- Draw Caption
    love.graphics.printf(caption, x1, y - off - 14, w-8, "center")
    -- Return
    return r
end






textInputHandler = {
    active = false,
    caption = "",
    s = "",
    callback = nil,
    checkChar = nil,
}

function updateTextInput(t)
    if textInputHandler.active then
        -- Update
        appendTextInput(t)
        -- Denote that update is in progress and other input updates should not be executed
        return true
    end
    return false
end

function appendTextInput(t)
    for i = 1,#t do
        local s = string.sub(t,i,i)
        if not textInputHandler.checkChar or textInputHandler.checkChar(s, textInputHandler.s) then
            textInputHandler.s = textInputHandler.s .. s
        end
    end
end

function handleTextInputKeypress(key)
    if not textInputHandler.active then return end
    if key == "backspace" then
        -- Backspace - delete last character
        textInputHandler.s = string.sub(textInputHandler.s, 1, string.len(textInputHandler.s) - 1)
    elseif key == "return" then
        -- Enter - apply
        textInputHandler.active = false
        love.keyboard.setTextInput(false)
        if textInputHandler.callback then textInputHandler.callback(textInputHandler.s) end
    elseif key == "esc" then
        textInputHandler.active = false
        love.keyboard.setTextInput(false)
        if textInputHandler.cancelCallback then textInputHandler.cancelCallback() end
    elseif key == "v" then
        if love.keyboard.isDown("lctrl") then
            appendTextInput(love.system.getClipboardText())
        end
    end
end

function drawTextInput()
    if textInputHandler.active then
        -- Draw Back
        local x = states.windowW/2
        local y = states.windowH/2
        local w2 = 200
        local w = w2*2
        local h = 100
        local x1 = x-w2
        local y1 = y-h
        local x2=x+w2
        local y2=y
        love.graphics.setColor(255,255,255,255)
        love.graphics.rectangle("fill", x1,y1,w,h)
        love.graphics.setColor(30,30,30,255)
        love.graphics.rectangle("fill", x1+1,y1+1,w-2,h-2)
        -- Draw Caption
        love.graphics.setColor(255,255,255,180)
        love.graphics.print(textInputHandler.caption, x1+10, y1+10)
        love.graphics.print("Chars: " .. string.len(textInputHandler.s), x2-60, y1+10)
        -- Draw Text
        love.graphics.setColor(255,255,255,255)
        love.graphics.print(">" .. textInputHandler.s, x1+16, y1+45)
    end
end



function textInput(caption, s, callback, cancelCallback, checkChar)
    textInputHandler.active = true
    textInputHandler.s = s
    textInputHandler.caption = caption
    textInputHandler.callback = callback
    textInputHandler.cancelCallback = cancelCallback 
    textInputHandler.checkChar = checkChar
    love.keyboard.setTextInput(true)
end

function numberInput(caption, s, callback, cancelCallback)
    textInput(caption, s, function(s) callback(tonumber(s)) end, cancelCallback, 
        function(c,s) 
            if c == "-" and string.len(s) <= 0 then return true
            elseif c == "." and not string.find(s,"%.") then return true
            else
                if c == "1" or c == "2" or c == "3" or c == "4" or c == "5" or c == "6" or c == "7" or c == "8" or c == "9" or c == "0" then return true end
            end
            return false
        end
    )
end




dialogHandler = {
    active = false,
    caption = "",
    buttons = {},
}

function questionDialog(caption, yesCallback, noCallback) 
    dialogHandler.active = true
    dialogHandler.caption = caption
    dialogHandler.buttons = {
        {caption = "Yes", callback = yesCallback, row = 1},
        {caption = "No", callback = noCallback, row = 1},
    }
end

function createDialog(caption, buttons)
    dialogHandler.active = true
    dialogHandler.caption = caption
    dialogHandler.buttons = buttons
end

function infoDialog(caption)
    dialogHandler.active = true
    dialogHandler.caption = caption
    dialogHandler.buttons = { {caption = "OK", callback = nil, row = 1 }}
end

function drawDialog()
    if dialogHandler.active then
        local oldMouse = states.mouse
        states.mouse = states.activeMouse
        local w = 450
        local h = 80 + 40*dialogHandler.buttons[#dialogHandler.buttons].row        
        -- Draw Back
        local x = states.windowW/2
        local y = states.windowH/2 - 50
        local w2 = w/2
        local x1 = x-w2
        local y1 = y-h/2
        local x2=x1+w
        local y2=y1+h
        love.graphics.setColor(255,255,255,255)
        love.graphics.rectangle("fill", x1,y1,w,h)
        love.graphics.setColor(30,30,30,255)
        love.graphics.rectangle("fill", x1+1,y1+1,w-2,h-2)
        -- Draw Caption
        love.graphics.setColor(255,255,255,180)
        love.graphics.print(dialogHandler.caption, x1+30, y1+28)
        -- Draw Buttons
        local btnW = 100
        local btnSpace = 140
        local btnH = 25
        local btn = 1
        while btn <= #dialogHandler.buttons do
            -- find all buttons for this row
            local btnTo = btn+1
            while btnTo <= #dialogHandler.buttons and dialogHandler.buttons[btnTo].row == dialogHandler.buttons[btn].row do
                btnTo = btnTo + 1
            end
            -- Draw them
            btnTo = btnTo - 1            
            local btnsInRow = btnTo - btn + 1
            local off = -btnSpace*(btnsInRow - 1)/2
            local by = y1 + 55 + 40*dialogHandler.buttons[btn].row
            for b = btn,btnTo do
                local bx = x + off + btnSpace * (b-btn)
                if button(bx, by, btnW, btnH, dialogHandler.buttons[b].caption) then
                    if dialogHandler.buttons[b].callback then 
                        dialogHandler.buttons[b].callback()
                    end
                    -- Close Dialog
                    dialogHandler.active = false
                    states.mouse = oldMouse
                    return
                end
            end
            -- Proceed
            btn = btnTo + 1
        end
        states.mouse = oldMouse
    end
end


wrapAngle_pi2 = 2.0*math.pi
wrapAngle_pi2Inverted = 1.0/(2.0*math.pi)

function wrapAngle(a)
    a = a - wrapAngle_pi2*math.floor(a*wrapAngle_pi2Inverted)
    return a
end




function writeTable(file, tbl, depth)
    local function write(key, value)
        local kType = type(key)
        local vType = type(value)
        if (kType == "number" or (kType == "string" and key:sub(1,2) ~= "__")) and
           (vType == "table" or vType == "string" or vType == "boolean" or vType == "number") then
                if kType == "string" then
                        file:write(string.rep("\t", depth) .. '["' .. key .. '"] = ')
                elseif kType == "number" then
                        file:write(string.rep("\t", depth))
                end

                if vType == "table" then
                    file:write("{\n")
                    writeTable(file, value, depth + 1)
                    file:write(string.rep("\t", depth) .. "},\n")
                elseif vType == "string" then
                        file:write('"' .. value .. '",\n')
                elseif vType == "boolean" or vType == "number" then
                        file:write(tostring(value) .. ",\n")
                end                               
        end
    end


    if tbl.saveList then
        -- only save list
        for i = 1,#tbl.saveList do
            local key = tbl.saveList[i]
            local value = tbl[key]
            write(key, value)
        end
    else
        -- full table
        for key, value in pairs(tbl) do
            write(key, value)
        end
    end

end

function loadTable(path)
    f, err = loadfile(path)
    if f == nil then 
        print("Error while opening/parsing file: " .. tostring(err))
    else 
        print("Loading table from " .. path)
        local fileTable = f()
        return fileTable
    end
    return nil
end

function applyTable(src, trg)
    for key, value in pairs(src) do
        trg[key] = value
    end
end