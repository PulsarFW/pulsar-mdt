<script lang="ts">
	import Icon from '../../Icon.svelte';
	import Modal from '../../primitives/Modal.svelte';
	import { alertsState, updateAlertUnits, removeAlert, routeToAlert } from '../../store/alerts.svelte';
	import { Nui } from '../../nui';
	import type { DispatchAlert } from '../../types';

	let { alert, compact = false }: { alert: DispatchAlert; compact?: boolean } = $props();

	let confirmDelete = $state(false);
	let managingUnits = $state(false);

	const myUnit = $derived(alertsState.myUnit);
	const myUnitData = $derived(myUnit ? (alertsState.units[myUnit.job] ?? []).find((u) => u.primary === myUnit.primary) : undefined);
	const myCallsign = $derived(myUnitData?.operatingUnder ?? myUnitData?.primary ?? null);
	const meAttached = $derived(myCallsign !== null && alert.attached.includes(String(myCallsign)));
	const hasAttaching = $derived(!alert.client && myUnit?.job !== 'prison' && myUnit?.job !== 'tow');

	const allJobUnits = $derived(Object.values(alertsState.units).flat());
	const unitOptions = $derived(allJobUnits.filter((u) => u.operatingUnder === null).sort((a, b) => Number(a.primary) - Number(b.primary)));

	function styleClass(): string {
		if (alert.style === 1) return 'type-1';
		if (alert.style === 2) return 'type-2';
		if (alert.style === 3) return 'type-3';
		return '';
	}

	function styleIcon(): string {
		if (alert.style === 1) return 'clipboard-list';
		if (alert.style === 2) return 'truck-medical';
		if (alert.style === 3) return 'truck-ramp-box';
		return 'circle-question';
	}

	function toggleSelf() {
		if (myCallsign === null) return;
		const callsign = String(myCallsign);
		const next = meAttached ? alert.attached.filter((c) => c !== callsign) : [...alert.attached, callsign];
		updateAlertUnits(alert.id, next);
	}

	function toggleUnit(primary: string | number) {
		const callsign = String(primary);
		const next = alert.attached.includes(callsign) ? alert.attached.filter((c) => c !== callsign) : [...alert.attached, callsign];
		updateAlertUnits(alert.id, next);
	}

	function doDelete() {
		confirmDelete = false;
		removeAlert(alert);
	}

	function doRoute() {
		routeToAlert(alert);
	}

	function doCamera() {
		if (alert.camera) Nui.viewCamera(alert.camera);
	}

	const description = $derived(typeof alert.description === 'object' && alert.description ? alert.description : null);
</script>

