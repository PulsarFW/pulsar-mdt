<script lang="ts">
	import { Nui } from '../nui';
	import { goBack, toast } from '../store/app.svelte';

	let title = $state('');
	let type = $state('');
	let summary = $state('');
	let description = $state('');

	async function submit() {
		if (!title.trim()) {
			toast.error('Must Add BOLO Title');
			return;
		}
		const ok = await Nui.createBolo({ title, type, summary: summary || undefined, description: description || undefined });
		if (ok) {
			toast.success('BOLO Created');
			goBack();
		} else toast.error('Failed to create BOLO.');
	}
</script>

<div class="wrap">
	<h2>Create BOLO</h2>
	<label>Title<input type="text" bind:value={title} /></label>
	<label>Type (e.g. Vehicle, Person)<input type="text" bind:value={type} /></label>
	<label>Summary<input type="text" bind:value={summary} /></label>
	<label>Description<textarea rows="6" bind:value={description}></textarea></label>
	<div class="actions">
		<button type="button" class="btn ghost" onclick={goBack}>Cancel</button>
		<button type="button" class="btn primary" onclick={submit}>Create</button>
	</div>
</div>

<style>
	.wrap {
		height: 100%;
		overflow-y: auto;
		padding: 1.6vh 1.4vw;
		display: flex;
		flex-direction: column;
		gap: 1vh;
		max-width: 40vw;
	}

	h2 {
		margin: 0;
		font-family: var(--font-heading);
		font-size: 1.6vmin;
	}

	label {
		display: flex;
		flex-direction: column;
		gap: 0.4vh;
		font-size: 1.05vmin;
		color: var(--color-text-muted);
	}

	input,
	textarea {
		background: var(--color-bg);
		border: var(--border-subtle);
		border-radius: var(--radius);
		color: var(--color-text);
		padding: 0.7vh 0.7vw;
		font-size: 1.1vmin;
		font-family: inherit;
	}

	.actions {
		display: flex;
		justify-content: flex-end;
		gap: 0.6vw;
		margin-top: 0.6vh;
	}

	.btn {
		border: none;
		padding: 0.8vh 1.2vw;
		font-size: 1.1vmin;
		cursor: pointer;
		border-radius: var(--radius);
	}

	.btn.ghost {
		background: transparent;
		color: var(--color-text-muted);
		border: var(--border-subtle);
	}

	.btn.primary {
		background: var(--color-primary);
		color: #fff;
	}
</style>
