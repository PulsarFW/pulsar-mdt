<script lang="ts">
	import Modal from '../../primitives/Modal.svelte';
	import { toast } from '../../store/app.svelte';
	import { EVIDENCE_TYPES } from '../../../config';

	let { showing, onSubmit, onClose }: { showing: boolean; onSubmit: (doc: { type: string; label: string; value: string }) => void; onClose: () => void } = $props();

	let type = $state(EVIDENCE_TYPES[0].value);
	let label = $state('');
	let value = $state('');

	function reset() {
		type = EVIDENCE_TYPES[0].value;
		label = '';
		value = '';
	}

	function submit() {
		if (!label.trim() || !value.trim()) {
			toast.error('Must fill out all evidence fields.');
			return;
		}
		onSubmit({ type, label, value });
		reset();
	}

	// photo evidence renders this value straight into an <img src>, every other type displays as text or a link
	const isPhoto = $derived(type === 'photo');
</script>

<Modal {showing} title="Add New Evidence" acceptLabel="Add" onAccept={submit} onClose={() => (onClose(), reset())}>
	<label>
		Type
		<select bind:value={type}>
			{#each EVIDENCE_TYPES as t (t.value)}
				<option value={t.value}>{t.label}</option>
			{/each}
		</select>
	</label>
	<label>Label<input type="text" bind:value={label} /></label>
	<label>
		{isPhoto ? 'Image URL' : 'Evidence Identifier'}
		<input type="text" bind:value placeholder={isPhoto ? 'https://... (link to the photo)' : 'Case/serial number, or a URL'} />
	</label>
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
