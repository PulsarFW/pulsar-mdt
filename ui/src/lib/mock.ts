import { applyMessage } from './messages';
import {
	MOCK_ALL_PERMISSIONS,
	MOCK_BOLOS,
	MOCK_CHARGES,
	MOCK_DISPATCH_ALERTS,
	MOCK_DISPATCH_LOG,
	MOCK_DISPATCH_UNITS,
	MOCK_GOV_JOB,
	MOCK_GOVERNMENT_JOBS_DATA,
	MOCK_JOB_PRESETS,
	MOCK_MY_UNIT,
	MOCK_PERMISSIONS,
	MOCK_PERMISSIONS_CATALOG,
	MOCK_QUALIFICATIONS,
	MOCK_RADIO_NAMES,
	MOCK_USER,
} from './mockData';

function seedCatalogs(): void {
	applyMessage('SET_DATA', { type: 'charges', data: MOCK_CHARGES });
	applyMessage('SET_DATA', { type: 'governmentJobs', data: Object.keys(MOCK_GOVERNMENT_JOBS_DATA) });
	applyMessage('SET_DATA', { type: 'governmentJobsData', data: MOCK_GOVERNMENT_JOBS_DATA });
	applyMessage('SET_DATA', { type: 'qualifications', data: MOCK_QUALIFICATIONS });
	applyMessage('SET_DATA', { type: 'permissions', data: MOCK_PERMISSIONS_CATALOG });
	applyMessage('SET_DATA', { type: 'bolos', data: MOCK_BOLOS });
}

// simulates the native ALERTS_DISPATCH_INIT broadcast, no websocket involved, matches the always-on path
function seedDispatch(): void {
	applyMessage('ALERTS_DISPATCH_INIT', {
		myUnit: MOCK_MY_UNIT,
		units: MOCK_DISPATCH_UNITS,
		alerts: MOCK_DISPATCH_ALERTS,
		radioNames: MOCK_RADIO_NAMES,
		dispatchLog: MOCK_DISPATCH_LOG,
	});
}

export function startMock(): void {
	setTimeout(() => {
		applyMessage('SET_USER', { user: MOCK_USER });
		applyMessage('JOB_LOGIN', {
			points: { reduction: 50, license: 20 },
			job: MOCK_GOV_JOB,
			jobPermissions: MOCK_PERMISSIONS,
			attorney: false,
		});
		seedCatalogs();
		seedDispatch();
		applyMessage('APP_SHOW', {});
	}, 200);
}

// re-fires SET_USER + JOB_LOGIN with a different identity, grantAll grants every permission flag, isSystemAdmin bypasses permission checks entirely
export function switchMockIdentity(presetKey: string, grantAll: boolean, isSystemAdmin: boolean): void {
	const preset = MOCK_JOB_PRESETS[presetKey];
	if (!preset) return;
	applyMessage('SET_USER', { user: { ...MOCK_USER, MDTSystemAdmin: isSystemAdmin } });
	applyMessage('JOB_LOGIN', {
		points: { reduction: 50, license: 20 },
		job: preset.job,
		jobPermissions: grantAll ? MOCK_ALL_PERMISSIONS : MOCK_PERMISSIONS,
		attorney: preset.attorney,
	});
}
