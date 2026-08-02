<script lang="ts">
	import { alertsState } from '../../store/alerts.svelte';
	import AlertCard from './AlertCard.svelte';

	const myUnit = $derived(alertsState.myUnit);
	const myUnitData = $derived(myUnit ? (alertsState.units[myUnit.job] ?? []).find((u) => u.primary === myUnit.primary) : undefined);
	const myCallsign = $derived(myUnitData?.operatingUnder ?? myUnitData?.primary ?? null);

	const attachedToMe = $derived(
		alertsState.showing && myCallsign !== null
			? alertsState.alerts.filter((a) => a.attached.includes(String(myCallsign))).sort((a, b) => b.time - a.time)
			: [],
	);

	const recent = $derived(
		alertsState.alerts
			.filter((a) => (a.onScreen || alertsState.showing) && !(myCallsign !== null && a.attached.includes(String(myCallsign))) && Date.now() - a.time <= 300000)
			.sort((a, b) => b.time - a.time),
	);

	const older = $derived(
		alertsState.showing
			? alertsState.alerts
					.filter((a) => !(myCallsign !== null && a.attached.includes(String(myCallsign))) && Date.now() - a.time > 300000)
					.sort((a, b) => b.time - a.time)
			: [],
	);
</script>

<div class="notifications" class:panel-open={alertsState.showing}>
	{#each attachedToMe as alert (alert.id)}
		<AlertCard {alert} />
	{/each}
	{#each recent as alert (alert.id)}
		<AlertCard {alert} />
	{/each}
	{#each older as alert (alert.id)}
		<AlertCard {alert} />
	{/each}
</div>

<style>
	.notifications {
		height: 100%;
		max-width: 650px;
		margin-left: auto;
		overflow-y: auto;
		overflow-x: hidden;
		padding: 0 0.4vw;
	}

	.notifications.panel-open {
		height: 45%;
	}
</style>
