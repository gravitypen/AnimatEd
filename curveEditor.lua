do
    curveEditor = {}
   
    function curveEditor.init()
        curveEditor.colors = {
            borderColor = {180, 180, 180},
            backgroundColor = {20, 20, 20},
            markerColor = {200, 230, 200},
            lineColor = {180, 220, 180},
        }
       
        curveEditor.position = {100, 100}
        curveEditor.size = {500, 400}
        curveEditor.markerRadius = 10
        curveEditor.graphSamples = 100
       
        curveEditor.startMarker = {0.2, 0.2}
        curveEditor.endMarker = {0.8, 0.8}
    end
   
    local function markerToWorld(marker)  
        return  (0.0 + marker[1]) * curveEditor.size[1] + curveEditor.position[1],
                (1.0 - marker[2]) * curveEditor.size[2] + curveEditor.position[2]
    end
   
    local function hoveringMarker(mx, my, marker)
        local markerX, markerY = markerToWorld(marker)
        local relX, relY = mx - markerX, my - markerY
        return relX*relX + relY*relY <= curveEditor.markerRadius*curveEditor.markerRadius
    end
   
    local function bezierX(t, startVel, endVel)
        local invT = 1.0 - t
        return 0.0 + startVel[1] * 3.0 * invT*invT*t + endVel[1] * 3.0 * invT*t*t + 1.0 * t*t*t
    end
   
    local function bezierY(t, startVel, endVel)
        local invT = 1.0 - t
        return 0.0 + startVel[2] * 3.0 * invT*invT*t + endVel[2] * 3.0 * invT*t*t + 1.0 * t*t*t
    end
   
    local function bezierXDel(t, startVel, endVel)
        local invT = 1.0 - t
        return startVel[1] * 3.0 * (1 - 4*t + 3*t*t) + endVel[1] * 3.0 * (2*t - 3*t*t) + 1.0 * 3*t*t
    end
   
    local function interpolate(t, startVel, endVel)
        local out = t
        for i = 1, 15 do
            out = out - (bezierX(out, startVel, endVel) - t) / bezierXDel(out, startVel, endVel)
        end
        return bezierY(out, startVel, endVel)
    end
   
    function curveEditor.draw()
        love.graphics.setColor(curveEditor.colors.backgroundColor)
        love.graphics.rectangle("fill", curveEditor.position[1], curveEditor.position[2], curveEditor.size[1], curveEditor.size[2])
       
        love.graphics.setColor(curveEditor.colors.borderColor)
        love.graphics.rectangle("line", curveEditor.position[1], curveEditor.position[2], curveEditor.size[1], curveEditor.size[2])
       
        -- draw grid?
       
        -- draw graph
        local function draw01Line(fromx, fromy, tox, toy)
            love.graphics.line(curveEditor.position[1] + curveEditor.size[1] * fromx, curveEditor.position[2] + curveEditor.size[2] * (1.0 - fromy),
                               curveEditor.position[1] + curveEditor.size[1] * tox,   curveEditor.position[2] + curveEditor.size[2] * (1.0 - toy))
        end
       
        local lastV = 0.0
        for i = 1, curveEditor.graphSamples - 1 do
            local t = i / (curveEditor.graphSamples - 1)
            local startT = (i-1) / (curveEditor.graphSamples - 1)
            local v = interpolate(t, curveEditor.startMarker, curveEditor.endMarker)
            love.graphics.setColor(curveEditor.colors.lineColor)
            draw01Line(startT, lastV, t, v)
            love.graphics.setColor(50, 50, 50)
            --draw01Line(bezierX(startT, curveEditor.startMarker, curveEditor.endMarker), bezierY(startT, curveEditor.startMarker, curveEditor.endMarker),
            --           bezierX(t, curveEditor.startMarker, curveEditor.endMarker),      bezierY(t, curveEditor.startMarker, curveEditor.endMarker))
            --draw01Line(startT, bezierX(startT, curveEditor.startMarker, curveEditor.endMarker),
            --           t,      bezierX(t, curveEditor.startMarker, curveEditor.endMarker))
            lastV = v
        end
       
        love.graphics.setColor(curveEditor.colors.markerColor)
        local startMarkerX, startMarkerY = markerToWorld(curveEditor.startMarker)
        love.graphics.circle("line", startMarkerX, startMarkerY, curveEditor.markerRadius, 12)
        local endMarkerX, endMarkerY = markerToWorld(curveEditor.endMarker)
        love.graphics.circle("line", endMarkerX, endMarkerY, curveEditor.markerRadius, 12)
       
        love.graphics.line(curveEditor.position[1], curveEditor.position[2] + curveEditor.size[2], startMarkerX, startMarkerY)
        love.graphics.line(curveEditor.position[1] + curveEditor.size[1], curveEditor.position[2], endMarkerX, endMarkerY)
    end
   
    function curveEditor.mousepressed(x, y, button)
        if button == "l" then
            local lx, ly = x - curveEditor.position[1], y - curveEditor.position[2]
            if true or lx > 0 and lx < curveEditor.size[1] and ly > 0 and ly < curveEditor.size[2] then
                if hoveringMarker(x, y, curveEditor.startMarker) then
                    curveEditor.dragging = curveEditor.startMarker
                end
               
                if hoveringMarker(x, y, curveEditor.endMarker) then
                    curveEditor.dragging = curveEditor.endMarker
                end
            end
        end
    end
       
    function curveEditor.mousemoved(x, y, dx, dy)
        if curveEditor.dragging then
            curveEditor.dragging[1] = curveEditor.dragging[1] + dx / curveEditor.size[1]
            curveEditor.dragging[2] = curveEditor.dragging[2] - dy / curveEditor.size[2]
            if curveEditor.dragging[1] < 0.0 then curveEditor.dragging[1] = 0.0 end
            if curveEditor.dragging[1] > 1.0 then curveEditor.dragging[1] = 1.0 end
        end
    end
   
    function curveEditor.mousereleased(x, y, button)
        if button == "l" then curveEditor.dragging = nil end
    end
end
 
 