/**
 *  SeineAxisModel
 *  Author: Thibaut Démare
 *  Description: 
 */
model SeineAxisModel

import "./Road.gaml"
import "./Warehouse.gaml"
import "./LogisticProvider.gaml"
import "./Provider.gaml"
import "./FinalDestinationManager.gaml"
import "./Batch.gaml"
import "./Building.gaml"
import "./Role.gaml"

/*
 * Init global variables and agents
 */
global {
	float step <- 60 °mn;//60 minutes per step
	
	//This data comes from "EuroRegionalMap" (EuroGeographics)
	file roads_shapefile <- file("../../../BD_SIG/Routes/From_Europe/roads_speed_length.shp");
	graph road_network;
	
	// Logistic provider
	file commissionaire_shapefile <- file("../../../BD_SIG/commissionnaire_transport/commissionnaire_de_transport.shp");
	
	// Warehouses classified by their size
	file warehouse_shapefile_small <- file("../../../BD_SIG/Warehouses/Huff/warehouses_small.shp");
	file warehouse_shapefile_average <- file("../../../BD_SIG/Warehouses/Huff/warehouses_average.shp");
	file warehouse_shapefile_large <- file("../../../BD_SIG/Warehouses/Huff/warehouses_large.shp");
	
	// Final destination (for instance : shop)
	file destination_shapefile <- file("../../../BD_SIG/FinalDestination/final_dest.shp");
	
	// A unique provider
	file provider_shapefile <- file("../../../BD_SIG/Provider/Provider.shp");
	
	//Define the border of the environnement according to the road network
	geometry shape <- envelope(roads_shapefile);
	
	// A non realistic list of product and their quantity
	map<int, float> products <- [1::1000, 2::10000, 3::40000, 5::30000, 6::15000, 7::20000, 8::50000, 9::40000, 10::25000, 11::60000, 12::55000, 13::32000, 14::80000, 15::70000, 16::90000, 17::85000, 18::95000, 19::50000];
	
	bool use_gs <- false;
	bool use_r1 <- true;//actor
	bool use_r2 <- false;//init_neighborhood_all
	bool use_r3 <- false;//init_neighborhood_warehouse
	bool use_r4 <- false;//init_neighborhood_final_destination
	bool use_r5 <- false;//init_neighborhood_logistic_provider
	bool use_r6 <- false;//init_neighborhood_warehouse_final
	bool use_r7 <- false;//init_neighborhood_logistic_final
	
	float neighborhood_dist <- 5°km;
	
	init {
		if(use_gs){
			// Init senders in order to create nodes/edges when we create agent
			do init_senders;
		}
		
		// Road network creation
		create Road from: roads_shapefile with: [speed::read("speed") as float];
		//map<Road,float> move_weights <- Road as_map (each::(each.speed*each.length));
		road_network <- as_edge_graph(Road);// with_weights move_weights;
		
		// Warehouses
		create Warehouse from: warehouse_shapefile_small returns: ws with: [huffValue::read("huff") as float, surface::read("surface") as float];
		create Warehouse from: warehouse_shapefile_average returns: wa with: [huffValue::read("huff") as float, surface::read("surface") as float];
		create Warehouse from: warehouse_shapefile_large returns: wl with: [huffValue::read("huff") as float, surface::read("surface") as float];
		
		//  Logistic providers
		create LogisticProvider from: commissionaire_shapefile;
		
		// Final destinations
		create FinalDestinationManager from: destination_shapefile with: [huffValue::read("huff") as float];
		
		// Add warehouse to logistic provider
			// Small warehouse case
		ws <- ws sort_by each.huffValue;
		loop while: not empty(ws) {
			ask LogisticProvider {
				if((length(ws)) > 0){
					self.warehouses_small <- self.warehouses_small + last(ws);
					last(ws).logisticProvider <- self;
					remove index: (length(ws)-1) from: ws;
				}
			}
		}
		
			// Average warehouse case
		wa <- wa sort_by each.huffValue;
		loop while: not empty(wa) {
			ask LogisticProvider {
				if((length(wa)) > 0){
					self.warehouses_average <- self.warehouses_average + last(wa);
					last(wa).logisticProvider <- self;
					remove index: (length(wa)-1) from: wa;
					
				}
			}
		}
		
			// Large warehouse case
		wl <- wl sort_by each.huffValue;
		loop while: not empty(wl) {
			ask LogisticProvider {
				if((length(wl)) > 0){
					self.warehouses_large <- self.warehouses_large + last(wl);
					last(wl).logisticProvider <- self;
					remove index: (length(wl)-1) from: wl;
				}
			}
		}
		
		// Creation of a SuperProvider
		create Provider from: provider_shapefile;
		
	}
	
	reflex init_edges when: cycle = 1 {
		if(use_gs){
			do init_neighborhood_networks;
		}
	}
	
	action init_senders {
		gs_clear_senders;
		
		if(use_r1){
			// In order to build a network of interaction between final destination manager and logistic manager
			gs_add_sender gs_host:"localhost" gs_port:2001 gs_sender_id:"actor";
		}
		
		if(use_r2){
			// In order to build a neighborhood network between all agent
			gs_add_sender gs_host:"localhost" gs_port:2002 gs_sender_id:"neighborhood_all";
		}
		
		if(use_r3){
			// In order to build a neighborhood network between warehouse
			gs_add_sender gs_host:"localhost" gs_port:2003 gs_sender_id:"neighborhood_warehouse";
		}
		
		if(use_r4){
			// In order to build a neighborhood network between final destination
			gs_add_sender gs_host:"localhost" gs_port:2004 gs_sender_id:"neighborhood_final_destination";
		}
		
		if(use_r5){
			// In order to build a neighborhood network between logistic provider
			gs_add_sender gs_host:"localhost" gs_port:2005 gs_sender_id:"neighborhood_logistic_provider";
		}
		
		if(use_r6){
			// In order to build a neighborhood network between warehouse and final destination
			gs_add_sender gs_host:"localhost" gs_port:2006 gs_sender_id:"neighborhood_warehouse_final";
		}
		
		if(use_r7){
			// In order to build a neighborhood network between logistic provider and final destination
			gs_add_sender gs_host:"localhost" gs_port:2007 gs_sender_id:"neighborhood_logistic_final";
		}
	}
	
	action init_neighborhood_networks{
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
	}
	
	action init_neighborhood_all {
		ask Warehouse {
			ask (Warehouse at_distance(neighborhood_dist)) {
				gs_add_edge gs_sender_id:"neighborhood_all" gs_edge_id:(myself.name + self.name) gs_node_id_from:myself.name gs_node_id_to:self.name gs_is_directed:false;
			}
			ask (FinalDestinationManager at_distance(neighborhood_dist)) {
				gs_add_edge gs_sender_id:"neighborhood_all" gs_edge_id:(myself.name + self.name) gs_node_id_from:myself.name gs_node_id_to:self.name gs_is_directed:false;
			}
			ask LogisticProvider at_distance(neighborhood_dist) {
				gs_add_edge gs_sender_id:"neighborhood_all" gs_edge_id:(myself.name + self.name) gs_node_id_from:myself.name gs_node_id_to:self.name gs_is_directed:false;
			}
		}
		
		ask FinalDestinationManager {
			ask LogisticProvider at_distance(neighborhood_dist) {
				gs_add_edge gs_sender_id:"neighborhood_all" gs_edge_id:(myself.name + self.name) gs_node_id_from:myself.name gs_node_id_to:self.name gs_is_directed:false;
			}
		}
	}
	
	action init_neighborhood_warehouse {
		ask Warehouse {
			ask (Warehouse at_distance(neighborhood_dist)) {
				gs_add_edge gs_sender_id:"neighborhood_warehouse" gs_edge_id:(myself.name + self.name) gs_node_id_from:myself.name gs_node_id_to:self.name gs_is_directed:false;
			}
		}
	}
	
	action init_neighborhood_final_destination {
		ask FinalDestinationManager {
			ask FinalDestinationManager at_distance(neighborhood_dist) {
				gs_add_edge gs_sender_id:"neighborhood_final_destination" gs_edge_id:(myself.name + self.name) gs_node_id_from:myself.name gs_node_id_to:self.name gs_is_directed:false;
			}
		}
	}
	
	action init_neighborhood_logistic_provider {
		ask LogisticProvider {
			ask LogisticProvider at_distance(neighborhood_dist) {
				gs_add_edge gs_sender_id:"neighborhood_logistic_provider" gs_edge_id:(myself.name + self.name) gs_node_id_from:myself.name gs_node_id_to:self.name gs_is_directed:false;
			}
		}
	}
	
	action init_neighborhood_warehouse_final {
		ask Warehouse {
			ask (Warehouse at_distance(neighborhood_dist)) {
				gs_add_edge gs_sender_id:"neighborhood_warehouse_final" gs_edge_id:(myself.name + self.name) gs_node_id_from:myself.name gs_node_id_to:self.name gs_is_directed:false;
			}
			ask (FinalDestinationManager at_distance(neighborhood_dist)) {
				gs_add_edge gs_sender_id:"neighborhood_warehouse_final" gs_edge_id:(myself.name + self.name) gs_node_id_from:myself.name gs_node_id_to:self.name gs_is_directed:false;
			}
		}
	}
	
	action init_neighborhood_logistic_final {
		ask FinalDestinationManager {
			ask (FinalDestinationManager at_distance(neighborhood_dist)) {
				gs_add_edge gs_sender_id:"neighborhood_logistic_final" gs_edge_id:(myself.name + self.name) gs_node_id_from:myself.name gs_node_id_to:self.name gs_is_directed:false;
			}
			ask LogisticProvider at_distance(neighborhood_dist) {
				gs_add_edge gs_sender_id:"neighborhood_logistic_final" gs_edge_id:(myself.name + self.name) gs_node_id_from:myself.name gs_node_id_to:self.name gs_is_directed:false;
			}
		}
	}
}

experiment exp_graph type: gui {
	output {
		display display_FinalDestinationManager {
			species Batch aspect: base;
			species Provider aspect: base;
			species FinalDestinationManager aspect: base;
			species Road aspect: geom; 			
		}
		
		display display_LogisticProvider {
			species Batch aspect: base;
			species Provider aspect: base;
			species LogisticProvider aspect: base;
			species Road aspect: geom; 
		}
		
		display display_Warehouse {
			species Batch aspect: base;
			species Provider aspect: base;
			species Warehouse aspect: base;
			species Road aspect: geom; 
		}
		
		display batch_road {
			species Batch aspect: little_base;
			species Road aspect: geom; 
		}
	}
}