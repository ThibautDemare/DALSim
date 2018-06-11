model Provider

import "Building.gaml"
import "GraphStreamConnection.gaml"
import "Order.gaml"
import "Commodity.gaml"
import "Parameters.gaml"
import "LogisticsServiceProvider.gaml"

species Provider parent: RestockingBuilding {
	list<LogisticsServiceProvider> customers <- [];
	string port;
	float attractiveness <- 1;
	float handling_time_to_maritime <- 1;

	init {
		if(port = "ANTWERP"){
			cost <- 200;
		}
		else {
			cost <- 400;
		}
		maxProcessOrdersCapacity <- 100;
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

	action addCustomer(LogisticsServiceProvider lp){
		customers <- customers + lp;
	}

	action lostCustomer(LogisticsServiceProvider lp){
		int k <- 0;
		bool notfound <- true;
		loop while: k < length(customers) and notfound {
			if(lp = customers[k]){
				remove index: k from: customers;
				notfound <- false;
			}
			else{
				k <- k + 1;
			}
		}
	}

	reflex receive_batch {
		// override reflex from RestockingBuilding
		// It is useless for providers since they are never restocked
	}

	/*
	 * Receive a request from a logistic provider to restock another building
	 */
	reflex processOrders when: !empty(currentOrders) and (((time/3600.0) + timeShifting) mod nbStepsBetweenPPO) = 0.0 {
		leavingVehicles <- [];
		// We empty progressively the list of orders after have processed them
		int i <- 0;
		loop while: ! empty(currentOrders) and i < maxProcessOrdersCapacity {
			Order order <- currentOrders[0];
			if(customers contains (order.logisticsServiceProvider)){
				// And create a Stock agent which will move within a Batch
				create Stock number:1 returns:sendedStock {
					self.product <- order.product;
					self.quantity <- order.quantity;
					self.fdm <- order.fdm;
					self.lp <- order.logisticsServiceProvider;
				}
	
				create Commodity number:1 returns:returnedAgent;
				Commodity commodity <- returnedAgent[0];
				commodity.stock <- sendedStock[0];
				commodity.volume <- sendedStock[0].quantity;
				commodity.finalDestination <- order.building;
				ask forwardingAgent {
					commodity.paths <- compute_shortest_path(myself, order.building, order.strategy, commodity);//'financial_costs'//travel_time
				}
				leavingCommodities <- leavingCommodities + commodity;
				
				i <- i + 1;
				
				outflow <- outflow + sendedStock[0].quantity;
				outflow_updated <- true;

				ask order {
					do die;
				}
			}
			remove index: 0 from: currentOrders;
			i <- i + 1;
		}
	}
	
	aspect base { 
		draw square(5°km) color: rgb("MediumSeaGreen") ;
	}
}