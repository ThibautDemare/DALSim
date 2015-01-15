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
		
species Building schedules: [] {
	list<Stock> stocks;
	float surfaceUsedForLH;
	float totalSurface;
	float occupiedSurface;
	
	/*
	 * Receive a batch
	 */
	reflex receive_batch{
		list<Batch> entering_batch <- (Batch inside self);
		if( !(empty (entering_batch))) {
			ask entering_batch {
				//If the batch is at the right adress
				if( target != nil and self.dest = myself){
					self.breakBulk <- self.computeBreakBulk(myself.totalSurface);
					target <- nil;
				}
				else if (target = nil and self.breakBulk = 0 and self.dest = myself) {
					loop while: !empty(self.stocks){
						Stock stockBatch <- first(self.stocks);
						loop stockBuilding over: myself.stocks {
							if( stockBuilding.fdm = stockBatch.fdm and stockBuilding.product = stockBatch.product ){
								stockBuilding.status <- 0;
								stockBuilding.quantity <- stockBuilding.quantity + stockBatch.quantity;
							}
						}
						remove index:0 from: self.stocks;
						ask stockBatch {
							do die;
						}
					}
					ask self {
						do die;
					}
				}
			}
 		}
	}
}

species RestockingBuilding parent: Building schedules: [] {
	list<Order> currentOrders <- [];
	
	action addOrder(Order order){
		currentOrders <- currentOrders + order;
	}
	
	/*
	 * Receive a request from a logistic provider to restock another building
	 */
	reflex processOrders when: !empty(currentOrders) and ((time/3600.0) mod numberofHoursBeforePO) = 0.0 and (time/3600.0) > 0{
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
						// And create a Stock agent which will move within a Batch
						create Stock number:1 returns:sendedStock {
							self.product <- order.product;
							self.quantity <- sendedQuantity;
							self.fdm <- order.fdm;
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
								self.breakBulk <- self.computeBreakBulk(myself.totalSurface);
								self.position <- order.position;
								self.dest <- order.building;
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