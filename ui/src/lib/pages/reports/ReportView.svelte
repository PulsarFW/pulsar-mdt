<script lang="ts">
	import Icon from '../../Icon.svelte';
	import Loader from '../../primitives/Loader.svelte';
	import Modal from '../../primitives/Modal.svelte';
	import RichText from '../../primitives/RichText.svelte';
	import OfficerSearch from '../../primitives/OfficerSearch.svelte';
	import PersonSearch from '../../primitives/PersonSearch.svelte';
	import SuspectCard from './SuspectCard.svelte';
	import SuspectDetail from './SuspectDetail.svelte';
	import SuspectForm from './SuspectForm.svelte';
	import EvidenceForm from './EvidenceForm.svelte';
	import { Nui } from '../../nui';
	import { appState, toast } from '../../store/app.svelte';
	import { REPORT_TYPES, EVIDENCE_TYPES, reportOfficerName, reportOfficerJob, reportTypeHasEvidence } from '../../../config';
	import type { Evidence, OfficerRef, PersonSearchResult, Report, ReportPerson, ReportSuspect, UpdateReportChange } from '../../types';

	let {
		reportId,
		creating,
		preSuspectSid = null,
		onCreated,
	}: {
		reportId: number | null;
		creating: boolean;
		preSuspectSid?: number | null;
		onCreated: (id: number) => void;
	} = $props();

	const isSystemAdmin = $derived(Boolean(appState.user?.MDTSystemAdmin));

	function hasPerm(permission?: string, allowSysAdmin = true): boolean {
		if (!permission) return true;
		return Boolean(appState.govJobPermissions[permission]) || (allowSysAdmin && isSystemAdmin);
	}

	const createableTypes = $derived(REPORT_TYPES.filter((r) => hasPerm(r.requiredCreatePermission, false)));

	let report = $state<Report | null>(null);
	let loading = $state(false);
	let editing = $state(false);

	let type = $state(0);
	let title = $state('');
	let notesHtml = $state('');
	let allowAttorney = $state(false);
	let primaries = $state<OfficerRef[]>([]);
	let people = $state<PersonSearchResult[]>([]);
	let evidence = $state<Evidence[]>([]);
	let suspects = $state<(ReportSuspect & { _new?: boolean })[]>([]);
	let changes: UpdateReportChange[] = [];
	let originalPrimaries: ReportPerson[] = [];
	let originalPeople: ReportPerson[] = [];
	let tempIdCounter = -1;

	const reportTypeDef = $derived(REPORT_TYPES.find((r) => r.value === type));
	const canEdit = $derived(hasPerm(reportTypeDef?.requiredCreatePermission));
	const mode = $derived(creating ? 'create' : editing ? 'edit' : 'view');

	function toReportPerson(o: { SID: number; First: string; Last: string; Callsign?: OfficerRef['Callsign'] }): ReportPerson {
		return { SID: o.SID, First: o.First, Last: o.Last, Callsign: o.Callsign ? String(o.Callsign) : undefined };
	}

	function resetForCreate() {
		type = createableTypes[0]?.value ?? 0;
		title = '';
		notesHtml = '';
		allowAttorney = false;
		primaries = appState.user ? [{ SID: appState.user.SID, First: appState.user.First, Last: appState.user.Last, Callsign: appState.user.Callsign }] : [];
		people = [];
		evidence = [];
		suspects = [];
		changes = [];
		report = null;
		editing = false;
	}

	async function load() {
		if (reportId === null) {
			report = null;
			return;
		}
		loading = true;
		const res = await Nui.viewReport(reportId);
		report = res || null;
		if (report) {
			type = report.type;
			title = report.title;
			notesHtml = report.notes;
			allowAttorney = report.allowAttorney;
			primaries = report.primaries.map((p) => ({ SID: p.SID, First: p.First, Last: p.Last, Callsign: p.Callsign }));
			people = report.people.map((p) => ({ SID: p.SID, First: p.First, Last: p.Last }));
			evidence = [...report.evidence];
			suspects = [...report.suspects];
		}
		editing = false;
		changes = [];
		loading = false;
	}

	$effect(() => {
		if (creating) {
			resetForCreate();
			if (preSuspectSid) openAddSuspect();
		} else {
			load();
		}
	});

	function startEdit() {
		editing = true;
		originalPrimaries = primaries.map(toReportPerson);
		originalPeople = people.map((p) => toReportPerson(p as never));
		changes = [];
	}

	function diffPeople(kind: 'primary' | 'person', original: ReportPerson[], current: ReportPerson[]): UpdateReportChange[] {
		const result: UpdateReportChange[] = [];
		for (const p of current) {
			if (!original.some((o) => o.SID === p.SID)) result.push({ type: kind, mode: 'add', data: p });
		}
		for (const o of original) {
			if (!current.some((p) => p.SID === o.SID)) result.push({ type: kind, mode: 'delete', data: { SID: o.SID } });
		}
		return result;
	}

	async function save() {
		if (creating) {
			if (type === 0 && suspects.length === 0) {
				toast.error('Must Select Suspect');
				return;
			}
			if (!title.trim()) {
				toast.error('Must Add Report Title');
				return;
			}
			if (!notesHtml.trim()) {
				toast.error('Must Add Report Notes');
				return;
			}
			const id = await Nui.createReport({
				type,
				title,
				notes: notesHtml,
				allowAttorney,
				primaries: primaries.map(toReportPerson),
				people: people.map((p) => toReportPerson(p as never)),
				suspects: suspects.map((s) => ({ SID: s.SID, First: s.First, Last: s.Last, charges: s.charges, plea: s.plea ?? 'unknown', Licenses: s.Licenses })),
				evidence: evidence.map((e) => ({ type: e.type, label: e.label, value: e.value })),
			});
			if (id) {
				toast.success('Report created.');
				onCreated(id);
			} else toast.error('Failed to create report.');
		} else if (editing && report) {
			const peopleChanges = diffPeople('person', originalPeople, people.map((p) => toReportPerson(p as never)));
			const primaryChanges = diffPeople('primary', originalPrimaries, primaries.map(toReportPerson));
			const ok = await Nui.updateReport(report.id, { title, notes: notesHtml, allowAttorney, changes: [...changes, ...peopleChanges, ...primaryChanges] });
			if (ok) {
				toast.success('Report updated.');
				await load();
			} else toast.error('Failed to update report.');
		}
	}

	// ---- Suspects ----
	let suspectFormOpen = $state(false);
	let editingSuspect = $state<ReportSuspect | null>(null);

	function openAddSuspect() {
		editingSuspect = null;
		suspectFormOpen = true;
	}
	function openEditSuspect(s: ReportSuspect) {
		editingSuspect = s;
		suspectFormOpen = true;
	}

	function onSuspectSubmit(s: { SID: number; First: string; Last: string; Licenses?: ReportSuspect['Licenses']; plea: string; charges: ReportSuspect['charges'] }) {
		if (editingSuspect) {
			suspects = suspects.map((x) => (x.SID === s.SID ? { ...x, plea: s.plea, charges: s.charges } : x));
			if (editing) changes = [...changes, { type: 'suspect', mode: 'update', data: { SID: s.SID, charges: s.charges, plea: s.plea } }];
		} else {
			suspects = [...suspects, { ...s, _new: true }];
			if (editing) changes = [...changes, { type: 'suspect', mode: 'add', data: { SID: s.SID, First: s.First, Last: s.Last, charges: s.charges, plea: s.plea } }];
		}
		suspectFormOpen = false;
		editingSuspect = null;
	}

	function deleteSuspect(s: ReportSuspect & { _new?: boolean }) {
		suspects = suspects.filter((x) => x.SID !== s.SID);
		if (editing) {
			if (s._new) {
				changes = changes.filter((c) => !(c.type === 'suspect' && c.data.SID === s.SID));
			} else {
				changes = [...changes, { type: 'suspect', mode: 'delete', data: { SID: s.SID } }];
			}
		}
	}

	// ---- Evidence ----
	let evidenceFormOpen = $state(false);

	function addEvidence(doc: { type: string; label: string; value: string }) {
		const tempId = tempIdCounter--;
		evidence = [...evidence, { id: tempId, report: reportId ?? 0, ...doc }];
		if (editing) changes = [...changes, { type: 'evidence', mode: 'add', data: doc }];
		evidenceFormOpen = false;
	}

	function removeEvidence(item: Evidence) {
		evidence = evidence.filter((e) => e.id !== item.id);
		if (editing) {
			if (item.id < 0) {
				changes = changes.filter((c) => !(c.type === 'evidence' && c.mode === 'add' && c.data.value === item.value && c.data.label === item.label));
			} else {
				changes = [...changes, { type: 'evidence', mode: 'delete', data: { id: item.id } }];
			}
		}
		if (viewingEvidence === item) viewingEvidence = null;
	}

	let viewingEvidence = $state<Evidence | null>(null);

	function evidenceLabel(type: string) {
		return EVIDENCE_TYPES.find((t) => t.value === type)?.label ?? type;
	}
	function evidenceColor(type: string) {
		return EVIDENCE_TYPES.find((t) => t.value === type)?.color ?? '#1eadd9';
	}

	async function openEvidenceLocker() {
		if (!report) return;
		const ok = await Nui.openEvidenceLocker(report.id);
		if (ok) Nui.close();
	}
