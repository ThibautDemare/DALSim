/**
 *  Road
 *  Author: Thibaut Démare
 *  Description: The road network is made of these agent. One agent is a line from the shapefile. 
 */

model Road

import "./Batch.gaml"

species Road schedules: [] {
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
				draw shape + 2°px color: rgb(120, 120, 120) border: rgb(120, 120, 120);
			}
			else {
				draw shape + 2°px color: rgb(255, colorValue, 0) border:rgb(255, colorValue, 0);
			}
		}
	}
}
