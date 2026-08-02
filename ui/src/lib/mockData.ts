import type {
	User,
	GovJob,
	OfficerRef,
	PermissionMap,
	Person,
	PersonSearchResult,
	PersonViewResult,
	Vehicle,
	Firearm,
	Warrant,
	Property,
	Charge,
	Report,
	ReportListItem,
	Notice,
	LibraryDocument,
	Bolo,
	RosterEntry,
	RosterDetail,
	Prisoner,
	GovWorker,
	HomeData,
	PaginatedResult,
	DispatchUnit,
	DispatchUnits,
	DispatchAlert,
	RadioName,
	DispatchLogEntry,
} from './types';

export const MOCK_USER: User = {
	SID: 42,
	First: 'John',
	Last: 'Doe',
	Callsign: 101,
	Qualifications: ['fto'],
	MDTSystemAdmin: false,
	Phone: '555-0101',
};

export const MOCK_GOV_JOB: GovJob = {
	Id: 'police',
	Name: 'Police',
	Grade: { Id: 'officer', Name: 'Officer', Level: 10 },
	Workplace: { Id: 'lspd', Name: 'Los Santos Police Department' },
};

export const MOCK_PERMISSIONS: PermissionMap = {
	MDT_HIRE: true,
	MDT_FIRE: true,
	FLEET_MANAGEMENT: true,
	police_alerts: true,
};

// every permission flag referenced client-side, dev menu's "grant all" toggle uses this so every admin surface is reachable
export const MOCK_ALL_PERMISSIONS: PermissionMap = {
	FLEET_MANAGEMENT: true,
	PD_HIGH_COMMAND: true,
	DOJ_JUDGE: true,
	GOV_DA: true,
	GOV_MAYOR: true,
	GOV_CPUB: true,
	police_alerts: true,
	ems_alerts: true,
	tow_alerts: true,
	doc_alerts: true,
	SAFD_HIGH_COMMAND: true,
	DOC_HIGH_COMMAND: true,
	DETECTIVE: true,
	FTO: true,
	DOJ_OVERTURN_CHARGES: true,
};

export interface MockIdentityPreset {
	label: string;
	job: GovJob | null;
	attorney: boolean;
}

// dev-menu identity presets, one per portal/department combo, Workplace.Id drives resolvePortal() and deptKeyFor()
export const MOCK_JOB_PRESETS: Record<string, MockIdentityPreset> = {
	lspd: { label: 'Police - LSPD', job: { Id: 'police', Name: 'Police', Grade: { Id: 'officer', Name: 'Officer', Level: 10 }, Workplace: { Id: 'lspd', Name: 'Los Santos Police Department' } }, attorney: false },
	bcso: { label: 'Police - BCSO', job: { Id: 'police', Name: 'Police', Grade: { Id: 'deputy', Name: 'Deputy', Level: 10 }, Workplace: { Id: 'bcso', Name: 'Blaine County Sheriff\'s Office' } }, attorney: false },
	sast: { label: 'Police - SAST', job: { Id: 'police', Name: 'Police', Grade: { Id: 'trooper', Name: 'Trooper', Level: 10 }, Workplace: { Id: 'sast', Name: 'San Andreas State Troopers' } }, attorney: false },
	guardius: { label: 'Police - Guardius', job: { Id: 'police', Name: 'Police', Grade: { Id: 'officer', Name: 'Officer', Level: 10 }, Workplace: { Id: 'guardius', Name: 'Guardius' } }, attorney: false },
	doj: { label: 'Government - DOJ', job: { Id: 'government', Name: 'Government', Grade: { Id: 'judge', Name: 'Judge', Level: 10 }, Workplace: { Id: 'doj', Name: 'Department of Justice' } }, attorney: false },
	da: { label: 'Government - DA', job: { Id: 'government', Name: 'Government', Grade: { Id: 'da', Name: 'District Attorney', Level: 10 }, Workplace: { Id: 'dattorney', Name: 'District Attorney\'s Office' } }, attorney: false },
	publicdefenders: { label: 'Government - Public Defenders', job: { Id: 'government', Name: 'Government', Grade: { Id: 'pd', Name: 'Public Defender', Level: 10 }, Workplace: { Id: 'publicdefenders', Name: 'Public Defenders' } }, attorney: false },
	medical: { label: 'EMS - Medical', job: { Id: 'ems', Name: 'EMS', Grade: { Id: 'paramedic', Name: 'Paramedic', Level: 10 }, Workplace: { Id: 'safd', Name: 'San Andreas Fire Department' } }, attorney: false },
	doc: { label: 'Prison - DOC', job: { Id: 'prison', Name: 'Prison', Grade: { Id: 'officer', Name: 'Corrections Officer', Level: 10 }, Workplace: { Id: 'doc', Name: 'Department of Corrections' } }, attorney: false },
	attorney: { label: 'Attorney (no job)', job: null, attorney: true },
	public: { label: 'Public (no job)', job: null, attorney: false },
};

