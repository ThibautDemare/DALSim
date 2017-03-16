/**
 *  Batch
 *  Author: Thibaut Démare
 *  Description: This agent simulates the real flow of goods. It moves on the physical network and must follow a supply chain. His behavior can be improve.
 */

model Batch

import "./SeineAxisModel.gaml"
import "./Building.gaml"
import "./FinalDestinationManager.gaml"

species Batch skills:[MovingOnNetwork] {
	float overallQuantity;
	list<Stock> stocks;
	point target;
	float speed <- 70.0 °km/°h;
	int position; // The position allows to make distinction between Batch agents coming from Provider (position = 1), national warehouse (position = 2), or local warehouse (position = 3).
	Building dest;
	int stepOrderMade;
	bool marked <- false;// useful for the Observer in order to avoid to count the batch two times
	float pathLength <- -1;

	action init_network{
		network <- road_network;
	}

	reflex delete when: target = nil and dest != nil {
		do die;
	}

	reflex move when: target != nil {
		if(network = nil){
			network <- road_network;
		}
		do go_to target:target.location length_attribute:"length" speed_attribute:"speed" mark:overallQuantity;

		if(location = dest.location){
			// The agent is at destination
			// We have to transfer its stocks to the building
			ask dest {
				do receive_stocks(myself);
			}
			target <- nil;
		}
	}

	aspect base {
		string c <- "";
		if( position = 1){// The provider must send new stock
			c <- "blue";
		}
		else if( position = 2 ){
			c <- "green";
		}
		else if( position = 3){
			c <- "orange";
		}
		else {
			c <- "grey";
		}
		if(position > 0){
			draw shape color: rgb(c) ;
		}
	}
	
	aspect little_base {
		string c <- "";
		if( position = 1){// The provider must send new stock
			c <- "blue";
		}
		else if( position = 2 ){
			c <- "green";
		}
		else if( position = 3){
			c <- "orange";
		}
		else {
			c <- "grey";
		}
		if(position > 0){
			draw shape color: rgb(c) ;
		}
	}
}