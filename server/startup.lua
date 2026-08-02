local config = load(LoadResourceFile(GetCurrentResourceName(), "config/server.lua"))()

_warrants = {}
_charges = {}
_notices = {}

local _ran = false

local _mdtTablesReady = false
function EnsureMDTTables(callback)
	if _mdtTablesReady then
		if callback then
			callback()
		end
		return
	end
	plsr.Database:Query(
		"CREATE TABLE IF NOT EXISTS `character_mdt_history` (`id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY, `sid` BIGINT UNSIGNED NOT NULL, `time` BIGINT NOT NULL, `actor_sid` BIGINT NULL, `log` TEXT NOT NULL, INDEX `idx_sid` (`sid`))",
		nil,
		function()
			plsr.Database:Query(
				"CREATE TABLE IF NOT EXISTS `characters` (`id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY, `account` BIGINT UNSIGNED NOT NULL, `sid` BIGINT UNSIGNED NULL, `deleted` TINYINT(1) NOT NULL DEFAULT 0, `phone` VARCHAR(20) NULL, `crypto_wallet` VARCHAR(20) NULL, `data` JSON NOT NULL, INDEX `idx_account` (`account`), INDEX `idx_sid` (`sid`), INDEX `idx_deleted` (`deleted`), INDEX `idx_phone` (`phone`), INDEX `idx_crypto_wallet` (`crypto_wallet`))",
				nil,
				function()
					plsr.Database:Query(
						"ALTER TABLE `characters` ADD COLUMN IF NOT EXISTS `callsign` VARCHAR(191) NULL, ADD INDEX IF NOT EXISTS `idx_callsign` (`callsign`)",
						nil,
						function()
							plsr.Database:Query(
								"CREATE TABLE IF NOT EXISTS `vehicles` (`id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY, `vin` VARCHAR(64) NOT NULL, `type` INT NOT NULL DEFAULT 0, `owner_type` INT NULL, `owner_id` VARCHAR(191) NULL, `owner_workplace` VARCHAR(191) NULL, `owner_level` INT NULL DEFAULT 0, `storage_type` INT NULL, `storage_id` VARCHAR(191) NULL, `registered_plate` VARCHAR(20) NULL, `fake_plate` VARCHAR(20) NULL, `data` JSON NOT NULL, UNIQUE INDEX `idx_vin` (`vin`), INDEX `idx_owner` (`owner_type`, `owner_id`), INDEX `idx_owner_fleet` (`owner_type`, `owner_workplace`, `owner_level`), INDEX `idx_storage` (`storage_type`, `storage_id`), INDEX `idx_type` (`type`), INDEX `idx_registered_plate` (`registered_plate`), INDEX `idx_fake_plate` (`fake_plate`))",
								nil,
								function()
									plsr.Database:Query(
										"ALTER TABLE `vehicles` ADD COLUMN IF NOT EXISTS `flags` JSON NULL, ADD COLUMN IF NOT EXISTS `strikes` JSON NULL, ADD COLUMN IF NOT EXISTS `gov_assigned` JSON NULL",
										nil,
										function()
											_mdtTablesReady = true
											if callback then
												callback()
											end
										end
									)
								end
							)
						end
					)
				end
			)
		end
	)
end

function AddCharacterMDTHistory(sid, actorSid, log, callback)
	EnsureMDTTables(function()
		plsr.Database:Insert(
			"INSERT INTO `character_mdt_history` (`sid`, `time`, `actor_sid`, `log`) VALUES (?, ?, ?, ?)",
			{ sid, os.time() * 1000, actorSid, log },
			function(success, newId)
				if callback then
					callback(success)
				end
			end
		)
	end)
end

function Startup()
	if _ran then
		return
	end
	RegisterTasks()

	-- Set Expired Active Warrants to Expired
	MySQL.query.await("UPDATE mdt_warrants SET state = ? WHERE state = ? AND expires < NOW()", {
		"expired",
		"active",
	})

	_charges = MySQL.query.await("SELECT * from mdt_charges")
	plsr.Logger:Trace("MDT", "Loaded ^2" .. #_charges .. "^7 Charges", { console = true })

	EnsureMDTTables(function()
		plsr.Database:Query("SELECT `vin`, `registered_plate`, `type`, `flags` FROM `vehicles` WHERE `flags` IS NOT NULL AND JSON_LENGTH(`flags`) > 0", nil, function(success, results)
			if not success then
				return
			end

			for k, row in ipairs(results) do
				if row.registered_plate and row.type == 0 then
					plsr.Radar:AddFlaggedPlate(row.registered_plate, "Vehicle Flagged in MDT")
				end
			end
		end)
	end)

	_ran = true

	-- SetHttpHandler(function(req, res)
	-- 	if req.path == '/charges' then
	-- 		res.send(json.encode(_charges))
	-- 	end
	-- end)

	EnsureMDTTables(function()
		plsr.Database:Query("SELECT `vin`, `strikes` FROM `vehicles` WHERE `strikes` IS NOT NULL AND JSON_LENGTH(`strikes`) > 0", nil, function(success, results)
			if not success then
				return
			end

			local cutoff = (os.time() * 1000) - (60 * 60 * 24 * config.Vehicles.strikeExpiryDays * 1000)
			for k, row in ipairs(results) do
				local ok, strikes = pcall(json.decode, row.strikes)
				if ok and type(strikes) == "table" then
					local allExpired = true
					for _, strike in ipairs(strikes) do
						if strike.Date > cutoff then
							allExpired = false
							break
						end
					end

					if allExpired then
						plsr.Database:Update("UPDATE `vehicles` SET `strikes` = ? WHERE `vin` = ?", { json.encode({}), row.vin })
					end
				end
			end
		end)
	end)
end
