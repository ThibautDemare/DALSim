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
	float step <- 1 °mn;//one minute per step
	
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
	
	init {
		// Road network creation
		create Road from: roads_shapefile with: [speed::read("speed") as float];
		//map<Road,float> move_weights <- Road as_map (each::(each.speed*each.length));
		road_network <- as_edge_graph(Road);// with_weights move_weights;
		
		// Final destinations
		create FinalDestinationManager from: destination_shapefile with: [huffValue::read("huff") as float];
		
		// Warehouses
		create Warehouse from: warehouse_shapefile_small returns: ws with: [huffValue::read("huff") as float, surface::read("surface") as float];
		create Warehouse from: warehouse_shapefile_average returns: wa with: [huffValue::read("huff") as float, surface::read("surface") as float];
		create Warehouse from: warehouse_shapefile_large returns: wl with: [huffValue::read("huff") as float, surface::read("surface") as float];
		
		//  Logistic providers
		create LogisticProvider from: commissionaire_shapefile;
		
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