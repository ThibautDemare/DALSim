/**
 *  LogisticProvider
 *  Author: Thibaut Démare
 *  Description: This agent manage the stock of its warehouses and the orders of his final destinations. His behavior is still simple but can be improve
 */

model LogisticProvider

import "./Provider.gaml"
import "./Warehouse.gaml"
import "./Batch.gaml"
import "./Building.gaml"
import "./SupplyChain.gaml"
import "./Order.gaml"
import "./Stock.gaml"
import "./SeineAxisModel.gaml"

species LogisticProvider parent: Role {
	list<SupplyChain> supplyChains;
	list<Warehouse> usedWarehouses;
	string color;
	
	init {
		if(use_gs){
			// Add a new node event for corresponding sender
			if(use_r1){
				gs_add_node gs_sender_id:"actor" gs_node_id:name;
				gs_add_node_attribute gs_sender_id:"actor" gs_node_id:name gs_attribute_name:"ui.style" gs_attribute_value:"fill-color:"+color+"; stroke-mode:plain; stroke-width:3px; stroke-color:red;";
			}
			if(use_r2){
				gs_add_node gs_sender_id:"neighborhood_all" gs_node_id:name;
				gs_add_node_attribute gs_sender_id:"neighborhood_all" gs_node_id:name gs_attribute_name:"ui.style" gs_attribute_value:"fill-color:"+color+";";
			}
			if(use_r5){
				gs_add_node gs_sender_id:"neighborhood_logistic_provider" gs_node_id:name;
				gs_add_node_attribute gs_sender_id:"neighborhood_logistic_provider" gs_node_id:name gs_attribute_name:"ui.style" gs_attribute_value:"fill-color:"+color+";";
			}
			if(use_r7){
				gs_add_node gs_sender_id:"neighborhood_logistic_final" gs_node_id:name;
				gs_add_node_attribute gs_sender_id:"neighborhood_logistic_final" gs_node_id:name gs_attribute_name:"ui.style" gs_attribute_value:"fill-color:"+color+";";
			}
		}
	}
	
	/**
	 * Test for each warehouse if it needs to be restock;
	 */
	reflex testOrdersNeeded when: ((time/3600.0) mod 24.0) = 0.0 { //An order is possible one time by day.
		loop warehouse over: usedWarehouses {
			loop stock over: warehouse.stocks {
  				if stock.quantity < 0.5*stock.maxQuantity and stock.ordered=false {
					stock.ordered <- true;
					create Order number: 1 returns: b {
						self.product <- stock.product;
						self.quantity <- stock.maxQuantity-stock.quantity;
						self.building <- warehouse;
					}
					
					do receiveOrder(first(b));
				}
			}
		}
	}
	
	/**
	 * 
	 */
	action receiveOrder(Order order){		
		// Need to know which warehouse must restock
		list<Building> supplyChain <- nil;
		Building sender <- nil;
		int i <- 0;
		int j <- 0;
		loop while: i < length(supplyChains) and sender = nil{
			supplyChain <- (supplyChains[i] as SupplyChain).buildings;
			j <- length(supplyChain)-1;
			loop while: j > 0 and sender = nil {
				if( order.building = supplyChain[j] ){
					sender <- supplyChain[j-1];
				}
				else{
					j <- j - 1;
				}
			}
			i <- i + 1;
		}	
		if( j = 1){// The provider must send new stock
			ask Provider {
				do receiveOrder(order);
			}
		}
		else{// A warehouse must send new stock
			ask (sender as Warehouse) {
				do receiveRestockRequest(order);
			}
		}
		ask order {
			do die;
		}
	}
	
	
	/**
	 * When a logistic provider has a new customer, he need to find a new supply chain. This method build it.
	 */
	action addFinalDest(FinalDestinationManager fdm){
		list<Building> supplyChain <- [];
		// Find appropriates warehouses
		Warehouse small <- findSmallWarehouse(fdm);
		Warehouse large <- findLargeWarehouse(fdm);
		Warehouse average <- findAverageWarehouse(small, large, fdm);
		usedWarehouses <- usedWarehouses + small + large + average;
		
		// Associate new stock to these warehouse
		do initStock(small, fdm);
		do initStock(large, fdm);
		do initStock(average, fdm);
		
		// Build the supply chain : the provider is the first one, and the final destination is the last.
		supplyChain <- supplyChain + provider.building;
		supplyChain <- supplyChain + large;
		supplyChain <- supplyChain + average;
		supplyChain <- supplyChain + small;
		supplyChain <- supplyChain + fdm.building;
		
		// Add the new supply chain to others
		create SupplyChain number:1 returns:sc;
		ask sc {
			buildings <- supplyChain;
			myself.supplyChains <- myself.supplyChains + self;
		}
	}
	
	/**
	 * We assume that the warehouse have already a stock when we initialize a new supply chain
	 */
	action initStock(Warehouse warehouse, FinalDestinationManager fdm){
		loop stockFdm over: (fdm.building as Building).stocks {
			Stock stockW <- nil;
			bool found <- false;
			int i <- 0;
			loop while: i < length(warehouse.stocks) and !found {
				stockW <- warehouse.stocks[i];
				if(stockW.product = stockFdm.product){
					found <- true;
				}
				i <- i + 1;
			}
			
			// If we have not found a stock, we must create one 
			if(!found){
				create Stock number:1 returns:s {
					self.product <- stockFdm.product;
					self.quantity <- stockFdm.maxQuantity;
					self.maxQuantity <- stockFdm.maxQuantity;
					self.ordered <- false;
					self.building <- warehouse;
				}
				warehouse.stocks <- warehouse.stocks + s[0];
			}
			else {// There is already a stock, we must update it
				ask stockW {
					self.quantity <- self.quantity + stockFdm.maxQuantity;
					self.maxQuantity <- self.maxQuantity + stockFdm.maxQuantity;
				}
			}
			// Finally we update the occupied surface
			warehouse.occupiedSurface <- warehouse.occupiedSurface + stockFdm.maxQuantity;
		}
	}
	
	/**
	 * Return a small warehouse according to the position of the final destination : the more the warehouse is close to the final destination, the more he have a chance to be selected.
	 */
	Warehouse findSmallWarehouse(FinalDestinationManager fdm){
		// Stupid selection method. To be improve, but I need test before going further.
		return one_of(small_warehouse);
	}
	
	/**
	 * Return a large warehouse according to the position of the final destination : the more the warehouse has a big free surface, the more he have a chance to be selected.
	 */
	Warehouse findLargeWarehouse(FinalDestinationManager fdm){
		// Stupid selection method. To be improve, but I need test before going further.
		return one_of(large_warehouse);
	}
	
	/**
	 * Return an average warehouse according to this formulae :
	 * - Let A be the small warehouse, B the average one that we are looking for, and C the large one.
	 * - Let ->AB the vector between the local warehouse and the average one.
	 * - Let ->CB be the vector between the large warehouse and the average one.
	 * So, we are trying to find B which minimize ||(->AB) + (->CB)||.
	 */
	Warehouse findAverageWarehouse(Warehouse small, Warehouse large, FinalDestinationManager fdm){
		// Stupid selection method. To be improve, but I need test before going further.
		return one_of(average_warehouse);
	}
	
	aspect base { 
		draw square(1.5°km) color: rgb("green") ;
	} 
}