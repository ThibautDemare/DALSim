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
}

