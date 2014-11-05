/**
 *  Batch
 *  Author: Thibaut Démare
 *  Description: This agent simulates the real flow of goods. It moves on the physical network and must follow a supply chain. His behavior can be improve.
 */

model Batch

import "./SeineAxisModel.gaml"
import "./Building.gaml"
import "./FinalDestinationManager.gaml"

species Batch skills:[MovingOnNetwork]{
	float overallQuantity;
	list<Stock> stocks;
	point target;
	float speed <- 70.0 °km/°h;
	int breakBulk <- 0;
	int position;
	Building dest;
	
	reflex move when: target != nil and breakBulk = 0 {
		do goto target:target.location on:road_network length_attribute:"length" speed_attribute:"speed" mark:overallQuantity;
	}
	
	/**
	 * A break bulk can take between 2 and 24 hours.
	 * This function must be improve and take care of the surface of the building
	 */
	int computeBreakBulk(float surface){
		return rnd(22)+2;
	}
	
	reflex decreaseBreakBulk when: breakBulk > 0 {
		breakBulk <- breakBulk - 1;
	}
	
	aspect base {
		string color <- "";
		if( position = 1){// The provider must send new stock
			color <- "blue";
		}
		else if( position = 2 ){
			color <- "green";
		}
		else if( position = 3){
			color <- "orange";
		}
		draw triangle(3.0°km) color: rgb(color) ;
	}
	
	aspect little_base {
		string color <- "";
		if( position = 1){// The provider must send new stock
			color <- "blue";
		}
		else if( position = 2 ){
			color <- "green";
		}
		else if( position = 3){
			color <- "orange";
		}
		draw triangle(1.0°km) color: rgb(color) ;
	}
}