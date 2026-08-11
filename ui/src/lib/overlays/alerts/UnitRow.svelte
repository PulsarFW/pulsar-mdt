<script lang="ts">
	import Icon from '../../Icon.svelte';
	import { appState } from '../../store/app.svelte';
	import { alertsState, changeAvailability, changeUnitType, breakOff, operateUnder } from '../../store/alerts.svelte';
	import { Nui } from '../../nui';
	import type { DispatchUnit } from '../../types';

	let { unit, unitType }: { unit: DispatchUnit; unitType: string } = $props();

	let open = $state(false);

	const myJob = $derived(appState.govJob?.Id ?? '');
	const myUnitData = $derived(
		alertsState.myUnit ? (alertsState.units[alertsState.myUnit.job] ?? []).find((u) => u.primary === alertsState.myUnit!.primary) : undefined,
	);
	const subUnits = $derived((alertsState.units[unitType] ?? []).filter((u) => u.operatingUnder === unit.primary));
	const mySubUnits = $derived(myUnitData ? (alertsState.units[unitType] ?? []).filter((u) => u.operatingUnder === myUnitData!.primary) : []);
	const withinUnit = $derived(Boolean(myUnitData) && (unit.primary === myUnitData!.primary || myUnitData!.operatingUnder === unit.primary));
	const clickable = $derived(myJob === unitType);
	const missingCallsign = $derived(unit.primary === null || unit.primary === undefined || unit.primary === '');

	function unitIcon(): string {
		if (unitType !== 'tow' && !unit.available) return 'hourglass-half';
		if (unitType === 'police') {
			if (unit.type === 'air1') return 'helicopter';
			if (unit.type === 'motorcycle') return 'motorcycle';
			if (unit.type === 'heat') return 'fire';
			return 'car-side';
		}
		if (unitType === 'ems') {
			if (unit.type === 'bus') return 'truck-medical';
			if (unit.type === 'lifeflight') return 'helicopter';
			return 'car-side';
		}
		if (unitType === 'tow') return 'truck-ramp-box';
		if (unitType === 'prison') return 'handcuffs';
		return 'circle-question';
	}

	function displayName(u: DispatchUnit): string {
		const mine = appState.user?.SID === u.character?.SID;
		const label = unitType === 'tow' && u.character ? `${u.character.First[0]}. ${u.character.Last}` : String(u.primary);
		return mine ? `${label} (You)` : label;
	}

	function toggle() {
		if (clickable) open = !open;
	}

	function doOperateUnder() {
		if (!myUnitData) return;
		operateUnder(unitType, unit.primary, myUnitData.primary);
		open = false;
	}
	function doBreakOff() {
		if (!myUnitData) return;
		breakOff(unitType, unit.primary, myUnitData.primary);
		open = false;
	}
	function doToggleAvailability() {
		changeAvailability(unitType, unit.primary);
		open = false;
	}
	function doChangeType(type: string) {
		changeUnitType(unitType, unit.primary, type);
		open = false;
	}
	function doSetRadio() {
		if (unit.radioChannel) Nui.swapToRadio(unit.radioChannel);
	}
</script>

