<script lang="ts">
	import Icon from '../../Icon.svelte';
	import Loader from '../../primitives/Loader.svelte';
	import Pagination from '../../primitives/Pagination.svelte';
	import { Nui } from '../../nui';
	import { appState } from '../../store/app.svelte';
	import { REPORT_TYPES, REPORTS_PER_PAGE } from '../../../config';
	import { timeAgo } from '../../util/format';
	import type { ReportListItem } from '../../types';

	let {
		selectedId = $bindable(null),
		initialTerm = '',
		onCreate,
	}: {
		selectedId: number | null;
		initialTerm?: string;
		onCreate: () => void;
	} = $props();

	const isSystemAdmin = $derived(Boolean(appState.user?.MDTSystemAdmin));
	const isAttorney = $derived(appState.attorney || (appState.govJob?.Id === 'government' && appState.govJob?.Workplace?.Id === 'publicdefenders'));

	function hasPerm(permission?: string): boolean {
		if (!permission) return true;
		return Boolean(appState.govJobPermissions[permission]) || isSystemAdmin;
	}

	const availableTypes = $derived(REPORT_TYPES.filter((r) => hasPerm(r.requiredViewPermission) || (r.allowAttorney && isAttorney)));

	let reportType = $state(0);
	let evidenceMode = $state(false);
	let term = $state(initialTerm);

	// resets to a valid type whenever the permitted set changes and the current selection falls outside it, also seeds the initial default
	$effect(() => {
		if (!availableTypes.some((t) => t.value === reportType)) {
			reportType = availableTypes[0]?.value ?? 0;
		}
	});
	let results = $state<ReportListItem[]>([]);
	let loading = $state(false);
	let page = $state(1);
	let pages = $state(1);
	let searched = $state(false);

	async function search(targetPage = 1) {
		loading = true;
		searched = true;
		page = targetPage;
		const res = await Nui.searchReports(term.trim(), reportType, page, REPORTS_PER_PAGE, isAttorney, evidenceMode);
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

	$effect(() => {
		if (initialTerm) search(1);
	});

	function typeShort(type: number): string {
		return REPORT_TYPES.find((r) => r.value === type)?.short ?? 'Incident';
	}
</script>

<div class="search-pane">
	<div class="filters">
		<select bind:value={reportType}>
			{#each availableTypes as t (t.value)}
				<option value={t.value}>{t.label}</option>
			{/each}
		</select>
		<label class="check">
			<input type="checkbox" bind:checked={evidenceMode} />
			<Icon name="magnifying-glass" size="1vmin" />
			Evidence Mode
		</label>
	</div>

	<form class="bar" onsubmit={(e) => (e.preventDefault(), search(1))}>
		<input type="text" placeholder={evidenceMode ? 'Search Reports By Evidence Identifier' : 'Search Reports'} bind:value={term} />
		{#if term}
			<button type="button" class="icon-btn" onclick={clear} title="Clear">
				<Icon name="xmark" size="1.1vmin" />
			</button>
		{/if}
		<button type="submit" class="icon-btn" title="Search">
			<Icon name="magnifying-glass" size="1.1vmin" />
		</button>
		{#if appState.govJob}
			<button type="button" class="icon-btn create" onclick={onCreate} title="New Report">
				<Icon name="plus" size="1.1vmin" />
			</button>
		{/if}
	</form>

	<div class="results">
		{#if loading}
			<Loader />
		{:else if !searched}
			<p class="hint">Search for a report.</p>
		{:else if results.length === 0}
			<p class="hint">No results found.</p>
		{:else}
			{#each results as report (report.id)}
				<button type="button" class="row" class:active={selectedId === report.id} onclick={() => (selectedId = report.id)}>
					<div class="info">
						<span class="name">{typeShort(report.type)} #{report.id} - {report.title}</span>
						<small>Created By {report.creatorName}</small>
						<small>{timeAgo(report.created)}</small>
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

	.filters {
		flex-shrink: 0;
		display: flex;
		align-items: center;
		justify-content: space-between;
		gap: 0.6vw;
		padding: 0.7vh 0.8vw;
		border-bottom: var(--border-subtle);
	}

	.filters select {
		flex: 1;
		background-color: var(--color-bg);
		border: var(--border-subtle);
		border-radius: var(--radius);
		color: var(--color-text);
		padding: 0.5vh 0.6vw;
		font-size: 1vmin;
	}

	.check {
		display: flex;
		align-items: center;
		gap: 0.3vw;
		font-size: 0.95vmin;
		color: var(--color-text-muted);
		white-space: nowrap;
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

	.icon-btn.create {
		color: var(--color-primary-light);
		border-color: var(--color-primary);
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
		font-size: 1.1vmin;
		font-weight: 600;
	}

	.info small {
		color: var(--color-surface-text-muted);
		font-size: 0.9vmin;
	}
</style>