// ---- People catalog (SID-keyed) ----

const licensesClean = { Drivers: { Active: true, Points: 0 }, Weapons: { Active: true } };

export const MOCK_PEOPLE: PersonViewResult[] = [
	{
		data: {
			_id: 1,
			SID: 7,
			First: 'Jane',
			Last: 'Smith',
			Gender: 1,
			DOB: '1990-01-01',
			Callsign: false,
			Phone: '555-0107',
			Licenses: { Drivers: { Active: true, Points: 2 }, Weapons: { Active: true } },
			Qualifications: [],
			Flags: { Violent: false, Gang: '' },
			Jobs: [],
			Mugshot: '',
			MDTHistory: [{ Time: Date.now() - 86400000 * 3, Char: 42, Log: 'John Doe Updated Profile, Set Flags To {"Violent":false,"Gang":""}' }],
		},
		parole: null,
		convictions: [{ id: 3, count: 1 }],
		vehicles: [{ Type: 0, VIN: 'ABC12345', Make: 'Vapid', Model: 'Stanier', RegisteredPlate: '8ABC123' }],
		ownedBusinesses: [],
	},
	{
		data: {
			_id: 2,
			SID: 15,
			First: 'Mike',
			Last: 'Johnson',
			Gender: 0,
			DOB: '1988-06-14',
			Callsign: false,
			Phone: '555-0115',
			Licenses: { Drivers: { Active: false, Suspended: true, Points: 11 }, Weapons: { Active: false, Suspended: true } },
			Qualifications: [],
			Flags: { Violent: true, Gang: 'Vagos' },
			Jobs: [],
			MDTHistory: [],
		},
		parole: null,
		convictions: [
			{ id: 1, count: 1 },
			{ id: 7, count: 2 },
		],
		vehicles: [],
		ownedBusinesses: [],
	},
	{
		data: {
			_id: 3,
			SID: 22,
			First: 'Sarah',
			Last: 'Connor',
			Gender: 1,
			DOB: '1984-11-02',
			Callsign: false,
			Phone: '555-0122',
			Licenses: { Drivers: { Active: true, Points: 0 }, Weapons: { Active: true } },
			Qualifications: [],
			Flags: { Violent: false, Gang: '' },
			Jobs: [{ Id: 'government', Name: 'Government', Grade: { Id: 'judge', Name: 'Judge', Level: 50 }, Workplace: { Id: 'doj', Name: 'Department of Justice' } }],
			MDTHistory: [],
		},
		parole: null,
		convictions: [],
		vehicles: [],
		ownedBusinesses: [],
	},
	{
		data: {
			_id: 4,
			SID: 31,
			First: 'Tyrone',
			Last: 'Biggums',
			Gender: 0,
			DOB: '1979-03-22',
			Callsign: false,
			Phone: '555-0131',
			Licenses: { Drivers: { Active: false, Suspended: true, Points: 12 }, Weapons: { Active: false, Suspended: true } },
			Qualifications: [],
			Flags: { Violent: true, Gang: 'Ballas' },
			Jobs: [],
			MDTHistory: [{ Time: Date.now() - 86400000 * 10, Char: 42, Log: 'John Doe Updated Profile, Set Mugshot To (image url)' }],
		},
		parole: { end: Date.now() + 1000 * 60 * 60 * 24 * 5, total: 12, parole: 4 },
		convictions: [
			{ id: 4, count: 1 },
			{ id: 1, count: 1 },
		],
		vehicles: [{ Type: 0, VIN: 'IMP55521', Make: 'Declasse', Model: 'Blista', RegisteredPlate: '3IMP991' }],
		ownedBusinesses: [],
	},
];

export const MOCK_PERSON: Person = MOCK_PEOPLE[0].data;
export const MOCK_PERSON_VIEW: PersonViewResult = MOCK_PEOPLE[0];

export const MOCK_PEOPLE_SEARCH: PersonSearchResult[] = MOCK_PEOPLE.map((p) => ({
	SID: p.data.SID,
	First: p.data.First,
	Last: p.data.Last,
	DOB: p.data.DOB,
	Licenses: p.data.Licenses,
}));

