
require "animator"
require "animatorBlender"
require "curveEditor"
require "test"
require "conf"
require "treeview"
require "editor"
require "util"

require "states"
require "skeletonState"
require "animationsState"
require "animationState"


function love.load()
    curveEditor.init()
    animator.load()
    skeletonState.load()
    skeletonState.loadSkeletons()
    test.init()
    states.load()
    loadGrid()
    --love.graphics.setFont(24)
end


function love.mousepressed(x, y, button)
    curveEditor.mousepressed(x, y, button)
    states.mousepressed(x,y,button)
end
 
function love.mousemoved(x, y, dx, dy)
    curveEditor.mousemoved(x, y, dx, dy)
end
 
function love.mousereleased(x, y, button)
    curveEditor.mousereleased(x, y, button)
end

function love.keypressed(key)
    states.keypressed(key)
    handleTextInputKeypress(key)
end

function love.textinput(t)
    updateTextInput(t)
end



function love.draw()
    states.draw()
    drawTextInput()
    drawDialog()
    while love.keyboard.isDown("q") do
    end
end


function love.update(td)
	treeviewHandler.updateInput()
    blender.updateTime(td)
	states.update()
end




function clamp(v, min, max)
	if v < min then v = min elseif v > max then v = max end
	return v
end




printIndentation = 0
function printOut(s, changeIndent)
    if changeIndent and changeIndent < 0 then
        printIndentation = printIndentation + changeIndent
    end
    if s then
        local out = ""
        for i = 1,clamp(printIndentation,0,12) do
            out = out .. "  "
        end
        print(out .. s)
    else
        -- call printOut() to reset indentation
        if not changeIndent then printIndentation = 0 end
    end
    if changeIndent and changeIndent > 0 then 
        printIndentation = printIndentation + changeIndent
    end
end




function loadGrid()
    gridShader = love.graphics.newShader([[
        uniform float cameraScale;
        uniform vec2 cameraPos;
        uniform float spacing = 100.0;
        uniform vec4 gridColor = vec4(0.7, 0.7, 0.7, 1.0); 

        const float thickness = 1.0;
        //const float smoothness = 2.0;

        float gridFunc(float coord, float thickness) {
            return 1.0 - step(1.0/spacing*thickness, coord);
            //return smoothstep(highEdge - 1.0/spacing*smoothness, highEdge, coord);
        }

        vec4 effect(vec4 color, Image texture, vec2 textureCoords, vec2 screenCoords) {
            vec2 realCoords = (screenCoords + cameraPos * cameraScale * vec2(1.0, -1.0)) / spacing / cameraScale;
            float gridVal = gridFunc(fract(realCoords.x), thickness/cameraScale) + gridFunc(fract(realCoords.y), thickness/cameraScale);
            float originMarkerFactor = 1.5;
            gridVal += gridFunc(abs(realCoords.x), thickness*originMarkerFactor/cameraScale) + gridFunc(abs(realCoords.y), thickness*originMarkerFactor/cameraScale);
            return mix(vec4(0.0), gridColor, vec4(clamp(gridVal, 0.0, 1.0)));
        }
    ]])
end

function drawGrid(x, y, scale)
    local bgColor = editor.backColor
    local gridColor = {0,0,0,128}
    local spacing = 1
    while scale*spacing <= 16 do spacing = spacing * 4 end
    love.graphics.setColor(bgColor)
    love.graphics.rectangle("fill", 0, 0, states.windowW, states.windowH)
    love.graphics.setShader(gridShader)
    gridShader:send("cameraScale", scale or 1.0)
    local sx, sy = x - love.window.getWidth()/2/scale, y + love.window.getHeight()/2/scale
    gridShader:send("cameraPos", {sx, sy})
    -- fine grid
    gridShader:send("gridColor", {0,0,0,0.25})
    gridShader:send("spacing", 16)
    love.graphics.rectangle("fill", 0, 0, love.window.getWidth(), love.window.getHeight())
    -- sparse grid
    gridShader:send("gridColor", {0,0,0,0.75})
    gridShader:send("spacing", 80)
    love.graphics.rectangle("fill", 0, 0, love.window.getWidth(), love.window.getHeight())
    -- x & y axis
    sx = states.windowW/2 - x*scale
    sy = states.windowH/2 - y*scale
    love.graphics.setShader()
    love.graphics.setColor(0,0,0,255)
    love.graphics.rectangle("fill", 0, sy-2, states.windowW, 4)
    love.graphics.rectangle("fill", sx-2, 0, 4, states.windowH)
end