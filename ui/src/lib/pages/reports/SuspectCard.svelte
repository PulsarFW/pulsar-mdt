<script lang="ts">
	import Icon from '../../Icon.svelte';
	import { dataState } from '../../store/data.svelte';
	import { CURRENCY } from '../../util/format';
	import type { ReportSuspect } from '../../types';

	let { suspect, onEdit, onDelete }: { suspect: ReportSuspect; onEdit: () => void; onDelete: () => void } = $props();

	const resolved = $derived(
		suspect.charges.map((s) => ({ charge: dataState.charges.find((c) => c.id === s.id), count: s.count })).filter((x): x is { charge: NonNullable<typeof x.charge>; count: number } => Boolean(x.charge)),
	);

	const totals = $derived.by(() => {
		let months = 0;
		let fine = 0;
		let points = 0;
		for (const { charge, count } of resolved) {
			if (charge.jail) months += charge.jail;
			if (charge.fine) fine += charge.fine * count;
			if (charge.points) points += charge.points * count;
		}
		return { months, fine, points };
	});
</script>

<div class="card">
	<div class="head">
		<span class="name">{suspect.First} {suspect.Last} - {suspect.plea}</span>
		<div class="actions">
			<button type="button" class="icon-btn" disabled={suspect.sentenced} onclick={onEdit} title="Edit"><Icon name="pen" size="1vmin" /></button>
			<button type="button" class="icon-btn" disabled={suspect.sentenced} onclick={onDelete} title="Delete"><Icon name="trash" size="1vmin" /></button>
		</div>
	</div>
	<div class="chips">
		{#each resolved as { charge, count } (charge.id)}
			<span class="chip type-{charge.type}">{charge.title} x{count}</span>
		{/each}
	</div>
	<div class="summary">
		<span>Months: {totals.months}</span>
		<span>Fine: {CURRENCY.format(totals.fine)}</span>
		<span>Points: {totals.points}</span>
	</div>
</div>

<style>
	.card {
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
		justify-content: space-between;
	}

	.name {
		font-size: 1.1vmin;
		font-weight: 600;
	}

	.actions {
		display: flex;
		gap: 0.4vw;
	}

	.icon-btn {
		background: transparent;
		border: var(--border-subtle);
		border-radius: var(--radius);
		color: var(--color-text-muted);
		cursor: pointer;
		padding: 0.3vh 0.6vw;
		display: flex;
	}

	.icon-btn:hover:not(:disabled) {
		color: var(--color-primary-light);
	}

	.icon-btn:disabled {
		opacity: 0.4;
		cursor: not-allowed;
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

	.summary {
		display: flex;
		gap: 1vw;
		font-size: 0.95vmin;
		color: var(--color-text-muted);
	}
</style>
