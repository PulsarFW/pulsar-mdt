<script lang="ts">
	import Icon from '../../Icon.svelte';
	import Loader from '../../primitives/Loader.svelte';
	import Modal from '../../primitives/Modal.svelte';
	import { Nui } from '../../nui';
	import { appState, navigate, toast } from '../../store/app.svelte';
	import { dataState } from '../../store/data.svelte';
	import { formatDate, formatDateTime } from '../../util/format';
	import type { PersonViewResult } from '../../types';

	let { sid }: { sid: number | null } = $props();

	let result = $state<PersonViewResult | null>(null);
	let loading = $state(false);

	$effect(() => {
		if (sid === null) {
			result = null;
			return;
		}
		loading = true;
		Nui.viewPerson(sid).then((res) => {
			result = res || null;
			loading = false;
		});
	});

	const person = $derived(result?.data ?? null);
	const myJob = $derived(appState.govJob);
	const isSystemAdmin = $derived(Boolean(appState.user?.MDTSystemAdmin));
	const inMdtContext = $derived(myJob?.Id === 'police' || myJob?.Id === 'government');
	const canViewVehicles = $derived(myJob?.Id === 'police' || (myJob?.Id === 'government' && myJob.Workplace?.Id !== 'publicdefenders'));

	function hasPerm(permission?: string): boolean {
		if (!permission) return true;
		return Boolean(appState.govJobPermissions[permission]) || isSystemAdmin;
	}

	const govJobEntries = $derived((person?.Jobs ?? []).filter((j) => dataState.governmentJobs.includes(j.Id)));
	const employmentEntries = $derived((person?.Jobs ?? []).filter((j) => !dataState.governmentJobs.includes(j.Id) && !j.Hidden));

	const prevConvictions = $derived.by(() => {
		const counts = new Map<number, number>();
		for (const c of result?.convictions ?? []) {
			counts.set(c.id, (counts.get(c.id) ?? 0) + (c.count ?? 1));
		}
		return Array.from(counts.entries())
			.map(([id, count]) => ({ charge: dataState.charges.find((ch) => ch.id === id), count }))
			.filter((x): x is { charge: NonNullable<typeof x.charge>; count: number } => Boolean(x.charge))
			.sort((a, b) => b.charge.jail + b.charge.fine - (a.charge.jail + a.charge.fine));
	});

	const activeLicenses = $derived(
		Object.entries(person?.Licenses ?? {}).filter(([, entry]) => entry && (entry.Active || entry.Suspended)),
	);

	const monthsRemainingParole = $derived.by(() => {
		if (!result?.parole || result.parole.end <= Date.now()) return 0;
		return Math.ceil((result.parole.end - Date.now()) / (1000 * 60 * 60 * 24 * 30));
	});

	// ---- modal state ----
	let modal = $state<'mugshot' | 'flags' | 'certs' | 'suspensions' | 'points' | 'expunge' | 'logs' | null>(null);

	let mugshotUrl = $state('');
	let flagViolent = $state(false);
	let flagGang = $state('');
	let attorneyChecked = $state(false);
	let unsuspend = $state<Record<string, boolean>>({});
	let pointsToRemove = $state(1);
	let expungeConfirm = $state(false);

	function openModal(which: NonNullable<typeof modal>) {
		if (!person) return;
		if (which === 'mugshot') mugshotUrl = person.Mugshot ?? '';
		if (which === 'flags') {
			flagViolent = Boolean(person.Flags?.Violent);
			flagGang = person.Flags?.Gang ?? '';
		}
		if (which === 'certs') attorneyChecked = Boolean(person.Attorney);
		if (which === 'suspensions') {
			unsuspend = {};
			for (const [key, entry] of Object.entries(person.Licenses ?? {})) {
				if (entry?.Suspended) unsuspend[key] = true;
			}
		}
		if (which === 'points') pointsToRemove = 1;
		if (which === 'expunge') expungeConfirm = false;
		modal = which;
	}

	async function saveMugshot() {
		if (!person) return;
		const ok = await Nui.updatePerson(person.SID, 'Mugshot', mugshotUrl);
		if (ok) {
			person.Mugshot = mugshotUrl;
			toast.success('Mugshot updated.');
		} else toast.error('Failed to update mugshot.');
		modal = null;
	}

	async function saveFlags() {
		if (!person) return;
		const flags = { Violent: flagViolent, Gang: flagGang };
		const ok = await Nui.updatePerson(person.SID, 'Flags', flags);
		if (ok) {
			person.Flags = flags;
			toast.success('Flags updated.');
		} else toast.error('Failed to update flags.');
		modal = null;
	}

	async function saveCerts() {
		if (!person) return;
		const ok = await Nui.updatePerson(person.SID, 'Attorney', attorneyChecked);
		if (ok) {
			person.Attorney = attorneyChecked;
			toast.success('Bar certification updated.');
		} else toast.error('Failed to update.');
		modal = null;
	}

	async function saveSuspensions() {
		if (!person) return;
		const toRevoke: Record<string, boolean> = {};
		for (const [key, wasSuspended] of Object.entries(unsuspend)) {
			if (!wasSuspended) toRevoke[key] = true;
		}
		const licenses = await Nui.revokeSuspension(person.SID, toRevoke);
		if (licenses) {
			person.Licenses = licenses;
			toast.success('License suspensions updated.');
		} else toast.error('Failed to update suspensions.');
		modal = null;
	}

	async function savePoints() {
		if (!person?.Licenses?.Drivers) return;
		const newPoints = person.Licenses.Drivers.Points! - pointsToRemove;
		if (newPoints < 0) return;
		const licenses = await Nui.removePoints(person.SID, newPoints);
		if (licenses) {
			person.Licenses = licenses;
			toast.success('License points updated.');
		} else toast.error('Failed to update points.');
		modal = null;
	}

	async function saveExpunge() {
		if (!person || !expungeConfirm) {
			toast.error('Confirmation required.');
			return;
		}
		const ok = await Nui.clearRecord(person.SID);
		if (ok) {
			result = result ? { ...result, convictions: [] } : result;
			toast.success('Criminal record expunged.');
		} else toast.error('Failed to expunge record.');
		modal = null;
	}