<div class="card {styleClass()}" class:panic={alert.panic} class:compact>
	<div class="main">
		<div class="title-row">
			{#if meAttached}<Icon name="thumbtack" size="0.9vmin" />{/if}
			<Icon name={styleIcon()} />
			<span class="code">{alert.code}</span>
			<span class="title">{alert.title}</span>
		</div>

		{#if description}
			<div class="minor">
				<Icon name={description.icon ?? 'circle-question'} />
				<b>{description.details ?? ''}</b>
			</div>
		{:else if typeof alert.description === 'string' && alert.description}
			<div class="minor">{alert.description}</div>
		{/if}

		{#if alert.location}
			<div class="minor">
				<Icon name="location-dot" />
				{alert.location.street1 ?? ''}{alert.location.street2 ? ` / ${alert.location.street2}` : ''}{alert.location.area ? ` | ${alert.location.area}` : ''}
			</div>
		{:else}
			<div class="minor"><Icon name="location-dot" /> Unknown Location</div>
		{/if}

		<div class="footer-row">
			<div class="time"><Icon name="stopwatch" /> {new Date(alert.time).toLocaleTimeString()}</div>
			{#if hasAttaching}
				<button type="button" class="pin" onclick={toggleSelf}><Icon name="link-slash" /></button>
				<button type="button" class="manage" onclick={() => (managingUnits = !managingUnits)}>
					{alert.attached.length > 0 ? alert.attached.join(', ') : 'Assign units...'}
				</button>
			{/if}
		</div>

		{#if managingUnits}
			<div class="unit-picker">
				{#each unitOptions as u (u.primary)}
					<button type="button" class="unit-toggle" class:active={alert.attached.includes(String(u.primary))} onclick={() => toggleUnit(u.primary)}>
						{u.primary}
					</button>
				{/each}
			</div>
		{/if}
	</div>

	<div class="actions">
		<button type="button" onclick={() => (confirmDelete = true)}><Icon name="xmark" /></button>
		{#if alert.location}
			<button type="button" onclick={doRoute}><Icon name="location-crosshairs" /></button>
		{/if}
		{#if alert.camera}
			<button type="button" onclick={doCamera}><Icon name="camera" /></button>
		{/if}
	</div>
</div>

<Modal
	showing={confirmDelete}
	title="Are you sure?"
	acceptLabel="Delete"
	onAccept={doDelete}
	onClose={() => (confirmDelete = false)}
>
	<p>
		{#if alert.attached.length > 0}
			Are you sure you want to clear this call? There are {alert.attached.length} unit(s) still attached - it will be removed from the entire dispatch system.
		{:else}
			Are you sure you want to clear this call? It will be removed from the entire dispatch system.
		{/if}
	</p>
</Modal>

<style>
	.card {
		position: relative;
		display: flex;
		gap: 0.7vw;
		background: var(--color-bg-panel);
		border: var(--border-subtle);
		border-left: 4px solid var(--color-info);
		border-radius: var(--radius);
		padding: 1vh 1vw;
		margin-bottom: 0.8vh;
		box-shadow: 0 3px 12px rgba(0, 0, 0, 0.4);
		pointer-events: auto;
	}

	.card.type-2 {
		border-left-color: #d1327a;
	}
	.card.type-3 {
		border-left-color: #9d6bdb;
	}
	.card.panic {
		border-color: rgba(255, 70, 70, 0.5);
		animation: pulse 1s infinite;
	}

	@keyframes pulse {
		0%, 100% { box-shadow: 0 3px 12px rgba(0, 0, 0, 0.4), 0 0 0 0 rgba(255, 60, 60, 0.5); }
		50% { box-shadow: 0 3px 12px rgba(0, 0, 0, 0.4), 0 0 0 5px rgba(255, 60, 60, 0); }
	}

	.main {
		flex: 1;
		min-width: 0;
		display: flex;
		flex-direction: column;
		gap: 0.5vh;
	}

	.title-row {
		display: flex;
		align-items: center;
		gap: 0.5vw;
		font-size: 1.25vmin;
		font-family: var(--font-heading);
		color: var(--color-text);
	}

	.code {
		background: var(--color-warning);
		color: #221a09;
		border-radius: 3px;
		padding: 0.15vh 0.55vw;
		font-size: 0.9vmin;
		font-weight: 700;
		flex-shrink: 0;
	}

	.title {
		font-weight: 600;
		overflow: hidden;
		text-overflow: ellipsis;
		white-space: nowrap;
	}

	.minor {
		display: flex;
		align-items: center;
		gap: 0.4vw;
		font-size: 0.95vmin;
		color: var(--color-text-muted);
	}

	.footer-row {
		display: flex;
		align-items: center;
		gap: 0.5vw;
		margin-top: 0.4vh;
		padding-top: 0.5vh;
		border-top: var(--border-subtle);
		font-size: 0.9vmin;
		color: var(--color-text-muted);
	}

	.time {
		display: flex;
		align-items: center;
		gap: 0.3vw;
		flex-shrink: 0;
	}

	.pin,
	.manage {
		background: var(--color-bg-panel-alt);
		border: 1px solid transparent;
		border-radius: 4px;
		color: var(--color-surface-text);
		padding: 0.4vh 0.6vw;
		cursor: pointer;
	}

	.pin:hover,
	.manage:hover {
		border-color: rgba(139, 92, 246, 0.35);
	}

	.manage {
		flex: 1;
		text-align: left;
		overflow: hidden;
		text-overflow: ellipsis;
		white-space: nowrap;
	}

	.unit-picker {
		display: flex;
		flex-wrap: wrap;
		gap: 0.35vw;
		margin-top: 0.5vh;
		padding-top: 0.5vh;
		border-top: var(--border-subtle);
		max-height: 12vh;
		overflow-y: auto;
	}

	.unit-toggle {
		background: var(--color-bg);
		border: var(--border-subtle);
		border-radius: 4px;
		color: var(--color-text-muted);
		padding: 0.35vh 0.65vw;
		font-size: 0.9vmin;
		cursor: pointer;
	}

	.unit-toggle.active {
		background: var(--color-primary);
		color: #fff;
		border-color: var(--color-primary);
	}

	.actions {
		display: flex;
		flex-direction: column;
		justify-content: center;
		gap: 0.4vh;
		border-left: var(--border-subtle);
		padding-left: 0.6vw;
	}

	.actions button {
		background: transparent;
		border: none;
		color: var(--color-text-muted);
		cursor: pointer;
		padding: 0.2vh;
	}

	.actions button:hover {
		color: var(--color-primary-light);
	}
</style>
