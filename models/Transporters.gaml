model Transporters

import "Experiments.gaml"

species Transporter skills:Transporter {
	string networkType <- "unknown";
	float timeBetweenVehicles;
	float maximalTransportedVolume;
}

species RoadTransporter parent: Transporter {
	string networkType <- "road";
	float timeBetweenVehicles <- 1;
	float maximalTransportedVolume <- 50;
	float volumeKilometersCosts <- 1000;
}

species RiverTransporter parent: Transporter {
	string networkType <- "river";
	float timeBetweenVehicles <- 6;
	float maximalTransportedVolume <- 500;
	float volumeKilometersCosts <- 100;
}

species MaritimeTransporter parent: Transporter {
	string networkType <- "maritime";
	float timeBetweenVehicles <- 12;
	float maximalTransportedVolume <- 1000;
	float volumeKilometersCosts <- 1;
}