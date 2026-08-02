<script lang="ts">
	import SplitView from '../primitives/SplitView.svelte';
	import VehiclesSearch from './vehicles/VehiclesSearch.svelte';
	import VehicleDetail from './vehicles/VehicleDetail.svelte';
	import { appState } from '../store/app.svelte';

	// arriving from Fleet Manager (vin+fleetManage=1 params) auto-collapses the search pane and unlocks the Storage Location/Assigned Drivers/Track fields on VehicleDetail
	const fleetManage = appState.pageParams.fleetManage === '1';
	let expanded = $state(!fleetManage);
	let selectedVin = $state<string | null>(appState.pageParams.vin ?? null);
</script>

<div class="page">
	<SplitView bind:expanded hideButton={fleetManage}>
		{#snippet list()}
			<VehiclesSearch bind:selectedVin />
		{/snippet}
		{#snippet detail()}
			<VehicleDetail vin={selectedVin} {fleetManage} />
		{/snippet}
	</SplitView>
</div>

<style>
	.page {
		height: 100%;
		padding: 1vh 1vw;
	}
</style>
