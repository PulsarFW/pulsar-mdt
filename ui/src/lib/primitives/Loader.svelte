<script lang="ts">
	let { text = 'Loading Data', subtext, static: isStatic = false }: { text?: string; subtext?: string; static?: boolean } = $props();
</script>

<div class="loader" class:static={isStatic}>
	<div class="spinner"></div>
	<div class="text">{text}</div>
	{#if subtext}<div class="subtext">{subtext}</div>{/if}
</div>

<style>
	.loader {
		text-align: center;
		margin-top: 1vh;
	}

	.loader.static {
		position: absolute;
		inset: 0;
		margin: auto;
		width: fit-content;
		height: fit-content;
	}

	.spinner {
		width: 3.2vh;
		height: 3.2vh;
		margin: 0 auto 1vh;
		border: 3px solid rgba(139, 92, 246, 0.2);
		border-top-color: var(--color-primary);
		border-radius: 50%;
		animation: spin 800ms linear infinite;
	}

	.text {
		font-size: 1.2vmin;
		font-weight: 600;
		color: var(--color-text);
	}

	.subtext {
		font-size: 1vmin;
		color: var(--color-text-muted);
		margin-top: 0.4vh;
	}

	@keyframes spin {
		to {
			transform: rotate(360deg);
		}
	}
</style>