</script>

<div class="detail">
	{#if reportId === null && !creating}
		<div class="empty">
			<Icon name="file-lines" size="4vmin" />
			<p>No Report Selected</p>
		</div>
	{:else if loading}
		<Loader />
	{:else if !creating && !report}
		<div class="empty">
			<Icon name="file-lines" size="4vmin" />
			<p>Report Not Found</p>
		</div>
	{:else}
		<div class="scroll">
			<div class="header">
				<h2>{creating ? 'New Report' : `Report #${report?.id} - ${title}`}</h2>
				<div class="actions">
					{#if mode === 'view' && appState.govJob?.Id === 'police' && reportTypeHasEvidence(type)}
						<button type="button" class="btn" onclick={openEvidenceLocker}>Evidence Locker</button>
					{/if}
					{#if mode !== 'view'}
						<button type="button" class="btn" onclick={() => (evidenceFormOpen = true)}>Add Evidence</button>
					{/if}
					{#if type === 0 && mode !== 'view'}
						<button type="button" class="btn" onclick={openAddSuspect}>Add Suspect</button>
					{/if}
					{#if mode === 'view'}
						<button type="button" class="btn primary" disabled={!canEdit} onclick={startEdit}>Edit Report</button>
					{:else}
						<button type="button" class="btn primary" onclick={save}>Save Report</button>
					{/if}
				</div>
			</div>

			<label class="field">
				Report Notes
				<RichText bind:value={notesHtml} disabled={mode === 'view'} placeholder="Enter Report Notes" />
			</label>

			{#if evidence.length > 0}
				<section>
					<h3>Evidence</h3>
					<div class="chips">
						{#each evidence as item (item.id)}
							<button type="button" class="chip" style:background={evidenceColor(item.type) + '33'} style:color={evidenceColor(item.type)} onclick={() => (viewingEvidence = item)}>
								{evidenceLabel(item.type)} [{item.label}]
								{#if mode !== 'view'}
									<span
										role="button"
										tabindex="0"
										onclick={(e) => (e.stopPropagation(), removeEvidence(item))}
										onkeydown={(e) => e.key === 'Enter' && (e.stopPropagation(), removeEvidence(item))}
									>
										<Icon name="xmark" size="0.85vmin" />
									</span>
								{/if}
							</button>
						{/each}
					</div>
				</section>
			{/if}

			<label class="field">
				Report Type
				<select bind:value={type} disabled={mode !== 'create'}>
					{#each createableTypes as t (t.value)}
						<option value={t.value}>{t.label}</option>
					{/each}
				</select>
			</label>

			<label class="field">
				Report Title
				<input type="text" bind:value={title} disabled={mode === 'view'} />
			</label>

			{#if reportTypeDef?.allowAttorney}
				<label class="field">
					Attorney Access
					<select value={String(allowAttorney)} disabled={mode === 'view'} onchange={(e) => (allowAttorney = (e.target as HTMLSelectElement).value === 'true')}>
						<option value="false">Don't Allow Attorney Viewing</option>
						<option value="true">Allow Attorney Viewing</option>
					</select>
				</label>
			{/if}

			<div class="field">
				<span class="field-label">{reportOfficerName(type)} Involved</span>
				{#if mode !== 'view'}
					<OfficerSearch bind:selected={primaries} job={reportOfficerJob(type)} label="" />
				{:else}
					<div class="chips">
						{#each primaries as p (p.SID)}
							<span class="chip static">{p.First} {p.Last}{p.Callsign ? ` (${p.Callsign})` : ''}</span>
						{/each}
					</div>
				{/if}
			</div>

			{#if type !== 0}
				<div class="field">
					<span class="field-label">People Involved</span>
					{#if mode !== 'view'}
						<PersonSearch bind:selected={people} label="" placeholder="John Doe, Jane Doe etc..." />
					{:else}
						<div class="chips">
							{#each people as p (p.SID)}
								<span class="chip static">{p.First} {p.Last}</span>
							{/each}
						</div>
					{/if}
				</div>
			{/if}

			{#if type === 0}
				<section>
					<h3>Suspects</h3>
					{#if suspects.length === 0 && mode !== 'view'}
						<p class="alert">Please Add A Suspect To Your Report</p>
					{/if}
					<div class="suspect-list">
						{#each suspects as suspect (suspect.SID)}
							{#if mode !== 'view'}
								<SuspectCard {suspect} onEdit={() => openEditSuspect(suspect)} onDelete={() => deleteSuspect(suspect)} />
							{:else if report}
								<SuspectDetail data={suspect} reportId={report.id} refresh={load} />
							{/if}
						{/each}
						{#if report}
							{#each report.suspectsOverturned as suspect (suspect.SID)}
								<SuspectDetail data={suspect} reportId={report.id} overturned />
							{/each}
						{/if}
					</div>
				</section>
			{/if}
		</div>
	{/if}
</div>

<SuspectForm showing={suspectFormOpen} existing={editingSuspect} preSuspectSid={editingSuspect ? null : preSuspectSid} onSubmit={onSuspectSubmit} onClose={() => ((suspectFormOpen = false), (editingSuspect = null))} />
<EvidenceForm showing={evidenceFormOpen} onSubmit={addEvidence} onClose={() => (evidenceFormOpen = false)} />

{#if viewingEvidence}
	<Modal showing={Boolean(viewingEvidence)} title={evidenceLabel(viewingEvidence.type)} acceptLabel="Close" onAccept={() => (viewingEvidence = null)} onClose={() => (viewingEvidence = null)}>
		<p>Label: {viewingEvidence.label}</p>
		{#if viewingEvidence.type === 'photo'}
			<img class="evidence-photo" src={viewingEvidence.value} alt={viewingEvidence.label} />
		{:else if /^https?:\/\//.test(viewingEvidence.value)}
			<p>Identifier: <a href={viewingEvidence.value} target="_blank" rel="noopener noreferrer">{viewingEvidence.value}</a></p>
		{:else}
			<p>Identifier: {viewingEvidence.value}</p>
		{/if}
	</Modal>
{/if}

<style>
	.detail {
		display: flex;
		flex-direction: column;
		height: 100%;
	}

	.empty {
		margin: auto;
		text-align: center;
		color: var(--color-text-muted);
	}

	.scroll {
		overflow-y: auto;
		padding: 1.2vh 1.2vw;
		display: flex;
		flex-direction: column;
		gap: 1.4vh;
	}

	.header {
		display: flex;
		align-items: center;
		justify-content: space-between;
		flex-wrap: wrap;
		gap: 0.6vh;
	}

	.header h2 {
		margin: 0;
		font-family: var(--font-heading);
		font-size: 1.6vmin;
	}

	.actions {
		display: flex;
		gap: 0.5vw;
	}

	.btn {
		background: var(--color-bg-panel-alt);
		border: var(--border-subtle);
		border-radius: var(--radius);
		color: var(--color-surface-text);
		cursor: pointer;
		padding: 0.6vh 0.9vw;
		font-size: 1.05vmin;
	}

	.btn:hover:not(:disabled) {
		border-color: var(--color-primary);
		color: var(--color-nav-text-active);
	}

	.btn:disabled {
		opacity: 0.4;
		cursor: not-allowed;
	}

	.btn.primary {
		background: var(--color-primary);
		color: #fff;
		border-color: var(--color-primary);
	}

	.field {
		display: flex;
		flex-direction: column;
		gap: 0.4vh;
	}

	.field-label {
		font-size: 1.05vmin;
		color: var(--color-text-muted);
	}

	input,
	select {
		background-color: var(--color-bg);
		border: var(--border-subtle);
		border-radius: var(--radius);
		color: var(--color-text);
		padding: 0.7vh 0.7vw;
		font-size: 1.1vmin;
	}

	input:disabled,
	select:disabled {
		color: var(--color-text-muted);
	}

	section h3 {
		margin: 0 0 0.4vh;
		font-size: 1.15vmin;
		text-transform: uppercase;
		letter-spacing: 0.03em;
		color: var(--color-text-muted);
	}

	.chips {
		display: flex;
		flex-wrap: wrap;
		gap: 0.4vh;
	}

	.chip {
		display: inline-flex;
		align-items: center;
		gap: 0.3vw;
		background: rgba(139, 92, 246, 0.15);
		color: var(--color-primary-light);
		border: none;
		border-radius: var(--radius);
		padding: 0.4vh 0.7vw;
		font-size: 1vmin;
		cursor: pointer;
	}

	.chip.static {
		cursor: default;
	}

	.alert {
		background: rgba(91, 163, 224, 0.12);
		color: var(--color-info);
		border-radius: var(--radius);
		padding: 0.7vh 0.9vw;
		font-size: 1.05vmin;
	}

	.suspect-list {
		display: flex;
		flex-direction: column;
		gap: 0.6vh;
	}

	.evidence-photo {
		max-width: 100%;
		border-radius: var(--radius);
	}

	a {
		color: var(--color-primary-light);
	}
</style>
