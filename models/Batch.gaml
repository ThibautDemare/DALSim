/**
 *  Batch
 *  Author: Thibaut Démare
 *  Description: This agent simulates the real flow of goods. It moves on the physical network and must follow a supply chain. His behavior can be improve.
 */

model Batch

import "./SeineAxisModel.gaml"
import "./Building.gaml"

species Batch skills:[moving]{
	int product;
	float quantity;
	point target;
	float speed <- 70.0 °km/°h;
	int breakBulk <- 0;
	string color;
	reflex move when: target != nil and breakBulk = 0 {
		do goto target: target speed: speed on: road_network;
	}
	
	reflex decreaseBreakBulk when: breakBulk > 0 {
		breakBulk <- breakBulk - 1;
	}
	aspect base { 
		draw circle(3.0°km) color: rgb(color) ;
	}
	
	aspect little_base {
		draw circle(1.0°km) color: rgb(color) ;
	}
}