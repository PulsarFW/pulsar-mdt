local config = load(LoadResourceFile(GetCurrentResourceName(), "config/server.lua"))()

local _predefined = {
	injuredPerson = {
		code = "10-47",
		title = "Injured Person",
		type = {"police_alerts", "ems_alerts"},
		isPanic = false,
		blip = {
			icon = 280,
			size = 1.2,
			color = 8,
			duration = (60 * 5),
		},
		styleOverride = 2,
	},
	illegalHunting = {
		code = "10-35",
		title = "Illegal Hunting",
		type = "police_alerts",
		isPanic = false,
		blip = {
			icon = 141,
			size = 0.9,
			color = 30,
			duration = (60 * 5),
		},
	},
	bane = {
		code = "10-31",
		title = "Breaking & Entering",
		type = "police_alerts",
		isPanic = false,
		blip = {
			icon = 311,
			size = 0.9,
			color = 30,
			duration = (60 * 5),
		},
	},
	shotsfired = {
		code = "10-99",
		title = "Shots Fired",
		type = "police_alerts",
		isPanic = false,
		blip = {
			icon = 110,
			size = 0.9,
			color = 30,
			duration = (60 * 3),
		},
	},
	shotsfiredvehicle = {
		code = "10-99",
		title = "Shots Fired From A Vehicle",
		type = "police_alerts",
		isPanic = false,
		blip = {
			icon = 229,
			size = 0.9,
			color = 30,
			duration = (60 * 3),
		},
	},
	oxysale = {
		code = "10-31",
		title = "Suspicious Activity",
		type = "police_alerts",
		isPanic = false,
		blip = {
			icon = 66,
			size = 0.9,
			color = 30,
			duration = (60 * 3),
		},
		isArea = true,
	},
	lockpickext = {
		code = "10-31",
		title = "Suspicious Activity",
		type = "police_alerts",
		isPanic = false,
		blip = {
			icon = 66,
			size = 0.9,
			color = 30,
			duration = (60 * 3),
		},
	},
	lockpickint = {
		code = "10-99B",
		title = "Stolen Vehicle",
		type = "police_alerts",
		isPanic = false,
		blip = {
			icon = 326,
			size = 0.9,
			color = 30,
			duration = (60 * 3),
		},
	},
	caraccident = {
		code = "10-50",
		title = "Vehicle Accident",
		type = {"police_alerts", "ems_alerts"},
		isPanic = false,
		blip = {
			icon = 620,
			size = 0.9,
			color = 30,
			duration = (60 * 3),
		},
		styleOverride = 2,
	},
	planeaccident = {
		code = "10-50",
		title = "Plane Crash",
		type = {"police_alerts", "ems_alerts"},
		isPanic = false,
		blip = {
			icon = 307,
			size = 0.9,
			color = 30,
			duration = (60 * 3),
		},
		styleOverride = 2,
	},
	heliaccident = {
		code = "10-50",
		title = "Helicopter Accident",
		type = {"police_alerts", "ems_alerts"},
		isPanic = false,
		blip = {
			icon = 64,
			size = 0.9,
			color = 30,
			duration = (60 * 3),
		},
		styleOverride = 2,
	},
	boataccident = {
		code = "10-50",
		title = "Boating Accident",
		type = {"police_alerts", "ems_alerts"},
		isPanic = false,
		blip = {
			icon = 427,
			size = 0.9,
			color = 30,
			duration = (60 * 3),
		},
		styleOverride = 2,
	},
	call911 = {
		code = "911",
		title = "911 Call",
		type = {"police_alerts", "ems_alerts"},
		isPanic = false,
		blip = {
			icon = 280,
			size = 0.9,
			color = 1,
			duration = (60 * 5),
		},
		styleOverride = 1,
	},
	call311 = {
		code = "311",
		title = "311 Call",
		type = {"police_alerts", "ems_alerts"},
		isPanic = false,
		blip = {
			icon = 280,
			size = 0.9,
			color = 5,
			duration = (60 * 5),
		},
		styleOverride = 1,
	},
	call911anon = {
		code = "911",
		title = "911 Call",
		type = {"police_alerts", "ems_alerts"},
		isPanic = false,
		isAnon = true,
		blip = {
			icon = 280,
			size = 0.9,
			color = 1,
			duration = (60 * 5),
		},
		styleOverride = 1,
	},
	call311anon = {
		code = "311",
		title = "311 Call",
		type = {"police_alerts", "ems_alerts"},
		isPanic = false,
		isAnon = true,
		blip = {
			icon = 280,
			size = 0.9,
			color = 5,
			duration = (60 * 5),
		},
		styleOverride = 1,
	},
	bankjob = {
		code = "10-90",
		title = "Bank Robbery",
		type = "police_alerts",
		isPanic = false,
		blip = {
			icon = 311,
			size = 0.9,
			color = 30,
			duration = (60 * 5),
		},
	},
	bobcat = {
		code = "10-90",
		title = "Armed Robbery",
		type = "police_alerts",
		isPanic = false,
		blip = {
			icon = 311,
			size = 0.9,
			color = 30,
			duration = (60 * 5),
		},
	},
	icurequest = {
		code = "NA",
		title = "ICU Patient Assistance",
		type = "ems_alerts",
		isPanic = false,
	},
	illegalStreetRacing = {
		code = "10-35",
		title = "Illegal Street Racing",
		type = "police_alerts",
		isPanic = false,
		blip = {
			icon = 227,
			size = 0.9,
			color = 30,
			duration = (60 * 5),
		},
	},
	towRequest = {
		code = "TOW",
		title = "PD Tow Request",
		type = "tow_alerts",
		isPanic = false,
		blip = {
			icon = 68,
			size = 0.9,
			color = 1,
			duration = (60 * 5),
			flashing = true,
		},
	},
	boosting = {
		code = "10-99A",
		title = "Grand Theft Auto",
		type = "police_alerts",
		isPanic = false,
		blip = {
			icon = 523,
			size = 0.9,
			color = 17,
			duration = (60 * 3),
		},
	},
	boostingTracked = {
		code = "10-99A",
		title = "Grand Theft Auto - Tracker Tampering",
		type = "police_alerts",
		isPanic = false,
		blip = {
			icon = 523,
			size = 0.9,
			color = 17,
			duration = (60 * 3),
		},
	},
}

