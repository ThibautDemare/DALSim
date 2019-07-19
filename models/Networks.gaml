model Networks

global {
	graph road_network;
	graph maritime_network;
	graph secondary_network;
	graph river_network;
}

species Network {
	string col;
	float speed;
	float length;
	int colorValue <- -1; // This value is filled by the custom GAMA Plugin : MovingOnNetwork. It allows to colour the road according to the quantity of goods on the road.
	string colorRVBValue <- "";
	int sizeShape <- 1;
	bool blocked <- false;
	float current_marks;
	float current_volume;
	float cumulative_marks;
	float cumulative_nb_agents;
	float current_nb_agents;

	aspect geom {
		if(blocked){
			draw shape + 2°px color: rgb("#4575b4") border: rgb("#4575b4");
		}
		else{
			if(colorRVBValue = ""){
				if(sizeShape = 0){
					draw shape color: rgb(col) border: rgb(col);
				}
				else {
					draw shape color: rgb(col) border: rgb(col);
				}
			}
			else {
				if(sizeShape = 0){
					draw shape color: rgb(colorRVBValue) border:rgb(colorRVBValue);
				}
				else {
					draw shape + sizeShape°px color: rgb(colorRVBValue) border:rgb(colorRVBValue);
				}
			}
		}
	}

	aspect lightGeom {
		if(blocked){
			draw shape color: rgb("#4575b4") border: rgb("#4575b4");
		}
		else{
			if(colorRVBValue = ""){
				draw shape color: rgb(col) border: rgb(col);
			}
			else {
				draw shape color: rgb(colorRVBValue) border:rgb(colorRVBValue);
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

species SecondaryMaritimeLine parent:Network {
	string col <- "blue";
}

species RiverLine parent:Network {
	string col <- "green";
	int is_new;
}