/**
 *  Building
 *  Author: Thibaut Démare
 *  Description: It is a physical structure that contains a stock and which has a surface. It can receive some batch and simulate a break bulk mechanism.
 */

model Building

import "./Batch.gaml"
import "./AwaitingStock.gaml"
import "./Stock.gaml"
import "./Order.gaml"
import "./Parameters.gaml"
import "./GraphStreamConnection.gaml"
import "./LogisticProvider.gaml"
		
species Building {
	list<Stock> stocks;
	list<AwaitingStock> entering_stocks;
	float totalSurface;
	float occupiedSurface;
	float outflow <- 0.0;// This data is sended to Graphstream for the supplying network
	bool outflow_updated <- false;
	int maxProcessEnteringGoodsCapacity <- 5;
	int timeShifting <- rnd(23);

	/*
	 * Receive a batch
	 */
	reflex receive_batch {
		list<Batch> entering_batch <- (Batch inside self);
		if( !(empty (entering_batch))) {
			ask entering_batch {
				//If the batch is at the right adress
				if(self.dest = myself){
					loop st over: self.stocks {
						create AwaitingStock number: 1 returns: ast {
							self.stepOrderMade <- myself.stepOrderMade;
							self.stock <- st;
							self.position <- myself.position;
							self.location <- myself.location;
						}
						myself.entering_stocks <- myself.entering_stocks + ast;
					}
					do die;
				}
			}
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
						(entering_stock.stock.lp as LogisticProvider).timeToDeliver <- (entering_stock.stock.lp as LogisticProvider).timeToDeliver + ((int(time/3600)) - entering_stock.stepOrderMade);
						if(stockBuilding.fdm.building = self){ // The average time to be delivered is only useful with the building of the FDM and not for every building of the supply chain
							stockBuilding.fdm.timeToBeDelivered <- stockBuilding.fdm.timeToBeDelivered + ((int(time/3600)) - entering_stock.stepOrderMade);
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
	list<Batch> leavingBatches <- [];
	int maxProcessOrdersCapacity;
	float cost;

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
					// If we find the right stock, we had the corresponding quantity within a batch
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

							// And create a Stock agent which will move within a Batch
							create Stock number:1 returns:sendedStock {
								self.product <- order.product;
								self.quantity <- sendedQuantity;
								self.fdm <- order.fdm;
								self.lp <- order.logisticProvider;
							}

							do sendStock(sendedStock[0], order.building, order.position, order.stepOrderMade);
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
		leavingBatches <- [];
	}

	action sendStock(Stock stockToSend, Building buildingTarget, int pos, int stpOrderMade){
		// Looking for a batch which go to the same building
		bool foundBatch <- false;
		int j <- 0;
		loop while: j < length(leavingBatches) and !foundBatch {
			if( (leavingBatches[j] as Batch).dest = buildingTarget and pos = (leavingBatches[j] as Batch).position){
				foundBatch <- true;
			}
			else {
				j <- j + 1;
			}
		}
		Batch lb <- nil;
		// There is such a Batch, we update it
		if(foundBatch){
			lb <- leavingBatches[j];
		}
		else {
			// else, we create one
			create Batch number: 1 returns:rlb {
				self.target <- buildingTarget.location;
				self.location <- myself.location;
				self.position <- pos;
				self.dest <- buildingTarget;
				self.stepOrderMade <- stpOrderMade;
			}
			lb <- first(rlb);
			leavingBatches <- leavingBatches + lb;
		}

		lb.overallQuantity <- lb.overallQuantity + stockToSend.quantity;
		lb.stocks <- lb.stocks + stockToSend;
	}
}