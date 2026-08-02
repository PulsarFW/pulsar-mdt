<script lang="ts">
	import SplitView from '../primitives/SplitView.svelte';
	import RosterSearch from './roster/RosterSearch.svelte';
	import RosterDetail from './roster/RosterDetail.svelte';
	import HireForm from './roster/HireForm.svelte';
	import { appState } from '../store/app.svelte';

	let selectedSid = $state<number | null>(null);
	let hireOpen = $state(false);
	let searchRef: { refresh: () => void } | undefined = $state();

	const selectedJob = $derived(appState.govJob?.Id ?? 'police');
</script>

<div class="page">
	<SplitView hideButton expanded={true}>
		{#snippet list()}
			<RosterSearch bind:selectedSid onHire={() => (hireOpen = true)} bind:this={searchRef} />
		{/snippet}
		{#snippet detail()}
			<RosterDetail {selectedJob} sid={selectedSid} onUpdated={() => searchRef?.refresh()} />
		{/snippet}
	</SplitView>
</div>

<HireForm showing={hireOpen} jobId={selectedJob} onClose={() => (hireOpen = false)} onHired={() => searchRef?.refresh()} />

<style>
	.page {
		height: 100%;
		padding: 1vh 1vw;
	}
</style>
