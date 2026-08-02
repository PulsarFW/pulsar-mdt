local config = load(LoadResourceFile(GetCurrentResourceName(), "config/shared.lua"))()
local serverConfig = load(LoadResourceFile(GetCurrentResourceName(), "config/server.lua"))()

_alertsPermMap = {
	[1] = "police_alerts",
	[2] = "ems_alerts",
	[3] = "tow_alerts",
	[4] = "doc_alerts",
}

_alertValidTypes = {
	police = {
		"car",
		"motorcycle",
		"air1",
	},
	ems = {
		"bus",
		"car",
		"lifeflight",
	},
	tow = {
		"truck-pickup",
	},
	prison = {
		"car",
	},
}

_alertTypeNames = {
	car = "Ground",
	motorcycle = "Motorcycle",
	air1 = "Air",
	bus = "Ambo",
	lifeflight = "Life Flight",
}

_alertsDefaultType = {
	police = _alertValidTypes.police[1],
	ems = _alertValidTypes.ems[1],
	tow = _alertValidTypes.tow[1],
	prison = _alertValidTypes.prison[1],
}

-- alertGroup (police_alerts/ems_alerts/tow_alerts) -> notification card style, mirrors old mdtAlerts.js's alertGroupStyles
local _alertGroupStyles = {
	police_alerts = 1,
	ems_alerts = 2,
	tow_alerts = 3,
}

local _logColors = {
	ems = "#2b0215",
	prison = "#52c7b8",
}

-- native dispatch state (units/alerts/log/radio) broadcasts over the Lua->NUI bridge; alert delivery is exclusive to native or the pulsar_ws mirror per config.Alerts.Websocket never both

_dispatchUnits = { police = {}, ems = {}, prison = {}, tow = {} }
_dispatchAlerts = {}
_dispatchLog = {}
_dispatchRadioNames = {
	{ radio = "1", text = "EMS" },
	{ radio = "2", text = "DOC" },
	{ radio = "3", text = "PD #1" },
}

local function findUnitIndex(job, primary)
	local list = _dispatchUnits[job]
	if not list then
		return nil
	end
	for i, u in ipairs(list) do
		if u.primary == primary then
			return i
		end
	end
	return nil
end

local function findUnitBySource(source)
	for job, list in pairs(_dispatchUnits) do
		for i, u in ipairs(list) do
			if u.source == source then
				return u, job, i
			end
		end
	end
	return nil, nil, nil
end

local function resolveAlertGroups(alertType)
	if type(alertType) == "table" then
		return alertType
	elseif type(alertType) == "string" then
		return { alertType }
	end
	return {}
end

local function eligibleForAlert(member, groups)
	for _, g in ipairs(groups) do
		if member.AlertPermissions[g] then
			return true
		end
	end
	return false
end

local function broadcastToOnDuty(event, ...)
	for k, v in pairs(emergencyAlertsData) do
		TriggerClientEvent(event, k, ...)
	end
end

local function addDispatchLog(logType, title, message, color)
	local log = {
		time = os.time() * 1000,
		type = logType,
		title = title,
		message = message,
		color = color,
	}

	table.insert(_dispatchLog, log)
	if #_dispatchLog > serverConfig.Alerts.dispatchLogMaxEntries then
		table.remove(_dispatchLog, 1)
	end

	broadcastToOnDuty("EmergencyAlerts:Client:DispatchLogAdd", log)

	if config.Alerts.Websocket then
		TriggerEvent("ws:mdt-alerts:addDispatchLog", logType, title, message, color)
	end
end

CreateThread(function()
	RegisterEACallbacks()
	StartAETrackingThreads()
end)

AddEventHandler("Proxy:Shared:RegisterReady", function()
	exports["pulsar_core"]:RegisterComponent("EmergencyAlerts", _pdAlerts)
end)

emergencyAlertsData = {}

