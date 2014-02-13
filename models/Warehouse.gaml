/**
 *  Warehouse
 *  Author: Thibaut Démare
 *  Description: A warehouse contains some batch of goods and is owned by a logistic provider
 */

model Warehouse

import "./Building.gaml"
import "./LogisticProvider.gaml"
import "./SeineAxisModel.gaml"

species Warehouse parent: Building{
	LogisticProvider logisticProvider;
	list<Batch> batchs;
	float huffValue;
	string color;
	
	init {
		logisticProvider <- nil;
		
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
}
