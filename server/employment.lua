local config = load(LoadResourceFile(GetCurrentResourceName(), "config/server.lua"))()

AddEventHandler("MDT:Server:RegisterCallbacks", function()
	plsr.Callbacks:RegisterServerCallback("MDT:Hire", function(source, data, cb)
		local char = plsr.Fetch:CharacterSource(source)

		local isSystemAdmin = char:GetData('MDTSystemAdmin')
		local hasPerms, loggedInJob = CheckMDTPermissions(source, {
			'MDT_HIRE',
			'PD_HIGH_COMMAND',
			'DOC_HIGH_COMMAND',
		}, data.JobId)

		if char and data.SID and data.WorkplaceId and data.GradeId and (hasPerms or isSystemAdmin) then
			local added = plsr.Jobs:GiveJob(data.SID, data.JobId, data.WorkplaceId, data.GradeId, true)
			cb(added)

			if added then
				AddCharacterMDTHistory(
					data.SID,
					char:GetData("SID"),
					string.format("%s Hired Them To %s", char:GetData("First") .. " " .. char:GetData("Last"), json.encode(data))
				)
			end
		else
			cb(false)
		end
	end)

	plsr.Callbacks:RegisterServerCallback("MDT:Fire", function(source, data, cb)
		local char = plsr.Fetch:CharacterSource(source)

		local isSystemAdmin = char:GetData('MDTSystemAdmin')
		local hasPerms, loggedInJob = CheckMDTPermissions(source, {
			'MDT_FIRE',
			'PD_HIGH_COMMAND',
			'DOC_HIGH_COMMAND',
		}, data.JobId)

		if char and data and data.SID and (hasPerms or isSystemAdmin) then
			local charData = plsr.MDT.People:View(data.SID)
			if charData then
				local canRemove = false
				if isSystemAdmin then
					canRemove = true
				else
					local plyrJob = plsr.Jobs.Permissions:HasJob(source, loggedInJob)
					for k, v in ipairs(charData.Jobs) do
						if v.Id == data.JobId then
							if plyrJob.Grade.Level > v.Grade.Level then
								canRemove = true
							end
							break
						end
					end
				end

				if canRemove then
					local removed = plsr.Jobs:RemoveJob(data.SID, data.JobId)
					cb(removed)

					if removed then
						AddCharacterMDTHistory(
							data.SID,
							char:GetData("SID"),
							string.format("%s Fired Them From Job %s", char:GetData("First") .. " " .. char:GetData("Last"), data.JobId)
						)

						if (data.JobId == "police" or data.JobId == "ems" or data.JobId == "prison") then
							plsr.Database:Single("SELECT `id`, `data` FROM `characters` WHERE `sid` = ? AND `deleted` = 0", { data.SID }, function(success, row)
								if not success or row == nil then
									return
								end
								local ok, existing = pcall(json.decode, row.data)
								if not ok or type(existing) ~= "table" then
									return
								end
								existing.Callsign = false

								plsr.Database:Update(
									"UPDATE `characters` SET `data` = ?, `callsign` = NULL WHERE `id` = ?",
									{ json.encode(existing), row.id },
									function(updateSuccess)
										if updateSuccess and (data.JobId == "police" or data.JobId == "ems") then
											local onlineChar = plsr.Fetch:SID(data.SID)
											if onlineChar then
												onlineChar:SetData("Callsign", false)
											end
										end
									end
								)
							end)
						end
					end
				else
					cb(false)
				end
			end
		else
			cb(false)
		end
	end)

	plsr.Callbacks:RegisterServerCallback("MDT:ManageEmployment", function(source, data, cb)
		local char = plsr.Fetch:CharacterSource(source)

		local isSystemAdmin = char:GetData('MDTSystemAdmin')
		local hasPerms, loggedInJob = CheckMDTPermissions(source, {
			'MDT_FIRE',
			'PD_HIGH_COMMAND',
			'DOC_HIGH_COMMAND',
		}, data.JobId)

		local newJobData = plsr.Jobs:DoesExist(data.data.Id, data.data.Workplace.Id, data.data.Grade.Id)

		if char and data and data.SID and (hasPerms or isSystemAdmin) and newJobData then
			local charData = plsr.MDT.People:View(data.SID)
			if charData then
				local canDoItBitch = false
				if isSystemAdmin then
					canDoItBitch = true
				else
					local plyrJob = plsr.Jobs.Permissions:HasJob(source, loggedInJob)
					for k, v in ipairs(charData.Jobs) do
						if v.Id == data.JobId then
							if plyrJob.Grade.Level > v.Grade.Level and plyrJob.Grade.Level > newJobData.Grade.Level then
								canDoItBitch = true
							end
							break
						end
					end
				end

				if canDoItBitch then
					local updated = plsr.Jobs:GiveJob(data.SID, newJobData.Id, newJobData.Workplace.Id, newJobData.Grade.Id)

					cb(updated)

					if updated then
						AddCharacterMDTHistory(
							data.SID,
							char:GetData("SID"),
							string.format("%s Promoted Them To %s", char:GetData("First") .. " " .. char:GetData("Last"), json.encode(newJobData))
						)
					end
				else
					cb(false)
				end
			end
		else
			cb(false)
		end
	end)

    plsr.Callbacks:RegisterServerCallback("MDT:Update:jobPermissions", function(source, data, cb)
		local char = plsr.Fetch:CharacterSource(source)
		local isSystemAdmin = char:GetData('MDTSystemAdmin')
		local hasPerms, loggedInJob = CheckMDTPermissions(source, {
			'PD_HIGH_COMMAND',
			'SAFD_HIGH_COMMAND',
			'DOC_HIGH_COMMAND',
		}, data.JobId)

		local targetData = plsr.Jobs:DoesExist(data.JobId, data.WorkplaceId, data.GradeId)

		if char and data and data.UpdatedPermissions and (hasPerms or isSystemAdmin) and targetData then
            local plyrJob = plsr.Jobs.Permissions:HasJob(source, loggedInJob)
            if isSystemAdmin or (plyrJob and plyrJob.Grade.Level > targetData.Grade.Level) then
                cb(
                    plsr.Jobs.Management.Grades:Edit(data.JobId, data.WorkplaceId, data.GradeId, {
                        Permissions = data.UpdatedPermissions,
                    })
                )
            else
                cb(false)
            end
		else
			cb(false)
		end
	end)

	plsr.Callbacks:RegisterServerCallback("MDT:Suspend", function(source, data, cb)
		local char = plsr.Fetch:CharacterSource(source)

		local isSystemAdmin = char:GetData('MDTSystemAdmin')
		local hasPerms, loggedInJob = CheckMDTPermissions(source, {
			'MDT_FIRE',
			'PD_HIGH_COMMAND',
			'DOC_HIGH_COMMAND',
		}, data.JobId)

		if char and data and data.SID and (hasPerms or isSystemAdmin) then
			local charData = plsr.MDT.People:View(data.SID)
			if charData then
				local canRemove = false
				if isSystemAdmin then
					canRemove = true
				else
					local plyrJob = plsr.Jobs.Permissions:HasJob(source, loggedInJob)
					for k, v in ipairs(charData.Jobs) do
						if v.Id == data.JobId then
							if plyrJob.Grade.Level > v.Grade.Level then
								canRemove = true
							end
							break
						end
					end
				end

				if canRemove and data.Length and type(data.Length) == "number" and data.Length > 0 and data.Length < config.Employment.maxSuspensionDays then
					local suspendData = {
						Actioned = {
							First = char:GetData("First"),
							Last = char:GetData("Last"),
							SID = char:GetData("SID"),
							Callsign = char:GetData("Callsign")
						},
						Length = data.Length,
						Expires = os.time() + (60 * 60 * 24 * data.Length),
					}

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
						if not existing.MDTSuspension then
							existing.MDTSuspension = {}
						end
						existing.MDTSuspension[data.JobId] = suspendData

						plsr.Database:Update("UPDATE `characters` SET `data` = ? WHERE `id` = ?", { json.encode(existing), row.id }, function(updateSuccess)
							if updateSuccess then
								AddCharacterMDTHistory(
									data.SID,
									char:GetData("SID"),
									string.format(
										"%s Suspended Them From Job %s for %s Days",
										char:GetData("First") .. " " .. char:GetData("Last"),
										data.JobId,
										data.Length
									)
								)

								local onlineChar = plsr.Fetch:SID(data.SID)
								if onlineChar then
									local suspensionShit = onlineChar:GetData("MDTSuspension") or {}

									suspensionShit[data.JobId] = suspendData
									onlineChar:SetData("MDTSuspension", suspensionShit)

									plsr.Jobs.Duty:Off(onlineChar:GetData("Source"), data.JobId)
								end

								cb(true)
							else
								cb(false)
							end
						end)
					end)
				else
					cb(false)
				end
			end
		else
			cb(false)
		end
	end)

	plsr.Callbacks:RegisterServerCallback("MDT:Unsuspend", function(source, data, cb)
		local char = plsr.Fetch:CharacterSource(source)

		local isSystemAdmin = char:GetData('MDTSystemAdmin')
		local hasPerms, loggedInJob = CheckMDTPermissions(source, {
			'MDT_FIRE',
			'PD_HIGH_COMMAND',
			'DOC_HIGH_COMMAND',
		}, data.JobId)

		if char and data and data.SID and (hasPerms or isSystemAdmin) then
			local charData = plsr.MDT.People:View(data.SID)
			if charData then
				local canRemove = false
				if isSystemAdmin then
					canRemove = true
				else
					local plyrJob = plsr.Jobs.Permissions:HasJob(source, loggedInJob)
					for k, v in ipairs(charData.Jobs) do
						if v.Id == data.JobId then
							if plyrJob.Grade.Level > v.Grade.Level then
								canRemove = true
							end
							break
						end
					end
				end

				if canRemove then
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
						if existing.MDTSuspension then
							existing.MDTSuspension[data.JobId] = nil
						end

						plsr.Database:Update("UPDATE `characters` SET `data` = ? WHERE `id` = ?", { json.encode(existing), row.id }, function(updateSuccess)
							if updateSuccess then
								AddCharacterMDTHistory(
									data.SID,
									char:GetData("SID"),
									string.format("%s Revoked Suspension From Job %s", char:GetData("First") .. " " .. char:GetData("Last"), data.JobId)
								)

								local onlineChar = plsr.Fetch:SID(data.SID)
								if onlineChar then
									local suspensionShit = onlineChar:GetData("MDTSuspension") or {}
									suspensionShit[data.JobId] = nil
									onlineChar:SetData("MDTSuspension", suspensionShit)
								end

								cb(true)
							else
								cb(false)
							end
						end)
					end)
				else
					cb(false)
				end
			end
		else
			cb(false)
		end
	end)
end)
