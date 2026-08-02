local config = load(LoadResourceFile(GetCurrentResourceName(), "config/shared.lua"))()

function RegisterChatCommands()
	plsr.Chat:RegisterAdminCommand("setcallsign", function(source, args, rawCommand)
		local newCallsign = args[2]
		local target = plsr.Fetch:SID(tonumber(args[1]))
		if target ~= nil then
			if
				plsr.Jobs.Permissions:HasJob(target:GetData("Source"), "police")
				or plsr.Jobs.Permissions:HasJob(target:GetData("Source"), "ems")
			then
				if plsr.MDT.People:Update(-1, target:GetData("SID"), "Callsign", newCallsign) then
					plsr.Chat.Send.System:Single(source, "Updated Callsign")
				else
					plsr.Chat.Send.System:Single(source, "Error Updating Callsign")
				end
			else
				plsr.Chat.Send.System:Single(source, "Target is not Emergency Personnel")
			end
		else
			plsr.Chat.Send.System:Single(source, "Invalid State ID")
		end
	end, {
		help = "Assign a callsign to an emergency worker",
		params = {
			{
				name = "Target",
				help = "State ID",
			},
			{
				name = "Callsign",
				help = "The callsign you want to assign to the player. This must be unique",
			},
		},
	}, 2)

	plsr.Chat:RegisterAdminCommand("reclaimcallsign", function(source, args, rawCommand)
		plsr.Database:Single("SELECT `id`, `data` FROM `characters` WHERE `callsign` = ? AND `deleted` = 0", { args[1] }, function(success, row)
			if not success or row == nil then
				plsr.Chat.Send.System:Single(source, "Nobody With That Callsign")
				return
			end
			local ok, existing = pcall(json.decode, row.data)
			if not ok or type(existing) ~= "table" then
				plsr.Chat.Send.System:Single(source, "Nobody With That Callsign")
				return
			end
			existing.Callsign = false

			plsr.Database:Update("UPDATE `characters` SET `data` = ?, `callsign` = NULL WHERE `id` = ?", { json.encode(existing), row.id }, function(updateSuccess)
				if updateSuccess then
					local char = plsr.Fetch:SID(existing.SID)
					if char then
						char:SetData("Callsign", false)
					end

					plsr.Chat.Send.System:Single(source, string.format("Callsign Reclaimed From %s %s (%s)", existing.First, existing.Last, existing.SID))
				else
					plsr.Chat.Send.System:Single(source, "Nobody With That Callsign")
				end
			end)
		end)
	end, {
		help = "Force Reclaim a Callsign",
		params = {
			{
				name = "Callsign",
				help = "The callsign you want to reclaim.",
			},
		},
	}, 1)

	plsr.Chat:RegisterCommand(
		"mdt",
		function(source, args, rawCommand)
			TriggerClientEvent("MDT:Client:Toggle", source)
		end,
		{
			help = "Open MDT",
		},
		0,
		{
			{
				Id = "police",
			},
			{
				Id = "government",
			},
			{
				Id = "ems",
			},
			{
				Id = "prison",
			},
		}
	)

	plsr.Chat:RegisterAdminCommand("addmdtsysadmin", function(source, args, rawCommand)
		local targetStateId = math.tointeger(args[1])
		local success = plsr.MDT.People:Update(-1, targetStateId, "MDTSystemAdmin", true)
		if success then
			plsr.Chat.Send.System:Single(source, "Granted System Admin to State ID: " .. targetStateId)
		else
			plsr.Chat.Send.System:Single(source, "Error Granting System Admin")
		end
	end, {
		help = "Grant MDT System Admin [Danger!]",
		params = {
			{
				name = "Target State ID",
				help = "State ID of Character",
			},
		},
	}, 1)

	plsr.Chat:RegisterAdminCommand("removemdtsysadmin", function(source, args, rawCommand)
		local targetStateId = math.tointeger(args[1])
		local success = plsr.MDT.People:Update(-1, targetStateId, "MDTSystemAdmin", false)
		if success then
			plsr.Chat.Send.System:Single(source, "Revoked System Admin from State ID: " .. targetStateId)
		else
			plsr.Chat.Send.System:Single(source, "Error Revoking System Admin")
		end
	end, {
		help = "Revoke MDT System Admin",
		params = {
			{
				name = "Target State ID",
				help = "State ID of Character",
			},
		},
	}, 1)

	plsr.Chat:RegisterAdminCommand("testalert", function(source, args, rawCommand)
		local coords = GetEntityCoords(GetPlayerPed(source))
		plsr.Callbacks:ClientCallback(source, "EmergencyAlerts:GetStreetName", coords, function(location)
			plsr.EmergencyAlerts:Create(
				"TEST",
				"Test Alert",
				{ "police_alerts", "ems_alerts", "tow_alerts", "doc_alerts" },
				location,
				{ icon = "question", details = "Dispatched via /testalert" },
				false,
				{ icon = 280, size = 0.9, color = 1, duration = 120 },
				nil,
				false,
				false
			)

			plsr.Chat.Send.System:Single(source, string.format(
				"Test alert dispatched to the native dispatch panel (websocket mirror: %s)",
				config.Alerts.Websocket and "ENABLED, check pulsar_ws for the mirrored event" or "DISABLED"
			))
		end)
	end, {
		help = "Fire a test dispatch alert - always hits the native panel, also mirrors to the websocket if config.Alerts.Websocket is enabled",
	}, 1)

	plsr.Chat:RegisterCommand(
		"clearblips",
		function(source, args, rawCommand)
			TriggerClientEvent("EmergencyAlerts:Client:Clear", source)
		end,
		{
			help = "Clear Emergency Alert Blips",
		},
		0,
		{
			{
				Id = "police",
			},
			{
				Id = "ems",
			},
			{
				Id = "tow",
			}
		}
	)
end
