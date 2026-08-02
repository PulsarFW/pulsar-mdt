<script lang="ts">
	import { dataState } from '../store/data.svelte';
	import { navigate } from '../store/app.svelte';
	import { timeUntil } from '../util/format';
	import Icon from '../Icon.svelte';

	const active = $derived(
		dataState.warrants.filter((w) => w.state === 'active').sort((a, b) => Date.parse(a.expires) - Date.parse(b.expires)),
	);
</script>

<div class="block">
	<div class="header">
		<span>Recently Created Warrants</span>
		<button type="button" class="view" onclick={() => navigate('warrants')} aria-label="View all warrants">
			<Icon name="magnifying-glass" size="0.8em" />
		</button>
	</div>
	<div class="list">
		{#if active.length > 0}
			{#each active as warrant (warrant.id)}
				<button type="button" class="row" onclick={() => navigate('warrants', { id: String(warrant.id) })}>
					<span class="title">{warrant.title}</span>
					<span class="sub">{timeUntil(warrant.expires)}</span>
				</button>
			{/each}
		{:else}
			<div class="empty">No Active Warrants</div>
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
		display: flex;
		align-items: center;
		justify-content: space-between;
		padding-bottom: 0.6rem;
		margin-bottom: 0.4rem;
		border-bottom: var(--border-subtle);
		color: var(--color-primary-light);
		font-family: var(--font-heading);
		font-size: 0.9rem;
	}

	.view {
		width: 1.8rem;
		height: 1.8rem;
		border-radius: var(--radius);
		border: none;
		background: rgba(139, 92, 246, 0.15);
		color: var(--color-primary-light);
		cursor: pointer;
		display: flex;
		align-items: center;
		justify-content: center;
	}

	.list {
		display: flex;
		flex-direction: column;
		gap: 0.3rem;
	}

	.row {
		display: flex;
		flex-direction: column;
		width: 100%;
		background: transparent;
		border: none;
		text-align: left;
		padding: 0.5rem 0.3rem;
		border-radius: var(--radius);
		color: var(--color-text);
		cursor: pointer;
	}

	.row:hover {
		background: rgba(139, 92, 246, 0.08);
	}

	.row .title {
		font-size: 0.85rem;
		white-space: nowrap;
		overflow: hidden;
		text-overflow: ellipsis;
	}

	.row .sub {
		font-size: 0.7rem;
		color: var(--color-text-muted);
	}

	.empty {
		padding: 1rem 0;
		text-align: center;
		font-size: 0.8rem;
		color: var(--color-text-muted);
	}
</style>
