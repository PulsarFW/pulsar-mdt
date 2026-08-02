<script lang="ts">
	import SplitView from '../primitives/SplitView.svelte';
	import ReportsSearch from './reports/ReportsSearch.svelte';
	import ReportView from './reports/ReportView.svelte';
	import { appState } from '../store/app.svelte';

	let expanded = $state(true);
	let selectedId = $state<number | null>(appState.pageParams.report ? Number(appState.pageParams.report) : null);
	let creating = $state(appState.pageParams.mode === 'create');
	const preSuspectSid = appState.pageParams.addSuspect ? Number(appState.pageParams.addSuspect) : null;
	const initialTerm = appState.pageParams.search ?? '';

	function onCreate() {
		creating = true;
		selectedId = null;
	}

	function onCreated(id: number) {
		creating = false;
		selectedId = id;
	}

	// picking a row while in create mode should drop back to viewing that report
	$effect(() => {
		if (selectedId !== null) creating = false;
	});
</script>

<div class="page">
	<SplitView bind:expanded>
		{#snippet list()}
			<ReportsSearch bind:selectedId {initialTerm} {onCreate} />
		{/snippet}
		{#snippet detail()}
			<ReportView reportId={creating ? null : selectedId} {creating} {preSuspectSid} {onCreated} />
		{/snippet}
	</SplitView>
</div>

<style>
	.page {
		height: 100%;
		padding: 1vh 1vw;
	}
</style>
