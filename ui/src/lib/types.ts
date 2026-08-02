export interface ActionResult {
	success: boolean;
	message?: string;
}

export interface GradeRef {
	Id: string;
	Name: string;
	Level?: number;
}

export interface WorkplaceRef {
	Id: string;
	Name: string;
}

export interface GovJob {
	Id: string;
	Name: string;
	Grade: GradeRef;
	Workplace?: WorkplaceRef;
	Hidden?: boolean;
}

export interface User {
	SID: number;
	First: string;
	Last: string;
	Callsign?: number | string | false;
	Qualifications?: string[];
	MDTSystemAdmin?: boolean;
	Phone?: string;
	DOB?: string;
	Mugshot?: string;
}

export type PermissionMap = Record<string, boolean>;

export interface LicenseEntry {
	Active: boolean;
	Suspended?: boolean;
	Points?: number;
}

export interface Licenses {
	Drivers?: LicenseEntry;
	Weapons?: LicenseEntry;
	Hunting?: LicenseEntry;
	Fishing?: LicenseEntry;
}

export interface GovFlags {
	Violent?: boolean;
	Gang?: string;
}

// employment.lua's Suspend/Unsuspend store one entry per job Id, not a single suspension record
export interface MDTSuspensionEntry {
	Actioned: { First: string; Last: string; SID: number; Callsign?: number | string | false };
	Length: number;
	Expires: number;
}

// pulsar_jobs' duty component, keyed by job Id, LastClockOn is a unix-seconds timestamp, TimeClockedOn is a rolling 14-day session log
export interface DutySession {
	time: number;
	minutes: number;
}

export interface Person {
	_id?: number;
	SID: number;
	User?: string;
	First: string;
	Last: string;
	Gender?: number;
	Origin?: string;
	Jobs?: GovJob[];
	DOB?: string;
	Callsign?: number | string | false;
	Phone?: string;
	Licenses?: Licenses;
	Qualifications?: string[];
	Flags?: GovFlags;
	Mugshot?: string;
	MDTSystemAdmin?: boolean;
	MDTHistory?: { Time: number; Char: number | -1; Log: string }[];
	MDTSuspension?: Record<string, MDTSuspensionEntry> | null;
	Attorney?: boolean;
	LastClockOn?: Record<string, number>;
	TimeClockedOn?: Record<string, DutySession[]>;
}

export interface OwnedVehicleRef {
	Type: number;
	VIN: string;
	Make: string;
	Model: string;
	RegisteredPlate: string;
}

// MDT:View:person's full response, wraps the raw character doc with derived cross-table data, not the same shape as Person alone
export interface PersonViewResult {
	data: Person;
	parole: { end: number; total: number; parole: number } | null;
	convictions: SuspectCharge[];
	vehicles: OwnedVehicleRef[];
	ownedBusinesses: string[];
}

export interface PersonSearchResult {
	SID: number;
	First: string;
	Last: string;
	DOB?: string;
	Licenses?: Licenses;
}

export interface OfficerRef {
	SID: number;
	First: string;
	Last: string;
	Callsign?: number | string | false;
}

export interface VehicleOwner {
	Type: number;
	Id: string | number;
	Workplace?: string;
	Person?: { First: string; Last: string; SID: number } | null;
	JobName?: string;
}

export interface VehicleStorage {
	Type: number;
	Id: string | number;
	Name?: string;
}

export interface VehicleFlag {
	Date: number;
	Type: string;
	Description: string;
	Author?: { SID: number; Callsign?: string; First: string; Last: string };
}

export interface Vehicle {
	_id?: number;
	VIN: string;
	Type?: number;
	Make: string;
	Model: string;
	Class?: string;
	ModelType?: string;
	RegisteredPlate: string;
	FakePlate?: string;
	Fuel?: number;
	Mileage?: number;
	Value?: number;
	FirstSpawn?: number;
	Owner?: VehicleOwner;
	Storage?: VehicleStorage;
	Flags?: VehicleFlag[];
	Strikes?: VehicleStrike[];
	GovAssigned?: OfficerRef[];
	RadarFlag?: string;
}

export interface VehicleStrike {
	Date: number;
	Description: string;
	Author?: { SID: number; Callsign?: string; First: string; Last: string };
}

