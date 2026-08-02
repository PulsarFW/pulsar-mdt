import type {
	ActionResult,
	Charge,
	CreateReportDoc,
	DispatchAlert,
	Firearm,
	FirearmFlag,
	FleetVehicle,
	HomeData,
	LibraryDocument,
	Notice,
	OfficerRef,
	PaginatedResult,
	PersonSearchResult,
	PersonViewResult,
	Person,
	Prisoner,
	Property,
	Report,
	ReportListItem,
	ReportSuspect,
	RosterDetail,
	RosterEntry,
	SentencePayload,
	UpdateReportDoc,
	Vehicle,
	Warrant,
} from './types';
import {
	MOCK_FIREARM,
	MOCK_FIREARMS_CATALOG,
	MOCK_HOME_DATA,
	MOCK_LIBRARY_DOCS,
	MOCK_NOTICE,
	MOCK_NOTICES,
	MOCK_OFFICER_SEARCH,
	MOCK_PEOPLE,
	MOCK_PEOPLE_SEARCH,
	MOCK_PERSON_VIEW,
	MOCK_PRISONERS,
	MOCK_PROPERTIES,
	MOCK_REPORT,
	MOCK_REPORTS,
	MOCK_REPORTS_CATALOG,
	MOCK_ROSTER,
	MOCK_ROSTER_CATALOG,
	MOCK_ROSTER_DETAIL,
	MOCK_VEHICLE,
	MOCK_VEHICLES,
	MOCK_VEHICLES_CATALOG,
	MOCK_WARRANT,
	MOCK_WARRANTS,
	MOCK_WARRANTS_CATALOG,
} from './mockData';

const RESOURCE_NAME = 'pulsar_mdt';

async function send(event: string, data: unknown = {}): Promise<void> {
	if (import.meta.env.DEV) {
		window.dispatchEvent(new CustomEvent('nui:send', { detail: { event, data } }));
		return;
	}
	try {
		await fetch(`https://${RESOURCE_NAME}/${event}`, {
			method: 'post',
			headers: { 'Content-Type': 'application/json; charset=UTF-8' },
			body: JSON.stringify(data),
		});
	} catch {
		// Expected to fail outside the actual NUI browser
	}
}

async function sendJson<T>(event: string, data: unknown, devValue: T): Promise<T> {
	if (import.meta.env.DEV) {
		window.dispatchEvent(new CustomEvent('nui:send', { detail: { event, data } }));
		return devValue;
	}
	try {
		const res = await fetch(`https://${RESOURCE_NAME}/${event}`, {
			method: 'post',
			headers: { 'Content-Type': 'application/json; charset=UTF-8' },
			body: JSON.stringify(data),
		});
		return (await res.json()) as T;
	} catch {
		return devValue;
	}
}

const OK: ActionResult = { success: true };

