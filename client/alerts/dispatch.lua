-- Relays server/alerts/component.lua's native dispatch broadcasts straight into SendNUIMessage - the always-on
-- path (no websocket/pulsar_ws dependency). See client/alerts/nui.lua for the matching outbound NUI callbacks.

RegisterNetEvent("EmergencyAlerts:Client:DispatchInit", function(myUnit, alerts, units, radioNames, dispatchLog)
	SendNUIMessage({
		type = "ALERTS_DISPATCH_INIT",
		data = {
			myUnit = myUnit,
			alerts = alerts,
			units = units,
			radioNames = radioNames,
			dispatchLog = dispatchLog,
		},
	})
end)

RegisterNetEvent("EmergencyAlerts:Client:DispatchUnitAdd", function(unit)
	SendNUIMessage({ type = "ALERTS_UNIT_ADD", data = { unit = unit } })
end)

RegisterNetEvent("EmergencyAlerts:Client:DispatchUnitRemove", function(job, source)
	SendNUIMessage({ type = "ALERTS_UNIT_REMOVE", data = { job = job, source = source } })
end)

RegisterNetEvent("EmergencyAlerts:Client:DispatchUnitUpdate", function(job, primary, key, value)
	SendNUIMessage({ type = "ALERTS_UNIT_UPDATE", data = { job = job, primary = primary, key = key, value = value } })
end)

RegisterNetEvent("EmergencyAlerts:Client:DispatchUnitOperateUnder", function(job, callsign, primary)
	SendNUIMessage({ type = "ALERTS_UNIT_OPERATE_UNDER", data = { job = job, callsign = callsign, primary = primary } })
end)

RegisterNetEvent("EmergencyAlerts:Client:DispatchUnitBreakOff", function(job, callsign)
	SendNUIMessage({ type = "ALERTS_UNIT_BREAK_OFF", data = { job = job, callsign = callsign } })
end)

RegisterNetEvent("EmergencyAlerts:Client:DispatchAlertAdd", function(alert)
	SendNUIMessage({ type = "ADD_ALERT", data = { alert = alert } })
end)

RegisterNetEvent("EmergencyAlerts:Client:DispatchAlertUpdateUnits", function(id, units)
	SendNUIMessage({ type = "ALERTS_ALERT_UPDATE_UNITS", data = { id = id, units = units } })
end)

RegisterNetEvent("EmergencyAlerts:Client:DispatchAlertRemove", function(id)
	SendNUIMessage({ type = "ALERTS_ALERT_REMOVE", data = { id = id } })
end)

RegisterNetEvent("EmergencyAlerts:Client:DispatchRadioUpdate", function(data)
	SendNUIMessage({ type = "ALERTS_RADIO_UPDATE", data = { data = data } })
end)

RegisterNetEvent("EmergencyAlerts:Client:DispatchLogAdd", function(log)
	SendNUIMessage({ type = "ALERTS_LOG_ADD", data = { log = log } })
end)
