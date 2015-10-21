/**
 *  Building
 *  Author: Thibaut Démare
 *  Description: It is a physical structure that contains a stock and which has a surface. It can receive some batch and simulate a break bulk mechanism.
 */

model Building

import "./Batch.gaml"
import "./Stock.gaml"
import "./Order.gaml"
import "./Parameters.gaml"
import "./GraphStreamConnection.gaml"
import "./LogisticProvider.gaml"
		
species Building schedules:[] {
	list<Stock> stocks;
	list<Stock> entering_stocks;
	list<int> listStepOrderMade <- [];
	float surfaceUsedForLH;
	float totalSurface;
	float occupiedSurface;
	float outflow <- 0.0;
	bool outflow_updated <- false;
	int maxProcessCapacity <- 10000;
	
	reflex processEnteringGoods when: length(entering_stocks) > 0 {
		int i <- 0;
		loop while: i < maxProcessCapacity  and length(entering_stocks) > 0 {
			Stock entering_stock <- entering_stocks[0];
			int j <- 0;
			bool notfound <- true;
			loop while: j < length(stocks) and notfound {
				Stock stockBuilding <- stocks[j];
				if( stockBuilding.fdm = entering_stock.fdm and stockBuilding.product = entering_stock.product ){
					notfound <- false;
					stockBuilding.status <- 0;
					stockBuilding.quantity <- stockBuilding.quantity + entering_stock.quantity;

					if(listStepOrderMade[0] >= 0){
						// Update lists containing the time to deliver some goods in order to measure the efficiency of the actors
						(entering_stock.lp as LogisticProvider).timeToDeliver <- (entering_stock.lp as LogisticProvider).timeToDeliver + ((int(time/3600)) - listStepOrderMade[0]);
						if(stockBuilding.fdm.building = self){ // The average time to be delivered is only useful with the building of the FDM and not for every building of the supply chain
							stockBuilding.fdm.timeToBeDelivered <- stockBuilding.fdm.timeToBeDelivered + ((int(time/3600)) - listStepOrderMade[0]);
						}
					}
				}
				j <- j + 1;
			}

			i <- i + 1;
			remove index:0 from: entering_stocks;
			remove index: 0 from: listStepOrderMade;

			if(notfound){
				// this stock probably came after a changement of LP
				// We need to transfer it somewhere.
				// We choose to send the lost stock directly to the FDM
				create Batch number: 1 returns:rlb {
					self.target <- entering_stock.fdm.building.location;
					self.location <- myself.location;
					self.position <- 4; // We define the fourth position as t
					self.dest <- entering_stock.fdm.building;
					self.stepOrderMade <- -1;
				}
			}

			ask entering_stock {
				do die;
			}
		}
	}

	/*
	 * Receive a batch
	 */
	reflex receive_batch {
		list<Batch> entering_batch <- (Batch inside self);
		if( !(empty (entering_batch))) {
			ask entering_batch {
				//If the batch is at the right adress
				if(self.dest = myself){
					loop stock over: self.stocks {
						myself.entering_stocks <- myself.entering_stocks + stock;
						myself.listStepOrderMade <- myself.listStepOrderMade + self.stepOrderMade;
					}
					do die;
				}
			}
 		}
	}
}

species RestockingBuilding parent: Building schedules:[] {
	list<Order> currentOrders <- [];
	
	action addOrder(Order order){
		currentOrders <- currentOrders + order;
	}
	
	/*
	 * Receive a request from a logistic provider to restock another building
	 */
	reflex processOrders when: !empty(currentOrders) {
		list<Batch> leavingBatches <- [];
		// We empty progressively the list of orders after have processed them
		int k <- 0;
		loop while: k<length(currentOrders) {
			Order order <- currentOrders[k];
			if(!dead(order)){
				// We compare the product and the owner of each stock to the product and owner of this current order
				bool foundStock <- false;
				int i <- 0;
				loop while: i < length(stocks) and !foundStock {
					Stock stock <- stocks[i];
					// If we find the right stock, we had the corresponding quantity within a batch
					if stock.fdm = order.fdm and stock.product = order.product {
						foundStock <- true;
						order.reference.status <- 3;
						// Compute the right quantity to send
						float sendedQuantity <- 0.0;
						if((stock.quantity -  order.quantity) > 0){
							sendedQuantity <- order.quantity;
						}
						else{
							sendedQuantity <- stock.quantity;
						}
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

						// Looking for a batch which go to the same building
						bool foundBatch <- false;
						int j <- 0;
						loop while: j < length(leavingBatches) and !foundBatch {
							if( (leavingBatches[j] as Batch).dest = order.building and order.position = (leavingBatches[j] as Batch).position){
								foundBatch <- true;
							}
							else {
								j <- j + 1;
							}
						}
						Batch lb <- nil;
						// There is a such Batch, we update it
						if(foundBatch){
							lb <- leavingBatches[j];
						}
						else {
							// else, we create one
							create Batch number: 1 returns:rlb {
								self.target <- order.building.location;
								self.location <- myself.location;
								self.position <- order.position;
								self.dest <- order.building;
								self.stepOrderMade <- order.stepOrderMade;
							}
							lb <- first(rlb);
							leavingBatches <- leavingBatches + lb;
						}

						lb.overallQuantity <- lb.overallQuantity + sendedQuantity;
						lb.stocks <- lb.stocks + sendedStock;
					}
					i <- i + 1;
				}

				if(foundStock){
					ask order {
						do die;
					}
				}
			}
			k <- k + 1;
		}
		currentOrders <- [];
	}
}