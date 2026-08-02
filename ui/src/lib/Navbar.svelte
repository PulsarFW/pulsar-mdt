<script lang="ts">
	import Icon from './Icon.svelte';
	import { navLinksFor, type PortalId } from '../config';
	import { appState, navigate } from './store/app.svelte';

	let { portal }: { portal: PortalId } = $props();

	const links = $derived(navLinksFor(portal, appState.govJobPermissions, Boolean(appState.user?.MDTSystemAdmin)));
</script>

<nav class="tabs">
	{#each links as link (link.page)}
		<button type="button" class="tab" class:active={appState.page === link.page} onclick={() => navigate(link.page)}>
			<Icon name={link.icon} size="1.3vmin" />
			<span>{link.label}</span>
		</button>
	{/each}
</nav>

<style>
	.tabs {
		flex-shrink: 0;
		display: flex;
		align-items: stretch;
		overflow-x: auto;
		overflow-y: hidden;
		background: var(--color-bg-panel-alt);
		border-bottom: var(--border-subtle);
	}

	.tab {
		flex: 1 1 0;
		min-width: max-content;
		display: flex;
		flex-direction: column;
		align-items: center;
		gap: 0.4vh;
		padding: 0.9vh 1.1vw;
		background: transparent;
		border: none;
		border-bottom: 2px solid transparent;
		color: var(--color-nav-text);
		cursor: pointer;
		font-size: 0.95vmin;
		white-space: nowrap;
		transition: color 120ms ease, border-color 120ms ease, background 120ms ease;
	}

	.tab:hover {
		color: var(--color-nav-text-active);
		background: rgba(139, 92, 246, 0.06);
	}

	.tab.active {
		color: var(--color-nav-text-active);
		border-bottom-color: var(--color-primary);
	}
</style>
