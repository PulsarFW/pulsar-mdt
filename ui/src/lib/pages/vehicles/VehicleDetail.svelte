<script lang="ts">
	import Icon from '../../Icon.svelte';
	import Loader from '../../primitives/Loader.svelte';
	import Modal from '../../primitives/Modal.svelte';
	import OfficerSearch from '../../primitives/OfficerSearch.svelte';
	import { Nui } from '../../nui';
	import { appState, navigate, toast } from '../../store/app.svelte';
	import { VEHICLE_TYPES, VEHICLE_FLAG_TYPES } from '../../../config';
	import type { OfficerRef, Vehicle, VehicleFlag, VehicleStrike } from '../../types';

	let { vin, fleetManage = false }: { vin: string | null; fleetManage?: boolean } = $props();

	let vehicle = $state<Vehicle | null>(null);
	let loading = $state(false);

	$effect(() => {
		if (vin === null) {
			vehicle = null;
			return;
		}
		loading = true;
		Nui.viewVehicle(vin).then((res) => {
			vehicle = res || null;
			loading = false;
		});
	});

	const myJob = $derived(appState.govJob);
	const isSystemAdmin = $derived(Boolean(appState.user?.MDTSystemAdmin));
	const canManageFlags = $derived(myJob?.Id === 'police');

	function flagLabel(type: string) {
		return VEHICLE_FLAG_TYPES.find((f) => f.value === type)?.label ?? type;
	}
	function flagSeverity(type: string) {
		return VEHICLE_FLAG_TYPES.find((f) => f.value === type)?.severity ?? 'error';
	}

	// ---- Flags ----
	let modal = $state<'flag' | 'flag-view' | 'strike' | 'strike-view' | 'assignees' | null>(null);
	let flagType = $state(VEHICLE_FLAG_TYPES[0]?.value ?? '');
	let flagDescription = $state('');
	let viewingFlagIdx = $state(-1);

	let strikeDescription = $state('');
	let viewingStrikeIdx = $state(-1);

	let assignedDrivers = $state<OfficerRef[]>([]);

	function openFlagForm() {
		flagType = VEHICLE_FLAG_TYPES[0]?.value ?? '';
		flagDescription = '';
		modal = 'flag';
	}

	function viewFlag(idx: number) {
		viewingFlagIdx = idx;
		modal = 'flag-view';
	}

	async function submitFlag() {
		if (!vehicle) return;
		if (vehicle.Flags?.some((f) => f.Type === flagType)) {
			toast.error('Vehicle already has this flag.');
			return;
		}
		const author: VehicleFlag['Author'] = appState.user
			? { SID: appState.user.SID, Callsign: appState.user.Callsign ? String(appState.user.Callsign) : undefined, First: appState.user.First, Last: appState.user.Last }
			: undefined;
		const flag: VehicleFlag = { Date: Date.now(), Type: flagType, Description: flagDescription, Author: author };
		const ok = await Nui.addVehicleFlag(vehicle.VIN, flag, vehicle.RegisteredPlate);
		if (ok) {
			vehicle.Flags = [...(vehicle.Flags ?? []), flag];
			toast.success('Flag added.');
		} else toast.error('Failed to add flag.');
		modal = null;
	}

	async function dismissFlag() {
		if (!vehicle || viewingFlagIdx < 0) return;
		const flag = vehicle.Flags?.[viewingFlagIdx];
		if (!flag) return;
		const removeRadarFlag = (vehicle.Flags?.length ?? 0) <= 1;
		const ok = await Nui.removeVehicleFlag(vehicle.VIN, flag.Type, vehicle.RegisteredPlate, removeRadarFlag);
		if (ok) {
			vehicle.Flags = vehicle.Flags?.filter((_, i) => i !== viewingFlagIdx);
			toast.success('Flag removed.');
		} else toast.error('Failed to remove flag.');
		modal = null;
	}

	// ---- Strikes ----
	function openStrikeForm() {
		strikeDescription = '';
		modal = 'strike';
	}

	function viewStrike(idx: number) {
		viewingStrikeIdx = idx;
		modal = 'strike-view';
	}

	async function submitStrike() {
		if (!vehicle) return;
		if ((vehicle.Strikes?.length ?? 0) >= 15) {
			toast.error('Vehicle has reached the maximum of 15 strikes.');
			return;
		}
		const author = appState.user ? { SID: appState.user.SID, Callsign: String(appState.user.Callsign ?? ''), First: appState.user.First, Last: appState.user.Last } : undefined;
		const strikes = [...(vehicle.Strikes ?? []), { Date: Date.now(), Description: strikeDescription, Author: author }];
		const ok = await Nui.updateVehicleStrikes(vehicle.VIN, strikes);
		if (ok) {
			vehicle.Strikes = strikes;
			toast.success('Strike added.');
		} else toast.error('Failed to add strike.');
		modal = null;
	}

	async function dismissStrike() {
		if (!vehicle || viewingStrikeIdx < 0) return;
		const strikes = vehicle.Strikes?.filter((_, i) => i !== viewingStrikeIdx) ?? [];
		const ok = await Nui.updateVehicleStrikes(vehicle.VIN, strikes);
		if (ok) {
			vehicle.Strikes = strikes;
			toast.success('Strike removed.');
		} else toast.error('Failed to remove strike.');
		modal = null;
	}

	// ---- Fleet-manage only ----
	function openAssignees() {
		assignedDrivers = vehicle?.GovAssigned ? [...vehicle.GovAssigned] : [];
		modal = 'assignees';
	}

	async function submitAssignees() {
		if (!vehicle) return;
		const ok = await Nui.setAssignedDrivers(vehicle.VIN, assignedDrivers);
		if (ok) {
			vehicle.GovAssigned = assignedDrivers;
			toast.success('Assigned drivers updated.');
		} else toast.error('Failed to update assigned drivers.');
		modal = null;
	}

	async function trackVehicle() {
		if (!vehicle) return;
		const ok = await Nui.trackFleetVehicle(vehicle.VIN);
		if (ok) toast.success('Waypoint set to vehicle.');
		else toast.error('Failed to track vehicle.');
	}
