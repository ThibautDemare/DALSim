/**
 *  Provider
 *  Author: Thibaut Démare
 *  Description: There is only one provider. He can satisfy all kind of demand. For each order receve,  a batch of goods is created.
 */

model Provider

import "./SeineAxisModel.gaml"
import "./LogisticProvider.gaml"
import "./Batch.gaml"

species Provider parent: Role{
	/*
	 * Receive order from logistic provider
	 */
	action receive_order(Order order){
		create Batch number: 1 {
			product <- order.product;
			quantity <- order.quantity;
			logisticProvider <- order.logisticProvider;
			supplyChain <- order.supplyChain;
			target <- first(order.supplyChain).location;
			location <- myself.location;
		}
	}
	
	aspect base { 
		draw square(1.5°km) color: rgb([100, 0, 100]) ;
	} 
}