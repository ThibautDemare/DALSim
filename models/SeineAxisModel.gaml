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
	
	// Obeservation value
		// Average  values
	int totalNumberOfBatch <- 0;
	int numberOfBatchProviderToLarge <- 0;
	int numberOfBatchLargeToAverage <- 0;
	int numberOfBatchAverageToSmall <- 0;
	int numberOfBatchSmallToFinal <- 0;
	float stockOnRoads <- 0.0;
	float stockInFinalDest <- 0.0;
	float stockInWarehouse <- 0.0;
		// T1 values
	int totalNumberOfBatchT1 <- 0;
	int numberOfBatchProviderToLargeT1 <- 0;
	int numberOfBatchLargeToAverageT1 <- 0;
	int numberOfBatchAverageToSmallT1 <- 0;
	int numberOfBatchSmallToFinalT1 <- 0;
	float stockOnRoadsT1 <- 0.0;
	float stockInFinalDestT1 <- 0.0;
	float stockInWarehouseT1 <- 0.0;
		// T2 values
	int totalNumberOfBatchT2 <- 0;
	int numberOfBatchProviderToLargeT2 <- 0;
	int numberOfBatchLargeToAverageT2 <- 0;
	int numberOfBatchAverageToSmallT2 <- 0;
	int numberOfBatchSmallToFinalT2 <- 0;
	float stockOnRoadsT2 <- 0.0;
	float stockInFinalDestT2 <- 0.0;
	float stockInWarehouseT2 <- 0.0;
	
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
	 * 
	 */
	reflex updateObservationValue {
		// Keep old value in *T1
		totalNumberOfBatchT1 <- totalNumberOfBatchT2;
		numberOfBatchProviderToLargeT1 <- numberOfBatchProviderToLargeT2;
		numberOfBatchLargeToAverageT1 <- numberOfBatchLargeToAverageT2;
		numberOfBatchAverageToSmallT1 <- numberOfBatchAverageToSmallT2;
		numberOfBatchSmallToFinalT1 <- numberOfBatchSmallToFinalT2;
		stockOnRoadsT1 <- stockOnRoadsT2;
		stockInFinalDestT1 <- stockInFinalDestT2;
		stockInWarehouseT1 <- stockInWarehouseT2;
		
		// Compute current value in *T2
		totalNumberOfBatchT2 <- length(Batch);
		stockOnRoadsT2 <- 0.0;
		numberOfBatchProviderToLargeT2 <- 0;
		numberOfBatchLargeToAverageT2 <- 0;
		numberOfBatchAverageToSmallT2 <- 0;
		numberOfBatchSmallToFinalT2 <- 0;
		ask Batch {
			if(self.color = "blue"){
				numberOfBatchProviderToLargeT2 <- numberOfBatchProviderToLargeT2 + 1;
			}
			else if(self.color = "green"){
				numberOfBatchLargeToAverageT2 <- numberOfBatchLargeToAverageT2 + 1;
			}
			else if(self.color = "orange"){
				numberOfBatchAverageToSmallT2 <- numberOfBatchAverageToSmallT2 + 1;
			}
			else if(self.color = "red"){
				numberOfBatchSmallToFinalT2 <- numberOfBatchSmallToFinalT2 + 1;
			}
			
			stockOnRoadsT2 <- stockOnRoadsT2 + self.quantity;
		}
		stockInFinalDestT2 <- 0.0;
		ask FinalDestinationManager {
			ask self.building.stocks {
				stockInFinalDestT2 <- stockInFinalDestT2 + self.quantity;
			}
		}
		stockInWarehouseT2 <- 0.0;
		ask Warehouse {
			ask self.stocks {
				stockInWarehouseT2 <- stockInWarehouseT2 + self.quantity;
			}
		}
	}

	/**
	 * 
	 */
	reflex updateAverageObservationValue when: ((time/3600.0) mod 24.0) = 0.0  {
		// Update mean values
		totalNumberOfBatch <- (totalNumberOfBatchT2 + totalNumberOfBatchT1)/2;
		numberOfBatchProviderToLarge <- (numberOfBatchProviderToLargeT2 + numberOfBatchProviderToLargeT1)/2;
		numberOfBatchLargeToAverage <- (numberOfBatchLargeToAverageT2 + numberOfBatchLargeToAverageT1)/2;
		numberOfBatchAverageToSmall <- (numberOfBatchAverageToSmallT2 + numberOfBatchAverageToSmallT1)/2;
		numberOfBatchSmallToFinal <- (numberOfBatchSmallToFinalT2 + numberOfBatchSmallToFinalT1)/2;
		stockOnRoads <- (stockOnRoadsT2 + stockOnRoadsT1)/2.0;
		stockInFinalDest <- (stockInFinalDestT2 + stockInFinalDestT1)/2.0;
		stockInWarehouse <- (stockInWarehouseT2 + stockInWarehouseT1)/2.0;
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

experiment exp_graph type: gui {
	output {
	/*	display display_FinalDestinationManager {
			species Batch aspect: base;
			species Provider aspect: base;
			species FinalDestinationManager aspect: base;
			species Road aspect: geom; 			
		}
		
		display display_Warehouse {
			species Batch aspect: base;
			species Provider aspect: base;
			species Warehouse aspect: base;
			species Road aspect: geom; 
		}
	/*	
		display display_LogisticProvider {
			species Batch aspect: base;
			species Provider aspect: base;
			species LogisticProvider aspect: base;
			species Road aspect: geom; 
		}
		
		display batch_road {
			species Batch aspect: little_base;
			species Road aspect: geom; 
		}
	*/
	/*	display chart_average_number_of_batch refresh_every: 24 {
			chart  "Number of batch" type: series {
				data "Average total number of batch" value: totalNumberOfBatch color: rgb('purple') ;
				data "Average number of batch going from the provider to a large warehouse" value: numberOfBatchProviderToLarge color: rgb('blue') ;
				data "Average number of batch going from a large warehouse to an average one" value: numberOfBatchLargeToAverage color: rgb('green') ;
				data "Average number of batch going from an average warehouse to a small one" value: numberOfBatchAverageToSmall color: rgb('orange') ;
				data "Average number of batch going from a small warehouse to a final destination" value: numberOfBatchSmallToFinal color: rgb('red') ;
			}
		}
		
		display chart_number_of_batch {
			chart  "Number of batch" type: series {
				data "Number of batch" value: totalNumberOfBatchT2 color: rgb('purple') ;
				data "Number of batch going from the provider to a large warehouse" value: numberOfBatchProviderToLargeT2 color: rgb('blue') ;
				data "Number of batch going from a large warehouse to an average one" value: numberOfBatchLargeToAverageT2 color: rgb('green') ;
				data "Number of batch going from an average warehouse to a small one" value: numberOfBatchAverageToSmallT2 color: rgb('orange') ;
				data "Number of batch going from a small warehouse to a final destination" value: numberOfBatchSmallToFinalT2 color: rgb('red') ;
			}
		}
		
		display chart_average_stock_on_roads refresh_every: 24 {
			chart "Stock quantity on road" type: series {
				data "Average stock quantity on road" value: stockOnRoads color: rgb('red') ;
			}
		}
		
		display chart_stock_on_roads {
			chart "Stock quantity on road" type: series {
				data "Stock quantity on road" value: stockOnRoadsT2 color: rgb('red') ;
			}
		}
		
		display chart_average_stock_in_final_dest refresh_every: 24 {
			chart  "Stock quantity in final destinations" type: series {
				data "Average stock quantity in final destinations" value: stockInFinalDest color: rgb('green') ;
			}
		}
		
		display chart_stock_in_final_dest {
			chart  "Stock quantity in final destinations" type: series {
				data "Stock quantity in final destinations" value: stockInFinalDestT2 color: rgb('green') ;
			}
		}
		
		display chart_average_stock_in_warehouse refresh_every: 24 {
			chart  "Stock quantity in warehouses" type: series {
				data "Average stock quantity in warehouses" value: stockInWarehouse color: rgb('orange') ;
			}
		}
		
		display chart_stock_in_warehouse {
			chart  "Stock quantity in warehouses" type: series {
				data "Stock quantity in warehouses" value: stockInWarehouseT2 color: rgb('orange') ;
			}
		}
	*/	
		file name: "results" type: text data: ""+(time/3600.0) + "; " + stockInWarehouseT2 + ";" + stockInFinalDestT2 + ";" + stockOnRoadsT2 + ";" + numberOfBatchLargeToAverageT2 + ";" + numberOfBatchAverageToSmallT2 + ";" + numberOfBatchSmallToFinalT2 + ";" + numberOfBatchProviderToLargeT2 + ";" + totalNumberOfBatchT2;
		file name: "results_average" type: text data: ""+(time/3600.0) + "; " + stockInWarehouse + ";" + stockInFinalDest + ";" + stockOnRoads + ";" + numberOfBatchLargeToAverage + ";" + numberOfBatchAverageToSmall + ";" + numberOfBatchSmallToFinal + ";" + numberOfBatchProviderToLarge + ";" + totalNumberOfBatch;
		
	}
}