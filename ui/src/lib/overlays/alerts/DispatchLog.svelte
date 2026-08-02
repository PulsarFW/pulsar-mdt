<script lang="ts">
	import Icon from '../../Icon.svelte';
	import Modal from '../../primitives/Modal.svelte';
	import { alertsState, toggleDispatchLog, logDispatchMessage } from '../../store/alerts.svelte';

	const DEFAULT_SETTINGS: Record<string, boolean> = {
		attaching: true,
		dutyChange: true,
		unitChange: true,
		radioUpdate: true,
		subUnitChanges: true,
		availabilityChange: true,
	};

	function loadSettings(): Record<string, boolean> {
		try {
			const raw = localStorage.getItem('dispatchLog_settings');
			return raw ? { ...DEFAULT_SETTINGS, ...JSON.parse(raw) } : { ...DEFAULT_SETTINGS };
		} catch {
			return { ...DEFAULT_SETTINGS };
		}
	}

	let settings = $state(loadSettings());
	let settingsOpen = $state(false);
	let draftSettings = $state({ ...settings });
	let message = $state('');

	const filteredLog = $derived(alertsState.dispatchLog.filter((log) => log.type === 'message' || settings[log.type]));

	function openSettings() {
		draftSettings = { ...settings };
		settingsOpen = true;
	}

	function saveSettings() {
		settings = { ...draftSettings };
		localStorage.setItem('dispatchLog_settings', JSON.stringify(settings));
		settingsOpen = false;
	}

	function submitMessage(e: SubmitEvent) {
		e.preventDefault();
		const trimmed = message.trim();
		if (!trimmed) return;
		logDispatchMessage(trimmed);
		message = '';
	}

	function formatTime(ms: number): string {
		return new Date(ms).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
	}

	const SETTING_LABELS: [string, string][] = [
		['dutyChange', 'Show Units Going On/Off Duty'],
		['unitChange', 'Show Units Transitioning'],
		['subUnitChanges', 'Show Units Operating Under/Breaking Off'],
		['availabilityChange', 'Show Units Changing Availability'],
		['attaching', 'Show Units Attaching/Detaching From Calls'],
		['radioUpdate', 'Show When Radio Info Is Added'],
	];
</script>

<div class="dispatch-rail">
	<div class="log-wrap" class:expanded={alertsState.dispatchExpanded}>
		{#if alertsState.dispatchExpanded}
			<div class="log-list">
				{#each filteredLog as log, i (i)}
					<div class="log-item" style:border-left-color={log.color ?? undefined}>
						<div class="log-time">{formatTime(log.time)}</div>
						<div class="log-body">
							{#if log.title}<h4>{log.title}</h4>{/if}
							<p>{log.message}</p>
						</div>
					</div>
				{/each}
			</div>
			<form class="input-row" onsubmit={submitMessage}>
				<input type="text" placeholder="Send Message" maxlength="128" bind:value={message} />
				<button type="submit"><Icon name="share" /></button>
			</form>
		{/if}
	</div>
	<div class="handle">
		<button type="button" class="toggle" onclick={toggleDispatchLog}>
			<span class="label">Dispatch Log</span>
			<span class="chevron" class:flipped={alertsState.dispatchExpanded}><Icon name="chevron-up" /></span>
		</button>
		{#if alertsState.dispatchExpanded}
			<button type="button" class="settings-btn" onclick={openSettings}>
				<Icon name="cog" />
			</button>
		{/if}
	</div>
</div>

<Modal showing={settingsOpen} title="Dispatch Log Settings" acceptLabel="Save" onAccept={saveSettings} onClose={() => (settingsOpen = false)}>
	{#each SETTING_LABELS as [key, label] (key)}
		<label class="check">
			<input type="checkbox" checked={draftSettings[key]} onchange={(e) => (draftSettings = { ...draftSettings, [key]: e.currentTarget.checked })} />
			<span>{label}</span>
		</label>
	{/each}
</Modal>

<style>
	.dispatch-rail {
		position: fixed;
		top: 12vh;
		left: 0.8vw;
		display: flex;
		flex-direction: row;
		gap: 0.5vw;
		width: 30%;
		max-width: 350px;
		height: 50%;
		max-height: 900px;
		pointer-events: auto;
		z-index: 39;
	}

	.log-wrap {
		display: flex;
		flex-direction: column;
		background: var(--color-bg-panel);
		width: 0;
		height: 100%;
		overflow: hidden;
		border-radius: var(--radius);
		transition: width 0.2s linear;
	}

	.log-wrap.expanded {
		width: 100%;
		border: var(--border-subtle);
		box-shadow: 0 4px 16px rgba(0, 0, 0, 0.45);
	}

	.log-list {
		flex: 1;
		overflow-y: auto;
		padding: 0.6vh 0.5vw;
		display: flex;
		flex-direction: column;
		gap: 0.4vh;
	}

	.log-item {
		display: flex;
		gap: 0.6vw;
		align-items: center;
		font-size: 0.9vmin;
		background: var(--color-bg-panel-alt);
		border-radius: 4px;
		padding: 0.5vh 0.6vw;
		border-left: 3px solid var(--color-info);
	}

	.log-time {
		color: var(--color-text-muted);
		flex-shrink: 0;
	}

	.log-body h4 {
		margin: 0;
		font-size: 0.95vmin;
		font-weight: 600;
		color: var(--color-text);
		white-space: nowrap;
		overflow: hidden;
		text-overflow: ellipsis;
	}

	.log-body p {
		margin: 0;
		color: var(--color-text-muted);
	}

	.input-row {
		display: flex;
		gap: 0.4vw;
		padding: 0.6vh 0.6vw;
	}

	.input-row input {
		flex: 1;
		background: transparent;
		border: none;
		border-bottom: var(--border-subtle);
		color: var(--color-text);
		font-size: 1vmin;
		padding: 0.4vh 0.2vw;
	}

	.input-row button {
		background: transparent;
		border: none;
		color: var(--color-text);
		cursor: pointer;
	}

	.handle {
		position: relative;
		background: var(--color-bg-panel-alt);
		border: var(--border-subtle);
		border-radius: var(--radius);
		box-shadow: 0 4px 16px rgba(0, 0, 0, 0.45);
		flex-shrink: 0;
		display: flex;
		flex-direction: column;
		align-items: center;
		justify-content: center;
		width: 2.4vw;
		min-width: 32px;
	}

	.toggle {
		background: transparent;
		border: none;
		display: flex;
		flex-direction: column;
		align-items: center;
		justify-content: center;
		gap: 1.4vh;
		padding: 2vh 0;
		cursor: pointer;
		width: 100%;
	}

	.label {
		writing-mode: vertical-rl;
		transform: rotate(180deg);
		font-size: 0.95vmin;
		color: var(--color-surface-text);
	}

	.chevron {
		font-size: 0.9vmin;
		color: var(--color-surface-text-muted);
		transform: rotate(90deg);
		transition: transform 150ms ease;
	}

	.chevron.flipped {
		transform: rotate(-90deg);
	}

	.settings-btn {
		position: absolute;
		bottom: 1vh;
		background: transparent;
		border: none;
		color: var(--color-surface-text-muted);
		cursor: pointer;
	}

	.settings-btn:hover {
		color: var(--color-nav-text-active);
	}

	.check {
		display: flex;
		flex-direction: row;
		align-items: center;
		gap: 0.6vw;
		font-size: 1.05vmin;
		color: var(--color-text);
		cursor: pointer;
	}
</style>
