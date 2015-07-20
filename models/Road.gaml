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
	int color_r <- 120;
	int color_g <- 120;
	int color_b <- 120;
	aspect geom {
		draw shape + 2°px border: rgb(color_r, color_g, color_b) color: rgb(color_r, color_g, color_b);
	}
}
