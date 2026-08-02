export interface BadgeData {
	First?: string;
	Last?: string;
	Department?: string;
	Title?: string;
	SID?: number | string;
	Callsign?: number | string;
	Mugshot?: string;
	/** live pedheadshot texture dictionary (see RegisterPedheadshotTransparent) - preferred over Mugshot when present */
	HeadshotTxd?: string;
	// driver's license shape
	Name?: string;
	Gender?: number;
	DOB?: string;
}

export const badgeState = $state({
	showing: false,
	/** 1 = government ID badge, 2 = driver's license */
	type: 0 as 0 | 1 | 2,
	data: null as BadgeData | null,
});

let hideTimer: ReturnType<typeof setTimeout> | undefined;

export function handleBadgeMessage(type: string, data: Record<string, unknown>) {
	switch (type) {
		case 'SHOW_GOV_ID':
			show(1, data as BadgeData);
			break;
		case 'SHOW_DRIVER_LICENSE':
			show(2, data as BadgeData);
			break;
		case 'HIDE_GOV_ID':
			if (badgeState.type === 1) hide();
			break;
		case 'HIDE_DRIVER_LICENSE':
			if (badgeState.type === 2) hide();
			break;
	}
}

function show(kind: 1 | 2, data: BadgeData) {
	clearTimeout(hideTimer);
	badgeState.showing = true;
	badgeState.type = kind;
	badgeState.data = data;
	// Lua-side auto-clears after ~9-11s depending on badge/license; mirror that here in case HIDE_* is missed
	hideTimer = setTimeout(hide, 11000);
}

function hide() {
	clearTimeout(hideTimer);
	badgeState.showing = false;
	badgeState.type = 0;
	badgeState.data = null;
}
