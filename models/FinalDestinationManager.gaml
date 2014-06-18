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

species FinalDestinationManager parent: Role{
	LogisticProvider logisticProvider;
	Building building;
	float huffValue;// number of customer according to huff model => this value cant be used like this because the Huff model does not take care of time.
	int currentInertia;
	int maxInertia;
	int decreasingRateOfStocks;
	string color;
	int department;
	int region;
	float surface;
	
	init {
		// Init the inertia mechanism
		currentInertia <- 0;
		// There is one chance on 10 to never change of logistic provider
		if(flip(probabilityToChangeLogisticProvider)){
			maxInertia <- rnd(24)+12;// Between one year and 3 years
		}
		else{
			maxInertia <- -1;
		}
		
		// Associate a building to this manager
		create Building number: 1 returns: buildings {
			location <- myself.location;
			totalSurface <- myself.surface;
			occupiedSurface <- 0.0;
		}
		
		ask buildings {
			myself.building <- self;
		}
		
		// Built its stocks
 /*		float freeSurface <- (building.totalSurface - building.occupiedSurface);// The free surface of the building according to the max quantity
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
				building <- myself.building;
				building.occupiedSurface <- building.occupiedSurface + quantity;
				maxOccupiedSurface <- maxOccupiedSurface + maxQuantity;
				fdm <- myself;
			}
			ls <- ls + s;
			freeSurface <- (building.totalSurface - maxOccupiedSurface);
		}
		building.stocks <- ls;*/

// Use just one product
/*		create Stock number: 1 returns: s;
		ask s {
			// The id of the product
			product <- 0;
			maxQuantity <- building.totalSurface;
			quantity <- rnd(maxQuantity as int) as float;
			building <- myself.building;
			building.occupiedSurface <- building.occupiedSurface + quantity; 
			fdm <- myself;
		}
		building.stocks <- s;*/

// use exactly 4 products occupying the same surface
/*		int i <- 0;
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
				quantity <- rnd(maxQuantity as int) as float;
				building <- myself.building;
				building.occupiedSurface <- building.occupiedSurface + quantity;
				fdm <- myself;
			}
			ls <- ls + s;
		}
		building.stocks <- ls;*/
		
// use between 2 and 6 products occupying the same surface
		int i <- 0;
		int nbProduct <- rnd(2)+2;
		float freeSurface <- building.totalSurface;// The free surface of the building according to the max quantity
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
				building <- myself.building;
				building.occupiedSurface <- building.occupiedSurface + quantity;
				fdm <- myself;
			}
			ls <- ls + s;
		}
		building.stocks <- ls;
		
		// Connection to graphstream
		if(use_gs){
			if(use_r9){
				gs_add_node gs_sender_id:"supply_chain" gs_node_id:building.name;
				gs_add_node_attribute gs_sender_id:"supply_chain" gs_node_id:building.name gs_attribute_name:"x" gs_attribute_value:location.x;
				gs_add_node_attribute gs_sender_id:"supply_chain" gs_node_id:building.name gs_attribute_name:"y" gs_attribute_value:location.y;
			}
		}
		
		logisticProvider <- chooseLogisticProvider();
		ask logisticProvider {
			do getNewCustomer(myself);
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
		}
	}
	
	/**
	 * The consumption is between 0 and 1/decreasingRateOfStocks of the maximum stock.
	 */
	reflex decreasingStocks  when: ((time/3600.0) mod numberOfHoursBeforeDS) = 0.0 {//the stock decrease one time by day (one cycle = 60min)
		loop stock over: building.stocks {
			stock.quantity <- stock.quantity - (rnd(stock.maxQuantity/decreasingRateOfStocks));
			if(stock.quantity < 0){
				stock.quantity <-  0.0;
			}
		}
	}
	
	/**
	 * Increment the currentInertia value one time by month
	 */
	reflex updateCurrentInertia when: ((time/3600.0) mod numberOfHoursBeforeUCI) = 0.0 { // One time by month. 720 = number of hours in one month 
		currentInertia <- currentInertia + 1;
	}
	
	/**
	 * If the agent can change his logistic provider, the agent must take a decision (a probability) if he really changes or not. The more the time goes, the more the agent has a chance.
	 */
	reflex wantToChangeLogisticProvider when: (currentInertia > maxInertia and maxInertia >= 0) {
		if(flip((currentInertia - maxInertia)/1000)){
			// Inform current logistic provider that he lost a customer
			ask logisticProvider {
				do lostCustomer(myself);
			}
			// Choose a new one
			logisticProvider <- chooseLogisticProvider();
			// Inform him that he gets a new customer
			ask logisticProvider {
				do getNewCustomer(myself);
			}
			currentInertia <- 0;
			if(use_gs){
				// Add new node/edge events for corresponding sender
				if(use_r1){
					// We don't remove the old edge. The actor network can be seen as a cumulative network.
					// Is it a problem? Do we need to remove this edge?
					gs_add_edge gs_sender_id:"actor" gs_edge_id:(name + logisticProvider.name) gs_node_id_from:name gs_node_id_to:logisticProvider.name gs_is_directed:false;
				}
			}
		}
	}
	
	/**
	 * Check for all product if it needs to be restock.
	 * If yes, an order is made to the logistic provider
	 */
	reflex testOrdersNeeded when: ((time/3600.0) mod numberOfHoursBeforeTON) = 0.0 { //An order is possible one time by day. 
		loop stock over: building.stocks {
			if stock.quantity < minimumStockFinalDestPercentage*stock.maxQuantity and stock.ordered=false {
				stock.ordered <- true;
				create Order number: 1 returns: b {
					self.product <- stock.product;
					self.quantity <- stock.maxQuantity-stock.quantity;
					self.building <- myself.building;
					self.logisticProvider <- myself.logisticProvider;
					fdm <- myself;
				}
				
				ask logisticProvider {
					do receiveOrder(first(b));
				}

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
		draw square(2°km) color: rgb("DarkOrange") ;
	} 
}