export interface Firearm {
	serial: string;
	model: string;
	item?: string;
	owner_sid?: number;
	owner_name?: string;
	purchased?: string;
	flags?: FirearmFlag[];
}

export interface FirearmFlag {
	id: number;
	title: string;
	description: string;
	date: string;
	author_sid: number;
	author_first: string;
	author_last: string;
	author_callsign?: string;
}

export interface Warrant {
	id: number;
	state: 'active' | 'served' | 'expired' | 'void';
	title: string;
	report?: number;
	suspect?: number;
	notes?: string;
	creatorSID: number;
	creatorName: string;
	creatorCallsign?: string;
	expires: string;
	issued?: string;
	suspectData?: { SID: number; First: string; Last: string; charges: unknown };
}

// pulsar_properties' raw client-cached record, `owner` is a plain ownership flag there, not a person record
export interface Property {
	_id?: number;
	label: string;
	type: string;
	owner?: boolean | { First: string; Last: string; SID: number };
	coords?: { x: number; y: number; z: number };
}

export interface Charge {
	id: number;
	type: number;
	title: string;
	description: string;
	fine: number;
	jail: number;
	points: number;
	active?: boolean;
}

export interface SuspectCharge {
	id: number;
	count: number;
}

export interface RevokedLicenses {
	drivers?: boolean;
	weapons?: boolean;
	hunting?: boolean;
	fishing?: boolean;
}

export interface ReportSuspect {
	id?: number;
	SID: number;
	First: string;
	Last: string;
	charges: SuspectCharge[];
	Licenses?: Licenses;
	plea?: string;
	sentenced?: boolean;
	sentencedAt?: string;
	points?: number;
	fine?: number;
	jail?: number;
	parole?: number;
	reduction?: { type: 'months' | 'fine' | false; value: number } | null;
	revoked?: RevokedLicenses | null;
	doc?: boolean;
	expunged?: boolean;
	warrant?: number;
}

export interface ReportPerson {
	SID: number;
	First: string;
	Last: string;
	Callsign?: string;
}

export interface Evidence {
	id: number;
	report: number;
	type: string;
	label: string;
	value: string;
}

export interface Report {
	id: number;
	type: number;
	title: string;
	notes: string;
	allowAttorney: boolean;
	creatorSID: number;
	creatorName: string;
	creatorCallsign?: string;
	created?: string;
	suspects: ReportSuspect[];
	suspectsOverturned: ReportSuspect[];
	primaries: ReportPerson[];
	people: ReportPerson[];
	evidence: Evidence[];
	paroleData?: { SID: number; end: string; total: number; parole: number; sentence: number; fine: number }[];
}

// search row shape, only the columns Reports.lua's Search() selects, not the full report
export interface ReportListItem {
	id: number;
	type: number;
	title: string;
	created: string;
	creatorSID: number;
	creatorName: string;
	creatorCallsign?: string;
}

// MDT:Create:report's doc payload, author is attributed server-side, suspects only apply to type 0 (Incident Report)
export interface CreateReportDoc {
	type: number;
	title: string;
	notes: string;
	allowAttorney: boolean;
	primaries: ReportPerson[];
	people: ReportPerson[];
	suspects: { SID: number; First: string; Last: string; charges: SuspectCharge[]; plea: string; Licenses?: Licenses }[];
	evidence: { type: string; label: string; value: string }[];
}

// MDT:Update:report's diff-list pattern, each entry is one pending mutation, not a full-array replace
export type UpdateReportChange =
	| { type: 'evidence'; mode: 'add'; data: { type: string; label: string; value: string } }
	| { type: 'evidence'; mode: 'delete'; data: { id: number } }
	| { type: 'suspect'; mode: 'add'; data: { SID: number; First: string; Last: string; charges: SuspectCharge[]; plea: string } }
	| { type: 'suspect'; mode: 'update'; data: { SID: number; charges: SuspectCharge[]; plea: string } }
	| { type: 'suspect'; mode: 'delete'; data: { SID: number } }
	| { type: 'primary' | 'person'; mode: 'add'; data: ReportPerson }
	| { type: 'primary' | 'person'; mode: 'delete'; data: { SID: number } };

export interface UpdateReportDoc {
	title: string;
	notes: string;
	allowAttorney: boolean;
	changes: UpdateReportChange[];
}

