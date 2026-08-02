RegisterNUICallback("CloseAlerts", function(data, cb)
	cb("OK")
	plsr.EmergencyAlerts:Close()
end)

RegisterNUICallback("ReceiveAlert", function(data, cb)
	if data and data.id then
		if data.panic then
			plsr.Sounds.Play:Distance(15, "panic.ogg", 0.5)
		else
			plsr.Sounds.Play:Distance(5, "alert_normal.ogg", 0.5)
		end

		if data.blip and type(data.blip) == "table" and data.location ~= nil then
			data.blip.id = string.format("emrg-%s", data.id)
			data.blip.title = string.format("%s", data.title)

			local eB = plsr.Blips:Add(data.blip.id, data.blip.title, data.location, data.blip.icon, data.blip.color, data.blip.size, 2, false, data.blip.flashing)
			SetBlipFlashes(eB, isPanic)
			table.insert(_alertBlips, {
				id = data.blip.id,
				time = GetCloudTimeAsInt() + data.blip.duration,
				blip = eB,
			})

			if isArea then
				local eAB = AddBlipForRadius(data.location.x, data.location.y, data.location.z, 100.0)
				SetBlipColour(eAB, data.blip.color)
				SetBlipAlpha(eAB, 90)
				table.insert(_alertBlips, {
					id = data.blip.id,
					time = GetCloudTimeAsInt() + data.blip.duration,
					blip = eAB,
				})
			end
		end
	end
	cb("OK")
end)

RegisterNUICallback("RemoveAlert", function(data, cb)
	if data and data.id then
		local id = string.format("emrg-%s", data.id)
        plsr.Blips:Remove(id)

		for k, v in ipairs(_alertBlips) do
			if v.id == id then
				RemoveBlip(v.blip)
			end
		end
	end

	cb("OK")
end)

RegisterNUICallback("AssignedToAlert", function(data, cb)
	plsr.UISounds.Play:FrontEnd(-1, "Menu_Accept", "Phone_SoundSet_Default")
	cb("OK")
end)

RegisterNUICallback("RouteAlert", function(data, cb)
	cb("OK")
	if data.location then
		plsr.UISounds.Play:FrontEnd(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET")
		plsr.EmergencyAlerts:Close()

		if data.blip then
			local f = false
			for k, v in ipairs(_alertBlips) do
				if v.id == string.format("emrg-%s", data.id) then
					v.time = GetCloudTimeAsInt() + data.blip.duration
					f = true
					break
				end
			end

			if not f then
				local eB = plsr.Blips:Add(
					string.format("emrg-%s", data.id),
					data.title,
					data.location,
					data.blip.icon,
					data.blip.color,
					data.blip.size,
					2
				)
				table.insert(_alertBlips, {
					id = string.format("emrg-%s", data.id),
					time = GetCloudTimeAsInt() + data.blip.duration,
					blip = eB,
				})
				SetBlipFlashes(eB, data.panic)
			end
		end

		ClearGpsPlayerWaypoint()
		SetNewWaypoint(data.location.x, data.location.y)
		plsr.Notification:Info("Alert Location Marked")
	end
end)

RegisterNUICallback("ViewCamera", function(data, cb)
	cb('OK')
	if data.camera then
		plsr.UISounds.Play:FrontEnd(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET")
		plsr.EmergencyAlerts:Close()
		plsr.Callbacks:ServerCallback("CCTV:ViewGroup", data.camera)
	end
end)

RegisterNUICallback("SwapToRadio", function(data, cb)
	cb("OK")
	plsr.UISounds.Play:FrontEnd(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET")
	TriggerEvent("Radio:Client:SetChannelFromInput", data.radio)
end)

-- ---- Dispatch panel actions - always available, no websocket required (see server/alerts/events.lua) ----

RegisterNUICallback("AlertsChangeUnitType", function(data, cb)
	cb("OK")
	TriggerServerEvent("EmergencyAlerts:Server:ChangeUnitType", data.job, data.primary, data.type)
end)

RegisterNUICallback("AlertsChangeAvailability", function(data, cb)
	cb("OK")
	TriggerServerEvent("EmergencyAlerts:Server:ChangeAvailability", data.job, data.primary)
end)

RegisterNUICallback("AlertsOperateUnder", function(data, cb)
	cb("OK")
	TriggerServerEvent("EmergencyAlerts:Server:OperateUnder", data.job, data.primary, data.unit)
end)

RegisterNUICallback("AlertsBreakOff", function(data, cb)
	cb("OK")
	TriggerServerEvent("EmergencyAlerts:Server:BreakOffUnit", data.job, data.primary, data.unit)
end)

RegisterNUICallback("AlertsChangeRadioChannel", function(data, cb)
	cb("OK")
	TriggerServerEvent("EmergencyAlerts:Server:ChangeRadioChannel", data.channel)
end)

RegisterNUICallback("AlertsChangePursuitMode", function(data, cb)
	cb("OK")
	TriggerServerEvent("EmergencyAlerts:Server:ChangePursuitMode", data.mode)
end)

RegisterNUICallback("AlertsUpdateAlertUnits", function(data, cb)
	cb("OK")
	TriggerServerEvent("EmergencyAlerts:Server:UpdateAlertUnits", data.id, data.units)
end)

RegisterNUICallback("AlertsRemoveAlert", function(data, cb)
	cb("OK")
	TriggerServerEvent("EmergencyAlerts:Server:RemoveAlert", data.id)
end)

RegisterNUICallback("AlertsAddRadioInfo", function(data, cb)
	cb("OK")
	TriggerServerEvent("EmergencyAlerts:Server:AddRadioInfo", data.radio, data.text)
end)

RegisterNUICallback("AlertsUpdateRadioInfo", function(data, cb)
	cb("OK")
	TriggerServerEvent("EmergencyAlerts:Server:UpdateRadioInfo", data.id, data.radio, data.text)
end)

RegisterNUICallback("AlertsRemoveRadioInfo", function(data, cb)
	cb("OK")
	TriggerServerEvent("EmergencyAlerts:Server:RemoveRadioInfo", data.id)
end)

RegisterNUICallback("AlertsLogMessage", function(data, cb)
	cb("OK")
	TriggerServerEvent("EmergencyAlerts:Server:LogMessage", data.message)
end)
