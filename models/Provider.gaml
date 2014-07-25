/**
 *  Provider
 *  Author: Thibaut Démare
 *  Description: There is only one provider. He can satisfy all kind of demand. For each order receve,  a batch of goods is created.
 */

model Provider

import "./SeineAxisModel.gaml"
import "./Stock.gaml"
import "./Batch.gaml"
import "./Building.gaml"
import "./GraphStreamConnection.gaml"
import "./Order.gaml"

species Provider parent: RestockingBuilding schedules: [] {
	
	init {
		if(use_gs){
			// Add a new node event for corresponding sender
			if(use_r9){
				gs_add_node gs_sender_id:"supply_chain" gs_node_id:name;
				gs_add_node_attribute gs_sender_id:"supply_chain" gs_node_id:name gs_attribute_name:"type" gs_attribute_value:"provider";
				gs_add_node_attribute gs_sender_id:"supply_chain" gs_node_id:name gs_attribute_name:"x" gs_attribute_value:location.x;
				gs_add_node_attribute gs_sender_id:"supply_chain" gs_node_id:name gs_attribute_name:"y" gs_attribute_value:location.y;
			}
		}
	}
	
	/*
	 * Receive a request from a logistic provider to restock another building
	 */
	reflex processOrders when: !empty(currentOrders){
		list<Batch> leavingBatches <- [];
		// We empty progressively the list of orders after have processed them
		int i <- 0;
		loop while: i<length(currentOrders) {
			Order order <- currentOrders[i];
			
			// And create a Stock agent which will move within a Batch
			create Stock number:1 returns:sendedStock {
				self.product <- order.product;
				self.quantity <- order.quantity;
				self.fdm <- order.fdm;
			}
			
			// Looking for a batch which go to the same building
			bool foundBatch <- false;
			int j <- 0;
			loop while: j < length(leavingBatches) and !foundBatch {
				if( (leavingBatches[j] as Batch).dest = order.building  and order.position = (leavingBatches[j] as Batch).position){
					foundBatch <- true;
				}
				else {
					j <- j + 1;
				}
			}
			Batch lb <- nil;
			// There is a such Batch, we update it
			if(foundBatch){
				lb <- leavingBatches[j];
			}
			else {
				// else, we create one
				create Batch number: 1 returns:rlb {
					self.target <- order.building.location;
					self.location <- myself.location;
					self.breakBulk <- self.computeBreakBulk(myself.totalSurface);
					self.position <- order.position;
					self.dest <- order.building;
				}
				lb <- first(rlb);
				leavingBatches <- leavingBatches + lb;
			}
			
			lb.overallQuantity <- lb.overallQuantity + order.quantity;
			lb.stocks <- lb.stocks + sendedStock;

			i <- i + 1;
			ask order {
				do die;
			}
		}
		currentOrders <- [];
	}
	
	aspect base { 
		draw square(5°km) color: rgb("MediumSeaGreen") ;
	} 
}