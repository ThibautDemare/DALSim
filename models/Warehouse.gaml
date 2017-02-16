/**
 *  Warehouse
 *  Author: Thibaut Démare
 *  Description: A warehouse contains some stock of goods. It is managed by one or many LSP. It can create Batch agent to satisfy orders.
 */

model Warehouse

import "./Building.gaml"
import "./GraphStreamConnection.gaml"

species Warehouse parent: RestockingBuilding {
	string color;
	float accessibility <- -1; // Will contain the Schimbel's index.
	
	init {
		if(use_gs){
			// Add a new node event for corresponding sender
			if(use_r2){
				gs_add_node gs_sender_id:"neighborhood_all" gs_node_id:name;
				gs_add_node_attribute gs_sender_id:"neighborhood_all" gs_node_id:name gs_attribute_name:"type" gs_attribute_value:"warehouse";
			}
			if(use_r3){
				gs_add_node gs_sender_id:"neighborhood_warehouse" gs_node_id:name;
			}
			if(use_r6){
				gs_add_node gs_sender_id:"neighborhood_warehouse_final" gs_node_id:name;
			}
			if(use_r9){
				gs_add_node gs_sender_id:"supply_chain" gs_node_id:name;
				gs_add_node_attribute gs_sender_id:"supply_chain" gs_node_id:name gs_attribute_name:"x" gs_attribute_value:location.x;
				gs_add_node_attribute gs_sender_id:"supply_chain" gs_node_id:name gs_attribute_name:"y" gs_attribute_value:location.y;
				gs_add_node_attribute gs_sender_id:"supply_chain" gs_node_id:name gs_attribute_name:"outflow" gs_attribute_value:0.0;
			}
		}
	}
	
	aspect base {
		draw shape+3°px color: rgb("RoyalBlue");
	}

	aspect base_condition {
		if(length(stocks) != 0){
			draw shape+3°px color: rgb("RoyalBlue");
		}
	}
}
