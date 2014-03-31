/**
 *  GraphStreamConnection
 *  Author: Thibaut
 *  Description: 
 */

model GraphStreamConnection

import "./SeineAxisModel.gaml"
import "./Warehouse.gaml"
import "./LogisticProvider.gaml"
import "./FinalDestinationManager.gaml"

global {
	
	bool use_gs <- true;
	bool use_r1 <- true;//actor
	bool use_r2 <- true;//init_neighborhood_all
	bool use_r3 <- true;//init_neighborhood_warehouse
	bool use_r4 <- true;//init_neighborhood_final_destination
	bool use_r5 <- true;//init_neighborhood_logistic_provider
	bool use_r6 <- true;//init_neighborhood_warehouse_final
	bool use_r7 <- true;//init_neighborhood_logistic_final
	bool use_r8 <- true;//init_use_road_network
	bool use_r9 <- true;//init_use_supply_chain
	
	float neighborhood_dist <- 1°km;
	
	/**
	 * Second step to send graphs events. These functions can't be called in standard init so it is made in a reflex at the first cycle.
	 */
	reflex init_edges when: cycle = 1 {
		if(use_gs){
			if(use_r1){
				// Send a step event to Graphstream to indicate that the graph has been built
				gs_step gs_sender_id:"actor" gs_step_number:1;
			}
			
			if(use_r2){
				do init_neighborhood_all;
			}
			
			if(use_r3){
				do init_neighborhood_warehouse;
			}
			
			if(use_r4){
				do init_neighborhood_final_destination;
			}
			
			if(use_r5){
				do init_neighborhood_logistic_provider;
			}
			
			if(use_r6){
				do init_neighborhood_warehouse_final;
			}
			
			if(use_r7){
				do init_neighborhood_logistic_final;
			}
		
			if(use_r9){
				// Send a step event to Graphstream to indicate that the graph has been built
				gs_step gs_sender_id:"supply_chain" gs_step_number:1;
			}
		}
	}
	
	
	action init_senders {
		gs_clear_senders;
		
		if(use_r1){
			// In order to build a network of interaction between final destination manager and logistic manager
			gs_add_sender gs_host:"localhost" gs_port:2001 gs_sender_id:"actor";
			gs_add_graph_attribute gs_sender_id:"actor" gs_attribute_name:"name" gs_attribute_value:"actor"+"_"+destination_file_name;
		}
		
		if(use_r2){
			// In order to build a neighborhood network between all agent
			gs_add_sender gs_host:"localhost" gs_port:2002 gs_sender_id:"neighborhood_all";
			gs_add_graph_attribute gs_sender_id:"neighborhood_all" gs_attribute_name:"name" gs_attribute_value:"neighborhood_all"+"_"+destination_file_name;
		}
		
		if(use_r3){
			// In order to build a neighborhood network between warehouse
			gs_add_sender gs_host:"localhost" gs_port:2003 gs_sender_id:"neighborhood_warehouse";
			gs_add_graph_attribute gs_sender_id:"neighborhood_warehouse" gs_attribute_name:"name" gs_attribute_value:"neighborhood_warehouse"+"_"+destination_file_name;
		}
		
		if(use_r4){
			// In order to build a neighborhood network between final destination
			gs_add_sender gs_host:"localhost" gs_port:2004 gs_sender_id:"neighborhood_final_destination";
			gs_add_graph_attribute gs_sender_id:"neighborhood_final_destination" gs_attribute_name:"name" gs_attribute_value:"neighborhood_final_destination"+"_"+destination_file_name;
		}
		
		if(use_r5){
			// In order to build a neighborhood network between logistic provider
			gs_add_sender gs_host:"localhost" gs_port:2005 gs_sender_id:"neighborhood_logistic_provider";
			gs_add_graph_attribute gs_sender_id:"neighborhood_logistic_provider" gs_attribute_name:"name" gs_attribute_value:"neighborhood_logistic_provider"+"_"+destination_file_name;
		}
		
		if(use_r6){
			// In order to build a neighborhood network between warehouse and final destination
			gs_add_sender gs_host:"localhost" gs_port:2006 gs_sender_id:"neighborhood_warehouse_final";
			gs_add_graph_attribute gs_sender_id:"neighborhood_warehouse_final" gs_attribute_name:"name" gs_attribute_value:"neighborhood_warehouse_final"+"_"+destination_file_name;
		}
		
		if(use_r7){
			// In order to build a neighborhood network between logistic provider and final destination
			gs_add_sender gs_host:"localhost" gs_port:2007 gs_sender_id:"neighborhood_logistic_final";
			gs_add_graph_attribute gs_sender_id:"neighborhood_logistic_final" gs_attribute_name:"name" gs_attribute_value:"neighborhood_logistic_final"+"_"+destination_file_name;
		}
		
		if(use_r8){
			// In order to build the road network
			gs_add_sender gs_host:"localhost" gs_port:2008 gs_sender_id:"road_network";
			gs_add_graph_attribute gs_sender_id:"road_network" gs_attribute_name:"name" gs_attribute_value:"road_network"+"_"+destination_file_name;
		}
		
		if(use_r9){
			// In order to build the supply chain network
			gs_add_sender gs_host:"localhost" gs_port:2009 gs_sender_id:"supply_chain";
			gs_add_graph_attribute gs_sender_id:"supply_chain" gs_attribute_name:"name" gs_attribute_value:"supply_chain"+"_"+destination_file_name;
		}
	}
	
	action init_neighborhood_all {
		ask Warehouse {
			ask (Warehouse at_distance(neighborhood_dist)) {
				if(self != myself){
					gs_add_edge gs_sender_id:"neighborhood_all" gs_edge_id:(myself.name + self.name) gs_node_id_from:myself.name gs_node_id_to:self.name gs_is_directed:false;
				}		
			}
			ask (FinalDestinationManager at_distance(neighborhood_dist)) {
				if(self != myself){
					gs_add_edge gs_sender_id:"neighborhood_all" gs_edge_id:(myself.name + self.name) gs_node_id_from:myself.name gs_node_id_to:self.name gs_is_directed:false;
				}		
			}
			ask LogisticProvider at_distance(neighborhood_dist) {
				if(self != myself){
					gs_add_edge gs_sender_id:"neighborhood_all" gs_edge_id:(myself.name + self.name) gs_node_id_from:myself.name gs_node_id_to:self.name gs_is_directed:false;
				}		
			}
		}
		
		ask FinalDestinationManager {
			ask LogisticProvider at_distance(neighborhood_dist) {
				if(self != myself){
					gs_add_edge gs_sender_id:"neighborhood_all" gs_edge_id:(myself.name + self.name) gs_node_id_from:myself.name gs_node_id_to:self.name gs_is_directed:false;
				}		
			}
			
			ask (FinalDestinationManager at_distance(neighborhood_dist)) {
				if(self != myself){
					gs_add_edge gs_sender_id:"neighborhood_all" gs_edge_id:(myself.name + self.name) gs_node_id_from:myself.name gs_node_id_to:self.name gs_is_directed:false;
				}		
			}
		}
		
		ask LogisticProvider {
			ask LogisticProvider at_distance(neighborhood_dist) {
				if(self != myself){
					gs_add_edge gs_sender_id:"neighborhood_all" gs_edge_id:(myself.name + self.name) gs_node_id_from:myself.name gs_node_id_to:self.name gs_is_directed:false;
				}		
			}
		}
		// Send a step event to Graphstream to indicate that the graph has been built
		gs_step gs_sender_id:"neighborhood_all" gs_step_number:1;
	}
	
	action init_neighborhood_warehouse {
		ask Warehouse {
			ask (Warehouse at_distance(neighborhood_dist)) {
				if(self != myself){
					gs_add_edge gs_sender_id:"neighborhood_warehouse" gs_edge_id:(myself.name + self.name) gs_node_id_from:myself.name gs_node_id_to:self.name gs_is_directed:false;
				}		
			}
		}
		// Send a step event to Graphstream to indicate that the graph has been built
		gs_step gs_sender_id:"neighborhood_warehouse" gs_step_number:1;
	}
	
	action init_neighborhood_final_destination {
		ask FinalDestinationManager {
			ask FinalDestinationManager at_distance(neighborhood_dist) {
				if(self != myself){
					gs_add_edge gs_sender_id:"neighborhood_final_destination" gs_edge_id:(myself.name + self.name) gs_node_id_from:myself.name gs_node_id_to:self.name gs_is_directed:false;
				}		
			}
		}
		// Send a step event to Graphstream to indicate that the graph has been built
		gs_step gs_sender_id:"neighborhood_final_destination" gs_step_number:1;
	}
	
	action init_neighborhood_logistic_provider {
		ask LogisticProvider {
			ask LogisticProvider at_distance(neighborhood_dist) {
				if(self != myself){
					gs_add_edge gs_sender_id:"neighborhood_logistic_provider" gs_edge_id:(myself.name + self.name) gs_node_id_from:myself.name gs_node_id_to:self.name gs_is_directed:false;
				}		
			}
		}
		// Send a step event to Graphstream to indicate that the graph has been built
		gs_step gs_sender_id:"neighborhood_logistic_provider" gs_step_number:1;
	}
	
	action init_neighborhood_warehouse_final {
		ask Warehouse {
			ask (Warehouse at_distance(neighborhood_dist)) {
				if(self != myself){
					gs_add_edge gs_sender_id:"neighborhood_warehouse_final" gs_edge_id:(myself.name + self.name) gs_node_id_from:myself.name gs_node_id_to:self.name gs_is_directed:false;
				}
			}
			ask (FinalDestinationManager at_distance(neighborhood_dist)) {
				if(self != myself){
					gs_add_edge gs_sender_id:"neighborhood_warehouse_final" gs_edge_id:(myself.name + self.name) gs_node_id_from:myself.name gs_node_id_to:self.name gs_is_directed:false;
				}		
			}
		}
		ask FinalDestinationManager {
			ask (FinalDestinationManager at_distance(neighborhood_dist)) {
				if(self != myself){
					gs_add_edge gs_sender_id:"neighborhood_warehouse_final" gs_edge_id:(myself.name + self.name) gs_node_id_from:myself.name gs_node_id_to:self.name gs_is_directed:false;
				}		
			}
		}
		// Send a step event to Graphstream to indicate that the graph has been built
		gs_step gs_sender_id:"neighborhood_warehouse_final" gs_step_number:1;
	}
	
	action init_neighborhood_logistic_final {
		ask FinalDestinationManager {
			ask (FinalDestinationManager at_distance(neighborhood_dist)) {
				if(self != myself){
					gs_add_edge gs_sender_id:"neighborhood_logistic_final" gs_edge_id:(myself.name + self.name) gs_node_id_from:myself.name gs_node_id_to:self.name gs_is_directed:false;
				}
			}
			ask LogisticProvider at_distance(neighborhood_dist) {
				if(self != myself){
					gs_add_edge gs_sender_id:"neighborhood_logistic_final" gs_edge_id:(myself.name + self.name) gs_node_id_from:myself.name gs_node_id_to:self.name gs_is_directed:false;
				}
			}
		}
		ask LogisticProvider {
			ask LogisticProvider at_distance(neighborhood_dist) {
				if(self != myself){
					gs_add_edge gs_sender_id:"neighborhood_logistic_final" gs_edge_id:(myself.name + self.name) gs_node_id_from:myself.name gs_node_id_to:self.name gs_is_directed:false;
				}
			}
		}
		// Send a step event to Graphstream to indicate that the graph has been built
		gs_step gs_sender_id:"neighborhood_logistic_final" gs_step_number:1;
	}
	
	action init_use_road_network {
		ask road_network.edges {
			// Get the source node
			point p_source <- (road_network source_of self);
			// Make a list with coordinate in order to send it
			list l_source <- [];
			l_source <- l_source + p_source.x;
			l_source <- l_source + p_source.y;
			// Create the node
			gs_add_node gs_sender_id:"road_network" gs_node_id:""+p_source.x+"_"+p_source.y;
			// Send the coordinate
			gs_add_node_attribute gs_sender_id:"road_network" gs_node_id:""+p_source.x+"_"+p_source.y gs_attribute_name:"xy" gs_attribute_value:l_source;
			
			// Get the target node
			point p_target<- (road_network target_of self);
			// Make a list with coordinate in order to send it
			list l_target <- [];
			l_target <- l_target + p_target.x;
			l_target <- l_target + p_target.y;
			// Create the node
			gs_add_node gs_sender_id:"road_network" gs_node_id:""+p_target.x+"_"+p_target.y;
			// Send the coordinate
			gs_add_node_attribute gs_sender_id:"road_network" gs_node_id:""+p_target.x+"_"+p_target.y gs_attribute_name:"xy" gs_attribute_value:l_target;
			
			// Create an undirected edge between these two nodes
			gs_add_edge gs_sender_id:"road_network" gs_edge_id:(""+p_source.x+"_"+p_source.y+p_target.x+"_"+p_target.y) gs_node_id_from:""+p_source.x+"_"+p_source.y gs_node_id_to:""+p_target.x+"_"+p_target.y gs_is_directed:false;
		}
		
		// Send a step event to Graphstream to indicate that the graph has been built
		gs_step gs_sender_id:"road_network" gs_step_number:1;
	}
}