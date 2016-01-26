local TickerLine = require ("resources/scripts/session/chat/ticker_line")

--------------------------------------------------
local instance = nil

--------------------------------------------------
local function renderBg (self)
	dio.drawing.font.drawBox (0, 0, self.size.w, self.size.h, 0x000000b0);
end

--------------------------------------------------
local function renderChat (self)

	local lineIdx = self.firstLineToDraw + self.chatLinesToDraw
	local y = (self.chatLinesToDraw - 1) * self.heightPerLine
	if lineIdx > #self.lines then
		lineIdx = #self.lines
	end

	local drawString = dio.drawing.font.drawString

	while y >= 0 and lineIdx > 0 do
		local line = self.lines [lineIdx]
		drawString (0, y + 2, line.author, 0x000000ff)
		drawString (0, y, line.author, 0xffff00ff)
		drawString (self.textOffset, y + 2, line.text, 0x000000ff)
		drawString (self.textOffset, y, line.text, 0xffffffff)

		y = y - self.heightPerLine
		lineIdx = lineIdx - 1
	end
end

--------------------------------------------------
local function renderTextEntry (self)

	local heightPerLine = self.heightPerLine
	local y = self.chatLinesToDraw * heightPerLine
	
	local drawString = dio.drawing.font.drawString
	drawString (0, y, string.rep ("-", 40), 0xffffffff)
	drawString (0, y + heightPerLine, self.text, 0xffffffff)
	local width = dio.drawing.font.measureString (self.text)
	drawString (width, y + heightPerLine, "_", 0xff0000ff)

end

--------------------------------------------------
local function resetTextEntry (self)
	self.text = ""
	self.isDirty = true
end

--------------------------------------------------
local function hide (self)
	self.isVisible = false
	dio.inputs.mouse.setExclusive (true)
	dio.inputs.setExclusiveKeys (false)
	dio.inputs.setArePlayingControlsEnabled (true)
end

--------------------------------------------------
local function addNewTickerLine (self, author, text)

	local ticker = self.ticker

	if #ticker.lines == ticker.linesToDraw then
		for idx = 2, #ticker.lines do
			ticker.lines [idx - 1] = ticker.lines [idx]			
		end
		table.remove (ticker.lines)
	end

	local newTickerLine = TickerLine (author, text, self.size.w, self.heightPerLine, self.textOffset)
	table.insert (ticker.lines, newTickerLine)
end

-- TODO
-- --------------------------------------------------
-- local function onUpdate (self)
-- end

--------------------------------------------------
local function onEarlyRender (self)

	-- TODO move calcualations to a CLIENT_UPDATE event when one is made
	self.isDirty = true

	if self.isDirty then

		dio.drawing.setRenderToTexture (self.renderToTexture)
		renderBg (self)
		renderChat (self)
		renderTextEntry (self)

		dio.drawing.setRenderToTexture (nil)
		self.isDirty = false

	end

	local lines = self.ticker.lines
	local idx = 1

	while idx <= #lines do

		local tickerLine = lines [idx]
		local isOk = tickerLine:update ()

		if not isOk then
			table.remove (lines, 1)

		else
			if tickerLine.isDirty then
				tickerLine:earlyRender ()
			end
			idx = idx + 1
		end
	end
end

