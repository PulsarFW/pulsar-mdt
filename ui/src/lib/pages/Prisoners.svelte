<script lang="ts">
	import Icon from '../Icon.svelte';
	import Loader from '../primitives/Loader.svelte';
	import Modal from '../primitives/Modal.svelte';
	import Pagination from '../primitives/Pagination.svelte';
	import { Nui } from '../nui';
	import { navigate, toast } from '../store/app.svelte';
	import { PRISONERS_PER_PAGE } from '../../config';
	import { formatDateTime } from '../util/format';
	import type { Prisoner } from '../types';

	let prisoners = $state<Prisoner[]>([]);
	let loading = $state(true);
	let search = $state('');
	let page = $state(1);

	async function load() {
		loading = true;
		prisoners = await Nui.docGetPrisoners();
		loading = false;
	}

	$effect(() => {
		load();
	});

	const filtered = $derived.by(() => {
		const term = search.trim().toLowerCase();
		if (!term) return prisoners;
		const asSid = parseInt(term, 10);
		return prisoners.filter((p) => `${p.First} ${p.Last}`.toLowerCase().includes(term) || p.SID === asSid);
	});
	const pages = $derived(Math.max(1, Math.ceil(filtered.length / PRISONERS_PER_PAGE)));
	const pageItems = $derived(filtered.slice((page - 1) * PRISONERS_PER_PAGE, page * PRISONERS_PER_PAGE));

	function remainingMinutes(p: Prisoner): number {
		return Math.max(0, Math.ceil((p.Jailed.Release - Date.now() / 1000) / 60));
	}

	// ---- Reduction modal ----
	let reducing = $state<Prisoner | null>(null);
	let reductionAmount = $state('');

	function openReduction(p: Prisoner) {
		reducing = p;
		reductionAmount = '';
	}

	async function submitReduction() {
		if (!reducing) return;
		const amount = parseInt(reductionAmount, 10);
		const remaining = Math.floor(remainingMinutes(reducing));
		if (Number.isNaN(amount) || amount <= 0 || amount > 100) {
			toast.error('Invalid Reduction');
			return;
		}
		if (amount > remaining) {
			toast.error('Cannot Reduce More than the Remaining Sentence');
			return;
		}
		const ok = await Nui.docReduceSentence(reducing.SID, amount);
		if (ok) {
			toast.success('Prisoner Sentence Updated');
			reducing = null;
			await load();
		} else toast.error('Failed to update sentence.');
	}
</script>

<div class="page">
	<div class="panel">
		<form class="bar" onsubmit={(e) => e.preventDefault()}>
			<input type="text" placeholder="Search by name or state ID" bind:value={search} />
			<Icon name="magnifying-glass" size="1.1vmin" />
		</form>

		<div class="results">
			{#if loading}
				<Loader />
			{:else if pageItems.length === 0}
				<p class="hint">No Prisoners Awake</p>
			{:else}
				{#each pageItems as prisoner (prisoner.SID)}
					<div class="row">
						<button type="button" class="info" onclick={() => navigate('people', { person: String(prisoner.SID) })}>
							<span class="name">{prisoner.First} {prisoner.Last} (State ID: {prisoner.SID})</span>
							<small>{Math.floor(remainingMinutes(prisoner))} min remaining of {prisoner.Jailed.Duration} min sentence</small>
							<small>Sentenced At: {formatDateTime(prisoner.Jailed.Time * 1000)} - Release: {formatDateTime(prisoner.Jailed.Release * 1000)}</small>
							<small>Current DOC Reductions: {prisoner.Jailed.Reduced ?? 0} min</small>
						</button>
						<button type="button" class="icon-btn" title="Reduce Sentence" onclick={() => openReduction(prisoner)}>
							<Icon name="check" size="1.1vmin" />
						</button>
					</div>
				{/each}
			{/if}
		</div>

		<Pagination {page} {pages} onChange={(p) => (page = p)} />
	</div>
</div>

{#if reducing}
	<Modal showing={Boolean(reducing)} title={`Reduce Sentence: ${reducing.First} ${reducing.Last}`} acceptLabel="Reduce" onAccept={submitReduction} onClose={() => (reducing = null)}>
		<label>Reduction Amount (minutes)<input type="text" bind:value={reductionAmount} /></label>
	</Modal>
{/if}

<style>
	.page {
		height: 100%;
		padding: 1vh 1vw;
	}

	.panel {
		height: 100%;
		display: flex;
		flex-direction: column;
		background: var(--color-bg-panel);
		border-radius: var(--radius);
		overflow: hidden;
	}

	.bar {
		flex-shrink: 0;
		display: flex;
		align-items: center;
		gap: 0.5vw;
		padding: 0.8vh 0.8vw;
		border-bottom: var(--border-subtle);
		color: var(--color-text-muted);
	}

	.bar input {
		flex: 1;
		background: var(--color-bg);
		border: var(--border-subtle);
		border-radius: var(--radius);
		color: var(--color-text);
		padding: 0.7vh 0.7vw;
		font-size: 1.1vmin;
	}

	.results {
		flex: 1;
		min-height: 0;
		overflow-y: auto;
		padding: 0.6vh 0.6vw;
		display: flex;
		flex-direction: column;
		gap: 0.4vh;
	}

	.hint {
		color: var(--color-text-muted);
		font-size: 1.1vmin;
		text-align: center;
		margin-top: 2vh;
	}

	.row {
		display: flex;
		align-items: center;
		gap: 0.5vw;
		background: var(--color-bg-panel-alt);
		border-radius: var(--radius);
		padding: 0.2vh 0.5vw;
	}

	.info {
		flex: 1;
		display: flex;
		flex-direction: column;
		min-width: 0;
		background: transparent;
		border: none;
		text-align: left;
		cursor: pointer;
		color: var(--color-surface-text);
		padding: 0.5vh 0.2vw;
	}

	.name {
		font-size: 1.1vmin;
		font-weight: 600;
	}

	.info small {
		color: var(--color-surface-text-muted);
		font-size: 0.9vmin;
	}

	.icon-btn {
		flex-shrink: 0;
		background: transparent;
		border: var(--border-subtle);
		border-radius: var(--radius);
		color: var(--color-surface-text-muted);
		cursor: pointer;
		padding: 0.5vh 0.7vw;
		display: flex;
	}

	.icon-btn:hover {
		color: var(--color-primary-light);
	}

	label {
		display: flex;
		flex-direction: column;
		gap: 0.4vh;
		font-size: 1.05vmin;
		color: var(--color-text-muted);
	}

	input {
		background: var(--color-bg);
		border: var(--border-subtle);
		border-radius: var(--radius);
		color: var(--color-text);
		padding: 0.7vh 0.7vw;
		font-size: 1.1vmin;
	}
</style>
