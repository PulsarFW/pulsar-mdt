local config = load(LoadResourceFile(GetCurrentResourceName(), "config/server.lua"))()
local sharedConfig = load(LoadResourceFile(GetCurrentResourceName(), "config/shared.lua"))()

_MDT = _MDT or {}
_bolos = {}
_breakpoints = config.Points

_governmentJobs = sharedConfig.Jobs.portals
_permissions = sharedConfig.Permissions
_qualifications = sharedConfig.Qualifications

local governmentJobs = {}
for _, jobId in ipairs(sharedConfig.Jobs.dutyTriggers) do
	governmentJobs[jobId] = true
end

_onDutyUsers = {}
_onDutyLawyers = {}

_dojWorkers = {}

_governmentJobData = {}

local sentencedSuspects = {}

CreateThread(function()
	RegisterChatCommands()
	RegisterMiddleware()
	Startup()
	TriggerEvent("MDT:Server:RegisterCallbacks")

	Wait(2500)
	UpdateMDTJobsData()
end)

AddEventHandler("Proxy:Shared:RegisterReady", function()
	exports["pulsar_core"]:RegisterComponent("MDT", _MDT)
end)

AddEventHandler("Characters:Server:PlayerLoggedOut", function(source, cData)
	_onDutyLawyers[source] = nil
end)

AddEventHandler("Characters:Server:PlayerDropped", function(source, cData)
	_onDutyLawyers[source] = nil
end)

function RegisterMiddleware()
    plsr.Middleware:Add('Characters:Spawning', function(source)
		local char = plsr.Fetch:CharacterSource(source)
		if char and char:GetData("Attorney") then
			Citizen.SetTimeout(5000, function()
				TriggerClientEvent("MDT:Client:Login", source, nil, nil, nil, true, {
					governmentJobs = _governmentJobs,
					charges = _charges,
					governmentJobsData = _governmentJobData,
				})
				_onDutyLawyers[source] = char:GetData('SID')
			end)
		end
    end, 50)
end

function UpdateMDTJobsData()
	local newData = {}
	local allJobData = plsr.Jobs:GetAll()
	for k, v in ipairs(_governmentJobs) do
		newData[v] = allJobData[v]
	end

	_governmentJobData = newData
	TriggerClientEvent("MDT:Client:SetData", -1, "governmentJobsData", _governmentJobData)
end

AddEventHandler('Jobs:Server:UpdatedCache', function(job)
	if job == -1 or governmentJobs[job] then
		UpdateMDTJobsData()
	end
end)

AddEventHandler('Job:Server:DutyAdd', function(dutyData, source, SID)
	if governmentJobs[dutyData.Id] then
		local job = plsr.Jobs.Permissions:HasJob(source, dutyData.Id)
		if job then
			_onDutyUsers[source] = job.Id
			local permissions = plsr.Jobs.Permissions:GetPermissionsFromJob(source, job.Id)
	
			TriggerClientEvent("MDT:Client:Login", source, _breakpoints, job, permissions, false, {
				governmentJobs = _governmentJobs,
				charges = _charges,
				governmentJobsData = _governmentJobData,
				permissions = _permissions,
				qualifications = _qualifications,
				bolos = _bolos,
			})

			local char = plsr.Fetch:CharacterSource(source)
			if char and job.Id == "government" then
				_dojWorkers[source] = {
					First = char:GetData("First"),
					Last = char:GetData("Last"),
					SID = char:GetData("SID"),
					Phone = char:GetData("Phone"),

					Job = job.Name,
					Workplace = job.Workplace.Name,
					Grade = job.Grade.Name,
				}
			end
		end
	end
end)

AddEventHandler('Jobs:Server:JobUpdate', function(source)
	local dutyData = plsr.Jobs.Duty:Get(source)
	if dutyData and governmentJobs[dutyData.Id] then
		local job = plsr.Jobs.Permissions:HasJob(source, dutyData.Id)
		if job then
			local permissions = plsr.Jobs.Permissions:GetPermissionsFromJob(source, job.Id)
			TriggerClientEvent('MDT:Client:UpdateJobData', source, job, permissions)
		end
	end
end)

