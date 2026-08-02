<script lang="ts">
	import { bodycamState } from '../store/bodycam.svelte';
	import { appState } from '../store/app.svelte';
	import { alertsState } from '../store/alerts.svelte';
	import { formatDate } from '../util/format';
	import axonLogo from '../../assets/axon.png';

	const TRACKED_JOBS = new Set(['police', 'ems', 'prison']);

	const eligible = $derived(Boolean(appState.user) && Boolean(appState.govJob) && TRACKED_JOBS.has(appState.govJob?.Id ?? ''));
	const visible = $derived(eligible && bodycamState.show && appState.hidden && !alertsState.showing);

	let now = $state(new Date());
	$effect(() => {
		const timer = setInterval(() => (now = new Date()), 1000);
		return () => clearInterval(timer);
	});

	const dateStr = $derived(formatDate(now.toISOString()));
	const timeStr = $derived(now.toLocaleTimeString());
</script>

{#if visible}
	<div class="bodycam">
		<div class="text">
			<div class="rec-line">REC <span class="dot"></span> XION CHASE-CAM™</div>
			<div>{appState.user?.First[0]}. {appState.user?.Last} [{appState.user?.Callsign || 'NOTSET'}]</div>
			<div>{appState.govJob?.Workplace?.Name ?? ''}</div>
			<div class="datetime">
				<span>{dateStr}</span>
				<span>{timeStr}</span>
			</div>
		</div>
		<img src={axonLogo} alt="" class="logo" />
	</div>
{/if}

<style>
	.bodycam {
		font-family: 'Share Tech Mono', monospace;
		position: absolute;
		top: 1vh;
		right: 1vw;
		background: rgba(0, 0, 0, 0.55);
		border: var(--border-subtle);
		border-radius: var(--radius);
		width: 22vw;
		max-width: 340px;
		display: flex;
		align-items: center;
		padding: 0.8vh 0.8vw;
		gap: 0.6vw;
		pointer-events: none;
		user-select: none;
		z-index: 40;
	}

	.text {
		flex: 1;
		text-align: right;
		font-size: 1.05vmin;
		color: var(--color-text);
	}

	.rec-line {
		display: flex;
		align-items: center;
		justify-content: flex-end;
		gap: 0.3vw;
	}

	.dot {
		width: 0.7vmin;
		height: 0.7vmin;
		border-radius: 50%;
		background: var(--color-error);
		animation: pulse 1.2s ease-in-out infinite;
	}

	.datetime {
		display: flex;
		justify-content: flex-end;
		gap: 0.8vw;
		margin-top: 0.2vh;
		color: var(--color-text-muted);
	}

	.logo {
		width: 3.6vh;
		height: 3.6vh;
		object-fit: contain;
		flex-shrink: 0;
		opacity: 0.85;
	}

	@keyframes pulse {
		0%,
		100% {
			opacity: 1;
		}
		50% {
			opacity: 0.25;
		}
	}
</style>
