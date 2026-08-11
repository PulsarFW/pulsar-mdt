<script lang="ts">
	import { appState } from '../../store/app.svelte';
	import { alertsState } from '../../store/alerts.svelte';
	import RosterSection from './RosterSection.svelte';
	import Radios from './Radios.svelte';

	// job -> which columns to show, in order (mirrors old's "stupidConfig")
	const LAYOUT: Record<string, string[]> = {
		police: ['tow', 'prison', 'ems', 'police'],
		ems: ['prison', 'police', 'ems'],
		prison: ['ems', 'police', 'prison'],
	};

	const jobId = $derived(appState.govJob?.Id ?? '');
	const unattachedUnits = $derived((type: string) => (alertsState.units[type] ?? []).filter((u) => u.operatingUnder == null));
</script>

{#if appState.user && jobId === 'tow'}
	<div class="roster tow">
		<RosterSection jobType="tow" units={unattachedUnits('tow')} fullHeight />
	</div>
{:else if appState.user && LAYOUT[jobId]}
	<div class="roster">
		<div class="columns">
			{#each LAYOUT[jobId] as type (type)}
				<RosterSection jobType={type} units={unattachedUnits(type)} />
			{/each}
		</div>
		<Radios />
	</div>
{/if}

<style>
	.roster {
		height: calc(55% - 0.6vh);
		margin-top: 0.6vh;
		width: 100%;
		display: flex;
		flex-direction: column;
		pointer-events: auto;
		background: var(--color-bg-panel);
		border: var(--border-subtle);
		border-radius: var(--radius);
		box-shadow: 0 4px 16px rgba(0, 0, 0, 0.45);
		overflow: hidden;
	}

	.roster.tow {
		display: block;
	}

	.columns {
		flex: 1;
		display: grid;
		grid-template-columns: repeat(auto-fit, minmax(0, 1fr));
		overflow: hidden;
	}
</style>
