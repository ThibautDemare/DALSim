model AwaitingStock

import "Stock.gaml"

species AwaitingStock schedules:[] {
	Stock stock;
	date stepOrderMade;
	int position;
	Building building;
	date incomingDate;
	string networkType;
}