return {
	Alerts = {
		Websocket = true, -- also mirror dispatch/alerts to pulsar_ws for a companion website, in-game panel works either way
		npcAlertChancePercent = 15, -- odds a nearby eligible npc/gunshot triggers a predefined alert
		npcAlertMinDistance = 10.0,
		npcAlertLosRadius = 17,
		disableTrackerHoldMs = 10000, -- how long you hold the interact key to disable someone's tracker
		disableTrackerDistance = 3.0, -- how close you have to stay for the hold to not cancel
	},

	Jobs = {
		portals = { "government", "police", "ems", "prison" }, -- get their own MDT portal + show in the employee directory, order = directory order
		dutyTriggers = { "police", "government", "ems", "tow", "prison" }, -- on-duty triggers MDT login + dispatch, tow gets alerts but no portal
		dispatchPanel = { "police", "prison", "ems", "tow" }, -- can open the dispatch/alerts panel with the keybind
		tracked = { "police", "ems", "prison" }, -- show up on the on-duty GPS tracker
	},

	Keybinds = {
		openMdt = { default = "", label = "Gov - Open MDT" },
		toggleAlertsPanel = { default = "GRAVE", label = "Police - Toggle Alerts Panel" },
	},

	MDT = {
		toggleCooldownMs = 2000, -- spam guard between open/close presses
		Tablet = { -- the physical prop shown while the MDT is open
			model = `prop_cs_tablet`,
			animDict = "amb@code_human_in_bus_passenger_idles@female@tablet@base",
			anim = "base",
			boneIndex = 60309,
			offset = { x = 0.02, y = -0.01, z = -0.03 },
			rotation = { x = 0.0, y = 0.0, z = -10.0 },
		},
	},

	Badges = {
		viewDistance = 4.0, -- how close someone has to be to see your presented badge/license
		viewLosRadius = 17,
		displayDurationMs = 9000, -- how long a presented badge/license stays on screen
		titleAbbreviations = { -- shortened for the badge card, add your own job titles here
			["Asst. District Attorney"] = "ADA",
			["Chief Public Defender"] = "Chf. Pub. Defender",
			["Superior Court Judge"] = "Superior Judge",
			["Probationary Officer"] = "Prob. Officer",
			["Probationary Deputy"] = "Prob. Deputy",
			["Probationary Trooper"] = "Prob. Trooper",
			["Emergency Medical Technician"] = "EMT",
			["Senior Emergency Medical Technician"] = "Senior EMT",
		},
	},

	BadgeModels = { -- department -> physical badge prop shown in-world, corrections has none so it falls back to doj
		lspd = `xrp_prop_pdbadge_1`,
		bcso = `xrp_prop_pdbadge_2`,
		safd = `xrp_prop_pdbadge_3`,
		doj = `xrp_prop_pdbadge_4`,
		sast = `xrp_prop_pdbadge_5`,
		guardius = `xrp_prop_pdbadge_6`,
	},

	-- department -> GPS tracker blip color (native GTA blip color ids)
	BlipColors = {
		police = { default = 3, sast = 55, bcso = 31, guardius = 46 },
		prison = { corrections = 11 },
		ems = { default = 8, doctors = 62 },
	},
}
