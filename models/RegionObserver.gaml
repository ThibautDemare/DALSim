
model RegionObserver

import "Building.gaml"

species RegionObserver {
	string name;

	// Share by number of vehicle
	float sumRoadVehicleRO <- 0.0;
	float shareRoadVehicleRO <- 0.0;
	float sumRiverVehicleRO <- 0.0;
	float shareRiverVehicleRO <- 0.0;
	float sumMaritimeVehicleRO <- 0.0;
	float shareMaritimeVehicleRO <- 0.0;
	float sumVehicleRO;

	// Share by quantity of goods
	float sumRoadQuantitiesRO <- 0.0;
	float shareRoadQuantitiesRO <- 0.0;
	float sumRiverQuantitiesRO <- 0.0;
	float shareRiverQuantitiesRO <- 0.0;
	float sumMaritimeQuantitiesRO <- 0.0;
	float shareMaritimeQuantitiesRO <- 0.0;
	float sumQuantitiesRO;

	list<Building> buildings <- [];

	aspect geom {
		draw shape color: rgb("grey") border: rgb("black");	
	}
}