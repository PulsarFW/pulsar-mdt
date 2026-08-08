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

	-- master catalog for the admin Permission Manager grid - restrict = false/{} means every job can be granted it
	Permissions = {
		["police_alerts"] = { name = "Police Alerts", restrict = false },
		["ems_alerts"] = { name = "Medical Alerts", restrict = false },
		["doc_alerts"] = { name = "DOC View Dispatch", restrict = false },

		["impound"] = { name = "Regular Impound", restrict = { job = "police" } },
		["impound_police"] = { name = "Police Impound", restrict = { job = "police" } },

		["PD_RAID"] = { name = "Raid Property Storage", restrict = { job = "police" } },

		["JOB_STORAGE"] = { name = "Access Storage", restrict = false },

		["BANK_ACCOUNT_MANAGE"] = { name = "Bank Account - Manage", restrict = false },
		["BANK_ACCOUNT_BILL"] = { name = "Bank Account - Bill", restrict = false },
		["BANK_ACCOUNT_WITHDRAW"] = { name = "Bank Account - Withdraw", restrict = false },
		["BANK_ACCOUNT_DEPOSIT"] = { name = "Bank Account - Deposit", restrict = false },
		["BANK_ACCOUNT_TRANSACTIONS"] = { name = "Bank Account - View Transactions", restrict = false },
		["BANK_ACCOUNT_BALANCE"] = { name = "Bank Account - View Balance", restrict = false },

		["FLEET_VEHICLES_0"] = { name = "Fleet Vehicles Level 1", restrict = false },
		["FLEET_VEHICLES_1"] = { name = "Fleet Vehicles Level 2", restrict = false },
		["FLEET_VEHICLES_2"] = { name = "Fleet Vehicles Level 3", restrict = false },
		["FLEET_VEHICLES_3"] = { name = "Fleet Vehicles Level 4", restrict = false },
		["FLEET_VEHICLES_4"] = { name = "Fleet Vehicles Level 5", restrict = false },
		["FLEET_MANAGEMENT"] = { name = "Manage Vehicle Fleet", restrict = false },
		["PD_HIGH_COMMAND"] = { name = "PD High Command", restrict = { job = "police" } },
		["PD_COMMAND"] = { name = "PD Command", restrict = { job = "police" } },
		["MDT_HIRE"] = { name = "Hire Employees", restrict = false },
		["MDT_FIRE"] = { name = "Fire Employees", restrict = false },
		["MDT_PROMOTE"] = { name = "Demote/Promote", restrict = false },
		["MDT_EDIT_EMPLOYEE"] = { name = "Edit Employees", restrict = false },

		["SAFD_HIGH_COMMAND"] = { name = "EMS High Command", restrict = { job = "ems", workplace = "safd" } },

		-- Report Permissions
		["MDT_INCIDENT_REPORT_VIEW"] = { name = "View Incident Reports", restrict = false },
		["MDT_INCIDENT_REPORT_CREATE"] = { name = "Create Incident Reports", restrict = { job = "police" } },
		["MDT_INVESTIGATIVE_REPORT_CREATE"] = { name = "Create Investigation Reports", restrict = { job = "police" } },
		["MDT_INVESTIGATIVE_REPORT_VIEW"] = { name = "View Investigations", restrict = { job = "police" } },
		["MDT_CIVILIAN_REPORT_CREATE"] = { name = "Create Civilian Reports", restrict = { job = "police" } },
		["MDT_CIVILIAN_REPORT_VIEW"] = { name = "View Civilian Report", restrict = { job = "police" } },
		["MDT_POLICE_FTO_REPORTS"] = { name = "Create/View Field Training Reports", restrict = { job = "police" } },
		["MDT_POLICE_DISCIPLINARY_REPORTS"] = { name = "Create/View Disciplinary Reports", restrict = { job = "police" } },
		["MDT_JUDGE_REPORTS"] = { name = "Judge Reports/Documents", restrict = { job = "government" } },
		["MDT_DA_REPORTS"] = { name = "DA's Office Reports", restrict = { job = "government", workplace = "dattorney" } },
		["MDT_PUBDEFENDER_REPORTS"] = { name = "Public Defender Reports", restrict = { job = "government", workplace = "publicdefenders" } },
		["MDT_MEDICAL_REPORTS"] = { name = "Medical Reports", restrict = { job = "ems" } },

		["STATE_ACCOUNT_MANAGE"] = { name = "State Gov. - Manage", restrict = { job = "government" } },
		["STATE_ACCOUNT_WITHDRAW"] = { name = "State Gov. - Withdraw", restrict = { job = "government" } },
		["STATE_ACCOUNT_DEPOSIT"] = { name = "State Gov. - Deposit", restrict = { job = "government" } },
		["STATE_ACCOUNT_TRANSACTIONS"] = { name = "State Gov. - View Transactions", restrict = { job = "government" } },
		["STATE_ACCOUNT_BILL"] = { name = "State Gov. Account - View Balance", restrict = { job = "government" } },
		["ATTORNEY_PENDING_EVIDENCE"] = { name = "Attorney - View Report", restrict = false },
		["PD_SECURED_ARMORY"] = { name = "Access Secured Armory", restrict = { job = "police" } },
		["DOJ_JUDGE"] = { name = "DOJ Judge", restrict = { job = "government", workplace = "doj" } },
		["GOV_MAYOR"] = { name = "Govt. Mayor", restrict = { job = "government", workplace = "mayoroffice" } },
		["GOV_DA"] = { name = "Govt. District Attorney", restrict = { job = "government", workplace = "dattorney" } },
		["GOV_CPUB"] = { name = "Chief Public Defender", restrict = { job = "government", workplace = "publicdefenders" } },
		["BAR_CERTIFICATIONS"] = { name = "Grant Bar Certification", restrict = { job = "government", workplace = "doj" } },
		["REVOKE_LICENSE_SUSPENSIONS"] = { name = "Revoke License Suspensions", restrict = { job = "government", workplace = "doj" } },
		["EXPUNGEMENT"] = { name = "Expungements", restrict = { job = "government", workplace = "doj" } },
		["PD_MANAGE_TRIALS"] = { name = "Manage Interceptor Trials", restrict = { job = "police" } },
		["DOJ_DOCUMENTS_VIEW"] = { name = "View DOJ Documents", restrict = {} },
		["DOJ_DOCUMENTS_CREATE"] = { name = "Create DOJ Documents", restrict = { job = "government", workplace = "doj" } },
		["DOJ_TRIAL_FINDINGS_CREATE"] = { name = "Create DOJ Trial Findings", restrict = { job = "government", workplace = "doj" } },
		["DOC_HIGH_COMMAND"] = { name = "DOC - High Command", restrict = { job = "prison", workplace = "corrections" } },
		["DOC_REPORTS_VIEW"] = { name = "View DOC Reports", restrict = { job = "prison", workplace = "corrections" } },
		["DOC_REPORTS_CREATE"] = { name = "Create DOC Reports", restrict = { job = "prison", workplace = "corrections" } },
		["DOC_DOCUMENTS_VIEW"] = { name = "View DOC Documents", restrict = { job = "prison", workplace = "corrections" } },
		["DOC_DOCUMENTS_CREATE"] = { name = "Create DOC Documents", restrict = { job = "prison", workplace = "corrections" } },
		["DOC_REDUCTION"] = { name = "DOC - Reduce Sentence", restrict = { job = "prison", workplace = "corrections" } },
	},

	-- master catalog for the roster "Edit Qualifications" checklist
	Qualifications = {
		["PD_FTO"] = { name = "PD FTO", restrict = { job = "police" } },
		["PD_AIR"] = { name = "PD Air Cert.", restrict = { job = "police" } },
		["PD_BOAT"] = { name = "PD Boating Cert.", restrict = { job = "police" } },
		["PD_INTERCEPTOR"] = { name = "PD Interceptor Cert.", restrict = { job = "police" } },
		["PD_BIKE"] = { name = "PD Bike Cert.", restrict = { job = "police" } },
		["PD_SWAT"] = { name = "SWAT", restrict = { job = "police" } },
		["PD_DETCOORDS"] = { name = "PD Det Coords", restrict = { job = "police" } },
		["PD_BEANBAG"] = { name = "PD Beanbag", restrict = { weapon = true } },
		["PD_SMG"] = { name = "PD SMG", restrict = { weapon = true } },
		["PD_AR"] = { name = "PD AR", restrict = { weapon = true } },
		["PD_SHOTGUN"] = { name = "PD Shotgun", restrict = { weapon = true } },
		["PD_GRAPPLE"] = { name = "PD Grapple Gun", restrict = { job = "police" } },

		["EMS_LIFEFLIGHT"] = { name = "Lifeflight Air Cert.", restrict = { job = "ems", workplace = "safd" } },
		["EMS_DIVING"] = { name = "Scuba Cert.", restrict = { job = "ems", workplace = "safd" } },
		["EMS_FTO"] = { name = "Diving Cert.", restrict = { job = "ems", workplace = "safd" } },
		["EMS_SURGEON"] = { name = "Surgery Cert.", restrict = { job = "ems", workplace = "safd" } },
		["EMS_MH"] = { name = "Counseling Cert.", restrict = { job = "ems", workplace = "safd" } },
	},
}