{#if missingCallsign && unitType !== 'tow'}
	<div class="row">
		<div class="avatar invalid"><Icon name="triangle-exclamation" /></div>
		<div class="info">
			<div class="name">{unit.character ? `${unit.character.First[0]}. ${unit.character.Last}` : 'Unknown'}</div>
			<div class="sub">Unset Callsign</div>
		</div>
	</div>
{:else}
	<div class="row">
		<button type="button" class="avatar" class:clickable class:unavailable={unitType !== 'tow' && !unit.available} onclick={toggle} disabled={!clickable}>
			<Icon name={unitIcon()} />
		</button>
		<div class="info">
			<div class="name">
				{displayName(unit)}
				{#if unit.pursuitMode}<span class="pursuit">{unit.pursuitMode}</span>{/if}
			</div>
			{#if unitType === 'tow'}
				<div class="sub">{unit.character?.Phone ?? ''}</div>
			{:else if subUnits.length > 0}
				<div class="sub-units">
					{#each subUnits as sub (sub.primary)}
						<span class="sub-unit">{displayName(sub)}</span>
					{/each}
				</div>
			{/if}
		</div>
		{#if unit.radioChannel}
			<button type="button" class="radio-chip" onclick={doSetRadio}>
				<Icon name="walkie-talkie" />
				{unit.radioChannel}
			</button>
		{/if}

		{#if open}
			<div class="popover" role="menu">
				<div class="popover-title">Unit: {unit.primary}</div>
				{#if unit.primary !== myUnitData?.primary && myUnitData?.operatingUnder == null && mySubUnits.length === 0}
					<button type="button" onclick={doOperateUnder}>Operate Under</button>
				{/if}
				{#if unit.primary !== myUnitData?.primary && myUnitData?.operatingUnder === unit.primary}
					<button type="button" onclick={doBreakOff}>Break Off From {unit.primary}</button>
				{/if}
				{#if withinUnit}
					<button type="button" onclick={doToggleAvailability}>Toggle Availability</button>
					{#if unitType === 'police'}
						<button type="button" disabled={unit.type === 'car'} onclick={() => doChangeType('car')}>Ground Unit</button>
						<button type="button" disabled={unit.type === 'heat'} onclick={() => doChangeType('heat')}>Heat Unit</button>
						<button type="button" disabled={unit.type === 'motorcycle'} onclick={() => doChangeType('motorcycle')}>Motorcycle Unit</button>
						<button type="button" disabled={unit.type === 'air1'} onclick={() => doChangeType('air1')}>Air Unit</button>
					{:else if unitType === 'ems'}
						<button type="button" disabled={unit.type === 'bus'} onclick={() => doChangeType('bus')}>Ambulance</button>
						<button type="button" disabled={unit.type === 'car'} onclick={() => doChangeType('car')}>Rapid Response</button>
						<button type="button" disabled={unit.type === 'lifeflight'} onclick={() => doChangeType('lifeflight')}>Life Flight</button>
					{/if}
				{/if}
				<button type="button" class="popover-close" onclick={() => (open = false)}>Close</button>
			</div>
		{/if}
	</div>
{/if}

<style>
	.row {
		position: relative;
		display: flex;
		align-items: center;
		gap: 0.6vw;
		padding: 0.6vh 0.7vw;
		border-bottom: 1px solid rgba(232, 232, 236, 0.06);
	}

	.avatar {
		flex-shrink: 0;
		width: 2.4vmin;
		height: 2.4vmin;
		border-radius: 50%;
		display: flex;
		align-items: center;
		justify-content: center;
		background: var(--color-primary-dark);
		color: #fff;
		border: none;
		font-size: 1.1vmin;
		cursor: default;
	}

	.avatar.clickable {
		cursor: pointer;
	}

	.avatar.clickable:hover {
		filter: brightness(1.25);
	}

	.avatar.unavailable {
		background: #a17400;
	}

	.avatar.invalid {
		background: var(--color-error-dark);
	}

	.info {
		flex: 1;
		min-width: 0;
	}

	.name {
		font-size: 1.1vmin;
		color: var(--color-text);
		display: flex;
		align-items: center;
		gap: 0.4vw;
	}

	.pursuit {
		font-size: 0.85vmin;
		background: var(--color-primary);
		color: #fff;
		border-radius: 3px;
		padding: 0.1vh 0.4vw;
	}

	.sub,
	.sub-units {
		font-size: 0.95vmin;
		color: var(--color-text-muted);
		margin-top: 0.2vh;
	}

	.sub-unit {
		background: rgba(255, 255, 255, 0.1);
		border-radius: 4px;
		padding: 0.1vh 0.4vw;
		margin-right: 0.4vw;
	}

	.radio-chip {
		display: flex;
		align-items: center;
		gap: 0.3vw;
		background: rgba(255, 255, 255, 0.1);
		border: none;
		border-radius: 4px;
		color: var(--color-text);
		padding: 0.3vh 0.5vw;
		font-size: 0.9vmin;
		cursor: pointer;
	}

	.popover {
		position: absolute;
		top: 100%;
		left: 0.7vw;
		z-index: 30;
		background: var(--color-bg-panel);
		border: var(--border-subtle);
		border-radius: var(--radius);
		box-shadow: 0 4px 16px rgba(0, 0, 0, 0.45);
		display: flex;
		flex-direction: column;
		min-width: 12vw;
		padding: 0.4vh 0;
	}

	.popover-title {
		font-size: 0.95vmin;
		color: var(--color-text-muted);
		padding: 0.5vh 0.9vw;
		border-bottom: var(--border-subtle);
	}

	.popover button {
		background: transparent;
		border: none;
		color: var(--color-text);
		text-align: left;
		padding: 0.6vh 0.9vw;
		font-size: 1vmin;
		cursor: pointer;
	}

	.popover button:hover:not(:disabled) {
		background: rgba(139, 92, 246, 0.15);
	}

	.popover button:disabled {
		color: var(--color-text-muted);
		cursor: default;
	}

	.popover-close {
		border-top: var(--border-subtle);
		color: var(--color-text-muted) !important;
	}
</style>