</script>

<div class="detail">
	{#if vin === null}
		<div class="empty">
			<Icon name="car-side" size="4vmin" />
			<p>No Vehicle Selected</p>
		</div>
	{:else if loading}
		<Loader />
	{:else if !vehicle}
		<div class="empty">
			<Icon name="car-side" size="4vmin" />
			<p>Vehicle Not Found</p>
		</div>
	{:else}
		<div class="scroll">
			{#if vehicle.RadarFlag}
				<div class="alert error">Radar Flagged: {vehicle.RadarFlag}</div>
			{/if}

			<div class="header">
				<h2>{vehicle.Make} {vehicle.Model}</h2>
				<div class="meta">
					<span>{VEHICLE_TYPES[vehicle.Type ?? 0]}</span>
					<span>VIN: {vehicle.VIN}</span>
					<span>Plate: {vehicle.RegisteredPlate}</span>
				</div>
				<div class="meta">
					{#if vehicle.Owner}
						{#if vehicle.Owner.Type === 0 && vehicle.Owner.Person}
							<button type="button" class="link" onclick={() => navigate('people', { person: String(vehicle!.Owner!.Id) })}>
								Owner: {vehicle.Owner.Person.First} {vehicle.Owner.Person.Last}
							</button>
						{:else}
							<span>Owner: {vehicle.Owner.JobName ?? 'Unknown'}</span>
						{/if}
					{/if}
					<span>Impounded: {vehicle.Storage?.Type === 0 ? 'Yes' : 'No'}</span>
				</div>
				{#if fleetManage}
					<div class="meta">
						<span>Storage: {vehicle.Storage?.Name ?? 'Unknown'}</span>
						<button type="button" class="icon-btn" title="Track Vehicle" onclick={trackVehicle}>
							<Icon name="location-crosshairs" size="1.1vmin" />
						</button>
					</div>
				{/if}
			</div>

			{#if fleetManage}
				<section>
					<div class="section-head">
						<h3>Assigned Drivers</h3>
						<button type="button" class="icon-btn" onclick={openAssignees}><Icon name="pen" size="1vmin" /></button>
					</div>
					{#if vehicle.GovAssigned && vehicle.GovAssigned.length > 0}
						<div class="chips">
							{#each vehicle.GovAssigned as officer (officer.SID)}
								<span class="chip static">({officer.Callsign ?? 'N/A'}) {officer.First[0]}. {officer.Last}</span>
							{/each}
						</div>
					{:else}
						<p class="hint">Non Assigned</p>
					{/if}
				</section>
			{/if}

			<section>
				<div class="section-head">
					<h3>Flags</h3>
					{#if canManageFlags}
						<button type="button" class="icon-btn" onclick={openFlagForm}><Icon name="plus" size="1vmin" /></button>
					{/if}
				</div>
				{#if vehicle.Flags && vehicle.Flags.length > 0}
					<div class="chips">
						{#each vehicle.Flags as flag, i (i)}
							<button type="button" class="chip severity-{flagSeverity(flag.Type)}" onclick={() => viewFlag(i)}>{flagLabel(flag.Type)}</button>
						{/each}
					</div>
				{:else}
					<p class="hint">No flags.</p>
				{/if}
			</section>

			<section>
				<div class="section-head">
					<h3>Vehicle Strikes</h3>
					{#if canManageFlags}
						<button type="button" class="icon-btn" onclick={openStrikeForm}><Icon name="plus" size="1vmin" /></button>
					{/if}
				</div>
				{#if vehicle.Strikes && vehicle.Strikes.length > 0}
					<div class="chips">
						{#each vehicle.Strikes as _, i (i)}
							<button type="button" class="chip static" onclick={() => viewStrike(i)}>Strike {i + 1}</button>
						{/each}
					</div>
				{:else}
					<p class="hint">No strikes.</p>
				{/if}
			</section>
		</div>
	{/if}
</div>

{#if vehicle}
	<Modal showing={modal === 'flag'} title="Add Vehicle Flag" onAccept={submitFlag} onClose={() => (modal = null)}>
		<label>
			Type
			<select bind:value={flagType}>
				{#each VEHICLE_FLAG_TYPES as t (t.value)}
					<option value={t.value}>{t.label}</option>
				{/each}
			</select>
		</label>
		<label>Description<textarea bind:value={flagDescription} rows="3"></textarea></label>
	</Modal>

	<Modal showing={modal === 'flag-view'} title={flagLabel(vehicle.Flags?.[viewingFlagIdx]?.Type ?? '')} acceptLabel="Remove Flag" onAccept={dismissFlag} onClose={() => (modal = null)}>
		{#if vehicle.Flags?.[viewingFlagIdx]}
			<p>Issued: {new Date(vehicle.Flags[viewingFlagIdx].Date).toLocaleString()}</p>
			{#if vehicle.Flags[viewingFlagIdx].Author}
				<p>Issued By: {vehicle.Flags[viewingFlagIdx].Author?.First} {vehicle.Flags[viewingFlagIdx].Author?.Last}</p>
			{/if}
			<p>Reason: {vehicle.Flags[viewingFlagIdx].Description}</p>
		{/if}
	</Modal>

	<Modal showing={modal === 'strike'} title="Add Vehicle Strike" onAccept={submitStrike} onClose={() => (modal = null)}>
		<label>Description<textarea bind:value={strikeDescription} rows="3"></textarea></label>
	</Modal>

	<Modal
		showing={modal === 'strike-view'}
		title={`Vehicle Strike ${viewingStrikeIdx + 1}`}
		acceptLabel={isSystemAdmin ? 'Remove Strike' : 'Close'}
		onAccept={isSystemAdmin ? dismissStrike : () => (modal = null)}
		onClose={() => (modal = null)}
	>
		{#if vehicle.Strikes?.[viewingStrikeIdx]}
			<p>Issued: {new Date(vehicle.Strikes[viewingStrikeIdx].Date).toLocaleString()}</p>
			{#if vehicle.Strikes[viewingStrikeIdx].Author}
				<p>Issued By: {vehicle.Strikes[viewingStrikeIdx].Author?.First} {vehicle.Strikes[viewingStrikeIdx].Author?.Last}</p>
			{/if}
			<p>Reason: {vehicle.Strikes[viewingStrikeIdx].Description}</p>
		{/if}
	</Modal>

	{#if fleetManage}
		<Modal showing={modal === 'assignees'} title="Assigned Drivers" onAccept={submitAssignees} onClose={() => (modal = null)}>
			<OfficerSearch bind:selected={assignedDrivers} job={myJob?.Id ?? 'police'} label="Assigned Drivers" />
		</Modal>
	{/if}
{/if}

<style>
	.detail {
		display: flex;
		flex-direction: column;
		height: 100%;
	}

	.empty {
		margin: auto;
		text-align: center;
		color: var(--color-text-muted);
	}

	.scroll {
		overflow-y: auto;
		padding: 1.2vh 1.2vw;
		display: flex;
		flex-direction: column;
		gap: 1.4vh;
	}

	.alert {
		border-radius: var(--radius);
		padding: 0.7vh 0.9vw;
		font-size: 1.05vmin;
	}

	.alert.error {
		background: rgba(161, 52, 52, 0.15);
		color: var(--color-error);
	}

	.header h2 {
		margin: 0 0 0.4vh;
		font-family: var(--font-heading);
		font-size: 1.7vmin;
	}

	.meta {
		display: flex;
		flex-wrap: wrap;
		align-items: center;
		gap: 1vw;
		font-size: 1.05vmin;
		color: var(--color-text-muted);
		margin-bottom: 0.3vh;
	}

	.link {
		background: transparent;
		border: none;
		color: var(--color-primary-light);
		cursor: pointer;
		padding: 0;
		font-size: inherit;
	}

	.section-head {
		display: flex;
		align-items: center;
		justify-content: space-between;
		margin-bottom: 0.6vh;
	}

	section h3 {
		margin: 0;
		font-size: 1.15vmin;
		text-transform: uppercase;
		letter-spacing: 0.03em;
		color: var(--color-text-muted);
	}

	.icon-btn {
		background: transparent;
		border: var(--border-subtle);
		border-radius: var(--radius);
		color: var(--color-text-muted);
		cursor: pointer;
		padding: 0.4vh 0.7vw;
		display: flex;
		align-items: center;
	}

	.icon-btn:hover {
		color: var(--color-primary-light);
	}

	.chips {
		display: flex;
		flex-wrap: wrap;
		gap: 0.5vh;
	}

	.chip {
		display: inline-flex;
		align-items: center;
		background: rgba(139, 92, 246, 0.15);
		color: var(--color-primary-light);
		border: none;
		border-radius: var(--radius);
		padding: 0.5vh 0.8vw;
		font-size: 1.05vmin;
		cursor: pointer;
	}

	.chip.static {
		cursor: default;
	}

	.chip.severity-error {
		background: rgba(161, 52, 52, 0.2);
		color: #e88;
	}

	.chip.severity-warning {
		background: rgba(242, 181, 131, 0.2);
		color: var(--color-warning);
	}

	.hint {
		color: var(--color-text-muted);
		font-size: 1.05vmin;
	}

	label {
		display: flex;
		flex-direction: column;
		gap: 0.4vh;
		font-size: 1.05vmin;
		color: var(--color-text-muted);
	}

	select,
	textarea {
		background-color: var(--color-bg);
		border: var(--border-subtle);
		border-radius: var(--radius);
		color: var(--color-text);
		padding: 0.7vh 0.7vw;
		font-size: 1.1vmin;
		font-family: inherit;
	}
</style>
