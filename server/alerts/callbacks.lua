local config = load(LoadResourceFile(GetCurrentResourceName(), "config/server.lua"))()
local sharedConfig = load(LoadResourceFile(GetCurrentResourceName(), "config/shared.lua"))()

local trackerJobs = {}
for _, jobId in ipairs(sharedConfig.Jobs.tracked) do
	trackerJobs[jobId] = true
end

function RegisterEACallbacks()
	plsr.Callbacks:RegisterServerCallback("EmergencyAlerts:DisablePDTracker", function(source, target, cb)
		local char = plsr.Fetch:CharacterSource(source)
		if char then
			local targetChar = plsr.Fetch:CharacterSource(target)
			local targetDuty = plsr.State:Player(target).onDuty
			if targetChar and trackerJobs[targetDuty] and not plsr.State:Player(target).trackerDisabled then
				plsr.State:SetPublicFlag(target, 'trackerDisabled', true)
				plsr.EmergencyAlerts:DisableTracker(target, true)


				local coords = GetEntityCoords(GetPlayerPed(target))
				plsr.Callbacks:ClientCallback(target, "EmergencyAlerts:GetStreetName", coords, function(location)
					local radioFreq = "Unknown Radio Frequency"
					if plsr.State:Player(target).onRadio then
						radioFreq = string.format("Radio Freq: %s", plsr.State:Player(target).onRadio)
					else
						radioFreq = "Not On Radio"
					end
	
					
					if targetDuty == "police" then
						plsr.EmergencyAlerts:Create("13-C", "Officer Tracker Disabled", "police_alerts", location, {
							icon = "circle-exclamation",
							details = string.format(
								"%s - %s %s | %s",
								targetChar:GetData("Callsign") or "UNKN",
								targetChar:GetData("First"),
								targetChar:GetData("Last"),
								radioFreq
							)
						}, false, {
							icon = 303,
							size = 1.2,
							color = 26,
							duration = config.Alerts.trackerDisabledAlertDurationSec,
						}, 1)
					elseif targetDuty == "prison" then
						plsr.EmergencyAlerts:Create("13-C", "DOC Officer Tracker Disabled", {"police_alerts", "doc_alerts"}, location, {
							icon = "circle-exclamation",
							details = string.format(
								"%s - %s %s | %s",
								targetChar:GetData("Callsign") or "UNKN",
								targetChar:GetData("First"),
								targetChar:GetData("Last"),
								radioFreq
							)
						}, false, {
							icon = 303,
							size = 1.2,
							color = 26,
							duration = config.Alerts.trackerDisabledAlertDurationSec,
						}, 1)
					elseif targetDuty == "ems" then
						plsr.EmergencyAlerts:Create("13-C", "Medic Tracker Disabled", {"police_alerts", "ems_alerts"}, location, {
							icon = "circle-exclamation",
							details = string.format(
								"%s - %s %s | %s",
								targetChar:GetData("Callsign") or "UNKN",
								targetChar:GetData("First"),
								targetChar:GetData("Last"),
								radioFreq
							)
						}, false, {
							icon = 303,
							size = 1.2,
							color = 48,
							duration = config.Alerts.trackerDisabledAlertDurationSec,
						}, 2)
					end
				end)

				plsr.Execute:Client(target, "Notification", "Info", "Your Tracker Has Been Disabled")
				cb(true)
				return
			end
		end
		cb(false)
	end)

	-- PD re-enabling their own tracker
	plsr.Callbacks:RegisterServerCallback("EmergencyAlerts:EnablePDTracker", function(source, target, cb)
		local char = plsr.Fetch:CharacterSource(source)
		if char and trackerJobs[plsr.State:Player(source).onDuty] and plsr.State:Player(source).trackerDisabled then
			plsr.State:SetPublicFlag(source, 'trackerDisabled', false)
			plsr.EmergencyAlerts:DisableTracker(source, false)

			local job = plsr.State:Player(source).onDuty

			plsr.Jobs.Duty:Off(source, false, true)
			Wait(250)
			plsr.Jobs.Duty:On(source, job, true)

			cb(true)
		else
			cb(false)
		end
	end)
end