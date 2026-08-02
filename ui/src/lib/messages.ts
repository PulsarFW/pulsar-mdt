import { handleAppMessage } from './store/app.svelte';
import { handleDataMessage } from './store/data.svelte';
import { handleBadgeMessage } from './store/badge.svelte';
import { handleBodycamMessage } from './store/bodycam.svelte';
import { handleAlertsMessage } from './store/alerts.svelte';

interface InboundMessage {
	type?: string;
	data?: unknown;
}

const APP_TYPES = new Set(['SET_USER', 'JOB_LOGIN', 'JOB_UPDATE', 'JOB_LOGOUT', 'LOGOUT', 'APP_SHOW', 'APP_HIDE']);
const DATA_TYPES = new Set(['SET_DATA', 'ADD_DATA', 'UPDATE_DATA', 'REMOVE_DATA', 'RESET_DATA']);
const BADGE_TYPES = new Set(['SHOW_GOV_ID', 'HIDE_GOV_ID', 'SHOW_DRIVER_LICENSE', 'HIDE_DRIVER_LICENSE']);
const BODYCAM_TYPES = new Set(['SET_BODYCAM', 'TOGGLE_BODYCAM']);
const ALERTS_TYPES = new Set([
	'SET_SHOWING',
	'ADD_ALERT',
	'ALERTS_WS_CONNECT',
	'ALERTS_WS_DISCONNECT',
	'ALERTS_UPDATE_PURSUIT_MODE',
	'ALERTS_UPDATE_RADIO_CHANNEL',
	// native dispatch broadcasts (client/alerts/dispatch.lua) - always fire, no websocket required
	'ALERTS_DISPATCH_INIT',
	'ALERTS_UNIT_ADD',
	'ALERTS_UNIT_REMOVE',
	'ALERTS_UNIT_UPDATE',
	'ALERTS_UNIT_OPERATE_UNDER',
	'ALERTS_UNIT_BREAK_OFF',
	'ALERTS_ALERT_UPDATE_UNITS',
	'ALERTS_ALERT_REMOVE',
	'ALERTS_RADIO_UPDATE',
	'ALERTS_LOG_ADD',
]);

function route(type: string, data: unknown) {
	const record = (data ?? {}) as Record<string, unknown>;
	if (APP_TYPES.has(type)) return handleAppMessage(type, record);
	if (DATA_TYPES.has(type)) return handleDataMessage(type, record);
	if (BADGE_TYPES.has(type)) return handleBadgeMessage(type, record);
	if (BODYCAM_TYPES.has(type)) return handleBodycamMessage(type, record);
	if (ALERTS_TYPES.has(type)) return handleAlertsMessage(type, record);
}

/** Returns an unsubscribe function */
export function attachMessageListener(): () => void {
	const handler = (event: MessageEvent<InboundMessage>) => {
		if (!event.isTrusted) return;
		if (event.data?.type) route(event.data.type, event.data.data);
	};
	window.addEventListener('message', handler);
	return () => window.removeEventListener('message', handler);
}

export { route as applyMessage };