_pdAlerts = {
	Create = function(self, code, title, alertType, location, description, isPanic, blip, styleOverride, isArea, camera)
		local groups = resolveAlertGroups(alertType)
		local style = styleOverride
		if not style and type(alertType) == "string" then
			style = _alertGroupStyles[alertType]
		end

		local alert = {
			id = string.format("dispatch-%s-%s", GetGameTimer(), math.random(1000, 9999)),
			code = code,
			title = title,
			type = alertType,
			location = location,
			description = description,
			panic = isPanic or false,
			blip = blip or false,
			style = style,
			isArea = isArea or false,
			camera = camera or false,
			attached = {},
			attachedSet = {},
			time = os.time() * 1000,
		}

		table.insert(_dispatchAlerts, alert)
		if #_dispatchAlerts > serverConfig.Alerts.activeAlertsMaxEntries then
			table.remove(_dispatchAlerts, 1)
		end

		if config.Alerts.Websocket then
			TriggerEvent(
				"ws:mdt-alerts:createAlert",
				code, title, alertType, location, description, isPanic, blip, styleOverride, isArea, camera
			)
		else
			for k, v in pairs(emergencyAlertsData) do
				if eligibleForAlert(v, groups) then
					TriggerClientEvent("EmergencyAlerts:Client:DispatchAlertAdd", k, alert)
				end
			end
		end
	end,
	OnDuty = function(self, dutyData, source, stateId, callsign)
		if
			dutyData
			and (dutyData.Id == "police" or dutyData.Id == "ems" or dutyData.Id == "tow" or dutyData.Id == "prison")
		then
			local alertPermissions = {}
			local allJobPermissions = plsr.Jobs.Permissions:GetPermissionsFromJob(source, dutyData.Id)
			for k, v in pairs(_alertsPermMap) do
				if allJobPermissions[v] then
					alertPermissions[v] = true
				end
			end

			local char = plsr.Fetch:CharacterSource(source)
			emergencyAlertsData[source] = {
				SID = stateId,
				Source = source,
				Job = dutyData.Id,
				Workplace = dutyData.WorkplaceId,
				Callsign = callsign,
				Phone = char:GetData("Phone"),
				AlertPermissions = alertPermissions,
				First = dutyData.First,
				Last = dutyData.Last,
				Coords = GetEntityCoords(GetPlayerPed(source)),
			}

			plsr.EmergencyAlerts:SendMemberUpdates()

			-- native dispatch unit, always created regardless of the websocket toggle
			local primary = (dutyData.Id == "tow") and string.format("TOW-%s", stateId) or callsign
			local unit = {
				source = source,
				job = dutyData.Id,
				primary = primary,
				available = true,
				type = _alertsDefaultType[dutyData.Id],
				character = {
					First = dutyData.First,
					Last = dutyData.Last,
					SID = stateId,
					Phone = char:GetData("Phone"),
				},
				operatingUnder = nil,
				pursuitMode = nil,
				radioChannel = nil,
			}
			table.insert(_dispatchUnits[dutyData.Id], unit)

			broadcastToOnDuty("EmergencyAlerts:Client:DispatchUnitAdd", unit)

			-- eligible alerts (created within the last 15 min, or already has units attached) for this member's groups
			local myAlerts = {}
			for _, a in ipairs(_dispatchAlerts) do
				if eligibleForAlert(emergencyAlertsData[source], resolveAlertGroups(a.type))
					and (a.time >= (os.time() * 1000) - serverConfig.Alerts.recentAlertWindowMs or #a.attached > 0)
				then
					table.insert(myAlerts, a)
				end
			end

			TriggerClientEvent(
				"EmergencyAlerts:Client:DispatchInit", source,
				unit, myAlerts, _dispatchUnits, _dispatchRadioNames, _dispatchLog
			)

			if dutyData.Id == "police" or dutyData.Id == "prison" then
				addDispatchLog("dutyChange", nil, string.format(
					"[%s] %s. %s is 10-41 (On Duty)",
					char:GetData("Callsign"),
					char:GetData("First"):sub(1, 1),
					char:GetData("Last")
				), _logColors[dutyData.Id])
			end

			if config.Alerts.Websocket then
				-- if the default "localhost" is used, it is actually replaced with the real server endpoint for the client on the client side (since the endpoint isn't known here)
				local url = GetConvar("WS_MDT_ALERTS_WSS", "http://localhost:4002/mdt-alerts")
				local token = exports["pulsar_ws"]:generateSocketToken("mdt-alerts", {
					source = source,
					job = dutyData.Id,
					callsign = primary,
				})

				TriggerClientEvent("EmergencyAlerts:Client:Connect", source, url, token)
			end

			if plsr.State:Player(source).trackerDisabled then
				plsr.State:SetPublicFlag(source, 'trackerDisabled', false)
			end
		end
	end,
	GetUnitData = function(self, source, job)
		local char = plsr.Fetch:CharacterSource(source)
		if char then
			local alertPermissions = {}
			local allJobPermissions = plsr.Jobs.Permissions:GetPermissionsFromJob(source, job)
			if allJobPermissions then
				for k, v in pairs(_alertsPermMap) do
					if allJobPermissions[v] then
						table.insert(alertPermissions, v)
					end
				end
			end

			return {
				character = {
					SID = char:GetData("SID"),
					First = char:GetData("First"),
					Last = char:GetData("Last"),
					Phone = char:GetData("Phone"),
				},
				alerts = alertPermissions
			}
		end
	end,
	OffDuty = function(self, dutyData, source, stateId)
		local emergencyMember = emergencyAlertsData[source]
		if emergencyMember then
			local unit, job = findUnitBySource(source)
			if unit and job then
				for i, u in ipairs(_dispatchUnits[job]) do
					if u.source == source then
						table.remove(_dispatchUnits[job], i)
						break
					end
				end

				-- units operating under the departing unit break off automatically
				for _, u in ipairs(_dispatchUnits[job]) do
					if u.operatingUnder == unit.primary then
						u.operatingUnder = nil
						broadcastToOnDuty("EmergencyAlerts:Client:DispatchUnitUpdate", job, u.primary, "operatingUnder", nil)
					end
				end

				broadcastToOnDuty("EmergencyAlerts:Client:DispatchUnitRemove", job, source)
			end

			if config.Alerts.Websocket then
				TriggerClientEvent("EmergencyAlerts:Client:Disconnect", source)
			end

			local c = plsr.Fetch:CharacterSource(source)
			if c and dutyData and dutyData.Id == "police" or dutyData.Id == "prison" then
				addDispatchLog("dutyChange", nil, string.format(
					"[%s] %s. %s is 10-42 (Off Duty)",
					c:GetData("Callsign"),
					c:GetData("First"):sub(1, 1),
					c:GetData("Last")
				), _logColors[dutyData.Id])
			end

			emergencyAlertsData[source] = nil

			plsr.EmergencyAlerts:SendMemberUpdates()
		end
	end,
	DisableTracker = function(self, source, state)
		local emergencyMember = emergencyAlertsData[source]
		if
			emergencyMember
			and (emergencyMember.Job == "police" or emergencyMember.Job == "prison" or emergencyMember.Job == "ems")
			and emergencyMember.TrackerDisabled ~= state
		then
			emergencyAlertsData[source].TrackerDisabled = state

			plsr.EmergencyAlerts:SendOnDutyEvent("EmergencyAlerts:Client:UpdateMember", emergencyAlertsData[source])
		end
	end,
	RefreshCallsign = function(self, stateId, newCallsign)
		for k, v in pairs(emergencyAlertsData) do
			if v.SID == stateId then
				emergencyAlertsData[k].Callsign = newCallsign
			end
		end
	end,
	SendMemberUpdates = function(self)
		plsr.EmergencyAlerts:SendOnDutyEvent("EmergencyAlerts:Client:UpdateMembers", emergencyAlertsData)
	end,
	SendOnDutyEvent = function(self, event, data)
		for k, v in pairs(emergencyAlertsData) do
			TriggerClientEvent(event, k, data)
		end
	end,
	-- ---- Dispatch actions (fired from the new client NUI callbacks, see client/alerts/nui.lua) ----
	ChangeUnitType = function(self, source, job, primary, unitType)
		local i = findUnitIndex(job, primary)
		if not i then
			return
		end
		_dispatchUnits[job][i].type = unitType
		broadcastToOnDuty("EmergencyAlerts:Client:DispatchUnitUpdate", job, primary, "type", unitType)
		addDispatchLog("unitChange", nil, string.format("%s Transitioning to %s Unit", primary, _alertTypeNames[unitType] or unitType), _logColors[job])
	end,
	ChangeAvailability = function(self, source, job, primary)
		local i = findUnitIndex(job, primary)
		if not i then
			return
		end
		local unit = _dispatchUnits[job][i]
		unit.available = not unit.available
		broadcastToOnDuty("EmergencyAlerts:Client:DispatchUnitUpdate", job, primary, "available", unit.available)
		addDispatchLog("availabilityChange", nil, string.format("%s is now %s", primary, unit.available and "10-8 (Available)" or "10-6 (Unavailable)"), _logColors[job])
	end,
	OperateUnder = function(self, source, job, primary, parentPrimary)
		local i = findUnitIndex(job, primary)
		if not i then
			return
		end
		_dispatchUnits[job][i].operatingUnder = parentPrimary
		broadcastToOnDuty("EmergencyAlerts:Client:DispatchUnitOperateUnder", job, primary, parentPrimary)
		addDispatchLog("subUnitChanges", nil, string.format("%s Now Operating Under %s", primary, parentPrimary), _logColors[job])
	end,
	BreakOffUnit = function(self, source, job, primary, parentPrimary)
		local i = findUnitIndex(job, primary)
		if not i then
			return
		end
		_dispatchUnits[job][i].operatingUnder = nil
		broadcastToOnDuty("EmergencyAlerts:Client:DispatchUnitBreakOff", job, primary)
		addDispatchLog("subUnitChanges", nil, string.format("%s Breaking Off From %s", primary, parentPrimary), _logColors[job])
	end,
	ChangeRadioChannel = function(self, source, channel)
		local unit = findUnitBySource(source)
		if not unit then
			return
		end
		unit.radioChannel = channel
		broadcastToOnDuty("EmergencyAlerts:Client:DispatchUnitUpdate", unit.job, unit.primary, "radioChannel", channel)
	end,
	ChangePursuitMode = function(self, source, mode)
		local unit, job = findUnitBySource(source)
		if not unit then
			return
		end
		local i = findUnitIndex(job, unit.operatingUnder ~= nil and unit.operatingUnder or unit.primary)
		if not i then
			return
		end
		_dispatchUnits[job][i].pursuitMode = mode
		broadcastToOnDuty("EmergencyAlerts:Client:DispatchUnitUpdate", job, _dispatchUnits[job][i].primary, "pursuitMode", mode)
	end,
	UpdateAlertUnits = function(self, source, alertId, units)
		local alert
		for _, a in ipairs(_dispatchAlerts) do
			if a.id == alertId then
				alert = a
				break
			end
		end
		if not alert then
			return
		end

		local newSet = {}
		for _, callsign in ipairs(units) do
			newSet[callsign] = true
		end

		for callsign in pairs(newSet) do
			if not alert.attachedSet[callsign] then
				addDispatchLog("attaching", nil, string.format("%s Attached to %s | %s", callsign, alert.code, alert.title), "#5D348B")
			end
		end
		for callsign in pairs(alert.attachedSet) do
			if not newSet[callsign] then
				addDispatchLog("attaching", nil, string.format("%s Detached From %s | %s", callsign, alert.code, alert.title), "#5D348B")
			end
		end

		alert.attached = units
		alert.attachedSet = newSet

		for k, v in pairs(emergencyAlertsData) do
			TriggerClientEvent("EmergencyAlerts:Client:DispatchAlertUpdateUnits", k, alertId, units)
		end
	end,
	RemoveAlert = function(self, source, alertId)
		for i, a in ipairs(_dispatchAlerts) do
			if a.id == alertId then
				table.remove(_dispatchAlerts, i)
				break
			end
		end
		broadcastToOnDuty("EmergencyAlerts:Client:DispatchAlertRemove", alertId)
	end,
	AddRadioInfo = function(self, source, radio, text)
		table.insert(_dispatchRadioNames, { radio = radio, text = text })
		broadcastToOnDuty("EmergencyAlerts:Client:DispatchRadioUpdate", _dispatchRadioNames)
		addDispatchLog("radioUpdate", nil, string.format("Radio Added: %s | %s", radio, text), "#6e6e6e")
	end,
	UpdateRadioInfo = function(self, source, id, radio, text)
		local entry = _dispatchRadioNames[id + 1]
		if not entry or entry.radio ~= radio then
			return
		end
		entry.text = text
		broadcastToOnDuty("EmergencyAlerts:Client:DispatchRadioUpdate", _dispatchRadioNames)
	end,
	RemoveRadioInfo = function(self, source, id)
		local entry = _dispatchRadioNames[id + 1]
		if not entry then
			return
		end
		table.remove(_dispatchRadioNames, id + 1)
		broadcastToOnDuty("EmergencyAlerts:Client:DispatchRadioUpdate", _dispatchRadioNames)
		addDispatchLog("radioUpdate", nil, string.format("Radio Removed: %s", entry.radio), "#6e6e6e")
	end,
	LogMessage = function(self, source, message)
		local member = emergencyAlertsData[source]
		if not member then
			return
		end
		local jobNames = { police = "PD", ems = "EMS", prison = "DOC", tow = "TOW" }
		addDispatchLog("message", string.format("%s Message | [%s] %s. %s", jobNames[member.Job] or member.Job, member.Callsign, member.First:sub(1, 1), member.Last), message, _logColors[member.Job])
	end,
}
