<script lang="ts">
	import Icon from '../../Icon.svelte';
	import Loader from '../../primitives/Loader.svelte';
	import Modal from '../../primitives/Modal.svelte';
	import { Nui } from '../../nui';
	import { navigate, toast } from '../../store/app.svelte';
	import { formatDateTime } from '../../util/format';
	import type { Firearm } from '../../types';

	const FLAG_TITLES = ['Stolen', 'Seized', 'Flagged', 'PD Trashed/Broken'];

	let { serial }: { serial: string | null } = $props();

	let firearm = $state<Firearm | null>(null);
	let loading = $state(false);

	$effect(() => {
		if (serial === null) {
			firearm = null;
			return;
		}
		loading = true;
		Nui.viewFirearm(serial).then((res) => {
			firearm = res || null;
			loading = false;
		});
	});

	let modal = $state<'flag' | 'flag-view' | null>(null);
	let flagTitle = $state(FLAG_TITLES[0]);
	let flagDescription = $state('');
	let viewingFlagIdx = $state(-1);

	function openFlagForm() {
		flagTitle = FLAG_TITLES[0];
		flagDescription = '';
		modal = 'flag';
	}

	function viewFlag(idx: number) {
		viewingFlagIdx = idx;
		modal = 'flag-view';
	}

	async function submitFlag() {
		if (!firearm) return;
		const created = await Nui.addFirearmFlag(firearm.serial, { title: flagTitle, description: flagDescription });
		if (created) {
			firearm.flags = [...(firearm.flags ?? []), created];
			toast.success('Flag added.');
		} else toast.error('Failed to add flag.');
		modal = null;
	}

	async function dismissFlag() {
		if (!firearm || viewingFlagIdx < 0) return;
		const flag = firearm.flags?.[viewingFlagIdx];
		if (!flag) return;
		const ok = await Nui.removeFirearmFlag(firearm.serial, flag.id);
		if (ok) {
			firearm.flags = firearm.flags?.filter((_, i) => i !== viewingFlagIdx);
			toast.success('Flag removed.');
		} else toast.error('Failed to remove flag.');
		modal = null;
	}
</script>

<div class="detail">
	{#if serial === null}
		<div class="empty">
			<Icon name="gun" size="4vmin" />
			<p>No Firearm Selected</p>
		</div>
	{:else if loading}
		<Loader />
	{:else if !firearm}
		<div class="empty">
			<Icon name="gun" size="4vmin" />
			<p>Firearm Not Found</p>
		</div>
	{:else}
		<div class="scroll">
			<div class="header">
				<h2>{firearm.model ?? 'Unknown'}</h2>
				<div class="meta">
					<span>Serial Number: {firearm.serial}</span>
					<span>Purchased: {formatDateTime(firearm.purchased)}</span>
				</div>
				<div class="meta">
					{#if firearm.owner_sid}
						<button type="button" class="link" onclick={() => navigate('people', { person: String(firearm!.owner_sid) })}>
							Owner: {firearm.owner_name} ({firearm.owner_sid})
						</button>
					{:else}
						<span>Owner: {firearm.owner_name ?? 'Unknown'}</span>
					{/if}
				</div>
			</div>

			<section>
				<div class="section-head">
					<h3>Flags</h3>
					<button type="button" class="icon-btn" onclick={openFlagForm}><Icon name="plus" size="1vmin" /></button>
				</div>
				{#if firearm.flags && firearm.flags.length > 0}
					<div class="chips">
						{#each firearm.flags as flag, i (flag.id)}
							<button type="button" class="chip" onclick={() => viewFlag(i)}>{flag.title}</button>
						{/each}
					</div>
				{:else}
					<p class="hint">No flags.</p>
				{/if}
			</section>
		</div>
	{/if}
</div>

{#if firearm}
	<Modal showing={modal === 'flag'} title="Add Firearm Flag" onAccept={submitFlag} onClose={() => (modal = null)}>
		<label>
			Title
			<select bind:value={flagTitle}>
				{#each FLAG_TITLES as t (t)}
					<option value={t}>{t}</option>
				{/each}
			</select>
		</label>
		<label>Description<textarea bind:value={flagDescription} rows="3"></textarea></label>
	</Modal>

	<Modal showing={modal === 'flag-view'} title={firearm.flags?.[viewingFlagIdx]?.title ?? ''} acceptLabel="Remove Flag" onAccept={dismissFlag} onClose={() => (modal = null)}>
		{#if firearm.flags?.[viewingFlagIdx]}
			<p>Issued: {formatDateTime(firearm.flags[viewingFlagIdx].date)}</p>
			<p>
				Issued By: {firearm.flags[viewingFlagIdx].author_sid
					? `[${firearm.flags[viewingFlagIdx].author_callsign ?? 'N/A'}] ${firearm.flags[viewingFlagIdx].author_first} ${firearm.flags[viewingFlagIdx].author_last}`
					: 'Unknown'}
			</p>
			<p>Reason: {firearm.flags[viewingFlagIdx].description}</p>
		{/if}
	</Modal>
{/if}

<style>
	.detail {
		display: flex;
		flex-direction: column;
		height: 100%;
	}

	.empty {
		margin: auto;
		text-align: center;
		color: var(--color-text-muted);
	}

	.scroll {
		overflow-y: auto;
		padding: 1.2vh 1.2vw;
		display: flex;
		flex-direction: column;
		gap: 1.4vh;
	}

	.header h2 {
		margin: 0 0 0.4vh;
		font-family: var(--font-heading);
		font-size: 1.7vmin;
	}

	.meta {
		display: flex;
		flex-wrap: wrap;
		gap: 1vw;
		font-size: 1.05vmin;
		color: var(--color-text-muted);
		margin-bottom: 0.3vh;
	}

	.link {
		background: transparent;
		border: none;
		color: var(--color-primary-light);
		cursor: pointer;
		padding: 0;
		font-size: inherit;
	}

	.section-head {
		display: flex;
		align-items: center;
		justify-content: space-between;
		margin-bottom: 0.6vh;
	}

	section h3 {
		margin: 0;
		font-size: 1.15vmin;
		text-transform: uppercase;
		letter-spacing: 0.03em;
		color: var(--color-text-muted);
	}

	.icon-btn {
		background: transparent;
		border: var(--border-subtle);
		border-radius: var(--radius);
		color: var(--color-text-muted);
		cursor: pointer;
		padding: 0.4vh 0.7vw;
		display: flex;
		align-items: center;
	}

	.icon-btn:hover {
		color: var(--color-primary-light);
	}

	.chips {
		display: flex;
		flex-wrap: wrap;
		gap: 0.5vh;
	}

	.chip {
		display: inline-flex;
		align-items: center;
		background: rgba(139, 92, 246, 0.15);
		color: var(--color-primary-light);
		border: none;
		border-radius: var(--radius);
		padding: 0.5vh 0.8vw;
		font-size: 1.05vmin;
		cursor: pointer;
	}

	.hint {
		color: var(--color-text-muted);
		font-size: 1.05vmin;
	}

	label {
		display: flex;
		flex-direction: column;
		gap: 0.4vh;
		font-size: 1.05vmin;
		color: var(--color-text-muted);
	}

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
