<script lang="ts">
	import Icon from '../Icon.svelte';
	import { Nui } from '../nui';
	import { navigate, toast } from '../store/app.svelte';
	import { dataState } from '../store/data.svelte';

	async function remove(id: number) {
		const ok = await Nui.deleteBolo(id);
		if (!ok) toast.error('Failed to remove BOLO.');
	}
</script>

<div class="widget">
	<div class="head">
		<span class="title">Active BOLOs</span>
		<button type="button" class="icon-btn" onclick={() => navigate('create-bolo')} aria-label="Create BOLO">
			<Icon name="plus" size="1vmin" />
		</button>
	</div>
	{#if dataState.bolos.length === 0}
		<p class="hint">No active BOLOs.</p>
	{:else}
		<div class="list">
			{#each dataState.bolos as bolo (bolo.id)}
				<div class="row">
					<div class="info">
						<span class="name">{bolo.title}</span>
						{#if bolo.summary}<small>{bolo.summary}</small>{/if}
						{#if bolo.author}<small>By [{bolo.author.Callsign ?? 'N/A'}] {bolo.author.First} {bolo.author.Last}</small>{/if}
					</div>
					<button type="button" class="icon-btn" title="Remove" onclick={() => remove(bolo.id)}>
						<Icon name="xmark" size="0.9vmin" />
					</button>
				</div>
			{/each}
		</div>
	{/if}
</div>

<style>
	.widget {
		background: var(--color-bg-panel-alt);
		border-radius: var(--radius);
		padding: 1vh 1vw;
		display: flex;
		flex-direction: column;
		gap: 0.6vh;
	}

	.head {
		display: flex;
		align-items: center;
		justify-content: space-between;
	}

	.title {
		font-size: 1.15vmin;
		font-weight: 600;
		color: var(--color-surface-text);
	}

	.icon-btn {
		background: transparent;
		border: var(--border-subtle);
		border-radius: var(--radius);
		color: var(--color-surface-text-muted);
		cursor: pointer;
		padding: 0.3vh 0.6vw;
		display: flex;
	}

	.icon-btn:hover {
		color: var(--color-nav-text-active);
	}

	.hint {
		color: var(--color-surface-text-muted);
		font-size: 1.05vmin;
		margin: 0;
	}

	.list {
		display: flex;
		flex-direction: column;
		gap: 0.4vh;
	}

	.row {
		display: flex;
		align-items: flex-start;
		justify-content: space-between;
		gap: 0.5vw;
		background: var(--color-bg);
		border-radius: var(--radius);
		padding: 0.5vh 0.7vw;
	}

	.info {
		display: flex;
		flex-direction: column;
		min-width: 0;
	}

	.name {
		font-size: 1.05vmin;
		font-weight: 600;
		color: var(--color-text);
	}

	.info small {
		color: var(--color-text-muted);
		font-size: 0.9vmin;
	}
</style>
