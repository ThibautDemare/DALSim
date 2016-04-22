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
import "./Stock.gaml"
import "./Building.gaml"
import "./Observer.gaml"
import "./Experiments.gaml"
import "./GraphStreamConnection.gaml"
import "./Parameters.gaml"

/*
 * Init global variables and agents
 */
global schedules: [world] + 
				shuffle(FinalDestinationManager) + 
				shuffle(LogisticProvider)+
				shuffle(Provider) + 
				shuffle(Building) +
				shuffle(Warehouse) +
				Batch + 
				Stock {

	//This data comes from "EuroGlobalMap" (EuroGeographics)
	// Each road has an attribute giving the speed in km/h
	//file roads_shapefile <- file("../../../BD_SIG/Used/Roads/Roads_one_component/roads_v2.shp");
	file roads_shapefile <- file("../../../BD_SIG/Used/Roads/roads_two_provider/roads_speed_length_km.shp");
	graph road_network;

	// Logistic provider
	// The list of logistics service provider. The data comes from the list of "commissionaire de transport" build by Devport
	file logistic_provider_shapefile <- file("../../../BD_SIG/Used/LogisticProvider/LogisticProvider.shp");

	// Warehouses classified by their size
	// The list of warehouses with their storage surface
	file warehouse_shapefile <- file("../../../BD_SIG/Used/Warehouses/warehouses_attractiveness_0.shp");

	// Final destination (for instance : shop)
	// The list of wholesaler on the Seine axis territory. They have an attribute giving the number of customers according to the Huff model.
	// The surface is in m^2. In the shapefile used, it is an estimation.
	string destination_path <- "../../../BD_SIG/Used/FinalDestination/";
	string destination_file_name <- "FinalDestinationManager";
	//string destination_file_name <- "FinalDestinationManager_subset_Paris_1";
	//string destination_file_name <- "FinalDestinationManager_subset_Paris_20";
	//string destination_file_name <- "FinalDestinationManager_subset_Paris_190";
	//string destination_file_name <- "FinalDestinationManager_subset_scattered_24";
	//string destination_file_name <- "FinalDestinationManager_subset_scattered_592";
	file destination_shapefile <- file(destination_path+destination_file_name+".shp");

	// The list of providers. They represent where the goods come in the territory.
	// In this simulation there are only two providers: one for the port of Le Havre, and one for the port of Antwerp
	file provider_shapefile <- file("../../../BD_SIG/Used/Provider/Provider.shp");

	//Define the border of the environnement according to the road network
	geometry shape <- envelope(roads_shapefile);

	init {
		if(use_gs){
			// Init senders in order to create nodes/edges when we create agent
			do init_senders;
		}

		// Road network creation
		create Road from: roads_shapefile with: [speed::read("speed") as float];
		road_network <- as_edge_graph(Road);

		if(use_gs){
			if(use_r8){
				// Send the road network to Graphstream
				do init_use_road_network;
			}
		}

		// Creation of a SuperProvider
		create Provider from: provider_shapefile with: [port::read("Port") as string];

		// Warehouses
		create Warehouse from: warehouse_shapefile returns: lw with: [totalSurface::read("surface") as float];

		//  Logistic providers
		create LogisticProvider from: logistic_provider_shapefile;

		// Final destinations
		create FinalDestinationManager from: destination_shapefile with: [huffValue::read("huff") as float, surface::read("surface") as float];
		/* 
		 * The following code can be commented or not, depending if the user want to execute the simulation with every FDM 
		 * It is mainly used for tests to avoid CPU overload.
		 */
		int i <- 500;
		list<FinalDestinationManager> lfdm <- shuffle(FinalDestinationManager);
		loop while: i < length(lfdm) {
			FinalDestinationManager s <- lfdm[i];
			remove index: i from: lfdm;
			ask s {
				do die;
			}
		}
		/**/
		
		// Init the decreasing rate of consumption
		do init_decreasingRateOfStocks;
		do init_cost;

		// I create one batch who will do nothing, because, if there is no batch at all, it slows down the simulation... Weird...
		create Batch number:1;
	}
	
	/*
	 * A part of the initialization of the final destinations managers must be made here.
	 * Indeed, we must schedule the FDM according to their surface (larger before). But the scheduling can't be made in the classic init.
	 */
	reflex second_init when: time = 0 {
		ask FinalDestinationManager sort_by (-1*each.surface){
			do second_init;
		}
	}
}

grid cell_stock_shortage width:50 height:50  {
	rgb color <- rgb(rgb(255,255,255),0.0);
	float nb_stock_shortage;
	float nb_stock;
	list<float> ratios <- [];

	reflex coloration {
		nb_stock_shortage <- 0;
		nb_stock <- 0;
		list<Building> buildings <- (Building inside self);// + (Warehouse inside self);

		loop b over: buildings {
			ask (b as Building).stocks {
				myself.nb_stock <- myself.nb_stock + 1;
				if(self.quantity = 0){
					myself.nb_stock_shortage <- myself.nb_stock_shortage + 1;
				}
			}
		}

		float ratio <- 0;
		if(nb_stock = 0 or nb_stock_shortage = 0){
			ratios <- ratios + 0;
		}
		else{
			ratio <- nb_stock_shortage/nb_stock;
			ratios <- ratios + ratio;
			if(length(ratios) > 72) { // 168 = 7 days
				remove index: 0 from: ratios;
			}
		}

		int i <- 0;
		float sum <- 0.0;
		loop while: i < length(ratios) {
			sum <- sum + ratios[i];
			i <- i + 1;
		}
		ratio <- sum / length(ratios);

		if(ratio = 0){
			color <- rgb(rgb(255,255,255),0.1);
		}
		else if(ratio < 0.025){
			color <- rgb(rgb(102,194,164),0.5);
		}
		else if(ratio < 0.07){
			color <- rgb(rgb(65,174,118),0.8);
		}
		else if(ratio < 0.15){
			color <- rgb(rgb(35,139,69),0.8);
		}
		else{
			color <- rgb(rgb(0,88,36),0.8);
		}
	}
}