export const MOCK_OFFICER_SEARCH: OfficerRef[] = [
	{ SID: 42, First: 'John', Last: 'Doe', Callsign: 101 },
	{ SID: 60, First: 'Emily', Last: 'Stone', Callsign: 205 },
	{ SID: 61, First: 'Marcus', Last: 'Reid', Callsign: 310 },
];

// ---- Vehicle catalog (VIN-keyed) ----

export const MOCK_VEHICLES_CATALOG: Vehicle[] = [
	{
		_id: 1,
		VIN: 'ABC12345',
		Type: 0,
		Make: 'Vapid',
		Model: 'Stanier',
		RegisteredPlate: '8ABC123',
		Owner: { Type: 0, Id: 7, Person: { First: 'Jane', Last: 'Smith', SID: 7 } },
		Storage: { Type: 1, Id: 'mission-row', Name: 'Mission Row Garage' },
		Flags: [],
		Strikes: [],
	},
	{
		_id: 2,
		VIN: 'STL99900',
		Type: 0,
		Make: 'Karin',
		Model: 'Sultan',
		RegisteredPlate: 'STL 990',
		Owner: { Type: 0, Id: 15, Person: { First: 'Mike', Last: 'Johnson', SID: 15 } },
		Flags: [{ Date: Date.now() - 3600000 * 6, Type: 'stolen', Description: 'Reported stolen from Vinewood Blvd', Author: { SID: 42, Callsign: '101', First: 'John', Last: 'Doe' } }],
		Strikes: [],
		RadarFlag: 'MDT Flag: Reported stolen from Vinewood Blvd',
	},
	{
		_id: 3,
		VIN: 'FLT00001',
		Type: 0,
		Make: 'Vapid',
		Model: 'Interceptor',
		RegisteredPlate: 'LSPD 001',
		Owner: { Type: 1, Id: 'police', Workplace: 'lspd', JobName: 'Los Santos Police Department' },
		Storage: { Type: 0, Id: 'impound', Name: 'Impound Lot' },
		GovAssigned: [{ SID: 42, First: 'John', Last: 'Doe', Callsign: 101 }],
		Flags: [],
		Strikes: [],
	},
	{
		_id: 4,
		VIN: 'IMP55521',
		Type: 0,
		Make: 'Declasse',
		Model: 'Blista',
		RegisteredPlate: '3IMP991',
		Owner: { Type: 0, Id: 31, Person: { First: 'Tyrone', Last: 'Biggums', SID: 31 } },
		Storage: { Type: 0, Id: 'impound', Name: 'Impound Lot' },
		Flags: [{ Date: Date.now() - 86400000 * 2, Type: 'evasion', Description: 'Fled a traffic stop on the 1-10', Author: { SID: 42, Callsign: '101', First: 'John', Last: 'Doe' } }],
		Strikes: [{ Date: Date.now() - 86400000 * 2, Description: 'Fled a lawful traffic stop', Author: { SID: 42, Callsign: '101', First: 'John', Last: 'Doe' } }],
	},
];

export const MOCK_VEHICLE: Vehicle = MOCK_VEHICLES_CATALOG[0];
export const MOCK_VEHICLES: PaginatedResult<Vehicle> = { data: MOCK_VEHICLES_CATALOG, pages: 1 };

// ---- Firearm catalog (serial-keyed) ----

export const MOCK_FIREARMS_CATALOG: Firearm[] = [
	{
		serial: 'SA-1234-1',
		model: 'WEAPON_PISTOL',
		owner_sid: 7,
		owner_name: 'Jane Smith',
		purchased: '2025-01-01 12:00:00',
		flags: [{ id: 1, title: 'Stolen', description: 'Reported stolen', date: '2025-06-01 08:00:00', author_sid: 42, author_first: 'John', author_last: 'Doe', author_callsign: '101' }],
	},
	{
		serial: 'SA-5678-2',
		model: 'WEAPON_CARBINERIFLE',
		owner_sid: 15,
		owner_name: 'Mike Johnson',
		purchased: '2024-11-14 09:30:00',
		flags: [],
	},
	{
		serial: 'SA-0001-9',
		model: 'WEAPON_COMBATPISTOL',
		owner_sid: undefined,
		owner_name: 'Unknown',
		purchased: '2023-05-02 17:00:00',
		flags: [{ id: 2, title: 'Flagged', description: 'Found at an active crime scene, no registered owner on file', date: '2025-07-20 21:15:00', author_sid: 60, author_first: 'Emily', author_last: 'Stone', author_callsign: '205' }],
	},
];