AddEventHandler('Job:Server:DutyRemove', function(dutyData, source, SID)
	if governmentJobs[dutyData.Id] then
		_onDutyUsers[source] = nil
		_dojWorkers[source] = nil
		TriggerClientEvent("MDT:Client:Logout", source)
	end
end)

function CheckMDTPermissions(source, permission, jobId)
	local mdtUser = _onDutyUsers[source]
	if mdtUser and (not jobId or jobId == mdtUser or (type(jobId) == 'table' and jobId[mdtUser])) then
		if not permission then
			return true
		end

		if type(permission) == 'string' then
			local hasPerm = plsr.Jobs.Permissions:HasPermissionInJob(source, mdtUser, permission)
			if hasPerm then
				return true, mdtUser
			end
		elseif type(permission) == 'table' then
			local jobPermissions = plsr.Jobs.Permissions:GetPermissionsFromJob(source, mdtUser)
			for k, v in ipairs(permission) do
				if jobPermissions[v] then
					return true, mdtUser
				end
			end
		end
		
		local char = plsr.Fetch:CharacterSource(source)
		if char:GetData('MDTSystemAdmin') then -- They have all permissions
			return true, mdtUser
		end
	end
	return false
end

RegisterNetEvent('MDT:Server:OpenPublicRecords', function()
	local src = source
	local dutyData = plsr.Jobs.Duty:Get(src)

	if not _onDutyUsers[src] then
		TriggerClientEvent("MDT:Client:SetMultipleData", src, {
			governmentJobs = _governmentJobs,
			charges = _charges,
			governmentJobsData = _governmentJobData,
			prison = false,
		})
	end

	TriggerClientEvent('MDT:Client:Toggle', src)
end)

RegisterNetEvent('MDT:Server:OpenDOCPublic', function()
	local src = source
	if not _onDutyUsers[src] then
		TriggerClientEvent("MDT:Client:SetMultipleData", src, {
			governmentJobs = _governmentJobs,
			charges = _charges,
			prison = true,
		})
	else
		TriggerClientEvent("MDT:Client:SetMultipleData", src, {
			prison = true,
		})
	end

	TriggerClientEvent('MDT:Client:Toggle', src)
end)

