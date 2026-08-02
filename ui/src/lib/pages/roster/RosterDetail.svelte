<script lang="ts">
	import Icon from '../../Icon.svelte';
	import Loader from '../../primitives/Loader.svelte';
	import Modal from '../../primitives/Modal.svelte';
	import { Nui } from '../../nui';
	import { appState, toast } from '../../store/app.svelte';
	import { dataState } from '../../store/data.svelte';
	import { formatDateTime } from '../../util/format';
	import type { GovJob, RosterDetail as RosterDetailType } from '../../types';

	let { selectedJob, sid, onUpdated }: { selectedJob: string; sid: number | null; onUpdated: () => void } = $props();

	let officer = $state<RosterDetailType | null>(null);
	let loading = $state(false);

	async function load() {
		if (sid === null) {
			officer = null;
			return;
		}
		loading = true;
		const res = await Nui.rosterSelect(sid, selectedJob);
		officer = res || null;
		loading = false;
	}

	$effect(() => {
		load();
	});

	const isSystemAdmin = $derived(Boolean(appState.user?.MDTSystemAdmin));
	function hasPerm(permission?: string): boolean {
		if (!permission) return true;
		return Boolean(appState.govJobPermissions[permission]) || isSystemAdmin;
	}
	const isHighCommand = $derived(hasPerm('PD_HIGH_COMMAND') || hasPerm('SAFD_HIGH_COMMAND') || hasPerm('DOJ_JUDGE') || hasPerm('DOC_HIGH_COMMAND'));
	const canFire = $derived(hasPerm('MDT_FIRE') || isHighCommand);
	const canPromote = $derived(hasPerm('MDT_PROMOTE') || isHighCommand);
	const canEdit = $derived(hasPerm('MDT_EDIT_EMPLOYEE') || isHighCommand);

	const govJobEntry = $derived(officer?.Jobs.find((j) => j.Id === selectedJob) ?? null);
	const jobData = $derived(dataState.governmentJobsData[selectedJob] as { Name?: string; Workplaces?: { Id: string; Name: string; Grades: { Id: string; Name: string; Level: number; Permissions?: Record<string, boolean> }[] }[] } | undefined);
	const showsCallsign = $derived(
		govJobEntry?.Id === 'police' || (govJobEntry?.Id === 'ems' && govJobEntry.Workplace?.Id === 'safd') || (govJobEntry?.Id === 'prison' && govJobEntry.Workplace?.Id === 'corrections'),
	);
	const canSuspendJob = $derived(govJobEntry?.Id === 'police' || govJobEntry?.Id === 'ems');
	const suspension = $derived.by(() => {
		const entry = officer?.MDTSuspension?.[selectedJob];
		if (!entry || entry.Expires * 1000 <= Date.now()) return null;
		return entry;
	});
	const isSelf = $derived(officer?.SID === appState.user?.SID);
	const showActions = $derived(officer && !isSelf && !officer.MDTSystemAdmin);
	const showSelfActions = $derived(officer && isSelf && isHighCommand);

	const workplaceGrades = $derived(jobData?.Workplaces?.find((w) => w.Id === govJobEntry?.Workplace?.Id)?.Grades ?? []);
	const qualifications = $derived(dataState.qualifications);
	const permissions = $derived(dataState.permissions);
	const grantedPermissions = $derived(Object.keys(workplaceGrades.find((g) => g.Id === govJobEntry?.Grade.Id)?.Permissions ?? {}));

	function dutySummaryMinutes(): number {
		if (!officer?.TimeClockedOn?.[selectedJob]) return 0;
		const cutoff = Date.now() / 1000 - 7 * 24 * 60 * 60;
		return officer.TimeClockedOn[selectedJob].filter((s) => s.time >= cutoff).reduce((a, s) => a + s.minutes, 0);
	}

	function formatMinutes(mins: number): string {
		if (mins <= 0) return '0 minutes';
		const hrs = Math.floor(mins / 60);
		const rem = mins % 60;
		return hrs > 0 ? `${hrs}h ${rem}m` : `${rem}m`;
	}

	// ---- modals ----
	let modal = $state<'mugshot' | 'callsign' | 'job' | 'fire' | 'suspend' | 'unsuspend' | 'qualifications' | 'duty' | null>(null);

	let mugshotUrl = $state('');
	let callsignValue = $state('');
	let workingJob = $state<GovJob | null>(null);
	let suspendDays = $state('3');
	let pendingQuals = $state<string[]>([]);

	function openModal(which: NonNullable<typeof modal>) {
		if (!officer) return;
		if (which === 'mugshot') mugshotUrl = officer.Mugshot ?? '';
		if (which === 'callsign') callsignValue = String(officer.Callsign ?? '');
		if (which === 'job') workingJob = govJobEntry ? { ...govJobEntry } : null;
		if (which === 'suspend') suspendDays = '3';
		if (which === 'qualifications') pendingQuals = [...(officer.Qualifications ?? [])];
		modal = which;
	}

	async function saveMugshot() {
		if (!officer) return;
		const ok = await Nui.updatePerson(officer.SID, 'Mugshot', mugshotUrl);
		if (ok) {
			officer.Mugshot = mugshotUrl;
			toast.success('Mugshot updated.');
		} else toast.error('Failed to update mugshot.');
		modal = null;
	}

	async function saveCallsign() {
		if (!officer) return;
		if (String(officer.Callsign ?? '') === callsignValue) {
			modal = null;
			return;
		}
		const parsed = parseInt(callsignValue, 10);
		if (Number.isNaN(parsed)) {
			toast.error('Invalid callsign.');
			return;
		}
		const available = await Nui.checkCallsign(String(parsed));
		if (!available) {
			toast.error('Callsign Already Assigned');
			return;
		}
		const ok = await Nui.updatePerson(officer.SID, 'Callsign', parsed);
		if (ok) {
			officer.Callsign = parsed;
			toast.success('Callsign updated.');
		} else toast.error('Failed to update callsign.');
		modal = null;
	}

	async function saveJob() {
		if (!officer || !workingJob) return;
		const ok = await Nui.manageEmployment(officer.SID, selectedJob, { Id: workingJob.Id, Workplace: { Id: workingJob.Workplace?.Id ?? '' }, Grade: { Id: workingJob.Grade.Id } });
		if (ok) {
			toast.success('Employment updated.');
			await load();
			onUpdated();
		} else toast.error('Failed to update employment.');
		modal = null;
	}

	function onDeptChange(deptId: string) {
		if (!workingJob || !jobData) return;
		const wp = jobData.Workplaces?.find((w) => w.Id === deptId);
		const lowestGrade = wp ? [...wp.Grades].sort((a, b) => a.Level - b.Level)[0] : undefined;
		workingJob = { ...workingJob, Workplace: wp ? { Id: wp.Id, Name: wp.Name } : workingJob.Workplace, Grade: lowestGrade ? { Id: lowestGrade.Id, Name: lowestGrade.Name, Level: lowestGrade.Level } : workingJob.Grade };
	}

	async function submitFire() {
		if (!officer) return;
		const ok = await Nui.fireEmployee(officer.SID, selectedJob);
		if (ok) {
			toast.success('Employee fired.');
			await load();
			onUpdated();
		} else toast.error('Failed to fire employee.');
		modal = null;
	}

	async function submitSuspend() {
		if (!officer) return;
		const days = parseInt(suspendDays, 10);
		if (Number.isNaN(days) || days <= 0 || days >= 99) {
			toast.error('Invalid suspension length.');
			return;
		}
		const ok = await Nui.suspendEmployee(officer.SID, selectedJob, days);
		if (ok) {
			toast.success('Employee suspended.');
			await load();
		} else toast.error('Failed to suspend employee.');
		modal = null;
	}

	async function submitUnsuspend() {
		if (!officer) return;
		const ok = await Nui.unsuspendEmployee(officer.SID, selectedJob);
		if (ok) {
			toast.success('Suspension revoked.');
			await load();
		} else toast.error('Failed to revoke suspension.');
		modal = null;
	}

	async function saveQualifications() {
		if (!officer) return;
		const ok = await Nui.updatePerson(officer.SID, 'Qualifications', pendingQuals);
		if (ok) {
			officer.Qualifications = pendingQuals;
			toast.success('Qualifications updated.');
		} else toast.error('Failed to update qualifications.');
		modal = null;
	}

	function toggleQual(id: string) {
		pendingQuals = pendingQuals.includes(id) ? pendingQuals.filter((q) => q !== id) : [...pendingQuals, id];
	}

	function qualAllowed(id: string): boolean {
		const q = qualifications[id];
		if (!q?.restrict) return true;
		if (q.restrict.weapon && (govJobEntry?.Id === 'police' || govJobEntry?.Id === 'prison')) return true;
		if (q.restrict.job === govJobEntry?.Id && (!q.restrict.workplace || q.restrict.workplace === govJobEntry?.Workplace?.Id)) return true;
		return false;
	}

	async function printBadge() {
		if (!officer) return;
		await Nui.close();
		Nui.printBadge(officer.SID, selectedJob);
		toast.success('Badge requested.');
	}
