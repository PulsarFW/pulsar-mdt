<script lang="ts">
	import SplitView from '../primitives/SplitView.svelte';
	import PeopleSearch from './people/PeopleSearch.svelte';
	import PeopleDetail from './people/PeopleDetail.svelte';
	import { appState } from '../store/app.svelte';

	let expanded = $state(true);
	let selectedSid = $state<number | null>(appState.pageParams.person ? Number(appState.pageParams.person) : null);
</script>

<div class="page">
	<SplitView bind:expanded>
		{#snippet list()}
			<PeopleSearch bind:selectedSid />
		{/snippet}
		{#snippet detail()}
			<PeopleDetail sid={selectedSid} />
		{/snippet}
	</SplitView>
</div>

<style>
	.page {
		height: 100%;
		padding: 1vh 1vw;
	}
</style>
