/**
 *  LogisticProvider
 *  Author: Thibaut Démare
 *  Description: This agent manage the stock of its warehouses and the orders of his final destinations. His behavior is still simple but can be improve
 */

model LogisticProvider

import "./Provider.gaml"
import "./Warehouse.gaml"
import "./Batch.gaml"
import "./Building.gaml"
import "./Order.gaml"
import "./SeineAxisModel.gaml"

species LogisticProvider parent: Role {
	list<FinalDestinationManager> finalDestinationManagers;
	list<Warehouse> warehouses_small;
	list<Warehouse> warehouses_average;
	list<Warehouse> warehouses_large;
	list<Order> orders;
	string color;
	
	init {
		if(use_gs){
			// Add a new node event for corresponding sender
			if(use_r1){
				gs_add_node gs_sender_id:"actor" gs_node_id:name;
				gs_add_node_attribute gs_sender_id:"actor" gs_node_id:name gs_attribute_name:"ui.style" gs_attribute_value:"fill-color:"+color+"; stroke-mode:plain; stroke-width:3px; stroke-color:red;";
			}
			if(use_r2){
				gs_add_node gs_sender_id:"neighborhood_all" gs_node_id:name;
				gs_add_node_attribute gs_sender_id:"neighborhood_all" gs_node_id:name gs_attribute_name:"ui.style" gs_attribute_value:"fill-color:"+color+";";
			}
			if(use_r5){
				gs_add_node gs_sender_id:"neighborhood_logistic_provider" gs_node_id:name;
				gs_add_node_attribute gs_sender_id:"neighborhood_logistic_provider" gs_node_id:name gs_attribute_name:"ui.style" gs_attribute_value:"fill-color:"+color+";";
			}
			if(use_r7){
				gs_add_node gs_sender_id:"neighborhood_logistic_final" gs_node_id:name;
				gs_add_node_attribute gs_sender_id:"neighborhood_logistic_final" gs_node_id:name gs_attribute_name:"ui.style" gs_attribute_value:"fill-color:"+color+";";
			}
		}
	}
	/*
	 * Receive order from the FinalDestinationManager and send it to the Provider
	 */
	action receive_order(Order order){
		if(length(warehouses_small) > 0){ 
			order.supplyChain <- (one_of(warehouses_small) as list) + order.supplyChain;
		}
		
		if(length(warehouses_average) > 0){
			order.supplyChain <- (one_of(warehouses_average) as list) + order.supplyChain;
		}	
		if(length(warehouses_large) > 0){
			order.supplyChain <- (one_of(warehouses_large) as list) + order.supplyChain;
		}
		if(length(warehouses_small) > 0 or length(warehouses_small) > 0 or length(warehouses_small) > 0){
			ask Provider {
				do receive_order(order);
			}
		}
		
		ask order {
			do die;
		}
	}
	
	aspect base { 
		draw square(1.5°km) color: rgb("green") ;
	} 
}