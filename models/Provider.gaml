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
import "./Order.gaml"

species Provider parent: Building{
	
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
	
	aspect base { 
		draw square(5°km) color: rgb("MediumSeaGreen") ;
	} 
}