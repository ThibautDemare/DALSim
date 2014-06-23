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

species LogisticProvider {
	SupplyChain supplyChain <- nil;
	list<SupplyChainElement> leafs <- [];
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
	/*reflex testOrdersNeeded when: ((time/3600.0) mod 24.0) = 0.0 { //An order is possible one time by day.
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
	}/**/
	
	
	/**
	 * Check for all product if it needs to be restock.
	 * If yes, an order is made to the logistic provider
	 */
	/*reflex testOrdersNeeded when: ((time/3600.0) mod numberOfHoursBeforeTON) = 0.0 { //An order is possible one time by day. 
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
					//do receiveOrder(first(b));
				}

			}
		}
	}/**/
	
	/**
	 * 
	 */
	/*action receiveOrder(Order order){
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
	}/**/
	
	/**
	 * When a logistic provider loose a customer (a FinalDestinationManager) he must update the stock on its warehouses
	 */
	action lostCustomer(FinalDestinationManager fdm){
		// Find the good SCE
		int i <- 0;
		SupplyChainElement sceLeaf <- nil;
		loop while: i<length(leafs) and sceLeaf = nil {
			if(fdm = ((leafs[i] as SupplyChainElement).building )){
				sceLeaf <- leafs[i];
			}
			i <- i + 1;
		}
		
		loop sceClose over: sceLeaf.fathers {
			Building b1 <- (sceClose as SupplyChainElement).building;
			do deleteStock(fdm, b1);
			
			loop sceLarge over: sceClose.fathers {
				Building b2 <- (sceLarge as SupplyChainElement).building;
				do deleteStock(fdm, b2);
			}
		}
	}
	
	action deleteStock(FinalDestinationManager fdm, Building b){
		loop stockFdm over: (fdm.building as Building).stocks {	
			int i <- 0;
			Stock stockW <- nil;
			// Browse the stocks of this warehouse and remove the outsourced stock
			loop while: i < length(b.stocks) {
				stockW <- b.stocks[i];
				if(stockW.fdm = fdm and stockW.product = stockFdm.product){
					// We update the occupied surface
					b.occupiedSurface <- b.occupiedSurface - stockW.maxQuantity;
					remove stockW from: b.stocks;
					ask stockW {
						do die;
					}
				}
				else {
					i <- i + 1;
				}
			}
		}
	}
	
	/**
	 * When a logistic provider has a new customer, he need to find a new supply chain. This method build it.
	 */
	action getNewCustomer(FinalDestinationManager fdm){
		/*
		 * If the supply chain has not been initiated yet.
		 */
		if(supplyChain = nil){
			// Build the root of this almost-tree
			create SupplyChainElement number:1 returns:rt {
				building <- provider;
				sons <- [];
			}
			// and build the supply chain with this root
			create SupplyChain number:1 returns:sc {
				root <- rt[0];
			}
		}
		
		/*
		 * The new customer become a new leaf of the "almost-tree" supply chain.
		 */
		create SupplyChainElement number:1 returns:fdmLeaf {
			self.building <- fdm.building;
			self.sons <- [];
		}
		leafs <- leafs + fdmLeaf[0];
		
		/*
		 * connect this leaf to a close warehouse
		 */
		// First we find an appropriate local warehouse
		Warehouse closeWarehouse <- findCloseWarehouse(fdm);
		do initStock(closeWarehouse, fdm);
		
		// And next, we look if there is already this warehouse in the supply chain
		SupplyChainElement sceCloseWarehouse <- nil;
		bool found <- false;
		int i <- 0;
		loop while: i<length( (supplyChain.root as SupplyChainElement).sons) and sceCloseWarehouse != nil {
			int j <- 0;
			loop while: j<length( (supplyChain.root.sons[i] as SupplyChainElement).sons) and sceCloseWarehouse != nil {
				if(closeWarehouse = ((supplyChain.root.sons[i] as SupplyChainElement).sons[j] as SupplyChainElement).building){
					sceCloseWarehouse <- (supplyChain.root.sons[i] as SupplyChainElement).sons[j];
				}
				j <- j + 1;
			}
			i <- i + 1;
		}
		// If there is not already this SCE
		if(sceCloseWarehouse = nil){
			// We must create a SCE corresponding to this warehouse
			create SupplyChainElement number:1 returns:sceBuild {
				building <- closeWarehouse;
				sons <- [] + fdmLeaf;
				fathers <- [];
				(fdmLeaf[0] as SupplyChainElement).fathers <- [] + self;
			}
			sceCloseWarehouse <- sceBuild[0];
		}
		else{
			// We must update the fathers of the leaf and the sons of the close warehouse
			sceCloseWarehouse.sons <- sceCloseWarehouse.sons + fdmLeaf[0];
			(fdmLeaf[0] as SupplyChainElement).fathers <- [] + sceCloseWarehouse;
		}
		
		/*
		 * Connect the close warehouse to the large warehouse
		 */
		// We try to find a father who has an appropriate surface
		SupplyChainElement sceLarge <- nil;
		found <- false;
		int i <- 0;
		loop while: i<length(supplyChain.root.sons) and !found {
			sceLarge <- supplyChain.root.sons[i];
			if( ((sceLarge.building as Building).totalSurface - (sceLarge.building as Building).occupiedSurface ) >= (fdm.building as Building).occupiedSurface ){
				found <- true;
			}
			i <- i + 1;
		}
		// If we have not found it in the large warehouses
		if(!found){
			// we must create one SCE
			// we find an appropriate large warehouse
			Warehouse largeWarehouse <- findLargeWarehouse(fdm);
			do initStock(largeWarehouse, fdm);
			// and create a SCE
			create SupplyChainElement number:1 returns:sceBuild {
				building <- largeWarehouse;
				sons <- [];
				fathers <- [] + myself.supplyChain.root;
			}
			sceLarge <- sceBuild[0];
		}
		// and then this father become the real father of this close warehouse
		sceCloseWarehouse.fathers <- sceCloseWarehouse.fathers + sceLarge;
		sceLarge.sons <- sceLarge.sons + sceCloseWarehouse;
		
		
		/*
		if(use_gs){
			if(use_r9){
				gs_add_node_attribute gs_sender_id:"supply_chain" gs_node_id:large.name gs_attribute_name:"type" gs_attribute_value:"large_warehouse";
				gs_add_node_attribute gs_sender_id:"supply_chain" gs_node_id:average.name gs_attribute_name:"type" gs_attribute_value:"average_warehouse";
				gs_add_node_attribute gs_sender_id:"supply_chain" gs_node_id:small.name gs_attribute_name:"type" gs_attribute_value:"small_warehouse";
				gs_add_node_attribute gs_sender_id:"supply_chain" gs_node_id:fdm.building.name gs_attribute_name:"type" gs_attribute_value:"final_dest";
			}
		}/**/
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
	Warehouse findCloseWarehouse(FinalDestinationManager fdm){
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