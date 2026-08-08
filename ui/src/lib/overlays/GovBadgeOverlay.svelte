<script lang="ts">
	import { badgeState } from '../store/badge.svelte';
	import { appState } from '../store/app.svelte';

	import doj from '../../assets/seals/doj_seal.webp';
	import lspd from '../../assets/seals/lspd_badge.webp';
	import sast from '../../assets/seals/SAST.webp';
	import guardius from '../../assets/seals/guardius.webp';
	import medical from '../../assets/seals/MedicalServices.webp';
	import corrections from '../../assets/seals/corrections.webp';
	import bcso from '../../assets/seals/bcso_seal.webp';
	import walletBg from '../../assets/badge/badge_background.png';
	import licenseCard from '../../assets/badge/card.png';

	// banner colors pulled from theme.css's per-department accent palette
	const DEPARTMENTS: Record<string, { name: string; seal: string; color: string }> = {
		lspd: { name: 'Los Santos Police Department', seal: lspd, color: '#bd9239' },
		bcso: { name: "Blaine County Sheriff's Office", seal: bcso, color: '#b2882e' },
		guardius: { name: 'Guardius', seal: guardius, color: '#bd9239' },
		sast: { name: 'San Andreas State Troopers', seal: sast, color: '#677aa8' },
		safd: { name: 'San Andreas Medical Services', seal: medical, color: '#7b9ff2' },
		doj: { name: 'San Andreas Department of Justice', seal: doj, color: '#009688' },
		dattorney: { name: "District Attorney's Office", seal: doj, color: '#009688' },
		publicdefenders: { name: 'Public Defenders Office', seal: doj, color: '#e5a502' },
		corrections: { name: 'San Andreas Department of Corrections', seal: corrections, color: '#e5a502' },
	};

	const visible = $derived(badgeState.showing && appState.hidden);
	const dept = $derived(DEPARTMENTS[badgeState.data?.Department ?? ''] ?? { name: 'San Andreas Government', seal: doj, color: '#e5a502' });
	// live pedheadshot (see RegisterPedheadshotTransparent in client/badges.lua) takes priority over the stored Mugshot
	const headshotUrl = $derived(badgeState.data?.HeadshotTxd ? `https://nui-img/${badgeState.data.HeadshotTxd}/${badgeState.data.HeadshotTxd}` : badgeState.data?.Mugshot);
</script>

