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
	list<LogisticProvider> customers <- [];

	init {
		maxProcessOrdersCapacity <- 3;
		if(use_gs){
			// Add a new node event for corresponding sender
			if(use_r9){
				gs_add_node gs_sender_id:"supply_chain" gs_node_id:name;
				gs_add_node_attribute gs_sender_id:"supply_chain" gs_node_id:name gs_attribute_name:"type" gs_attribute_value:"provider";
				gs_add_node_attribute gs_sender_id:"supply_chain" gs_node_id:name gs_attribute_name:"x" gs_attribute_value:location.x;
				gs_add_node_attribute gs_sender_id:"supply_chain" gs_node_id:name gs_attribute_name:"y" gs_attribute_value:location.y;
				gs_add_node_attribute gs_sender_id:"supply_chain" gs_node_id:name gs_attribute_name:"outflow" gs_attribute_value:0.0;
			}
		}
	}

	action addCustomer(LogisticProvider lp){
		customers <- customers + lp;
	}

	/*
	 * Receive a request from a logistic provider to restock another building
	 */
	reflex processOrders when: !empty(currentOrders) and (((time/3600.0) + timeShifting) mod nbStepsBetweenPPO) = 0.0 {
		leavingBatches <- [];
		// We empty progressively the list of orders after have processed them
		int i <- 0;
		loop while: ! empty(currentOrders) and i < maxProcessOrdersCapacity {
			Order order <- currentOrders[0];
			if(customers contains (order.logisticProvider)){
				// And create a Stock agent which will move within a Batch
				create Stock number:1 returns:sendedStock {
					self.product <- order.product;
					self.quantity <- order.quantity;
					self.fdm <- order.fdm;
					self.lp <- order.logisticProvider;
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
				// There is such a Batch, we update it
				if(foundBatch){
					lb <- leavingBatches[j];
				}
				else {
					// else, we create one
					create Batch number: 1 returns:rlb {
						self.target <- order.building.location;
						self.location <- myself.location;
						self.position <- order.position;
						self.dest <- order.building;
						self.stepOrderMade <- order.stepOrderMade;
					}
					lb <- first(rlb);
					leavingBatches <- leavingBatches + lb;
				}

				lb.overallQuantity <- lb.overallQuantity + order.quantity;
				lb.stocks <- lb.stocks + sendedStock;

				outflow <- outflow + first(sendedStock).quantity;
				outflow_updated <- true;
			}
			ask order {
				do die;
			}
			remove index: 0 from: currentOrders;
			i <- i + 1;
		}
	}
	
	aspect base { 
		draw square(5°km) color: rgb("MediumSeaGreen") ;
	}
}