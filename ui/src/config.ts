/*
	Pulsar MDT content config.
	Server owners: for colors/fonts, edit theme.css instead.
*/

export type PortalId = 'police' | 'doj' | 'da' | 'publicdefenders' | 'medical' | 'doc' | 'attorney' | 'public';

export type PageId =
	| 'home'
	| 'reports'
	| 'people'
	| 'vehicles'
	| 'firearms'
	| 'warrants'
	| 'properties'
	| 'roster'
	| 'penal-code'
	| 'library'
	| 'fleet-manager'
	| 'prisoners'
	| 'admin-permissions'
	| 'admin-charges'
	| 'create-notice'
	| 'create-bolo'
	| 'error';

export interface NavLink {
	page: PageId;
	icon: string;
	label: string;
	/** job-permission flag required to show this link, MDTSystemAdmin always bypasses, undefined = shown to anyone in the portal */
	permission?: string;
	/** shown only to MDTSystemAdmin, no department permission can grant it */
	systemAdminOnly?: boolean;
}

// one route/permission table per portal, every portal renders through the same Shell.svelte + Navbar, only this table differs
const REPORTS_PEOPLE_VEHICLES_CORE: NavLink[] = [
	{ page: 'reports', icon: 'file-lines', label: 'Reports' },
	{ page: 'people', icon: 'people', label: 'People' },
	{ page: 'vehicles', icon: 'car', label: 'Vehicles' },
	{ page: 'firearms', icon: 'gun', label: 'Firearms' },
	{ page: 'warrants', icon: 'file-signature', label: 'Warrants' },
	{ page: 'properties', icon: 'house', label: 'Properties' },
];

const ROSTER_LIBRARY_TAIL: NavLink[] = [
	{ page: 'roster', icon: 'address-book', label: 'Roster' },
	{ page: 'penal-code', icon: 'gavel', label: 'Penal Code' },
	{ page: 'library', icon: 'book', label: 'Library' },
];

export const PORTAL_ROUTES: Record<PortalId, NavLink[]> = {
	police: [
		{ page: 'home', icon: 'house', label: 'Dashboard' },
		...REPORTS_PEOPLE_VEHICLES_CORE,
		...ROSTER_LIBRARY_TAIL,
		{ page: 'fleet-manager', icon: 'car-side', label: 'Fleet Manager', permission: 'FLEET_MANAGEMENT' },
		{ page: 'admin-permissions', icon: 'lock', label: 'Permissions', permission: 'PD_HIGH_COMMAND' },
		{ page: 'admin-charges', icon: 'scale-balanced', label: 'Charges (Admin)', systemAdminOnly: true },
	],
	doj: [
		{ page: 'home', icon: 'house', label: 'Home' },
		...REPORTS_PEOPLE_VEHICLES_CORE,
		...ROSTER_LIBRARY_TAIL,
		{ page: 'admin-permissions', icon: 'lock', label: 'Permissions', permission: 'DOJ_JUDGE' },
		{ page: 'admin-charges', icon: 'scale-balanced', label: 'Charges (Admin)', systemAdminOnly: true },
	],
	da: [
		{ page: 'home', icon: 'house', label: 'Home' },
		...REPORTS_PEOPLE_VEHICLES_CORE,
		...ROSTER_LIBRARY_TAIL,
		{ page: 'admin-permissions', icon: 'lock', label: 'Permissions', permission: 'GOV_DA' },
		{ page: 'admin-charges', icon: 'scale-balanced', label: 'Charges (Admin)', systemAdminOnly: true },
	],
	publicdefenders: [
		{ page: 'home', icon: 'house', label: 'Home' },
		...REPORTS_PEOPLE_VEHICLES_CORE,
		...ROSTER_LIBRARY_TAIL,
	],
	medical: [
		{ page: 'home', icon: 'house', label: 'Home' },
		{ page: 'reports', icon: 'file-lines', label: 'Reports' },
		{ page: 'people', icon: 'people', label: 'People' },
		{ page: 'roster', icon: 'address-book', label: 'Roster' },
		{ page: 'library', icon: 'book', label: 'Library' },
		{ page: 'fleet-manager', icon: 'car-side', label: 'Fleet Manager', permission: 'FLEET_MANAGEMENT' },
		{ page: 'admin-permissions', icon: 'lock', label: 'Permissions', permission: 'SAFD_HIGH_COMMAND' },
		{ page: 'admin-charges', icon: 'scale-balanced', label: 'Charges (Admin)', systemAdminOnly: true },
	],
	doc: [
		{ page: 'home', icon: 'house', label: 'Home' },
		{ page: 'reports', icon: 'file-lines', label: 'Reports' },
		{ page: 'people', icon: 'people', label: 'People' },
		{ page: 'vehicles', icon: 'car', label: 'Vehicles' },
		{ page: 'roster', icon: 'address-book', label: 'Roster' },
		{ page: 'penal-code', icon: 'gavel', label: 'Penal Code' },
		{ page: 'library', icon: 'book', label: 'Library' },
		{ page: 'prisoners', icon: 'user-lock', label: 'Prisoners' },
		{ page: 'fleet-manager', icon: 'car-side', label: 'Fleet Manager', permission: 'FLEET_MANAGEMENT' },
		{ page: 'admin-permissions', icon: 'lock', label: 'Permissions', permission: 'DOC_HIGH_COMMAND' },
		{ page: 'admin-charges', icon: 'scale-balanced', label: 'Charges (Admin)', systemAdminOnly: true },
	],
	attorney: [
		{ page: 'home', icon: 'house', label: 'Home' },
		...REPORTS_PEOPLE_VEHICLES_CORE,
		...ROSTER_LIBRARY_TAIL,
	],
	public: [
		{ page: 'home', icon: 'house', label: 'Home' },
		{ page: 'warrants', icon: 'file-signature', label: 'Warrants' },
		{ page: 'penal-code', icon: 'gavel', label: 'Penal Code' },
		{ page: 'library', icon: 'book', label: 'Library' },
	],
};

