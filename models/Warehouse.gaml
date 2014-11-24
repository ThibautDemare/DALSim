/**
 *  Warehouse
 *  Author: Thibaut Démare
 *  Description: A warehouse contains some batch of goods and is owned by a logistic provider
 */

model Warehouse

import "./Building.gaml"
import "./GraphStreamConnection.gaml"

species Warehouse parent: RestockingBuilding schedules: [] {
	float huffValue;
	string color;
	int department;
	int region;
	
	init {
		if(use_gs){
			// Add a new node event for corresponding sender
			if(use_r2){
				gs_add_node gs_sender_id:"neighborhood_all" gs_node_id:name;
				gs_add_node_attribute gs_sender_id:"neighborhood_all" gs_node_id:name gs_attribute_name:"region" gs_attribute_value:region;
				gs_add_node_attribute gs_sender_id:"neighborhood_all" gs_node_id:name gs_attribute_name:"department" gs_attribute_value:department;
				gs_add_node_attribute gs_sender_id:"neighborhood_all" gs_node_id:name gs_attribute_name:"type" gs_attribute_value:"warehouse";
			}
			if(use_r3){
				gs_add_node gs_sender_id:"neighborhood_warehouse" gs_node_id:name;
				gs_add_node_attribute gs_sender_id:"neighborhood_warehouse" gs_node_id:name gs_attribute_name:"region" gs_attribute_value:region;
				gs_add_node_attribute gs_sender_id:"neighborhood_warehouse" gs_node_id:name gs_attribute_name:"department" gs_attribute_value:department;
			}
			if(use_r6){
				gs_add_node gs_sender_id:"neighborhood_warehouse_final" gs_node_id:name;
				gs_add_node_attribute gs_sender_id:"neighborhood_warehouse_final" gs_node_id:name gs_attribute_name:"region" gs_attribute_value:region;
				gs_add_node_attribute gs_sender_id:"neighborhood_warehouse_final" gs_node_id:name gs_attribute_name:"department" gs_attribute_value:department;
			}
			if(use_r9){
				gs_add_node gs_sender_id:"supply_chain" gs_node_id:name;
				gs_add_node_attribute gs_sender_id:"supply_chain" gs_node_id:name gs_attribute_name:"x" gs_attribute_value:location.x;
				gs_add_node_attribute gs_sender_id:"supply_chain" gs_node_id:name gs_attribute_name:"y" gs_attribute_value:location.y;
			}
		}
	}
	
	aspect base {
		draw circle(1.5°km) color: rgb("RoyalBlue");
	}

	aspect base_condition {
		if(length(stocks) != 0){
			draw circle(1.5°km) color: rgb("RoyalBlue");
		}
	}
}
