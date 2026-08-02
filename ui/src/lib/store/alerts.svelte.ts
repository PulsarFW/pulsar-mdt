import { io, type Socket } from 'socket.io-client';
import { Nui } from '../nui';
import type { DispatchAlert, DispatchLogEntry, DispatchUnit, DispatchUnits, RadioName } from '../types';

export const alertsState = $state({
	showing: false,
	connected: false,
	units: {} as DispatchUnits,
	alerts: [] as DispatchAlert[],
	myUnit: null as DispatchUnit | null,
	radioNames: [] as RadioName[],
	dispatchLog: [] as DispatchLogEntry[],
	dispatchExpanded: true,
	rosterSections: {} as Record<string, boolean>,
	// alert ids I've already been notified I'm attached to, so AssignedToAlert only fires once per attach
	attachedAlertIds: [] as string[],
	// optional external mirror connection - purely cosmetic/status, nothing above depends on this being true
	socketConnected: false,
});

// Lua tables serialize empty arrays as `{}` not `[]`, defensively coerce anywhere a Lua-sourced array might arrive empty
function arr<T>(x: unknown): T[] {
	return Array.isArray(x) ? (x as T[]) : [];
}

function myCallsign(): string | number | null {
	const mine = alertsState.myUnit;
	if (!mine) return null;
	const live = alertsState.units[mine.job]?.find((u) => u.primary === mine.primary);
	return live?.operatingUnder ?? live?.primary ?? mine.primary;
}

function trimLog(log: DispatchLogEntry[]): DispatchLogEntry[] {
	return log.length > 200 ? log.slice(log.length - 200) : log;
}

function addAlert(alert: DispatchAlert) {
	const now = Date.now();
	const normalized: DispatchAlert = { ...alert, attached: arr(alert.attached), onScreen: true, time: alert.time ?? now };
	alertsState.alerts = [...alertsState.alerts.filter((a) => a.time >= now - 1800000 || a.attached.length > 0), normalized];
	Nui.receiveAlert(normalized);
}

let mirrorSocket: Socket | null = null;

function connectMirror(url: string, token: string) {
	if (!url) return;
	mirrorSocket?.disconnect();
	mirrorSocket = io(url, { query: { token } });
	mirrorSocket.on('connect', () => {
		alertsState.socketConnected = true;
	});
	mirrorSocket.on('disconnect', () => {
		alertsState.socketConnected = false;
	});
	// best-effort inbound sync from a companion website MDT, if the server owner built one - purely additive
	mirrorSocket.on('alert', (alert: DispatchAlert) => addAlert(alert));
	mirrorSocket.on('dispatchLog', (log: DispatchLogEntry) => {
		alertsState.dispatchLog = trimLog([...alertsState.dispatchLog, log]);
	});
}

function disconnectMirror() {
	mirrorSocket?.disconnect();
	mirrorSocket = null;
	alertsState.socketConnected = false;
}

