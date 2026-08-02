import type { PageId, PointBreakpoints } from '../../config';
import type { GovJob, PermissionMap, User } from '../types';

interface NavEntry {
	page: PageId;
	params: Record<string, string>;
}

export const appState = $state({
	hidden: true,
	opacity: false,
	user: null as User | null,
	userHeadshotTxd: null as string | null,
	govJob: null as GovJob | null,
	govJobPermissions: {} as PermissionMap,
	attorney: false,
	pointBreakpoints: { reduction: 50, license: 20 } as PointBreakpoints,
	page: 'home' as PageId,
	pageParams: {} as Record<string, string>,
	navStack: [] as NavEntry[],
});

export interface Toast {
	id: number;
	kind: 'success' | 'error';
	message: string;
}

export const toastState = $state({ toasts: [] as Toast[] });

let nextToastId = 1;
export const toast = {
	success(message: string) {
		push('success', message);
	},
	error(message: string) {
		push('error', message);
	},
};

function push(kind: 'success' | 'error', message: string) {
	const id = nextToastId++;
	toastState.toasts = [...toastState.toasts, { id, kind, message }];
	setTimeout(() => dismissToast(id), 4000);
}

export function dismissToast(id: number) {
	toastState.toasts = toastState.toasts.filter((t) => t.id !== id);
}

export function handleAppMessage(type: string, data: Record<string, unknown>) {
	switch (type) {
		case 'SET_USER':
			appState.user = data.user as User;
			if (data.headshot) appState.userHeadshotTxd = data.headshot as string;
			break;
		case 'JOB_LOGIN':
			appState.pointBreakpoints = (data.points as PointBreakpoints) ?? appState.pointBreakpoints;
			appState.govJob = data.job as GovJob;
			appState.govJobPermissions = (data.jobPermissions as PermissionMap) ?? {};
			appState.attorney = Boolean(data.attorney);
			resetNav();
			break;
		case 'JOB_UPDATE':
			appState.govJob = (data.job as GovJob) ?? appState.govJob;
			appState.govJobPermissions = (data.jobPermissions as PermissionMap) ?? appState.govJobPermissions;
			break;
		case 'LOGOUT':
		case 'JOB_LOGOUT':
			// JOB_LOGOUT fires when the player leaves their job specifically, without the full character-logout side effects, same portal fallback either way
			appState.govJob = null;
			appState.govJobPermissions = {};
			appState.attorney = false;
			resetNav();
			break;
		case 'APP_SHOW':
			appState.hidden = false;
			appState.opacity = false;
			break;
		case 'APP_HIDE':
			appState.hidden = true;
			appState.opacity = false;
			break;
	}
}

function resetNav() {
	appState.page = 'home';
	appState.pageParams = {};
	appState.navStack = [];
}

/** Pushes the current page onto the back-stack, then navigates forward */
export function navigate(page: PageId, params: Record<string, string> = {}) {
	appState.navStack = [...appState.navStack, { page: appState.page, params: appState.pageParams }];
	appState.page = page;
	appState.pageParams = params;
}

export function goBack() {
	if (appState.navStack.length === 0) return;
	const prev = appState.navStack[appState.navStack.length - 1];
	appState.navStack = appState.navStack.slice(0, -1);
	appState.page = prev.page;
	appState.pageParams = prev.params;
}

export function setOpacity(state: boolean) {
	if (!appState.hidden) appState.opacity = state;
}
