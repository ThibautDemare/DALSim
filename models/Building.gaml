model Building

import "AwaitingStock.gaml"

species Building {
	list<Stock> stocks;
	list<AwaitingStock> entering_stocks <- [];
	float totalSurface;
	float occupiedSurface;
	float outflow <- 0.0;// This data is sended to Graphstream for the supplying network
	bool outflow_updated <- false;
	int timeShifting <- rnd(23);

	list<Vehicle> leavingVehicles_road <- []; // Liste des véhicules au départ pour le mode routier
	date lastVehicleDeparture_road;
	list<Vehicle> leavingVehicles_river <- []; // Liste des véhicules au départ pour le mode fluvial
	date lastVehicleDeparture_river;
	list<Vehicle> leavingVehicles_maritime <- []; // Liste des véhicules au départ pour le mode maritime
	date lastVehicleDeparture_maritime;
	list<Vehicle> leavingVehicles_secondary <- []; // Liste des véhicules au départ pour le mode maritime secondaire
	date lastVehicleDeparture_secondary;
	list<Commodity> leavingCommodities <- [];
	list<Commodity> comingCommodities <- [];

	float handling_time_to_road <- 1;
	float handling_time_from_road <- 1;

	float colorValue <- -1;

	float cost;

	list<float> nbRoadVehiclesLastSteps <- [0.0];
	list<float> nbRiverVehiclesLastSteps <- [0.0];
	list<float> nbMaritimeVehiclesLastSteps <- [0.0];
	list<float> nbSecondaryVehiclesLastSteps <- [0.0];
	list<float> nbRoadQuantitiesLastSteps <- [0.0];
	list<float> nbRiverQuantitiesLastSteps <- [0.0];
	list<float> nbMaritimeQuantitiesLastSteps <- [0.0];
	list<float> nbSecondaryQuantitiesLastSteps <- [0.0];

	// Measures of efficiency
	// based on time to deliver some goods (originally in the FinalConsignee agent)
	list<int> localTimeToBeDeliveredLastDeliveries <- []; // This variable is used to have an idea of the efficicency of the LP to deliver quickly the goods
	float localTimeToBeDelivered <- 0.0;

	action removeVehicleFromList(Vehicle vehicle, string networkType) {
		list<Vehicle> leavingVehicles;
		if(networkType = "road"){
			leavingVehicles <- leavingVehicles_road;
			if(lastVehicleDeparture_road = nil or lastVehicleDeparture_road < vehicle.departureDate){
				lastVehicleDeparture_road <- vehicle.departureDate;
			}
		}
		else if(networkType = "river"){
			leavingVehicles <- leavingVehicles_river;
			if(lastVehicleDeparture_river = nil or lastVehicleDeparture_river < vehicle.departureDate){
				lastVehicleDeparture_river <- vehicle.departureDate;
			}
		}
		else if(networkType = "maritime"){
			leavingVehicles <- leavingVehicles_maritime;
			if(lastVehicleDeparture_maritime = nil or lastVehicleDeparture_maritime < vehicle.departureDate){
				lastVehicleDeparture_maritime <- vehicle.departureDate;
			}
		}
		else {
			leavingVehicles <- leavingVehicles_secondary;
			if(lastVehicleDeparture_secondary = nil or lastVehicleDeparture_secondary < vehicle.departureDate){
				lastVehicleDeparture_secondary <- vehicle.departureDate;
			}
		}
		int i <- 0;
		bool notfound <- true;
		loop while: i < length(leavingVehicles) and notfound {
			if(leavingVehicles[i] = vehicle){
				remove index: i from: leavingVehicles;
				notfound <- false;
			}
			i <- i + 1;
		}
	}

	reflex manageRoadComingCommodities {
		int i <- 0;
		loop while:i<length(comingCommodities) {
			if(comingCommodities[i].currentNetwork = 'road' and
				comingCommodities[i].incomingDate + handling_time_from_road#hour >= current_date
			){
				leavingCommodities <+ comingCommodities[i];
				remove index:i from:comingCommodities;
			}
			else{
				i <- i + 1;
			}
		} 
	}

	action welcomeVehicle(Vehicle v){
		if(v.networkType = "road"){
			nbRoadVehiclesLastSteps[length(nbRoadVehiclesLastSteps)-1] <- nbRoadVehiclesLastSteps[length(nbRoadVehiclesLastSteps)-1] + 1.0;
		}
		else if(v.networkType = "river"){
			nbRiverVehiclesLastSteps[length(nbRiverVehiclesLastSteps)-1] <- nbRiverVehiclesLastSteps[length(nbRiverVehiclesLastSteps)-1] + 1.0;
		}
		else if(v.networkType = "maritime"){
			nbMaritimeVehiclesLastSteps[length(nbMaritimeVehiclesLastSteps)-1] <- nbMaritimeVehiclesLastSteps[length(nbMaritimeVehiclesLastSteps)-1] + 1.0;
		}
		else {
			nbSecondaryVehiclesLastSteps[length(nbSecondaryVehiclesLastSteps)-1] <- nbSecondaryVehiclesLastSteps[length(nbSecondaryVehiclesLastSteps)-1] + 1.0;
		}
	}

	action receiveCommodity(Commodity c, string nt){
		if(nt = "road"){
			nbRoadQuantitiesLastSteps[length(nbRoadQuantitiesLastSteps)-1] <- nbRoadQuantitiesLastSteps[length(nbRoadQuantitiesLastSteps)-1] + c.volume;
		}
		else if(nt = "river"){
			nbRiverQuantitiesLastSteps[length(nbRiverQuantitiesLastSteps)-1] <- nbRiverQuantitiesLastSteps[length(nbRiverQuantitiesLastSteps)-1] + c.volume;
		}
		else if(nt = "maritime") {
			nbMaritimeQuantitiesLastSteps[length(nbMaritimeQuantitiesLastSteps)-1] <- nbMaritimeQuantitiesLastSteps[length(nbMaritimeQuantitiesLastSteps)-1] + c.volume;
		}
		else {
			nbSecondaryQuantitiesLastSteps[length(nbSecondaryQuantitiesLastSteps)-1] <- nbSecondaryQuantitiesLastSteps[length(nbSecondaryQuantitiesLastSteps)-1] + c.volume;
		}
		if(c.finalDestination = self){
			create AwaitingStock number: 1 returns: ast {
				self.stepOrderMade <- c.stepOrderMade;
				self.stock <- c.stock;
				self.location <- myself.location;
				self.building <- myself;
				self.networkType <- nt;
				self.incomingDate <- c.incomingDate;
			}
			entering_stocks <- entering_stocks + ast[0];
			ask c {
				do die;
			}
		}
		else {
			comingCommodities <+ c;
		}
	}

	float getHandlingTimeFrom(string nt){
		return handling_time_from_road;
	}

	reflex processEnteringGoods when: length(entering_stocks) > 0 {
		list<AwaitingStock> toBeIncluded <- [];
		int k <- 0;
		loop while: k < length(entering_stocks) {
			float handling_time <- getHandlingTimeFrom(entering_stocks[k].networkType);
			if(entering_stocks[k].incomingDate + handling_time°h >= current_date){
				toBeIncluded <- toBeIncluded + entering_stocks[k];
				remove index:k from:entering_stocks;
			}
			else {
				k <- k + 1;
			}
		}

		loop while:length(toBeIncluded) > 0 {
			AwaitingStock entering_stock <- toBeIncluded[0];
			int j <- 0;
			bool notfound <- true;
			loop while: j < length(stocks) and notfound {
				Stock stockBuilding <- stocks[j];
				if( stockBuilding.fdm = entering_stock.stock.fdm and stockBuilding.product = entering_stock.stock.product ){
					notfound <- false;
					stockBuilding.status <- 0;
					stockBuilding.quantity <- stockBuilding.quantity + entering_stock.stock.quantity;
					if(entering_stock.stepOrderMade >= starting_date){
						// Update lists containing the time to deliver some goods in order to measure the efficiency of the actors
						float t <- ((current_date - entering_stock.stepOrderMade))/3600.0;
						(entering_stock.stock.lp as LogisticsServiceProvider).timeToDeliver <- (entering_stock.stock.lp as LogisticsServiceProvider).timeToDeliver + t;//((int(time/3600)) - entering_stock.stepOrderMade);
						localTimeToBeDeliveredLastDeliveries <- localTimeToBeDeliveredLastDeliveries + t;//((int(time/3600)) - entering_stock.stepOrderMade);
					}
				}
				j <- j + 1;
			}

			remove index:0 from: toBeIncluded;

			if(notfound){
				// this stock probably came after a changement of LP
				// We need to transfer it.
				ask entering_stock.stock.fdm {
					do manageLostStock(entering_stock);
				}
			}
			else {
				ask entering_stock {
					do die;
				}
			}
		}
	}
}

