<script lang="ts">
	import Icon from '../Icon.svelte';
	import Loader from '../primitives/Loader.svelte';
	import { Nui } from '../nui';
	import { navigate } from '../store/app.svelte';
	import { VEHICLE_TYPES } from '../../config';
	import type { FleetVehicle } from '../types';

	let vehicles = $state<FleetVehicle[]>([]);
	let loading = $state(true);
	let search = $state('');

	$effect(() => {
		Nui.viewVehicleFleet().then((res) => {
			vehicles = res || [];
			loading = false;
		});
	});

	const filtered = $derived.by(() => {
		const term = search.trim().toLowerCase();
		if (!term) return vehicles;
		return vehicles.filter((v) => v.VIN.toLowerCase().includes(term) || v.RegisteredPlate?.toLowerCase().includes(term) || `${v.Make} ${v.Model}`.toLowerCase().includes(term));
	});

	function assignedLabel(v: FleetVehicle): string {
		if (!v.GovAssigned || v.GovAssigned.length === 0) return 'Non Assigned';
		return v.GovAssigned.map((g) => `(${g.Callsign ?? 'N/A'}) ${g.First[0]}. ${g.Last}`).join(', ');
	}
</script>

<div class="page">
	<div class="panel">
		<form class="bar" onsubmit={(e) => e.preventDefault()}>
			<input type="text" placeholder="Search By Plate, VIN or Make/Model" bind:value={search} />
			<Icon name="magnifying-glass" size="1.1vmin" />
		</form>

		<div class="results">
			{#if loading}
				<Loader />
			{:else if filtered.length === 0}
				<p class="hint">No fleet vehicles found.</p>
			{:else}
				{#each filtered as vehicle (vehicle.VIN)}
					<button type="button" class="row" onclick={() => navigate('vehicles', { vin: vehicle.VIN, fleetManage: '1' })}>
						<div class="info">
							<span class="name">{vehicle.Type ? `(${VEHICLE_TYPES[vehicle.Type]}) ` : ''}{vehicle.Make} {vehicle.Model}</span>
							<small>VIN: {vehicle.VIN} - Plate: {vehicle.RegisteredPlate}</small>
							<small>Assigned: {assignedLabel(vehicle)}</small>
							<small>Storage: {vehicle.Storage?.Name ?? 'Unknown'}</small>
						</div>
					</button>
				{/each}
			{/if}
		</div>
	</div>
</div>

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
		background: var(--color-bg-panel-alt);
		border: 1px solid transparent;
		border-radius: var(--radius);
		padding: 0.7vh 0.7vw;
		cursor: pointer;
		text-align: left;
		color: var(--color-surface-text);
	}

	.row:hover {
		border-color: rgba(139, 92, 246, 0.3);
	}

	.info {
		display: flex;
		flex-direction: column;
		min-width: 0;
	}

	.name {
		font-size: 1.15vmin;
		font-weight: 600;
	}

	.info small {
		color: var(--color-surface-text-muted);
		font-size: 0.95vmin;
	}
</style>
