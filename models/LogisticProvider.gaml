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
import "./GraphStreamConnection.gaml"

species LogisticProvider parent: Role {
	list<SupplyChain> supplyChains;
	list<Warehouse> usedWarehouses;
	string color;
	int department;
	int region;
	
	init {
		if(use_gs){
			// Add a new node event for corresponding sender
			if(use_r1){
				gs_add_node gs_sender_id:"actor" gs_node_id:name;
				gs_add_node_attribute gs_sender_id:"actor" gs_node_id:name gs_attribute_name:"region" gs_attribute_value:region;
				gs_add_node_attribute gs_sender_id:"actor" gs_node_id:name gs_attribute_name:"department" gs_attribute_value:department;
			}
			if(use_r2){
				gs_add_node gs_sender_id:"neighborhood_all" gs_node_id:name;
				gs_add_node_attribute gs_sender_id:"neighborhood_all" gs_node_id:name gs_attribute_name:"region" gs_attribute_value:region;
				gs_add_node_attribute gs_sender_id:"neighborhood_all" gs_node_id:name gs_attribute_name:"department" gs_attribute_value:department;
				gs_add_node_attribute gs_sender_id:"neighborhood_all" gs_node_id:name gs_attribute_name:"type" gs_attribute_value:"logistic_provider";
			}
			if(use_r5){
				gs_add_node gs_sender_id:"neighborhood_logistic_provider" gs_node_id:name;
				gs_add_node_attribute gs_sender_id:"neighborhood_logistic_provider" gs_node_id:name gs_attribute_name:"region" gs_attribute_value:region;
				gs_add_node_attribute gs_sender_id:"neighborhood_logistic_provider" gs_node_id:name gs_attribute_name:"department" gs_attribute_value:department;
			}
			if(use_r7){
				gs_add_node gs_sender_id:"neighborhood_logistic_final" gs_node_id:name;
				gs_add_node_attribute gs_sender_id:"neighborhood_logistic_final" gs_node_id:name gs_attribute_name:"region" gs_attribute_value:region;
				gs_add_node_attribute gs_sender_id:"neighborhood_logistic_final" gs_node_id:name gs_attribute_name:"department" gs_attribute_value:department;
			}
		}
	}
	
	/**
	 * Test for each warehouse if it needs to be restock;
	 */
	reflex testOrdersNeeded when: ((time/3600.0) mod 24.0) = 0.0 { //An order is possible one time by day.
		loop warehouse over: usedWarehouses {
			loop stock over: warehouse.stocks {
  				if stock.lp = self and stock.quantity < 0.5*stock.maxQuantity and stock.ordered = false {
					stock.ordered <- true;
					create Order number: 1 returns: b {
						self.product <- stock.product;
						self.quantity <- stock.maxQuantity-stock.quantity;
						self.building <- warehouse;
						self.fdm <- stock.fdm;
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
		
		// Find the right supply chain
		loop while: i < length(supplyChains) and sender = nil{
			if((supplyChains[i] as SupplyChain).fdm = order.fdm){
				supplyChain <- (supplyChains[i] as SupplyChain).buildings;
				j <- length(supplyChain)-1;
				// find the building which must restock;
				loop while: j > 0 and sender = nil {
					if( order.building = supplyChain[j] ){
						sender <- supplyChain[j-1];
					}
					else{
						j <- j - 1;
					}
				}
			}
			i <- i + 1;
		}
		
		if( j = 1){// The provider must send new stock
			order.color <- "blue";
			ask Provider {
				do receiveOrder(order);
			}
		}
		else{// A warehouse must send new stock
			
			if( j = 2 ){
			order.color <- "green";
			}
			else if ( j = 3 ){
				order.color <- "orange";
			}
			else {
				order.color <- "red";
			}
			
			ask (sender as Warehouse) {
				do receiveRestockRequest(order);
			}
		}
		
		ask order {
			do die;
		}
	}
	
	/**
	 * When a logistic provider loose a customer (a FinalDestinationManager) he must update the stock on its warehouses
	 */
	action lostCustomer(FinalDestinationManager fdm){
		// Find the good supply chain
		int i <- 0;
		SupplyChain sc <- nil;
		loop while: i<length(supplyChains) and sc = nil {
			if(fdm = sc.fdm ){
				sc <- supplyChains[i];
			}
			i <- i + 1;
		}
		// Browse the different stock of the final dest
		loop stockFdm over: (fdm.building as Building).stocks {
			i <- 1;
			// Browse the warehouses of this supply chain 
			loop while: i < (length(sc.buildings)-1) {
				Warehouse w <- (sc.buildings[i] as Warehouse);
				int j <- 0;
				Stock stockW <- nil;
				// Browse the stocks of this warehouse and remove the outsourced stock
				loop while: j < length(w.stocks) {
					stockW <- w.stocks[j];
					if(stockW.fdm = fdm and stockW.product = stockFdm.product){
						// We update the occupied surface
						w.occupiedSurface <- w.occupiedSurface - stockW.maxQuantity;
						remove stockW from: w.stocks;
						ask stockW {
							do die;
						}
					}
					else {
						j <- j + 1;
					}
				}
				i <- i + 1;
			}
		}
		// Delete the associated supply chain
		ask sc {
			do die;
		}
	}
	
	/**
	 * When a logistic provider has a new customer, he need to find a new supply chain. This method build it.
	 */
	action getNewCustomer(FinalDestinationManager fdm){
		list<Building> supplyChain <- [];
		supplyChain <- supplyChain + provider.building;
		
		Warehouse small <- nil;
		Warehouse large <- nil;
		Warehouse average <- nil;
		
		loop while: small = large or small = average or large = average {
			small <- findSmallWarehouse(fdm);
			large <- findLargeWarehouse(fdm);
			average <- findAverageWarehouse(small, large, fdm);
		}
		
		do initStock(small, fdm);
		do initStock(large, fdm);
		do initStock(average, fdm);
		
		supplyChain <- supplyChain + large;
		supplyChain <- supplyChain + average;
		supplyChain <- supplyChain + small;
		
		usedWarehouses <- usedWarehouses + small;
		usedWarehouses <- usedWarehouses + large;
		usedWarehouses <- usedWarehouses + average;
		
		supplyChain <- supplyChain + fdm.building;
		
		// Add the new supply chain to others
		create SupplyChain number:1 returns:sc;
		ask sc {
			buildings <- supplyChain;
			myself.supplyChains <- myself.supplyChains + self;
			self.fdm <- fdm;
		}
		
		if(use_gs){
			if(use_r9){
				gs_add_node_attribute gs_sender_id:"supply_chain" gs_node_id:large.name gs_attribute_name:"type" gs_attribute_value:"large_warehouse";
				gs_add_node_attribute gs_sender_id:"supply_chain" gs_node_id:average.name gs_attribute_name:"type" gs_attribute_value:"average_warehouse";
				gs_add_node_attribute gs_sender_id:"supply_chain" gs_node_id:small.name gs_attribute_name:"type" gs_attribute_value:"small_warehouse";
				gs_add_node_attribute gs_sender_id:"supply_chain" gs_node_id:fdm.building.name gs_attribute_name:"type" gs_attribute_value:"final_dest";
			}
		}
	}
	
	/**
	 * We assume that the warehouse have already a stock when we initialize a new supply chain
	 */
	action initStock(Warehouse warehouse, FinalDestinationManager fdm){
		loop stockFdm over: (fdm.building as Building).stocks {
			// We create the stock agent
			create Stock number:1 returns:s {
				self.product <- stockFdm.product;
				self.quantity <- stockFdm.maxQuantity;
				self.maxQuantity <- stockFdm.maxQuantity;
				self.ordered <- false;
				self.building <- warehouse;
				self.fdm <- fdm;
				self.lp <- myself;
			}
			
			// and add it to the list of stocks in the warehouse
			warehouse.stocks <- warehouse.stocks + s[0];
			
			// Finally we update the occupied surface
			warehouse.occupiedSurface <- warehouse.occupiedSurface + stockFdm.maxQuantity;
		}
	}
	
	/**
	 * Return a small warehouse according to the position of the final destination : the more the warehouse is close to the final destination, the more he have a chance to be selected.
	 */
	Warehouse findSmallWarehouse(FinalDestinationManager fdm){
		list<Warehouse> lsw <- Warehouse sort_by (fdm distance_to each);
		int f <- ((rnd(10000)/10000)^6)*(length(lsw)-1);
		// I assume that there is always at least one warehouse which have a free space greater than the occupied surface of the stock to outsource.
		// According to results, it doesn't seem foolish.
		loop while:( (lsw[f] as Building).totalSurface - (lsw[f] as Building).occupiedSurface ) < (fdm.building as Building).occupiedSurface {
			f <- ((rnd(10000)/10000)^6)*(length(lsw)-1);
		}
		return lsw[f];/**/
		//return one_of(average_warehouse);
	}
	
	/**
	 * Return a large warehouse according to the position of the final destination : the more the warehouse has a big free surface, the more he have a chance to be selected.
	 */
	Warehouse findLargeWarehouse(FinalDestinationManager fdm){
		list<Warehouse> llw <- Warehouse sort_by (each.totalSurface-each.occupiedSurface);
		int f <- ((rnd(10000)/10000)^6)*(length(llw)-1);
		// I assume that there is always at least one warehouse which have a free space greater than the occupied surface of the stock to outsource.
		// According to results, it doesn't seem foolish.
		loop while:( (llw[(length(llw)-1) - f] as Building).totalSurface - (llw[(length(llw)-1) - f] as Building).occupiedSurface ) < (fdm.building as Building).occupiedSurface {
			f <- ((rnd(10000)/10000)^6)*(length(llw)-1);
		}
		return llw[(length(llw)-1) - f];/**/
		//return one_of(large_warehouse);
	}
	
	/**
	 * Return an average warehouse according to this formulae :
	 * - Let A be the small warehouse, B the average one that we are looking for, and C the large one.
	 * - Let ->AB the vector between the local warehouse and the average one.
	 * - Let ->CB be the vector between the large warehouse and the average one.
	 * So, we are trying to find B which minimize ||(->AB) + (->CB)||.
	 */
	Warehouse findAverageWarehouse(Warehouse small, Warehouse large, FinalDestinationManager fdm){
		list<Warehouse> law <- Warehouse;
		float min_euclidean_norm <-  -(2-252)*21023;// The max float value
		int min_index <- -1;
		int i <- 0;
		float x_s <- small.location.x;
		float y_s <- small.location.y;
		float x_l <- large.location.x;
		float y_l <- large.location.y;
		loop while: i < length(law) {
			if( ((law[i] as Building).totalSurface - (law[i] as Building).occupiedSurface ) > (fdm.building as Building).occupiedSurface ){
				float x_a <- (law[i] as Warehouse).location.x;
				float y_a <- (law[i] as Warehouse).location.y;
				float euclidean_norm <- sqrt( ((x_a-x_s) + (x_a-x_l))^2 + ((y_a-y_s) + (y_a-y_l))^2 );
				if(euclidean_norm < min_euclidean_norm){
					min_euclidean_norm <- euclidean_norm;
					min_index <- i;
				}
			}
			i <- i + 1;
		}
		if(min_index = -1){
			write "error : no average warehouse has been found";
		}
		return law[min_index];/**/
		//return one_of(average_warehouse);
	}
	
	aspect base { 
		draw square(1.5°km) color: rgb("green") ;
	} 
}