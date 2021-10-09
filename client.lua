-------------------------------------
------- Edited by ra1der#0954 -------
------------------------------------- 

ESX = nil
local timing, isPlayerWhitelisted = math.ceil(1 * 60000), false
local RobbingATM = false
local HackingATM = false

ATMCheck = {
	"prop_atm_01", --market
	"prop_atm_03" -- kırmızı
}

Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(0)
	end
end)

-- Core Thread Function:
RegisterCommand('atmsoy', function()
	if not RobbingATM then
		if not HackingATM then
			local entity, entityDst = ESX.Game.GetClosestObject(ATMCheck)
			if DoesEntityExist(entity) and entityDst <= 1.5 then
				startRobbingATM()					
			else
				TriggerEvent('mythic_notify:client:SendAlert', { type = 'error', text = 'Yakınında herhangi bir ATM yok!'})
			end
		end
	end
end)

-- Starting ATM Robbery:
function startRobbingATM()
	ESX.TriggerServerCallback("ra1der_atmrobbery:isRobbingPossible", function(cooldownATM)
		if not cooldownATM then
			ESX.TriggerServerCallback('ra1der_atmrobbery:getOnlinePoliceCount', function(policeCount)
				if policeCount then
					local result = exports["reload-skillbar"]:taskBar()
					if result then
						RobbingATM = true

						TriggerServerEvent('m3:dispatch:notify', 'ATM Soygunu', 'Anonim', 'Yok', GetEntityCoords(PlayerPedId()))
						
						TriggerServerEvent("ra1der_atmRobbery:CooldownATM")
						local player = PlayerPedId()
						local playerPos = GetEntityCoords(player)

						exports['mythic_progbar']:Progress({
							name = "robatm",
							duration = Config.ConnectTime,
							label = 'Bağlanılıyor...',
							useWhileDead = false,
							canCancel = false,
							controlDisables = {
								disableMovement = true,
								disableCarMovement = true,
								disableMouse = false,
								disableCombat = true,
							},
							animation = {
								animDict = "random@atmrobberygen@male",
								anim = "idle_a",
								flags = 49,
							},
						}, function(cancelled)
							if not cancelled then
								TriggerEvent("mhacking:show")
								TriggerEvent("mhacking:start",4,75,hackingEvent)
								HackingATM = true
							end
						end)
					end
				else
					RobbingATM = false
				end
			end)
		else
			RobbingATM = false
		end
	end)
end

--Hack Ekranı
function hackingEvent(success)
	local player = PlayerPedId()
    TriggerEvent('mhacking:hide')
    if success then
		local deger = math.random(0, 100)
		print(deger)
		if deger >= 70 then 
		TriggerServerEvent("ra1der_atmrobbery:addItem") 		
		end
		TriggerServerEvent("ra1der_atmRobbery:success")	
		TriggerEvent('mythic_notify:client:SendAlert', { type = 'inform', text = 'ATM\'yi başarıyla soydun!'})
    else
		TriggerEvent('mythic_notify:client:SendAlert', { type = 'error', text = 'ATM\'yi hacklemekte başarısız oldun!'})
	end
	RobbingATM = false
	HackingATM = false
end

-- Drawtext 
function DrawText3Ds(x,y,z, text)
    local onScreen,_x,_y=World3dToScreen2d(x,y,z)
    local px,py,pz=table.unpack(GetGameplayCamCoords())

    SetTextScale(0.32, 0.32)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 0)
    SetTextEntry("STRING")
    SetTextCentre(1)
    AddTextComponentString(text)
    DrawText(_x,_y)
    local factor = (string.len(text)) / 500
    DrawRect(_x,_y+0.0125, 0.015+ factor, 0.03, 0, 0, 0, 80)
end