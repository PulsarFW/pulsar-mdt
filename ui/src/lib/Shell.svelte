<script lang="ts">
	import { appState } from './store/app.svelte';
	import { dataState } from './store/data.svelte';
	import { resolvePortal } from '../config';
	import Titlebar from './Titlebar.svelte';
	import Navbar from './Navbar.svelte';
	import Toast from './Toast.svelte';

	import Home from './pages/Home.svelte';
	import ErrorPage from './pages/ErrorPage.svelte';
	import PrisonKiosk from './pages/PrisonKiosk.svelte';
	import PenalCode from './pages/PenalCode.svelte';
	import Library from './pages/Library.svelte';
	import CreateNotice from './pages/CreateNotice.svelte';
	import People from './pages/People.svelte';
	import Vehicles from './pages/Vehicles.svelte';
	import Properties from './pages/Properties.svelte';
	import Firearms from './pages/Firearms.svelte';
	import Warrants from './pages/Warrants.svelte';
	import Reports from './pages/Reports.svelte';
	import Roster from './pages/Roster.svelte';
	import FleetManager from './pages/FleetManager.svelte';
	import Prisoners from './pages/Prisoners.svelte';
	import PermissionManager from './pages/PermissionManager.svelte';
	import AdminCharges from './pages/AdminCharges.svelte';
	import CreateBolo from './pages/CreateBolo.svelte';

	const portal = $derived(resolvePortal(appState.govJob, appState.attorney));
</script>

{#if !appState.hidden}
	<div class="panel" style:opacity={appState.opacity ? '0.6' : '1'}>
		<Titlebar />
		{#if dataState.prison}
			<!-- in-cell kiosk mode: an inmate interacting with their own MDT, no navbar/portal chrome -->
			<div class="content">
				<PrisonKiosk />
			</div>
		{:else}
			<Navbar {portal} />
			<div class="content">
				{#if appState.page === 'home'}
					<Home {portal} />
				{:else if appState.page === 'penal-code'}
					<PenalCode />
				{:else if appState.page === 'library'}
					<Library />
				{:else if appState.page === 'create-notice'}
					<CreateNotice />
				{:else if appState.page === 'people'}
					<People />
				{:else if appState.page === 'vehicles'}
					<Vehicles />
				{:else if appState.page === 'properties'}
					<Properties />
				{:else if appState.page === 'firearms'}
					<Firearms />
				{:else if appState.page === 'warrants'}
					<Warrants />
				{:else if appState.page === 'reports'}
					<Reports />
				{:else if appState.page === 'roster'}
					<Roster />
				{:else if appState.page === 'fleet-manager'}
					<FleetManager />
				{:else if appState.page === 'prisoners'}
					<Prisoners />
				{:else if appState.page === 'admin-permissions'}
					<PermissionManager />
				{:else if appState.page === 'admin-charges'}
					<AdminCharges />
				{:else if appState.page === 'create-bolo'}
					<CreateBolo />
				{:else}
					<ErrorPage />
				{/if}
			</div>
		{/if}
		<Toast />
	</div>
{/if}

<style>
	.panel {
		position: absolute;
		top: 7vh;
		left: 9vw;
		right: 9vw;
		bottom: 7vh;
		display: flex;
		flex-direction: column;
		background: rgba(6, 6, 8, 1);
		border: var(--border-subtle);
		border-radius: var(--radius);
		overflow: hidden;
		pointer-events: auto;
		transition: opacity 200ms ease;
	}

	.content {
		flex: 1;
		min-width: 0;
		overflow-y: auto;
	}
</style>
