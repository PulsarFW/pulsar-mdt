-- server-only, not exposed to the client/NUI, put client-visible stuff in config/shared.lua instead
return {
	Items = { -- inventory item names this resource looks for by RegisterUse
		governmentBadge = "government_badge",
		governmentId = "govid",
	},

	Points = { -- sent to the client on login as pointBreakpoints
		reduction = 50, -- points below eligible for a sentence reduction
		license = 20, -- points to suspend a driving license
	},

	Badges = {
		printCooldownMs = 20000, -- /printbadge cooldown per player
	},

	Warrants = {
		defaultDurationDays = 7, -- new warrant expiry
	},

	Vehicles = {
		strikeExpiryDays = 30, -- startup cleanup purges strikes older than this
	},

	DOC = {
		visitationLobby = { street1 = "Bolingbroke Penitentiary", coords = vector3(1852.444, 2585.973, 45.672) },
	},

	Employment = {
		maxSuspensionDays = 99,
	},

	Alerts = {
		dispatchLogMaxEntries = 200,
		activeAlertsMaxEntries = 50,
		injuredPersonCooldownSec = 120,
		areaJitterRadius = 50, -- meters an "area" alert's coords get randomized by
		trackerDisabledAlertDurationSec = 600, -- how long the "tracker disabled" blip stays up
		recentAlertWindowSec = 900, -- 15 min - an alert is still "eligible" to a newly-on-duty unit within this window, regardless of attached units
	},
}
