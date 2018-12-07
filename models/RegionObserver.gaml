
model RegionObserver

import "Building.gaml"

species RegionObserver {
	string name;

	// Share by number of vehicle
	float sumRoadVehicleRO <- 0.0;
	float sumRiverVehicleRO <- 0.0;
	float sumMaritimeVehicleRO <- 0.0;
	int sumVehicleRO;

	// Share by quantity of goods
	float sumRoadQuantitiesRO <- 0.0;
	float sumRiverQuantitiesRO <- 0.0;
	float sumMaritimeQuantitiesRO <- 0.0;
	int sumQuantitiesRO;

	list<Building> buildings <- [];

	aspect geom {
		draw shape color: rgb("grey") border: rgb("black");	
	}
}