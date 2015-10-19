
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
    test.init()
    states.load()
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