{#if visible}
	<div class="overlay">
		{#if badgeState.type === 1}
			<div class="wallet">
				<img class="wallet-bg" src={walletBg} alt="" />
				<div class="wallet-content">
					<div class="info-pane">
						<div class="mugshot" style:background-image={headshotUrl ? `url(${headshotUrl})` : undefined}></div>
						<div class="dept-banner" style:background-color={dept.color}>{dept.name}</div>
						<div class="id-text">
							<div class="title">{badgeState.data?.Title ?? ''}</div>
							<div class="name">{badgeState.data?.First?.[0]?.toUpperCase() ?? ''}. {badgeState.data?.Last ?? ''}</div>
							{#if badgeState.data?.Callsign}
								<div class="callsign">#{badgeState.data.Callsign}</div>
							{/if}
							<div class="sid">State ID: {badgeState.data?.SID ?? ''}</div>
						</div>
					</div>
					<div class="seal-pane">
						<img src={dept.seal} alt="" />
					</div>
				</div>
			</div>
		{:else}
			<div class="license">
				<img class="license-bg" src={licenseCard} alt="" />
				<div class="license-content">
					<div class="license-title">San Andreas ID Card</div>
					<div class="license-body">
						<div class="license-mugshot" style:background-image={headshotUrl ? `url(${headshotUrl})` : undefined}></div>
						<div class="license-info">
							<p><span class="label">Name:</span> <span class="value">{badgeState.data?.Name ?? ''}</span></p>
							<p><span class="label">State ID:</span> <span class="value">{badgeState.data?.SID ?? ''}</span></p>
							<p><span class="label">DOB:</span> <span class="value">{badgeState.data?.DOB ?? 'Unknown'}</span></p>
						</div>
					</div>
				</div>
			</div>
		{/if}
	</div>
{/if}

<style>
	.overlay {
		position: fixed;
		top: 3vh;
		left: 2vw;
		width: fit-content;
		height: fit-content;
		pointer-events: none;
		user-select: none;
		z-index: 50;
	}

	/* bifold wallet, info card on one leaf, dept seal on the other, png has real transparent rounded corners so it's a plain img with content laid on top */
	.wallet {
		position: relative;
		width: 26vw;
		max-width: 400px;
	}

	.wallet-bg {
		display: block;
		width: 100%;
		height: auto;
		filter: drop-shadow(0 6px 16px rgba(0, 0, 0, 0.5));
	}

	.wallet-content {
		position: absolute;
		inset: 0;
		display: flex;
		padding: 9% 8% 9% 6%;
		gap: 6%;
	}

	.info-pane {
		flex: 0.8;
		background: #ebebeb;
		border-radius: 6px;
		display: flex;
		flex-direction: column;
		align-items: center;
		overflow: hidden;
		padding: 7% 5% 5%;
	}

	.mugshot {
		width: 34%;
		aspect-ratio: 1;
		border-radius: 50%;
		background-color: #cfcfcf;
		background-size: cover;
		background-position: center;
		flex-shrink: 0;
	}

	.dept-banner {
		width: 100%;
		margin-top: 6%;
		padding: 5% 3%;
		text-align: center;
		color: #fff;
		font-family: var(--font-heading);
		font-size: 0.95vmin;
		font-weight: 600;
		line-height: 1.25;
	}

	.id-text {
		margin-top: 6%;
		text-align: center;
	}

	.title {
		font-size: 1.15vmin;
		font-weight: 700;
		color: #1a1a1a;
		text-transform: capitalize;
	}

	.name {
		font-size: 1.05vmin;
		color: #1a1a1a;
		text-transform: capitalize;
		margin-top: 3%;
	}

	.callsign,
	.sid {
		font-size: 0.9vmin;
		color: #444;
		margin-top: 3%;
	}

	.seal-pane {
		flex: 1;
		display: flex;
		align-items: center;
		justify-content: center;
	}

	.seal-pane img {
		width: 78%;
		object-fit: contain;
	}

	/* sits on the "San Andreas Republic" ID card texture */
	.license {
		position: relative;
		width: 19vw;
		max-width: 320px;
	}

	.license-bg {
		display: block;
		width: 100%;
		height: auto;
		filter: drop-shadow(0 6px 16px rgba(0, 0, 0, 0.5));
	}

	.license-content {
		position: absolute;
		inset: 0;
		padding: 7% 8%;
		display: flex;
		flex-direction: column;
		justify-content: center;
	}

	.license-title {
		font-family: var(--font-heading);
		font-size: 1.55vmin;
		font-weight: 700;
		letter-spacing: 0.05em;
		text-transform: uppercase;
		color: #111;
		text-align: center;
	}

	.license-body {
		display: flex;
		align-items: center;
		gap: 9%;
		margin-top: 11%;
		padding: 0 3%;
	}

	.license-mugshot {
		width: 30%;
		aspect-ratio: 1;
		border-radius: 50%;
		background-color: #cfcfcf;
		background-size: cover;
		background-position: center;
		border: 2px solid rgba(255, 255, 255, 0.85);
		box-shadow: 0 1px 4px rgba(0, 0, 0, 0.35);
		flex-shrink: 0;
	}

	.license-info {
		flex: 1;
	}

	.license-info p {
		display: flex;
		flex-direction: column;
		gap: 0.2vh;
		margin: 0.7vh 0;
		font-size: 1.2vmin;
	}

	.license-info .label {
		font-weight: 600;
		font-size: 0.85vmin;
		color: rgba(0, 0, 0, 0.6);
	}

	.license-info .value {
		font-weight: 700;
		color: #0a0a0a;
	}
</style>