// MDT:SentencePlayer's payload, report.lua stores sentence.{type,value} into the suspect's `reduction` column
export interface SentencePayload {
	report: number;
	data: ReportSuspect;
	jail: number;
	fine: number;
	points: number;
	parole: { end: number; total: number; parole: number; sentence: number; fine: number } | null;
	sentence: {
		type: 'months' | 'fine' | false;
		value: number;
		revoke: RevokedLicenses;
		doc: boolean;
	};
}

export interface Notice {
	id: number;
	title: string;
	description?: string;
	creator?: number;
	created?: string;
	restricted?: string;
}

export interface LibraryDocument {
	id: number;
	label: string;
	link: string;
	job?: string;
	workplace?: string;
}

export interface Bolo {
	id: number;
	title: string;
	type: string;
	summary?: string;
	description?: string;
	author?: { SID: number; First: string; Last: string; Callsign?: string };
}

export interface RosterEntry {
	Mugshot?: string;
	First: string;
	Last: string;
	SID: number;
	Callsign?: number | string | false;
	Jobs: GovJob[];
}

export interface RosterDetail extends RosterEntry {
	MDTSuspension?: Record<string, MDTSuspensionEntry> | null;
	MDTSystemAdmin?: boolean;
	Qualifications?: string[];
	Phone?: string;
	TimeClockedOn?: Record<string, DutySession[]>;
	LastClockOn?: Record<string, number>;
}

export interface FleetVehicle extends Vehicle {
	GovAssignedNames?: string[];
}

// pulsar_jail's Duration/Reduced are in minutes not days, Time/Release are unix seconds, GetPrisoners() has no Mugshot field
export interface Prisoner {
	SID: number;
	First: string;
	Last: string;
	Jailed: {
		Time: number;
		Release: number;
		Duration: number;
		Released?: boolean;
		Reduced?: number;
	};
}

export interface GovWorker {
	First: string;
	Last: string;
	SID: number;
	Phone?: string;
	Job: string;
	Workplace: string;
	Grade: string;
}

export interface HomeData {
	warrants: Warrant[];
	notices: Notice[];
	govWorkers: GovWorker[];
}

export interface PaginatedResult<T> {
	data: T[];
	pages: number | null;
}

// ---- Alerts/Dispatch (separate transport, socket.io-client over pulsar_ws/namespaces/mdtAlerts.js, url+token arrive via ALERTS_WS_CONNECT not nui.ts's fetch bridge) ----

export interface AlertBlip {
	icon: number;
	size: number;
	color: number;
	duration: number;
	flashing?: boolean;
}

export interface AlertLocation {
	street1?: string;
	street2?: string | null;
	area?: string;
	x: number;
	y: number;
	z: number;
}

export interface AlertVehicleColor {
	r: number;
	g: number;
	b: number;
}

export interface AlertDescription {
	icon?: string;
	details?: string;
	vehicleColor?: AlertVehicleColor;
	vehiclePlate?: string;
	vehicleClass?: string;
}

// style: 1=police(911/311/clipboard), 2=EMS(truck-medical), 3=misc(truck-ramp-box) - mdtAlerts.js's alertGroupStyles
export interface DispatchAlert {
	id: string;
	code: string;
	title: string;
	type: string | string[];
	location: AlertLocation | false;
	description: AlertDescription | string | false;
	panic: boolean;
	blip: AlertBlip | false;
	style: number | null;
	isArea?: boolean;
	camera?: unknown;
	attached: string[];
	time: number;
	client?: boolean;
	onScreen?: boolean;
}

export interface DispatchCharacterRef {
	First: string;
	Last: string;
	SID: number;
	Phone?: string;
}

export interface DispatchUnit {
	source: number;
	job: string;
	primary: string | number;
	available: boolean;
	type: string;
	character: DispatchCharacterRef | null;
	operatingUnder: string | number | null;
	pursuitMode: string | null;
	radioChannel: string | null;
}

// keyed by job Id (police/ems/prison/tow) - mirrors mdtAlerts.js's in-memory `units` object exactly
export type DispatchUnits = Record<string, DispatchUnit[]>;

export interface RadioName {
	radio: string;
	text: string;
}

export interface DispatchLogEntry {
	time: number;
	type: string;
	title: string | null;
	message: string;
	color?: string | null;
}