</script>

<div class="detail">
	{#if sid === null}
		<div class="empty">
			<Icon name="user-large" size="4vmin" />
			<p>No Person Selected</p>
		</div>
	{:else if loading}
		<Loader />
	{:else if !person}
		<div class="empty">
			<Icon name="user-large" size="4vmin" />
			<p>Person Not Found</p>
		</div>
	{:else}
		<div class="scroll">
			<div class="header">
				<div class="avatar">
					{#if person.Mugshot}
						<img src={person.Mugshot} alt="" />
					{:else}
						<Icon name="user-large" size="2.4vmin" />
					{/if}
				</div>
				<div class="identity">
					<h2>{person.First} {person.Last}</h2>
					<div class="meta">
						<span>State ID: {person.SID}</span>
						<span>{person.Gender === 1 ? 'Female' : 'Male'}</span>
						<span>DOB: {formatDate(person.DOB)}</span>
						{#if person.Attorney}<span class="badge">Bar Certified Attorney</span>{/if}
					</div>
					<div class="meta">
						<span>Violent: {person.Flags?.Violent ? 'Yes' : 'No'}</span>
						<span>Gang Affiliation: {person.Flags?.Gang || 'None'}</span>
					</div>
					{#if monthsRemainingParole > 0}
						<div class="alert info">Has {monthsRemainingParole} Month(s) of Parole Remaining</div>
					{/if}
				</div>
			</div>

			{#if inMdtContext}
				<div class="actions">
					{#if myJob?.Id === 'police'}
						<button type="button" class="btn" onclick={() => openModal('flags')}>Flags</button>
						<button type="button" class="btn" disabled={dataState.governmentJobs.some((j) => person!.Jobs?.some((pj) => pj.Id === j))} onclick={() => openModal('mugshot')}>Mugshot</button>
					{/if}
					<button type="button" class="btn" onclick={() => navigate('reports', { search: `suspect: ${person.SID}` })}>Related Incident Reports</button>
					<button type="button" class="btn" onclick={() => navigate('reports', { mode: 'create', addSuspect: String(person.SID) })}>Create Incident</button>
					{#if hasPerm('BAR_CERTIFICATIONS')}
						<button type="button" class="btn" onclick={() => openModal('certs')}>Certs</button>
					{/if}
					{#if hasPerm('REVOKE_LICENSE_SUSPENSIONS')}
						<button type="button" class="btn" onclick={() => openModal('suspensions')}>Suspensions</button>
						<button type="button" class="btn" disabled={(person.Licenses?.Drivers?.Points ?? 0) <= 0} onclick={() => openModal('points')}>Points</button>
					{/if}
					{#if hasPerm('EXPUNGEMENT')}
						<button type="button" class="btn" onclick={() => openModal('expunge')}>Expunge</button>
					{/if}
					{#if isSystemAdmin}
						<button type="button" class="btn" onclick={() => openModal('logs')}>Logs</button>
					{/if}
				</div>
			{/if}

			{#if canViewVehicles && result && result.vehicles.length > 0}
				<section>
					<h3>Owned Vehicles</h3>
					<div class="chips">
						{#each result.vehicles as v (v.VIN)}
							<button type="button" class="chip" onclick={() => navigate('vehicles', { vin: v.VIN })}>
								{v.Make} {v.Model} - {v.RegisteredPlate}
							</button>
						{/each}
					</div>
				</section>
			{/if}

			{#if govJobEntries.length > 0}
				<section>
					<h3>Government Employee</h3>
					<div class="chips">
						{#each govJobEntries as job (job.Id)}
							<span class="chip static">{job.Workplace?.Name ?? job.Name} - {job.Grade.Name}</span>
						{/each}
					</div>
				</section>
			{/if}

			{#if employmentEntries.length > 0}
				<section>
					<h3>Employment Information</h3>
					<div class="chips">
						{#each employmentEntries as job (job.Id)}
							<span class="chip static">
								{#if result?.ownedBusinesses.includes(job.Id)}<Icon name="shield-halved" size="0.9vmin" />{/if}
								{job.Workplace?.Name ?? job.Name} - {job.Grade?.Name ?? 'Employee'}
							</span>
						{/each}
					</div>
				</section>
			{/if}

			<section>
				<h3>Criminal Record</h3>
				{#if prevConvictions.length === 0}
					<div class="alert info">{person.First} {person.Last} Has No Past Convictions</div>
				{:else}
					<div class="chips">
						{#each prevConvictions as { charge, count } (charge.id)}
							<span class="chip static type-{charge.type}">{charge.title} x{count}</span>
						{/each}
					</div>
				{/if}
			</section>

			{#if activeLicenses.length > 0}
				<section>
					<h3>Licenses</h3>
					<div class="license-list">
						{#each activeLicenses as [name, entry] (name)}
							<div class="license-row">
								<span>{name} License</span>
								<span class:suspended={entry!.Suspended}>
									{entry!.Suspended ? 'Suspended' : 'Active'}{entry!.Points ? ` - ${entry!.Points} Points` : ''}
								</span>
							</div>
						{/each}
					</div>
				</section>
			{/if}
		</div>
	{/if}
</div>

{#if person}
	<Modal showing={modal === 'mugshot'} title="Update Mugshot" onAccept={saveMugshot} onClose={() => (modal = null)}>
		<label>Image URL<input type="text" bind:value={mugshotUrl} /></label>
	</Modal>

	<Modal showing={modal === 'flags'} title="Update Flags" onAccept={saveFlags} onClose={() => (modal = null)}>
		<label class="row"><input type="checkbox" bind:checked={flagViolent} /> Violent</label>
		<label>Gang Affiliation<input type="text" bind:value={flagGang} /></label>
	</Modal>

	<Modal showing={modal === 'certs'} title="Bar Certification" onAccept={saveCerts} onClose={() => (modal = null)}>
		<label class="row"><input type="checkbox" bind:checked={attorneyChecked} /> Bar Certified Attorney</label>
	</Modal>

	<Modal showing={modal === 'suspensions'} title="License Suspensions" onAccept={saveSuspensions} onClose={() => (modal = null)}>
		{#each Object.entries(person.Licenses ?? {}).filter(([, e]) => e?.Suspended) as [name] (name)}
			<label class="row"><input type="checkbox" bind:checked={unsuspend[name]} /> {name} License Active (uncheck to revoke)</label>
		{/each}
	</Modal>

	<Modal showing={modal === 'points'} title="Remove Driver License Points" onAccept={savePoints} onClose={() => (modal = null)}>
		<label>
			Points to Remove: {pointsToRemove}
			<input type="range" min="1" max={person.Licenses?.Drivers?.Points ?? 1} bind:value={pointsToRemove} />
		</label>
	</Modal>

	<Modal showing={modal === 'expunge'} title="Criminal Record Expungement" onAccept={saveExpunge} onClose={() => (modal = null)}>
		<label class="row"><input type="checkbox" bind:checked={expungeConfirm} /> I confirm I want to expunge this record</label>
	</Modal>

	<Modal showing={modal === 'logs'} title="System Logs" acceptLabel="Close" onAccept={() => (modal = null)} onClose={() => (modal = null)}>
		{#if (person.MDTHistory ?? []).length === 0}
			<p class="hint">No system logs.</p>
		{:else}
			{#each [...(person.MDTHistory ?? [])].sort((a, b) => b.Time - a.Time) as h, i (i)}
				<div class="log-row">
					<span>{h.Log}</span>
					<small>{h.Char > -1 ? `SID ${h.Char}` : 'System'} | {formatDateTime(h.Time)}</small>
				</div>
			{/each}
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
		gap: 1vw;
		align-items: flex-start;
	}

	.avatar {
		flex-shrink: 0;
		width: 7vh;
		height: 7vh;
		border-radius: var(--radius);
		background: var(--color-bg);
		display: flex;
		align-items: center;
		justify-content: center;
		overflow: hidden;
		color: var(--color-text-muted);
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
		margin-bottom: 0.3vh;
	}

	.badge {
		color: var(--color-primary-light);
	}

	.alert {
		border-radius: var(--radius);
		padding: 0.7vh 0.9vw;
		font-size: 1.05vmin;
	}

	.alert.info {
		background: rgba(91, 163, 224, 0.12);
		color: var(--color-info);
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

	.btn:hover:not(:disabled) {
		border-color: var(--color-primary);
		color: var(--color-nav-text-active);
	}

	.btn:disabled {
		opacity: 0.4;
		cursor: not-allowed;
	}

	section h3 {
		margin: 0 0 0.6vh;
		font-size: 1.15vmin;
		text-transform: uppercase;
		letter-spacing: 0.03em;
		color: var(--color-text-muted);
	}

	.chips {
		display: flex;
		flex-wrap: wrap;
		gap: 0.5vh;
	}

	.chip {
		display: inline-flex;
		align-items: center;
		gap: 0.4vw;
		background: rgba(139, 92, 246, 0.15);
		color: var(--color-primary-light);
		border: none;
		border-radius: var(--radius);
		padding: 0.5vh 0.8vw;
		font-size: 1.05vmin;
		cursor: pointer;
	}

	.chip.static {
		cursor: default;
	}

	.chip.type-3 {
		background: rgba(161, 52, 52, 0.2);
		color: #e88;
	}

	.license-list,
	.log-row {
		display: flex;
		flex-direction: column;
		gap: 0.4vh;
	}

	.license-row {
		display: flex;
		justify-content: space-between;
		font-size: 1.05vmin;
		padding: 0.4vh 0;
		border-bottom: var(--border-subtle);
	}

	.suspended {
		color: var(--color-error);
	}

	.log-row {
		padding: 0.6vh 0;
		border-bottom: var(--border-subtle);
	}

	.log-row small {
		color: var(--color-text-muted);
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

	label input[type='text'] {
		background: var(--color-bg);
		border: var(--border-subtle);
		border-radius: var(--radius);
		color: var(--color-text);
		padding: 0.7vh 0.7vw;
		font-size: 1.1vmin;
	}

	.hint {
		color: var(--color-text-muted);
		font-size: 1.05vmin;
	}
</style>
