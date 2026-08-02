local config = load(LoadResourceFile(GetCurrentResourceName(), "config/shared.lua"))()

_mdtOpen = false
_openCd = false -- Prevents spamm open/close
_settings = {}
_perms = {}
_loggedIn = false
_mdtLoggedIn = false

local _bodycam = false
local _ownHeadshotTxd = nil
local _ownHeadshotHandle = nil

local function RefreshOwnHeadshot()
	if _ownHeadshotHandle then
		UnregisterPedheadshot(_ownHeadshotHandle)
	end

	_ownHeadshotTxd, _ownHeadshotHandle = CaptureHeadshotTxd(PlayerPedId(), 2500)

	SendNUIMessage({
		type = "SET_USER",
		data = {
			user = plsr.State:Get('character'),
			headshot = _ownHeadshotTxd,
		},
	})
end

CreateThread(function()
	plsr.Keybinds:Add("gov_mdt", config.Keybinds.openMdt.default, "keyboard", config.Keybinds.openMdt.label, function()
		ToggleMDT()
	end)

	RegisterBadgeCallbacks()
end)

AddEventHandler("Characters:Client:Spawn", function()
	_loggedIn = true
	_mdtLoggedIn = false
end)

local usefulData = {
	Callsign = true,
	Qualifications = true,
	MDTSystemAdmin = true,
}

AddEventHandler("Characters:Client:Updated", function(key)
	if key == -1 or usefulData[key] then
		if not plsr.State.flags.loggedIn then
			return
		end

		local char = plsr.State:Get('character')
		SendNUIMessage({
			type = "SET_USER",
			data = {
				user = char,
				headshot = _ownHeadshotTxd,
			},
		})
	end
end)

RegisterNetEvent("MDT:Client:Login", function(points, job, jobPermissions, attorney, data)
	_mdtLoggedIn = true

	if data then
		for k, v in pairs(data) do
			plsr.MDT.Data:Set(k, v)
		end
	end

	SendNUIMessage({
		type = "SET_USER",
		data = {
			user = plsr.State:Get('character'),
			headshot = _ownHeadshotTxd,
		},
	})

	SendNUIMessage({
		type = "JOB_LOGIN",
		data = {
			points = points,
			job = job,
			jobPermissions = jobPermissions,
			attorney = attorney,
		},
	})

	CreateThread(RefreshOwnHeadshot)
end)

RegisterNetEvent("MDT:Client:Logout", function()
	_mdtLoggedIn = false
	SendNUIMessage({
		type = "JOB_LOGOUT",
		data = nil,
	})
end)

RegisterNetEvent("MDT:Client:UpdateJobData", function(job, jobPermissions)
	SendNUIMessage({
		type = "JOB_UPDATE",
		data = {
			job = job,
			jobPermissions = jobPermissions,
		},
	})
end)

RegisterNetEvent("Characters:Client:Logout", function()
	plsr.MDT:Close()
	plsr.MDT.Badges:Close()
	plsr.EmergencyAlerts:Close()

	if _ownHeadshotHandle then
		UnregisterPedheadshot(_ownHeadshotHandle)
		_ownHeadshotHandle = nil
		_ownHeadshotTxd = nil
	end

	SendNUIMessage({
		type = "LOGOUT",
		data = nil,
	})
	SendNUIMessage({
		type = "SET_BODYCAM",
		data = {
			state = false,
		},
	})

	_bodycam = false
	_mdtLoggedIn = false
	_loggedIn = false
end)

RegisterNetEvent("UI:Client:Reset", function(manual)
	plsr.MDT:Close()
	plsr.MDT.Badges:Close()
	plsr.EmergencyAlerts:Close()
	SendNUIMessage({
		type = "SET_BODYCAM",
		data = {
			state = _bodycam,
		},
	})

	if _bodycam and manual then
		plsr.Sounds.Play:Distance(15, "bodycam.ogg", 0.1)
	end
end)

AddEventHandler("MDT:Client:ToggleBodyCam", function()
	SendNUIMessage({
		type = "TOGGLE_BODYCAM",
		data = nil,
	})

	_bodycam = not _bodycam
	if _bodycam then
		plsr.Sounds.Play:Distance(15, "bodycam.ogg", 0.05)
	end
end)

function ToggleMDT()
	if not _openCd and _mdtLoggedIn then
		if not _mdtOpen then
			_openCd = true
			plsr.MDT:Open()

			CreateThread(function()
				Wait(config.MDT.toggleCooldownMs)
				_openCd = false
			end)
		else
			plsr.MDT:Close()
		end
	end
end

AddEventHandler("Government:Client:AccessPublicRecords", function()
	Wait(250)
	TriggerServerEvent("MDT:Server:OpenPublicRecords")
end)
