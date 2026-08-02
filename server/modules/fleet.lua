AddEventHandler("MDT:Server:RegisterCallbacks", function()
	plsr.Callbacks:RegisterServerCallback("MDT:ViewVehicleFleet", function(source, data, cb)
		local hasPerms, loggedInJob = CheckMDTPermissions(source, {
			'FLEET_MANAGEMENT',
		})

    if hasPerms and loggedInJob then
      EnsureMDTTables(function()
        plsr.Database:Query(
          "SELECT `id`, `data`, `gov_assigned` FROM `vehicles` WHERE `owner_type` = 1 AND `owner_id` = ?",
          { tostring(loggedInJob) },
          function(success, rows)
            if success then
              local results = {}
              for k, row in ipairs(rows) do
                local ok, v = pcall(json.decode, row.data)
                if ok and type(v) == "table" then
                  v._id = row.id
                  if row.gov_assigned then
                    local gok, ga = pcall(json.decode, row.gov_assigned)
                    v.GovAssigned = (gok and ga) or nil
                  end

                  if v.Storage then
                    if v.Storage.Type == 0 then
                      v.Storage.Name = plsr.Vehicles.Garages:Impound().name
                    elseif v.Storage.Type == 1 then
                      v.Storage.Name = plsr.Vehicles.Garages:Get(v.Storage.Id).name
                    elseif v.Storage.Type == 2 then
                      local prop = plsr.Properties:Get(v.Storage.Id)
                      v.Storage.Name = prop?.label
                    end
                  end

                  table.insert(results, v)
                end
              end

              cb(results)
            else
              cb(false)
            end
          end
        )
      end)
    else
      cb(false)
    end
	end)

	plsr.Callbacks:RegisterServerCallback("MDT:SetAssignedDrivers", function(source, data, cb)
    local hasPerms, loggedInJob = CheckMDTPermissions(source, {
			'FLEET_MANAGEMENT',
		})

    if hasPerms and loggedInJob and data.vehicle and data.assigned then
      local ass = {}
      for k,v in ipairs(data.assigned) do
        table.insert(ass, {
          SID = v.SID,
          First = v.First,
          Last = v.Last,
          Callsign = v.Callsign
        })
      end

      EnsureMDTTables(function()
        plsr.Database:Update("UPDATE `vehicles` SET `gov_assigned` = ? WHERE `vin` = ?", { json.encode(ass), data.vehicle }, function(success)
          cb(success)
        end)
      end)
    else
      cb(false)
    end
	end)

  plsr.Callbacks:RegisterServerCallback("MDT:TrackFleetVehicle", function(source, data, cb)
    local hasPerms, loggedInJob = CheckMDTPermissions(source, {
			'FLEET_MANAGEMENT',
		})

    if hasPerms and loggedInJob and data.vehicle then
      cb(plsr.Vehicles.Owned:Track(data.vehicle))
    else
      cb(false)
    end
	end)
end)