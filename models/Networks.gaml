model Networks

import "Experiments.gaml"

global {
	graph road_network;
	graph maritime_network;
	graph river_network;
}

species Road {
	float speed;
	float length;
	int colorValue <- -1; // This value is filled by the custom GAMA Plugin : MovingOnNetwork. It allows to colour the road according to the quantity of goods on the road.
	bool blocked <- false;
	aspect geom {
		if(blocked){
			draw shape + 2°px color: rgb(0, 255, 0) border: rgb(0, 255, 0);
		}
		else{
			if(colorValue = -1){
				string col <- "grey"; 
				draw shape + 2°px color: rgb(col) border: rgb(col);
			}
			else {
				draw shape + 2°px color: rgb(255, colorValue, 0) border:rgb(255, colorValue, 0);
			}
		}
	}
}

species MaritimeLine {
	float speed;
	float length;
	int colorValue <- -1; // This value is filled by the custom GAMA Plugin : MovingOnNetwork. It allows to colour the road according to the quantity of goods on the road.
	bool blocked <- false;
	aspect geom {
		if(blocked){
			draw shape + 2°px color: rgb(0, 255, 0) border: rgb(0, 255, 0);
		}
		else{
			if(colorValue = -1){
				string col <- "blue"; 
				draw shape + 2°px color: rgb(col) border: rgb(col);
			}
			else {
				draw shape + 2°px color: rgb(255, colorValue, 0) border:rgb(255, colorValue, 0);
			}
		}
	}
}

species RiverLine {
	float speed;
	float length;
	int colorValue <- -1; // This value is filled by the custom GAMA Plugin : MovingOnNetwork. It allows to colour the road according to the quantity of goods on the road.
	bool blocked <- false;
	aspect geom {
		if(blocked){
			draw shape + 2°px color: rgb(0, 255, 0) border: rgb(0, 255, 0);
		}
		else{
			if(colorValue = -1){
				string col <- "green"; 
				draw shape + 2°px color: rgb(col) border: rgb(col);
			}
			else {
				draw shape + 2°px color: rgb(255, colorValue, 0) border:rgb(255, colorValue, 0);
			}
		}
	}
}