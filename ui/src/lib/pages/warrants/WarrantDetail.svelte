<script lang="ts">
	import Icon from '../../Icon.svelte';
	import Loader from '../../primitives/Loader.svelte';
	import Modal from '../../primitives/Modal.svelte';
	import { Nui } from '../../nui';
	import { appState, navigate, toast } from '../../store/app.svelte';
	import { formatDateTime } from '../../util/format';
	import type { Warrant } from '../../types';

	const WARRANT_STATES: { label: string; value: Warrant['state'] }[] = [
		{ label: 'Active', value: 'active' },
		{ label: 'Served', value: 'served' },
		{ label: 'Expired', value: 'expired' },
		{ label: 'Void', value: 'void' },
	];

	let { id }: { id: number | null } = $props();

	let warrant = $state<Warrant | null>(null);
	let loading = $state(false);

	async function load() {
		if (id === null) {
			warrant = null;
			return;
		}
		loading = true;
		const res = await Nui.viewWarrant(id);
		warrant = res || null;
		loading = false;
	}

	$effect(() => {
		load();
	});

	const inMdtContext = $derived(Boolean(appState.govJob?.Id));
	const canUpdateStatus = $derived(appState.govJob?.Id === 'police');
	const stateLabel = $derived(WARRANT_STATES.find((s) => s.value === warrant?.state)?.label ?? warrant?.state);

	let showUpdate = $state(false);
	let newState = $state<Warrant['state']>('served');

	function openUpdate() {
		newState = warrant?.state === 'active' ? 'void' : (warrant?.state ?? 'void');
		showUpdate = true;
	}

	async function submitUpdate() {
		if (!warrant) return;
		const ok = await Nui.updateWarrant(warrant.id, newState);
		if (ok) {
			toast.success('Warrant updated.');
			await load();
		} else toast.error('Failed to update warrant.');
		showUpdate = false;
	}
</script>

<div class="detail">
	{#if id === null}
		<div class="empty">
			<Icon name="file-signature" size="4vmin" />
			<p>No Warrant Selected</p>
		</div>
	{:else if loading}
		<Loader />
	{:else if !warrant}
		<div class="empty">
			<Icon name="file-signature" size="4vmin" />
			<p>Warrant Not Found</p>
		</div>
	{:else}
		<div class="scroll">
			<div class="header">
				<h2>{warrant.title}</h2>
				<div class="meta">
					<span>Issued At: {warrant.issued ? formatDateTime(warrant.issued) : 'Unknown'}</span>
					<span>Status: {stateLabel}</span>
					{#if warrant.state === 'active'}<span>Expires: {formatDateTime(warrant.expires)}</span>{/if}
				</div>
			</div>

			{#if warrant.suspectData}
				<section>
					<h3>Suspect</h3>
					<button type="button" class="link" onclick={() => navigate('people', { person: String(warrant!.suspectData!.SID) })}>
						{warrant.suspectData.First} {warrant.suspectData.Last} ({warrant.suspectData.SID})
					</button>
				</section>
			{/if}

			{#if inMdtContext}
				<section>
					<h3>Issuing Officer</h3>
					<p>[{warrant.creatorCallsign}] {warrant.creatorName} ({warrant.creatorSID})</p>
				</section>

				{#if warrant.report}
					<section>
						<h3>Report</h3>
						<button type="button" class="link" onclick={() => navigate('reports', { report: String(warrant!.report), mode: 'view' })}>
							Report #{warrant.report}
						</button>
					</section>
				{/if}

				{#if warrant.notes}
					<section>
						<h3>Warrant Notes</h3>
						<p class="notes">{warrant.notes}</p>
					</section>
				{/if}

				{#if canUpdateStatus}
					<button type="button" class="btn" onclick={openUpdate}>Update Status</button>
				{/if}
			{/if}
		</div>
	{/if}
</div>

{#if warrant}
	<Modal showing={showUpdate} title="Update Warrant" onAccept={submitUpdate} onClose={() => (showUpdate = false)}>
		<label>
			State
			<select bind:value={newState}>
				{#each WARRANT_STATES.filter((s) => s.value !== 'active') as s (s.value)}
					<option value={s.value}>{s.label}</option>
				{/each}
			</select>
		</label>
		<p class="hint">A warrant state cannot be changed back to active once changed, a new warrant will have to be issued.</p>
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

	.header h2 {
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

	section h3 {
		margin: 0 0 0.4vh;
		font-size: 1.15vmin;
		text-transform: uppercase;
		letter-spacing: 0.03em;
		color: var(--color-text-muted);
	}

	section p {
		margin: 0;
		font-size: 1.1vmin;
	}

	.notes {
		white-space: pre-wrap;
	}

	.link {
		background: transparent;
		border: none;
		color: var(--color-primary-light);
		cursor: pointer;
		padding: 0;
		font-size: 1.1vmin;
	}

	.btn {
		align-self: flex-start;
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
</style>
