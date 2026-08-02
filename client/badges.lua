local config = load(LoadResourceFile(GetCurrentResourceName(), "config/shared.lua"))()

local badgeEntity = 0
local licenseEntity
local inBadgeAnim = false

local badgeModels = config.BadgeModels

function CaptureHeadshotTxd(ped, timeoutMs)
	timeoutMs = timeoutMs or 1500

	local handle = RegisterPedheadshotTransparent(ped)
	if not handle or handle == 0 then
		handle = RegisterPedheadshot(ped)
	end
	if not handle or handle == 0 then
		return nil, nil
	end

	local start = GetGameTimer()
	while not IsPedheadshotReady(handle) or not IsPedheadshotValid(handle) do
		if GetGameTimer() - start > timeoutMs then
			UnregisterPedheadshot(handle)
			return nil, nil
		end
		Wait(0)
	end

	return GetPedheadshotTxdString(handle), handle
end

function RegisterBadgeCallbacks()
	plsr.Callbacks:RegisterClientCallback("MDT:Client:CanShowBadge", function(data, cb)
		if
			not inBadgeAnim
			and not _mdtOpen
			and not plsr.State.flags.doingAction
			and not plsr.State.flags.isDead
			and not plsr.Animations.Emotes:Get()
			and IsPedOnFoot(PlayerPedId())
		then
			StartBadgeAnim(data.Department)
			Wait(2500)

			cb(true)
		else
			cb(false)
		end
	end)

	plsr.Callbacks:RegisterClientCallback("MDT:Client:CanShowLicense", function(data, cb)
		if
			not inBadgeAnim
			and not _mdtOpen
			and not plsr.State.flags.doingAction
			and not plsr.State.flags.isDead
			and not plsr.Animations.Emotes:Get()
			and IsPedOnFoot(PlayerPedId())
		then
			StartLicenseAnim()
			Wait(2500)

			cb(true)
		else
			cb(false)
		end
	end)
end

function StartBadgeAnim(department)
	if inBadgeAnim then
		return
	end

	local playerPed = PlayerPedId()
	local model = badgeModels[department] or `xrp_prop_pdbadge_4`
	inBadgeAnim = true

	LoadAnim("paper_1_rcm_alt1-7")
	LoadModel(model)

	badgeEntity = CreateObject(model, GetEntityCoords(playerPed), 1, 1, 0)
	AttachEntityToEntity(
		badgeEntity,
		playerPed,
		GetPedBoneIndex(playerPed, 57005),
		0.13,
		0.05,
		-0.06,
		40.0,
		55.0,
		-267.0,
		1,
		1,
		0,
		1,
		0,
		1
	)
	TaskPlayAnim(playerPed, 1.0, -1, -1, 50, 0, 0, 0, 0)
	TaskPlayAnim(playerPed, "paper_1_rcm_alt1-7", "player_one_dual-7", 1.0, 1.0, -1, 50, 0, 0, 0, 0)

	Citizen.SetTimeout(11000, function()
		StopBadgeAnim()
	end)
end

function StopBadgeAnim()
	if inBadgeAnim then
		StopAnimTask(PlayerPedId(), "paper_1_rcm_alt1-7", "player_one_dual-7", 3.0)
		DeleteEntity(badgeEntity)

		inBadgeAnim = false
	end
end

function StartLicenseAnim()
	if inBadgeAnim then
		return
	end

	local playerPed = PlayerPedId()
	local model = `p_ld_id_card_01`
	inBadgeAnim = true

	LoadAnim("paper_1_rcm_alt1-7")
	LoadModel(model)

	licenseEntity = CreateObject(model, GetEntityCoords(playerPed), 1, 1, 0)
	AttachEntityToEntity(
		licenseEntity,
		playerPed,
		GetPedBoneIndex(playerPed, 57005),
		0.13,
		0.05,
		-0.06,
		40.0,
		55.0,
		-267.0,
		1,
		1,
		0,
		1,
		0,
		1
	)

	TaskPlayAnim(playerPed, 1.0, -1, -1, 50, 0, 0, 0, 0)
	TaskPlayAnim(playerPed, "paper_1_rcm_alt1-7", "player_one_dual-7", 1.0, 1.0, -1, 50, 0, 0, 0, 0)

	Citizen.SetTimeout(11000, function()
		StopLicenseAnim()
	end)
end

function StopLicenseAnim()
	if inBadgeAnim then
		StopAnimTask(PlayerPedId(), "paper_1_rcm_alt1-7", "player_one_dual-7", 3.0)
		DeleteEntity(licenseEntity)

		inBadgeAnim = false
	end
end

RegisterNetEvent("MDT:Client:ShowBadge", function(sender, data)
	if not plsr.State.flags.loggedIn or plsr.State.flags.inventoryOpen then
		return
	end

	local senderClient = GetPlayerFromServerId(sender)

	local isMe = false
	if sender == plsr.State.flags.ID then
		isMe = true
	end

	plsr.Logger:Trace(
		"MDT/Badge",
		string.format(
			"Sender Source: %s; Sender Player: %s; My Source: %s; My Ped: %s",
			sender,
			senderClient,
			plsr.State.flags.ID,
			PlayerPedId()
		)
	)

	if senderClient < 0 and not isMe then
		return
	end

	if not senderClient then
		return
	end

	local myPed = PlayerPedId()
	local senderPed = GetPlayerPed(senderClient)

	if DoesEntityExist(senderPed) then
		local dist = #(GetEntityCoords(senderPed) - GetEntityCoords(myPed))

		if dist <= config.Badges.viewDistance and HasEntityClearLosToEntity(myPed, senderPed, config.Badges.viewLosRadius) then
			local txd, handle = CaptureHeadshotTxd(senderPed, 1500)
			data.HeadshotTxd = txd
			plsr.MDT.Badges:Open(data)

			if handle then
				Citizen.SetTimeout(10000, function()
					UnregisterPedheadshot(handle)
				end)
			end
		end
	end
end)

RegisterNetEvent("MDT:Client:ShowLicense", function(sender, data)
	if not plsr.State.flags.loggedIn or plsr.State.flags.inventoryOpen then
		return
	end

	local senderClient = GetPlayerFromServerId(sender)

	local isMe = false
	if sender == plsr.State.flags.ID then
		isMe = true
	end

	plsr.Logger:Trace(
		"MDT/Badge",
		string.format(
			"Sender Source: %s; Sender Player: %s; My Source: %s; My Ped: %s",
			sender,
			senderClient,
			plsr.State.flags.ID,
			PlayerPedId()
		)
	)

	if senderClient < 0 and not isMe then
		return
	end

	if not senderClient then
		return
	end

	local myPed = PlayerPedId()
	local senderPed = GetPlayerPed(senderClient)

	if DoesEntityExist(senderPed) then
		local dist = #(GetEntityCoords(senderPed) - GetEntityCoords(myPed))

		if dist <= config.Badges.viewDistance and HasEntityClearLosToEntity(myPed, senderPed, config.Badges.viewLosRadius) then
			local txd, handle = CaptureHeadshotTxd(senderPed, 1500)
			data.HeadshotTxd = txd
			plsr.MDT.Licenses:Open(data)

			if handle then
				Citizen.SetTimeout(10000, function()
					UnregisterPedheadshot(handle)
				end)
			end
		end
	end
end)
