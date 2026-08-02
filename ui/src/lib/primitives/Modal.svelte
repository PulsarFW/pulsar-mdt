<script lang="ts">
	import type { Snippet } from 'svelte';

	let {
		showing,
		title,
		acceptLabel = 'OK',
		closeLabel = 'Close',
		onAccept,
		onClose,
		children,
	}: {
		showing: boolean;
		title: string;
		acceptLabel?: string;
		closeLabel?: string;
		onAccept: () => void;
		onClose: () => void;
		children: Snippet;
	} = $props();
</script>

{#if showing}
	<div class="backdrop" onclick={onClose} onkeydown={(e) => e.key === 'Escape' && onClose()} role="button" tabindex="-1" aria-label="Close dialog">
		<div class="dialog-shell" onclick={(e) => e.stopPropagation()} onkeydown={(e) => e.stopPropagation()} role="dialog" aria-modal="true" tabindex="-1">
			<div class="dialog">
				<div class="title">{title}</div>
				<div class="body">
					{@render children()}
				</div>
				<div class="actions">
					<button type="button" class="btn btn-ghost" onclick={onClose}>{closeLabel}</button>
					<button type="button" class="btn btn-primary" onclick={onAccept}>{acceptLabel}</button>
				</div>
			</div>
		</div>
	</div>
{/if}

<style>
	.backdrop {
		position: fixed;
		inset: 0;
		background: rgba(0, 0, 0, 0.6);
		display: flex;
		align-items: center;
		justify-content: center;
		z-index: 150;
		pointer-events: auto;
	}

	.dialog-shell {
		width: 30vw;
		background: var(--color-bg-panel);
		border: var(--border-subtle);
		border-radius: var(--radius);
	}

	.dialog {
		padding: 2vh 1.6vw;
	}

	.title {
		font-family: var(--font-heading);
		font-size: 1.6vmin;
		color: var(--color-text);
	}

	.body {
		margin-top: 1.4vh;
		display: flex;
		flex-direction: column;
		gap: 1.2vh;
	}

	.actions {
		margin-top: 1.8vh;
		display: flex;
		justify-content: flex-end;
		gap: 0.8vw;
	}

	.btn {
		border: none;
		padding: 0.9vh 1.6vw;
		font-size: 1.2vmin;
		font-family: var(--font-body);
		cursor: pointer;
		border-radius: var(--radius);
	}

	.btn-ghost {
		background: transparent;
		color: var(--color-text-muted);
		border: var(--border-subtle);
	}

	.btn-primary {
		background: var(--color-primary);
		color: #ffffff;
	}
</style>