species RestockingBuilding parent: Building {
	list<Order> currentOrders <- [];
	list<Vehicle> leavingVehicles <- [];
	int maxProcessOrdersCapacity;

	action addOrder(Order order){
		currentOrders <- currentOrders + order;
	}

	/*
	 * Receive a request from a logistic provider to restock another building
	 */
	reflex processOrders when: !empty(currentOrders) and (((time/3600.0) + timeShifting) mod nbStepsBetweenWPO) = 0.0 {
		// We empty progressively the list of orders after have processed them
		int k <- 0;
		list<Order> awaitingOrder <- [];

		// If the warehouse does not belong to a LSP anymore, then we have to empty the list of orders
		if(length(currentOrders) > 0 and maxProcessOrdersCapacity = 0){
			loop while: !empty(currentOrders) {
				ask currentOrders[0] {
					do die;
				}
				remove index: 0 from: currentOrders;
			}
		}

		loop while: !empty(currentOrders) and k < maxProcessOrdersCapacity {
			Order order <- currentOrders[0];
			if(!dead(order)){// when we test the restock, a son send his orders to all of his fathers. Therefore, a building can receive an order which is not for him in reality.
				// We compare the product and the owner of each stock to the product and owner of this current order
				float sendedQuantity <- 0.0;
				bool foundStock <- false;
				int i <- 0;
				loop while: i < length(stocks) and !foundStock {
					Stock stock <- stocks[i];
					// If we find the right stock, we add the corresponding quantity within a vehicle
					if stock.fdm = order.fdm and stock.product = order.product {
						foundStock <- true;
						order.reference.status <- 3;
						// Compute the right quantity to send
						if((stock.quantity -  order.quantity) > 0){
							sendedQuantity <- order.quantity;
						}
						else{
							sendedQuantity <- stock.quantity;
						}
						// We only send something if the quantity is not empty
						if(sendedQuantity > 0){
							stock.quantity <- stock.quantity - sendedQuantity;

							outflow <- outflow + sendedQuantity;
							outflow_updated <- true;

							// And create a Stock agent which will move within a Vehicle
							create Stock number:1 returns:sendedStock {
								self.product <- order.product;
								self.quantity <- sendedQuantity;
								self.fdm <- order.fdm;
								self.lp <- order.logisticsServiceProvider;
							}
							do sendStock(sendedStock[0], order);
						}
					}
					i <- i + 1;
				}

				if(foundStock){
					k <- k + 1;
					if(sendedQuantity > 0){
						ask order {
							do die;
						}
					}
					else {
						awaitingOrder <- awaitingOrder + order;
					}
				}
			}
			remove index: 0 from: currentOrders;
		}
		currentOrders <- awaitingOrder + currentOrders;
	}

	action sendStock(Stock stockToSend, Order order){
		create Commodity number:1 returns:returnedAgent;
		Commodity commodity <- returnedAgent[0];
		commodity.stock <- stockToSend;
		commodity.volume <- stockToSend.quantity;
		commodity.finalDestination <- order.building;
		commodity.stepOrderMade <- order.stepOrderMade;
		ask forwardingAgent {
			commodity.paths <- compute_shortest_path(myself, order.building, order.strategy, commodity);//'financial_costs'//travel_time
		}
		order.fdm.localTransportationCosts <- order.fdm.localTransportationCosts + commodity.costs;
		order.fdm.transportedVolumes <- order.fdm.transportedVolumes + commodity.volume;
		leavingCommodities <- leavingCommodities + commodity;
	}
}