--------------------------------------------------
local permissions =
{
	tourist = 
	{
		canChat = true,
	},
	builder = 
	{
		canBuild = true,
		canDestroy = true,
		canChat = true,
	},
	mod = 
	{
		canBuild = true,
		canDestroy = true,
		canChat = true,
		canPromoteTo = {tourist = true, builder = true},
	},
	admin = 
	{
		canBuild = true,
		canDestroy = true,
		canChat = true,
		canPromoteTo = {tourist = true, builder = true, mod = true},
	}
}

--------------------------------------------------
local connections = {}

--------------------------------------------------
local function onPlayerLoad (event)

	local filename = "player_" .. event.playerName .. ".lua"
	local settings = dio.file.loadLua (filename)

	local isPasswordCorrect = true
	if settings then
		isPasswordCorrect = (settings.password == event.password)
	end

	local connection =
	{
		connectionId = event.connectionId,
		playerName = event.playerName,
		screenName = event.playerName,
		password = event.password,
		permissionLevel = event.isSinglePlayer and "builder" or "tourist",
		isPasswordCorrect = isPasswordCorrect,
		needsSaving = event.isSinglePlayer,
	}

	if settings and isPasswordCorrect then
		connection.permissionLevel = settings.permissionLevel
		connection.needsSaving = true
		dio.world.setPlayerXyz (event.playerName, settings.xyz)
	end

	connection.screenName = connection.screenName .. " [" .. connection.permissionLevel .. "]"

	connections [event.connectionId] = connection
end

--------------------------------------------------
local function onPlayerSave (event)

	local connection = connections [event.connectionId]
	local permissions = permissions [connection.permissionLevel]

	if connection.needsSaving then

		local xyz, error = dio.world.getPlayerXyz (event.playerName)
		if xyz then

			local filename = "player_" .. event.playerName .. ".lua"
			local settings =
			{
				xyz = xyz,
				password = connection.password,
				permissionLevel = connection.permissionLevel,
			}

			dio.file.saveLua (filename, settings, "settings")

		else
			print (error)
		end
	end

	connections [event.connectionId] = nil
end

--------------------------------------------------
local function onEntityPlaced (event)
	local connection = connections [event.playerId]
	local canBuild = permissions [connection.permissionLevel].canBuild
	event.cancel = not canBuild
	print ("cancel???  " .. tostring (event.cancel))
end

--------------------------------------------------
local function onEntityDestroyed (event)
	local connection = connections [event.playerId]
	local canDestroy = permissions [connection.permissionLevel].canDestroy
	event.cancel = not canDestroy
	print ("cancel???  " .. tostring (event.cancel))
end

--------------------------------------------------
local function onChatReceived (event)

	local connection = connections [event.authorConnectionId]
	local canPromoteTo = permissions [connection.permissionLevel].canPromoteTo

	if event.text == ".group" then

		event.targetConnectionId = event.authorConnectionId
		event.text = "Your group = " .. connection.permissionLevel

	elseif canPromoteTo then

		local commandIdx = event.text:find (".setGroup")

		if commandIdx == 1 then

			local words = {}
			for word in event.text:gmatch ("[^ ]+") do
				table.insert (words, word)
			end

			event.targetConnectionId = event.authorConnectionId
			event.text = "FAILED: .setGroup [playerName] [permissionLevel]";

			if #words >= 3 then

				local levelToSet = words [3]

				if canPromoteTo [levelToSet] and permissions [levelToSet] then
					local playerToPromote = words [2]

					local hasPromoted = false
					for _, promoteConnection in pairs (connections) do
						if promoteConnection.playerName == playerToPromote and promoteConnection.isPasswordCorrect then
							promoteConnection.permissionLevel = levelToSet
							promoteConnection.needsSaving = true
							hasPromoted = true
						end
					end

					if hasPromoted then
						event.text = "SUCCESS: .setGroup " .. playerToPromote .. " -> " .. levelToSet;						
					end
				end
			end
		end
	end
end

--------------------------------------------------
local function onLoadSuccessful ()

	-- dio.players.setPlayerAction (player, actions.LEFT_CLICK, outcomes.DESTROY_BLOCK)

	local types = dio.events.types
	dio.events.addListener (types.SERVER_PLAYER_LOAD, onPlayerLoad)
	dio.events.addListener (types.SERVER_PLAYER_SAVE, onPlayerSave)
	dio.events.addListener (types.SERVER_ENTITY_PLACED, onEntityPlaced)
	dio.events.addListener (types.SERVER_ENTITY_DESTROYED, onEntityDestroyed)
	dio.events.addListener (types.SERVER_CHAT_RECEIVED, onChatReceived)

end

--------------------------------------------------
local modSettings = 
{
	name = "Base Game",

	description = "This is required to play the game!",

	urls = 
	{
		latest = "http://www.robtheswan.com/game/mods/rest.html",
		website = "http://www.robtheswan.com/game/mods/blah.html",
		forums = "http://www.robtheswan.com/game/mods/forums.html",
		bugs = "http://www.robtheswan.com/game/mods/forums.html",
		wiki = "http://www.robtheswan.com/game/mods/forums.html",
	},

	dependencies =
	{
		gameApi =
		{
			minimumVersion = {major = 0, minor = 1},
			maximumVersion = {major = 0, minor = 1},
		},
	},

	permissionsRequired = 
	{
		client = true,
		player = true,
		file = true,
	},
}

--------------------------------------------------
return modSettings, onLoadSuccessful
