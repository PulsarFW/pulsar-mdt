<script lang="ts">
	import Icon from '../../Icon.svelte';
	import Modal from '../../primitives/Modal.svelte';
	import { Nui } from '../../nui';
	import { appState, navigate, toast } from '../../store/app.svelte';
	import { dataState } from '../../store/data.svelte';
	import { REDUCTION_TYPES, PAROLE_MULTIPLIER } from '../../../config';
	import { CURRENCY } from '../../util/format';
	import type { ReportSuspect } from '../../types';

	let {
		data,
		reportId,
		overturned = false,
		refresh,
	}: {
		data: ReportSuspect;
		reportId: number;
		overturned?: boolean;
		refresh?: () => void;
	} = $props();

	const isSystemAdmin = $derived(Boolean(appState.user?.MDTSystemAdmin));
	const canOverturn = $derived((Boolean(appState.govJobPermissions['DOJ_OVERTURN_CHARGES']) || isSystemAdmin) && !overturned);

	const resolved = $derived(
		data.charges.map((s) => ({ charge: dataState.charges.find((c) => c.id === s.id), count: s.count })).filter((x): x is { charge: NonNullable<typeof x.charge>; count: number } => Boolean(x.charge)),
	);
	const months = $derived(resolved.reduce((a, { charge }) => a + (charge.jail || 0), 0));
	const fineTotal = $derived(resolved.reduce((a, { charge, count }) => a + (charge.fine ? charge.fine * count : 0), 0));
	const pointsTotal = $derived(resolved.reduce((a, { charge, count }) => a + (charge.points ? charge.points * count : 0), 0));
	const isFelony = $derived(resolved.some(({ charge }) => charge.type > 2));
	const isInfraction = $derived(!resolved.some(({ charge }) => charge.type > 1));

	// ---- Sentencing modal ----
	let sentenceOpen = $state(false);
	let sentenceType = $state<'months' | 'fine' | false>(false);
	let sentenceValue = $state(0);
	let revokeDrivers = $state(false);
	let revokeWeapons = $state(false);
	let revokeHunting = $state(false);
	let revokeFishing = $state(false);
	let requestDoc = $state(false);

	function openSentence() {
		sentenceType = false;
		sentenceValue = 0;
		revokeDrivers = (data.Licenses?.Drivers?.Points ?? 0) + pointsTotal >= (appState.pointBreakpoints.license ?? 12) && Boolean(data.Licenses?.Drivers?.Active);
		revokeWeapons = false;
		revokeHunting = false;
		revokeFishing = false;
		requestDoc = false;
		sentenceOpen = true;
	}

	function calcJail() {
		const base = sentenceType === 'months' ? Math.round(months * (1 - sentenceValue / 100)) : months;
		return Math.ceil(base);
	}
	function calcFine() {
		const base = sentenceType === 'fine' ? fineTotal * (1 - sentenceValue / 100) : fineTotal;
		return Math.ceil(base);
	}
	function calcParoleTotal() {
		return Math.ceil(calcJail() * PAROLE_MULTIPLIER);
	}

	async function submitSentence() {
		if (data.sentenced) return;
		const jail = calcJail();
		const fine = calcFine();
		const points = pointsTotal;
		const paroleTotal = calcParoleTotal();
		const payload = {
			report: reportId,
			data,
			jail,
			fine,
			points,
			parole: !isInfraction
				? {
						end: Math.floor(Date.now() / 1000) + paroleTotal * 60,
						total: paroleTotal,
						parole: Math.ceil(jail * (PAROLE_MULTIPLIER - 1)),
						sentence: jail,
						fine,
					}
				: null,
			sentence: {
				type: sentenceType,
				value: sentenceValue,
				revoke: { drivers: revokeDrivers, weapons: revokeWeapons, hunting: revokeHunting, fishing: revokeFishing },
				doc: requestDoc,
			},
		};
		const ok = await Nui.sentencePlayer(payload);
		if (ok) {
			toast.success('Sentenced Successfully');
			refresh?.();
		} else toast.error('Unable to Sentence');
		sentenceOpen = false;
	}

	// ---- Warrant modal ----
	let warrantOpen = $state(false);
	let warrantNotes = $state('');

	async function submitWarrant() {
		const ok = await Nui.issueWarrant(reportId, data, warrantNotes);
		if (ok) {
			toast.success('Warrant Created');
			warrantOpen = false;
			warrantNotes = '';
			refresh?.();
		} else toast.error('Failed to create warrant.');
	}

	// ---- Overturn modal ----
	let overturnOpen = $state(false);

	async function submitOverturn() {
		const ok = await Nui.overturnSentence(reportId, data.SID);
		if (ok) {
			toast.success('Suspect Charges Overturned');
			refresh?.();
		} else toast.error('Failed to overturn charges.');
		overturnOpen = false;
	}