export function handleAlertsMessage(type: string, data: Record<string, unknown>) {
	switch (type) {
		case 'SET_SHOWING':
			alertsState.showing = Boolean(data.state);
			break;
		case 'ADD_ALERT':
			addAlert(data.alert as DispatchAlert);
			break;
		case 'ALERTS_DISPATCH_INIT': {
			const myUnit = data.myUnit as DispatchUnit;
			const units = (data.units ?? {}) as DispatchUnits;
			alertsState.myUnit = myUnit;
			alertsState.units = {
				police: arr(units.police),
				ems: arr(units.ems),
				prison: arr(units.prison),
				tow: arr(units.tow),
			};
			alertsState.alerts = arr<DispatchAlert>(data.alerts).map((a) => ({ ...a, attached: arr(a.attached) }));
			alertsState.radioNames = arr(data.radioNames);
			alertsState.dispatchLog = arr(data.dispatchLog);
			alertsState.connected = true;
			alertsState.rosterSections = { police: false, ems: false, prison: false, tow: false, [myUnit.job]: true };
			break;
		}
		case 'ALERTS_UNIT_ADD': {
			const unit = data.unit as DispatchUnit;
			alertsState.units = { ...alertsState.units, [unit.job]: [...(alertsState.units[unit.job] ?? []), unit] };
			break;
		}
		case 'ALERTS_UNIT_REMOVE': {
			const job = data.job as string;
			const source = data.source as number;
			alertsState.units = { ...alertsState.units, [job]: (alertsState.units[job] ?? []).filter((u) => u.source !== source) };
			break;
		}
		case 'ALERTS_UNIT_UPDATE': {
			const job = data.job as string;
			const primary = data.primary as string | number;
			const key = data.key as string;
			alertsState.units = {
				...alertsState.units,
				[job]: (alertsState.units[job] ?? []).map((u) => (u.primary === primary ? { ...u, [key]: data.value } : u)),
			};
			break;
		}
		case 'ALERTS_UNIT_OPERATE_UNDER': {
			const job = data.job as string;
			const callsign = data.callsign as string | number;
			const primary = data.primary as string | number;
			alertsState.units = {
				...alertsState.units,
				[job]: (alertsState.units[job] ?? []).map((u) => (u.primary === callsign ? { ...u, operatingUnder: primary } : u)),
			};
			break;
		}
		case 'ALERTS_UNIT_BREAK_OFF': {
			const job = data.job as string;
			const callsign = data.callsign as string | number;
			alertsState.units = {
				...alertsState.units,
				[job]: (alertsState.units[job] ?? []).map((u) => (u.primary === callsign ? { ...u, operatingUnder: null } : u)),
			};
			break;
		}
		case 'ALERTS_ALERT_UPDATE_UNITS': {
			const id = data.id as string;
			const units = arr<string | number>(data.units);
			alertsState.alerts = alertsState.alerts.map((a) => (a.id === id ? { ...a, attached: units as string[] } : a));

			const mine = myCallsign();
			const meAttached = mine !== null && units.includes(mine);
			if (meAttached && !alertsState.attachedAlertIds.includes(id)) {
				alertsState.attachedAlertIds = [...alertsState.attachedAlertIds, id];
				Nui.assignedToAlert();
			} else if (!meAttached && alertsState.attachedAlertIds.includes(id)) {
				alertsState.attachedAlertIds = alertsState.attachedAlertIds.filter((x) => x !== id);
			}
			break;
		}
		case 'ALERTS_ALERT_REMOVE': {
			const id = data.id as string;
			alertsState.alerts = alertsState.alerts.filter((a) => a.id !== id);
			Nui.removeAlert(id);
			break;
		}
		case 'ALERTS_RADIO_UPDATE':
			alertsState.radioNames = arr(data.data);
			break;
		case 'ALERTS_LOG_ADD':
			alertsState.dispatchLog = trimLog([...alertsState.dispatchLog, data.log as DispatchLogEntry]);
			break;
		case 'ALERTS_WS_CONNECT':
			connectMirror((data.url as string) ?? '', (data.token as string) ?? '');
			break;
		case 'ALERTS_WS_DISCONNECT':
			disconnectMirror();
			break;
		case 'ALERTS_UPDATE_PURSUIT_MODE':
			// Lua-sourced pursuit flag for my own character, loop it back through the native action so the roster reflects it for every on-duty officer
			changePursuitMode((data.mode as string | null) ?? null);
			break;
		case 'ALERTS_UPDATE_RADIO_CHANNEL':
			changeRadioChannel((data.channel as string) ?? '');
			break;
	}
}

export function toggleDispatchLog(): void {
	alertsState.dispatchExpanded = !alertsState.dispatchExpanded;
}

export function toggleRosterSection(jobType: string): void {
	alertsState.rosterSections = { ...alertsState.rosterSections, [jobType]: !alertsState.rosterSections[jobType] };
}

export function changeUnitType(job: string, primary: string | number, unitType: string): void {
	Nui.alertsChangeUnitType(job, primary, unitType);
}

export function changeAvailability(job: string, primary: string | number): void {
	Nui.alertsChangeAvailability(job, primary);
}

export function operateUnder(job: string, primary: string | number, unit: string | number): void {
	Nui.alertsOperateUnder(job, primary, unit);
}

export function breakOff(job: string, primary: string | number, unit: string | number): void {
	Nui.alertsBreakOff(job, primary, unit);
}

export function changeRadioChannel(channel: string): void {
	Nui.alertsChangeRadioChannel(channel);
}

export function changePursuitMode(mode: string | null): void {
	Nui.alertsChangePursuitMode(mode);
}

export function updateAlertUnits(id: string, units: (string | number)[]): void {
	Nui.alertsUpdateAlertUnits(id, units);
}

export function removeAlert(alert: DispatchAlert): void {
	if (alert.client) {
		alertsState.alerts = alertsState.alerts.filter((a) => a.id !== alert.id);
		Nui.removeAlert(alert.id);
	} else {
		Nui.alertsRemoveAlert(alert.id);
	}
}

export function addRadioInfo(radio: string, text: string): void {
	Nui.alertsAddRadioInfo(radio, text);
}

export function updateRadioInfo(id: number, radio: string, text: string): void {
	Nui.alertsUpdateRadioInfo(id, radio, text);
}

export function removeRadioInfo(id: number): void {
	Nui.alertsRemoveRadioInfo(id);
}

export function logDispatchMessage(message: string): void {
	Nui.alertsLogMessage(message);
}

export function routeToAlert(alert: DispatchAlert): void {
	Nui.routeAlert(alert);
}
