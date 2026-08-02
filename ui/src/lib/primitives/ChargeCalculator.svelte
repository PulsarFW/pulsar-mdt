<script lang="ts">
	import Icon from '../Icon.svelte';
	import Modal from './Modal.svelte';
	import { dataState } from '../store/data.svelte';
	import { CURRENCY } from '../util/format';
	import type { Charge, SuspectCharge } from '../types';

	let { selected = $bindable([]) }: { selected: SuspectCharge[] } = $props();

	let search = $state('');
	let detailsCharge = $state<Charge | null>(null);

	const filtered = $derived(
		dataState.charges
			.filter((c) => c.title.toLowerCase().includes(search.toLowerCase()))
			.sort((a, b) => a.type - b.type || a.jail - b.jail || a.fine - b.fine),
	);

	const selectedCharges = $derived(
		selected
			.map((s) => ({ charge: dataState.charges.find((c) => c.id === s.id), count: s.count }))
			.filter((x): x is { charge: Charge; count: number } => Boolean(x.charge)),
	);

	const totals = $derived.by(() => {
		let months = 0;
		let fine = 0;
		let points = 0;
		for (const { charge, count } of selectedCharges) {
			if (charge.jail) months += charge.jail;
			if (charge.fine) fine += charge.fine * count;
			if (charge.points) points += charge.points * count;
		}
		return { months, fine, points };
	});

	function addCharge(charge: Charge) {
		const existing = selected.find((s) => s.id === charge.id);
		if (existing) {
			selected = selected.map((s) => (s.id === charge.id ? { ...s, count: s.count + 1 } : s));
		} else {
			selected = [...selected, { id: charge.id, count: 1 }];
		}
	}

	function removeCharge(id: number) {
		selected = selected.filter((s) => s.id !== id);
	}
</script>

<div class="calculator">
	<div class="catalog">
		<input type="text" placeholder="Search charges..." bind:value={search} />
		<div class="list">
			{#each filtered as charge (charge.id)}
				<button type="button" class="tile type-{charge.type}" onclick={() => addCharge(charge)}>
					<span class="title">{charge.title}</span>
					<span class="meta">
						{#if charge.jail}<span>Time: {charge.jail}mo</span>{/if}
						{#if charge.fine}<span>Fine: {CURRENCY.format(charge.fine)}</span>{/if}
						{#if charge.points}<span>Points: {charge.points}</span>{/if}
					</span>
					<span
						class="info"
						role="button"
						tabindex="0"
						onclick={(e) => (e.stopPropagation(), (detailsCharge = charge))}
						onkeydown={(e) => e.key === 'Enter' && (e.stopPropagation(), (detailsCharge = charge))}
					>
						<Icon name="circle-exclamation" size="1vmin" />
					</span>
				</button>
			{/each}
		</div>
	</div>

	<div class="current">
		<h4>Current Charges</h4>
		<div class="list">
			{#each selectedCharges as { charge, count } (charge.id)}
				<div class="row">
					<span>{charge.title} x{count}</span>
					<button type="button" onclick={() => removeCharge(charge.id)} aria-label="Remove">
						<Icon name="xmark" size="1vmin" />
					</button>
				</div>
			{/each}
			{#if selectedCharges.length === 0}
				<p class="hint">No charges selected.</p>
			{/if}
		</div>
		<div class="totals">
			<span>Months: {totals.months}</span>
			<span>Fine: {CURRENCY.format(totals.fine)}</span>
			<span class:high={totals.points >= 12}>Points: {totals.points}</span>
		</div>
	</div>
</div>

{#if detailsCharge}
	<Modal showing={Boolean(detailsCharge)} title={detailsCharge.title} acceptLabel="Close" onAccept={() => (detailsCharge = null)} onClose={() => (detailsCharge = null)}>
		<p>Type: {detailsCharge.type === 1 ? 'Infraction' : detailsCharge.type === 2 ? 'Misdemeanor' : 'Felony'}</p>
		<p>Description: {detailsCharge.description}</p>
		<p>Fine: {CURRENCY.format(detailsCharge.fine)}</p>
		<p>Jail Sentence: {detailsCharge.jail}mo</p>
		<p>License Points: {detailsCharge.points}</p>
	</Modal>
{/if}

<style>
	.calculator {
		display: flex;
		gap: 0.8vw;
		height: 30vh;
	}

	.catalog,
	.current {
		flex: 1;
		min-width: 0;
		display: flex;
		flex-direction: column;
		background: var(--color-bg);
		border: var(--border-subtle);
		border-radius: var(--radius);
		padding: 0.6vh 0.6vw;
		gap: 0.5vh;
	}

	.current {
		flex: 0 0 34%;
	}

	.catalog input {
		background: var(--color-bg-panel-alt);
		border: var(--border-subtle);
		border-radius: var(--radius);
		color: var(--color-surface-text);
		padding: 0.6vh 0.6vw;
		font-size: 1.05vmin;
	}

	.list {
		flex: 1;
		min-height: 0;
		overflow-y: auto;
		display: flex;
		flex-direction: column;
		gap: 0.4vh;
	}

	.tile {
		display: flex;
		flex-direction: column;
		align-items: flex-start;
		gap: 0.2vh;
		background: var(--color-bg-panel-alt);
		border: none;
		border-left: 3px solid var(--color-text-muted);
		border-radius: var(--radius);
		padding: 0.5vh 0.6vw;
		cursor: pointer;
		color: var(--color-surface-text);
		text-align: left;
		position: relative;
	}

	.tile.type-1 {
		border-left-color: var(--color-info);
	}
	.tile.type-2 {
		border-left-color: var(--color-warning);
	}
	.tile.type-3 {
		border-left-color: var(--color-error);
	}

	.tile .title {
		font-size: 1.05vmin;
		font-weight: 600;
	}

	.tile .meta {
		display: flex;
		gap: 0.7vw;
		font-size: 0.9vmin;
		color: var(--color-surface-text-muted);
	}

	.tile .info {
		position: absolute;
		top: 0.5vh;
		right: 0.5vw;
		color: var(--color-surface-text-muted);
		cursor: pointer;
	}

	.current h4 {
		margin: 0;
		font-size: 1.05vmin;
		color: var(--color-text-muted);
	}

	.row {
		display: flex;
		align-items: center;
		justify-content: space-between;
		background: var(--color-bg-panel-alt);
		border-radius: var(--radius);
		padding: 0.4vh 0.6vw;
		font-size: 1vmin;
		color: var(--color-surface-text);
	}

	.row button {
		background: transparent;
		border: none;
		color: var(--color-surface-text-muted);
		cursor: pointer;
		display: flex;
	}

	.hint {
		color: var(--color-text-muted);
		font-size: 0.95vmin;
	}

	.totals {
		display: flex;
		justify-content: space-between;
		border-top: var(--border-subtle);
		padding-top: 0.5vh;
		font-size: 1vmin;
		color: var(--color-text);
	}

	.totals .high {
		color: var(--color-error);
	}
</style>
