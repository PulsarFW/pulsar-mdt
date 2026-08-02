<script lang="ts">
	import Modal from '../../primitives/Modal.svelte';
	import { Nui } from '../../nui';
	import { toast } from '../../store/app.svelte';
	import { dataState } from '../../store/data.svelte';

	let { showing, jobId, onClose, onHired }: { showing: boolean; jobId: string; onClose: () => void; onHired: () => void } = $props();

	const jobData = $derived(dataState.governmentJobsData[jobId] as { Name?: string; Workplaces?: { Id: string; Name: string; Grades: { Id: string; Name: string; Level: number }[] }[] } | undefined);

	let targetSid = $state('');
	let workplaceId = $state('');
	let gradeName = $state('');
	let gradeId = $state('');

	$effect(() => {
		if (showing) {
			targetSid = '';
			const wp = jobData?.Workplaces?.[0];
			setWorkplace(wp?.Id ?? '');
		}
	});

	function setWorkplace(id: string) {
		workplaceId = id;
		const wp = jobData?.Workplaces?.find((w) => w.Id === id);
		const lowest = wp ? [...wp.Grades].sort((a, b) => a.Level - b.Level)[0] : undefined;
		gradeId = lowest?.Id ?? '';
		gradeName = lowest?.Name ?? '';
	}

	async function submit() {
		const sid = parseInt(targetSid, 10);
		if (Number.isNaN(sid)) {
			toast.error('Invalid state ID.');
			return;
		}
		if (!workplaceId || !gradeId) {
			toast.error('Must select a department.');
			return;
		}
		const ok = await Nui.hireEmployee(sid, jobId, workplaceId, gradeId);
		if (ok) {
			toast.success('Employee hired.');
			onHired();
			onClose();
		} else toast.error('Failed to hire employee.');
	}
</script>

<Modal {showing} title="Hire Employee" acceptLabel="Hire" onAccept={submit} {onClose}>
	<label>New Hire State ID<input type="text" bind:value={targetSid} /></label>
	{#if jobId === 'police' || jobId === 'government'}
		<label>
			Department
			<select value={workplaceId} onchange={(e) => setWorkplace((e.target as HTMLSelectElement).value)}>
				{#each jobData?.Workplaces ?? [] as w (w.Id)}
					<option value={w.Id}>{w.Name}</option>
				{/each}
			</select>
		</label>
	{/if}
	<label>Rank<input type="text" value={gradeName} disabled /></label>
</Modal>

<style>
	label {
		display: flex;
		flex-direction: column;
		gap: 0.4vh;
		font-size: 1.05vmin;
		color: var(--color-text-muted);
	}

	input,
	select {
		background-color: var(--color-bg);
		border: var(--border-subtle);
		border-radius: var(--radius);
		color: var(--color-text);
		padding: 0.7vh 0.7vw;
		font-size: 1.1vmin;
	}
</style>
