<script lang="ts">
	import Icon from '../../Icon.svelte';
	import Modal from '../../primitives/Modal.svelte';
	import { alertsState, addRadioInfo, updateRadioInfo, removeRadioInfo } from '../../store/alerts.svelte';
	import { Nui } from '../../nui';

	let openIndex = $state<number | null>(null);
	let mode = $state<'add' | 'edit'>('add');
	let radio = $state('');
	let text = $state('');

	function openAdd() {
		radio = '';
		text = '';
		mode = 'add';
		openIndex = -1;
	}

	function openEdit(i: number) {
		radio = alertsState.radioNames[i].radio;
		text = alertsState.radioNames[i].text;
		mode = 'edit';
		openIndex = i;
	}

	function close() {
		openIndex = null;
	}

	function submit() {
		if (!radio.trim() || !text.trim()) return;
		if (mode === 'add') {
			addRadioInfo(radio.trim(), text.trim());
		} else if (openIndex !== null && openIndex >= 0) {
			updateRadioInfo(openIndex, radio.trim(), text.trim());
		}
		close();
	}

	function remove(i: number) {
		removeRadioInfo(i);
	}

	function join(freq: string) {
		Nui.swapToRadio(freq);
	}
</script>

<div class="radios">
	{#each alertsState.radioNames as r, i (r.radio + i)}
		<button type="button" class="chip" onclick={() => openEdit(i)}>
			<Icon name="walkie-talkie" />
			<span>{r.radio} - {r.text}</span>
		</button>
	{/each}
	<button type="button" class="chip add" onclick={openAdd}>
		<Icon name="plus" />
		<span>Add</span>
	</button>
</div>

<Modal
	showing={openIndex !== null}
	title={mode === 'add' ? 'Add Radio Info' : 'Update Radio Info'}
	acceptLabel={mode === 'add' ? 'Add' : 'Save'}
	onAccept={submit}
	onClose={close}
>
	<label>
		Radio Frequency
		<input type="text" maxlength="5" bind:value={radio} disabled={mode === 'edit'} />
	</label>
	<label>
		Info
		<input type="text" maxlength="32" bind:value={text} />
	</label>
	{#if mode === 'edit' && openIndex !== null && openIndex >= 0}
		<button type="button" class="join-btn" onclick={() => join(radio)}>Switch to Channel</button>
		<button type="button" class="delete-btn" onclick={() => (remove(openIndex as number), close())}>Delete</button>
	{/if}
</Modal>

<style>
	.radios {
		display: flex;
		align-items: center;
		gap: 0.4vw;
		overflow-x: auto;
		background: var(--color-bg-panel-alt);
		padding: 0.5vh 0.6vw;
	}

	.chip {
		flex-shrink: 0;
		display: flex;
		align-items: center;
		gap: 0.4vw;
		background: rgba(255, 255, 255, 0.08);
		border: none;
		border-radius: 4px;
		color: var(--color-surface-text);
		padding: 0.5vh 0.7vw;
		font-size: 0.95vmin;
		cursor: pointer;
		white-space: nowrap;
	}

	.chip:hover {
		background: rgba(139, 92, 246, 0.2);
	}

	.chip.add {
		color: var(--color-nav-text-active);
	}

	label {
		display: flex;
		flex-direction: column;
		gap: 0.4vh;
		font-size: 1.05vmin;
		color: var(--color-text-muted);
	}

	input {
		background: var(--color-bg);
		border: var(--border-subtle);
		border-radius: var(--radius);
		color: var(--color-text);
		padding: 0.7vh 0.7vw;
		font-size: 1.1vmin;
	}

	.join-btn,
	.delete-btn {
		border: var(--border-subtle);
		background: transparent;
		border-radius: var(--radius);
		padding: 0.7vh 0.7vw;
		font-size: 1vmin;
		cursor: pointer;
	}

	.join-btn {
		color: var(--color-text);
	}

	.delete-btn {
		color: var(--color-error);
	}
</style>