</script>

<div class="detail">
	{#if sid === null}
		<div class="empty">
			<Icon name="id-badge" size="4vmin" />
			<p>No Officer Selected</p>
		</div>
	{:else if loading}
		<Loader />
	{:else if !officer || !govJobEntry}
		<div class="empty">
			<Icon name="id-badge" size="4vmin" />
			<p>Officer Not Found</p>
		</div>
	{:else}
		<div class="scroll">
			<div class="header">
				<button type="button" class="avatar" onclick={() => canEdit && openModal('mugshot')} disabled={!canEdit}>
					{#if officer.Mugshot}<img src={officer.Mugshot} alt="" />{:else}<Icon name="user-large" size="2.2vmin" />{/if}
				</button>
				<div class="identity">
					<h2>{officer.First} {officer.Last}</h2>
					<div class="meta">
						<span>State ID: {officer.SID}</span>
						{#if showsCallsign}
							<button type="button" class="link" disabled={!canEdit} onclick={() => canEdit && openModal('callsign')}>
								Callsign: {officer.Callsign || 'Not Set'}
							</button>
						{/if}
						{#if officer.Phone}<span>Phone: {officer.Phone}</span>{/if}
					</div>
				</div>
			</div>

			{#if suspension}
				<div class="alert warning">
					Suspended - {suspension.Length} day suspension, expires {formatDateTime(suspension.Expires * 1000)}
					<br />
					Suspended By: [{suspension.Actioned.Callsign}] {suspension.Actioned.First[0]}. {suspension.Actioned.Last}
				</div>
			{/if}

			<div class="grid">
				<div><span class="k">Department</span><span class="v">{govJobEntry.Workplace?.Name}</span></div>
				<div><span class="k">Rank</span><span class="v">{govJobEntry.Grade.Name}</span></div>
				<div class="full">
					<span class="k">Qualifications</span>
					<span class="v">{(officer.Qualifications ?? []).map((q) => qualifications[q]?.name ?? 'Unknown').join(', ') || 'No Qualifications'}</span>
				</div>
				<div class="full">
					<span class="k">Permissions</span>
					<span class="v">{grantedPermissions.map((p) => permissions[p]?.name ?? p).join(', ') || 'None'}</span>
				</div>
				{#if officer.LastClockOn?.[selectedJob]}
					<div class="full"><span class="k">Last Clocked On</span><span class="v">{formatDateTime(officer.LastClockOn[selectedJob] * 1000)}</span></div>
				{/if}
				{#if officer.TimeClockedOn?.[selectedJob]}
					<button type="button" class="full clickable" onclick={() => (modal = 'duty')}>
						<span class="k">Time Worked (Last 7 Days)</span><span class="v">{formatMinutes(dutySummaryMinutes())}</span>
					</button>
				{/if}
			</div>

			{#if showActions}
				<div class="actions">
					{#if canPromote}<button type="button" class="btn" onclick={() => openModal('job')}>Edit</button>{/if}
					{#if canFire}<button type="button" class="btn" onclick={() => (modal = 'fire')}>Fire</button>{/if}
					{#if canFire && !suspension && canSuspendJob}<button type="button" class="btn" onclick={() => openModal('suspend')}>Suspend</button>{/if}
					{#if canFire && suspension && canSuspendJob}<button type="button" class="btn" onclick={submitUnsuspend}>Revoke Suspension</button>{/if}
					{#if isHighCommand}<button type="button" class="btn" onclick={() => openModal('qualifications')}>Qualifications</button>{/if}
					{#if isHighCommand}<button type="button" class="btn" onclick={printBadge}>Print Badge</button>{/if}
				</div>
			{:else if showSelfActions}
				<div class="actions">
					<button type="button" class="btn" onclick={() => openModal('qualifications')}>Qualifications</button>
					<button type="button" class="btn" onclick={printBadge}>Print Badge</button>
				</div>
			{/if}
		</div>
	{/if}
</div>

{#if officer}
	<Modal showing={modal === 'mugshot'} title="Update Mugshot" onAccept={saveMugshot} onClose={() => (modal = null)}>
		<label>Image URL<input type="text" bind:value={mugshotUrl} /></label>
	</Modal>

	<Modal showing={modal === 'callsign'} title="Update Callsign" onAccept={saveCallsign} onClose={() => (modal = null)}>
		<label>Callsign (3 digits, numbers only)<input type="text" maxlength="3" bind:value={callsignValue} /></label>
	</Modal>

	{#if workingJob}
		<Modal showing={modal === 'job'} title="Edit Employment" onAccept={saveJob} onClose={() => (modal = null)}>
			<label>
				Department
				<select
					value={workingJob.Workplace?.Id ?? ''}
					disabled={!isHighCommand || workingJob.Id === 'ems'}
					onchange={(e) => onDeptChange((e.target as HTMLSelectElement).value)}
				>
					{#each jobData?.Workplaces ?? [] as w (w.Id)}
						<option value={w.Id}>{w.Name}</option>
					{/each}
				</select>
			</label>
			<label>
				Rank
				<select
					value={workingJob.Grade.Id}
					disabled={!canPromote}
					onchange={(e) => {
						const g = workplaceGrades.find((g) => g.Id === (e.target as HTMLSelectElement).value);
						if (g && workingJob) workingJob = { ...workingJob, Grade: { Id: g.Id, Name: g.Name, Level: g.Level } };
					}}
				>
					{#each workplaceGrades as g (g.Id)}
						<option value={g.Id}>{g.Name}</option>
					{/each}
				</select>
			</label>
		</Modal>
	{/if}

	<Modal showing={modal === 'fire'} title="Fire Employee" acceptLabel="Fire" onAccept={submitFire} onClose={() => (modal = null)}>
		<p>Are you sure you want to fire {govJobEntry?.Workplace?.Name} {govJobEntry?.Grade.Name} {officer.First} {officer.Last}?</p>
	</Modal>

	<Modal showing={modal === 'suspend'} title="Suspend Employee" acceptLabel="Suspend" onAccept={submitSuspend} onClose={() => (modal = null)}>
		<label>Suspension Length (Days)<input type="text" bind:value={suspendDays} /></label>
		<p class="hint">Are you sure you want to suspend {govJobEntry?.Workplace?.Name} {govJobEntry?.Grade.Name} {officer.First} {officer.Last} for {suspendDays} days?</p>
	</Modal>

	<Modal showing={modal === 'qualifications'} title="Edit Qualifications" onAccept={saveQualifications} onClose={() => (modal = null)}>
		<div class="qual-list">
			{#each Object.entries(qualifications).filter(([id]) => qualAllowed(id)) as [id, q] (id)}
				<label class="row"><input type="checkbox" checked={pendingQuals.includes(id)} onchange={() => toggleQual(id)} /> {q.name}</label>
			{/each}
		</div>
	</Modal>

	<Modal showing={modal === 'duty'} title="Recent Sessions on Duty" acceptLabel="Close" onAccept={() => (modal = null)} onClose={() => (modal = null)}>
		{#each officer.TimeClockedOn?.[selectedJob] ?? [] as session, i (i)}
			<p>{formatDateTime(session.time * 1000)} - {formatMinutes(session.minutes)}</p>
		{/each}
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
		gap: 1.2vh;
	}

	.header {
		display: flex;
		gap: 1vw;
		align-items: flex-start;
	}

	.avatar {
		flex-shrink: 0;
		width: 7vh;
		height: 7vh;
		border-radius: var(--radius);
		background: var(--color-bg);
		border: var(--border-subtle);
		display: flex;
		align-items: center;
		justify-content: center;
		overflow: hidden;
		color: var(--color-text-muted);
		cursor: pointer;
		padding: 0;
	}

	.avatar:disabled {
		cursor: default;
	}

	.avatar img {
		width: 100%;
		height: 100%;
		object-fit: cover;
	}

	.identity h2 {
		margin: 0 0 0.4vh;
		font-family: var(--font-heading);
		font-size: 1.7vmin;
	}

	.meta {
		display: flex;
		flex-wrap: wrap;
		gap: 1vw;
		font-size: 1.05vmin;
		color: var(--color-text-muted);
	}

	.link {
		background: transparent;
		border: none;
		color: var(--color-primary-light);
		cursor: pointer;
		padding: 0;
		font-size: inherit;
	}

	.link:disabled {
		color: var(--color-text-muted);
		cursor: default;
	}

	.alert {
		border-radius: var(--radius);
		padding: 0.7vh 0.9vw;
		font-size: 1.05vmin;
	}

	.alert.warning {
		background: rgba(242, 181, 131, 0.12);
		color: var(--color-warning);
	}

	.grid {
		display: grid;
		grid-template-columns: 1fr 1fr;
		gap: 0.8vh 1vw;
	}

	.grid > div,
	.grid > button {
		display: flex;
		flex-direction: column;
		gap: 0.2vh;
	}

	.grid .full {
		grid-column: 1 / -1;
	}

	.grid button.clickable {
		background: transparent;
		border: none;
		text-align: left;
		cursor: pointer;
		padding: 0;
	}

	.k {
		font-size: 0.95vmin;
		color: var(--color-text-muted);
		text-transform: uppercase;
		letter-spacing: 0.03em;
	}

	.v {
		font-size: 1.1vmin;
	}

	.actions {
		display: flex;
		flex-wrap: wrap;
		gap: 0.5vw;
	}

	.btn {
		background: var(--color-bg-panel-alt);
		border: var(--border-subtle);
		border-radius: var(--radius);
		color: var(--color-surface-text);
		cursor: pointer;
		padding: 0.7vh 0.9vw;
		font-size: 1.05vmin;
	}

	.btn:hover {
		border-color: var(--color-primary);
		color: var(--color-nav-text-active);
	}

	label {
		display: flex;
		flex-direction: column;
		gap: 0.4vh;
		font-size: 1.05vmin;
		color: var(--color-text-muted);
	}

	label.row {
		flex-direction: row;
		align-items: center;
		gap: 0.6vw;
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

	.hint {
		color: var(--color-text-muted);
		font-size: 0.95vmin;
	}

	.qual-list {
		display: flex;
		flex-direction: column;
		gap: 0.4vh;
		max-height: 30vh;
		overflow-y: auto;
	}
</style>
