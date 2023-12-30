Framework = nil

local Webhook = "WEBHOOK_HERE" -- Put your Discord webhook here to log Play and Saves
local BotUsername = "Wasabi Boombox" -- Name for the Bot

if GetResourceState('es_extended') == 'started' or GetResourceState('es_extended') == 'starting' then
    Framework = 'ESX'
    ESX = exports['es_extended']:getSharedObject()
else
    print("^0[^1ERROR^0] The framework could not be initialised!^0")
    print("^0[^1ERROR^0] For Support: https://discord.gg/wasabiscripts^0")
end

MySQL.ready(function()
    if Framework == "ESX" then
        MySQL.Sync.execute(
            "CREATE TABLE IF NOT EXISTS `boombox_songs` (" ..
                "`identifier` varchar(64) NOT NULL, " ..
                "`label` varchar(30) NOT NULL, " ..
                "`link` longtext NOT NULL " ..
            ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4; "
        )
    end
end)

if Framework == "ESX" then
    ESX.RegisterUsableItem(Config.BoomboxItem, function(source)
        local xPlayer = ESX.GetPlayerFromId(source)
        TriggerClientEvent('boombox:useBoombox', source)
        xPlayer.removeInventoryItem(Config.BoomboxItem, 1)
    end)
end

RegisterServerEvent('boombox:deleteObj', function(netId)
    TriggerClientEvent('boombox:deleteObj', -1, netId)
end)

if Framework == "ESX" then
    RegisterServerEvent('boombox:objDeleted', function()
        local xPlayer = ESX.GetPlayerFromId(source)
        xPlayer.addInventoryItem(Config.BoomboxItem, 1)
    end)
end

RegisterNetEvent("boombox:soundStatus")
AddEventHandler("boombox:soundStatus", function(type, musicId, data)
    TriggerClientEvent("boombox:soundStatus", -1, type, musicId, data)
end)

RegisterNetEvent("boombox:syncActive")
AddEventHandler("boombox:syncActive", function(activeRadios)
    TriggerClientEvent("boombox:syncActive", -1, activeRadios)
end)

if Framework == "ESX" then
    RegisterServerEvent('boombox:save')
    AddEventHandler('boombox:save', function(name, link)
        local xPlayer = ESX.GetPlayerFromId(source)
        SongConfirmed(16448250, "Save Song Log", "Player Name: **"..xPlayer.getName().."**\n Player Identifier: **"..xPlayer.getIdentifier().."**\n Song Name: **"..name.."**\n Song Link: **"..link.."**\n Date: "..os.date("** Time: %H:%M Date: %d.%m.%y **").."", "Made by Andistyler")
        MySQL.Async.insert('INSERT INTO `boombox_songs` (`identifier`, `label`, `link`) VALUES (@identifier, @label, @link)', {
            ['@identifier'] = xPlayer.identifier,
            ['@label'] = name,
            ['@link'] = link
        })
    end)
end

if Framework == "ESX" then
    RegisterServerEvent('boombox:deleteSong')
    AddEventHandler('boombox:deleteSong', function(data)
        local xPlayer = ESX.GetPlayerFromId(source)
        MySQL.Async.execute('DELETE FROM `boombox_songs` WHERE `identifier` = @identifier AND label = @label AND link = @link', {
            ["@identifier"] = xPlayer.identifier,
            ["@label"] = data.label,
            ["@link"] = data.link,
        })
    end)
end

if Framework == "ESX" then
    ESX.RegisterServerCallback('boombox:getSavedSongs', function(source, cb)
        local savedSongs = {}
        local xPlayer = ESX.GetPlayerFromId(source)
        MySQL.Async.fetchAll('SELECT label, link FROM boombox_songs WHERE identifier = @identifier', {
            ['@identifier'] = xPlayer.identifier
        }, function(result)
            if result[1] then
                for i=1, #result do
                    table.insert(savedSongs, {label = result[i].label, link = result[i].link})
                end
            end
            if savedSongs then
                cb(savedSongs)
            else
                cb(false)
            end
        end)
    end)
end

if Framework == "ESX" then
    RegisterNetEvent("boombox:DiscordKnows")
    AddEventHandler("boombox:DiscordKnows", function(link)
        local xPlayer = ESX.GetPlayerFromId(source)
        SongConfirmed(16448250, "Play Song Log", "Player Name: **"..xPlayer.getName().."**\n Player Identifier: **"..xPlayer.getIdentifier().."**\n Song Link: **"..link.."**\n Date: "..os.date("** Time: %H:%M Date: %d.%m.%y **").."", "Made by Andistyler")
    end)
end

----- Boom Box Discord Hook System -----

SongConfirmed = function(color, name, message, footer)
    if Webhook and Webhook ~= 'WEBHOOK_HERE' then
        local SongConfirmed = {
                {
                    ["color"] = color,
                    ["title"] = "**".. name .."**",
                    ["description"] = message,
                    ["footer"] = {
                        ["text"] = footer,
                    },
                }
            }

          PerformHttpRequest(Webhook, function(err, text, headers) end, 'POST', json.encode({username = BotUsername, embeds = SongConfirmed}), { ['Content-Type'] = 'application/json' })
    end
end