export const MOCK_FIREARM: Firearm = MOCK_FIREARMS_CATALOG[0];

// ---- Warrant catalog (id-keyed) ----

export const MOCK_WARRANTS_CATALOG: Warrant[] = [
	{
		id: 1,
		state: 'active',
		title: 'Warrant For Mike Johnson (15)',
		report: 1,
		suspect: 1,
		notes: 'Suspect fled the scene of an armed robbery on Vinewood Blvd. Considered armed and dangerous.',
		creatorSID: 42,
		creatorName: 'John Doe',
		creatorCallsign: '101',
		expires: new Date(Date.now() + 6 * 24 * 60 * 60 * 1000).toISOString(),
		issued: new Date(Date.now() - 1 * 24 * 60 * 60 * 1000).toISOString(),
		suspectData: { SID: 15, First: 'Mike', Last: 'Johnson', charges: [] },
	},
	{
		id: 2,
		state: 'served',
		title: 'Warrant For Tyrone Biggums (31)',
		report: 1,
		suspect: 2,
		notes: 'Served during a routine traffic stop.',
		creatorSID: 60,
		creatorName: 'Emily Stone',
		creatorCallsign: '205',
		expires: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000).toISOString(),
		issued: new Date(Date.now() - 10 * 24 * 60 * 60 * 1000).toISOString(),
		suspectData: { SID: 31, First: 'Tyrone', Last: 'Biggums', charges: [] },
	},
	{
		id: 3,
		state: 'expired',
		title: 'Warrant For Marcus Webb (50)',
		notes: 'No leads, warrant lapsed.',
		creatorSID: 42,
		creatorName: 'John Doe',
		creatorCallsign: '101',
		expires: new Date(Date.now() - 14 * 24 * 60 * 60 * 1000).toISOString(),
		issued: new Date(Date.now() - 21 * 24 * 60 * 60 * 1000).toISOString(),
	},
	{
		id: 4,
		state: 'void',
		title: 'Warrant For Danny Ocean (55)',
		notes: 'Voided - charges dropped by the DA.',
		creatorSID: 61,
		creatorName: 'Marcus Reid',
		creatorCallsign: '310',
		expires: new Date(Date.now() - 5 * 24 * 60 * 60 * 1000).toISOString(),
		issued: new Date(Date.now() - 12 * 24 * 60 * 60 * 1000).toISOString(),
	},
];

export const MOCK_WARRANT: Warrant = MOCK_WARRANTS_CATALOG[0];
export const MOCK_WARRANTS: PaginatedResult<Warrant> = { data: MOCK_WARRANTS_CATALOG, pages: 1 };

export const MOCK_PROPERTIES: Property[] = [
	{ _id: 1, label: 'Alta St Apartment', type: 'house', owner: { First: 'Jane', Last: 'Smith', SID: 7 } },
	{ _id: 2, label: 'Downtown Vinewood Office', type: 'office', owner: true },
	{ _id: 3, label: 'La Mesa Warehouse', type: 'warehouse', owner: false },
];

// ---- Charge catalog ----

export const MOCK_CHARGES: Charge[] = [
	{ id: 1, type: 3, title: 'Grand Theft Auto', description: 'Unlawful taking of a vehicle', fine: 5000, jail: 20, points: 0, active: true },
	{ id: 2, type: 2, title: 'Reckless Driving', description: 'Operating a vehicle with willful disregard for safety', fine: 750, jail: 0, points: 4, active: true },
	{ id: 3, type: 1, title: 'Jaywalking', description: 'Crossing outside of a designated crosswalk', fine: 75, jail: 0, points: 0, active: true },
	{ id: 4, type: 3, title: 'Assault with a Deadly Weapon', description: 'Use of a weapon to threaten or cause harm', fine: 7500, jail: 36, points: 0, active: true },
	{ id: 5, type: 2, title: 'Possession of a Controlled Substance', description: 'Unlawful possession of narcotics', fine: 1200, jail: 6, points: 0, active: true },
	{ id: 6, type: 1, title: 'Speeding', description: 'Exceeding the posted speed limit', fine: 150, jail: 0, points: 1, active: true },
	{ id: 7, type: 3, title: 'Evading Arrest', description: 'Fleeing from a lawful police stop', fine: 4000, jail: 18, points: 8, active: true },
	{ id: 8, type: 1, title: 'Public Intoxication', description: 'Being under the influence in a public place', fine: 200, jail: 0, points: 0, active: true },
];
export const MOCK_CHARGE: Charge = MOCK_CHARGES[0];

// ---- Report catalog (id-keyed) ----

