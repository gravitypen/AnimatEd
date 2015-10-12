
require "animator"
require "cuveEditor"
require "test"


function love.load()
    curveEditor.init()
    animator.load()
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
    curveEditor.draw()
end




function love.update()

end


