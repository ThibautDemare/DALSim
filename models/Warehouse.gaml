/**
 *  Warehouse
 *  Author: Thibaut Démare
 *  Description: A warehouse contains some batch of goods and is owned by a logistic provider
 */

model Warehouse

import "./Building.gaml"
import "./LogisticProvider.gaml"
import "./Batch.gaml"
import "./Stock.gaml"
import "./Order.gaml"
import "./SeineAxisModel.gaml"

species Warehouse parent: Building{
	float huffValue;
	string color;
	
	init {
		if(use_gs){
			// Add a new node event for corresponding sender
			if(use_r2){
				gs_add_node gs_sender_id:"neighborhood_all" gs_node_id:name;
				gs_add_node_attribute gs_sender_id:"neighborhood_all" gs_node_id:name gs_attribute_name:"ui.style" gs_attribute_value:"fill-color:"+color+";";
			}
			if(use_r3){
				gs_add_node gs_sender_id:"neighborhood_warehouse" gs_node_id:name;
				gs_add_node_attribute gs_sender_id:"neighborhood_warehouse" gs_node_id:name gs_attribute_name:"ui.style" gs_attribute_value:"fill-color:"+color+";";
			}
			if(use_r6){
				gs_add_node gs_sender_id:"neighborhood_warehouse_final" gs_node_id:name;
				gs_add_node_attribute gs_sender_id:"neighborhood_warehouse_final" gs_node_id:name gs_attribute_name:"ui.style" gs_attribute_value:"fill-color:"+color+";";
			}
		}
	}
	
	/*
	 * Receive a request from a logistic provider to restock another building
	 */
	action receiveRestockRequest(Order order){
		// We must update the stock and take care if we don't send a too big quantity (according to the real stock of this building) 
		float sendedQuantity <- 0.0;
		int i <- 0;
		bool found <- false;
					
		loop while: i < length(stocks) and !found {
			Stock stock <- stocks[i];
			if stock.product = order.product {				
				if((stock.quantity -  order.quantity) > 0){
					sendedQuantity <- order.quantity;
				}
				else{
					sendedQuantity <- stock.quantity;
				}
				stock.quantity <- stock.quantity - sendedQuantity;
				found <- true;
			}
			i <- i + 1;
		}
		
		// We create a new batch which can move to this warehouse to another building
		create Batch number: 1 {
			self.product <- order.product;
			self.quantity <- sendedQuantity;		
			self.target <- order.building.location;
			self.location <- myself.location;
			self.color <- "blue";
		}
	}
}
