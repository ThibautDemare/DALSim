model Main

import "GraphStreamConnection.gaml"
import "Terminals.gaml"
import "Transporters.gaml"
import "ForwardingAgent.gaml"
import "Vehicle.gaml"
import "Perturbator.gaml"
import "Experiments.gaml"
import "RegionObserver.gaml"

/*
 * Init global variables and agents
 */
global {

	string pathBD <- "../../../BD_SIG/Used/";

	// To draw the borders of the countries and therefore the coastline
	file countries_borders <- file(pathBD+"Countries/borders.shp");

	// The road network
	//This data comes from "EuroGlobalMap" (EuroGeographics)
	// Each road has an attribute giving the speed in km/h
	file roads_shapefile <- file(pathBD+"Roads/Road_Network_LH-A/Road_Network_LH-A_lambert93_filtered_attributes.shp");

	// The maritime network
	file maritime_shapefile <- file(pathBD+"Maritime/maritime_lambert93_filtered_attributes.shp");

	// The river  network
	// This Shapefile comes from the database made by the ETIS Project. However, we updated it according to this website :
	// - http://maps.grade.de/index.htm
	// in order to have correct CEMT values
	// And also we updated it in order to have the Canal Seine Nord navigable.
	//file river_shapefile <- file(pathBD+"River/river_network_length_in_km.shp"); Only the Seine and Oise => not the part to Antwerp with Canal Seine Nord
	file river_shapefile <- file(pathBD+"River/IWW_Axe_Seine_Antwerp_CLASS-40-50-60_lambert93.shp");
	list<RiverLine> canalSeineNord <- [];

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
	
	// The french regions
	// Data comes from :
	// Contours des régions françaises sur OpenStreetMap (consulted the 30/11/2018) -> https://www.data.gouv.fr/fr/datasets/contours-des-regions-francaises-sur-openstreetmap/
	file regions_shapefile <- file(pathBD+"Regions/regions.shp");
	// And Antwerp (actually, it is the limits of Antwerpen + Beveren (had to merge them because one of the Antwerp terminal is not inside the boundaries of the city))
	// Data come from :
	// Atlas de Belgique - divisions communes (consulted the 06/21/2018) -> http://www.atlas-belgique.be/cms2/index.php?page=cartodata_fr
	file antwerp_shapefile <- file(pathBD+"Regions/antwerpen_limits.shp");
	// And Le Havre limits
	file lh_shapefile <- file(pathBD+"Regions/lh_limits.shp");

	//Define the border of the environnement according to the road network
	geometry shape <- envelope(roads_shapefile);

	ForwardingAgent forwardingAgent;

	bool second_init_bool <- true;
	
	init {
		// Graphstream connections
		if(use_gs){
			// Init senders in order to create nodes/edges when we create agent
			do init_senders;
		}

		// Transportation networks
			// Road
		create Road from: roads_shapefile with: [speed::read("speed") as float, length::read("length") as float];
		road_network <- as_edge_graph(Road);
			// Maritime
		create MaritimeLine from: maritime_shapefile with: [speed::read("speed") as float, length::read("length") as float];
		maritime_network <- as_edge_graph(MaritimeLine);
			// River
		create RiverLine from: river_shapefile with: [speed::read("speed") as float, length::read("length") as float, is_new::read("is_new") as int];
		river_network <- as_edge_graph(RiverLine);

		// Countries
		create Country from: countries_borders;

		// Region observers
		create RegionObserver from: regions_shapefile with: [name::read("nom") as string];
		create RegionObserver from: antwerp_shapefile with: [name::read("Name") as string];
		create RegionObserver from: lh_shapefile with: [name::read("nom") as string];

		// Providers
		create Provider from: provider_shapefile with: [port::read("Port") as string];

		// Transporters
		create RoadTransporter number:1;
		create RiverTransporter number:1;
		create MaritimeTransporter number:1;
		
		// Terminals
			// Terminals of LH (they are maritime and river terminals)
		create MaritimeRiverTerminal from: terminal_LH_shapefile with: [handling_time_to_road::read("TO_ROAD") as float,
			handling_time_to_river::read("TO_RIVER") as float,
			handling_time_to_maritime::read("TO_MARITIM") as float,
			handling_time_from_road::read("FROM_ROAD") as float,
			handling_time_from_river::read("FROM_RIVER") as float,
			handling_time_from_maritime::read("FROM_MARIT") as float
		];
			// Terminals inside  the Seine axis (they are river terminals)
		create RiverTerminal from: river_terminals with: [handling_time_to_road::read("TO_ROAD") as float,
			handling_time_to_river::read("TO_RIVER") as float,
			handling_time_from_road::read("FROM_ROAD") as float,
			handling_time_from_river::read("FROM_RIVER") as float
		];
			// Terminals of Antwerp (they are maritime and river terminals if we have the Canal Seine Nord, otherwise, they are MaritimeTerminal agents)
		create MaritimeRiverTerminal from: terminal_A_shapefile with: [handling_time_to_road::read("TO_ROAD") as float,
			handling_time_to_river::read("TO_RIVER") as float,
			handling_time_to_maritime::read("TO_MARITIM") as float,
			handling_time_from_road::read("FROM_ROAD") as float,
			handling_time_from_river::read("FROM_RIVER") as float,
			handling_time_from_maritime::read("FROM_MARIT") as float
		];

		// Forwarding agent
		create ForwardingAgent number:1 returns:fas;
		forwardingAgent <- fas[0];

		// Create a vehicle to call "init_networks"
		create Vehicle number:1;

		// Warehouses
		create Warehouse from: warehouse_shapefile returns: lw with: [totalSurface::read("surface") as float];
		/*
		 * The following code can be commented or not, depending if the user want to execute the simulation with every Warehouse 
		 * It is mainly used for tests to avoid CPU overload.
		 */
		int i <- 100;
		list<Warehouse> llsp <- shuffle(Warehouse);
		loop while: i < length(llsp) {
			Warehouse s <- llsp[i];
			remove index: i from: llsp;
			ask s {
				do die;
			}
		}
		/**/

		//  Logistic Service providers
		create LogisticsServiceProvider from: logistic_provider_shapefile;

		/*
		 * The following code can be commented or not, depending if the user want to execute the simulation with every LSP 
		 * It is mainly used for tests to avoid CPU overload.
		 */
		int i <- 50;
		list<LogisticsServiceProvider> llsp <- shuffle(LogisticsServiceProvider);
		loop while: i < length(llsp) {
			LogisticsServiceProvider s <- llsp[i];
			remove index: i from: llsp;
			ask s {
				do die;
			}
		}
		/**/

		// Final destinations
		create FinalConsignee from: destination_shapefile with: [huffValue::float(read("huff")), surface::float(read("surface"))];
		/* 
		 * The following code can be commented or not, depending if the user want to execute the simulation with every FDM 
		 * It is mainly used for tests to avoid CPU overload.
		 */
		int i <- 50;
		list<FinalConsignee> lfdm <- shuffle(FinalConsignee);
		loop while: i < length(lfdm) {
			FinalConsignee s <- lfdm[i];
			remove index: i from: lfdm;
			ask s {
				do die;
			}
		}
		/**/

		create Commodity number:1; // create an empty commodity here, because, otherwise, I don't have access to the list of commodities while the simulation is running, in GUI mode

		// Init other parameters
		do init_decreasingRateOfStocks;
		do init_cost;
	}
	
	/*
	 * A part of the initialization of some agents must be made here once every agent have been fully initilized.
	 */
	reflex second_init when: second_init_bool {
		second_init_bool <- false;

		// We initialyse stocks and associate the buildings  to their FDM
		list<Building> buildingOfFDM <- [];
		ask FinalConsignee sort_by (-1*each.surface){
			do second_init;
			buildingOfFDM <+ self.building;
		}

		// We initialyse the networks so the vehicles can move on these
		ask Vehicle[0] {
			do init_networks;
		}

		// We initialyse the networks but this time for the forwarding agent so he can compute multi-modal shortest paths
		ask forwardingAgent {
			do add_mode network:road_network mode:'road' nodes:
				buildingOfFDM + (Warehouse as list) + (MaritimeTerminal as list) + (RiverTerminal as list) + (MaritimeRiverTerminal as list);
			do add_mode network:maritime_network mode:'maritime' nodes:
				(Provider as list) + (MaritimeTerminal as list) + (MaritimeRiverTerminal as list);
			do add_mode network:river_network mode:'river' nodes:
				(RiverTerminal as list) + (MaritimeRiverTerminal as list);
		}

		// We block the canal Seine Nord at the beginning of the simulation
		ask RiverLine {
			if(is_new = 1){
				canalSeineNord <+ self;
				ask forwardingAgent {
					do block_edge edge:myself;
				}
			}
		}

		ask RegionObserver{
			ask ((Building as list) + (Warehouse as list) + (MaritimeTerminal as list) + (RiverTerminal as list) + (MaritimeRiverTerminal as list)) inside self {
				myself.buildings <+ self;
			}
			ask ((FinalConsignee as list)) inside self {
				myself.fcs <+ self;
			}
			ask ((MaritimeRiverTerminal as list) + ((MaritimeRiverTerminal as list) as list) + (MaritimeTerminal as list)) inside self {
				myself.terminals <+ self;
			}
		}
		// We associate a provider to each LSPs according to the distance and the attractiveness
//		LHAttractiveness <- 1.0;
//		AntAttractiveness <- 3.0;
//		do update_proba_to_choose_provider;
	}
}

species Country {
	aspect geom {
		draw shape color: rgb("#91bfdb") border: rgb("grey");
	}
}
