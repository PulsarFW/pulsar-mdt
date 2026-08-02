export const searchState = $state({
	people: '',
	vehicle: '',
	firearm: '',
	report: '',
	warrant: '',
	property: '',
});

export function clearSearch() {
	searchState.people = '';
	searchState.vehicle = '';
	searchState.firearm = '';
	searchState.report = '';
	searchState.warrant = '';
	searchState.property = '';
}
