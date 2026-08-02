<script lang="ts">
	import Modal from '../../primitives/Modal.svelte';
	import ChargeCalculator from '../../primitives/ChargeCalculator.svelte';
	import { Nui } from '../../nui';
	import { toast } from '../../store/app.svelte';
	import { PLEA_TYPES } from '../../../config';
	import type { PersonSearchResult, ReportSuspect, SuspectCharge } from '../../types';

	let {
		showing,
		existing = null,
		preSuspectSid = null,
		onSubmit,
		onClose,
	}: {
		showing: boolean;
		existing?: ReportSuspect | null;
		preSuspectSid?: number | null;
		onSubmit: (suspect: { SID: number; First: string; Last: string; Licenses?: ReportSuspect['Licenses']; plea: string; charges: SuspectCharge[] }) => void;
		onClose: () => void;
	} = $props();

	let term = $state('');
	let options = $state<PersonSearchResult[]>([]);
	let loading = $state(false);
	let picked = $state<PersonSearchResult | null>(null);
	let plea = $state('unknown');
	let charges = $state<SuspectCharge[]>([]);
	let debounceHandle: ReturnType<typeof setTimeout> | undefined;

	$effect(() => {
		if (!showing) return;
		if (existing) {
			picked = { SID: existing.SID, First: existing.First, Last: existing.Last };
			plea = existing.plea ?? 'unknown';
			charges = existing.charges;
		} else {
			picked = null;
			plea = 'unknown';
			charges = [];
			term = '';
			options = [];
			if (preSuspectSid) {
				Nui.inputSearchSID(String(preSuspectSid)).then((res) => {
					if (res[0]) picked = res[0];
				});
			}
		}
	});

	function onInput() {
		clearTimeout(debounceHandle);
		if (!term.trim()) {
			options = [];
			return;
		}
		loading = true;
		debounceHandle = setTimeout(async () => {
			options = await Nui.inputSearchPeople(term.trim());
			loading = false;
		}, 1000);
	}

	function pick(option: PersonSearchResult) {
		picked = option;
		term = '';
		options = [];
	}

	function submit() {
		if (!picked) {
			toast.error('Must Select Suspect');
			return;
		}
		if (!plea) {
			toast.error('Must Select Plea');
			return;
		}
		if (charges.length === 0) {
			toast.error('Must Add Charges');
			return;
		}
		onSubmit({ SID: picked.SID, First: picked.First, Last: picked.Last, Licenses: picked.Licenses, plea, charges });
	}
</script>

<Modal {showing} title={existing ? 'Edit Suspect' : 'Add Suspect'} acceptLabel={existing ? 'Save' : 'Add'} onAccept={submit} onClose={() => (onClose(), (charges = []))}>
	<label>
		Suspect
		{#if existing || picked}
			<input type="text" value={picked ? `${picked.First} ${picked.Last} [${picked.SID}]` : ''} disabled />
		{:else}
			<input type="text" placeholder="Search name or state ID..." bind:value={term} oninput={onInput} />
			{#if loading}<small>Searching...</small>{/if}
			{#if options.length > 0}
				<div class="options">
					{#each options as option (option.SID)}
						<button type="button" class="option" onclick={() => pick(option)}>{option.First} {option.Last} [{option.SID}]</button>
					{/each}
				</div>
			{/if}
		{/if}
	</label>

	<label>
		Plea
		<select bind:value={plea}>
			{#each PLEA_TYPES as p (p.value)}
				<option value={p.value}>{p.label}</option>
			{/each}
		</select>
	</label>

	<ChargeCalculator bind:selected={charges} />

	<p class="hint">
		Please remember to press Sentence on the suspect after the report is submitted! It also checks their parole. Charges should be stacked - the system
		stacks fines but not time for the same charge.
	</p>
</Modal>

<style>
	label {
		display: flex;
		flex-direction: column;
		gap: 0.4vh;
		font-size: 1.05vmin;
		color: var(--color-text-muted);
		position: relative;
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

	.options {
		position: absolute;
		top: 100%;
		left: 0;
		right: 0;
		z-index: 20;
		background: var(--color-bg-panel-alt);
		border: var(--border-subtle);
		border-radius: var(--radius);
		max-height: 20vh;
		overflow-y: auto;
	}

	.option {
		display: block;
		width: 100%;
		text-align: left;
		background: transparent;
		border: none;
		color: var(--color-surface-text);
		cursor: pointer;
		padding: 0.6vh 0.7vw;
		font-size: 1.05vmin;
	}

	.option:hover {
		background: rgba(139, 92, 246, 0.12);
	}

	.hint {
		color: var(--color-text-muted);
		font-size: 0.9vmin;
	}
</style>
