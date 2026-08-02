local requiredCharacterData = {
	SID = 1,
	User = 1,
	First = 1,
	Last = 1,
	Gender = 1,
	Origin = 1,
	Jobs = 1,
	DOB = 1,
	Callsign = 1,
	Phone = 1,
	Licenses = 1,
	Qualifications = 1,
	Flags = 1,
	Mugshot = 1,
	MDTSystemAdmin = 1,
	MDTHistory = 1,
	MDTSuspension = 1,
	Attorney = 1,
	LastClockOn = 1,
	TimeClockedOn = 1,
}

function GetCharacterVehiclesData(sid)
	local p = promise.new()

	plsr.Database:Query("SELECT `data` FROM `vehicles` WHERE `owner_type` = 0 AND `owner_id` = ?", { tostring(sid) }, function(success, rows)
		if not success then
			p:resolve({})
			return
		end

		local vehicles = {}
		for k, row in ipairs(rows) do
			local ok, v = pcall(json.decode, row.data)
			if ok and type(v) == "table" then
				table.insert(vehicles, { Type = v.Type, VIN = v.VIN, Make = v.Make, Model = v.Model, RegisteredPlate = v.RegisteredPlate })
			end
		end
		p:resolve(vehicles)
	end)

	return Citizen.Await(p)
end

_MDT.People = {
	Search = {
		People = function(self, term)
			local p = promise.new()
			local like = "%" .. term .. "%"
			plsr.Database:Query(
				"SELECT `id`, `sid`, `data` FROM `characters` WHERE `deleted` = 0 AND (CONCAT(JSON_UNQUOTE(JSON_EXTRACT(`data`, '$.First')), ' ', JSON_UNQUOTE(JSON_EXTRACT(`data`, '$.Last'))) LIKE ? OR `sid` LIKE ?) LIMIT 12",
				{ like, like },
				function(success, rows)
					if not success then
						p:resolve(false)
						return
					end

					local results = {}
					for k, row in ipairs(rows) do
						local ok, v = pcall(json.decode, row.data)
						if ok and type(v) == "table" then
							v._id = row.id
							table.insert(results, v)
						end
					end
					p:resolve(results)
				end
			)
			return Citizen.Await(p)
		end,
	},
	View = function(self, id, requireAllData)
		-- 5 DB Calls Here But IDK what else to do
		local SID = tonumber(id)
		local p = promise.new()
		plsr.Database:Single("SELECT `id`, `data` FROM `characters` WHERE `sid` = ? AND `deleted` = 0", { SID }, function(success, row)
			if not success or row == nil then
				p:resolve(false)
				return
			end
			local ok, char = pcall(json.decode, row.data)
			if not ok or type(char) ~= "table" then
				p:resolve(false)
				return
			end
			char._id = row.id

			local historyRows = MySQL.query.await("SELECT `time`, `actor_sid`, `log` FROM `character_mdt_history` WHERE `sid` = ? ORDER BY `time` DESC", { SID })
			local history = {}
			for k, h in ipairs(historyRows) do
				table.insert(history, { Time = h.time, Char = h.actor_sid, Log = h.log })
			end
			char.MDTHistory = history

			if requireAllData then
				local vehicles = GetCharacterVehiclesData(SID)
				local ownedBusinesses = {}

				if char.Jobs then
					for k, v in ipairs(char.Jobs) do
						local jobData = plsr.Jobs:Get(v.Id)
						if jobData.Owner and jobData.Owner == char.SID then
							table.insert(ownedBusinesses, v.Id)
						end
					end
				end

				local parole = MySQL.single.await("SELECT end, total, parole FROM character_parole WHERE SID = ?", {
					SID
				})

				local chargesData = MySQL.query.await("SELECT SID, charges FROM mdt_reports_people WHERE sentenced = ? AND type = ? AND SID = ? AND expunged = ?", {
					1,
					"suspect",
					SID,
					0
				})

				local convictions = {}
				for k,v in ipairs(chargesData) do
					local c = json.decode(v.charges)
					for _, ch in ipairs(c) do
						table.insert(convictions, ch)
					end
				end

				p:resolve({
					data = char,
					parole = parole,
					convictions = convictions,
					vehicles = vehicles,
					ownedBusinesses = ownedBusinesses,
				})
			else
				p:resolve(char)
			end
		end)
		return Citizen.Await(p)
	end,
	Update = function(self, requester, id, key, value)
		local p = promise.new()
		local logVal = value
		if type(value) == "table" then
			logVal = json.encode(value)
		end

		local actorSid, log
		if requester == -1 then
			actorSid = -1
			log = string.format("System Updated Profile, Set %s To %s", key, logVal)
		else
			actorSid = requester:GetData("SID")
			log = string.format(
				"%s Updated Profile, Set %s To %s",
				requester:GetData("First") .. " " .. requester:GetData("Last"),
				key,
				logVal
			)
		end

		plsr.Database:Single("SELECT `id`, `data` FROM `characters` WHERE `sid` = ? AND `deleted` = 0", { id }, function(success, row)
			if not success or row == nil then
				p:resolve(false)
				return
			end
			local ok, existing = pcall(json.decode, row.data)
			if not ok or type(existing) ~= "table" then
				p:resolve(false)
				return
			end
			existing[key] = value

			local sql = "UPDATE `characters` SET `data` = ?"
			local params = { json.encode(existing) }
			if key == "Callsign" then
				sql = sql .. ", `callsign` = ?"
				table.insert(params, value)
			end
			sql = sql .. " WHERE `id` = ?"
			table.insert(params, row.id)

			plsr.Database:Update(sql, params, function(updateSuccess)
				if updateSuccess then
					AddCharacterMDTHistory(id, actorSid, log)

					local target = plsr.Fetch:SID(id)
					if target then
						target:SetData(key, value)
					end

					if key == "Mugshot" then
						plsr.Inventory:UpdateGovIDMugshot(id, value)
					end
				end
				p:resolve(updateSuccess)
			end)
		end)
		return Citizen.Await(p)
	end,
}

