<script lang="ts">
	import Icon from '../Icon.svelte';
	import Loader from '../primitives/Loader.svelte';
	import Modal from '../primitives/Modal.svelte';
	import { Nui } from '../nui';
	import { appState, toast } from '../store/app.svelte';
	import { dataState } from '../store/data.svelte';

	interface Grade {
		Id: string;
		Name: string;
		Level: number;
		Permissions: Record<string, boolean>;
	}
	interface Workplace {
		Id: string;
		Name: string;
		Grades: Grade[];
	}

	const jobId = $derived(appState.govJob?.Id ?? '');
	const jobData = $derived(dataState.governmentJobsData[jobId] as { Name?: string; Workplaces?: Workplace[] } | undefined);

	let workplaceId = $state('');
	let search = $state('');

	$effect(() => {
		if (jobData?.Workplaces && !jobData.Workplaces.some((w) => w.Id === workplaceId)) {
			workplaceId = jobData.Workplaces[0]?.Id ?? '';
		}
	});

	const workplace = $derived(jobData?.Workplaces?.find((w) => w.Id === workplaceId));
	const filteredGrades = $derived((workplace?.Grades ?? []).filter((g) => g.Name.toLowerCase().includes(search.toLowerCase())).sort((a, b) => a.Level - b.Level));

	let editing = $state<Grade | null>(null);
	let pending = $state<string[]>([]);
	let loading = $state(false);

	function openGrade(g: Grade) {
		editing = g;
		pending = Object.keys(g.Permissions).filter((p) => g.Permissions[p]);
	}

	function toggle(perm: string) {
		pending = pending.includes(perm) ? pending.filter((p) => p !== perm) : [...pending, perm];
	}

	const availablePermissions = $derived(
		Object.entries(dataState.permissions).filter(([, p]) => !p.restrict || p.restrict.job === jobId),
	);

	async function save() {
		if (!editing || !workplace) return;
		loading = true;
		const updated: Record<string, true> = {};
		for (const perm of pending) updated[perm] = true;
		const ok = await Nui.updateJobPermissions(jobId, workplace.Id, editing.Id, updated);
		if (ok) {
			editing.Permissions = updated;
			toast.success('Permissions Updated');
		} else toast.error('Failed to Update Permissions');
		loading = false;
		editing = null;
	}
</script>

<div class="page">
	<div class="panel">
		{#if loading}
			<Loader static />
		{:else}
			<div class="filters">
				<select bind:value={workplaceId}>
					{#each jobData?.Workplaces ?? [] as w (w.Id)}
						<option value={w.Id}>{w.Name}</option>
					{/each}
				</select>
				<div class="search">
					<input type="text" placeholder="Search rank..." bind:value={search} />
					{#if search}
						<button type="button" onclick={() => (search = '')} aria-label="Clear"><Icon name="xmark" size="1vmin" /></button>
					{/if}
				</div>
			</div>

			<div class="grades">
				{#each filteredGrades as grade (grade.Id)}
					<button type="button" class="row" onclick={() => openGrade(grade)}>
						<span>{grade.Name}</span>
						<span>Level {grade.Level ?? 1}</span>
						<span>{Object.keys(grade.Permissions ?? {}).length} Permissions</span>
					</button>
				{/each}
			</div>
		{/if}
	</div>
</div>

{#if editing}
	<Modal showing={Boolean(editing)} title={`Update ${workplace?.Name} - ${editing.Name}`} onAccept={save} onClose={() => (editing = null)}>
		<div class="perm-list">
			{#each availablePermissions as [id, p] (id)}
				<label class="row"><input type="checkbox" checked={pending.includes(id)} onchange={() => toggle(id)} /> {p.name}</label>
			{/each}
		</div>
	</Modal>
{/if}

<style>
	.page {
		height: 100%;
		padding: 1vh 1vw;
	}

	.panel {
		height: 100%;
		display: flex;
		flex-direction: column;
		background: var(--color-bg-panel);
		border-radius: var(--radius);
		overflow: hidden;
		padding: 0.8vh 0.8vw;
		gap: 0.8vh;
	}

	.filters {
		display: flex;
		gap: 0.6vw;
	}

	.filters select {
		flex: 1;
		background-color: var(--color-bg);
		border: var(--border-subtle);
		border-radius: var(--radius);
		color: var(--color-text);
		padding: 0.6vh 0.7vw;
		font-size: 1.05vmin;
	}

	.search {
		flex: 1;
		display: flex;
		align-items: center;
		gap: 0.3vw;
	}

	.search input {
		flex: 1;
		background: var(--color-bg);
		border: var(--border-subtle);
		border-radius: var(--radius);
		color: var(--color-text);
		padding: 0.6vh 0.7vw;
		font-size: 1.05vmin;
	}

	.search button {
		background: transparent;
		border: none;
		color: var(--color-text-muted);
		cursor: pointer;
	}

	.grades {
		flex: 1;
		min-height: 0;
		overflow-y: auto;
		display: flex;
		flex-direction: column;
		gap: 0.4vh;
	}

	.row {
		display: grid;
		grid-template-columns: 1fr 1fr 1fr;
		background: var(--color-bg-panel-alt);
		border: 1px solid transparent;
		border-radius: var(--radius);
		padding: 0.7vh 0.8vw;
		cursor: pointer;
		text-align: left;
		color: var(--color-surface-text);
		font-size: 1.05vmin;
	}

	.row:hover {
		border-color: rgba(139, 92, 246, 0.3);
	}

	.perm-list {
		display: flex;
		flex-direction: column;
		gap: 0.4vh;
		max-height: 34vh;
		overflow-y: auto;
	}

	.perm-list label {
		display: flex;
		align-items: center;
		gap: 0.6vw;
		font-size: 1.05vmin;
		color: var(--color-text);
	}
</style>
