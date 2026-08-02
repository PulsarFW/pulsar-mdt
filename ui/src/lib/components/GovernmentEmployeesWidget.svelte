<script lang="ts">
	import { dataState } from '../store/data.svelte';

	const sorted = $derived([...dataState.govWorkers].sort((a, b) => a.Workplace.localeCompare(b.Workplace) || a.Last.localeCompare(b.Last)));
</script>

<div class="block">
	<div class="header"><span>Available DOJ</span></div>
	<div class="list">
		{#if sorted.length > 0}
			{#each sorted as worker, i (i)}
				<div class="row">
					<span class="name">{worker.First} {worker.Last}</span>
					<span class="sub">{worker.Grade} - {worker.Workplace}</span>
					{#if worker.Phone}<span class="phone">{worker.Phone}</span>{/if}
				</div>
			{/each}
		{:else}
			<div class="empty">No DOJ</div>
		{/if}
	</div>
</div>

<style>
	.block {
		background: var(--color-bg-panel);
		border: var(--border-subtle);
		border-radius: var(--radius);
		padding: 0.8rem;
	}

	.header {
		padding-bottom: 0.6rem;
		margin-bottom: 0.4rem;
		border-bottom: var(--border-subtle);
		color: var(--color-primary-light);
		font-family: var(--font-heading);
		font-size: 0.9rem;
	}

	.list {
		display: flex;
		flex-direction: column;
		gap: 0.3rem;
		max-height: 30vh;
		overflow-y: auto;
	}

	.row {
		display: flex;
		align-items: baseline;
		gap: 0.5rem;
		padding: 0.4rem 0.3rem;
	}

	.name {
		font-size: 0.85rem;
		color: var(--color-text);
	}

	.sub {
		flex: 1;
		font-size: 0.75rem;
		color: var(--color-text-muted);
	}

	.phone {
		font-size: 0.75rem;
		color: var(--color-text-muted);
	}

	.empty {
		padding: 1rem 0;
		text-align: center;
		font-size: 0.8rem;
		color: var(--color-text-muted);
	}
</style>
