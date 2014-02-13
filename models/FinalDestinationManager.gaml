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

species FinalDestinationManager parent: Role{
	LogisticProvider logisticProvider;
	Building building;
	float huffValue;// number of customer according to huff model => this value cant be used like this because the Huff model does not take care of time.
	int currentInertia;
	int maxInertia;
	int decreasingRateOfStocks;
	
	init {
		logisticProvider <- chooseLogisticProvider();
		
		// Init the inertia mechanism
		currentInertia <- 0;
		// There is one chance on 10 to never change of logistic provider
		if(flip(0.9)){
			maxInertia <- rnd(24)+12;// Between one year and 3 years
		}
		else{
			maxInertia <- -1;
		}
		
		create Building number: 1 returns: buildings {
			location <- myself.location;
		}
		
		create Stock number: 5 returns: s;
		ask s {
			pair temp <- one_of(products.pairs);
			product <- temp.key;
			quantity <- rnd(temp.value as int) as float;
			maxQuantity <- temp.value;			
			building <- first(buildings);
		}
		
		ask buildings {
			self.stocks <- s;
			myself.building <- self;
		}
		
		//Connection to graphstream
		if(use_gs){
			// Add new node/edge events for corresponding sender
			if(use_r1){
				gs_add_node gs_sender_id:"actor" gs_node_id:name;
				gs_add_node_attribute gs_sender_id:"actor" gs_node_id:name gs_attribute_name:"ui.style" gs_attribute_value:"fill-color:blue;";
				gs_add_edge gs_sender_id:"actor" gs_edge_id:(name + logisticProvider.name) gs_node_id_from:name gs_node_id_to:logisticProvider.name gs_is_directed:false;
			}
			if(use_r2){
				gs_add_node gs_sender_id:"neighborhood_all" gs_node_id:name;
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
		}
	}
	
	/*
	 * The consumption is between 0 and 1/decreasingRateOfStocks of the maximum stock.
	 */
	reflex decreasingStocks  when: (cycle mod 24) = 0 {//the stock decrease one time by day (one cycle = 60min)
		loop stock over: building.stocks {
			stock.quantity <- stock.quantity - (rnd(stock.maxQuantity/decreasingRateOfStocks));
			if(stock.quantity < 0){
				stock.quantity <-  0.0;
			}
		}
	}
	
	reflex updateCurrentInertia when: ((time/3600.0) mod 720.0) = 0.0 { // One time by month. 720 = number of hours in one month 
		currentInertia <- currentInertia + 1;
	}
	
	reflex wantToChangeLogisticProvider when: (currentInertia > maxInertia) {
		if(flip((currentInertia - maxInertia)/1000)){
			logisticProvider <- chooseLogisticProvider();
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
	
	/*
	 * Check for all product if it needs to be restock
	 * If yes, an order is made to the logistic provider
	 */
	reflex order when: ((time/3600.0) mod 24.0) = 0.0 { //A order is possible one time by day. 
		loop stock over: building.stocks {
			if stock.quantity < 0.05*stock.maxQuantity and stock.ordered=false {
				stock.ordered <- true;
				create Order number: 1 returns: b {
					self.product <- stock.product;
					self.quantity <- stock.maxQuantity;
					self.unitVolume <- stock.unitVolume;
					self.supplyChain <- supplyChain + stock.building;
					self.logisticProvider <- myself.logisticProvider;
				}
				
				ask logisticProvider {
					do receive_order(first(b));
				}

			}
		}
	}
	
	/*
	 * Receive a batch of goods
	 * We adjust the corresponding stock quantity
	 */
	reflex receive_batch {
		list<Batch> entering_batch <- (Batch inside self) where (each.target = nil);
		if not (empty (entering_batch)) {
			ask entering_batch {
				if (self.breakBulk = 0) {					
					loop stock over: myself.building.stocks {
						if stock.product = self.product {
							stock.ordered <- false;
							stock.quantity <- stock.quantity + self.quantity;
						}
					}
					ask self {
						do die;
					}
				}
			}
		}
	}
	
	LogisticProvider chooseLogisticProvider {
		list<LogisticProvider> llp <- LogisticProvider sort_by (self distance_to each);
		int f <- ((rnd(10000)/10000)^6)*(length(llp)-1);
		return llp[f];
	}
	
	aspect base { 
		draw square(1.5°km) color: rgb("blue") ;
	} 
}