export const MOCK_REPORTS_CATALOG: Report[] = [
	{
		id: 1,
		type: 0,
		title: 'Armed Robbery - Vinewood Blvd',
		notes: '<p>Responded to a 911 call reporting an armed robbery in progress at a convenience store on Vinewood Blvd. Two suspects fled the scene in a stolen Sultan (STL 990). One suspect apprehended at the scene, second suspect fled on foot and is still at large.</p>',
		allowAttorney: true,
		creatorSID: 42,
		creatorName: 'John Doe',
		creatorCallsign: '101',
		created: new Date(Date.now() - 86400000).toISOString(),
		suspects: [
			{ id: 1, SID: 15, First: 'Mike', Last: 'Johnson', charges: [{ id: 1, count: 1 }, { id: 7, count: 1 }], plea: 'not-guilty', sentenced: false, warrant: 1 },
			{
				id: 2,
				SID: 31,
				First: 'Tyrone',
				Last: 'Biggums',
				charges: [{ id: 4, count: 1 }, { id: 1, count: 1 }],
				plea: 'guilty',
				sentenced: true,
				sentencedAt: new Date(Date.now() - 43200000).toISOString(),
				points: 0,
				fine: 12500,
				jail: 56,
				parole: 28,
				reduction: { type: 'months', value: 10 },
				revoked: { drivers: true, weapons: true },
				doc: true,
			},
		],
		suspectsOverturned: [],
		primaries: [{ SID: 42, First: 'John', Last: 'Doe', Callsign: '101' }, { SID: 60, First: 'Emily', Last: 'Stone', Callsign: '205' }],
		people: [],
		evidence: [
			{ id: 1, report: 1, type: 'photo', label: 'Store security footage still', value: 'https://placehold.co/600x400?text=Evidence+Photo' },
			{ id: 2, report: 1, type: 'casing', label: '9mm casing recovered at scene', value: 'CASE-2210-A' },
		],
		paroleData: [{ SID: 31, end: new Date(Date.now() + 1000 * 60 * 60 * 24 * 5).toISOString(), total: 28, parole: 28, sentence: 56, fine: 12500 }],
	},
	{
		id: 2,
		type: 1,
		title: 'Ongoing Narcotics Investigation - La Mesa',
		notes: '<p>Investigating a suspected narcotics distribution operation out of a warehouse in La Mesa. Surveillance ongoing, no arrests yet.</p>',
		allowAttorney: true,
		creatorSID: 42,
		creatorName: 'John Doe',
		creatorCallsign: '101',
		created: new Date(Date.now() - 86400000 * 4).toISOString(),
		suspects: [],
		suspectsOverturned: [],
		primaries: [{ SID: 42, First: 'John', Last: 'Doe', Callsign: '101' }],
		people: [{ SID: 7, First: 'Jane', Last: 'Smith' }],
		evidence: [],
	},
	{
		id: 3,
		type: 2,
		title: 'Noise Complaint - Alta St',
		notes: '<p>Responded to a noise complaint. Advised resident to lower volume. No further action taken.</p>',
		allowAttorney: false,
		creatorSID: 61,
		creatorName: 'Marcus Reid',
		creatorCallsign: '310',
		created: new Date(Date.now() - 86400000 * 8).toISOString(),
		suspects: [],
		suspectsOverturned: [],
		primaries: [{ SID: 61, First: 'Marcus', Last: 'Reid', Callsign: '310' }],
		people: [{ SID: 22, First: 'Sarah', Last: 'Connor' }],
		evidence: [],
	},
];

export const MOCK_REPORT: Report = MOCK_REPORTS_CATALOG[0];

export const MOCK_REPORT_LIST: ReportListItem[] = MOCK_REPORTS_CATALOG.map((r) => ({
	id: r.id,
	type: r.type,
	title: r.title,
	created: r.created ?? new Date().toISOString(),
	creatorSID: r.creatorSID,
	creatorName: r.creatorName,
	creatorCallsign: r.creatorCallsign,
}));

export const MOCK_REPORTS: PaginatedResult<ReportListItem> = { data: MOCK_REPORT_LIST, pages: 1 };

export const MOCK_NOTICES: Notice[] = [
	{ id: 1, title: 'Welcome to the department', description: 'Be safe out there.', creator: 42, created: new Date(Date.now() - 86400000 * 2).toISOString(), restricted: 'public' },
	{ id: 2, title: 'Shift Change Reminder', description: 'Day shift now starts at 0600 sharp, effective this week.', creator: 60, created: new Date(Date.now() - 86400000 * 5).toISOString(), restricted: 'police' },
	{ id: 3, title: 'Equipment Inspection Due', description: 'All patrol vehicles due for inspection by end of month.', creator: 42, created: new Date(Date.now() - 86400000 * 9).toISOString(), restricted: 'government' },
];
export const MOCK_NOTICE: Notice = MOCK_NOTICES[0];

