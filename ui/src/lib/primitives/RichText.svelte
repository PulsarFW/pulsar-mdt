<script lang="ts">
	let { value = $bindable(''), disabled = false, placeholder = 'Enter text...' }: { value?: string; disabled?: boolean; placeholder?: string } = $props();

	let el: HTMLDivElement | undefined = $state();
	let mounted = false;

	$effect(() => {
		if (el && !mounted) {
			el.innerHTML = value;
			mounted = true;
		}
	});

	function onInput() {
		value = el?.innerHTML ?? '';
	}

	function exec(command: string, arg?: string) {
		el?.focus();
		document.execCommand(command, false, arg);
		onInput();
	}

	function findBlockAncestor(node: Node): HTMLElement | null {
		let n: Node | null = node;
		while (n && n !== el) {
			if (n.parentNode === el) return n instanceof HTMLElement ? n : null;
			n = n.parentNode;
		}
		return null;
	}

	// execCommand('formatBlock') is unreliable in FiveM's CEF, so this swaps the block element directly instead
	function toggleBlock(tag: string) {
		if (!el) return;
		el.focus();
		const sel = window.getSelection();
		if (!sel || sel.rangeCount === 0) return;

		const block = findBlockAncestor(sel.getRangeAt(0).startContainer);
		const replacement = document.createElement(block && block.tagName.toLowerCase() === tag ? 'p' : tag);
		if (block) {
			replacement.innerHTML = block.innerHTML;
			block.replaceWith(replacement);
		} else {
			replacement.innerHTML = el.innerHTML;
			el.innerHTML = '';
			el.appendChild(replacement);
		}

		const range = document.createRange();
		range.selectNodeContents(replacement);
		range.collapse(false);
		sel.removeAllRanges();
		sel.addRange(range);

		onInput();
	}

	let imageUrl = $state('');
	let showImageInput = $state(false);

	function confirmImage() {
		if (imageUrl.trim()) exec('insertImage', imageUrl.trim());
		imageUrl = '';
		showImageInput = false;
	}
</script>

<div class="richtext" class:disabled>
	{#if !disabled}
		<div class="toolbar" role="toolbar" tabindex="-1" onmousedown={(e) => e.preventDefault()}>
			<button type="button" onclick={() => toggleBlock('h2')} title="Heading">H2</button>
			<button type="button" class="highlight" onclick={() => exec('hiliteColor', '#ffe066')} title="Highlight">HL</button>
			<span class="sep"></span>
			<button type="button" onclick={() => exec('bold')} title="Bold"><b>B</b></button>
			<button type="button" onclick={() => exec('italic')} title="Italic"><i>I</i></button>
			<button type="button" class="underline" onclick={() => exec('underline')} title="Underline">U</button>
			<button type="button" class="strike" onclick={() => exec('strikeThrough')} title="Strikethrough">S</button>
			<span class="sep"></span>
			<button type="button" onclick={() => exec('insertUnorderedList')} title="Bullet List">•</button>
			<button type="button" onclick={() => exec('insertOrderedList')} title="Numbered List">1.</button>
			<button type="button" onclick={() => toggleBlock('blockquote')} title="Blockquote">❝</button>
			<button type="button" class="code" onclick={() => toggleBlock('pre')} title="Code Block">&lt;/&gt;</button>
			<span class="sep"></span>
			<button type="button" onclick={() => (showImageInput = !showImageInput)} title="Insert Image">IMG</button>
		</div>
	{/if}
	{#if showImageInput}
		<div class="image-input">
			<input
				type="text"
				bind:value={imageUrl}
				placeholder="Image URL"
				onkeydown={(e) => {
					if (e.key === 'Enter') confirmImage();
					if (e.key === 'Escape') showImageInput = false;
				}}
			/>
			<button type="button" onclick={confirmImage}>Insert</button>
			<button type="button" onclick={() => (showImageInput = false)}>Cancel</button>
		</div>
	{/if}
	<div
		bind:this={el}
		class="editor"
		contenteditable={!disabled}
		data-placeholder={placeholder}
		oninput={onInput}
		role="textbox"
		aria-multiline="true"
		tabindex="0"
	></div>
</div>

<style>
	.richtext {
		display: flex;
		flex-direction: column;
		border: var(--border-subtle);
		border-radius: var(--radius);
		background: var(--color-bg);
		overflow: hidden;
	}

	.toolbar {
		display: flex;
		align-items: center;
		gap: 0.3vw;
		padding: 0.4vh 0.5vw;
		border-bottom: var(--border-subtle);
		background: var(--color-bg-panel-alt);
		flex-wrap: wrap;
	}

	.sep {
		width: 1px;
		align-self: stretch;
		background: var(--color-border);
		margin: 0 0.1vw;
	}

	.toolbar button {
		background: transparent;
		border: var(--border-subtle);
		border-radius: var(--radius);
		color: var(--color-surface-text-muted);
		cursor: pointer;
		min-width: 2.2vh;
		height: 2.2vh;
		padding: 0 0.4vw;
		font-size: 0.95vmin;
		display: flex;
		align-items: center;
		justify-content: center;
	}

	.toolbar button.underline {
		text-decoration: underline;
	}

	.toolbar button.strike {
		text-decoration: line-through;
	}

	.toolbar button.code {
		font-family: monospace;
	}

	.toolbar button:hover {
		color: var(--color-nav-text-active);
		border-color: var(--color-primary);
	}

	.image-input {
		display: flex;
		gap: 0.3vw;
		padding: 0.4vh 0.5vw;
		border-bottom: var(--border-subtle);
		background: var(--color-bg-panel-alt);
	}

	.image-input input {
		flex: 1;
		background: var(--color-bg);
		border: var(--border-subtle);
		border-radius: var(--radius);
		color: var(--color-surface-text);
		padding: 0.3vh 0.5vw;
		font-size: 0.95vmin;
	}

	.image-input button {
		background: transparent;
		border: var(--border-subtle);
		border-radius: var(--radius);
		color: var(--color-surface-text-muted);
		cursor: pointer;
		padding: 0 0.6vw;
		font-size: 0.95vmin;
	}

	.image-input button:hover {
		color: var(--color-nav-text-active);
		border-color: var(--color-primary);
	}

	.editor {
		flex: 1;
		min-height: 12vh;
		padding: 0.8vh 0.8vw;
		font-size: 1.1vmin;
		color: var(--color-text);
		overflow-y: auto;
	}

	.editor :global(blockquote) {
		margin: 0.4vh 0;
		padding-left: 0.6vw;
		border-left: 2px solid var(--color-border);
		color: var(--color-text-muted);
	}

	.editor :global(pre) {
		background: var(--color-bg-panel-alt);
		border: var(--border-subtle);
		border-radius: var(--radius);
		padding: 0.5vh 0.6vw;
		font-family: monospace;
		white-space: pre-wrap;
	}

	.editor :global(img) {
		max-width: 100%;
		border-radius: var(--radius);
	}

	.editor:focus {
		outline: none;
	}

	.editor:empty::before {
		content: attr(data-placeholder);
		color: var(--color-text-muted);
	}

	.richtext.disabled .editor {
		color: var(--color-text-muted);
	}
</style>
