<script lang="ts">
	import SplitView from '../primitives/SplitView.svelte';
	import FirearmsSearch from './firearms/FirearmsSearch.svelte';
	import FirearmDetail from './firearms/FirearmDetail.svelte';

	let expanded = $state(true);
	let selectedSerial = $state<string | null>(null);
</script>

<div class="page">
	<SplitView bind:expanded>
		{#snippet list()}
			<FirearmsSearch bind:selectedSerial />
		{/snippet}
		{#snippet detail()}
			<FirearmDetail serial={selectedSerial} />
		{/snippet}
	</SplitView>
</div>

<style>
	.page {
		height: 100%;
		padding: 1vh 1vw;
	}
</style>
