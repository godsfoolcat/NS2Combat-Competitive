-- disable commander bots
local oldOnConsoleAddBots = OnConsoleAddBots
function OnConsoleAddBots(client, numBotsParam, forceTeam, botType, passive)
    return oldOnConsoleAddBots(client, numBotsParam, forceTeam, nil, passive)
end