AddEventHandler("MDT:Server:RegisterCallbacks", function()
	plsr.Callbacks:RegisterServerCallback("MDT:GetHomeData", function(source, data, cb)
		local gJob = _onDutyUsers[source]
		local warrants = MySQL.query.await("SELECT id, state, report, suspect, title, creatorSID, creatorName, creatorCallsign, issued, expires FROM mdt_warrants WHERE state = ? AND expires > NOW() ORDER BY issued DESC LIMIT 5", {
			"active"
		})

		local notices
		if gJob then
			notices = MySQL.query.await("SELECT `id`, title, created FROM mdt_notices WHERE restricted IN (?, ?, ?)", {
				"public",
				"government",
				gJob,
			})
		else
			notices = MySQL.query.await("SELECT `id`, title, created FROM mdt_notices WHERE restricted = ?", {
				"public",
			})
		end

		local gWorkers = {}
		for k, v in pairs(_dojWorkers) do
			table.insert(gWorkers, v)
		end

		cb({
			warrants = warrants,
			notices = notices,
			govWorkers = gWorkers,
		})
	end)

	plsr.Callbacks:RegisterServerCallback("MDT:IssueWarrant", function(source, data, cb)
		local char = plsr.Fetch:CharacterSource(source)

		if char and CheckMDTPermissions(source, false) and data.report and data.suspect and data.suspect.id then
			local id = plsr.MDT.Warrants:Create(data.report, data.suspect, data.notes, {
				SID = char:GetData("SID"),
				First = char:GetData("First"),
				Last = char:GetData("Last"),
				Callsign = char:GetData("Callsign"),
			})

			if id then
				MySQL.query.await("UPDATE mdt_reports_people SET warrant = ? WHERE type = ? AND SID = ? AND report = ?", {
					id,
					"suspect",
					data.suspect.SID,
					data.report,
				})

				cb(true)
				return
			end
		end

		cb(false)
	end)

	plsr.Callbacks:RegisterServerCallback("MDT:SentencePlayer", function(source, data, cb)
		local char = plsr.Fetch:CharacterSource(source)

		if CheckMDTPermissions(source, false) and data.report and not data.data.sentenced then
			if not sentencedSuspects[data.report] then
				sentencedSuspects[data.report] = {}
			end
			local transactions = {}

			if data.data.SID and not sentencedSuspects[data.report][data.data.SID] then
				table.insert(transactions, {
					query = "UPDATE mdt_reports_people SET sentenced = ?, sentencedAt = NOW(), points = ?, fine = ?, jail = ?, parole = ?, reduction = ?, revoked = ?, doc = ? WHERE type = ? AND SID = ? AND report = ? AND sentenced = ?",
					values = {
						1,
						data.points,
						data.fine,
						data.jail,
						data.parole?.parole or 0,
						json.encode({
							type = data.sentence.type,
							value = data.sentence.value,
						}),
						json.encode(data.sentence.revoke),
						data.sentence.doc and 1 or 0,
						
						"suspect",
						data.data.SID,
						data.report,
						0
					}
				})

				if data.parole ~= nil then
					table.insert(transactions, {
						query = "INSERT INTO character_parole (SID, end, total, parole, sentence, fine) VALUES (?, FROM_UNIXTIME(?), ?, ?, ?, ?) ON DUPLICATE KEY UPDATE end = VALUES(end), total = VALUES(total), parole = VALUES(parole), sentence = VALUES(sentence), fine = VALUES(fine)",
						values = {
							data.data.SID,
							math.ceil(data.parole["end"]),
							data.parole.total,
							data.parole.parole,
							data.parole.sentence,
							data.parole.fine
						}
					})
				end

				table.insert(transactions, {
					query = "UPDATE mdt_warrants SET state = ? WHERE report = ? AND suspect = ?",
					values = {
						"served",
						data.report,
						data.data.id,
					}
				})

				MySQL.transaction.await(transactions)

				if data.sentence.revoke or data.points > 0 then
					local needsUpdate = false
					local pointsInc = 0
					local revokeSet = {}

					if data.points > 0 then
						needsUpdate = true
						pointsInc = data.points
					end

					if data.sentence.revoke then
						for k, v in pairs(data.sentence.revoke) do
							if v then
								needsUpdate = true

								if k == 'drivers' then
									revokeSet.Drivers = { Active = false, Suspended = true }
								elseif k == 'weapons' then
									revokeSet.Weapons = { Active = false, Suspended = true }
								elseif k == 'hunting' then
									revokeSet.Hunting = { Active = false, Suspended = true }
								elseif k == 'fishing' then
									revokeSet.Fishing = { Active = false, Suspended = true }
								end
							end
						end
					end

					if needsUpdate then
						local p = promise.new()
						plsr.Database:Single("SELECT `id`, `data` FROM `characters` WHERE `sid` = ? AND `deleted` = 0", { data.data.SID }, function(success, row)
							if not success or row == nil then
								p:resolve(false)
								return
							end
							local ok, existing = pcall(json.decode, row.data)
							if not ok or type(existing) ~= "table" then
								p:resolve(false)
								return
							end

							if not existing.Licenses then
								existing.Licenses = {}
							end
							if pointsInc ~= 0 then
								if not existing.Licenses.Drivers then
									existing.Licenses.Drivers = {}
								end
								existing.Licenses.Drivers.Points = (existing.Licenses.Drivers.Points or 0) + pointsInc
							end
							for licenseType, flags in pairs(revokeSet) do
								if not existing.Licenses[licenseType] then
									existing.Licenses[licenseType] = {}
								end
								existing.Licenses[licenseType].Active = flags.Active
								existing.Licenses[licenseType].Suspended = flags.Suspended
							end

							plsr.Database:Update("UPDATE `characters` SET `data` = ? WHERE `id` = ?", { json.encode(existing), row.id }, function(updateSuccess)
								if updateSuccess then
									local char = plsr.Fetch:SID(data.data.SID)
									if char then
										char:SetData('Licenses', existing.Licenses)
									end
								end
								p:resolve(updateSuccess)
							end)
						end)

						Citizen.Await(p)
					end
				end
				cb(true)
			else
				cb(false)
			end
		else
			cb(false)
		end
	end)

	plsr.Callbacks:RegisterServerCallback("MDT:OverturnSentence", function(source, data, cb)
		local char = plsr.Fetch:CharacterSource(source)

		if CheckMDTPermissions(source, "DOJ_OVERTURN_CHARGES") and data.report and data.SID then
			plsr.Logger:Warn(
				"MDT",
				string.format(
					"%s %s (%s) Overturned Charges From State ID %s on Report %s",
					char:GetData("First"),
					char:GetData("Last"),
					char:GetData("SID"),
					data.SID,
					data.report
				),
				{
					console = true,
					file = true,
					database = true,
					discord = {
						embed = true,
					},
				}
			)

			MySQL.query.await("UPDATE mdt_reports_people SET type = ? WHERE report = ? AND type = ? AND SID = ? AND sentenced = ?", {
				"suspectOverturned",
				data.report,
				"suspect",
				data.SID,
				1
			})

			cb(true)
		else
			cb(false)
		end
	end)

	plsr.Callbacks:RegisterServerCallback("MDT:RosterView", function(source, data, cb)
		plsr.Database:Query(
			"SELECT `data` FROM `characters` WHERE JSON_CONTAINS(JSON_EXTRACT(`data`, '$.Jobs'), JSON_OBJECT('Id', ?), '$') AND `deleted` = 0",
			{ data.job },
			function(success, rows)
				if not success then
					cb({})
					return
				end

				local results = {}
				for k, row in ipairs(rows) do
					local ok, v = pcall(json.decode, row.data)
					if ok and type(v) == "table" then
						local matchedJob = nil
						for _, j in ipairs(v.Jobs or {}) do
							if j.Id == data.job then
								matchedJob = j
								break
							end
						end
						table.insert(results, {
							Mugshot = v.Mugshot,
							First = v.First,
							Last = v.Last,
							SID = v.SID,
							Callsign = v.Callsign,
							Jobs = matchedJob and { matchedJob } or {},
						})
					end
				end
				cb(results)
			end
		)
	end)

	plsr.Callbacks:RegisterServerCallback("MDT:RosterSelect", function(source, data, cb)
		plsr.Database:Single("SELECT `data` FROM `characters` WHERE `sid` = ? AND `deleted` = 0", { data.person }, function(success, row)
			if not success or row == nil then
				cb(false)
				return
			end
			local ok, v = pcall(json.decode, row.data)
			if not ok or type(v) ~= "table" then
				cb(false)
				return
			end

			local matchedJob = nil
			for _, j in ipairs(v.Jobs or {}) do
				if j.Id == data.job then
					matchedJob = j
					break
				end
			end

			if not matchedJob then
				cb(false)
				return
			end

			cb({
				Mugshot = v.Mugshot,
				First = v.First,
				Last = v.Last,
				SID = v.SID,
				Callsign = v.Callsign,
				MDTSuspension = v.MDTSuspension,
				MDTSystemAdmin = v.MDTSystemAdmin,
				Qualifications = v.Qualifications,
				Phone = v.Phone,
				TimeClockedOn = v.TimeClockedOn,
				LastClockOn = v.LastClockOn,
				Jobs = { matchedJob },
			})
		end)
	end)

	plsr.Callbacks:RegisterServerCallback("MDT:RevokeLicenseSuspension", function(source, data, cb)
		local char = plsr.Fetch:CharacterSource(source)

		if CheckMDTPermissions(source, 'REVOKE_LICENSE_SUSPENSIONS') then
			local canUpdate = false
			local unsuspendTypes = {}

			for k, v in pairs(data.unsuspend) do
				if v then
					canUpdate = true
					table.insert(unsuspendTypes, k)
				end
			end

			if canUpdate then
				plsr.Logger:Warn(
					"MDT",
					string.format(
						"%s %s (%s) Revoked License Suspensions: %s From State ID %s",
						char:GetData("First"),
						char:GetData("Last"),
						char:GetData("SID"),
						json.encode(data.unsuspend),
						data.SID
					),
					{
						console = true,
						file = true,
						database = true,
						discord = {
							embed = true,
						},
					}
				)

				plsr.Database:Single("SELECT `id`, `data` FROM `characters` WHERE `sid` = ? AND `deleted` = 0", { data.SID }, function(success, row)
					if not success or row == nil then
						cb(false)
						return
					end
					local ok, existing = pcall(json.decode, row.data)
					if not ok or type(existing) ~= "table" then
						cb(false)
						return
					end
					if not existing.Licenses then
						existing.Licenses = {}
					end

					for _, licenseType in ipairs(unsuspendTypes) do
						if not existing.Licenses[licenseType] then
							existing.Licenses[licenseType] = {}
						end
						existing.Licenses[licenseType].Active = false
						existing.Licenses[licenseType].Suspended = false

						if licenseType == 'Drivers' then
							existing.Licenses.Drivers.Active = true
							existing.Licenses.Drivers.Points = 0
						end
					end

					plsr.Database:Update("UPDATE `characters` SET `data` = ? WHERE `id` = ?", { json.encode(existing), row.id }, function(updateSuccess)
						if updateSuccess then
							local target = plsr.Fetch:SID(data.SID)
							if target then
								target:SetData('Licenses', existing.Licenses)
							end
							cb(existing.Licenses)
						else
							cb(false)
						end
					end)
				end)
			else
				cb(false)
			end
		else
			cb(false)
		end
	end)

	plsr.Callbacks:RegisterServerCallback("MDT:RemoveLicensePoints", function(source, data, cb)
		local char = plsr.Fetch:CharacterSource(source)

		if CheckMDTPermissions(source, 'REVOKE_LICENSE_SUSPENSIONS') and data.SID and data.newPoints then
			plsr.Logger:Warn(
				"MDT",
				string.format(
					"%s %s (%s) Changed License Points of State ID %s to %s",
					char:GetData("First"),
					char:GetData("Last"),
					char:GetData("SID"),
					data.SID,
					data.newPoints
				),
				{
					console = true,
					file = true,
					database = true,
					discord = {
						embed = true,
					},
				}
			)

			plsr.Database:Single("SELECT `id`, `data` FROM `characters` WHERE `sid` = ? AND `deleted` = 0", { data.SID }, function(success, row)
				if not success or row == nil then
					cb(false)
					return
				end
				local ok, existing = pcall(json.decode, row.data)
				if not ok or type(existing) ~= "table" then
					cb(false)
					return
				end
				if not existing.Licenses then
					existing.Licenses = {}
				end
				if not existing.Licenses.Drivers then
					existing.Licenses.Drivers = {}
				end
				existing.Licenses.Drivers.Points = data.newPoints

				plsr.Database:Update("UPDATE `characters` SET `data` = ? WHERE `id` = ?", { json.encode(existing), row.id }, function(updateSuccess)
					if updateSuccess then
						local target = plsr.Fetch:SID(data.SID)
						if target then
							target:SetData('Licenses', existing.Licenses)
						end
						cb(existing.Licenses)
					else
						cb(false)
					end
				end)
			end)
		else
			cb(false)
		end
	end)

	plsr.Callbacks:RegisterServerCallback("MDT:ClearCriminalRecord", function(source, data, cb)
		local char = plsr.Fetch:CharacterSource(source)

		if char and CheckMDTPermissions(source, 'EXPUNGEMENT') and data.SID then
			local u = MySQL.query.await("UPDATE mdt_reports_people SET expunged = ? WHERE type = ? AND sentenced = ? AND SID = ?", {
				1,
				"suspect",
				1,
				data.SID
			})

			if u and u.affectedRows > 0 then
				plsr.Logger:Warn(
					"MDT",
					string.format(
						"%s %s (%s) Expunged %s Incidents From State ID %s",
						char:GetData("First"),
						char:GetData("Last"),
						char:GetData("SID"),
						u.affectedRows,
						data.SID
					),
					{
						console = true,
						file = true,
						database = true,
						discord = {
							embed = true,
						},
					}
				)
			end
			cb(true)
		else
			cb(false)
		end
	end)

	plsr.Callbacks:RegisterServerCallback("MDT:OpenEvidenceLocker", function(source, caseNum, cb)
		if
			plsr.Jobs.Permissions:HasJob(source, 'police', nil, nil, nil, true)
			or plsr.Jobs.Permissions:HasJob(source, 'ems', nil, nil, nil, true)
			or plsr.Jobs.Permissions:HasJob(source, 'prison', nil, nil, nil, true)
		then
			plsr.Callbacks:ClientCallback(source, "Inventory:Compartment:Open", {
				invType = 44,
				owner = ("evidencelocker:%s"):format(caseNum),
			}, function()
				plsr.Inventory:OpenSecondary(source, 44, ("evidencelocker:%s"):format(caseNum))
			end)
			cb(true)
		else
			cb(false)
		end
	end)

	plsr.Callbacks:RegisterServerCallback("MDT:OpenPersonalLocker", function(source, data, cb)
		local char = plsr.Fetch:CharacterSource(source)
		if char and (plsr.Jobs.Permissions:HasJob(source, 'police') or plsr.Jobs.Permissions:HasJob(source, 'ems') or plsr.Jobs.Permissions:HasJob(source, 'prison')) then
			cb(true)

			plsr.Callbacks:ClientCallback(source, "Inventory:Compartment:Open", {
				invType = 45,
				owner = ("pdlocker:%s"):format(char:GetData('SID')),
			}, function()
				plsr.Inventory:OpenSecondary(source, 45, ("pdlocker:%s"):format(char:GetData('SID')))
			end)
		else
			cb(false)
		end
	end)

	plsr.Callbacks:RegisterServerCallback("MDT:DOCGetPrisoners", function(source, data, cb)
		cb(plsr.Jail:GetPrisoners())
	end)

	plsr.Callbacks:RegisterServerCallback("MDT:DOCReduceSentence", function(source, data, cb)
		local char = plsr.Fetch:CharacterSource(source)
		if char and CheckMDTPermissions(source, 'DOC_REDUCTION') and data.reduction then
			local target = plsr.Fetch:SID(data.SID)
			if target then
				if plsr.Jail:Reduce(target:GetData("Source"), data.reduction) then
					plsr.Logger:Warn(
						"MDT",
						string.format(
							"%s %s (%s) Reduced %s %s (%s) Prison Sentence By %s Months",
							char:GetData("First"),
							char:GetData("Last"),
							char:GetData("SID"),
							target:GetData("First"),
							target:GetData("Last"),
							target:GetData("SID"),
							data.reduction
						),
						{
							console = true,
							file = true,
							database = true,
							discord = {
								embed = true,
							},
						}
					)
					cb(true)
				else
					cb(false)
				end
			else
				cb(false)
			end
		else
			cb(false)
		end
	end)

	local vCooldowns = {}
	plsr.Callbacks:RegisterServerCallback("MDT:DOCRequestVisitation", function(source, data, cb)
		local char = plsr.Fetch:CharacterSource(source)
		if char and (vCooldowns[source] == nil or vCooldowns[source] <= os.time()) and data.SID then
			local target = plsr.Fetch:SID(data.SID)
			if target then
				local jailed = target:GetData("Jailed")
				if jailed and not jailed.Released then
					local dutyData = plsr.Jobs.Duty:GetDutyData("prison")
					if dutyData and dutyData.Count > 0 then
						local lobby = config.DOC.visitationLobby
						plsr.EmergencyAlerts:Create(
							"DOC",
							"Visition Request from Lobby",
							"doc_alerts",
							{ street1 = lobby.street1, x = lobby.coords.x, y = lobby.coords.y, z = lobby.coords.z },
							{
								details = string.format("Request to Visit %s %s (%s)", target:GetData("First"), target:GetData("Last"), target:GetData("SID")),
								icon = "info",
							},
							false,
							false,
							nil,
							false
						)
						vCooldowns[source] = os.time() + (3 * 60)
						cb({ success = true })
					else
						cb({
							success = false,
							message = "No DOC Available"
						})
					end
				else
					cb({ success = false })	
				end
			else
				cb({ success = false })	
			end
		else
			cb({
				success = false,
				message = "Please Wait Before Requesting Again"
			})
		end
	end)
end)
