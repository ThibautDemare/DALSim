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
import "./GraphStreamConnection.gaml"

species Provider parent: Role{
	Building building;
	
	init {
		create Building number: 1 returns: buildings {
			location <- myself.location;
		}
		
		ask buildings {
			myself.building <- self;
		}
		
		if(use_gs){
			// Add a new node event for corresponding sender
			if(use_r9){
				gs_add_node gs_sender_id:"supply_chain" gs_node_id:building.name;
				gs_add_node_attribute gs_sender_id:"supply_chain" gs_node_id:building.name gs_attribute_name:"type" gs_attribute_value:"provider";
				gs_add_node_attribute gs_sender_id:"supply_chain" gs_node_id:building.name gs_attribute_name:"x" gs_attribute_value:location.x;
				gs_add_node_attribute gs_sender_id:"supply_chain" gs_node_id:building.name gs_attribute_name:"y" gs_attribute_value:location.y;
			}
		}
	}
		
	/*
	 * Receive order from a logistic provider
	 */
	action receiveOrder(Order order){
		// We create a new batch which can move to this provider to another building
		create Batch number: 1 {
			self.product <- order.product;
			self.quantity <- order.quantity;		
			self.target <- order.building.location;
			self.location <- myself.location;
			self.color <- order.color;
			self.breakBulk <- self.computeBreakBulk(rnd(10000)+2000);//We consider a fictive surface between 2000 and 12000
		}
	}
	
	aspect base { 
		draw square(5°km) color: rgb("MediumSeaGreen") ;
	} 
}