function GetVehicleOwnerData(sid)
	local p = promise.new()
	plsr.Database:Single("SELECT `data` FROM `characters` WHERE `sid` = ? AND `deleted` = 0", { sid }, function(success, row)
		if not success or row == nil then
			p:resolve(nil)
			return
		end
		local ok, decoded = pcall(json.decode, row.data)
		if ok and type(decoded) == "table" then
			p:resolve({ First = decoded.First, Last = decoded.Last, SID = decoded.SID })
		else
			p:resolve(nil)
		end
	end)

	return Citizen.Await(p)
end

_MDT.Vehicles = {
	Search = function(self, term, page, perPage)
		local p = promise.new()

		local skip = 0
		if page > 1 then
			skip = perPage * (page - 1)
		end

		local sql, params

		if term and term:sub(1, 5) == "SID: " then
			local sid = tonumber(term:sub(6, #term))
			if sid then
				sql = "SELECT `id`, `data` FROM `vehicles` WHERE `owner_type` = 0 AND `owner_id` = ? ORDER BY `id` DESC LIMIT ? OFFSET ?"
				params = { tostring(sid), perPage + 1, skip }
			end
		end

		if not sql then
			local like = "%" .. term .. "%"
			sql = "SELECT `id`, `data` FROM `vehicles` WHERE `vin` LIKE ? OR `registered_plate` LIKE ? OR CONCAT(JSON_UNQUOTE(JSON_EXTRACT(`data`, '$.Make')), ' ', JSON_UNQUOTE(JSON_EXTRACT(`data`, '$.Model'))) LIKE ? ORDER BY `id` DESC LIMIT ? OFFSET ?"
			params = { like, like, like, perPage + 1, skip }
		end

		plsr.Database:Query(sql, params, function(success, rows)
			if not success then
				p:resolve(false)
				return
			end

			local results = {}
			for k, row in ipairs(rows) do
				local ok, decoded = pcall(json.decode, row.data)
				if ok and type(decoded) == "table" then
					decoded._id = row.id
					decoded.Type = decoded.Type or 0
					decoded.Make = decoded.Make or "Unknown"
					decoded.Model = decoded.Model or "Unknown"
					decoded.RegisteredPlate = decoded.RegisteredPlate or "N/A"
					decoded.VIN = decoded.VIN or "N/A"
					table.insert(results, decoded)
				end
			end

			local pageCount = nil
			if #results > perPage then -- There is more results for the next pages
				table.remove(results)
				pageCount = page + 1
			end

			p:resolve({
				data = results,
				pages = pageCount,
			})
		end)
		return Citizen.Await(p)
	end,
	View = function(self, VIN)
		local p = promise.new()
		plsr.Database:Single("SELECT `data`, `flags`, `strikes`, `gov_assigned` FROM `vehicles` WHERE `vin` = ?", { VIN }, function(success, row)
			if not success or row == nil then
				p:resolve(false)
				return
			end
			local ok, vehicle = pcall(json.decode, row.data)
			if not ok or type(vehicle) ~= "table" then
				p:resolve(false)
				return
			end

			if row.flags then
				local fok, flags = pcall(json.decode, row.flags)
				vehicle.Flags = (fok and flags) or nil
			end
			if row.strikes then
				local sok, strikes = pcall(json.decode, row.strikes)
				vehicle.Strikes = (sok and strikes) or nil
			end
			if row.gov_assigned then
				local gok, govAssigned = pcall(json.decode, row.gov_assigned)
				vehicle.GovAssigned = (gok and govAssigned) or nil
			end

			if vehicle.Owner then
				if vehicle.Owner.Type == 0 then
					vehicle.Owner.Person = GetVehicleOwnerData(vehicle.Owner.Id)
				elseif vehicle.Owner.Type == 1 or vehicle.Owner.Type == 2 then
					local jobData = plsr.Jobs:DoesExist(vehicle.Owner.Id, vehicle.Owner.Workplace)
					if jobData then
						if jobData.Workplace then
							vehicle.Owner.JobName = string.format('%s (%s)', jobData.Name, jobData.Workplace.Name)
						else
							vehicle.Owner.JobName = jobData.Name
						end
					end
				end

				if vehicle.Owner.Type == 2 then
					vehicle.Owner.JobName = vehicle.Owner.JobName .. " (Dealership Buyback)"
				end
			end

			if vehicle.Storage then
				if vehicle.Storage.Type == 0 then
					vehicle.Storage.Name = plsr.Vehicles.Garages:Impound().name
				elseif vehicle.Storage.Type == 1 then
					vehicle.Storage.Name = plsr.Vehicles.Garages:Get(vehicle.Storage.Id).name
				elseif vehicle.Storage.Type == 2 then
					local prop = plsr.Properties:Get(vehicle.Storage.Id)
					vehicle.Storage.Name = prop?.label
				end
			end

			if vehicle.RegisteredPlate then
				local flagged = plsr.Radar:CheckPlate(vehicle.RegisteredPlate)
				if flagged and not flagged:find("^MDT Flag: ") then
					vehicle.RadarFlag = flagged
				end
			end

			p:resolve(vehicle)
		end)
		return Citizen.Await(p)
	end,
	Flags = {
		Add = function(self, VIN, data, plate)
			local p = promise.new()
			EnsureMDTTables(function()
				plsr.Database:Single("SELECT `flags` FROM `vehicles` WHERE `vin` = ?", { VIN }, function(success, row)
					if not success or row == nil then
						p:resolve(false)
						return
					end
					local flags = {}
					if row.flags then
						local ok, decoded = pcall(json.decode, row.flags)
						if ok and type(decoded) == "table" then
							flags = decoded
						end
					end
					table.insert(flags, data)

					plsr.Database:Update("UPDATE `vehicles` SET `flags` = ? WHERE `vin` = ?", { json.encode(flags), VIN }, function(updateSuccess)
						if updateSuccess and data.Type and data.Description and plate then
							plsr.Radar:AddFlaggedPlate(plate, "MDT Flag: " .. data.Description)
						end
						p:resolve(updateSuccess)
					end)
				end)
			end)
			return Citizen.Await(p)
		end,
		Remove = function(self, VIN, flag, plate, removeRadarFlag)
			local p = promise.new()
			EnsureMDTTables(function()
				plsr.Database:Single("SELECT `flags` FROM `vehicles` WHERE `vin` = ?", { VIN }, function(success, row)
					if not success or row == nil then
						p:resolve(false)
						return
					end
					local flags = {}
					if row.flags then
						local ok, decoded = pcall(json.decode, row.flags)
						if ok and type(decoded) == "table" then
							flags = decoded
						end
					end

					local remaining = {}
					for _, f in ipairs(flags) do
						if f.Type ~= flag then
							table.insert(remaining, f)
						end
					end

					plsr.Database:Update("UPDATE `vehicles` SET `flags` = ? WHERE `vin` = ?", { json.encode(remaining), VIN }, function(updateSuccess)
						p:resolve(updateSuccess)

						if updateSuccess and plate and removeRadarFlag then
							local isFlagged = plsr.Radar:CheckPlate(plate)
							if isFlagged == "Vehicle Flagged in MDT" then
								plsr.Radar:RemoveFlaggedPlate(plate)
							end
						end
					end)
				end)
			end)
			return Citizen.Await(p)
		end,
	},
	UpdateStrikes = function(self, VIN, strikes)
		local p = promise.new()
		EnsureMDTTables(function()
			plsr.Database:Update("UPDATE `vehicles` SET `strikes` = ? WHERE `vin` = ?", { json.encode(strikes), VIN }, function(success)
				p:resolve(success)
			end)
		end)
		return Citizen.Await(p)
	end,
	GetStrikes = function(self, VIN)
		local p = promise.new()
		EnsureMDTTables(function()
			plsr.Database:Single("SELECT `strikes` FROM `vehicles` WHERE `vin` = ?", { VIN }, function(success, row)
				if success and row ~= nil and row.strikes then
					local ok, strikes = pcall(json.decode, row.strikes)
					if ok and type(strikes) == "table" then
						p:resolve(#strikes)
						return
					end
				end
				p:resolve(0)
			end)
		end)

		return Citizen.Await(p)
	end
}

AddEventHandler("MDT:Server:RegisterCallbacks", function()
	plsr.Callbacks:RegisterServerCallback("MDT:Search:vehicle", function(source, data, cb)
		if CheckMDTPermissions(source, false) then
			cb(plsr.MDT.Vehicles:Search(data.term, data.page, data.perPage))
		else
			cb(false)
		end
	end)

	plsr.Callbacks:RegisterServerCallback("MDT:View:vehicle", function(source, data, cb)
		if CheckMDTPermissions(source, false) then
			cb(plsr.MDT.Vehicles:View(data))
		else
			cb(false)
		end
	end)

	plsr.Callbacks:RegisterServerCallback("MDT:Create:vehicle-flag", function(source, data, cb)
		if CheckMDTPermissions(source, false, 'police') then
			cb(plsr.MDT.Vehicles.Flags:Add(data.parent, data.doc, data.plate))
		else
			cb(false)
		end
	end)

	plsr.Callbacks:RegisterServerCallback("MDT:Delete:vehicle-flag", function(source, data, cb)
		if CheckMDTPermissions(source, false, 'police') then
			cb(plsr.MDT.Vehicles.Flags:Remove(data.parent, data.id, data.plate, data.removeRadarFlag))
		else
			cb(false)
		end
	end)

	plsr.Callbacks:RegisterServerCallback("MDT:Update:vehicle-strikes", function(source, data, cb)
		if CheckMDTPermissions(source, false, 'police') then
			cb(plsr.MDT.Vehicles:UpdateStrikes(data.VIN, data.strikes))
		else
			cb(false)
		end
	end)
end)
