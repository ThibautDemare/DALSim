model Building

import "AwaitingStock.gaml"

species Building {
	list<Stock> stocks;
	list<AwaitingStock> entering_stocks <- [];
	float totalSurface;
	float occupiedSurface;
	float outflow <- 0.0;// This data is sended to Graphstream for the supplying network
	bool outflow_updated <- false;
	int maxProcessEnteringGoodsCapacity <- 5;
	int timeShifting <- rnd(23);

	list<Vehicle> leavingVehicles <- []; // Liste des véhicules au départ
	list<Commodity> leavingCommodities <- [];
	list<Commodity> comingCommodities <- [];

	float handling_time_to_road <- 1;
	float handling_time_from_road <- 1;

	float colorValue <- -1;

	float cost;

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

	action receiveCommodity(Commodity c){
		if(c.finalDestination = self){
			create AwaitingStock number: 1 returns: ast {
				self.stepOrderMade <- c.stepOrderMade;
				self.stock <- c.stock;
				self.location <- myself.location;
				self.building <- myself;
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

	reflex processEnteringGoods when: length(entering_stocks) > 0 {
		int i <- 0;
		loop while: i < maxProcessEnteringGoodsCapacity and length(entering_stocks) > 0 {
			AwaitingStock entering_stock <- entering_stocks[0];
			int j <- 0;
			bool notfound <- true;
			loop while: j < length(stocks) and notfound {
				Stock stockBuilding <- stocks[j];
				if( stockBuilding.fdm = entering_stock.stock.fdm and stockBuilding.product = entering_stock.stock.product ){
					notfound <- false;
					stockBuilding.status <- 0;
					stockBuilding.quantity <- stockBuilding.quantity + entering_stock.stock.quantity;
					if(entering_stock.stepOrderMade >= 0){
						// Update lists containing the time to deliver some goods in order to measure the efficiency of the actors
						(entering_stock.stock.lp as LogisticsServiceProvider).timeToDeliver <- (entering_stock.stock.lp as LogisticsServiceProvider).timeToDeliver + ((int(time/3600)) - entering_stock.stepOrderMade);
						if(stockBuilding.fdm.building = self){ // The average time to be delivered is only useful with the building of the FDM and not for every building of the supply chain
							stockBuilding.fdm.localTimeToBeDeliveredLastDeliveries <- stockBuilding.fdm.localTimeToBeDeliveredLastDeliveries + ((int(time/3600)) - entering_stock.stepOrderMade);
						}
					}
				}
				j <- j + 1;
			}

			i <- i + 1;
			remove index:0 from: entering_stocks;

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
		leavingCommodities <- leavingCommodities + commodity;
	}
}