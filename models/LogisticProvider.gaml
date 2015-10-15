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
	
	list<SupplyChainElement> lvl1Warehouses <- [];
	list<SupplyChainElement> lvl2Warehouses <- [];

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



	/*
	 * These methods are used to remove a customer and disconnect him of the supply chain
	 */

	/**
	 * When a logistic provider loose a customer (a FinalDestinationManager) he must update the stock on its warehouses
	 */
	action lostCustomer(FinalDestinationManager fdm){
		/*
		 * Browse the warehouses to get the stocks to remove and the list of warehouses which could be deleted from the supply chain
		 */
		int i <- 0;
		list<Warehouse> uselessWarehouses <- [];
		list<Stock> stockRemoved <- [];
		loop while: i < length(lvl1Warehouses) {
			int j <- 0;
			list<Stock> temp_stocks <- (lvl1Warehouses[i] as Warehouse).stocks;
			bool useless <- true;
			loop while: j < length(temp_stocks) {
				if(temp_stocks[j].fdm = fdm and temp_stocks[j].lp = self){
					stockRemoved <- stockRemoved + temp_stocks[j];
					remove index: j from: (lvl1Warehouses[i] as Warehouse).stocks;
				}
				else {
					// if the current stock is managed by the current LP, but does not belong to the FDM, then it means that this warehouse is useful
					if(temp_stocks[j].lp = self){
						useless <- false;
					}
					j <- j + 1;
				}
			}
			if(useless){
				uselessWarehouses <- uselessWarehouses + lvl1Warehouses[i];
				remove index: i from: lvl1Warehouses;
			}
			else {
				i <- i + 1;
			}
		}

		// I wanted to make a mathod in order to not duplicate the following code, unfortunately, I can't return both the list of useless warehouse and of stocks...
		// It is ugly... I know and I feel ashamed!
		i <- 0;
		loop while: i < length(lvl2Warehouses) {
			int j <- 0;
			list<Stock> temp_stocks <- (lvl2Warehouses[i] as Warehouse).stocks;
			bool useless <- true;
			loop while: j < length(temp_stocks) {
				if(temp_stocks[j].fdm = fdm and temp_stocks[j].lp = self){
					stockRemoved <- stockRemoved + temp_stocks[j];
					remove index: j from: (lvl2Warehouses[i] as Warehouse).stocks;
				}
				else {
					// if the current stock is managed by the current LP, but does not belong to the FDM, then it means that this warehouse is useful
					if(temp_stocks[j].lp = self){
						useless <- false;
					}
					j <- j + 1;
				}
			}
			if(useless){
				uselessWarehouses <- uselessWarehouses + lvl2Warehouses[i];
				remove index: i from: lvl2Warehouses;
			}
			else {
				i <- i + 1;
			}
		}

		/*
		 * Delete the useless SupplyChainElement and the supply chain itself if there is no more customer
		 */
		list<SupplyChainElement> uselessSCE <- deleteUselessSCE(supplyChain.root, fdm, uselessWarehouses);
		loop while: 0 < length(uselessSCE) {
			ask uselessSCE[0] {
				do die;
			}
			remove index: 0 from: uselessSCE;
		}
		if(length(supplyChain.root.sons) = 0){
			ask supplyChain.root {
				do die;
			}
			ask supplyChain {
				do die;
			}
			supplyChain <- nil;
		}
	}

	/*
	 * A recursive method which browse the supply chain and delete the useless supply chain elements from the leafs to the root
	 */
	list<SupplyChainElement> deleteUselessSCE(SupplyChainElement sce, FinalDestinationManager fdm, list<Warehouse> uselessWarehouses){
		int i <- 0;
		list<SupplyChainElement> uselessSCE <- [];
		loop while: i < length(sce.sons) {
			uselessSCE <- uselessSCE + deleteUselessSCE(sce.sons[i], fdm, uselessWarehouses);
			if(uselessSCE contains sce.sons[i]){
				remove index: i from: sce.sons;
			}
			else {
				i <- i + 1;
			}
		}
		if(uselessWarehouses contains sce or sce.building = fdm.building){
			return uselessSCE + sce;
		}
		return uselessSCE;
	}



	/*
	 * These methods are used to connect a new customer to the supply chain
	 */

	action connectRoot {
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

	SupplyChainElement connectCustomer(FinalDestinationManager fdm) {
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
		return fdmLeaf[0];
	}

	SupplyChainElement connectLvl1Warehouse(FinalDestinationManager fdm, SupplyChainElement fdmLeaf) {
		// First we find an appropriate local warehouse
		Warehouse closeWarehouse <- findWarehouseLvl1(fdm, sizeOfStockLocalWarehouse);
		if(! (lvl1Warehouses contains closeWarehouse)){
			lvl1Warehouses <- lvl1Warehouses + closeWarehouse;
		}
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
				fdmLeaf.fathers <- [] + self;
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
			sceCloseWarehouse.sons <- sceCloseWarehouse.sons + fdmLeaf;
			fdmLeaf.fathers <- [] + sceCloseWarehouse;
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

		return sceCloseWarehouse;
	}

	action connectLvl2Warehouse(FinalDestinationManager fdm, SupplyChainElement sceCloseWarehouse){
		// We try to find a father who has an appropriate surface
		SupplyChainElement sceLarge <- nil;
		bool found <- false;
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
			Warehouse largeWarehouse <- findWarehouseLvl2(fdm, sizeOfStockLargeWarehouse);
			if(! (lvl2Warehouses contains largeWarehouse)){
				lvl2Warehouses <- lvl1Warehouses + largeWarehouse;
			}
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
	 * When a logistic provider has a new customer, he needs to find a new supply chain. This method build it.
	 */
	action getNewCustomer(FinalDestinationManager fdm){

		/*
		 * Initiate the supply chain with just the provider as root
		 */
		if(supplyChain = nil){
			do connectRoot;
		}

		/*
		 * The new customer become a new leaf of the "almost-tree" supply chain.
		 */
		SupplyChainElement fdmLeaf <- connectCustomer(fdm);

		/*
		 * connect this leaf to a close warehouse
		 */
		SupplyChainElement sceCloseWarehouse <- connectLvl1Warehouse(fdm, fdmLeaf);

		/*
		 * Connect the close warehouse to the large warehouse
		 */
		do connectLvl2Warehouse(fdm, sceCloseWarehouse);

	}
	
	/**
	 * We assume that the warehouse have already a stock when we initialize a new supply chain
	 */
	action initStock(Warehouse warehouse, FinalDestinationManager fdm, int sizeOfStock){
		loop stockFdm over: (fdm.building as Building).stocks {
			// We create the stock agent
			create Stock number:1 returns:s {
				self.product <- stockFdm.product;
				self.quantity <- rnd(stockFdm.maxQuantity * sizeOfStock);
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
			w <- world.findWarehouseLvl1Strat1(fdm, sizeOfStock, lvl1Warehouses, lvl2Warehouses);
		}
		else if(adoptedStrategy = 2){
			w <- world.findWarehouseLvl1Strat2(fdm, sizeOfStock, lvl1Warehouses, lvl2Warehouses);
		}
		else if(adoptedStrategy = 3){
			w <- world.findWarehouseLvl1Strat3(fdm, sizeOfStock, lvl1Warehouses, lvl2Warehouses);
		}
		return w;
	}

	/**
	 * Return a warehouse of third level in the supply chain
	 */
	Warehouse findWarehouseLvl2(FinalDestinationManager fdm, int sizeOfStock){
		Warehouse w <- nil;
		if(adoptedStrategy = 1){
			w <- world.findWarehouseLvl2Strat1(fdm, sizeOfStock, lvl1Warehouses, lvl2Warehouses);
		}
		else if(adoptedStrategy = 2){
			w <- world.findWarehouseLvl2Strat2(fdm, sizeOfStock, lvl1Warehouses, lvl2Warehouses);
		}
		else if(adoptedStrategy = 3){
			w <- world.findWarehouseLvl2Strat3(fdm, sizeOfStock, lvl1Warehouses, lvl2Warehouses);
		}
		return w;
	}
	
	aspect base { 
		draw square(1.5°km) color: rgb("green") ;
	}
}