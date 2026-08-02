<script lang="ts">
	import Icon from '../../Icon.svelte';
	import Loader from '../../primitives/Loader.svelte';
	import { Nui } from '../../nui';
	import { appState } from '../../store/app.svelte';
	import { dataState } from '../../store/data.svelte';
	import type { RosterEntry } from '../../types';

	let {
		selectedSid = $bindable(null),
		onHire,
	}: {
		selectedSid: number | null;
		onHire: () => void;
	} = $props();

	const isSystemAdmin = $derived(Boolean(appState.user?.MDTSystemAdmin));
	function hasPerm(permission?: string): boolean {
		if (!permission) return true;
		return Boolean(appState.govJobPermissions[permission]) || isSystemAdmin;
	}
	const isHighCommand = $derived(hasPerm('PD_HIGH_COMMAND') || hasPerm('SAFD_HIGH_COMMAND') || hasPerm('DOC_HIGH_COMMAND'));
	const canHire = $derived(hasPerm('MDT_HIRE') || isHighCommand);

	let selectedJob = $state(appState.govJob?.Id ?? 'police');
	let workplace = $state<string | null>(null);
	let search = $state('');
	let officers = $state<RosterEntry[]>([]);
	let loading = $state(false);

	const jobData = $derived(dataState.governmentJobsData[selectedJob] as { Name?: string; Workplaces?: { Id: string; Name: string }[] } | undefined);

	async function load() {
		loading = true;
		officers = await Nui.rosterView(selectedJob);
		loading = false;
	}

	$effect(() => {
		selectedJob;
		load();
	});

	export function refresh() {
		load();
	}

	const filtered = $derived.by(() => {
		const term = search.trim().toLowerCase();
		return officers
			.filter((o) => {
				const govJobEntry = o.Jobs.find((j) => j.Id === selectedJob);
				if (!govJobEntry) return false;
				if (workplace && govJobEntry.Workplace?.Id !== workplace) return false;
				if (!term) return true;
				return `${o.First} ${o.Last}`.toLowerCase().includes(term) || String(o.Callsign ?? '').toLowerCase().includes(term);
			})
			.sort((a, b) => Number(a.Callsign || 0) - Number(b.Callsign || 0));
	});

	function deptGrade(o: RosterEntry): string {
		const j = o.Jobs.find((j) => j.Id === selectedJob);
		return j ? `${j.Workplace?.Name ?? ''} - ${j.Grade.Name}` : '';
	}
</script>

<div class="search-pane">
	<div class="filters">
		{#if appState.user?.MDTSystemAdmin}
			<select bind:value={selectedJob}>
				{#each dataState.governmentJobs as job (job)}
					<option value={job}>{(dataState.governmentJobsData[job] as { Name?: string })?.Name ?? job}</option>
				{/each}
			</select>
		{/if}
		<select value={workplace ?? ''} onchange={(e) => (workplace = (e.target as HTMLSelectElement).value || null)}>
			<option value="">All Departments</option>
			{#each jobData?.Workplaces ?? [] as w (w.Id)}
				<option value={w.Id}>{w.Name}</option>
			{/each}
		</select>
	</div>

	<form class="bar" onsubmit={(e) => e.preventDefault()}>
		<input type="text" placeholder="Search By Name or Callsign" bind:value={search} />
		{#if search}
			<button type="button" class="icon-btn" onclick={() => (search = '')} title="Clear">
				<Icon name="xmark" size="1.1vmin" />
			</button>
		{/if}
		{#if canHire}
			<button type="button" class="icon-btn create" onclick={onHire} title="Hire">
				<Icon name="plus" size="1.1vmin" />
			</button>
		{/if}
	</form>

	<div class="results">
		{#if loading}
			<Loader />
		{:else if filtered.length === 0}
			<p class="hint">No officers found.</p>
		{:else}
			{#each filtered as officer (officer.SID)}
				<button type="button" class="row" class:active={selectedSid === officer.SID} disabled={loading} onclick={() => (selectedSid = officer.SID)}>
					<div class="avatar">
						{#if officer.Mugshot}<img src={officer.Mugshot} alt="" />{:else}<Icon name="user-large" size="1.6vmin" />{/if}
					</div>
					<div class="info">
						<span class="name">{officer.Callsign ? `(${officer.Callsign}) ` : ''}{officer.First} {officer.Last}</span>
						<small>{deptGrade(officer)}</small>
					</div>
				</button>
			{/each}
		{/if}
	</div>
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
		gap: 0.5vw;
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
		gap: 0.7vw;
		background: var(--color-bg-panel-alt);
		border: 1px solid transparent;
		border-radius: var(--radius);
		padding: 0.6vh 0.7vw;
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

	.avatar {
		flex-shrink: 0;
		width: 3vh;
		height: 3vh;
		border-radius: 50%;
		background: var(--color-bg);
		display: flex;
		align-items: center;
		justify-content: center;
		overflow: hidden;
		color: var(--color-text-muted);
	}

	.avatar img {
		width: 100%;
		height: 100%;
		object-fit: cover;
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
