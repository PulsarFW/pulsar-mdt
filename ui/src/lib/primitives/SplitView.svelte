<script lang="ts">
	import Icon from '../Icon.svelte';
	import type { Snippet } from 'svelte';

	let {
		expanded = $bindable(true),
		hideButton = false,
		list,
		detail,
	}: {
		expanded?: boolean;
		hideButton?: boolean;
		list: Snippet;
		detail: Snippet;
	} = $props();
</script>

<div class="split">
	{#if !hideButton || expanded}
		<div class="list-pane" class:collapsed={!expanded}>
			{#if !hideButton}
				<button type="button" class="toggle" onclick={() => (expanded = !expanded)} title={expanded ? 'Collapse' : 'Expand'}>
					<Icon name={expanded ? 'chevron-left' : 'chevron-right'} size="1.2vmin" />
				</button>
			{/if}
			{#if expanded}
				<div class="list-content">
					{@render list()}
				</div>
			{/if}
		</div>
	{/if}
	<div class="detail-pane">
		{@render detail()}
	</div>
</div>

<style>
	.split {
		display: flex;
		height: 100%;
		gap: 0.6vw;
	}

	.list-pane {
		flex: 0 0 32%;
		min-width: 0;
		display: flex;
		flex-direction: column;
		background: var(--color-bg-panel);
		border-radius: var(--radius);
		overflow: hidden;
	}

	.list-pane.collapsed {
		flex: 0 0 auto;
	}

	.toggle {
		flex-shrink: 0;
		background: transparent;
		border: none;
		border-bottom: var(--border-subtle);
		color: var(--color-text-muted);
		cursor: pointer;
		padding: 0.8vh;
		display: flex;
		align-items: center;
		justify-content: center;
		transition: color 120ms ease;
	}

	.toggle:hover {
		color: var(--color-primary-light);
	}

	.list-content {
		flex: 1;
		min-height: 0;
		overflow-y: auto;
	}

	.detail-pane {
		flex: 1;
		min-width: 0;
		display: flex;
		flex-direction: column;
		background: var(--color-bg-panel);
		border-radius: var(--radius);
		overflow: hidden;
	}
</style>
