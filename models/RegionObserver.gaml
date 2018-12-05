
model RegionObserver

import "Building.gaml"

species RegionObserver {
	string name;

	// Share by number of vehicle
	float shareRoadVehicleRO <- 0.0;
	float shareRiverVehicleRO <- 0.0;
	float shareMaritimeVehicleRO <- 0.0;
	int sumVehicleRO;

	// Share by quantity of goods
	float shareRoadQuantitiesRO <- 0.0;
	float shareRiverQuantitiesRO <- 0.0;
	float shareMaritimeQuantitiesRO <- 0.0;
	int sumQuantitiesRO;

	list<Building> buildings <- [];

	aspect geom {
		draw shape color: rgb("grey") border: rgb("black");	
	}
}