AddEventHandler("Job:Server:DutyAdd", function(dutyData, source, stateId, callsign)
	plsr.EmergencyAlerts:OnDuty(dutyData, source, stateId, callsign)
end)

AddEventHandler("Job:Server:DutyRemove", function(dutyData, source, stateId)
	plsr.EmergencyAlerts:OffDuty(dutyData, source, stateId)
end)

AddEventHandler("EmergencyAlerts:Server:ServerDoPredefined", function(src, type, description)
	local data = _predefined[type]
	if data == nil then
		return
	end

	local coords = GetEntityCoords(GetPlayerPed(src))

	local tpCoords = plsr.State:Player(src).tpLocation
	if tpCoords ~= nil then
		coords = vector3(tpCoords.x, tpCoords.y, tpCoords.z)
	end

	plsr.Callbacks:ClientCallback(src, "EmergencyAlerts:GetStreetName", coords, function(location)
		if location ~= nil then
			plsr.EmergencyAlerts:Create(
				data.code,
				data.title,
				data.type,
				location,
				description or data.description or "",
				data.isPanic or false,
				data.blip or false,
				data.styleOverride
			)
		end
	end)
end)

local _cds = {}
RegisterNetEvent("EmergencyAlerts:Server:DoPredefined", function(type, description)
	local src = source
	local data = _predefined[type]
	if data == nil then
		return
	end

	if type == "injuredPerson" then
		if _cds[source] ~= nil and _cds[source] > os.time() then
			return
		else
			_cds[source] = os.time() + config.Alerts.injuredPersonCooldownSec
		end
	end

	if data.isAnon then
		plsr.EmergencyAlerts:Create(
			data.code,
			data.title,
			data.type,
			false,
			description or data.description or "",
			data.isPanic or false,
			data.blip or false,
			data.styleOverride,
			false
		)
	else
		local coords = GetEntityCoords(GetPlayerPed(src))

		local tpCoords = plsr.State:Player(src).tpLocation
		if tpCoords then
			coords = vector3(tpCoords.x, tpCoords.y, tpCoords.z)
		elseif data.isArea then
			local r = config.Alerts.areaJitterRadius
			coords = vector3(coords.x + math.random(-r, r), coords.y + math.random(-r, r), coords.z)
		end

		plsr.Callbacks:ClientCallback(src, "EmergencyAlerts:GetStreetName", coords, function(location)
			plsr.EmergencyAlerts:Create(
				data.code,
				data.title,
				data.type,
				location,
				description or data.description or "",
				data.isPanic or false,
				data.blip or false,
				data.styleOverride,
				data.isArea or false
			)
		end)
	end

end)

-- ---- Dispatch panel actions (from client/alerts/nui.lua's new NUI callbacks) - always available, no websocket
-- required. Mirrors pulsar_ws/namespaces/mdtAlerts.js's socket.on(...) handlers as plain server events instead. ----

RegisterNetEvent("EmergencyAlerts:Server:ChangeUnitType", function(job, primary, unitType)
	plsr.EmergencyAlerts:ChangeUnitType(source, job, primary, unitType)
end)

RegisterNetEvent("EmergencyAlerts:Server:ChangeAvailability", function(job, primary)
	plsr.EmergencyAlerts:ChangeAvailability(source, job, primary)
end)

RegisterNetEvent("EmergencyAlerts:Server:OperateUnder", function(job, primary, parentPrimary)
	plsr.EmergencyAlerts:OperateUnder(source, job, primary, parentPrimary)
end)

RegisterNetEvent("EmergencyAlerts:Server:BreakOffUnit", function(job, primary, parentPrimary)
	plsr.EmergencyAlerts:BreakOffUnit(source, job, primary, parentPrimary)
end)

RegisterNetEvent("EmergencyAlerts:Server:ChangeRadioChannel", function(channel)
	plsr.EmergencyAlerts:ChangeRadioChannel(source, channel)
end)

RegisterNetEvent("EmergencyAlerts:Server:ChangePursuitMode", function(mode)
	plsr.EmergencyAlerts:ChangePursuitMode(source, mode)
end)

RegisterNetEvent("EmergencyAlerts:Server:UpdateAlertUnits", function(alertId, units)
	plsr.EmergencyAlerts:UpdateAlertUnits(source, alertId, units)
end)

RegisterNetEvent("EmergencyAlerts:Server:RemoveAlert", function(alertId)
	plsr.EmergencyAlerts:RemoveAlert(source, alertId)
end)

RegisterNetEvent("EmergencyAlerts:Server:AddRadioInfo", function(radio, text)
	plsr.EmergencyAlerts:AddRadioInfo(source, radio, text)
end)

RegisterNetEvent("EmergencyAlerts:Server:UpdateRadioInfo", function(id, radio, text)
	plsr.EmergencyAlerts:UpdateRadioInfo(source, id, radio, text)
end)

RegisterNetEvent("EmergencyAlerts:Server:RemoveRadioInfo", function(id)
	plsr.EmergencyAlerts:RemoveRadioInfo(source, id)
end)

RegisterNetEvent("EmergencyAlerts:Server:LogMessage", function(message)
	plsr.EmergencyAlerts:LogMessage(source, message)
end)