--------------------------------------------------
local modsToLoad =
{
    {
        id = "creative2",
        folder = "diorama",
        modName = "creative",
    },
    {
        folder = "diorama",
        modName = "blocks",
    },
    {
        folder = "diorama",
        modName = "motd",
    },
    {
        folder = "diorama",
        modName = "spawn",
    },
}

--------------------------------------------------
local mods = {}

--------------------------------------------------
local function main ()

    local regularPermissions =
    {
        blocks = true,
        drawing = true,
        entities = true,
        file = true,
        network = true,
        world = true,
    }

    for _, modData in ipairs (modsToLoad) do
        local mod, error = dio.mods.load (modData, regularPermissions)
        if mod then
            mods [modData.modName] = mod
        else
            print (error)
        end
    end
end

--------------------------------------------------
main ()