model Commodity

import "Building.gaml"

species Commodity {
	float volume;
	Building finalDestination;
	list<Building> paths;
	date incomingDate;
	string currentNetwork;
	Stock stock;
	int stepOrderMade;
}