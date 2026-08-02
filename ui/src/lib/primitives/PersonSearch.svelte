<script lang="ts">
	import Icon from '../Icon.svelte';
	import { Nui } from '../nui';
	import type { PersonSearchResult } from '../types';

	let {
		selected = $bindable([]),
		label = 'Search Person',
		placeholder = 'Name or State ID...',
		disabled = false,
	}: {
		selected?: PersonSearchResult[];
		label?: string;
		placeholder?: string;
		disabled?: boolean;
	} = $props();

	let term = $state('');
	let options = $state<PersonSearchResult[]>([]);
	let loading = $state(false);
	let open = $state(false);
	let debounceHandle: ReturnType<typeof setTimeout> | undefined;

	const filteredOptions = $derived(options.filter((o) => !selected.some((s) => s.SID === o.SID)));

	function onInput() {
		open = true;
		clearTimeout(debounceHandle);
		if (!term.trim()) {
			options = [];
			loading = false;
			return;
		}
		loading = true;
		debounceHandle = setTimeout(async () => {
			options = await Nui.inputSearchPeople(term.trim());
			loading = false;
		}, 2000);
	}

	function pick(option: PersonSearchResult) {
		selected = [...selected, option];
		term = '';
		options = [];
		open = false;
	}

	function remove(sid: number) {
		selected = selected.filter((s) => s.SID !== sid);
	}
</script>

<div class="wrap">
	<label for="person-search-input">{label}</label>
	{#if selected.length > 0}
		<div class="chips">
			{#each selected as person (person.SID)}
				<span class="chip">
					{person.First} {person.Last} [{person.SID}]
					{#if !disabled}
						<button type="button" onclick={() => remove(person.SID)} aria-label="Remove">
							<Icon name="xmark" size="0.9vmin" />
						</button>
					{/if}
				</span>
			{/each}
		</div>
	{/if}
	{#if !disabled}
		<div class="input-row">
			<input id="person-search-input" type="text" {placeholder} bind:value={term} oninput={onInput} onfocus={() => (open = true)} />
			{#if loading}
				<span class="hint">Searching...</span>
			{/if}
		</div>
		{#if open && filteredOptions.length > 0}
			<div class="options">
				{#each filteredOptions as option (option.SID)}
					<button type="button" class="option" onclick={() => pick(option)}>
						<span>{option.First} {option.Last}</span>
						<small>State ID: {option.SID}</small>
					</button>
				{/each}
			</div>
		{/if}
	{/if}
</div>

<style>
	.wrap {
		display: flex;
		flex-direction: column;
		gap: 0.4vh;
		position: relative;
	}

	label {
		font-size: 1vmin;
		color: var(--color-text-muted);
	}

	.chips {
		display: flex;
		flex-wrap: wrap;
		gap: 0.4vh;
	}

	.chip {
		display: inline-flex;
		align-items: center;
		gap: 0.4vw;
		background: rgba(139, 92, 246, 0.15);
		color: var(--color-primary-light);
		border-radius: var(--radius);
		padding: 0.4vh 0.7vw;
		font-size: 1vmin;
	}

	.chip button {
		background: transparent;
		border: none;
		color: inherit;
		cursor: pointer;
		display: flex;
	}

	.input-row {
		display: flex;
		align-items: center;
		gap: 0.6vw;
	}

	input {
		flex: 1;
		background: var(--color-bg);
		border: var(--border-subtle);
		border-radius: var(--radius);
		color: var(--color-text);
		padding: 0.8vh 0.8vw;
		font-size: 1.1vmin;
	}

	input:focus {
		outline: none;
		border-color: var(--color-primary);
	}

	.hint {
		font-size: 0.95vmin;
		color: var(--color-text-muted);
		white-space: nowrap;
	}

	.options {
		position: absolute;
		top: 100%;
		left: 0;
		right: 0;
		z-index: 20;
		background: var(--color-bg-panel-alt);
		border: var(--border-subtle);
		border-radius: var(--radius);
		max-height: 22vh;
		overflow-y: auto;
	}

	.option {
		display: flex;
		flex-direction: column;
		width: 100%;
		text-align: left;
		background: transparent;
		border: none;
		color: var(--color-surface-text);
		cursor: pointer;
		padding: 0.7vh 0.8vw;
	}

	.option:hover {
		background: rgba(139, 92, 246, 0.12);
	}

	.option small {
		color: var(--color-surface-text-muted);
		font-size: 0.9vmin;
	}
</style>
