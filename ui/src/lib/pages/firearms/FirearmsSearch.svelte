<script lang="ts">
	import Icon from '../../Icon.svelte';
	import Loader from '../../primitives/Loader.svelte';
	import Pagination from '../../primitives/Pagination.svelte';
	import { Nui } from '../../nui';
	import type { Firearm } from '../../types';

	const PER_PAGE = 6;

	let { selectedSerial = $bindable(null) }: { selectedSerial: string | null } = $props();

	let term = $state('');
	let results = $state<Firearm[]>([]);
	let loading = $state(false);
	let page = $state(1);
	let searched = $state(false);

	const pages = $derived(Math.max(1, Math.ceil(results.length / PER_PAGE)));
	const pageResults = $derived(results.slice((page - 1) * PER_PAGE, page * PER_PAGE));

	async function search() {
		loading = true;
		searched = true;
		page = 1;
		results = await Nui.searchFirearms(term.trim());
		loading = false;
	}

	function clear() {
		term = '';
		results = [];
		searched = false;
		page = 1;
	}
</script>

<div class="search-pane">
	<form class="bar" onsubmit={(e) => (e.preventDefault(), search())}>
		<input type="text" placeholder="Search By Serial Number, Owner State ID, or Owner Name" bind:value={term} />
		{#if term}
			<button type="button" class="icon-btn" onclick={clear} title="Clear">
				<Icon name="xmark" size="1.1vmin" />
			</button>
		{/if}
		<button type="submit" class="icon-btn" title="Search">
			<Icon name="magnifying-glass" size="1.1vmin" />
		</button>
	</form>

	<div class="results">
		{#if loading}
			<Loader />
		{:else if !searched}
			<p class="hint">Search by serial number, owner state ID, or owner name.</p>
		{:else if pageResults.length === 0}
			<p class="hint">No results found.</p>
		{:else}
			{#each pageResults as firearm (firearm.serial)}
				<button type="button" class="row" class:active={selectedSerial === firearm.serial} onclick={() => (selectedSerial = firearm.serial)}>
					<div class="info">
						<span class="name">{firearm.model ?? 'Unknown'}</span>
						<small>Serial: {firearm.serial}</small>
						<small>Owner: {firearm.owner_sid ? `${firearm.owner_name} (${firearm.owner_sid})` : firearm.owner_name}</small>
					</div>
				</button>
			{/each}
		{/if}
	</div>

	<Pagination {page} {pages} onChange={(p) => (page = p)} />
</div>

<style>
	.search-pane {
		display: flex;
		flex-direction: column;
		height: 100%;
	}

	.bar {
		flex-shrink: 0;
		display: flex;
		gap: 0.4vw;
		padding: 0.8vh 0.8vw;
		border-bottom: var(--border-subtle);
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

	.bar input:focus {
		outline: none;
		border-color: var(--color-primary);
	}

	.icon-btn {
		background: transparent;
		border: var(--border-subtle);
		border-radius: var(--radius);
		color: var(--color-text-muted);
		cursor: pointer;
		padding: 0 0.8vw;
		display: flex;
		align-items: center;
	}

	.icon-btn:hover {
		color: var(--color-primary-light);
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
		background: var(--color-bg-panel-alt);
		border: 1px solid transparent;
		border-radius: var(--radius);
		padding: 0.7vh 0.7vw;
		cursor: pointer;
		text-align: left;
		color: var(--color-surface-text);
	}

	.row:hover {
		border-color: rgba(139, 92, 246, 0.3);
	}

	.row.active {
		border-color: var(--color-primary);
	}

	.info {
		display: flex;
		flex-direction: column;
		min-width: 0;
	}

	.name {
		font-size: 1.15vmin;
		font-weight: 600;
	}

	.info small {
		color: var(--color-surface-text-muted);
		font-size: 0.95vmin;
	}
</style>