export function navLinksFor(portal: PortalId, permissions: Record<string, boolean>, isSystemAdmin: boolean): NavLink[] {
	return PORTAL_ROUTES[portal].filter((link) => {
		if (link.systemAdminOnly) return isSystemAdmin;
		return !link.permission || isSystemAdmin || permissions[link.permission];
	});
}

// null govJob + not an attorney falls through to the unauthenticated `public` portal (warrants/penal-code/library only)
export function resolvePortal(govJob: { Id: string; Workplace?: { Id: string } } | null, attorney: boolean): PortalId {
	if (!govJob) return attorney ? 'attorney' : 'public';
	switch (govJob.Id) {
		case 'police':
			return 'police';
		case 'government':
			switch (govJob.Workplace?.Id) {
				case 'doj':
					return 'doj';
				case 'dattorney':
					return 'da';
				case 'publicdefenders':
					return 'publicdefenders';
				default:
					return 'public';
			}
		case 'prison':
			return 'doc';
		case 'ems':
			return 'medical';
		default:
			return attorney ? 'attorney' : 'public';
	}
}

export interface Branding {
	primary: string;
	secondary: string;
}

// titlebar text per portal
export function brandingFor(govJob: { Id: string; Workplace?: { Id: string; Name: string } } | null, attorney: boolean): Branding {
	if (attorney && !govJob) {
		return { primary: 'Electronic Records System', secondary: 'San Andreas Department of Justice' };
	}
	switch (govJob?.Id) {
		case 'police':
			return { primary: govJob.Workplace?.Name ?? 'Police', secondary: 'Electronic Records System' };
		case 'prison':
			return { primary: 'San Andreas Department of Corrections', secondary: 'Electronic Records System' };
		case 'government':
			if (govJob.Workplace?.Id === 'doj') {
				return { primary: 'San Andreas Department of Justice', secondary: 'Electronic Records System' };
			}
			return { primary: 'State of San Andreas', secondary: 'Public Records Repository' };
		case 'ems':
			return { primary: 'State of San Andreas Medical Services', secondary: 'Electronic Records System' };
		default:
			return { primary: 'State of San Andreas', secondary: 'Public Records Repository' };
	}
}

export type DeptKey = 'lspd' | 'guardius' | 'bcso' | 'sast' | 'doj' | 'medical' | 'standard';