AddEventHandler("MDT:Server:RegisterCallbacks", function()
	plsr.Callbacks:RegisterServerCallback("MDT:InputSearch:people", function(source, data, cb)
		local like = "%" .. data.term .. "%"
		plsr.Database:Query(
			"SELECT `data` FROM `characters` WHERE CONCAT(JSON_UNQUOTE(JSON_EXTRACT(`data`, '$.First')), ' ', JSON_UNQUOTE(JSON_EXTRACT(`data`, '$.Last'))) LIKE ? OR `sid` LIKE ? LIMIT 4",
			{ like, like },
			function(success, rows)
				if not success then
					cb({})
					return
				end

				local results = {}
				for k, row in ipairs(rows) do
					local ok, v = pcall(json.decode, row.data)
					if ok and type(v) == "table" then
						table.insert(results, { SID = v.SID, First = v.First, Last = v.Last, DOB = v.DOB, Licenses = v.Licenses })
					end
				end
				cb(results)
			end
		)
	end)

	plsr.Callbacks:RegisterServerCallback("MDT:InputSearch:job", function(source, data, cb)
		if CheckMDTPermissions(source, false) then
			local like = "%" .. data.term .. "%"
			plsr.Database:Query(
				"SELECT `data` FROM `characters` WHERE JSON_CONTAINS(JSON_EXTRACT(`data`, '$.Jobs'), JSON_OBJECT('Id', ?), '$') AND (CONCAT(JSON_UNQUOTE(JSON_EXTRACT(`data`, '$.First')), ' ', JSON_UNQUOTE(JSON_EXTRACT(`data`, '$.Last'))) LIKE ? OR `callsign` LIKE ? OR `sid` LIKE ?) LIMIT 4",
				{ data.job, like, like, like },
				function(success, rows)
					if not success then
						cb({})
						return
					end

					local results = {}
					for k, row in ipairs(rows) do
						local ok, v = pcall(json.decode, row.data)
						if ok and type(v) == "table" then
							table.insert(results, { SID = v.SID, First = v.First, Last = v.Last, Callsign = v.Callsign })
						end
					end
					cb(results)
				end
			)
		else
			cb(false)
		end
	end)

	plsr.Callbacks:RegisterServerCallback("MDT:InputSearchSID", function(source, data, cb)
		if CheckMDTPermissions(source, false) then
			plsr.Database:Single("SELECT `data` FROM `characters` WHERE `sid` = ?", { tonumber(data.term) }, function(success, row)
				if not success then
					cb({})
					return
				end
				if row == nil then
					cb({})
					return
				end
				local ok, v = pcall(json.decode, row.data)
				if not ok or type(v) ~= "table" then
					cb({})
					return
				end
				cb({ { SID = v.SID, First = v.First, Last = v.Last, DOB = v.DOB, Licenses = v.Licenses } })
			end)
		else
			cb(false)
		end
	end)

	plsr.Callbacks:RegisterServerCallback("MDT:Search:people", function(source, data, cb)
		cb(plsr.MDT.People.Search:People(data.term))
	end)

	plsr.Callbacks:RegisterServerCallback("MDT:View:person", function(source, data, cb)
		cb(plsr.MDT.People:View(data, true))
	end)

	plsr.Callbacks:RegisterServerCallback("MDT:Update:person", function(source, data, cb)
		local char = plsr.Fetch:CharacterSource(source)
		if char and CheckMDTPermissions(source, false) and data.SID then
			cb(plsr.MDT.People:Update(char, data.SID, data.Key, data.Data))
		else
			cb(false)
		end
	end)

	plsr.Callbacks:RegisterServerCallback("MDT:CheckCallsign", function(source, data, cb)
		if CheckMDTPermissions(source, false) then
			plsr.Database:Scalar("SELECT COUNT(*) FROM `characters` WHERE `callsign` = ?", { data }, function(success, count)
				cb(not success or count == 0)
			end)
		else
			cb(false)
		end
	end)
end)