export const MOCK_LIBRARY_DOCS: LibraryDocument[] = [
	{ id: 1, label: 'Field Training Manual', link: 'https://example.com', job: 'police' },
	{ id: 2, label: 'Traffic Stop Procedures', link: 'https://example.com', job: 'police' },
	{ id: 3, label: 'Use of Force Policy', link: 'https://example.com', job: 'police' },
];

export const MOCK_BOLOS: Bolo[] = [
	{ id: 1, title: 'Stolen Sultan', type: 'vehicle', summary: 'STL 990, last seen on Vinewood Blvd', author: { SID: 42, First: 'John', Last: 'Doe', Callsign: '101' } },
	{ id: 2, title: 'Armed Suspect at Large', type: 'person', summary: 'Male, ~30s, fled on foot from Vinewood Blvd robbery', author: { SID: 60, First: 'Emily', Last: 'Stone', Callsign: '205' } },
	{ id: 3, title: 'Missing Person', type: 'person', summary: 'Last seen near Legion Square, please advise if spotted', author: { SID: 42, First: 'John', Last: 'Doe', Callsign: '101' } },
];

// ---- Roster catalog (SID-keyed) ----

export const MOCK_ROSTER_CATALOG: RosterDetail[] = [
	{
		First: 'John',
		Last: 'Doe',
		SID: 42,
		Callsign: 101,
		Jobs: [MOCK_GOV_JOB],
		Qualifications: ['fto'],
		Phone: '555-0101',
		LastClockOn: { police: Math.floor(Date.now() / 1000) - 3600 },
		TimeClockedOn: { police: [{ time: Math.floor(Date.now() / 1000) - 86400, minutes: 90 }, { time: Math.floor(Date.now() / 1000) - 86400 * 3, minutes: 240 }] },
	},
	{
		First: 'Emily',
		Last: 'Stone',
		SID: 60,
		Callsign: 205,
		Jobs: [{ Id: 'police', Name: 'Police', Grade: { Id: 'sergeant', Name: 'Sergeant', Level: 20 }, Workplace: { Id: 'lspd', Name: 'Los Santos Police Department' } }],
		Qualifications: ['fto', 'detective'],
		Phone: '555-0205',
		LastClockOn: { police: Math.floor(Date.now() / 1000) - 7200 },
		TimeClockedOn: { police: [{ time: Math.floor(Date.now() / 1000) - 86400 * 2, minutes: 300 }] },
	},
	{
		First: 'Marcus',
		Last: 'Reid',
		SID: 61,
		Callsign: 310,
		Jobs: [{ Id: 'police', Name: 'Police', Grade: { Id: 'cadet', Name: 'Cadet', Level: 1 }, Workplace: { Id: 'lspd', Name: 'Los Santos Police Department' } }],
		Qualifications: [],
		Phone: '555-0310',
		LastClockOn: { police: Math.floor(Date.now() / 1000) - 1800 },
		TimeClockedOn: { police: [{ time: Math.floor(Date.now() / 1000) - 43200, minutes: 120 }] },
	},
	{
		First: 'Alicia',
		Last: 'Vance',
		SID: 62,
		Callsign: 150,
		Jobs: [{ Id: 'police', Name: 'Police', Grade: { Id: 'chief', Name: 'Chief', Level: 90 }, Workplace: { Id: 'lspd', Name: 'Los Santos Police Department' } }],
		Qualifications: ['fto', 'detective', 'swat'],
		Phone: '555-0150',
		MDTSuspension: { police: { Actioned: { First: 'John', Last: 'Doe', SID: 42, Callsign: 101 }, Length: 3, Expires: Math.floor(Date.now() / 1000) + 86400 * 2 } },
		LastClockOn: { police: Math.floor(Date.now() / 1000) - 86400 * 4 },
		TimeClockedOn: { police: [] },
	},
];

export const MOCK_ROSTER: RosterEntry[] = MOCK_ROSTER_CATALOG.map((r) => ({ First: r.First, Last: r.Last, SID: r.SID, Callsign: r.Callsign, Jobs: r.Jobs }));
export const MOCK_ROSTER_DETAIL: RosterDetail = MOCK_ROSTER_CATALOG[0];

