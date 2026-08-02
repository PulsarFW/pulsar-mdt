<script lang="ts">
	import { dataState } from '../store/data.svelte';
	import { appState, navigate, toast } from '../store/app.svelte';
	import { Nui } from '../nui';
	import { timeAgo } from '../util/format';
	import Icon from '../Icon.svelte';
	import Modal from '../primitives/Modal.svelte';
	import Pagination from '../primitives/Pagination.svelte';
	import Loader from '../primitives/Loader.svelte';
	import type { Notice } from '../types';

	const PER_PAGE = 3;
	const HIGH_COMMAND_PERMS = ['PD_HIGH_COMMAND', 'SAFD_HIGH_COMMAND', 'DOJ_JUDGE', 'GOV_MAYOR', 'GOV_DA', 'GOV_CPUB', 'DOC_HIGH_COMMAND'];

	const canCreate = $derived(HIGH_COMMAND_PERMS.some((p) => appState.govJobPermissions[p]) || Boolean(appState.user?.MDTSystemAdmin));

	let page = $state(1);
	const sorted = $derived([...dataState.notices].sort((a, b) => (b.created ? Date.parse(b.created) : 0) - (a.created ? Date.parse(a.created) : 0)));
	const pages = $derived(Math.max(1, Math.ceil(sorted.length / PER_PAGE)));
	const pageItems = $derived(sorted.slice((page - 1) * PER_PAGE, page * PER_PAGE));

	let openNotice = $state<Notice | null>(null);
	let loadingNotice = $state(false);
	let detail = $state<Notice | null>(null);

	async function open(notice: Notice) {
		openNotice = notice;
		loadingNotice = true;
		detail = (await Nui.viewNotice(notice.id)) || null;
		loadingNotice = false;
	}

	function close() {
		openNotice = null;
		detail = null;
	}

	function canDelete(notice: Notice): boolean {
		return canCreate || notice.creator === appState.user?.SID;
	}

	async function remove() {
		if (!openNotice) return;
		const ok = await Nui.deleteNotice(openNotice.id);
		if (ok) {
			dataState.notices = dataState.notices.filter((n) => n.id !== openNotice!.id);
			toast.success('Notice Dismissed');
		} else {
			toast.error('Unable to Dismiss Notice');
		}
		close();
	}
</script>

<div class="block">
	<div class="header">
		<span>Notice Board</span>
		{#if canCreate}
			<button type="button" class="create" onclick={() => navigate('create-notice')} aria-label="Create notice">
				<Icon name="plus" size="0.8em" />
			</button>
		{/if}
	</div>
	<div class="list">
		{#if pageItems.length > 0}
			{#each pageItems as notice (notice.id)}
				<button type="button" class="notice-row" onclick={() => open(notice)}>
					<Icon name={notice.restricted !== 'public' && notice.restricted !== 'government' ? 'lock' : 'circle-exclamation'} size="1.1vmin" />
					<span class="title">{notice.title}</span>
					<span class="time">{timeAgo(notice.created)}</span>
				</button>
			{/each}
		{:else}
			<div class="empty">No Notices</div>
		{/if}
	</div>
	<Pagination bind:page {pages} />
</div>

<Modal showing={openNotice !== null} title={openNotice?.title ?? ''} acceptLabel={canDelete(openNotice ?? ({} as Notice)) ? 'Delete' : 'Close'} onAccept={canDelete(openNotice ?? ({} as Notice)) ? remove : close} onClose={close}>
	{#if loadingNotice || !detail}
		<Loader static />
	{:else}
		<p class="body-text">{@html detail.description}</p>
		<div class="meta">
			<span>Author: State ID {detail.creator}</span>
		</div>
	{/if}
</Modal>

<style>
	.block {
		background: var(--color-bg-panel);
		border: var(--border-subtle);
		border-radius: var(--radius);
		padding: 0.8rem;
	}

	.header {
		display: flex;
		align-items: center;
		justify-content: space-between;
		padding-bottom: 0.6rem;
		margin-bottom: 0.4rem;
		border-bottom: var(--border-subtle);
		color: var(--color-primary-light);
		font-family: var(--font-heading);
		font-size: 0.9rem;
	}

	.create {
		width: 1.8rem;
		height: 1.8rem;
		border-radius: var(--radius);
		border: none;
		background: rgba(139, 92, 246, 0.15);
		color: var(--color-primary-light);
		cursor: pointer;
		display: flex;
		align-items: center;
		justify-content: center;
	}

	.list {
		display: flex;
		flex-direction: column;
		gap: 0.3rem;
	}

	.notice-row {
		display: flex;
		align-items: center;
		gap: 0.5rem;
		width: 100%;
		background: transparent;
		border: none;
		text-align: left;
		padding: 0.5rem 0.3rem;
		border-radius: var(--radius);
		color: var(--color-text);
		cursor: pointer;
	}

	.notice-row:hover {
		background: rgba(139, 92, 246, 0.08);
	}

	.notice-row .title {
		flex: 1;
		font-size: 0.85rem;
		white-space: nowrap;
		overflow: hidden;
		text-overflow: ellipsis;
	}

	.notice-row .time {
		font-size: 0.7rem;
		color: var(--color-text-muted);
		flex-shrink: 0;
	}

	.empty {
		padding: 1rem 0;
		text-align: center;
		font-size: 0.8rem;
		color: var(--color-text-muted);
	}

	.body-text {
		white-space: pre-line;
		color: var(--color-text);
		font-size: 1.2vmin;
	}

	.meta {
		margin-top: 1vh;
		font-size: 1.05vmin;
		color: var(--color-text-muted);
	}
</style>