// per-department background/accent palette, keyed by workplace not job, applied via a `data-dept` attribute in App.svelte, see theme.css for the values
export function deptKeyFor(govJob: { Workplace?: { Id: string } } | null): DeptKey {
	switch (govJob?.Workplace?.Id) {
		case 'lspd':
			return 'lspd';
		case 'guardius':
			return 'guardius';
		case 'bcso':
			return 'bcso';
		case 'sast':
			return 'sast';
		case 'doj':
		case 'dattorney':
		case 'mayoroffice':
			return 'doj';
		case 'doctors':
		case 'safd':
			return 'medical';
		default:
			return 'standard';
	}
}

// ---- Report types ----
// requiredViewPermission/requiredCreatePermission are real authorization gates, not labels, only type 0 (Incident Report) carries a Suspects list, every other type uses the plain Primaries/People pickers
export interface ReportTypeDef {
	value: number;
	label: string;
	short: string;
	requiredViewPermission?: string;
	requiredCreatePermission?: string;
	hasEvidence?: boolean;
	allowAttorney?: boolean;
	officerName?: string;
	officerType?: 'police' | 'ems' | 'government' | 'prison';
}

export const REPORT_TYPES: ReportTypeDef[] = [
	{ value: 0, label: 'Incident Report', short: 'Incident', requiredViewPermission: 'MDT_INCIDENT_REPORT_VIEW', requiredCreatePermission: 'MDT_INCIDENT_REPORT_CREATE', hasEvidence: true, allowAttorney: true },
	{ value: 1, label: 'Investigative Report', short: 'Investigation', requiredViewPermission: 'MDT_INVESTIGATIVE_REPORT_VIEW', requiredCreatePermission: 'MDT_INVESTIGATIVE_REPORT_CREATE', hasEvidence: true, allowAttorney: true },
	{ value: 2, label: 'Civilian Report', short: 'Civ. Report', requiredViewPermission: 'MDT_CIVILIAN_REPORT_VIEW', requiredCreatePermission: 'MDT_CIVILIAN_REPORT_CREATE', hasEvidence: true, allowAttorney: true },
	{ value: 3, label: 'PD Field Training Reports', short: 'PD FTO', requiredViewPermission: 'MDT_POLICE_FTO_REPORTS', requiredCreatePermission: 'MDT_POLICE_FTO_REPORTS' },
	{ value: 4, label: 'PD Disciplinary Reports', short: 'Disciplinary', requiredViewPermission: 'MDT_POLICE_DISCIPLINARY_REPORTS', requiredCreatePermission: 'MDT_POLICE_DISCIPLINARY_REPORTS' },
	{ value: 5, label: 'PD Command Documents', short: 'PD Command', requiredViewPermission: 'PD_COMMAND', requiredCreatePermission: 'PD_COMMAND' },
	{ value: 6, label: 'PD High Command Documents', short: 'PD HC', requiredViewPermission: 'PD_HIGH_COMMAND', requiredCreatePermission: 'PD_HIGH_COMMAND' },
	{ value: 10, label: 'Medical Report', short: 'Medical', requiredViewPermission: 'MDT_MEDICAL_REPORTS', requiredCreatePermission: 'MDT_MEDICAL_REPORTS', officerName: 'Medic', officerType: 'ems' },
	{ value: 11, label: 'EMS Documents', short: 'EMS Docs', requiredViewPermission: 'MDT_MEDICAL_REPORTS', requiredCreatePermission: 'MDT_MEDICAL_REPORTS', officerName: 'Medic', officerType: 'ems' },
	{ value: 12, label: 'EMS HC Documents', short: 'EMS HC', requiredViewPermission: 'SAFD_HIGH_COMMAND', requiredCreatePermission: 'SAFD_HIGH_COMMAND', officerName: 'Medic', officerType: 'ems' },
	{ value: 20, label: 'Trial Findings (Public)', short: 'Trial', requiredCreatePermission: 'DOJ_TRIAL_FINDINGS_CREATE', officerName: 'Judges', officerType: 'government' },
	{ value: 21, label: 'Judge Private Documents', short: 'DOJ Judge', requiredViewPermission: 'MDT_JUDGE_REPORTS', requiredCreatePermission: 'MDT_JUDGE_REPORTS', officerName: 'Judges', officerType: 'government' },
	{ value: 22, label: 'DOJ Documents', short: 'DOJ', requiredViewPermission: 'DOJ_DOCUMENTS_VIEW', requiredCreatePermission: 'DOJ_DOCUMENTS_CREATE', officerName: 'Judges', officerType: 'government', allowAttorney: true },
	{ value: 25, label: "DA's Office Reports", short: 'DA', requiredViewPermission: 'MDT_DA_REPORTS', requiredCreatePermission: 'MDT_DA_REPORTS', officerName: 'Prosecutors', officerType: 'government' },
	{ value: 26, label: 'Pub. Defender Reports', short: 'Pub. Defender', requiredViewPermission: 'MDT_PUBDEFENDER_REPORTS', requiredCreatePermission: 'MDT_PUBDEFENDER_REPORTS', officerName: 'Public Defenders', officerType: 'government' },
	{ value: 30, label: 'DOC Reports', short: 'DOC Reports', requiredViewPermission: 'DOC_REPORTS_VIEW', requiredCreatePermission: 'DOC_REPORTS_CREATE', officerName: 'Officer', officerType: 'prison', hasEvidence: true },
	{ value: 31, label: 'DOC Documents', short: 'DOC Documents', requiredViewPermission: 'DOC_DOCUMENTS_VIEW', requiredCreatePermission: 'DOC_DOCUMENTS_CREATE', officerName: 'Officer', officerType: 'prison' },
];

