/**
 *  FinalDestinationManager
 *  Author: Thibaut Démare
 *  Description: This agent sells his stock and then must order a restock to his logistic provider.
 */

model FinalDestinationManager

import "./LogisticProvider.gaml"
import "./SeineAxisModel.gaml"
import "./Warehouse.gaml"
import "./Batch.gaml"
import "./Building.gaml"
import "./Order.gaml"
import "./Stock.gaml"
import "./GraphStreamConnection.gaml"
import "./Parameters.gaml"

species FinalDestinationManager schedules: [] {
	LogisticProvider logisticProvider;
	list<float> localLPEfficiencies <- [];
	float localAverageLPEfficiency <- 0.0;
	int numberOfDaysOfContract <- rnd(minimalNumberOfDaysOfContract);
	Building building;
	float huffValue;// number of customer according to huff model => this value cant be used like this because the Huff model does not take care of time.
	int decreasingRateOfStocks;
	string color;
	int department;
	int region;
	float surface;
	
	init {

		// Associate a building to this manager
		create Building number: 1 returns: buildings {
			location <- myself.location;
			totalSurface <- myself.surface;
			surfaceUsedForLH <- myself.surface;
			occupiedSurface <- 0.0;
			myself.building <- self;
		}
		
		//Connection to graphstream
		if(use_gs){
			// Add new node/edge events for corresponding sender
			if(use_r1){
				gs_add_node gs_sender_id:"actor" gs_node_id:name;
				gs_add_node_attribute gs_sender_id:"actor" gs_node_id:name gs_attribute_name:"region" gs_attribute_value:region;
				gs_add_node_attribute gs_sender_id:"actor" gs_node_id:name gs_attribute_name:"department" gs_attribute_value:department;
				gs_add_edge gs_sender_id:"actor" gs_edge_id:(name + logisticProvider.name) gs_node_id_from:name gs_node_id_to:logisticProvider.name gs_is_directed:false;
			}
			if(use_r2){
				gs_add_node gs_sender_id:"neighborhood_all" gs_node_id:name;
				gs_add_node_attribute gs_sender_id:"neighborhood_all" gs_node_id:name gs_attribute_name:"region" gs_attribute_value:region;
				gs_add_node_attribute gs_sender_id:"neighborhood_all" gs_node_id:name gs_attribute_name:"department" gs_attribute_value:department;
				gs_add_node_attribute gs_sender_id:"neighborhood_all" gs_node_id:name gs_attribute_name:"type" gs_attribute_value:"final_dest";
			}
			if(use_r4){
				gs_add_node gs_sender_id:"neighborhood_final_destination" gs_node_id:name;
				gs_add_node_attribute gs_sender_id:"neighborhood_final_destination" gs_node_id:name gs_attribute_name:"region" gs_attribute_value:region;
				gs_add_node_attribute gs_sender_id:"neighborhood_final_destination" gs_node_id:name gs_attribute_name:"department" gs_attribute_value:department;
			}
			if(use_r6){
				gs_add_node gs_sender_id:"neighborhood_warehouse_final" gs_node_id:name;
				gs_add_node_attribute gs_sender_id:"neighborhood_warehouse_final" gs_node_id:name gs_attribute_name:"region" gs_attribute_value:region;
				gs_add_node_attribute gs_sender_id:"neighborhood_warehouse_final" gs_node_id:name gs_attribute_name:"department" gs_attribute_value:department;
			}
			if(use_r7){
				gs_add_node gs_sender_id:"neighborhood_logistic_final" gs_node_id:name;
				gs_add_node_attribute gs_sender_id:"neighborhood_logistic_final" gs_node_id:name gs_attribute_name:"region" gs_attribute_value:region;
				gs_add_node_attribute gs_sender_id:"neighborhood_logistic_final" gs_node_id:name gs_attribute_name:"department" gs_attribute_value:department;
			}
			
			if(use_r9){
				gs_add_node gs_sender_id:"supply_chain" gs_node_id:name;
				gs_add_node_attribute gs_sender_id:"supply_chain" gs_node_id:name gs_attribute_name:"x" gs_attribute_value:location.x;
				gs_add_node_attribute gs_sender_id:"supply_chain" gs_node_id:name gs_attribute_name:"y" gs_attribute_value:location.y;
				gs_add_node_attribute gs_sender_id:"supply_chain" gs_node_id:name gs_attribute_name:"outflow" gs_attribute_value:0.0;
			}
		}
	}
	
	action second_init{
		//do buildRandStock;
		//do buildOneStock;
		//do buildFourStock;
		do buildTwoToSixStock;
		
		logisticProvider <- chooseLogisticProvider();
		ask logisticProvider {
			do getNewCustomer(myself);
		}
		
		loop stock over: building.stocks {
			stock.lp <- logisticProvider;
		}
	}
	
	/**
	 * The consumption is between 0 and 1/decreasingRateOfStocks of the maximum stock.
	 */
	reflex decreasingStocks  when: ((time/3600.0) mod numberOfHoursBeforeDS) = 0.0 {
		loop stock over: building.stocks {
			float consumeQuantity <- 0.0;
			loop while: consumeQuantity = 0 {
				consumeQuantity <- rnd(stock.maxQuantity/decreasingRateOfStocks);
			}
			stock.quantity <- stock.quantity - consumeQuantity;
			if(stock.quantity < 0){
				stock.quantity <-  0.0;
			}
		}
	}
	
	/**
	 * This reflex manages the contract with the logistic provider.
	 * If the contract is old enough, and if the efficiency of the LP is too low, then the FDM change of collaborator.
	 */
	reflex manageContractWithLP {
		numberOfDaysOfContract <- numberOfDaysOfContract + 1;
		if(numberOfDaysOfContract > minimalNumberOfDaysOfContract){
			if(localAverageLPEfficiency < averageLPEfficiency){
				// the logsitic provider is not efficient enough. He must be replaced by another one.
				// Inform the current logistic provider that he losts a customer
				ask logisticProvider {
					do lostCustomer(myself);
				}
				// Choose a new one
				logisticProvider <- chooseLogisticProvider();
				// Inform him that he gets a new customer
				ask logisticProvider {
					do getNewCustomer(myself);
				}

				// We changed of LP but the new one does not know that some stock should be restocked.
				int i <- 0;
				loop while: i < length(building.stocks) {
					building.stocks[i].status <- 0;
				}

				// Re-initialise some variables : contract is new, and efficiency values are set to zero.
				numberOfDaysOfContract <- 0;
				localLPEfficiencies <- [];
				localAverageLPEfficiency <- 0.0;
			}
		}
	}

	/**
	 * The more the logistic provider is close, the more he has a chance to be selected.
	 */
	LogisticProvider chooseLogisticProvider {
		list<LogisticProvider> llp <- LogisticProvider sort_by (self distance_to each);
		int f <- ((rnd(10000)/10000)^6)*(length(llp)-1);
		return llp[f];
	}
	
	aspect base { 
		draw shape+3°px color: rgb("DarkOrange") ;
	}
	
	action buildRandStock{
		// Built its stocks
 		float freeSurface <- (building.surfaceUsedForLH - building.occupiedSurface);// The free surface of the building according to the max quantity
		float maxOccupiedSurface <- 0.0;// the occupied surface if the stock are maximum.
		list<Stock> ls <- [];
		int i <- 0;// useful to add an id to products
		loop while: freeSurface > 0 {
			create Stock number: 1 returns: s;
			ask s {
				// The id of the product
				product <- i;
				i <- i + 1;
				
				// If the free surface is greater than 10 percent of the total surface,
				// then we have : 10 percent of the free surface <= maxQuantity < freeSurface
				if(freeSurface > myself.building.surfaceUsedForLH*0.1){
					maxQuantity <- rnd(freeSurface - freeSurface*0.1)+freeSurface*0.1;
				}
				else{
					// else, the maxQuantity is the remaining surface
					maxQuantity <- freeSurface;
				}
				
				// If the remaining surface is very too tiny
				if((freeSurface-maxQuantity) < myself.building.surfaceUsedForLH*0.1){
					maxQuantity <- freeSurface;
				}
				
				quantity <- rnd(maxQuantity as int) as float;
				myself.building.occupiedSurface <- myself.building.occupiedSurface + maxQuantity;
				maxOccupiedSurface <- maxOccupiedSurface + maxQuantity;
				fdm <- myself;
				self.building <- myself.building;
			}
			ls <- ls + s;
			freeSurface <- (building.surfaceUsedForLH - maxOccupiedSurface);
		}
		building.stocks <- ls;
	}

	action buildOneStock {
		// Use just one product
		create Stock number: 1 returns: s;
		ask s {
			// The id of the product
			product <- 0;
			maxQuantity <- myself.building.surfaceUsedForLH;
			quantity <- rnd(maxQuantity as int) as float;
			myself.building.occupiedSurface <- myself.building.occupiedSurface + maxQuantity; 
			fdm <- myself;
			self.building <- myself.building;
		}
		building.stocks <- s;
	}

	action buildFourStock {
		// use exactly 4 products occupying the same surface
		int i <- 0;
		float freeSurface <- building.surfaceUsedForLH;// The free surface of the building according to the max quantity
		float surfaceByProduct <- freeSurface / 4.0;
		float maxOccupiedSurface <- 0.0;// the occupied surface if the stock are maximum.
		list<Stock> ls <- [];
		loop while: i < 4 {
			create Stock number: 1 returns: s;
			ask s {
				// The id of the product
				product <- i;
				i <- i + 1;
				maxQuantity <- surfaceByProduct;
				quantity <- rnd(maxQuantity);
				myself.building.occupiedSurface <- myself.building.occupiedSurface + maxQuantity;
				fdm <- myself;
				self.building <- myself.building;
			}
			ls <- ls + s;
		}
		building.stocks <- ls;
	}

	action buildTwoToSixStock {	
		// use between 2 and 6 products occupying the same surface
		int i <- 0;
		int nbProduct <- rnd(2)+2;
		float freeSurface <- building.surfaceUsedForLH;// The free surface of the building according to the max quantity
		float surfaceByProduct <- freeSurface / nbProduct;
		float maxOccupiedSurface <- 0.0;// the occupied surface if the stock are maximum.
		list<Stock> ls <- [];
		loop while: i < nbProduct {
			create Stock number: 1 returns: s;
			ask s {
				// The id of the product
				product <- i;
				i <- i + 1;
				maxQuantity <- surfaceByProduct;
				quantity <- rnd(maxQuantity as int) as float;
				myself.building.occupiedSurface <- myself.building.occupiedSurface + maxQuantity;
				fdm <- myself;
				self.building <- myself.building;
			}
			ls <- ls + s;
		}
		building.stocks <- ls;
	}
}
