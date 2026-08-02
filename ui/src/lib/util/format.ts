export const CURRENCY = new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' });

export function timeAgo(iso?: string): string {
	if (!iso) return '';
	const diffMs = Date.now() - Date.parse(iso);
	const mins = Math.floor(diffMs / 60000);
	if (mins < 1) return 'just now';
	if (mins < 60) return `${mins}m ago`;
	const hrs = Math.floor(mins / 60);
	if (hrs < 24) return `${hrs}h ago`;
	return `${Math.floor(hrs / 24)}d ago`;
}

export function timeUntil(iso: string): string {
	const diffMs = Date.parse(iso) - Date.now();
	if (diffMs <= 0) return 'expired';
	const hrs = Math.floor(diffMs / 3600000);
	if (hrs < 24) return `expires in ${hrs}h`;
	return `expires in ${Math.floor(hrs / 24)}d`;
}

export function formatDate(iso?: string): string {
	if (!iso) return 'Unknown';
	return new Date(iso).toLocaleDateString(undefined, { year: 'numeric', month: 'long', day: 'numeric' });
}

// MDT record fields mix epoch-ms numbers (client-set Date.now()) and MySQL datetime strings, this accepts either
export function formatDateTime(value?: number | string): string {
	if (!value) return 'Unknown';
	const date = typeof value === 'number' ? new Date(value) : new Date(value.includes(' ') ? value.replace(' ', 'T') : value);
	if (Number.isNaN(date.getTime())) return 'Unknown';
	return date.toLocaleString(undefined, { year: 'numeric', month: 'long', day: 'numeric', hour: 'numeric', minute: '2-digit' });
}
