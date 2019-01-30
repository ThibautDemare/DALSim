
model RegionObserver

import "Building.gaml"

species RegionObserver {
	string name;
	list<Building> buildings <- [];
	list<FinalConsignee> fcs <- [];
	list<Terminal> terminals <- [];

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

	// Share by number of vehicle leaving terminals
	float sumLeavingRoadVehicleRO <- 0.0;
	float shareLeavingRoadVehicleRO <- 0.0;
	float sumLeavingRiverVehicleRO <- 0.0;
	float shareLeavingRiverVehicleRO <- 0.0;
	float sumLeavingMaritimeVehicleRO <- 0.0;
	float shareLeavingMaritimeVehicleRO <- 0.0;
	float sumLeavingVehicleRO;

	// Share by quantity of goods leaving terminals
	float sumLeavingRoadQuantitiesRO <- 0.0;
	float shareLeavingRoadQuantitiesRO <- 0.0;
	float sumLeavingRiverQuantitiesRO <- 0.0;
	float shareLeavingRiverQuantitiesRO <- 0.0;
	float sumLeavingMaritimeQuantitiesRO <- 0.0;
	float shareLeavingMaritimeQuantitiesRO <- 0.0;
	float sumLeavingQuantitiesRO;

	// Share of FC by origin port
	int nbAntwerp <- 0;
	int nbHavre <- 0;

	aspect geom {
		draw shape color: rgb("#91bfdb") border: rgb("grey");
	}
}