</script>

<div class="suspect">
	<div class="head">
		<button type="button" class="link" onclick={() => navigate('people', { person: String(data.SID) })}>{data.First} {data.Last}</button>
		<span class="plea">{data.plea}</span>

		<div class="actions">
			{#if !data.sentenced}
				{#if data.warrant}
					<button type="button" class="icon-btn" title="View Warrant" onclick={() => navigate('warrants', { id: String(data.warrant) })}>
						<Icon name="file-signature" size="1.1vmin" />
					</button>
				{:else}
					<button type="button" class="icon-btn" title="Issue Warrant" disabled={isInfraction} onclick={() => (warrantOpen = true)}>
						<Icon name="file-signature" size="1.1vmin" />
					</button>
				{/if}
				<button type="button" class="btn" onclick={openSentence}>Charge {data.First} {data.Last}</button>
			{:else}
				<span class="badge">{overturned ? 'Overturned' : 'Sentenced'}</span>
				{#if canOverturn}
					<button type="button" class="icon-btn" title="Overturn Charges" onclick={() => (overturnOpen = true)}>
						<Icon name="scale-balanced" size="1.1vmin" />
					</button>
				{/if}
			{/if}
		</div>
	</div>

	<div class="chips">
		{#each resolved as { charge, count } (charge.id)}
			<span class="chip type-{charge.type}">{charge.title} x{count}</span>
		{/each}
	</div>

	{#if data.sentenced}
		<div class="post-flags">
			{#if data.doc}<span class="flag">DOC Transport</span>{/if}
			{#if data.revoked?.weapons}<span class="flag">Permit Revoked</span>{/if}
			{#if data.revoked?.drivers}<span class="flag">License Revoked</span>{/if}
			{#if data.reduction?.type}<span class="flag">Reduction of {data.reduction.value}%</span>{/if}
		</div>
		<div class="summary">
			<span>Months: {data.jail ?? 0}{data.reduction?.type === 'months' ? ` (-${data.reduction.value}%)` : ''}</span>
			<span>Fine: {CURRENCY.format(data.fine ?? 0)}{data.reduction?.type === 'fine' ? ` (-${data.reduction.value}%)` : ''}</span>
			<span>Points: {data.points ?? 0}</span>
		</div>
	{:else}
		<div class="summary">
			<span>Months: {months}</span>
			<span>Fine: {CURRENCY.format(fineTotal)}</span>
			<span>Points: {pointsTotal}</span>
		</div>
	{/if}
</div>

<Modal showing={sentenceOpen} title={`Sentence ${data.First} ${data.Last}`} acceptLabel="Sentence" onAccept={submitSentence} onClose={() => (sentenceOpen = false)}>
	{#if !isInfraction}
		<div class="preview">
			<span>Months: {calcJail()}</span>
			<span>Parole: {calcParoleTotal()}</span>
			<span>Fine: {CURRENCY.format(calcFine())}</span>
			<span>Points: {pointsTotal}</span>
		</div>
		<label>
			Reduction Type
			<select bind:value={sentenceType}>
				<option value={false}>No Reduction</option>
				{#each REDUCTION_TYPES as r (r.value)}
					<option value={r.value}>{r.label}</option>
				{/each}
			</select>
		</label>
		<label>
			Reduction Percent
			<input type="number" min="0" max={appState.pointBreakpoints.reduction} bind:value={sentenceValue} disabled={sentenceType === false} />
		</label>
	{:else}
		<div class="preview">
			<span>Fine: {CURRENCY.format(calcFine())}</span>
			<span>Points: {pointsTotal}</span>
		</div>
	{/if}

	<label class="row">
		<input type="checkbox" bind:checked={revokeDrivers} disabled={(data.Licenses?.Drivers?.Points ?? 0) + pointsTotal < (appState.pointBreakpoints.license ?? 12) || !data.Licenses?.Drivers?.Active} />
		Revoke Driver's License
	</label>
	{#if !isInfraction}
		<label class="row">
			<input type="checkbox" bind:checked={revokeWeapons} disabled={data.Licenses?.Weapons?.Suspended || !isFelony} />
			Revoke Weapons License
		</label>
	{/if}
	<label class="row">
		<input type="checkbox" bind:checked={revokeHunting} disabled={data.Licenses?.Hunting?.Suspended} />
		Revoke Hunting License
	</label>
	<label class="row">
		<input type="checkbox" bind:checked={revokeFishing} disabled={data.Licenses?.Fishing?.Suspended} />
		Revoke Fishing License
	</label>
	{#if !isInfraction}
		<label class="row"><input type="checkbox" bind:checked={requestDoc} /> Requested DOC Transport?</label>
	{/if}

	<p class="warn">Once sentenced, the charges brought upon {data.First} {data.Last} cannot be edited or removed.</p>
</Modal>

<Modal showing={warrantOpen} title={`Issue Arrest Warrant For ${data.First} ${data.Last}`} acceptLabel="Create Warrant" onAccept={submitWarrant} onClose={() => (warrantOpen = false)}>
	<label>Suspect<input type="text" value={`${data.First} ${data.Last} (${data.SID})`} disabled /></label>
	<label>Expires<input type="text" value={new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toLocaleString()} disabled /></label>
	<label>Warrant Notes<textarea rows="6" bind:value={warrantNotes}></textarea></label>
</Modal>

<Modal showing={overturnOpen} title={`Overturn Charges For ${data.First} ${data.Last}`} acceptLabel="Overturn Charges" onAccept={submitOverturn} onClose={() => (overturnOpen = false)}>
	<p>Are you sure you want to overturn these charges? This cannot be reversed.</p>
</Modal>

<style>
	.suspect {
		background: var(--color-bg);
		border: var(--border-subtle);
		border-radius: var(--radius);
		padding: 0.8vh 0.9vw;
		display: flex;
		flex-direction: column;
		gap: 0.5vh;
	}

	.head {
		display: flex;
		align-items: center;
		gap: 0.6vw;
		flex-wrap: wrap;
	}

	.link {
		background: transparent;
		border: none;
		color: var(--color-primary-light);
		cursor: pointer;
		font-size: 1.1vmin;
		font-weight: 600;
		padding: 0;
	}

	.plea {
		color: var(--color-text-muted);
		font-size: 1vmin;
		text-transform: capitalize;
	}

	.actions {
		margin-left: auto;
		display: flex;
		align-items: center;
		gap: 0.4vw;
	}

	.btn {
		background: var(--color-bg-panel-alt);
		border: var(--border-subtle);
		border-radius: var(--radius);
		color: var(--color-surface-text);
		cursor: pointer;
		padding: 0.5vh 0.8vw;
		font-size: 1vmin;
	}

	.btn:hover {
		border-color: var(--color-primary);
		color: var(--color-nav-text-active);
	}

	.icon-btn {
		background: transparent;
		border: var(--border-subtle);
		border-radius: var(--radius);
		color: var(--color-text-muted);
		cursor: pointer;
		padding: 0.4vh 0.6vw;
		display: flex;
	}

	.icon-btn:hover:not(:disabled) {
		color: var(--color-primary-light);
	}

	.icon-btn:disabled {
		opacity: 0.4;
		cursor: not-allowed;
	}

	.badge {
		font-size: 0.95vmin;
		color: var(--color-text-muted);
	}

	.chips {
		display: flex;
		flex-wrap: wrap;
		gap: 0.4vh;
	}

	.chip {
		background: rgba(139, 92, 246, 0.15);
		color: var(--color-primary-light);
		border-radius: var(--radius);
		padding: 0.3vh 0.6vw;
		font-size: 0.95vmin;
	}

	.chip.type-3 {
		background: rgba(161, 52, 52, 0.2);
		color: #e88;
	}

	.post-flags {
		display: flex;
		flex-wrap: wrap;
		gap: 0.4vh;
	}

	.flag {
		background: rgba(242, 181, 131, 0.15);
		color: var(--color-warning);
		border-radius: var(--radius);
		padding: 0.3vh 0.6vw;
		font-size: 0.9vmin;
	}

	.summary {
		display: flex;
		gap: 1vw;
		font-size: 0.95vmin;
		color: var(--color-text-muted);
	}

	.preview {
		display: flex;
		gap: 1vw;
		font-size: 1.05vmin;
		background: var(--color-bg-panel-alt);
		border-radius: var(--radius);
		padding: 0.6vh 0.7vw;
		color: var(--color-surface-text);
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
	select,
	textarea {
		background-color: var(--color-bg);
		border: var(--border-subtle);
		border-radius: var(--radius);
		color: var(--color-text);
		padding: 0.6vh 0.7vw;
		font-size: 1.05vmin;
		font-family: inherit;
	}

	.warn {
		color: var(--color-warning);
		font-size: 0.95vmin;
	}
</style>
