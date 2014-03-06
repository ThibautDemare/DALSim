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
import "./GraphStreamConnection.gaml"
import "./Parameters.gaml"

/*
 * Init global variables and agents
 */
global {
	//This data comes from "EuroRegionalMap" (EuroGeographics)
	file roads_shapefile <- file("../../../BD_SIG/Routes/From_Europe/roads_speed_length.shp");
	graph road_network;
	
	// Logistic provider
	file logistic_provider_shapefile <- file("../../../BD_SIG/LogisticProvider/LogisticProvider.shp");
	
	// Warehouses classified by their size
	file warehouse_shapefile_small <- file("../../../BD_SIG/Warehouses/HuffColor/warehouses_small.shp");
	file warehouse_shapefile_average <- file("../../../BD_SIG/Warehouses/HuffColor/warehouses_average.shp");
	file warehouse_shapefile_large <- file("../../../BD_SIG/Warehouses/HuffColor/warehouses_large.shp");
	
	list<Warehouse> small_warehouse;
	list<Warehouse> average_warehouse;
	list<Warehouse> large_warehouse;
	
	// Final destination (for instance : shop)
	file destination_shapefile <- file("../../../BD_SIG/FinalDestination/FinalDestinationManager.shp");
	
	// A unique provider
	file provider_shapefile <- file("../../../BD_SIG/Provider/Provider.shp");
	
	// The only one provider
	Provider provider;
	
	//Define the border of the environnement according to the road network
	geometry shape <- envelope(roads_shapefile);
	
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
		create LogisticProvider from: logistic_provider_shapefile;
		
		// Final destinations
		create FinalDestinationManager from: destination_shapefile with: [huffValue::read("huff") as float, surface::read("surface") as float, color::read("color") as string];
		
		// Init the decreasing rate of consumption
		do init_decreasingRateOfStocks;
		
	}
}

