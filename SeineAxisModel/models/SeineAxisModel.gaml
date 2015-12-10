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
	
	//This data comes from "EuroRegionalMap" (EuroGeographics)
	file roads_shapefile <- file("../../../BD_SIG/Used/Roads/Roads_one_component/roads_v2.shp");
	graph road_network;
	
	// Logistic provider
	file logistic_provider_shapefile <- file("../../../BD_SIG/Used/LogisticProvider/LogisticProvider.shp");
	
	// Warehouses classified by their size
	file warehouse_shapefile <- file("../../../BD_SIG/Used/Warehouses/warehouses_attractiveness_0.shp");
	
	// Final destination (for instance : shop)
	string destination_path <- "../../../BD_SIG/Used/FinalDestination/";
	string destination_file_name <- "FinalDestinationManager";
	//string destination_file_name <- "FinalDestinationManager_subset_Paris_1";
	//string destination_file_name <- "FinalDestinationManager_subset_Paris_20";
	//string destination_file_name <- "FinalDestinationManager_subset_Paris_190";
	//string destination_file_name <- "FinalDestinationManager_subset_scattered_24";
	//string destination_file_name <- "FinalDestinationManager_subset_scattered_592";
	file destination_shapefile <- file(destination_path+destination_file_name+".shp");
	
	// A unique provider
	file provider_shapefile <- file("../../../BD_SIG/Used/Provider/Provider.shp");
	
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
		create Warehouse from: warehouse_shapefile returns: lw with: [probaAnt::read("probaAnt") as float, totalSurface::read("surface") as float];
		ask Warehouse {
			surfaceUsedForLH <- totalSurface*(1-probaAnt);
		}
		
		//  Logistic providers
		create LogisticProvider from: logistic_provider_shapefile;
		
		// Final destinations
		create FinalDestinationManager from: destination_shapefile with: [huffValue::read("huff") as float, surface::read("surface") as float, color::read("color") as string];
		/*
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

		// This part remove every useless agent among LPs and warehouses
		int i <- 0;
		list<LogisticProvider> llp <- LogisticProvider;
		loop while: i < length(llp) {
			if(length(llp[i].customers) = 0){
				LogisticProvider lp <- llp[i];
				remove index: i from: llp;
				ask lp {
					do die;
				}
			}
			else {
				i <- i + 1;
			}
		}

		i <- 0;
		list<Warehouse> lw <- Warehouse;
		loop while: i < length(lw) {
			if(length(lw[i].stocks) = 0){
				Warehouse w <- lw[i];
				remove index: i from: lw;
				ask w {
					do die;
				}
			}
			else {
				i <- i + 1;
			}
		}
	}
}

grid cell_surface width:50 height:50  {
	rgb color <- rgb(255,255,255);
	float surface;
	float maxSurface;

	reflex coloration {
		surface <- 0;
		maxSurface <- 0;
		list<Building> buildings <- (Warehouse inside self) + (Building inside self);

		loop b over: buildings {
			ask (b as Building).stocks {
				myself.maxSurface <- myself.maxSurface + self.maxQuantity;
				myself.surface <- myself.surface + self.quantity;
			}
		}

		if(maxSurface = 0){
			color <- rgb(255, 255, 255);
		}
		else{
			float ratio <- surface/maxSurface;
			if(ratio < 0.25){
				color <- rgb(237,248,251);
			}
			else if(ratio < 0.5){
				color <- rgb(178,226,226);
			}
			else if(ratio < 0.75){
				color <- rgb(102,194,164);
			}
			else{
				color <- rgb(35,139,69);
			}
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

grid cell_saturation width:50 height:50  {
	rgb color <- rgb(255,255,255);
	float surface;
	float maxSurface;

	reflex coloration {
		surface <- 0;
		maxSurface <- 0;
		list<Building> buildings <- (Warehouse inside self) + (Building inside self);

		loop b over: buildings {
			maxSurface <- maxSurface + b.surfaceUsedForLH;
			ask (b as Building).stocks {
				myself.surface <- myself.surface + self.quantity;
			}
		}

		if(maxSurface = 0){
			color <- rgb(255, 255, 255);
		}
		else{
			float ratio <- surface/maxSurface;
			if(ratio < 0.25){
				color <- rgb(237,248,251);
			}
			else if(ratio < 0.5){
				color <- rgb(178,226,226);
			}
			else if(ratio < 0.75){
				color <- rgb(102,194,164);
			}
			else{
				color <- rgb(35,139,69);
			}
		}
	}
}