export function reportOfficerName(reportType: number): string {
	return REPORT_TYPES.find((r) => r.value === reportType)?.officerName ?? 'Officers';
}

export function reportOfficerJob(reportType: number): 'police' | 'ems' | 'government' | 'prison' {
	return REPORT_TYPES.find((r) => r.value === reportType)?.officerType ?? 'police';
}

export function reportTypeHasEvidence(reportType: number): boolean {
	return Boolean(REPORT_TYPES.find((r) => r.value === reportType)?.hasEvidence);
}

// ---- Static reference data (ported from old ui/src/data/*.js) ----
export const CHARGE_TYPES = [
	{ value: 1, label: 'Infraction' },
	{ value: 2, label: 'Misdemeanor' },
	{ value: 3, label: 'Felony' },
];

export const PLEA_TYPES = [
	{ value: 'guilty', label: 'Guilty' },
	{ value: 'not-guilty', label: 'Not Guilty' },
	{ value: 'no-contest', label: 'No Contest' },
	{ value: 'unknown', label: 'Unknown' },
];

export const REDUCTION_TYPES = [
	{ value: 'months', label: 'Jail Time' },
	{ value: 'fine', label: 'Fine' },
];

// jail sentences get this multiplied and added on top as parole (SentencePlayer's `parole.parole` field)
export const PAROLE_MULTIPLIER = 1.5;

export const EVIDENCE_TYPES = [
	{ value: 'photo', label: 'Photo', color: '#9542f5' },
	{ value: 'casing', label: 'Casing', color: '#969696' },
	{ value: 'projectile', label: 'Projectile', color: '#de4628' },
	{ value: 'weapon', label: 'Weapon', color: '#8f032b' },
	{ value: 'fragment', label: 'Fragment', color: '#038f11' },
	{ value: 'other', label: 'Other', color: '#1eadd9' },
];

export const VEHICLE_TYPES = ['Vehicle', 'Boat', 'Aircraft'];

export const PROPERTY_TYPES: Record<string, string> = {
	house: 'House',
	office: 'Office',
	warehouse: 'Warehouse',
};

export const VEHICLE_FLAG_TYPES = [
	{ value: 'stolen', label: 'Stolen Vehicle', severity: 'error' },
	{ value: 'suspended', label: 'Suspended Registration', severity: 'warning' },
	{ value: 'BOLO', label: 'BOLO', severity: 'error' },
	{ value: 'evasion', label: 'History of Evasion', severity: 'error' },
	{ value: 'oc', label: 'Suspected OC Involvement', severity: 'error' },
];

// ---- Pagination ----
export const REPORTS_PER_PAGE = 6;
export const PEOPLE_PER_PAGE = 4;
export const VEHICLES_PER_PAGE = 10;
export const FIREARMS_PER_PAGE = 10;
export const WARRANTS_PER_PAGE = 10;
export const PROPERTIES_PER_PAGE = 12;
export const PRISONERS_PER_PAGE = 10;

// license-suspension / criminal-record breakpoints, set server-side and arrive via JOB_LOGIN's `points` payload
export interface PointBreakpoints {
	reduction: number;
	license: number;
}
