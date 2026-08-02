export const bodycamState = $state({ show: false });

export function handleBodycamMessage(type: string, data: Record<string, unknown>) {
	switch (type) {
		case 'SET_BODYCAM':
			bodycamState.show = Boolean(data.state);
			break;
		case 'TOGGLE_BODYCAM':
			bodycamState.show = !bodycamState.show;
			break;
	}
}
