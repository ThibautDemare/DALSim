
model RegionObserver

import "Building.gaml"

species RegionObserver {
	string name;
	list<Building> buildings <- [];
	list<FinalDestinationManager> fcs <- [];

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

	// Share of FC by origin port
	int nbAntwerp <- 0;
	int nbHavre <- 0;

	aspect geom {
		draw shape color: rgb("#91bfdb") border: rgb("grey");
	}
}