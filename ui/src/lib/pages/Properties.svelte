<script lang="ts">
	import Icon from '../Icon.svelte';
	import Loader from '../primitives/Loader.svelte';
	import Pagination from '../primitives/Pagination.svelte';
	import { Nui } from '../nui';
	import { toast } from '../store/app.svelte';
	import { PROPERTY_TYPES, PROPERTIES_PER_PAGE } from '../../config';
	import type { Property } from '../types';

	let loading = $state(true);
	let results = $state<Property[]>([]);
	let term = $state('');
	let page = $state(1);

	async function load() {
		loading = true;
		results = (await Nui.getProperties()) || [];
		loading = false;
	}

	load();

	const filtered = $derived.by(() => {
		const q = term.trim().toLowerCase();
		if (!q) return results;
		return results.filter((p) => {
			if (p.label.toLowerCase().includes(q)) return true;
			if (p.owner && typeof p.owner === 'object') {
				if (`${p.owner.First} ${p.owner.Last}`.toLowerCase().includes(q)) return true;
				if (String(p.owner.SID) === q) return true;
			}
			return false;
		});
	});

	const pages = $derived(Math.max(1, Math.ceil(filtered.length / PROPERTIES_PER_PAGE)));
	const pageResults = $derived(filtered.slice((page - 1) * PROPERTIES_PER_PAGE, page * PROPERTIES_PER_PAGE));

	$effect(() => {
		filtered;
		page = 1;
	});

	function ownerLabel(p: Property): string {
		if (p.owner && typeof p.owner === 'object') return `${p.owner.First} ${p.owner.Last} (${p.owner.SID})`;
		if (p.owner === true) return 'Owned';
		return 'Available';
	}

	async function markGps(p: Property) {
		if (p._id === undefined) return;
		const ok = await Nui.findProperty(p._id);
		if (ok) toast.success('Marked Successfully');
		else toast.error('Error Marking GPS');
	}
</script>

<div class="page">
	<div class="bar">
		<input type="text" placeholder="Search by address, owner name, or owner state ID" bind:value={term} />
		{#if term}
			<button type="button" class="icon-btn" onclick={() => (term = '')} title="Clear">
				<Icon name="xmark" size="1.1vmin" />
			</button>
		{/if}
	</div>

	<div class="results">
		{#if loading}
			<Loader />
		{:else if pageResults.length === 0}
			<p class="hint">No Properties Found</p>
		{:else}
			{#each pageResults as property (property._id)}
				<div class="row">
					<div class="col">
						<span class="col-label">Address</span>
						<span class="col-value">{property.label}</span>
					</div>
					<div class="col owner">
						<span class="col-label">Owner</span>
						<span class="col-value">{ownerLabel(property)}</span>
					</div>
					<div class="col type">
						<span class="col-label">Type</span>
						<span class="col-value">{PROPERTY_TYPES[property.type] ?? 'Property'}</span>
					</div>
					<button type="button" class="gps-btn" onclick={() => markGps(property)} title="Mark GPS">
						<Icon name="location-crosshairs" />
					</button>
				</div>
			{/each}
		{/if}
	</div>

	<Pagination {page} {pages} onChange={(p) => (page = p)} />
</div>

<style>
	.page {
		display: flex;
		flex-direction: column;
		height: 100%;
		padding: 1vh 1vw;
		gap: 0.8vh;
	}

	.bar {
		display: flex;
		gap: 0.4vw;
	}

	.bar input {
		flex: 1;
		background: var(--color-bg-panel);
		border: var(--border-subtle);
		border-radius: var(--radius);
		color: var(--color-text);
		padding: 0.8vh 0.8vw;
		font-size: 1.1vmin;
	}

	.bar input:focus {
		outline: none;
		border-color: var(--color-primary);
	}

	.icon-btn {
		background: transparent;
		border: var(--border-subtle);
		border-radius: var(--radius);
		color: var(--color-text-muted);
		cursor: pointer;
		padding: 0 0.8vw;
		display: flex;
		align-items: center;
	}

	.icon-btn:hover {
		color: var(--color-primary-light);
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
		margin-top: 4vh;
	}

	.row {
		display: flex;
		align-items: center;
		gap: 1vw;
		background: var(--color-bg-panel);
		border: var(--border-subtle);
		border-radius: var(--radius);
		padding: 1vh 1vw;
	}

	.col {
		display: flex;
		flex-direction: column;
		min-width: 0;
		flex: 2;
	}

	.col.owner {
		flex: 1.6;
	}

	.col.type {
		flex: 1;
	}

	.col-label {
		font-size: 0.85vmin;
		color: var(--color-text-muted);
		text-transform: uppercase;
		letter-spacing: 0.03em;
	}

	.col-value {
		font-size: 1.05vmin;
		color: var(--color-text);
		overflow: hidden;
		text-overflow: ellipsis;
		white-space: nowrap;
	}

	.gps-btn {
		flex-shrink: 0;
		background: transparent;
		border: none;
		color: var(--color-text-muted);
		cursor: pointer;
		padding: 0.4vh;
	}

	.gps-btn:hover {
		color: var(--color-primary-light);
	}
</style>
