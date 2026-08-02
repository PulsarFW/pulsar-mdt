<script lang="ts">
	import { Nui } from '../nui';
	import { dataState } from '../store/data.svelte';
	import type { PortalId } from '../../config';
	import NoticeBoard from '../components/NoticeBoard.svelte';
	import WarrantsWidget from '../components/WarrantsWidget.svelte';
	import GovernmentEmployeesWidget from '../components/GovernmentEmployeesWidget.svelte';
	import BoloWidget from '../components/BoloWidget.svelte';
	import Loader from '../primitives/Loader.svelte';

	let { portal }: { portal: PortalId } = $props();

	let loading = $state(true);

	async function refresh() {
		const home = await Nui.getHomeData();
		dataState.warrants = home.warrants;
		dataState.notices = home.notices;
		dataState.govWorkers = home.govWorkers;
		dataState.homeLastFetch = Date.now();
		loading = false;
	}

	$effect(() => {
		refresh();
		const timer = setInterval(refresh, 2 * 60 * 1000);
		return () => clearInterval(timer);
	});
</script>

<div class="wrap">
	{#if loading}
		<Loader static />
	{:else}
		<div class="grid">
			<NoticeBoard />
			<WarrantsWidget />
			<GovernmentEmployeesWidget />
			{#if portal === 'police'}
				<BoloWidget />
			{/if}
		</div>
	{/if}
</div>

<style>
	.wrap {
		height: 100%;
		padding: 1.6vh 1.2vw;
		overflow-y: auto;
		position: relative;
	}

	.grid {
		display: grid;
		grid-template-columns: 1fr 1fr;
		gap: 1vh 1vw;
	}
</style>
