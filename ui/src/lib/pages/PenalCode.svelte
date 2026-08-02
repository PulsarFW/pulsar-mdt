<script lang="ts">
	import { dataState } from '../store/data.svelte';
	import { CHARGE_TYPES } from '../../config';
	import { CURRENCY } from '../util/format';
	import Modal from '../primitives/Modal.svelte';
	import Icon from '../Icon.svelte';
	import type { Charge } from '../types';

	let search = $state('');
	let selected = $state<Charge | null>(null);

	const filtered = $derived(
		dataState.charges
			.filter((c) => c.title.toUpperCase().includes(search.toUpperCase()))
			.slice()
			.sort((a, b) => a.type - b.type || a.jail - b.jail || a.fine - b.fine),
	);

	function typeLabel(type: number): string {
		return CHARGE_TYPES.find((t) => t.value === type)?.label ?? 'Unknown';
	}
</script>

<div class="wrap">
	<div class="header">
		<div class="key">
			<span class="key-title">Penal Code</span>
			{#each CHARGE_TYPES as t (t.value)}
				<span class="key-item type-{t.value}"><i class="swatch"></i>{t.label}</span>
			{/each}
		</div>
		<div class="search">
			<Icon name="magnifying-glass" size="1.1vmin" />
			<input type="text" placeholder="Search Charge" bind:value={search} />
			{#if search}
				<button type="button" onclick={() => (search = '')} aria-label="Clear"><Icon name="xmark" size="1vmin" /></button>
			{/if}
		</div>
	</div>

	<div class="grid">
		{#each filtered as charge (charge.id)}
			<button type="button" class="charge type-{charge.type}" title={charge.title} onclick={() => (selected = charge)}>
				<span class="title">{charge.title}</span>
				<small>
					{#if charge.jail}Time: {charge.jail} {/if}
					{#if charge.fine}Fine: {CURRENCY.format(charge.fine)} {/if}
					{#if charge.points}Points: {charge.points}{/if}
				</small>
			</button>
		{:else}
			<div class="empty">No charges match your search.</div>
		{/each}
	</div>
</div>

<Modal showing={selected !== null} title={selected?.title ?? ''} acceptLabel="Close" closeLabel="" onAccept={() => (selected = null)} onClose={() => (selected = null)}>
	{#if selected}
		<div class="detail-row"><span>Charge Type</span><strong>{typeLabel(selected.type)}</strong></div>
		<div class="detail-row full"><span>Description</span><p>{selected.description}</p></div>
		{#if selected.fine}<div class="detail-row"><span>Fine</span><strong>{CURRENCY.format(selected.fine)}</strong></div>{/if}
		{#if selected.jail}<div class="detail-row"><span>Jail Sentence</span><strong>{selected.jail} Months</strong></div>{/if}
		{#if selected.points}<div class="detail-row"><span>License Points</span><strong>{selected.points} Points</strong></div>{/if}
	{/if}
</Modal>

<style>
	.wrap {
		height: 100%;
		display: flex;
		flex-direction: column;
		padding: 1.6vh 1.2vw;
		gap: 1.4vh;
	}

	.header {
		display: flex;
		align-items: center;
		justify-content: space-between;
		flex-shrink: 0;
		gap: 1vw;
	}

	.key {
		display: flex;
		align-items: center;
		gap: 1vw;
	}

	.key-title {
		font-family: var(--font-heading);
		font-size: 1.7vmin;
		color: var(--color-text);
	}

	.key-item {
		display: flex;
		align-items: center;
		gap: 0.4vw;
		font-size: 1.05vmin;
		color: var(--color-text-muted);
	}

	.swatch {
		width: 0.8vmin;
		height: 0.8vmin;
		border-radius: 2px;
		display: inline-block;
	}

	.key-item.type-1 .swatch {
		background: var(--color-info);
	}
	.key-item.type-2 .swatch {
		background: var(--color-warning);
	}
	.key-item.type-3 .swatch {
		background: var(--color-error);
	}

	.search {
		display: flex;
		align-items: center;
		gap: 0.5vw;
		background: var(--color-bg-panel-alt);
		border: var(--border-subtle);
		border-radius: var(--radius);
		padding: 0.6vh 0.8vw;
		color: var(--color-surface-text-muted);
		width: 18vw;
	}

	.search input {
		flex: 1;
		background: transparent;
		border: none;
		outline: none;
		color: var(--color-surface-text);
		font-size: 1.1vmin;
	}

	.search button {
		background: transparent;
		border: none;
		color: var(--color-surface-text-muted);
		cursor: pointer;
		display: flex;
	}

	.grid {
		flex: 1;
		overflow-y: auto;
		display: flex;
		flex-wrap: wrap;
		align-content: flex-start;
		gap: 0.6vh 0.8vw;
	}

	.charge {
		width: 48%;
		text-align: left;
		background: var(--color-bg-panel-alt);
		border: var(--border-subtle);
		border-left: 3px solid var(--color-text-muted);
		border-radius: var(--radius);
		padding: 0.8vh 0.9vw;
		cursor: pointer;
		color: var(--color-surface-text);
		transition: filter 120ms ease;
	}

	.charge:hover {
		filter: brightness(1.15);
	}

	.charge.type-1 {
		border-left-color: var(--color-info);
	}
	.charge.type-2 {
		border-left-color: var(--color-warning);
	}
	.charge.type-3 {
		border-left-color: var(--color-error);
	}

	.charge .title {
		display: block;
		font-size: 1.2vmin;
		font-weight: 600;
		white-space: nowrap;
		overflow: hidden;
		text-overflow: ellipsis;
	}

	.charge small {
		color: var(--color-surface-text-muted);
		font-size: 1vmin;
	}

	.empty {
		width: 100%;
		text-align: center;
		padding: 3vh 0;
		color: var(--color-text-muted);
	}

	.detail-row {
		display: flex;
		justify-content: space-between;
		font-size: 1.2vmin;
		color: var(--color-text);
	}

	.detail-row span {
		color: var(--color-text-muted);
	}

	.detail-row.full {
		flex-direction: column;
		gap: 0.4vh;
	}

	.detail-row.full p {
		margin: 0;
		white-space: pre-line;
	}
</style>
