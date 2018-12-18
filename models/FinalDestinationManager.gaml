model FinalDestinationManager

import "Building.gaml"
import "Observer.gaml"

species FinalDestinationManager {
	// Basic characteristics
	float surface;
	int decreasingRateOfStocks;
	float huffValue;// number of customer according to huff model => this value cant be used like this because the Huff model does not take care of time.
	Building building;

	// Relative to contract with LSP
	LogisticsServiceProvider logisticsServiceProvider;
	int timeShifting <- rnd(23);
	int numberOfHoursOfContract <- rnd(minimalNumberOfHoursOfContract) - 100;

	// Measures of efficiency
	int stratMeasureLSPEfficiency <- 0;
		// based on number of stock shortages
	list<float> localNbStockShortagesLastSteps <- [];
	float localAverageNbStockShortagesLastSteps <- 0.0;
		// based on time to deliver some goods to the final consignee
	list<int> localTimeToBeDeliveredLastDeliveries <- []; // This variable is used to have an idea of the efficicency of the LP to deliver quickly the goods
	float localTimeToBeDelivered <- 0.0;
		// based on costs of deliveries and warehousing
	list<float> localTransportationCosts <- [];
	float localWarehousingCosts <- 0.0;
	float localAverageCosts <- 0.0;

	init {

		// Associate a building to this manager
		create Building number: 1 returns: buildings {
			location <- myself.location;
			totalSurface <- myself.surface;
			occupiedSurface <- 0.0;
			myself.building <- self;
		}

		if(isLocalLSPSwitcStrat){
			stratMeasureLSPEfficiency <- one_of(possibleLSPSwitcStrats);
		}
		else {
			stratMeasureLSPEfficiency <- globalLSPSwitchStrat;
		}

		//Connection to graphstream
		if(use_gs){
			// Add new node/edge events for corresponding sender
			if(use_r1){
				gs_add_node gs_sender_id:"actor" gs_node_id:name;
				gs_add_edge gs_sender_id:"actor" gs_edge_id:(name + logisticsServiceProvider.name) gs_node_id_from:name gs_node_id_to:logisticsServiceProvider.name gs_is_directed:false;
			}
			if(use_r2){
				gs_add_node gs_sender_id:"neighborhood_all" gs_node_id:name;
				gs_add_node_attribute gs_sender_id:"neighborhood_all" gs_node_id:name gs_attribute_name:"type" gs_attribute_value:"final_dest";
			}
			if(use_r4){
				gs_add_node gs_sender_id:"neighborhood_final_destination" gs_node_id:name;
			}
			if(use_r6){
				gs_add_node gs_sender_id:"neighborhood_warehouse_final" gs_node_id:name;
			}
			if(use_r7){
				gs_add_node gs_sender_id:"neighborhood_logistic_final" gs_node_id:name;
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
		logisticsServiceProvider <- chooseLogisticProvider();
		ask logisticsServiceProvider {
			do getNewCustomer(myself, nil, nil);
		}
		loop stock over: building.stocks {
			stock.lp <- logisticsServiceProvider;
		}
	}
	
	/**
	 * The consumption is between 0 and 1/decreasingRateOfStocks of the maximum stock.
	 */
	reflex decreasingStocks  when: (((time/3600.0) + timeShifting) mod nbStepsbetweenDS) = 0.0 {
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
	reflex manageContractWithLP when: allowLSPSwitch {
		numberOfHoursOfContract <- numberOfHoursOfContract + 1;
		if(numberOfHoursOfContract mod minimalNumberOfHoursOfContract = 0){
			if(shouldISwitchMyLSP()){
				// the logsitic provider is not efficient enough. He must be replaced by another one.
				// Inform the current logistic provider that he losts a customer
				TransferredStocks stocksRemoved;
				ask logisticsServiceProvider {
					stocksRemoved <- lostCustomer(myself);
				}

				// Choose a new one
				logisticsServiceProvider <- chooseLogisticProvider();
				// Inform him that he gets a new customer
				ask logisticsServiceProvider {
					do getNewCustomer(myself, stocksRemoved.stocksLvl1, stocksRemoved.stocksLvl2);
				}

				ask stocksRemoved {
					do die;
				}

				// We changed of LP but the new one does not know that some stock should be restocked.
				int i <- 0;
				loop while: i < length(building.stocks) {
					building.stocks[i].status <- 0;
					building.stocks[i].lp <- logisticsServiceProvider;
					i <- i + 1;
				}

				// Re-initialise some variables : contract is new, and efficiency values are set to zero.
				numberOfHoursOfContract <- 0;
				localNbStockShortagesLastSteps <- [];
				localAverageNbStockShortagesLastSteps <- 0.0;
				localTimeToBeDeliveredLastDeliveries <- [];
				localTimeToBeDelivered <- 0.0;
				localTransportationCosts <- [];
				localWarehousingCosts <- 0.0;
				localAverageCosts <- 0.0;
			}
		}
	}

	bool shouldISwitchMyLSP {
		if(stratMeasureLSPEfficiency = 1){
			if(localAverageNbStockShortagesLastSteps > averageNbStockShortages ){
				return true;
			}
		}
		else if(stratMeasureLSPEfficiency = 2){
			if(localTimeToBeDelivered > averageTimeToBeDelivered ){
				return true;
			}
		}
		else if(stratMeasureLSPEfficiency = 3){
			if(localAverageCosts > averageCosts){
				return true;
			}
		}
		return false;
	}

	/**
	 * The more the logistic provider is close, the more he has a chance to be selected.
	 */
	LogisticsServiceProvider chooseLogisticProvider {
		list<LogisticsServiceProvider> llp <- LogisticsServiceProvider sort_by (self distance_to each);
//		int i <- 0;
//		bool notfound <- true;
//		loop while: notfound {
//			if(flip(0.5) and llp[i] != logisticProvider){
//				notfound <- false;
//			}
//			else {
//				i <- i + 1;
//				if(i >= length(llp)){
//					i <- length(llp)-1;
//					notfound <- false;
//				}
//			}
//		}
//		return llp[i];

		int f <- ((rnd(10000)/10000)^4)*(length(llp)-1);
		return llp[f];

//		return one_of(LogisticProvider);
	}

	action manageLostStock(AwaitingStock aws) {
		ask logisticsServiceProvider {
			do manageLostStock(aws);
		}
	}

	aspect base { 
		draw shape+3°px color: rgb("DarkOrange") ;
	}
	
	action buildRandStock{
		// Built its stocks
 		float freeSurface <- (building.totalSurface - building.occupiedSurface);// The free surface of the building according to the max quantity
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
				if(freeSurface > myself.building.totalSurface*0.1){
					maxQuantity <- rnd(freeSurface - freeSurface*0.1)+freeSurface*0.1;
				}
				else{
					// else, the maxQuantity is the remaining surface
					maxQuantity <- freeSurface;
				}
				
				// If the remaining surface is very too tiny
				if((freeSurface-maxQuantity) < myself.building.totalSurface*0.1){
					maxQuantity <- freeSurface;
				}
				
				quantity <- rnd(maxQuantity as int) as float;
				myself.building.occupiedSurface <- myself.building.occupiedSurface + maxQuantity;
				maxOccupiedSurface <- maxOccupiedSurface + maxQuantity;
				fdm <- myself;
				self.building <- myself.building;
			}
			ls <- ls + s;
			freeSurface <- (building.totalSurface - maxOccupiedSurface);
		}
		building.stocks <- ls;
	}

	action buildOneStock {
		// Use just one product
		create Stock number: 1 returns: s;
		ask s {
			// The id of the product
			product <- 0;
			maxQuantity <- myself.building.totalSurface;
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
		float freeSurface <- building.totalSurface;// The free surface of the building according to the max quantity
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
		float freeSurface <- building.totalSurface;// The free surface of the building according to the max quantity
		float surfaceByProduct <- freeSurface / nbProduct;
		list<Stock> ls <- [];
		loop while: i < nbProduct {
			create Stock number: 1 returns: s;
			ask s {
				// The id of the product
				product <- i;
				maxQuantity <- surfaceByProduct;
				quantity <- rnd(maxQuantity as int) as float;
				myself.building.occupiedSurface <- myself.building.occupiedSurface + maxQuantity;
				fdm <- myself;
				self.building <- myself.building;
			}
			i <- i + 1;
			ls <- ls + s;
		}
		building.stocks <- ls;
	}
}
