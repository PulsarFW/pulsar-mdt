<script lang="ts">
	import Icon from './Icon.svelte';
	import { Nui } from './nui';
	import { appState, setOpacity } from './store/app.svelte';
	import { brandingFor } from '../config';

	import saSeal from '../assets/seals/seal.webp';
	import lsSeal from '../assets/seals/ls_seal.webp';
	import sastSeal from '../assets/seals/SAST.webp';
	import bcsoSeal from '../assets/seals/bcso_seal.webp';
	import guardiusSeal from '../assets/seals/guardius2.webp';
	import dojSeal from '../assets/seals/doj_seal.webp';
	import medicalSeal from '../assets/seals/MedicalServices.webp';
	import docSeal from '../assets/seals/corrections.webp';

	const branding = $derived(brandingFor(appState.govJob, appState.attorney));
	const headshotUrl = $derived(appState.userHeadshotTxd ? `https://nui-img/${appState.userHeadshotTxd}/${appState.userHeadshotTxd}` : undefined);

	const seal = $derived.by(() => {
		if (appState.attorney && !appState.govJob) return dojSeal;
		switch (appState.govJob?.Id) {
			case 'police':
				switch (appState.govJob.Workplace?.Id) {
					case 'lspd':
						return lsSeal;
					case 'bcso':
						return bcsoSeal;
					case 'sast':
						return sastSeal;
					case 'guardius':
						return guardiusSeal;
					default:
						return saSeal;
				}
			case 'prison':
				return docSeal;
			case 'government':
				return dojSeal;
			case 'ems':
				return medicalSeal;
			default:
				return saSeal;
		}
	});
</script>

<div class="titlebar" onmouseenter={() => setOpacity(true)} onmouseleave={() => setOpacity(false)} role="presentation">
	<div class="branding">
		<img class="seal" src={seal} alt="" />
		<div class="text">
			<span class="primary">{branding.primary}</span>
			<span class="secondary">{branding.secondary}</span>
		</div>
	</div>

	<div class="right">
		<div class="account">
			<div class="account-text">
				<small>{appState.govJob?.Name ?? (appState.attorney ? 'Attorney' : 'Public')}</small>
				<span>{appState.user ? `${appState.user.First} ${appState.user.Last}` : ''}</span>
			</div>
			<div class="avatar placeholder">
				{#if headshotUrl}
					<img src={headshotUrl} alt="" />
				{/if}
			</div>
		</div>

		<div class="divider"></div>

		<button type="button" class="icon-btn" title="Close" onclick={() => Nui.close()}>
			<Icon name="xmark" size="1.6vmin" />
		</button>
	</div>
</div>

<style>
	.titlebar {
		flex-shrink: 0;
		display: flex;
		align-items: center;
		justify-content: space-between;
		padding: 1vh 1.2vw;
		border-bottom: var(--border-subtle);
	}

	.branding {
		display: flex;
		align-items: center;
		gap: 0.8vw;
	}

	.seal {
		height: 5.2vh;
		width: auto;
		object-fit: contain;
	}

	.text {
		display: flex;
		flex-direction: column;
	}

	.text .primary {
		font-family: var(--font-heading);
		font-size: 1.8vmin;
		font-weight: 700;
		color: var(--color-text);
	}

	.text .secondary {
		font-size: 1.1vmin;
		color: var(--color-text-muted);
	}

	.right {
		display: flex;
		align-items: center;
		gap: 0.7vw;
	}

	.account {
		display: flex;
		align-items: center;
		gap: 0.7vw;
	}

	.account-text {
		text-align: right;
	}

	.account-text small {
		display: block;
		color: var(--color-text-muted);
		font-size: 1.05vmin;
	}

	.account-text span {
		font-size: 1.3vmin;
		font-weight: 600;
		color: var(--color-text);
	}

	.avatar {
		width: 3vh;
		height: 3vh;
		border-radius: 50%;
		overflow: hidden;
		flex-shrink: 0;
	}

	.avatar.placeholder {
		background: rgba(139, 92, 246, 0.25);
	}

	.avatar img {
		width: 100%;
		height: 100%;
		object-fit: cover;
	}

	.divider {
		width: 1px;
		height: 3vh;
		background: rgba(232, 232, 236, 0.12);
	}

	.icon-btn {
		background: transparent;
		border: none;
		color: rgba(232, 232, 236, 0.55);
		cursor: pointer;
		padding: 1vh 0.9vw;
		display: flex;
		border-radius: var(--radius);
		transition: color 120ms ease, background 120ms ease;
	}

	.icon-btn:hover {
		color: var(--color-primary-light);
		background: rgba(139, 92, 246, 0.12);
	}
</style>