export const MOCK_PRISONERS: Prisoner[] = [
	{ SID: 9, First: 'Bad', Last: 'Guy', Jailed: { Time: Math.floor(Date.now() / 1000) - 900, Release: Math.floor(Date.now() / 1000) + 1800, Duration: 45, Released: false } },
	{ SID: 70, First: 'Danny', Last: 'Trejo Jr', Jailed: { Time: Math.floor(Date.now() / 1000) - 5400, Release: Math.floor(Date.now() / 1000) + 120, Duration: 92, Reduced: 20, Released: false } },
	{ SID: 71, First: 'Big', Last: 'Mike', Jailed: { Time: Math.floor(Date.now() / 1000) - 60, Release: Math.floor(Date.now() / 1000) + 7140, Duration: 120, Released: false } },
];

// dataState.qualifications/permissions catalogs (config/server.lua's Qualifications/Permissions), used by Roster's quals editor and PermissionManager's checklist
export const MOCK_QUALIFICATIONS: Record<string, { name: string; restrict?: { job?: string; workplace?: string; weapon?: boolean } }> = {
	fto: { name: 'Field Training Officer' },
	detective: { name: 'Detective', restrict: { job: 'police' } },
	swat: { name: 'SWAT', restrict: { job: 'police', workplace: 'lspd' } },
};

export const MOCK_PERMISSIONS_CATALOG: Record<string, { name: string; restrict?: { job?: string; workplace?: string; weapon?: boolean } }> = {
	MDT_HIRE: { name: 'Hire Employees', restrict: { job: 'police' } },
	MDT_FIRE: { name: 'Fire Employees', restrict: { job: 'police' } },
	MDT_PROMOTE: { name: 'Promote Employees', restrict: { job: 'police' } },
	FLEET_MANAGEMENT: { name: 'Fleet Management', restrict: { job: 'police' } },
	DETECTIVE: { name: 'Detective Access', restrict: { job: 'police' } },
};

// dataState.governmentJobsData, keyed by job Id, each carrying its Workplaces/Grades/Permissions tree
export const MOCK_GOVERNMENT_JOBS_DATA: Record<string, { Name: string; Workplaces: { Id: string; Name: string; Grades: { Id: string; Name: string; Level: number; Permissions: Record<string, boolean> }[] }[] }> = {
	police: {
		Name: 'Police',
		Workplaces: [
			{
				Id: 'lspd',
				Name: 'Los Santos Police Department',
				Grades: [
					{ Id: 'cadet', Name: 'Cadet', Level: 1, Permissions: {} },
					{ Id: 'officer', Name: 'Officer', Level: 10, Permissions: { DETECTIVE: true } },
					{ Id: 'sergeant', Name: 'Sergeant', Level: 20, Permissions: { DETECTIVE: true, MDT_PROMOTE: true } },
					{ Id: 'chief', Name: 'Chief', Level: 90, Permissions: { MDT_HIRE: true, MDT_FIRE: true, MDT_PROMOTE: true, FLEET_MANAGEMENT: true, PD_HIGH_COMMAND: true } },
				],
			},
			{ Id: 'bcso', Name: "Blaine County Sheriff's Office", Grades: [{ Id: 'deputy', Name: 'Deputy', Level: 10, Permissions: {} }] },
		],
	},
	government: {
		Name: 'Government',
		Workplaces: [{ Id: 'doj', Name: 'Department of Justice', Grades: [{ Id: 'judge', Name: 'Judge', Level: 50, Permissions: { DOJ_JUDGE: true } }] }],
	},
	ems: {
		Name: 'EMS',
		Workplaces: [
			{
				Id: 'safd',
				Name: 'San Andreas Fire Department',
				Grades: [
					{ Id: 'cadet', Name: 'Cadet', Level: 1, Permissions: {} },
					{ Id: 'paramedic', Name: 'Paramedic', Level: 10, Permissions: {} },
					{ Id: 'chief', Name: 'Chief', Level: 90, Permissions: { SAFD_HIGH_COMMAND: true } },
				],
			},
		],
	},
	prison: {
		Name: 'Prison',
		Workplaces: [
			{
				Id: 'doc',
				Name: 'Department of Corrections',
				Grades: [
					{ Id: 'officer', Name: 'Corrections Officer', Level: 10, Permissions: {} },
					{ Id: 'warden', Name: 'Warden', Level: 90, Permissions: { DOC_HIGH_COMMAND: true } },
				],
			},
		],
	},
};

