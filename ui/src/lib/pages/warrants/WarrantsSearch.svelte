<script lang="ts">
	import Icon from '../../Icon.svelte';
	import Loader from '../../primitives/Loader.svelte';
	import Pagination from '../../primitives/Pagination.svelte';
	import { Nui } from '../../nui';
	import { appState } from '../../store/app.svelte';
	import { formatDateTime } from '../../util/format';
	import type { Warrant } from '../../types';

	const PER_PAGE = 10;
	const WARRANT_STATE_LABELS: Record<string, string> = { active: 'Active', void: 'Void', served: 'Served', expired: 'Expired' };

	let { selectedId = $bindable(null) }: { selectedId: number | null } = $props();

	let term = $state('');
	let results = $state<Warrant[]>([]);
	let loading = $state(false);
	let page = $state(1);
	let pages = $state(1);
	let searched = $state(false);

	const inMdtContext = $derived(Boolean(appState.govJob?.Id));

	async function search(targetPage = 1) {
		loading = true;
		searched = true;
		page = targetPage;
		const res = await Nui.searchWarrants(term.trim(), page, PER_PAGE);
		results = res.data;
		if (res.pages && res.pages > pages) pages = Math.ceil(res.pages);
		loading = false;
	}

	function clear() {
		term = '';
		results = [];
		searched = false;
		page = 1;
		pages = 1;
	}

	function statusLine(w: Warrant): string {
		if (w.state === 'active' || w.state === 'expired') {
			return `${WARRANT_STATE_LABELS[w.state]} - ${w.state === 'active' ? 'Expires' : 'Expired'} ${formatDateTime(w.expires)}`;
		}
		return WARRANT_STATE_LABELS[w.state] ?? w.state;
	}
</script>

<div class="search-pane">
	<form class="bar" onsubmit={(e) => (e.preventDefault(), search(1))}>
		<input type="text" placeholder="Search Suspect Name or Warrant Number" bind:value={term} />
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
			<p class="hint">Search by suspect name or warrant number.</p>
		{:else if results.length === 0}
			<p class="hint">No results found.</p>
		{:else}
			{#each results as warrant (warrant.id)}
				<button type="button" class="row" class:active={selectedId === warrant.id} onclick={() => (selectedId = warrant.id)}>
					<div class="info">
						<span class="name">#{warrant.id} - {warrant.title}</span>
						{#if inMdtContext}<small>Issued By {warrant.creatorName} [{warrant.creatorCallsign}]</small>{/if}
						<small>{statusLine(warrant)}</small>
					</div>
				</button>
			{/each}
		{/if}
	</div>

	<Pagination {page} {pages} onChange={(p) => search(p)} />
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
