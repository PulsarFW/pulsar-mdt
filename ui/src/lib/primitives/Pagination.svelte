<script lang="ts">
	let { page = $bindable(1), pages, onChange }: { page: number; pages: number; onChange?: (p: number) => void } = $props();

	function go(p: number) {
		page = p;
		onChange?.(p);
	}

	const items = $derived.by(() => {
		const total = pages;
		const current = page;
		const nums = new Set<number>([1, total]);
		for (let d = -1; d <= 1; d++) {
			const p = current + d;
			if (p >= 1 && p <= total) nums.add(p);
		}
		const sorted = Array.from(nums).sort((a, b) => a - b);
		const result: (number | '…')[] = [];
		for (let i = 0; i < sorted.length; i++) {
			if (i > 0 && sorted[i] - sorted[i - 1] > 1) result.push('…');
			result.push(sorted[i]);
		}
		return result;
	});
</script>

{#if pages > 1}
	<div class="pagination">
		{#each items as item, i (i)}
			{#if item === '…'}
				<span class="ellipsis">…</span>
			{:else}
				<button type="button" class="page-btn" class:active={page === item} onclick={() => go(item)}>{item}</button>
			{/if}
		{/each}
	</div>
{/if}

<style>
	.pagination {
		display: flex;
		flex-wrap: wrap;
		gap: 0.3rem;
		justify-content: center;
		margin-top: 0.8rem;
	}

	.page-btn {
		width: 1.7rem;
		height: 1.7rem;
		border-radius: var(--radius);
		border: var(--border-subtle);
		background: transparent;
		color: var(--color-text-muted);
		font-size: 0.72rem;
		cursor: pointer;
	}

	.page-btn.active {
		border-color: var(--color-primary);
		color: var(--color-primary-light);
	}

	.ellipsis {
		display: flex;
		align-items: center;
		justify-content: center;
		width: 1.7rem;
		height: 1.7rem;
		color: var(--color-text-muted);
		font-size: 0.72rem;
	}
</style>
