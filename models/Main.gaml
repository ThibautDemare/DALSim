model Main

import "GraphStreamConnection.gaml"
import "Terminals.gaml"
import "Transporters.gaml"
import "ForwardingAgent.gaml"
import "Vehicle.gaml"
import "Perturbator.gaml"
import "Experiments.gaml"
/*
import "AwaitingStock.gaml"
import "LogisticsServiceProvider.gaml"
import "Building.gaml"
import "Commodity.gaml"
import "FinalDestinationManager.gaml"

import "Networks.gaml"
import "Observer.gaml"
import "Order.gaml"
import "Parameters.gaml"
import "Provider.gaml"
import "Stock.gaml"
import "Strategies.gaml"
import "SupplyChain.gaml"
import "Terminals.gaml"
import "TransferredStocks.gaml"
import "Transporters.gaml"
import "Warehouse.gaml"
*/

/*
 * Init global variables and agents
 */
global {

	string pathBD <- "../../../BD_SIG/Used/";

	// The road network
	//This data comes from "EuroGlobalMap" (EuroGeographics)
	// Each road has an attribute giving the speed in km/h
	file roads_shapefile <- file(pathBD+"Roads/Road_Network_LH-A/Road_Network_LH-A_lambert93_filtered_attributes.shp");

	// The maritime network
	file maritime_shapefile <- file(pathBD+"Maritime/maritime_lambert93_filtered_attributes.shp");

	// The river  network
	file river_shapefile <- file(pathBD+"River/river_network_length_in_km.shp");

	// Logistic provider
	// The list of logistics service provider. The data comes from the list of "commissionaire de transport" build by Devport
	file logistic_provider_shapefile <- file(pathBD+"LogisticProvider/LogisticProvider.shp");

	// Warehouses classified by their size
	// The list of warehouses with their storage surface
	file warehouse_shapefile <- file(pathBD+"Warehouses/warehouses_attractiveness_0.shp");

	// Final destination (for instance : shop)
	// The list of wholesaler on the Seine axis territory. They have an attribute giving the number of customers according to the Huff model.
	// The surface is in m^2. In the shapefile used, it is an estimation.
	string destination_path <- pathBD+"FinalDestination/";
	string destination_file_name <- "FinalDestinationManager";
	//string destination_file_name <- "FinalDestinationManager_subset_Paris_1";
	//string destination_file_name <- "FinalDestinationManager_subset_Paris_20";
	//string destination_file_name <- "FinalDestinationManager_subset_Paris_190";
	//string destination_file_name <- "FinalDestinationManager_subset_scattered_24";
	//string destination_file_name <- "FinalDestinationManager_subset_scattered_592";
	file destination_shapefile <- file(destination_path+destination_file_name+".shp");

	// The list of providers. They represent where the goods come in the territory.
	// In this simulation there are only two providers: one for the port of Le Havre, and one for the port of Antwerp
	file provider_shapefile <- file(pathBD+"Provider/Provider.shp");

	// The maritime terminals near LH and Antwerp
	file terminal_LH_shapefile <- file(pathBD+"Terminals/maritime_terminals_LH.shp");
	file terminal_A_shapefile <- file(pathBD+"Terminals/maritime_terminals_A_lambert93.shp");
	file river_terminals <- file(pathBD+"Terminals/river_terminals.shp");
	
	//Define the border of the environnement according to the road network
	geometry shape <- envelope(roads_shapefile);

	ForwardingAgent forwardingAgent;

	bool second_init_bool <- true;
	
	init {
		if(use_gs){
			// Init senders in order to create nodes/edges when we create agent
			do init_senders;
		}

		// Road network creation
		create Road from: roads_shapefile with: [speed::read("speed") as float, length::read("length") as float];
		road_network <- as_edge_graph(Road);
		
		// Maritime  network creation
		create MaritimeLine from: maritime_shapefile with: [speed::read("speed") as float, length::read("length") as float];
		maritime_network <- as_edge_graph(MaritimeLine);
		
		// Maritime  network creation
		create RiverLine from: river_shapefile with: [speed::read("speed") as float, length::read("length") as float];
		river_network <- as_edge_graph(RiverLine);
		
		// Creation of Providers
		create Provider from: provider_shapefile with: [port::read("Port") as string];
		
		// Warehouses
		create Warehouse from: warehouse_shapefile returns: lw with: [totalSurface::read("surface") as float];
		
		create RoadTransporter number:1;
		create RiverTransporter number:1;
		create MaritimeTransporter number:1;
		
		// Maritime Terminals
		create MaritimeRiverTerminal from: terminal_LH_shapefile with: [handling_time_to_road::read("TO_ROAD") as float,
			handling_time_to_river::read("TO_RIVER") as float,
			handling_time_to_maritime::read("TO_MARITIM") as float,
			handling_time_from_road::read("FROM_ROAD") as float,
			handling_time_from_river::read("FROM_RIVER") as float,
			handling_time_from_maritime::read("FROM_MARIT") as float
		];
		create RiverTerminal from: river_terminals with: [handling_time_to_road::read("TO_ROAD") as float,
			handling_time_to_river::read("TO_RIVER") as float,
			handling_time_from_road::read("FROM_ROAD") as float,
			handling_time_from_river::read("FROM_RIVER") as float
		];
		create MaritimeTerminal from: terminal_A_shapefile with: [handling_time_to_road::read("TO_ROAD") as float,
			handling_time_to_maritime::read("TO_MARITIM") as float,
			handling_time_from_road::read("FROM_ROAD") as float,
			handling_time_from_maritime::read("FROM_MARIT") as float
		];
		// Forwarding agent
		create ForwardingAgent number:1 returns:fas;
		forwardingAgent <- fas[0];

		// Create a vehicle to init_networks
		create Vehicle number:1;

		// Warehouses
		create Warehouse from: warehouse_shapefile returns: lw with: [totalSurface::read("surface") as float];

		//  Logistic providers
		create LogisticsServiceProvider from: logistic_provider_shapefile;

		/*
		 * The following code can be commented or not, depending if the user want to execute the simulation with every LSP 
		 * It is mainly used for tests to avoid CPU overload.
		 */
		/*int i <- 100;
		list<LogisticProvider> llsp <- shuffle(LogisticProvider);
		loop while: i < length(llsp) {
			LogisticProvider s <- llsp[i];
			remove index: i from: llsp;
			ask s {
				do die;
			}
		}
		/**/


		// Final destinations
		create FinalDestinationManager from: destination_shapefile with: [huffValue::float(read("huff")), surface::float(read("surface"))];
		/* 
		 * The following code can be commented or not, depending if the user want to execute the simulation with every FDM 
		 * It is mainly used for tests to avoid CPU overload.
		 */
		int i <- 100;
		list<FinalDestinationManager> lfdm <- shuffle(FinalDestinationManager);
		loop while: i < length(lfdm) {
			FinalDestinationManager s <- lfdm[i];
			remove index: i from: lfdm;
			ask s {
				do die;
			}
		}
		/**/

		// Init other parameters
		do init_decreasingRateOfStocks;
		do init_cost;
		do init_threshold;

	
	}
	
	/*
	 * A part of the initialization of the final destinations managers must be made here.
	 * Indeed, we must schedule the FDM according to their surface (larger before). But the scheduling can't be made in the classic init.
	 */
	reflex second_init when: second_init_bool {
		second_init_bool <- false;

		list<Building> buildingOfFDM <- [];
		ask FinalDestinationManager sort_by (-1*each.surface){
			do second_init;
			buildingOfFDM <+ self.building;
		}

		ask Vehicle[0] {
			do init_networks;
		}

		Provider LHP <- nil;
		Provider AntP <- nil;
		ask Provider {
			if(self.port = "LE HAVRE"){
				LHP <- self;
			}
			else{
				AntP <- self;
			}
		}
		
		
		ask ForwardingAgent {
			do add_network network:road_network mode:'road' nodes:
				buildingOfFDM + (Warehouse as list) + (MaritimeTerminal as list) + (RiverTerminal as list) + (MaritimeRiverTerminal as list);
			do add_network network:maritime_network mode:'maritime' nodes:
				(Provider as list) + (MaritimeTerminal as list) + (MaritimeRiverTerminal as list);
			do add_network network:river_network mode:'river' nodes:
				(RiverTerminal as list) + (MaritimeRiverTerminal as list);
		}
		
		LHAttractiveness <- 1.0;
		AntAttractiveness <- 3.0;
		do update_proba_to_choose_provider;
	}
}
