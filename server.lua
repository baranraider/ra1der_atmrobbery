local ESX = nil

local CoolDownTimerATM = {}

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

-- Event for adding cooldown to player:
RegisterServerEvent("ra1der_atmrobbery:CooldownATM")
AddEventHandler("ra1der_atmrobbery:CooldownATM",function()
	local xPlayer = ESX.GetPlayerFromId(source)
	table.insert(CoolDownTimerATM,{CoolDownTimerATM = GetPlayerIdentifier(source), time = ((Config.RobCooldown * 60000))})
end)

-- Cooldown timer thread:
Citizen.CreateThread(function() -- do not touch this thread function!
	while true do
	Citizen.Wait(1000)
		for k,v in pairs(CoolDownTimerATM) do
			if v.time <= 0 then
				RemoveCooldownTimer(v.CoolDownTimerATM)
			else
				v.time = v.time - 1000
			end
		end
	end
end)

-- Callback to get cooldown:
ESX.RegisterServerCallback("ra1der_atmrobbery:isRobbingPossible",function(source,cb)
	local xPlayer = ESX.GetPlayerFromId(source)
	local waitTimer = GetTimeForCooldown(GetPlayerIdentifier(source))
	if not CheckCooldownTime(GetPlayerIdentifier(source)) then
		cb(false)
	else
		TriggerClientEvent('mythic_notify:client:SendAlert', xPlayer.source, { type = 'error', text = string.format("ATM soyulmuş, düzelmesine kalan süre: %s dakika",waitTimer)})
		cb(true)
	end
end)

-- Callback to get police count:
ESX.RegisterServerCallback("ra1der_atmrobbery:getOnlinePoliceCount",function(source,cb)
	local xPlayer = ESX.GetPlayerFromId(source)
	local Players = ESX.GetPlayers()
	local policeOnline = 0
	for i = 1, #Players do
		local xPlayer = ESX.GetPlayerFromId(Players[i])
		if xPlayer["job"]["name"] == "police" or xPlayer["job"]["name"] == "sheriff" then
			policeOnline = policeOnline + 1
		end
	end
	if policeOnline >= Config.RequiredPolice then
		cb(true)
	else
		cb(false)
		TriggerClientEvent('mythic_notify:client:SendAlert', xPlayer.source, { type = 'error', text = 'Şehirde yeterli polis yok!'})
	end
end)

RegisterServerEvent("ra1der_atmrobbery:addItem") 
AddEventHandler("ra1der_atmrobbery:addItem", function()
	local xPlayer = ESX.GetPlayerFromId(source)
	
	xPlayer.addInventoryItem('id_card', 1)
	TriggerClientEvent('mythic_notify:client:SendAlert', xPlayer.source, { type = 'inform', text = 'ATM\'den 1x mavi güvenlik kartı buldun!'})
end)


RegisterServerEvent("ra1der_atmrobbery:success")
AddEventHandler("ra1der_atmrobbery:success",function()
	local xPlayer = ESX.GetPlayerFromId(source)
    local reward = math.random(Config.MinReward, Config.MaxReward)
	
	xPlayer.addInventoryItem('cash', reward)
	TriggerClientEvent('mythic_notify:client:SendAlert', xPlayer.source, { type = 'inform', text = 'ATM\'den '..reward..'$ para çıktı!'})
	if Config.EnableDiscordLog then
		dclog(xPlayer, 'ATM\'yi soymayı **başardı**, **'..reward..'$** para aldı.')
	end
end)

-- Do not touch:
function RemoveCooldownTimer(source)
	for k,v in pairs(CoolDownTimerATM) do
		if v.CoolDownTimerATM == source then
			table.remove(CoolDownTimerATM,k)
		end
	end
end
function GetTimeForCooldown(source)
	for k,v in pairs(CoolDownTimerATM) do
		if v.CoolDownTimerATM == source then
			return math.ceil(v.time/60000)
		end
	end
end
function CheckCooldownTime(source)
	for k,v in pairs(CoolDownTimerATM) do
		if v.CoolDownTimerATM == source then
			return true
		end
	end
	return false
end

function dclog(xPlayer, text)
	local playerName = Sanitize(xPlayer.getName())
	
	local discord_webhook = GetConvar('', Config.DiscordWebhook)
	if discord_webhook == '' then
	  return
	end
	local headers = {
	  ['Content-Type'] = 'application/json'
	}
	local data = {
	  ["username"] = Config.WebhookName,
	  ["avatar_url"] = Config.WebhookAvatarUrl,
	  ["embeds"] = {{
		["author"] = {
		  ["name"] = playerName .. ' - ' .. xPlayer.identifier
		},
		["color"] = 1942002,
		["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ")
	  }}
	}
	data['embeds'][1]['description'] = text
	PerformHttpRequest(discord_webhook, function(err, text, headers) end, 'POST', json.encode(data), headers)
end

function Sanitize(str)
	local replacements = {
		['&' ] = '&amp;',
		['<' ] = '&lt;',
		['>' ] = '&gt;',
		['\n'] = '<br/>'
	}

	return str
		:gsub('[&<>\n]', replacements)
		:gsub(' +', function(s)
			return ' '..('&nbsp;'):rep(#s-1)
		end)
end
