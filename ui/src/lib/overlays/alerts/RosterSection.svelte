<script lang="ts">
	import Icon from '../../Icon.svelte';
	import { alertsState, toggleRosterSection } from '../../store/alerts.svelte';
	import UnitRow from './UnitRow.svelte';
	import type { DispatchUnit } from '../../types';

	let { jobType, units, fullHeight = false }: { jobType: string; units: DispatchUnit[]; fullHeight?: boolean } = $props();

	const TYPE_NAMES: Record<string, string> = { police: 'Police', ems: 'EMS', prison: 'DOC', tow: 'Tow' };

	const allUnits = $derived(alertsState.units[jobType] ?? []);
	const expanded = $derived(Boolean(alertsState.rosterSections[jobType]));
</script>

<div class="section" class:full-height={fullHeight}>
	<button type="button" class="header" onclick={() => toggleRosterSection(jobType)}>
		<h3>
			{TYPE_NAMES[jobType] ?? jobType}
			{#if allUnits.length > 0}<small> - On Duty: <b>{allUnits.length}</b></small>{/if}
			{#if (jobType === 'police' || jobType === 'ems') && units.length > 0}
				<small>&nbsp;({units.length} {units.length === 1 ? 'Unit' : 'Units'})</small>
			{/if}
		</h3>
		<span class="chevron" class:flipped={expanded}><Icon name="chevron-up" /></span>
	</button>
	{#if expanded}
		<div class="list">
			{#if units.length > 0}
				{#each [...units].sort((a, b) => Number(a.primary) - Number(b.primary)) as unit (unit.primary ?? unit.source)}
					<UnitRow {unit} unitType={jobType} />
				{/each}
			{:else}
				<div class="empty">No {TYPE_NAMES[jobType] ?? jobType} On Duty</div>
			{/if}
		</div>
	{/if}
</div>

<style>
	.section {
		display: flex;
		flex-direction: column;
		min-width: 0;
		border-right: var(--border-subtle);
	}

	.section:last-child {
		border-right: none;
	}

	.section.full-height {
		height: 100%;
	}

	.header {
		display: flex;
		align-items: center;
		justify-content: space-between;
		background: var(--color-bg-panel-alt);
		border: none;
		cursor: pointer;
		padding: 0.8vh 0.8vw;
		text-align: left;
	}

	.header h3 {
		margin: 0;
		font-family: var(--font-heading);
		font-size: 1.1vmin;
		color: var(--color-surface-text);
	}

	.header small {
		font-size: 0.9vmin;
		font-weight: 400;
		color: var(--color-surface-text-muted);
	}

	.chevron {
		font-size: 0.9vmin;
		color: var(--color-surface-text-muted);
		transition: transform 150ms ease;
	}

	.chevron.flipped {
		transform: rotate(180deg);
	}

	.list {
		overflow-y: auto;
		flex: 1;
	}

	.empty {
		text-align: center;
		font-size: 0.95vmin;
		color: var(--color-text-muted);
		padding: 1.4vh 0.7vw;
	}
</style>
