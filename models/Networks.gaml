model Networks

global {
	graph road_network;
	graph maritime_network;
	graph river_network;
}

species Network {
	string col;
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
				draw shape + 2°px color: rgb(col) border: rgb(col);
			}
			else {
				draw shape + 2°px color: rgb(255, colorValue, 0) border:rgb(255, colorValue, 0);
			}
		}
	}
}
species Road parent:Network {
	string col <- "grey";
}

species MaritimeLine parent:Network {
	string col <- "blue";
}

species RiverLine parent:Network {
	string col <- "green";
	int is_new;
}