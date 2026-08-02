import type { Bolo, Charge, GovWorker, Notice, Warrant } from '../types';

interface HasId {
	id?: number;
	_id?: number;
}

// master catalogs (config/server.lua's Qualifications/Permissions), not the same shape as a person's own Qualifications string[] or jobPermissions flag map
export interface CatalogEntry {
	name: string;
	restrict?: { job?: string; workplace?: string; weapon?: boolean };
}

export const dataState = $state({
	charges: [] as Charge[],
	warrants: [] as Warrant[],
	notices: [] as Notice[],
	govWorkers: [] as GovWorker[],
	bolos: [] as Bolo[],
	qualifications: {} as Record<string, CatalogEntry>,
	permissions: {} as Record<string, CatalogEntry>,
	governmentJobs: [] as string[],
	governmentJobsData: {} as Record<string, unknown>,
	homeLastFetch: 0,
	// true while a prisoner is interacting with their in-cell kiosk MDT - forces the PublicPrison portal
	prison: false,
});

type BucketKey = keyof typeof dataState;

function matchesId(item: HasId, id: unknown): boolean {
	return item.id === id || item._id === id;
}

export function handleDataMessage(type: string, data: Record<string, unknown>) {
	const key = data.type as BucketKey;

	switch (type) {
		case 'RESET_DATA':
			dataState.charges = [];
			dataState.warrants = [];
			dataState.notices = [];
			dataState.govWorkers = [];
			dataState.bolos = [];
			dataState.qualifications = {};
			dataState.permissions = {};
			dataState.governmentJobs = [];
			dataState.governmentJobsData = {};
			dataState.homeLastFetch = 0;
			dataState.prison = false;
			break;
		case 'SET_DATA':
			setBucket(key, data.data);
			break;
		case 'ADD_DATA':
			addToBucket(key, data.data);
			break;
		case 'UPDATE_DATA':
			updateInBucket(key, data.id, data.data);
			break;
		case 'REMOVE_DATA':
			removeFromBucket(key, data.id);
			break;
	}
}

function setBucket(key: BucketKey, value: unknown) {
	switch (key) {
		case 'charges':
			dataState.charges = (value as Charge[]) ?? [];
			break;
		case 'warrants':
			dataState.warrants = (value as Warrant[]) ?? [];
			break;
		case 'notices':
			dataState.notices = (value as Notice[]) ?? [];
			break;
		case 'govWorkers':
			dataState.govWorkers = (value as GovWorker[]) ?? [];
			break;
		case 'bolos':
			dataState.bolos = (value as Bolo[]) ?? [];
			break;
		case 'qualifications':
			dataState.qualifications = (value as Record<string, CatalogEntry>) ?? {};
			break;
		case 'permissions':
			dataState.permissions = (value as Record<string, CatalogEntry>) ?? {};
			break;
		case 'governmentJobs':
			dataState.governmentJobs = (value as string[]) ?? [];
			break;
		case 'governmentJobsData':
			dataState.governmentJobsData = (value as Record<string, unknown>) ?? {};
			break;
		case 'homeLastFetch':
			dataState.homeLastFetch = (value as number) ?? 0;
			break;
		case 'prison':
			dataState.prison = Boolean(value);
			break;
	}
}

function addToBucket(key: BucketKey, item: unknown) {
	switch (key) {
		case 'charges':
			dataState.charges = [...dataState.charges, item as Charge];
			break;
		case 'warrants':
			dataState.warrants = [...dataState.warrants, item as Warrant];
			break;
		case 'notices':
			dataState.notices = [item as Notice, ...dataState.notices];
			break;
		case 'govWorkers':
			dataState.govWorkers = [...dataState.govWorkers, item as GovWorker];
			break;
		case 'bolos':
			dataState.bolos = [item as Bolo, ...dataState.bolos];
			break;
	}
}

function updateInBucket(key: BucketKey, id: unknown, patch: unknown) {
	switch (key) {
		case 'charges':
			dataState.charges = dataState.charges.map((c) => (matchesId(c, id) ? { ...c, ...(patch as Charge) } : c));
			break;
		case 'warrants':
			dataState.warrants = dataState.warrants.map((w) => (matchesId(w, id) ? { ...w, ...(patch as Warrant) } : w));
			break;
	}
}

function removeFromBucket(key: BucketKey, id: unknown) {
	switch (key) {
		case 'charges':
			dataState.charges = dataState.charges.filter((c) => !matchesId(c, id));
			break;
		case 'bolos':
			dataState.bolos = dataState.bolos.filter((b) => !matchesId(b, id));
			break;
		case 'notices':
			dataState.notices = dataState.notices.filter((n) => !matchesId(n, id));
			break;
	}
}
