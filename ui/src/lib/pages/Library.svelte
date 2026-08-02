<script lang="ts">
	import { Nui } from '../nui';
	import { appState, toast } from '../store/app.svelte';
	import { dataState } from '../store/data.svelte';
	import Loader from '../primitives/Loader.svelte';
	import type { LibraryDocument } from '../types';

	interface WorkplaceRef {
		Id: string;
		Name: string;
	}
	interface JobCatalogEntry {
		Name: string;
		Workplaces: WorkplaceRef[];
	}

	const isSysAdmin = $derived(Boolean(appState.user?.MDTSystemAdmin));

	let loading = $state(true);
	let docs = $state<LibraryDocument[]>([]);
	let selected = $state<number>(-1);

	let newLabel = $state('');
	let newLink = $state('');
	let newJob = $state(appState.govJob?.Id ?? '');
	let newWorkplace = $state<string | false>(false);

	const jobData = $derived(dataState.governmentJobsData[newJob] as JobCatalogEntry | undefined);

	async function refresh() {
		loading = true;
		docs = await Nui.getLibraryDocuments();
		selected = docs[0]?.id ?? -1;
		loading = false;
	}

	$effect(() => {
		refresh();
	});

	async function addDocument() {
		loading = true;
		const id = await Nui.addLibraryDocument(newLabel, newLink, newJob, newWorkplace || undefined);
		if (id) {
			toast.success('Successfully Added Document to Library');
			newLabel = '';
			newLink = '';
			await refresh();
		} else {
			toast.error('Failed to Add Document to Library');
			loading = false;
		}
	}

	async function removeDocument(id: number) {
		loading = true;
		const ok = await Nui.removeLibraryDocument(id);
		if (ok) {
			toast.success('Successfully Removed Document from Library');
			await refresh();
		} else {
			toast.error('Failed to Remove Document from Library');
			loading = false;
		}
	}

	const activeDoc = $derived(docs.find((d) => d.id === selected));
</script>

<div class="wrap">
	{#if loading}
		<Loader static />
	{:else}
		<div class="layout">
			<div class="tabs">
				{#each docs as doc (doc.id)}
					<button type="button" class="tab" class:active={selected === doc.id} onclick={() => (selected = doc.id)}>{doc.label}</button>
				{/each}
				{#if isSysAdmin}
					<button type="button" class="tab" class:active={selected === -1} onclick={() => (selected = -1)}>Add New Document</button>
				{/if}
			</div>
			<div class="content">
				{#if selected === -1}
					<div class="form">
						<label><span>Document Label</span><input type="text" bind:value={newLabel} maxlength="64" /></label>
						<label><span>Document Link (must be .pdf)</span><input type="text" bind:value={newLink} maxlength="400" /></label>
						<label>
							<span>Agency</span>
							<select bind:value={newJob}>
								{#each dataState.governmentJobs as j (j)}
									<option value={j}>{(dataState.governmentJobsData[j] as JobCatalogEntry | undefined)?.Name ?? 'Unknown'}</option>
								{/each}
							</select>
						</label>
						<label>
							<span>Department</span>
							<select bind:value={newWorkplace}>
								<option value={false}>All Departments</option>
								{#each jobData?.Workplaces ?? [] as w (w.Id)}
									<option value={w.Id}>{w.Name}</option>
								{/each}
							</select>
						</label>
						<button type="button" class="btn btn-primary" onclick={addDocument} disabled={!newLabel || !newLink}>Add To Library</button>
					</div>
				{:else if activeDoc}
					<iframe src={activeDoc.link} title={activeDoc.label} class="viewer"></iframe>
					{#if isSysAdmin}
						<button type="button" class="btn btn-ghost" onclick={() => removeDocument(activeDoc!.id)}>Remove Document</button>
					{/if}
				{:else}
					<div class="empty">No documents available.</div>
				{/if}
			</div>
		</div>
	{/if}
</div>

<style>
	.wrap {
		height: 100%;
		padding: 1.2vh 1vw;
		position: relative;
	}

	.layout {
		height: 100%;
		display: flex;
		gap: 1vw;
	}

	.tabs {
		flex: 0 0 16%;
		display: flex;
		flex-direction: column;
		gap: 0.3vh;
		border-right: var(--border-subtle);
		padding-right: 0.6vw;
		overflow-y: auto;
	}

	.tab {
		text-align: left;
		background: transparent;
		border: none;
		color: var(--color-text-muted);
		padding: 0.7vh 0.6vw;
		border-radius: var(--radius);
		cursor: pointer;
		font-size: 1.1vmin;
	}

	.tab:hover {
		background: rgba(139, 92, 246, 0.08);
	}

	.tab.active {
		color: var(--color-primary-light);
		background: rgba(139, 92, 246, 0.15);
	}

	.content {
		flex: 1;
		display: flex;
		flex-direction: column;
		min-width: 0;
	}

	.viewer {
		flex: 1;
		width: 100%;
		border: var(--border-subtle);
		border-radius: var(--radius);
		background: #fff;
	}

	.form {
		display: flex;
		flex-direction: column;
		gap: 1.2vh;
		max-width: 26vw;
	}

	label {
		display: flex;
		flex-direction: column;
		gap: 0.4vh;
		font-size: 1.1vmin;
		color: var(--color-text-muted);
	}

	input,
	select {
		background-color: var(--color-bg-panel-alt);
		border: var(--border-subtle);
		border-radius: var(--radius);
		color: var(--color-surface-text);
		padding: 0.7vh 0.8vw;
		font-size: 1.2vmin;
	}

	.btn {
		border: none;
		padding: 1vh 1vw;
		font-size: 1.2vmin;
		cursor: pointer;
		border-radius: var(--radius);
		margin-top: 0.6vh;
	}

	.btn:disabled {
		opacity: 0.5;
		cursor: not-allowed;
	}

	.btn-primary {
		background: var(--color-primary);
		color: #ffffff;
	}

	.btn-ghost {
		background: transparent;
		color: var(--color-error);
		border: 1px solid rgba(229, 72, 77, 0.4);
	}

	.empty {
		color: var(--color-text-muted);
		text-align: center;
		padding: 3vh 0;
	}
</style>
