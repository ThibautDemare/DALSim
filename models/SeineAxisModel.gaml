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
import "./Observer.gaml"
import "./Experiments.gaml"

/*
 * Init global variables and agents
 */
global {
	float step <- 60 °mn;//60 minutes per step
	
	//This data comes from "EuroRegionalMap" (EuroGeographics)
	file roads_shapefile <- file("../../../BD_SIG/Routes/From_Europe/roads_speed_length.shp");
	graph road_network;
	
	// Logistic provider
	file commissionaire_shapefile <- file("../../../BD_SIG/commissionnaire_transport/LogisticProvider.shp");
	
	// Warehouses classified by their size
	file warehouse_shapefile_small <- file("../../../BD_SIG/Warehouses/HuffColor/warehouses_small.shp");
	file warehouse_shapefile_average <- file("../../../BD_SIG/Warehouses/HuffColor/warehouses_average.shp");
	file warehouse_shapefile_large <- file("../../../BD_SIG/Warehouses/HuffColor/warehouses_large.shp");
	
	// Final destination (for instance : shop)
	file destination_shapefile <- file("../../../BD_SIG/FinalDestination/FinalDestinationManager.shp");
	
	// A unique provider
	file provider_shapefile <- file("../../../BD_SIG/Provider/Provider.shp");
	
	//Define the border of the environnement according to the road network
	geometry shape <- envelope(roads_shapefile);
	
	bool use_gs <- false;
	bool use_r1 <- false;//actor
	bool use_r2 <- false;//init_neighborhood_all
	bool use_r3 <- false;//init_neighborhood_warehouse
	bool use_r4 <- false;//init_neighborhood_final_destination
	bool use_r5 <- false;//init_neighborhood_logistic_provider
	bool use_r6 <- false;//init_neighborhood_warehouse_final
	bool use_r7 <- false;//init_neighborhood_logistic_final
	bool use_r8 <- false;//init_use_road_network
	bool use_r9 <- true;//init_use_supply_chain
	
	float neighborhood_dist <- 1°km;
	
	// The only one provider
	Provider provider;
	
	list<Warehouse> small_warehouse;
	list<Warehouse> average_warehouse;
	list<Warehouse> large_warehouse;
	
	init {
		if(use_gs){
			// Init senders in order to create nodes/edges when we create agent
			do init_senders;
		}
		
		// Road network creation
		create Road from: roads_shapefile with: [speed::read("speed") as float];
		//map<Road,float> move_weights <- Road as_map (each::(each.speed*each.length));
		road_network <- as_edge_graph(Road);// with_weights move_weights;
		
		if(use_gs){
			if(use_r8){
				// Send the road network to Graphstream
				do init_use_road_network;
			}
		}
		
		
		// Creation of a SuperProvider
		create Provider from: provider_shapefile returns:p;
		ask p {
			provider <- self;
		}
		
		// Warehouses
		create Warehouse from: warehouse_shapefile_small returns: sw with: [huffValue::read("huff") as float, totalSurface::read("surface") as float, color::read("color") as string];
		create Warehouse from: warehouse_shapefile_average returns: aw with: [huffValue::read("huff") as float, totalSurface::read("surface") as float, color::read("color") as string];
		create Warehouse from: warehouse_shapefile_large returns: lw with: [huffValue::read("huff") as float, totalSurface::read("surface") as float, color::read("color") as string];
		small_warehouse <- sw;
		average_warehouse <- aw;
		large_warehouse <- lw;
		
		//  Logistic providers
		create LogisticProvider from: commissionaire_shapefile;
		
		// Final destinations
		create FinalDestinationManager from: destination_shapefile with: [huffValue::read("huff") as float, surface::read("surface") as float, color::read("color") as string];
		
		// Init the decreasing rate of consumption
		do init_decreasingRateOfStocks;
		
	}
	
	/**
	 * Call inits methods to build graph with graphstream. They can't be called in global init so it is made in a reflex at the first cycle.
	 */
	reflex init_edges when: cycle = 1 {
		if(use_gs){
			do init_neighborhood_networks;
		}
	}
	
	/**
	 * The final destinations are separated in 4 ordered sets. To each final destinations of these sets, we associate a decreasing rate of 
	 * stocks according to the number of customer computed by the Huff model. The more the customers there are, the more the decreasing 
	 * rate allows a large consumption.
	 */
	action init_decreasingRateOfStocks {
		list<FinalDestinationManager> dests <- FinalDestinationManager sort_by each.huffValue;
		int i <- 0;
		int ld <- length(dests);
		loop while: i < ld {
			FinalDestinationManager fdm <- dests[i];
			if(i<length(dests)/4){
				fdm.decreasingRateOfStocks <- 9;
			}
			else if(i<length(dests)*2/4){
				fdm.decreasingRateOfStocks <- 7;
			}
			else if(i<length(dests)*3/4){
				fdm.decreasingRateOfStocks <- 5;
			}
			else {
				fdm.decreasingRateOfStocks <- 3;
			}
			i <- i + 1;
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
		
		if(use_r8){
			// In order to build the road network
			gs_add_sender gs_host:"localhost" gs_port:2008 gs_sender_id:"road_network";
		}
		
		if(use_r9){
			// In order to build the supply chain network
			gs_add_sender gs_host:"localhost" gs_port:2009 gs_sender_id:"supply_chain";
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

