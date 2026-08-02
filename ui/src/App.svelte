<script lang="ts">
	import { onMount } from 'svelte';
	import { attachMessageListener } from './lib/messages';
	import { Nui } from './lib/nui';
	import { appState } from './lib/store/app.svelte';
	import { deptKeyFor } from './config';
	import Shell from './lib/Shell.svelte';
	import GovBadgeOverlay from './lib/overlays/GovBadgeOverlay.svelte';
	import BodyCamOverlay from './lib/overlays/BodyCamOverlay.svelte';
	import AlertsPanel from './lib/overlays/AlertsPanel.svelte';
	import DevMenu from './lib/DevMenu.svelte';

	$effect(() => {
		document.documentElement.dataset.dept = deptKeyFor(appState.govJob);
	});

	onMount(() => {
		const detachMessages = attachMessageListener();
		const onKey = (e: KeyboardEvent) => {
			if (e.key === 'Escape') Nui.close();
			else if (e.key === '`') Nui.closeAlerts();
		};
		window.addEventListener('keydown', onKey);
		return () => {
			detachMessages();
			window.removeEventListener('keydown', onKey);
		};
	});
</script>

<main>
	<Shell />
	<GovBadgeOverlay />
	<BodyCamOverlay />
	<AlertsPanel />
	{#if import.meta.env.DEV}
		<DevMenu />
	{/if}
</main>

<style>
	main {
		position: relative;
		width: 100vw;
		height: 100vh;
		overflow: hidden;
	}
</style>
