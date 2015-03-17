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
import "./Strategies.gaml"

species LogisticProvider schedules: [] {
	SupplyChain supplyChain <- nil;
	string color;
	int department;
	int region;
	list<int> timeToDeliver <- [];
	
	init {
		timeToDeliver <- [];
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
		Warehouse closeWarehouse <- findWarehouseLvl1(fdm, sizeOfStockLocalWarehouse);
		do initStock(closeWarehouse, fdm, sizeOfStockLocalWarehouse);

		// And next, we look if there is already this warehouse in the supply chain
		SupplyChainElement sceCloseWarehouse <- nil;
		bool found <- false;
		int i <- 0;
		loop while: i<length( (supplyChain.root as SupplyChainElement).sons) and sceCloseWarehouse = nil {
			int j <- 0;
			loop while: j<length( (supplyChain.root.sons[i] as SupplyChainElement).sons) and sceCloseWarehouse = nil {
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
				float p <- 0.0;
					using topology(road_network){
	                       p <-  (fdm.building.location distance_to sceCloseWarehouse.building.location);
	                }
					gs_add_edge_attribute gs_sender_id:"supply_chain" gs_edge_id:(fdm.building.name + sceCloseWarehouse.building.name) gs_attribute_name:"length" gs_attribute_value:p;
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
			if( ((sceLarge.building as Building).surfaceUsedForLH - (sceLarge.building as Building).occupiedSurface ) >= ((fdm.building as Building).occupiedSurface * sizeOfStockLargeWarehouse) ){
				found <- true;
				do initStock( (sceLarge.building as Warehouse), fdm, sizeOfStockLargeWarehouse);
			}
			i <- i + 1;
		}

		// If we have not found it in the large warehouses
		if(!found){
			// we must create one SCE
			// we find an appropriate large warehouse
			Warehouse largeWarehouse <- findWarehouseLvl3(fdm, sizeOfStockLargeWarehouse);

			do initStock(largeWarehouse, fdm, sizeOfStockLargeWarehouse);
			// and create a SCE
			create SupplyChainElement number:1 returns:sceBuild {
				self.supplyChain <- myself.supplyChain;
				self.position <- 1;
				self.building <- largeWarehouse;
				self.sons <- [];
				self.fathers <- [] + myself.supplyChain.root;
			}
			sceLarge <- sceBuild[0];
			supplyChain.root.sons <- supplyChain.root.sons + sceLarge;

			if(use_gs){
				if(use_r9){
					gs_add_node_attribute gs_sender_id:"supply_chain" gs_node_id:sceLarge.building.name gs_attribute_name:"type" gs_attribute_value:"large_warehouse";
					gs_add_edge gs_sender_id:"supply_chain" gs_edge_id:(sceLarge.building.name + provider.name) gs_node_id_from:sceLarge.building.name gs_node_id_to:provider.name gs_is_directed:false;
					float p <- 0.0;
					using topology(road_network){
	                       p <-  (sceLarge.building.location distance_to provider.location);
	                }
					gs_add_edge_attribute gs_sender_id:"supply_chain" gs_edge_id:(sceLarge.building.name + provider.name) gs_attribute_name:"length" gs_attribute_value:p;
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
				float p <- 0.0;
				using topology(road_network){
                       p <-  (sceCloseWarehouse.building.location distance_to sceLarge.building.location);
                }
				gs_add_edge_attribute gs_sender_id:"supply_chain" gs_edge_id:(sceCloseWarehouse.building.name + sceLarge.building.name) gs_attribute_name:"length" gs_attribute_value:p;
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
				self.building <- warehouse;
			}
			
			// and add it to the list of stocks in the warehouse
			warehouse.stocks <- warehouse.stocks + s[0];
			
			// Finally we update the occupied surface
			warehouse.occupiedSurface <- warehouse.occupiedSurface + (s[0] as Stock).maxQuantity;
		}
	}
	
	/**
	 * Return a warehouse of first level in the supply chain
	 */
	Warehouse findWarehouseLvl1(FinalDestinationManager fdm, int sizeOfStock){
		Warehouse w <- nil;
		if(adoptedStrategy = 1){
			w <- world.findWarehouseLvl1Strat1(fdm, sizeOfStock);
		}
		else if(adoptedStrategy = 2){
			w <- world.findWarehouseLvl1Strat2(fdm, sizeOfStock);
		}
		else if(adoptedStrategy = 3){
			w <- world.findWarehouseLvl1Strat3(fdm, sizeOfStock);
		}
		return w;
	}

	/**
	 * Return a warehouse of third level in the supply chain
	 */
	Warehouse findWarehouseLvl3(FinalDestinationManager fdm, int sizeOfStock){
		Warehouse w <- nil;
		if(adoptedStrategy = 1){
			w <- world.findWarehouseLvl3Strat1(fdm, sizeOfStock);
		}
		else if(adoptedStrategy = 2){
			w <- world.findWarehouseLvl3Strat2(fdm, sizeOfStock);
		}
		else if(adoptedStrategy = 3){
			w <- world.findWarehouseLvl3Strat3(fdm, sizeOfStock);
		}
		return w;
	}
	
	aspect base { 
		draw square(1.5°km) color: rgb("green") ;
	} 
}