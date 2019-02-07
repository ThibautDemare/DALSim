model Transporters

import "Experiments.gaml"

species Transporter skills:Transporter {
	string networkType <- "unknown";
	float timeBetweenVehicles;
	float maximalTransportedVolume;
	float volumeKilometersCosts;
}

species RoadTransporter parent: Transporter {
	string networkType <- "road";
	float timeBetweenVehicles <- 1;
	float maximalTransportedVolume <- 33;// 33 palettes par camion / 1 camion = 2 EVP soit 16.5 palettes par evp

	/*
	 * Source :
	 * - Simulateur de coût de revient du CNR : http://www.cnr.fr/Outils-simulation2/Simulateurs 
	 */
	float volumeKilometersCosts <- 0.427 / maximalTransportedVolume;
}

species RiverTransporter parent: Transporter {
	string networkType <- "river";
	float timeBetweenVehicles <- 6;
	float maximalTransportedVolume <- 5775; // 1 barge ~ 350 EVP donc ~ 350 *16.5 = 5775 palettes par barges

	/* le fluvial coûte 2 à 4 fois moins que le routier. On va prendre la valeur basse dans notre simulation.
	 * sources :
	 * - https://www.guichet-entreprises.fr/fr/fluvial/transport-fluvial/
	 * - http://www.cnba-transportfluvial.fr/le-transport-fluvial/le-secteur
	 * - http://seme.cer.free.fr/plaisance/transport-fluvial.php
	 */
	float volumeKilometersCosts <- RoadTransporter[0].volumeKilometersCosts / 2.0;
}

species MaritimeTransporter parent: Transporter {
	string networkType <- "maritime";
	float timeBetweenVehicles <- 12;
	float maximalTransportedVolume <- 38346; // moyenne de 2 324 EVP par porte conteneur (source : Wikipedia). Soit 2324 * 16.5 = 38346 palettes par navires
	float volumeKilometersCosts <- RoadTransporter[0].volumeKilometersCosts / 4.0; // We don't really *need* a volume kilometer cost for this mode, however, if we give a zero value, there are weird results when we compute shortest paths 
}