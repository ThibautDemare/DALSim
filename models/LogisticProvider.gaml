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
import "./Parameters.gaml"

species LogisticProvider {
	SupplyChain supplyChain <- nil;
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
	
	reflex testRestockNeeded when: supplyChain != nil and ((time/3600.0) mod numberOfHoursBeforeTRN) = 0.0 and (time/3600.0) > 0 {
		ask supplyChain.leafs { 
			do recursiveTests([] as list<Order>);
		}
	}
	
	/**
	 * When a logistic provider loose a customer (a FinalDestinationManager) he must update the stock on its warehouses
	 */
	action lostCustomer(FinalDestinationManager fdm){
		// Find the good SCE
		int i <- 0;
		SupplyChainElement sceLeaf <- nil;
		loop while: i<length(supplyChain.leafs) and sceLeaf = nil {
			if(fdm.building = ((supplyChain.leafs[i] as SupplyChainElement).building )){
				sceLeaf <- supplyChain.leafs[i];
			}
			i <- i + 1;
		}
		// Delete the stocks which belong to the FDM, in the warehouses of the supply chain
		// Also, find the SCE which are not still used
		list<SupplyChainElement> sceToDelete <- [];
		loop sceClose over: sceLeaf.fathers {
			Building b1 <- (sceClose as SupplyChainElement).building;
			do deleteStock(fdm, b1);
			
			if(isUseless(sceClose.building)){
				sceToDelete <- sceToDelete + sceClose;
			}
			
			loop sceLarge over: sceClose.fathers {
				Building b2 <- (sceLarge as SupplyChainElement).building;
				do deleteStock(fdm, b2);
				
				if(isUseless(sceLarge.building)){
					sceToDelete <- sceToDelete + sceLarge;
				}
			}
			
			if(use_gs){
				if(use_r9){
					gs_remove_edge gs_sender_id:"supply_chain" gs_edge_id:(fdm.name + sceClose.building.name);
				}
			}
		}
		
		// And finally remove these useless SCE from the SC
		do removeSCE(sceToDelete);
	}
	
	/**
	 * Remove a SupplyChainElement from the SupplyChain of the current LogisticProvider
	 */
	action removeSCE(list<SupplyChainElement> sceToDelete){
		loop while: !empty(sceToDelete){
			SupplyChainElement sce <- first(sceToDelete);
			// Delete this sce in his fathers
			loop father over:sce.fathers {
				int j <- 0;
				bool found <- false;
				loop while: j < length(father.sons) and !found {
					if(father.sons[j] = sce){
						found <- true;
					}
					else {
						j <- j + 1;
					}
				}
				remove index: j from: father.sons;
				
				if(use_gs){
					if(use_r9){
						gs_remove_edge gs_sender_id:"supply_chain" gs_edge_id:(sce.building.name + father.building.name);
					}
				}
			}
			// Delete this sce in his sons
			loop son over:sce.sons {
				int j <- 0;
				bool found <- false;
				loop while: j < length(son.fathers) and !found {
					if(son.fathers[j] = sce){
						found <- true;
					}
					else {
						j <- j + 1;
					}
				}
				remove index: j from: son.fathers;
				
				if(use_gs){
					if(use_r9){
						gs_remove_edge gs_sender_id:"supply_chain" gs_edge_id:(son.building.name + sce.building.name);
					}
				}
			}
			remove index:0 from: sceToDelete;
			ask sce {
				do die;
			}
		}
	}
	
	/**
	 * Check if a building have still some stock managed by the current logistic provider.
	 * If there is not, it means that the building is useless in the supply chain.
	 */
	bool isUseless(Building b){
		// Watch if this warehouse is useful or not
		int j <- 0;
		bool isUseless <- true;
		loop while: j < length(b.stocks) and isUseless {
			Stock stock <- b.stocks[j];
			if(stock.lp = self){
				isUseless <- false;
			}
			j <- j + 1;
		}
		return isUseless;
	}
	
	/**
	 * Delete all the stocks of a given FinalDestinationManager in a given building
	 */
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
		 * Initiate the supply chain with just the provider as root
		 */
		if(supplyChain = nil){
			// Build the root of this almost-tree
			create SupplyChainElement number:1 returns:rt {
				building <- provider;
				sons <- [];
				position <- 0;
			}
			// and build the supply chain with this root
			create SupplyChain number:1 returns:sc {
				logisticProvider <- myself;
				root <- rt[0];
			}
			supplyChain <- first(sc);
			first(rt).supplyChain <- supplyChain;
			
			if(use_gs){
				if(use_r9){
					gs_add_node_attribute gs_sender_id:"supply_chain" gs_node_id:provider.name gs_attribute_name:"type" gs_attribute_value:"provider";
				}
			}
		}
		
		/*
		 * The new customer become a new leaf of the "almost-tree" supply chain.
		 */
		create SupplyChainElement number:1 returns:fdmLeaf {
			self.building <- fdm.building;
			self.sons <- [];
			self.supplyChain <- myself.supplyChain;
			position <- 3;
		}
		supplyChain.leafs <- supplyChain.leafs + fdmLeaf[0];
		if(use_gs){
			if(use_r9){
				gs_add_node_attribute gs_sender_id:"supply_chain" gs_node_id:fdm.name gs_attribute_name:"type" gs_attribute_value:"final_dest";
			}
		}
			
		/*
		 * connect this leaf to a close warehouse
		 */
		// First we find an appropriate local warehouse
		Warehouse closeWarehouse <- findCloseWarehouse(fdm, sizeOfStockLocalWarehouse);
		do initStock(closeWarehouse, fdm, sizeOfStockLocalWarehouse);
		
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
				self.supplyChain <- myself.supplyChain;
				position <- 2;
				building <- closeWarehouse;
				sons <- [] + fdmLeaf;
				fathers <- [];
				(fdmLeaf[0] as SupplyChainElement).fathers <- [] + self;
			}
			sceCloseWarehouse <- sceBuild[0];
			
			if(use_gs){
				if(use_r9){
					gs_add_node_attribute gs_sender_id:"supply_chain" gs_node_id:sceCloseWarehouse.building.name gs_attribute_name:"type" gs_attribute_value:"close_warehouse";
				}
			}
		}
		else{
			// We must update the fathers of the leaf and the sons of the close warehouse
			sceCloseWarehouse.sons <- sceCloseWarehouse.sons + fdmLeaf[0];
			(fdmLeaf[0] as SupplyChainElement).fathers <- [] + sceCloseWarehouse;
		}
		
		if(use_gs){
			if(use_r9){
				gs_add_edge gs_sender_id:"supply_chain" gs_edge_id:(fdm.name + sceCloseWarehouse.building.name) gs_node_id_from:fdm.name gs_node_id_to:sceCloseWarehouse.building.name gs_is_directed:false;
			}
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
			if( ((sceLarge.building as Building).totalSurface - (sceLarge.building as Building).occupiedSurface ) >= ((fdm.building as Building).occupiedSurface * sizeOfStockLargeWarehouse) ){
				found <- true;
				do initStock( (sceLarge.building as Warehouse), fdm, sizeOfStockLargeWarehouse);
			}
			i <- i + 1;
		}
		// If we have not found it in the large warehouses
		if(!found){
			// we must create one SCE
			// we find an appropriate large warehouse
			Warehouse largeWarehouse <- findLargeWarehouse(fdm, sizeOfStockLargeWarehouse);
			do initStock(largeWarehouse, fdm, sizeOfStockLargeWarehouse);
			// and create a SCE
			create SupplyChainElement number:1 returns:sceBuild {
				self.supplyChain <- myself.supplyChain;
				position <- 1;
				building <- largeWarehouse;
				sons <- [];
				fathers <- [] + myself.supplyChain.root;
			}
			sceLarge <- sceBuild[0];
			supplyChain.root.sons <- supplyChain.root.sons + sceLarge;
			
			if(use_gs){
				if(use_r9){
					gs_add_node_attribute gs_sender_id:"supply_chain" gs_node_id:sceLarge.building.name gs_attribute_name:"type" gs_attribute_value:"large_warehouse";
					gs_add_edge gs_sender_id:"supply_chain" gs_edge_id:(sceLarge.building.name + provider.name) gs_node_id_from:sceLarge.building.name gs_node_id_to:provider.name gs_is_directed:false;
				}
			}
		}
		// and then this father become the real father of this close warehouse
		found <- false;
		i <- 0;
		loop while: i<length(sceCloseWarehouse.fathers) and !found {
			if(sceCloseWarehouse.fathers[i] = sceLarge){
				found <- true;
			}
			i <- i + 1;
		}
		if(!found){
			sceCloseWarehouse.fathers <- sceCloseWarehouse.fathers + sceLarge;
		}
		
		found <- false;
		i <- 0;
		loop while: i<length(sceLarge.sons) and !found {
			if(sceLarge.sons[i] = sceCloseWarehouse){
				found <- true;
			}
			i <- i + 1;
		}
		if(!found){
			sceLarge.sons <- sceLarge.sons + sceCloseWarehouse;
		}
		
		if(use_gs){
			if(use_r9){
				gs_add_edge gs_sender_id:"supply_chain" gs_edge_id:(sceCloseWarehouse.building.name + sceLarge.building.name) gs_node_id_from:sceCloseWarehouse.building.name gs_node_id_to:sceLarge.building.name gs_is_directed:false;
			}
		}
	}
	
	/**
	 * We assume that the warehouse have already a stock when we initialize a new supply chain
	 */
	action initStock(Warehouse warehouse, FinalDestinationManager fdm, int sizeOfStock){
		loop stockFdm over: (fdm.building as Building).stocks {
			// We create the stock agent
			create Stock number:1 returns:s {
				self.product <- stockFdm.product;
				self.quantity <- stockFdm.maxQuantity * sizeOfStock;
				self.maxQuantity <- stockFdm.maxQuantity * sizeOfStock;
				self.status <- 0;
				self.fdm <- fdm;
				self.lp <- myself;
			}
			
			// and add it to the list of stocks in the warehouse
			warehouse.stocks <- warehouse.stocks + s[0];
			
			// Finally we update the occupied surface
			warehouse.occupiedSurface <- warehouse.occupiedSurface + (s[0] as Stock).maxQuantity;
		}
	}
	
	/**
	 * Return a small warehouse according to the position of the final destination : the more the warehouse is close to the final destination, the more he has a chance to be selected.
	 */
	Warehouse findCloseWarehouse(FinalDestinationManager fdm, int sizeOfStock){
		list<Warehouse> lsw <- Warehouse sort_by (fdm distance_to each);
		int f <- ((rnd(10000)/10000)^32)*(length(lsw)-1);
		// I assume that there is always at least one warehouse which have a free space greater than the occupied surface of the stock to outsource.
		// According to results, it doesn't seem foolish.
		loop while:
				( (lsw[f] as Building).totalSurface - (lsw[f] as Building).occupiedSurface)	< (fdm.building as Building).occupiedSurface * sizeOfStock {
			f <- ((rnd(10000)/10000)^32)*(length(lsw)-1);
		}
		return lsw[f];/**/
		//return one_of(average_warehouse);
	}
	
	/**
	 * Return a large warehouse : the more the warehouse has a big free surface, the more he has a chance to be selected.
	 */
	Warehouse findLargeWarehouse(FinalDestinationManager fdm, int sizeOfStock){
		list<Warehouse> llw <- Warehouse sort_by (each.totalSurface-each.occupiedSurface);
		int f <- ((rnd(10000)/10000)^32)*(length(llw)-1);
		// I assume that there is always at least one warehouse which have a free space greater than the occupied surface of the stock to outsource.
		// According to results, it doesn't seem foolish.
		loop while:( (llw[(length(llw)-1) - f] as Building).totalSurface - (llw[(length(llw)-1) - f] as Building).occupiedSurface ) < ((fdm.building as Building).occupiedSurface * sizeOfStock) {
			f <- ((rnd(10000)/10000)^32)*(length(llw)-1);
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
	Warehouse findAverageWarehouse(Warehouse small, Warehouse large, FinalDestinationManager fdm, int sizeOfStock){
		list<Warehouse> law <- Warehouse;
		float min_euclidean_norm <-  -(2-252)*21023;// The max float value
		int min_index <- -1;
		int i <- 0;
		float x_s <- small.location.x;
		float y_s <- small.location.y;
		float x_l <- large.location.x;
		float y_l <- large.location.y;
		loop while: i < length(law) {
			if( ((law[i] as Building).totalSurface - (law[i] as Building).occupiedSurface ) > (fdm.building as Building).occupiedSurface * sizeOfStock ){
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