<script lang="ts">
	import { Nui } from '../nui';
	import { appState, goBack, toast } from '../store/app.svelte';
	import { dataState } from '../store/data.svelte';
	import RichText from '../primitives/RichText.svelte';

	const HIGH_COMMAND_PERMS = ['PD_HIGH_COMMAND', 'SAFD_HIGH_COMMAND', 'DOJ_JUDGE', 'GOV_MAYOR', 'GOV_DA', 'GOV_CPUB', 'DOC_HIGH_COMMAND'];
	const isSystemAdmin = $derived(Boolean(appState.user?.MDTSystemAdmin));
	const canPostPublic = $derived(appState.govJobPermissions.DOJ_JUDGE || appState.govJobPermissions.GOV_MAYOR || appState.govJobPermissions.GOV_DA);

	const restrictOptions = $derived(
		dataState.governmentJobs.filter((j) => appState.govJob?.Id === j || isSystemAdmin || HIGH_COMMAND_PERMS.some((p) => appState.govJobPermissions[p])),
	);

	let title = $state('');
	let description = $state('');
	let restricted = $state(appState.govJob?.Id ?? 'public');
	let submitting = $state(false);

	function jobName(id: string): string {
		const job = dataState.governmentJobsData[id] as { Name?: string } | undefined;
		return job?.Name ?? id;
	}

	async function submit(e: SubmitEvent) {
		e.preventDefault();
		if (!title.trim()) return;
		submitting = true;
		const ok = await Nui.createNotice({ title, description, restricted });
		submitting = false;
		if (ok) {
			toast.success('Notice Created');
			goBack();
		} else {
			toast.error('Unable to Create Notice');
		}
	}
</script>

<form class="wrap" onsubmit={submit}>
	<div class="fields">
		<label>
			<span>Notice Title</span>
			<input type="text" bind:value={title} maxlength="64" required />
		</label>

		<label>
			<span>Restrict Notice</span>
			<select bind:value={restricted}>
				{#if canPostPublic}
					<option value="public">Public Records Notice</option>
				{/if}
				{#each restrictOptions as job (job)}
					<option value={job}>{jobName(job)}</option>
				{/each}
			</select>
		</label>

		<label>
			<span>Notice</span>
			<RichText bind:value={description} disabled={submitting} placeholder="Enter Notice" />
		</label>
	</div>

	<div class="actions">
		<button type="button" class="btn btn-ghost" onclick={goBack} disabled={submitting}>Go Back</button>
		<button type="submit" class="btn btn-primary" disabled={submitting}>Create Notice</button>
	</div>
</form>

<style>
	.wrap {
		height: 100%;
		display: flex;
		flex-direction: column;
		padding: 1.6vh 1.2vw;
	}

	.fields {
		flex: 1;
		overflow-y: auto;
		display: flex;
		flex-direction: column;
		gap: 1.2vh;
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
		font-family: var(--font-body);
	}

	.actions {
		flex-shrink: 0;
		display: flex;
		gap: 0.8vw;
		margin-top: 1.4vh;
	}

	.btn {
		flex: 1;
		border: none;
		padding: 1vh 1vw;
		font-size: 1.2vmin;
		font-family: var(--font-body);
		cursor: pointer;
		border-radius: var(--radius);
	}

	.btn:disabled {
		opacity: 0.5;
		cursor: not-allowed;
	}

	.btn-ghost {
		background: transparent;
		color: var(--color-text-muted);
		border: var(--border-subtle);
	}

	.btn-primary {
		background: var(--color-primary);
		color: #ffffff;
	}
</style>
