

treeviewHandler = {
	frameColor = {255,255,255,255},
	backColor = {30,30,30,255},
	textColor = {255,255,255,180},
	highlightColor = {255,255,255,255},
	selectBackColor = {64,64,64,255},
	textScale = 1.0,
	smallTextScale = 1.0,
	lineHeight = 18,
	indentation = 10,
	leftdown = false,
	leftclick = false,
	selectElement = nil,
	selected = nil,
	hovered = nil,
}



function treeviewHandler.updateInput()
	local shift = love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift")
	treeviewHandler.shift = shift
	treeviewHandler.mx, treeviewHandler.my = love.mouse.getPosition()
	local prev = treeviewHandler.leftdown
	treeviewHandler.leftdown = love.mouse.isDown("l")
	treeviewHandler.leftclick = treeviewHandler.leftdown and not prev
end

-- root being a single element and getName,
-- getChild, getSibling being functions returning the respective data or nil
-- returns selected, hovered
function treeview(x, y, w, h, root, getName, getChild, getSibling, newParentCallback)

	treeviewHandler.checkMouse = treeviewHandler.mx >= x and treeviewHandler.mx <= x+w and treeviewHandler.my >= y and treeviewHandler.my <= y+h
	if not treeviewHandler.shift and treeviewHandler.checkMouse and treeviewHandler.leftclick then root.__treeview_selected = nil end

	-- Draw Back
	love.graphics.setColor(treeviewHandler.frameColor)
	love.graphics.rectangle("fill",x,y,w,h)
	love.graphics.setColor(treeviewHandler.backColor)
	love.graphics.rectangle("fill",x+1,y+1,w-2,h-2)

	-- Element Recursion
	treeviewHandler.selectElement = nil
	treeviewHandler.selected = root.__treeview_selected
	states.setScissor(x+3, y+3, w-6, h-5)
	treeviewItem(x+4, y+4, root, getName, getChild, getSibling)
	states.resetScissor()
	-- an element has been clicked
	if treeviewHandler.selectElement then 
		if treeviewHandler.shift then
			-- Assign new Parent? (selected as new child of selectElement)
			if treeviewHandler.selected then newParentCallback(treeviewHandler.selected, treeviewHandler.selectElement) end
		else
			-- Selection
			root.__treeview_selected = treeviewHandler.selectElement
		end 
	end

	return root.__treview_selected, treeviewHandler.hovered
end


function treeviewItem(x, y, node, getName, getChild, getSibling)
	if not node then return 0 end
	-- Mouse Interaction
	local hover = false
	if treeviewHandler.checkMouse then
		if treeviewHandler.my >= y and treeviewHandler.my < y+treeviewHandler.lineHeight then
			hover = true
			treeviewHandler.hovered = node
			if treeviewHandler.leftclick then
				if treeviewHandler.mx > x+18 then
					-- Select Element
					treeviewHandler.selectElement = node
				else
					-- Minimize Element
					if node.__treeview_open then
						node.__treeview_open = false
					else
						node.__treeview_open = true
					end
				end
			end
		end
	end
	-- Background
	if treeviewHandler.selected == node then
		love.graphics.setColor(treeviewHandler.selectBackColor)
		love.graphics.rectangle("fill", 0,y,8192,treeviewHandler.lineHeight-2)
	end
	-- Print Element
	love.graphics.setColor(hover and treeviewHandler.highlightColor or treeviewHandler.textColor)
	local hasChild = getChild(node)
	if hasChild then 
		local s
		if node.__treeview_open then
			s = "[-]"
		else
			s = "[+]" 
		end
		love.graphics.print(s, x, y, 0, treeviewHandler.smallTextScale, treeviewHandler.smallTextScale, 0, 0)
	end
	love.graphics.print(getName(node), x+20, y, 0, treeviewHandler.textScale, treeviewHandler.textScale, 0, 0)
	-- Proceed with Childs
	y = y + treeviewHandler.lineHeight
	if hasChild and node.__treeview_open then
		y = treeviewItem(x+treeviewHandler.indentation, y, hasChild, getName, getChild, getSibling)
	end
	-- Siblings
	local sibling = getSibling(node)
	if sibling then
		y = treeviewItem(x, y, sibling, getName, getChild, getSibling)
	end
	-- Return Position below this element and its predecessors
	return y
end



-- two ways to call this function:
--   1. list is a table of values
--   2. (not yet implemented) list is a function returning the next element in a linked list like manner (and root when nil is given)
-- Returns selected (or nil), hovered [both index]
function listview(x, y, w, h, list, getName)
	getName = getName or function(s) return s end

	treeviewHandler.checkMouse = treeviewHandler.mx >= x and treeviewHandler.mx <= x+w and treeviewHandler.my >= y and treeviewHandler.my <= y+h
	if treeviewHandler.checkMouse and treeviewHandler.leftclick then list.__treeview_selected = nil end

	-- Draw Back
	love.graphics.setColor(treeviewHandler.frameColor)
	love.graphics.rectangle("fill",x,y,w,h)
	love.graphics.setColor(treeviewHandler.backColor)
	love.graphics.rectangle("fill",x+1,y+1,w-2,h-2)

	-- Element Recursion
	states.setScissor(x+3, y+3, w-6, h-5) 
	x = x + 4
	y = y + 4
	local hovered = nil
	local selectElement = 0
	for i = 1,#list do 
		
		-- Update Mouse
		local hover = false
		if treeviewHandler.checkMouse then
			if treeviewHandler.my >= y and treeviewHandler.my < y+treeviewHandler.lineHeight then
				hover = true
				hovered = i
				if treeviewHandler.leftclick then
					-- Select Element
					selectElement = i
					print("jo!")
				end
			end
		end
		
		-- Draw Selection
		if list.__treeview_selected == i then
			print("Drawing Selection")
			love.graphics.setColor(treeviewHandler.selectBackColor)
			love.graphics.rectangle("fill", 0,y,8192,treeviewHandler.lineHeight-2)			
		end
		-- Print
		love.graphics.setColor(hover and treeviewHandler.highlightColor or treeviewHandler.textColor)
		love.graphics.print(getName(list[i]), x, y, 0, treeviewHandler.textScale, treeviewHandler.textScale, 0, 0)

		y = y + treeviewHandler.lineHeight
	end
	--love.graphics.setScissor()
	states.resetScissor()
	if selectElement > 0 then
		list.__treeview_selected = selectElement
	end

	return list.__treview_selected, hovered
end