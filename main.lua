
require "animator"
require "animatorBlender"
require "curveEditor"
require "test"
require "conf"
require "treeview"
require "editor"

require "states"
require "skeletonState"
require "animationsState"
require "animationState"


function love.load()
    curveEditor.init()
    animator.load()
    test.init()
    states.load()
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

end




function love.draw()
    --curveEditor.draw()
    states.draw()
    --test.draw()
end




function love.update(td)
	treeviewHandler.updateInput()
	states.update()
	test.update(td)
end




function clamp(v, min, max)
	if v < min then v = min elseif v > max then v = max end
	return v
end