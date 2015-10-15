
require "animator"
require "animatorBlender"
require "curveEditor"
require "test"
require "conf"
require "treeview"


function love.load()
    curveEditor.init()
    animator.load()
    test.init()
end


function love.mousepressed(x, y, button)
    curveEditor.mousepressed(x, y, button)
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
    test.draw()
end




function love.update(td)
	test.update(td)
end


