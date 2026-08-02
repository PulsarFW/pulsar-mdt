<script lang="ts">
	import Icon from '../Icon.svelte';
</script>

<div class="wrap">
	<Icon name="triangle-exclamation" size="4vh" />
	<div class="title">Invalid Permissions</div>
	<div class="sub">You don't have access to this page.</div>
</div>

<style>
	.wrap {
		height: 100%;
		display: flex;
		flex-direction: column;
		align-items: center;
		justify-content: center;
		gap: 1vh;
		color: var(--color-text-muted);
	}

	.title {
		font-family: var(--font-heading);
		font-size: 1.8vmin;
		color: var(--color-text);
	}

	.sub {
		font-size: 1.2vmin;
	}
</style>
