model LogisticsServiceProvider

import "Provider.gaml"
import "SupplyChain.gaml"
import "TransferredStocks.gaml"
import "Strategies.gaml"

species LogisticsServiceProvider {
	int timeShifting <- rnd(23);
	int adoptedSelectingWarehouseStrategy;
	SupplyChain supplyChain <- nil;
	list<int> timeToDeliver <- [];
	list<Warehouse> lvl1Warehouses <- []; // close warehouse
	list<Warehouse> lvl2Warehouses <- []; // large warehouse
	list<FinalDestinationManager> customers <- [];
	Provider provider;
	float cumulateCosts <- 0;
	float averageCosts <- 0;
	float threshold;
	float probaAnt <- 0.5;
	string costsPathStrategy <- one_of(['financial_costs']);//'financial_costs';//'travel_time'//'financial_costs','travel_time'
	
	init {
		adoptedSelectingWarehouseStrategy <- one_of(possibleSelectingWarehouseStrategies);
		provider <- one_of(Provider);
		ask provider {
			do addCustomer(myself);
		}

		if(localThreshold) {
			threshold <- rnd(minlocalThreshold, maxlocalThreshold);//truncated_gauss({minlocalThreshold, maxlocalThreshold});
		}
		else {
			threshold <- globalThreshold;
		}

		timeToDeliver <- [];
		if(use_gs){
			// Add a new node event for corresponding sender
			if(use_r1){
				gs_add_node gs_sender_id:"actor" gs_node_id:name;
			}
			if(use_r2){
				gs_add_node gs_sender_id:"neighborhood_all" gs_node_id:name;
				gs_add_node_attribute gs_sender_id:"neighborhood_all" gs_node_id:name gs_attribute_name:"type" gs_attribute_value:"logistic_provider";
			}
			if(use_r5){
				gs_add_node gs_sender_id:"neighborhood_logistic_provider" gs_node_id:name;
			}
			if(use_r7){
				gs_add_node gs_sender_id:"neighborhood_logistic_final" gs_node_id:name;
			}
		}
	}

	reflex testRestockNeeded when: supplyChain != nil and (((time/3600.0) + timeShifting) mod nbStepsbetweenTRN) = 0.0 and (time/3600.0) > 0 {
		ask supplyChain.leafs { 
			do recursiveTests([] as list<Order>);
		}
	}

	action updateSupplyChainProvider {
		// Select (or not) a new provider
		Provider LHP <- nil;
		Provider AntP <- nil;
		ask Provider {
			if(self.port = "LE HAVRE"){
				LHP <- self;
			}
			else{
				AntP <- self;
			}
		}
		bool update <- false;
		if(flip(probaAnt)){
			if(AntP != provider){
				ask provider {
					do lostCustomer(myself);
				}
				provider <- AntP;
				update <- true;
				ask provider {
					do addCustomer(myself);
				}
			}
		}
		else {
			if(LHP != provider){
				ask provider {
					do lostCustomer(myself);
				}
				provider <- LHP;
				update <- true;
				ask provider {
					do addCustomer(myself);
				}
			}
		}
		// Do I need to update ?
		if(update and supplyChain != nil){
			// Update the supply chain according to this new provider
			create SupplyChainElement number:1 returns:rt {
				supplyChain <- myself.supplyChain;
				building <- myself.provider;
				sons <- [];
				position <- 0;
			}
			SupplyChainElement newRoot <- rt[0];
			int j <- 0;
			loop while: j<length(supplyChain.root.sons) {
				int i <- 0;
				loop while: i < length(supplyChain.root.sons[j].fathers) {
					if(supplyChain.root.sons[j].fathers[i].building = supplyChain.root.building){
						supplyChain.root.sons[j].fathers[i] <- newRoot;
						newRoot.sons <- newRoot.sons + supplyChain.root.sons[j];
					}
					i <- i + 1;
				}
				j <- j + 1;
			}
			supplyChain.root <- newRoot;
		}
	}

	/*
	 * This method looks for the warehouse of his supply chain which need to be restocked
	 */
	action manageLostStock(AwaitingStock aws) {
		list<Warehouse> lw;
		if(aws.position = 1){
			lw <- lvl2Warehouses;
		}
		else {
			lw <- lvl1Warehouses;
		}
		int i <- 0;
		bool notfound <- true;
		loop while: i < length(lw) and notfound {
			Warehouse w <- lw[i];
			int j <- 0;
			loop while: j < length(w.stocks) and notfound {
				if(aws.stock.product = w.stocks[j].product and w.stocks[j].lp = self and aws.stock.fdm = w.stocks[j].fdm){	
					create Commodity number:1 returns:returnedAgent;
					Commodity commodity <- returnedAgent[0];
					commodity.stock <- aws.stock;
					commodity.volume <- aws.stock.quantity;
					commodity.finalDestination <- w;
					commodity.stepOrderMade <- aws.stepOrderMade;
					aws.building.leavingCommodities <- aws.building.leavingCommodities + commodity;
					ask forwardingAgent {
						commodity.paths <- compute_shortest_path(aws.building, w, myself.costsPathStrategy, commodity);//'financial_costs'//travel_time
					}
					notfound <- false;
				}
				j <- j + 1;
			}
			i <- i + 1;
		}
	}



	/*
	 * These methods are used to remove a customer and disconnect him of the supply chain
	 */

	/**
	 * When a logistic provider loose a customer (a FinalDestinationManager) he must update the stock on its warehouses
	 */
	TransferredStocks lostCustomer(FinalDestinationManager fdm){
		int k <- 0;
		bool notfound <- true;
		loop while: k < length(customers) and notfound {
			if(fdm = customers[k]){
				remove index: k from: customers;
				notfound <- false;
			}
			else{
				k <- k + 1;
			}
		}
		/*
		 * Browse the warehouses to get the stocks to remove and the list of warehouses which could be deleted from the supply chain
		 */
		int i <- 0;
		list<Warehouse> uselessWarehouses <- [];
		TransferredStocks stocksRemoved;
		create TransferredStocks number: 1 returns: rts;
		stocksRemoved <- rts[0];
		loop while: i < length(lvl1Warehouses) {
			int j <- 0;
			list<Stock> temp_stocks <- (lvl1Warehouses[i] as Warehouse).stocks;
			bool useless <- true;
			loop while: j < length(temp_stocks) {
				if(temp_stocks[j].fdm = fdm and temp_stocks[j].lp = self){
					(lvl1Warehouses[i] as Warehouse).occupiedSurface <- (lvl1Warehouses[i] as Warehouse).occupiedSurface - temp_stocks[j].maxQuantity;
					stocksRemoved.stocksLvl1 <- stocksRemoved.stocksLvl1 + temp_stocks[j];
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
					(lvl2Warehouses[i] as Warehouse).occupiedSurface <- (lvl2Warehouses[i] as Warehouse).occupiedSurface - temp_stocks[j].maxQuantity;
					stocksRemoved.stocksLvl2 <- stocksRemoved.stocksLvl2 + temp_stocks[j];
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
				if(building != myself.provider and building != fdm.building){
					(building as RestockingBuilding).maxProcessOrdersCapacity <- (building as RestockingBuilding).maxProcessOrdersCapacity - 5;
				}
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

		return stocksRemoved;
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
		if(sce.building = fdm.building){
			remove sce from: sce.supplyChain.leafs;
		}
		if(uselessWarehouses contains sce.building or sce.building = fdm.building){
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
			building <- myself.provider;
			(building as RestockingBuilding).maxProcessOrdersCapacity <- (building as RestockingBuilding).maxProcessOrdersCapacity + 5;
			sons <- [];
			position <- 0;
		}
		// and build the supply chain with this root
		create SupplyChain number:1 returns:sc {
			logisticsServiceProvider <- myself;
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

	SupplyChainElement connectLvl1Warehouse(FinalDestinationManager fdm, SupplyChainElement fdmLeaf, list<Stock> stocksLvl1) {
		// First we find an appropriate local warehouse
		Warehouse closeWarehouse <- findWarehouseLvl1(fdm, sizeOfStockLocalWarehouse);
		do initStock(closeWarehouse, fdm, stocksLvl1, sizeOfStockLocalWarehouse);
		SupplyChainElement sceCloseWarehouse <- nil;

		if(!(lvl1Warehouses contains closeWarehouse)){
			lvl1Warehouses <- lvl1Warehouses + closeWarehouse;
			// We must create a SCE corresponding to this warehouse
			create SupplyChainElement number:1 returns:sceBuild {
				self.supplyChain <- myself.supplyChain;
				position <- 2;
				building <- closeWarehouse;
				sons <- [] + fdmLeaf;
				fathers <- [];
			}
			sceCloseWarehouse <- sceBuild[0];

			if(use_gs){
				if(use_r9){
					gs_add_node_attribute gs_sender_id:"supply_chain" gs_node_id:sceCloseWarehouse.building.name gs_attribute_name:"type" gs_attribute_value:"close_warehouse";
				}
			}
		}
		else{
			// The selected warehouse exists already in the supply chain. We must find it
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

			// We must update the fathers of the leaf and the sons of the close warehouse
			sceCloseWarehouse.sons <- sceCloseWarehouse.sons + fdmLeaf;

		}

		fdmLeaf.fathers <- [] + sceCloseWarehouse;

		ask sceCloseWarehouse {
			(building as RestockingBuilding).maxProcessOrdersCapacity <- (building as RestockingBuilding).maxProcessOrdersCapacity + 5;
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

	action connectLvl2Warehouse(FinalDestinationManager fdm, SupplyChainElement sceCloseWarehouse, list<Stock> stocksLvl2){
		// We try to find a father who has an appropriate surface
		SupplyChainElement sceLarge <- nil;
		bool found <- false;
		int i <- 0;
		loop while: i<length(supplyChain.root.sons) and !found {
			sceLarge <- supplyChain.root.sons[i];
			if( ((sceLarge.building as Building).totalSurface - (sceLarge.building as Building).occupiedSurface ) >= ((fdm.building as Building).occupiedSurface * sizeOfStockLargeWarehouse) ){
				found <- true;
				do initStock( (sceLarge.building as Warehouse), fdm, stocksLvl2, sizeOfStockLargeWarehouse);
			}
			i <- i + 1;
		}

		// If we have not found it in the large warehouses
		if(!found){
			// we must create one SCE
			// we find an appropriate large warehouse
			Warehouse largeWarehouse <- findWarehouseLvl2(fdm, sizeOfStockLargeWarehouse);
			if(! (lvl2Warehouses contains largeWarehouse)){// Should always be true, isn't it? otherwise, we would have found a SCE...
				lvl2Warehouses <- lvl2Warehouses + largeWarehouse;
			}
			do initStock(largeWarehouse, fdm, stocksLvl2, sizeOfStockLargeWarehouse);
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

		ask sceLarge {
			(building as RestockingBuilding).maxProcessOrdersCapacity <- (building as RestockingBuilding).maxProcessOrdersCapacity + 5;
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
	action getNewCustomer(FinalDestinationManager fdm, list<Stock> stocksLvl1, list<Stock> stocksLvl2){

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
		SupplyChainElement sceCloseWarehouse <- connectLvl1Warehouse(fdm, fdmLeaf, stocksLvl1);

		/*
		 * Connect the close warehouse to the large warehouse
		 */
		do connectLvl2Warehouse(fdm, sceCloseWarehouse, stocksLvl2);
		customers <- customers + fdm;
	}
	
	/**
	 * We assume that the warehouse have already a stock when we initialize a new supply chain
	 */
	action initStock(Warehouse warehouse, FinalDestinationManager f, list<Stock> stocks, int sizeOfStock){
		if(stocks = nil or length(stocks) = 0){
			loop stockFdm over: (f.building as Building).stocks {
				// We create the stock agent
				create Stock number:1 returns:s {
					self.product <- stockFdm.product;
					self.quantity <- rnd(stockFdm.maxQuantity * sizeOfStock);
					self.maxQuantity <- stockFdm.maxQuantity * sizeOfStock;
					self.status <- 0;
					self.fdm <- f;
					self.lp <- myself;
					self.building <- warehouse;
				}

				// and add it to the list of stocks in the warehouse
				warehouse.stocks <- warehouse.stocks + s[0];

				// Finally we update the occupied surface
				warehouse.occupiedSurface <- warehouse.occupiedSurface + (s[0] as Stock).maxQuantity;
			}
		}
		else {
			loop stock over: stocks {
				warehouse.occupiedSurface <- warehouse.occupiedSurface + stock.maxQuantity;
				stock.fdm <- f;
				stock.lp <- self;
				stock.building <- warehouse;
				stock.status <- 0;
			}
			warehouse.stocks <- warehouse.stocks + stocks;
		}
	}
	
	/**
	 * Return a warehouse of first level in the supply chain
	 */
	Warehouse findWarehouseLvl1(FinalDestinationManager fdm, int sizeOfStock){
		Warehouse w <- nil;
		if(adoptedSelectingWarehouseStrategy = 1){
			w <- world.findWarehouseLvl1Strat1(fdm, sizeOfStock, lvl2Warehouses);
		}
		else if(adoptedSelectingWarehouseStrategy = 2){
			w <- world.findWarehouseLvl1Strat2(fdm, sizeOfStock, lvl1Warehouses, lvl2Warehouses);
		}
		else if(adoptedSelectingWarehouseStrategy = 3){
			w <- world.findWarehouseLvl1Strat3(fdm, sizeOfStock, lvl2Warehouses);
		}
		else if(adoptedSelectingWarehouseStrategy = 4){
			w <- world.findWarehouseLvl1Strat4(fdm, sizeOfStock, lvl2Warehouses);
		}
		return w;
	}

	/**
	 * Return a warehouse of third level in the supply chain
	 */
	Warehouse findWarehouseLvl2(FinalDestinationManager fdm, int sizeOfStock){
		Warehouse w <- nil;
		if(adoptedSelectingWarehouseStrategy = 1){
			w <- world.findWarehouseLvl2Strat1(fdm, sizeOfStock, lvl1Warehouses);
		}
		else if(adoptedSelectingWarehouseStrategy = 2){
			w <- world.findWarehouseLvl2Strat2(fdm, sizeOfStock, lvl1Warehouses, lvl2Warehouses);
		}
		else if(adoptedSelectingWarehouseStrategy = 3){
			w <- world.findWarehouseLvl2Strat3(fdm, sizeOfStock, lvl1Warehouses);
		}
		else if(adoptedSelectingWarehouseStrategy = 4){
			w <- world.findWarehouseLvl2Strat4(fdm, sizeOfStock, lvl1Warehouses);
		}
		return w;
	}
	
	aspect base { 
		Provider LHP <- nil;
		Provider AntP <- nil;
		ask Provider {
			if(self.port = "LE HAVRE"){
				LHP <- self;
			}
			else{
				AntP <- self;
			}
		}
		if(AntP = provider){
			draw shape+3°px  color: rgb(14, 234, 2) ; //vert
		}
		else {
			draw shape+3°px color: rgb(12, 0, 236) ; // bleu
		}

	}
	
	aspect simple_base { 
		draw shape+3°px  color: rgb(66, 219, 108) ; //vert
	}
}