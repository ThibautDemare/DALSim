/**
 *  Road
 *  Author: Thibaut Démare
 *  Description: The road network is made of these agent. One agent is a line from the shapefile. 
 */

model Road

import "./Batch.gaml"

species Road schedules: [] {
	//geometry display_shape <- shape + 2.0;
	float speed;
	float length;
	string color <- "gray";
	aspect geom {
		draw shape color: rgb(color);
	}
}
