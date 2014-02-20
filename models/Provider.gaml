/**
 *  Provider
 *  Author: Thibaut Démare
 *  Description: There is only one provider. He can satisfy all kind of demand. For each order receve,  a batch of goods is created.
 */

model Provider

import "./SeineAxisModel.gaml"
import "./LogisticProvider.gaml"
import "./Batch.gaml"
import "./Building.gaml"

species Provider parent: Role{
	Building building;
	
	init {
		create Building number: 1 returns: buildings {
			location <- myself.location;
		}
		
		ask buildings {
			myself.building <- self;
		}
	}
		
	/*
	 * Receive order from logistic provider
	 */
	action receiveOrder(Order order){
		// We create a new batch which can move to this provider to another building
		create Batch number: 1 {
			self.product <- order.product;
			self.quantity <- order.quantity;		
			self.target <- order.building.location;
			self.location <- myself.location;
			self.color <- order.color;
		}
	}
	
	aspect base { 
		draw square(1.5°km) color: rgb([100, 0, 100]) ;
	} 
}