export const Nui = {
	// ---- App lifecycle ----
	close: () => send('Close'),
	inputSearchPeople: (term: string) => sendJson<PersonSearchResult[]>('InputSearch', { type: 'people', term }, MOCK_PEOPLE_SEARCH),
	inputSearchJob: (job: string, term: string) => sendJson<OfficerRef[]>('InputSearch', { type: 'job', job, term }, MOCK_OFFICER_SEARCH),
	inputSearchSID: (term: string) => sendJson<PersonSearchResult[]>('InputSearchSID', { term }, MOCK_PEOPLE_SEARCH),

	// ---- People search/view ----
	// search callback is "MDT:Search:people" but view/update are singular "MDT:View:person"/"MDT:Update:person", type must match exactly
	// people search is a flat server-capped (LIMIT 12) array, no server pagination, callers paginate client-side
	searchPeople: (term: string) => sendJson<PersonSearchResult[]>('Search', { type: 'people', term }, MOCK_PEOPLE_SEARCH),
	viewPerson: (sid: number) => sendJson<PersonViewResult | false>('View', { type: 'person', id: sid }, MOCK_PEOPLE.find((p) => p.data.SID === sid) ?? MOCK_PERSON_VIEW),
	updatePerson: (sid: number, key: string, value: unknown) => sendJson<boolean>('Update', { type: 'person', SID: sid, Key: key, Data: value }, true),
	revokeSuspension: (sid: number, unsuspend: Record<string, boolean>) =>
		sendJson<Person['Licenses'] | false>('RevokeSuspension', { SID: sid, unsuspend }, MOCK_PERSON_VIEW.data.Licenses ?? false),
	clearRecord: (sid: number) => sendJson<boolean>('ClearRecord', { SID: sid }, true),
	removePoints: (sid: number, newPoints: number) =>
		sendJson<Person['Licenses'] | false>('RemovePoints', { SID: sid, newPoints }, MOCK_PERSON_VIEW.data.Licenses ?? false),

	// ---- Vehicles ----
	searchVehicles: (term: string, page: number, perPage: number) => sendJson<PaginatedResult<Vehicle>>('Search', { type: 'vehicle', term, page, perPage }, MOCK_VEHICLES),
	viewVehicle: (vin: string) => sendJson<Vehicle | false>('View', { type: 'vehicle', id: vin }, MOCK_VEHICLES_CATALOG.find((v) => v.VIN === vin) ?? MOCK_VEHICLE),
	addVehicleFlag: (parent: string, doc: unknown, plate?: string) =>
		sendJson<boolean>('Create', { type: 'vehicle-flag', parent, doc, plate }, true),
	// id is the flag's Type string (e.g. "stolen"), not a numeric id, vehicles.lua's Flags.Remove matches on `f.Type`
	removeVehicleFlag: (parent: string, id: string, plate?: string, removeRadarFlag?: boolean) =>
		sendJson<boolean>('Delete', { type: 'vehicle-flag', parent, id, plate, removeRadarFlag }, true),
	updateVehicleStrikes: (vin: string, strikes: unknown[]) => sendJson<boolean>('Update', { type: 'vehicle-strikes', VIN: vin, strikes }, true),
	setAssignedDrivers: (vehicle: string, assigned: OfficerRef[]) => sendJson<boolean>('SetAssignedDrivers', { vehicle, assigned }, true),
	trackFleetVehicle: (vehicle: string) => sendJson<boolean>('TrackFleetVehicle', { vehicle }, true),

	// ---- Firearms ----
	searchFirearms: (term: string) => sendJson<Firearm[]>('Search', { type: 'firearm', term }, MOCK_FIREARMS_CATALOG),
	viewFirearm: (serial: string) => sendJson<Firearm | false>('View', { type: 'firearm', id: serial }, MOCK_FIREARMS_CATALOG.find((f) => f.serial === serial) ?? MOCK_FIREARM),
	// firearm.lua's Flags.Add returns the single created flag, not an array
	addFirearmFlag: (parentId: string, doc: unknown) => sendJson<FirearmFlag | false>('Create', { type: 'firearm-flag', parentId, doc }, MOCK_FIREARM.flags?.[0] ?? false),
	removeFirearmFlag: (parentId: string, id: number) => sendJson<boolean>('Delete', { type: 'firearm-flag', parentId, id }, true),

	// ---- Warrants ----
	searchWarrants: (term: string, page: number, perPage: number) => sendJson<PaginatedResult<Warrant>>('Search', { type: 'warrant', term, page, perPage }, MOCK_WARRANTS),
	viewWarrant: (id: number) => sendJson<Warrant | false>('View', { type: 'warrant', id }, MOCK_WARRANTS_CATALOG.find((w) => w.id === id) ?? MOCK_WARRANT),
	issueWarrant: (report: number, suspect: ReportSuspect, notes: string) => sendJson<boolean>('IssueWarrant', { report, suspect, notes }, true),
	updateWarrant: (id: number, state: Warrant['state']) => sendJson<boolean>('Update', { type: 'warrant', id, state }, true),

	// ---- Properties ----
	getProperties: () => sendJson<Property[]>('GetProperties', {}, MOCK_PROPERTIES),
	findProperty: (id: number) => sendJson<boolean>('FindProperty', id, true),

	// ---- Fleet ----
	// fleet.lua derives the job from the caller's own on-duty session, never a client-supplied job
	viewVehicleFleet: () => sendJson<FleetVehicle[] | false>('ViewVehicleFleet', {}, [MOCK_VEHICLE]),

	// ---- Reports ----
	// reports.lua's Search() always requires reportType and only returns list columns, View returns the full shape
	searchReports: (term: string, reportType: number, page: number, perPage: number, isAttorney: boolean, evidence: boolean) =>
		sendJson<PaginatedResult<ReportListItem>>('Search', { type: 'report', term, reportType, page, perPage, isAttorney, evidence }, MOCK_REPORTS),
	viewReport: (id: number) => sendJson<Report | false>('View', { type: 'report', id }, MOCK_REPORTS_CATALOG.find((r) => r.id === id) ?? MOCK_REPORT),
	createReport: (doc: CreateReportDoc) => sendJson<number | false>('Create', { type: 'report', doc }, 1),
	updateReport: (id: number, report: UpdateReportDoc) => sendJson<boolean>('Update', { type: 'report', id, report }, true),
	deleteReport: (id: number) => sendJson<boolean>('Delete', { type: 'report', id }, true),
	sentencePlayer: (payload: SentencePayload) => sendJson<boolean>('SentencePlayer', payload, true),
	overturnSentence: (report: number, sid: number) => sendJson<boolean>('OverturnSentence', { report, SID: sid }, true),
	// raw report id, not wrapped, client/nui.lua's EvidenceLocker cb(true)s immediately so this always resolves true
	openEvidenceLocker: (caseNum: number) => sendJson<boolean>('EvidenceLocker', caseNum, true),

	// ---- Roster / employment ----
	rosterView: (job: string) => sendJson<RosterEntry[]>('RosterView', { job }, MOCK_ROSTER),
	rosterSelect: (person: number, job: string) => sendJson<RosterDetail | false>('RosterSelect', { person, job }, MOCK_ROSTER_CATALOG.find((r) => r.SID === person) ?? MOCK_ROSTER_DETAIL),
	hireEmployee: (sid: number, jobId: string, workplaceId: string, gradeId: string) =>
		sendJson<boolean>('HireEmployee', { SID: sid, JobId: jobId, WorkplaceId: workplaceId, GradeId: gradeId }, true),
	fireEmployee: (sid: number, jobId: string) => sendJson<boolean>('FireEmployee', { SID: sid, JobId: jobId }, true),
	manageEmployment: (sid: number, jobId: string, newJob: { Id: string; Workplace: { Id: string }; Grade: { Id: string } }) =>
		sendJson<boolean>('ManageEmployment', { SID: sid, JobId: jobId, data: newJob }, true),
	// employment.lua's Suspend expects a whole-number day count (1-98), not a reason string
	suspendEmployee: (sid: number, jobId: string, lengthDays: number) => sendJson<boolean>('SuspendEmployee', { SID: sid, JobId: jobId, Length: lengthDays }, true),
	unsuspendEmployee: (sid: number, jobId: string) => sendJson<boolean>('UnsuspendEmployee', { SID: sid, JobId: jobId }, true),
	checkCallsign: (callsign: string) => sendJson<boolean>('CheckCallsign', callsign, true),
	// replaces the WHOLE Permissions map for that grade - omitted keys are implicitly revoked, not left alone
	updateJobPermissions: (jobId: string, workplaceId: string, gradeId: string, updatedPermissions: Record<string, true>) =>
		sendJson<boolean>('Update', { type: 'jobPermissions', JobId: jobId, WorkplaceId: workplaceId, GradeId: gradeId, UpdatedPermissions: updatedPermissions }, true),
	// badges.lua only calls cb(false) on failure, never cb(true) on success, treat "no error toast" as success
	printBadge: (sid: number, jobId: string) => sendJson<boolean>('PrintBadge', { SID: sid, JobId: jobId }, true),

	// ---- Library ----
	getLibraryDocuments: () => sendJson<LibraryDocument[]>('GetLibraryDocuments', {}, MOCK_LIBRARY_DOCS),
	addLibraryDocument: (label: string, link: string, job?: string, workplace?: string) =>
		sendJson<number | false>('AddLibraryDocument', { label, link, job, workplace }, 1),
	removeLibraryDocument: (id: number) => sendJson<boolean>('RemoveLibraryDocument', { id }, true),

	// ---- DOC / prisoners ----
	docGetPrisoners: () => sendJson<Prisoner[]>('DOCGetPrisoners', {}, MOCK_PRISONERS),
	// reduction is MINUTES subtracted from Jailed.Duration (pulsar_jail's Reduce()), not a percentage or day count
	docReduceSentence: (sid: number, reduction: number) => sendJson<boolean>('DOCReduceSentence', { SID: sid, reduction }, true),
	docRequestVisitation: (sid: number) => sendJson<{ success: boolean; message?: string }>('DOCRequestVisitation', { SID: sid }, OK),

	// ---- Dashboard / home ----
	getHomeData: () => sendJson<HomeData>('GetHomeData', {}, MOCK_HOME_DATA),

	// ---- BOLOs / Charges / Notices (misc) ----
	// author is attributed server-side (misc.lua's Create:BOLO callback), like the vehicle-flag/firearm-flag pattern
	createBolo: (doc: { title: string; type: string; summary?: string; description?: string }) => sendJson<boolean>('Create', { type: 'BOLO', doc }, true),
	deleteBolo: (id: number) => sendJson<boolean>('Delete', { type: 'BOLO', id }, true),
	// charge create/update/delete just return a boolean, the actual change arrives via misc.lua's broadcast which data.svelte.ts applies automatically
	createCharge: (doc: Omit<Charge, 'id' | 'active'>) => sendJson<boolean>('Create', { type: 'charge', doc }, true),
	updateCharge: (doc: Charge) => sendJson<boolean>('Update', { type: 'charge', doc }, true),
	deleteCharge: (doc: { id: number }) => sendJson<boolean>('Delete', { type: 'charge', doc }, true),
	createNotice: (doc: unknown) => sendJson<number | false>('Create', { type: 'notice', doc }, 1),
	viewNotice: (id: number) => sendJson<Notice | false>('View', { type: 'notice', id }, MOCK_NOTICES.find((n) => n.id === id) ?? MOCK_NOTICE),
	deleteNotice: (id: number) => sendJson<boolean>('Delete', { type: 'notice', id }, true),

	// ---- Alerts / Dispatch (pushed to Lua so it can spawn world-side effects - blips, waypoints, sounds) ----
	// client/alerts/nui.lua reads location/blip/id/title/panic off the payload root, so these take the full alert object not just its id
	closeAlerts: () => send('CloseAlerts'),
	receiveAlert: (alert: DispatchAlert) => send('ReceiveAlert', alert),
	removeAlert: (alertId: string) => send('RemoveAlert', { id: alertId }),
	assignedToAlert: () => send('AssignedToAlert'),
	routeAlert: (alert: DispatchAlert) => send('RouteAlert', alert),
	viewCamera: (camera: unknown) => send('ViewCamera', { camera }),
	swapToRadio: (radio: string) => send('SwapToRadio', { radio }),

	// ---- Dispatch panel actions - always available natively, no websocket required ----
	alertsChangeUnitType: (job: string, primary: string | number, unitType: string) => send('AlertsChangeUnitType', { job, primary, type: unitType }),
	alertsChangeAvailability: (job: string, primary: string | number) => send('AlertsChangeAvailability', { job, primary }),
	alertsOperateUnder: (job: string, primary: string | number, unit: string | number) => send('AlertsOperateUnder', { job, primary, unit }),
	alertsBreakOff: (job: string, primary: string | number, unit: string | number) => send('AlertsBreakOff', { job, primary, unit }),
	alertsChangeRadioChannel: (channel: string) => send('AlertsChangeRadioChannel', { channel }),
	alertsChangePursuitMode: (mode: string | null) => send('AlertsChangePursuitMode', { mode }),
	alertsUpdateAlertUnits: (id: string, units: (string | number)[]) => send('AlertsUpdateAlertUnits', { id, units }),
	// server-tracked alerts only, client-only local alerts are removed from the store directly without a round-trip
	alertsRemoveAlert: (id: string) => send('AlertsRemoveAlert', { id }),
	alertsAddRadioInfo: (radio: string, text: string) => send('AlertsAddRadioInfo', { radio, text }),
	alertsUpdateRadioInfo: (id: number, radio: string, text: string) => send('AlertsUpdateRadioInfo', { id, radio, text }),
	alertsRemoveRadioInfo: (id: number) => send('AlertsRemoveRadioInfo', { id }),
	alertsLogMessage: (message: string) => send('AlertsLogMessage', { message }),
};