--------------------------------------------------
local function onLateRender (self)

	if self.isVisible then
		dio.drawing.drawTexture (self.renderToTexture, self.position.x, self.position.y, self.size.w * self.scale, self.size.h * self.scale, 0xffffffff)

	else
		local lines = self.ticker.lines
		local y = self.position.y + ((self.textEntryLinesToDraw + #lines) * self.heightPerLine * self.scale)

		for _, tickerLine in ipairs (lines) do
			y = y - self.heightPerLine * self.scale
			tickerLine:lateRender (self.position.x, y)
		end
	end
end

--------------------------------------------------
local function onChatMessageReceived (author, text)

	local self = instance

	local line = 
	{
		author = author, 
		text = text
	}

	table.insert (self.lines, line)

	if self.autoScroll then
		self.firstLineToDraw = #self.lines - self.chatLinesToDraw + 1
		if self.firstLineToDraw < 1 then
			self.firstLineToDraw = 1
		end
	end

	addNewTickerLine (self, author, text)

	self.isDirty = true

end

--------------------------------------------------
local function onKeyClicked (keyCode, keyCharacter, keyModifiers)

	local self = instance

	if self.isVisible then

		if keyCharacter then

		 	self.text = self.text .. string.char (keyCharacter)
		 	self.isDirty = true

		elseif keyCode == dio.inputs.keyCodes.ENTER then

			local isOk, errorStr = dio.clientChat.send (self.text)
			if not isOk then
				onChatMessageReceived ("Self", "Last message did not send! (" .. errorStr .. ")")
			end

			resetTextEntry (self)

		elseif keyCode == dio.inputs.keyCodes.ESCAPE then

			hide (self)

		elseif keyCode == dio.inputs.keyCodes.BACKSPACE then

			local stringLen = self.text:len ()
			if stringLen > 0 then
				self.text = self.text:sub (1, -2)
				self.isDirty = true
			end			
		end

		return true

	elseif keyCode == self.chatAppearKeyCode then

		self.isVisible = true
		dio.inputs.mouse.setExclusive (false)
		dio.inputs.setExclusiveKeys (true)
		dio.inputs.setArePlayingControlsEnabled (false)
		resetTextEntry (self)

		local handle = dio.clientDebug.beginDeliveryTimeTest ()		
		self.timeTestHandles [handle] = dio.system.getTime ()

		return true

	end

	return false
end

--------------------------------------------------
local function onClientWindowFocusLost ()

	-- local self = instance

	-- if self.isVisible then
	-- 	hide (self)
	-- end	

end

--------------------------------------------------
local function onDeliveryTimeTestComplete (handle)

	local self = instance

	local now = dio.system.getTime ()
	local timeInMs = now - self.timeTestHandles [handle]
	self.timeTestHandles [handle] = nil

	onChatMessageReceived ("SERVER", "packet delivery test = (" .. tostring (handle) .. ") took " .. tostring (timeInMs) .. " ms")
end

--------------------------------------------------
local function onLoadSuccessful ()

	local chatLinesToDraw = 18
	local textEntryLinesToDraw = 2
	local heightPerLine = 14
	local height = (chatLinesToDraw + textEntryLinesToDraw) * heightPerLine

	instance = 
	{
		firstLineToDraw = 1,
		autoScroll = true,
		chatLinesToDraw = chatLinesToDraw,
		textEntryLinesToDraw = textEntryLinesToDraw,
		position = {x = 20, y = 20},
		size = {w = 512, h = height},
		heightPerLine = heightPerLine,
		textOffset = 100,
		scale = 2,
		lines = {},
		isDirty = true,
		isVisible = false,
		chatAppearKeyCode = dio.inputs.keyCodes.T,
		text = "",

		ticker = 
		{
			linesToDraw = chatLinesToDraw,
			lines = {}
		},

		timeTestHandles = {},
	}

	instance.renderToTexture = dio.drawing.createRenderToTexture (instance.size.w, instance.size.h)
	dio.drawing.addRenderPassBefore (function () onEarlyRender (instance) end)
	dio.drawing.addRenderPassAfter (function () onLateRender (instance) end)

	local types = dio.events.types
	dio.events.addListener (types.CLIENT_CHAT_MESSAGE_RECEIVED, onChatMessageReceived)
	dio.events.addListener (types.CLIENT_KEY_CLICKED, onKeyClicked)
	dio.events.addListener (types.CLIENT_WINDOW_FOCUS_LOST, onClientWindowFocusLost)
	dio.events.addListener (types.CLIENT_DELIVERY_TIME_TEST_COMPLETE, onDeliveryTimeTestComplete)

	onChatMessageReceived ("Self", "World loaded")

end

--------------------------------------------------
local modSettings = 
{
	name = "Chat",

	description = "Can draw a chat window and allow players to type in it",

	permissionsRequired = 
	{
		client = true,
		player = true,
	},
}

--------------------------------------------------
return modSettings, onLoadSuccessful
