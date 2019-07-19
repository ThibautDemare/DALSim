model ForwardingAgent

import "Transporters.gaml"
import "Experiments.gaml"

species ForwardingAgent skills:[TransportOrganizer]{
	Transporter transporter_road;
	Transporter transporter_maritime;
	Transporter transporter_river;
	Transporter transporter_secondary;
	float colorValue <- -1;

	init {
		transporter_road <- RoadTransporter[0];
		transporter_river <- RiverTransporter[0];
		transporter_maritime <- MaritimeTransporter[0];
		transporter_secondary <- SecondaryMaritimeTransporter[0];
	}

	aspect geom {
		if(colorValue = -1){
			string col <- "grey"; 
			draw shape + 2°px color: rgb(col) border: rgb(col);
		}
		else {
			draw shape + 2°px color: rgb(255, colorValue, 0) border:rgb(255, colorValue, 0);
		}
	}
}