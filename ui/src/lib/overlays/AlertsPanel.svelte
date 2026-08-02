<script lang="ts">
	import { appState } from '../store/app.svelte';
	import { alertsState } from '../store/alerts.svelte';
	import Notifications from './alerts/Notifications.svelte';
	import Roster from './alerts/Roster.svelte';
	import DispatchLog from './alerts/DispatchLog.svelte';

	const eligible = $derived(
		Boolean(appState.govJobPermissions.police_alerts) ||
			Boolean(appState.govJobPermissions.ems_alerts) ||
			Boolean(appState.govJobPermissions.tow_alerts) ||
			Boolean(appState.govJobPermissions.doc_alerts),
	);
</script>

{#if eligible && alertsState.connected}
	<div class="feed-wrap" class:showing={alertsState.showing}>
		<Notifications />
		{#if alertsState.showing}
			<Roster />
		{/if}
	</div>
	{#if alertsState.showing && appState.govJob?.Id !== 'tow'}
		<DispatchLog />
	{/if}
{/if}

<style>
	.feed-wrap {
		position: fixed;
		top: 0;
		bottom: 0;
		right: 0;
		width: min(100%, 62.5vw);
		max-width: 1000px;
		padding: 1.6vh 0.8vw 0.9vh 0;
		box-sizing: border-box;
		z-index: -1;
		pointer-events: none;
	}

	.feed-wrap.showing {
		z-index: 40;
	}
</style>
