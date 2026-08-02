<script lang="ts">
	import Icon from '../Icon.svelte';
	import Modal from '../primitives/Modal.svelte';
	import { Nui } from '../nui';
	import { dataState } from '../store/data.svelte';
	import { toast } from '../store/app.svelte';
	import { CHARGE_TYPES } from '../../config';
	import { CURRENCY } from '../util/format';
	import type { Charge } from '../types';

	let search = $state('');
	const filtered = $derived(dataState.charges.filter((c) => c.title.toLowerCase().includes(search.toLowerCase())).sort((a, b) => a.type - b.type || a.title.localeCompare(b.title)));

	let editing = $state<Charge | null>(null);
	let creating = $state(false);
	let form = $state<{ type: number; title: string; description: string; fine: number; jail: number; points: number }>({
		type: 1,
		title: '',
		description: '',
		fine: 0,
		jail: 0,
		points: 0,
	});

	function openCreate() {
		form = { type: 1, title: '', description: '', fine: 0, jail: 0, points: 0 };
		creating = true;
	}

	function openEdit(charge: Charge) {
		form = { type: charge.type, title: charge.title, description: charge.description, fine: charge.fine, jail: charge.jail, points: charge.points };
		editing = charge;
	}

	function closeModal() {
		creating = false;
		editing = null;
	}

	async function submit() {
		if (!form.title.trim()) {
			toast.error('Must Add Charge Title');
			return;
		}
		if (editing) {
			const ok = await Nui.updateCharge({ ...editing, ...form });
			if (ok) toast.success('Charge updated.');
			else toast.error('Failed to update charge.');
		} else {
			const ok = await Nui.createCharge(form);
			if (ok) toast.success('Charge created.');
			else toast.error('Failed to create charge.');
		}
		closeModal();
	}

	let deleting = $state<Charge | null>(null);

	async function submitDelete() {
		if (!deleting) return;
		const ok = await Nui.deleteCharge({ id: deleting.id });
		if (ok) toast.success('Charge deleted.');
		else toast.error('Failed to delete charge.');
		deleting = null;
	}

	function typeLabel(type: number): string {
		return CHARGE_TYPES.find((t) => t.value === type)?.label ?? 'Unknown';
	}
</script>

<div class="page">
	<div class="panel">
		<form class="bar" onsubmit={(e) => e.preventDefault()}>
			<input type="text" placeholder="Search charges..." bind:value={search} />
			<Icon name="magnifying-glass" size="1.1vmin" />
			<button type="button" class="icon-btn create" onclick={openCreate} title="Add Charge">
				<Icon name="plus" size="1.1vmin" />
			</button>
		</form>

		<div class="results">
			{#each filtered as charge (charge.id)}
				<div class="row">
					<button type="button" class="info" onclick={() => openEdit(charge)}>
						<span class="name type-{charge.type}">{charge.title}</span>
						<small>{typeLabel(charge.type)} - Fine: {CURRENCY.format(charge.fine)} - Jail: {charge.jail}mo - Points: {charge.points}</small>
					</button>
					<button type="button" class="icon-btn" title="Delete" onclick={() => (deleting = charge)}>
						<Icon name="trash" size="1vmin" />
					</button>
				</div>
			{/each}
			{#if filtered.length === 0}
				<p class="hint">No charges found.</p>
			{/if}
		</div>
	</div>
</div>

<Modal showing={creating || Boolean(editing)} title={editing ? 'Edit Charge' : 'Add Charge'} onAccept={submit} onClose={closeModal}>
	<label>
		Type
		<select bind:value={form.type}>
			{#each CHARGE_TYPES as t (t.value)}
				<option value={t.value}>{t.label}</option>
			{/each}
		</select>
	</label>
	<label>Title<input type="text" bind:value={form.title} /></label>
	<label>Description<textarea rows="3" bind:value={form.description}></textarea></label>
	<label>Fine ($)<input type="number" min="0" bind:value={form.fine} /></label>
	<label>Jail (months)<input type="number" min="0" bind:value={form.jail} /></label>
	<label>License Points<input type="number" min="0" bind:value={form.points} /></label>
</Modal>

{#if deleting}
	<Modal showing={Boolean(deleting)} title="Delete Charge" acceptLabel="Delete" onAccept={submitDelete} onClose={() => (deleting = null)}>
		<p>Are you sure you want to delete "{deleting.title}"?</p>
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
	}

	.bar {
		flex-shrink: 0;
		display: flex;
		align-items: center;
		gap: 0.5vw;
		padding: 0.8vh 0.8vw;
		border-bottom: var(--border-subtle);
		color: var(--color-text-muted);
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
		flex-shrink: 0;
		background: transparent;
		border: var(--border-subtle);
		border-radius: var(--radius);
		color: var(--color-text-muted);
		cursor: pointer;
		padding: 0.5vh 0.7vw;
		display: flex;
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
		gap: 0.5vw;
		background: var(--color-bg-panel-alt);
		border-radius: var(--radius);
		padding: 0.2vh 0.5vw;
	}

	.info {
		flex: 1;
		display: flex;
		flex-direction: column;
		min-width: 0;
		background: transparent;
		border: none;
		text-align: left;
		cursor: pointer;
		color: var(--color-surface-text);
		padding: 0.5vh 0.2vw;
	}

	.name {
		font-size: 1.1vmin;
		font-weight: 600;
	}

	.name.type-3 {
		color: var(--color-error);
	}

	.info small {
		color: var(--color-surface-text-muted);
		font-size: 0.9vmin;
	}

	.row .icon-btn {
		color: var(--color-surface-text-muted);
	}

	label {
		display: flex;
		flex-direction: column;
		gap: 0.4vh;
		font-size: 1.05vmin;
		color: var(--color-text-muted);
	}

	input,
	select,
	textarea {
		background-color: var(--color-bg);
		border: var(--border-subtle);
		border-radius: var(--radius);
		color: var(--color-text);
		padding: 0.7vh 0.7vw;
		font-size: 1.1vmin;
		font-family: inherit;
	}
</style>
