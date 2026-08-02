<script lang="ts">
	import { appState } from './store/app.svelte';
	import { alertsState } from './store/alerts.svelte';
	import { applyMessage } from './messages';
	import { switchMockIdentity } from './mock';
	import { MOCK_JOB_PRESETS } from './mockData';

	let presetKey = $state('lspd');
	let grantAll = $state(true);
	let isSystemAdmin = $state(false);
	let open = $state(true);

	// applied on explicit change only, main.ts's startMock() fires its own default JOB_LOGIN on a delay so an on-mount effect would race it
	function apply() {
		switchMockIdentity(presetKey, grantAll, isSystemAdmin);
	}

	// alertsState.showing is normally toggled by a native keybind, bun run dev has no equivalent to that
	function toggleDispatchPanel() {
		alertsState.showing = !alertsState.showing;
	}

	// Nui.close() is a no-op outside a real game client, so this fires the same APP_SHOW/APP_HIDE directly
	function toggleMdt() {
		applyMessage(appState.hidden ? 'APP_SHOW' : 'APP_HIDE', {});
	}

	let testAlertId = 1;
	function fireTestAlert() {
		testAlertId += 1;
		applyMessage('ADD_ALERT', {
			alert: {
				id: `dev-test-${testAlertId}`,
				code: '10-99',
				title: `Test Alert #${testAlertId}`,
				type: 'police_alerts',
				location: { street1: 'Test St', street2: null, area: 'Test Area', x: 0, y: 0, z: 0 },
				description: { icon: 'question', details: 'Fired from the dev menu' },
				panic: testAlertId % 2 === 0,
				blip: false,
				style: 1,
				isArea: false,
				camera: false,
				attached: [],
				time: Date.now(),
			},
		});
	}

	const currentPortal = $derived(appState.govJob?.Workplace?.Id ?? (appState.attorney ? 'attorney' : 'public'));

	// prison's workplace id is "doc" but GovBadgeOverlay's dept key is "corrections"
	function badgeDeptKey(): string {
		const wp = appState.govJob?.Workplace?.Id;
		return wp === 'doc' ? 'corrections' : (wp ?? 'doj');
	}

	// no game client in bun run dev so no live pedshot, falls back to the placeholder circle
	function previewBadge() {
		applyMessage('SHOW_GOV_ID', {
			First: appState.user?.First ?? 'John',
			Last: appState.user?.Last ?? 'Doe',
			Department: badgeDeptKey(),
			Title: appState.govJob?.Grade?.Name ?? 'Officer',
			SID: appState.user?.SID ?? 1,
			Callsign: appState.user?.Callsign || 101,
		});
	}

	function previewLicense() {
		applyMessage('SHOW_DRIVER_LICENSE', {
			Name: `${appState.user?.First ?? 'John'} ${appState.user?.Last ?? 'Doe'}`,
			SID: appState.user?.SID ?? 1,
			DOB: appState.user?.DOB ?? '1990-01-01',
		});
	}
</script>

<div class="dev-menu" class:collapsed={!open}>
	<button type="button" class="handle" onclick={() => (open = !open)}>
		<span class="dot"></span>
		<span class="label">DEV</span>
		<span class="chevron" class:flipped={!open}>▾</span>
	</button>
	{#if open}
		<div class="body">
			<label>
				<span class="field-label">Identity</span>
				<select bind:value={presetKey} onchange={apply}>
					{#each Object.entries(MOCK_JOB_PRESETS) as [key, preset] (key)}
						<option value={key}>{preset.label}</option>
					{/each}
				</select>
			</label>
			<label class="check">
				<input type="checkbox" bind:checked={grantAll} onchange={apply} />
				<span>Grant all permissions</span>
			</label>
			<label class="check">
				<input type="checkbox" bind:checked={isSystemAdmin} onchange={apply} />
				<span>MDTSystemAdmin</span>
			</label>
			<div class="readout">
				<span class="readout-key">portal</span>
				<code>{currentPortal}</code>
			</div>
			<div class="actions">
				<button type="button" onclick={toggleMdt}>{appState.hidden ? 'Show' : 'Close'} MDT</button>
				<button type="button" onclick={toggleDispatchPanel}>{alertsState.showing ? 'Close' : 'Open'} Dispatch Panel</button>
				<button type="button" onclick={fireTestAlert}>Fire Test Alert</button>
				<button type="button" onclick={previewBadge}>Preview Gov Badge</button>
				<button type="button" onclick={previewLicense}>Preview License</button>
			</div>
		</div>
	{/if}
</div>

<style>
	.dev-menu {
		position: fixed;
		bottom: 1.2vh;
		left: 1vw;
		z-index: 9999;
		pointer-events: auto;
		width: 14vw;
		min-width: 190px;
		background: #0a0a0a;
		border: 1px solid #333;
		font-family: Consolas, 'SF Mono', monospace;
		color: #ccc;
	}

	.handle {
		display: flex;
		align-items: center;
		gap: 6px;
		width: 100%;
		background: #141414;
		border: none;
		border-bottom: 1px solid #333;
		color: #999;
		cursor: pointer;
		padding: 5px 8px;
		font-family: inherit;
		text-align: left;
	}

	.handle:hover {
		color: #ccc;
	}

	.dot {
		width: 6px;
		height: 6px;
		background: #999;
		flex-shrink: 0;
	}

	.label {
		flex: 1;
		font-size: 10px;
		letter-spacing: 0.05em;
	}

	.chevron {
		font-size: 9px;
		color: #666;
		transition: transform 150ms ease;
	}

	.chevron.flipped {
		transform: rotate(-90deg);
	}

	.body {
		display: flex;
		flex-direction: column;
		gap: 8px;
		padding: 8px;
	}

	label {
		display: flex;
		flex-direction: column;
		gap: 3px;
	}

	.field-label {
		font-size: 9.5px;
		color: #777;
		text-transform: uppercase;
		letter-spacing: 0.04em;
	}

	label.check {
		flex-direction: row;
		align-items: center;
		gap: 6px;
		font-size: 11px;
		cursor: pointer;
	}

	label.check input {
		accent-color: #777;
		cursor: pointer;
	}

	select {
		font-family: inherit;
		font-size: 11px;
		background-color: #141414;
		color: #ccc;
		border: 1px solid #333;
		padding: 3px 5px;
	}

	select:focus {
		outline: none;
		border-color: #666;
	}

	.readout {
		display: flex;
		align-items: center;
		gap: 6px;
		padding-top: 7px;
		border-top: 1px solid #262626;
		font-size: 10px;
	}

	.readout-key {
		color: #666;
		text-transform: uppercase;
		letter-spacing: 0.04em;
	}

	.readout code {
		font-family: inherit;
		color: #999;
		word-break: break-all;
	}

	.actions {
		display: flex;
		flex-direction: column;
		gap: 4px;
		padding-top: 7px;
		border-top: 1px solid #262626;
	}

	.actions button {
		font-family: inherit;
		font-size: 10.5px;
		background: #141414;
		color: #ccc;
		border: 1px solid #333;
		padding: 4px 7px;
		cursor: pointer;
		text-align: left;
	}

	.actions button:hover {
		background: #1e1e1e;
		border-color: #555;
	}
</style>
