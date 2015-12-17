--------------------------------------------------
local m = {}

--------------------------------------------------
function m.addLabel (menu, text)

	local label = 
	{
		text = text,
		x = 0,
		y = menu.next_y
	}

	menu.next_y = menu.next_y + 10
	table.insert (menu.items, label)
end

--------------------------------------------------
function m.addBreak (menu)

	menu.next_y = menu.next_y + 10
	local label = 
	{
		text = "******************************************",
		x = 0,
		y = menu.next_y
	}

	menu.next_y = menu.next_y + 20
	table.insert (menu.items, label)
end

--------------------------------------------------
function m.addButton (menu, text, onClicked)

	local button = 
	{
		text_unfocused = "  " .. text .. "  ",
		text_focused = "[ " .. text .. " ]",
		text = text,
		x = 100,
		y = menu.next_y,
		w = 200,
		h = 10,
		onClicked = onClicked
	}

	menu.next_y = menu.next_y + 10
	table.insert (menu.items, button)
end

--------------------------------------------------
function m.addEventListener (menu, event, onFired)
	menu.events [event] = onFired
end

--------------------------------------------------
return m
