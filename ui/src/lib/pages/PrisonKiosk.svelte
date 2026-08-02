<script lang="ts">
	import Icon from '../Icon.svelte';
	import Loader from '../primitives/Loader.svelte';
	import { Nui } from '../nui';
	import { toast } from '../store/app.svelte';
	import { formatDateTime } from '../util/format';
	import type { Prisoner } from '../types';

	let prisoners = $state<Prisoner[]>([]);
	let loading = $state(true);
	let search = $state('');
	let requested = $state<Set<number>>(new Set());

	$effect(() => {
		Nui.docGetPrisoners().then((res) => {
			prisoners = res;
			loading = false;
		});
	});

	const filtered = $derived.by(() => {
		const term = search.trim().toLowerCase();
		if (!term) return prisoners;
		const asSid = parseInt(term, 10);
		return prisoners.filter((p) => `${p.First} ${p.Last}`.toLowerCase().includes(term) || p.SID === asSid);
	});

	function remainingMinutes(p: Prisoner): number {
		return Math.max(0, Math.ceil((p.Jailed.Release - Date.now() / 1000) / 60));
	}

	async function requestVisitation(sid: number) {
		requested = new Set([...requested, sid]);
		const res = await Nui.docRequestVisitation(sid);
		if (res?.success) toast.success('Visitation Requested. Please Wait');
		else toast.error(res?.message || 'Error Requesting Visitation');
	}
</script>

<div class="page">
	<div class="header">
		<Icon name="user-lock" size="2vmin" />
		<h2>Inmate Terminal</h2>
	</div>

	<form class="bar" onsubmit={(e) => e.preventDefault()}>
		<input type="text" placeholder="Search by name or state ID" bind:value={search} />
		<Icon name="magnifying-glass" size="1.1vmin" />
	</form>

	<div class="results">
		{#if loading}
			<Loader />
		{:else if filtered.length === 0}
			<p class="hint">No Prisoners Awake</p>
		{:else}
			{#each filtered as prisoner (prisoner.SID)}
				<div class="row">
					<div class="info">
						<span class="name">{prisoner.First} {prisoner.Last} (State ID: {prisoner.SID})</span>
						<small>{remainingMinutes(prisoner)} min remaining of {prisoner.Jailed.Duration} min sentence</small>
						<small>Sentenced At: {formatDateTime(prisoner.Jailed.Time * 1000)} - Release: {formatDateTime(prisoner.Jailed.Release * 1000)}</small>
					</div>
					<button type="button" class="icon-btn" title="Let DOC Know You Are Here" disabled={requested.has(prisoner.SID)} onclick={() => requestVisitation(prisoner.SID)}>
						<Icon name="phone" size="1.1vmin" />
					</button>
				</div>
			{/each}
		{/if}
	</div>
</div>

<style>
	.page {
		height: 100%;
		display: flex;
		flex-direction: column;
		padding: 1.4vh 1.4vw;
		gap: 1vh;
	}

	.header {
		display: flex;
		align-items: center;
		gap: 0.6vw;
		color: var(--color-text);
	}

	.header h2 {
		margin: 0;
		font-family: var(--font-heading);
		font-size: 1.6vmin;
	}

	.bar {
		flex-shrink: 0;
		display: flex;
		align-items: center;
		gap: 0.5vw;
		background: var(--color-bg-panel);
		border-radius: var(--radius);
		padding: 0.8vh 0.8vw;
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

	.results {
		flex: 1;
		min-height: 0;
		overflow-y: auto;
		display: flex;
		flex-direction: column;
		gap: 0.5vh;
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
		background: var(--color-bg-panel);
		border-radius: var(--radius);
		padding: 0.6vh 0.8vw;
	}

	.info {
		flex: 1;
		display: flex;
		flex-direction: column;
		min-width: 0;
	}

	.name {
		font-size: 1.1vmin;
		font-weight: 600;
		color: var(--color-text);
	}

	.info small {
		color: var(--color-text-muted);
		font-size: 0.9vmin;
	}

	.icon-btn {
		flex-shrink: 0;
		background: transparent;
		border: var(--border-subtle);
		border-radius: var(--radius);
		color: var(--color-text-muted);
		cursor: pointer;
		padding: 0.6vh 0.8vw;
		display: flex;
	}

	.icon-btn:hover:not(:disabled) {
		color: var(--color-primary-light);
		border-color: var(--color-primary);
	}

	.icon-btn:disabled {
		opacity: 0.4;
		cursor: not-allowed;
	}
</style>
