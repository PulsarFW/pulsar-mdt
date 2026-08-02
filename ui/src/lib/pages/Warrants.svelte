<script lang="ts">
	import SplitView from '../primitives/SplitView.svelte';
	import WarrantsSearch from './warrants/WarrantsSearch.svelte';
	import WarrantDetail from './warrants/WarrantDetail.svelte';
	import { appState } from '../store/app.svelte';

	let expanded = $state(true);
	let selectedId = $state<number | null>(appState.pageParams.id ? Number(appState.pageParams.id) : null);
</script>

<div class="page">
	<SplitView bind:expanded>
		{#snippet list()}
			<WarrantsSearch bind:selectedId />
		{/snippet}
		{#snippet detail()}
			<WarrantDetail id={selectedId} />
		{/snippet}
	</SplitView>
</div>

<style>
	.page {
		height: 100%;
		padding: 1vh 1vw;
	}
</style>
