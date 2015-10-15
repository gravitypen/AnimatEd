


skeletonState = {
	shortcuts = {}
}


function skeletonState.load()
end


function skeletonState.enter()
end


function skeletonState.update()
end

function skeletonState.draw()
	love.graphics.setColor(100,0,0,255)
	love.graphics.rectangle("fill", 0,0,9999,9999)
end