export const MOCK_GOV_WORKERS: GovWorker[] = [
	{ First: 'Jane', Last: 'Judge', SID: 3, Job: 'Judge', Workplace: 'Superior Court', Grade: 'Judge' },
	{ First: 'Robert', Last: 'Vance', SID: 22, Job: 'District Attorney', Workplace: "District Attorney's Office", Grade: 'DA' },
	{ First: 'Linda', Last: 'Cho', SID: 80, Job: 'Public Defender', Workplace: 'Public Defenders', Grade: 'PD' },
];

export const MOCK_HOME_DATA: HomeData = {
	warrants: MOCK_WARRANTS_CATALOG.filter((w) => w.state === 'active'),
	notices: MOCK_NOTICES,
	govWorkers: MOCK_GOV_WORKERS,
};

// ---- Dispatch/Alerts fixtures, fed through the same handleAlertsMessage() path the real Lua broadcasts use ----

export const MOCK_MY_UNIT: DispatchUnit = {
	source: 1,
	job: 'police',
	primary: 101,
	available: true,
	type: 'car',
	character: { First: 'John', Last: 'Doe', SID: 42, Phone: '555-0101' },
	operatingUnder: null,
	pursuitMode: null,
	radioChannel: null,
};

export const MOCK_DISPATCH_UNITS: DispatchUnits = {
	police: [
		MOCK_MY_UNIT,
		{ source: 2, job: 'police', primary: 205, available: true, type: 'car', character: { First: 'Emily', Last: 'Stone', SID: 60, Phone: '555-0205' }, operatingUnder: null, pursuitMode: null, radioChannel: '3' },
		{ source: 3, job: 'police', primary: 310, available: false, type: 'motorcycle', character: { First: 'Marcus', Last: 'Reid', SID: 61, Phone: '555-0310' }, operatingUnder: 205, pursuitMode: null, radioChannel: null },
	],
	ems: [
		{ source: 4, job: 'ems', primary: 1, available: true, type: 'bus', character: { First: 'Sarah', Last: 'Kim', SID: 90, Phone: '555-0900' }, operatingUnder: null, pursuitMode: null, radioChannel: '1' },
	],
	prison: [
		{ source: 5, job: 'prison', primary: 12, available: true, type: 'car', character: { First: 'Diego', Last: 'Alvarez', SID: 95, Phone: '555-0950' }, operatingUnder: null, pursuitMode: null, radioChannel: '2' },
	],
	tow: [],
};

export const MOCK_DISPATCH_ALERTS: DispatchAlert[] = [
	{
		id: 'dispatch-mock-1',
		code: '10-99',
		title: 'Shots Fired',
		type: 'police_alerts',
		location: { street1: 'Vinewood Blvd', street2: 'Innocence Blvd', area: 'Downtown Vinewood', x: 215.4, y: -805.2, z: 30.7 },
		description: { icon: 'question', details: 'Multiple gunshots reported' },
		panic: false,
		blip: { icon: 110, size: 0.9, color: 30, duration: 180 },
		style: 1,
		isArea: false,
		camera: false,
		attached: ['101'],
		time: Date.now() - 60000,
	},
	{
		id: 'dispatch-mock-2',
		code: '10-50',
		title: 'Vehicle Accident',
		type: ['police_alerts', 'ems_alerts'],
		location: { street1: 'Route 68', street2: null, area: 'Grapeseed', x: 1704.2, y: 4924.9, z: 42.1 },
		description: { icon: 'car-side', details: 'Two-vehicle collision, injuries reported' },
		panic: false,
		blip: { icon: 620, size: 0.9, color: 30, duration: 180 },
		style: 2,
		isArea: false,
		camera: false,
		attached: [],
		time: Date.now() - 300000,
	},
];

export const MOCK_RADIO_NAMES: RadioName[] = [
	{ radio: '1', text: 'EMS' },
	{ radio: '2', text: 'DOC' },
	{ radio: '3', text: 'PD #1' },
];

export const MOCK_DISPATCH_LOG: DispatchLogEntry[] = [
	{ time: Date.now() - 900000, type: 'dutyChange', title: null, message: '[101] J. Doe is 10-41 (On Duty)', color: undefined },
	{ time: Date.now() - 600000, type: 'dutyChange', title: null, message: '[205] E. Stone is 10-41 (On Duty)', color: undefined },
	{ time: Date.now() - 300000, type: 'availabilityChange', title: null, message: '310 is now 10-6 (Unavailable)', color: undefined },
	{ time: Date.now() - 120000, type: 'message', title: 'PD Message | [101] J. Doe', message: 'Setting up a checkpoint on Route 68.', color: undefined },
];
