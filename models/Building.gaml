/**
 *  Building
 *  Author: Thibaut Démare
 *  Description: It is a physical structure that contains a stock and which has a surface. It can receive some batch and simulate a break bulk mechanism.
 */

model Building

import "./Batch.gaml"
import "./Stock.gaml"
import "./Order.gaml"
		
species Building {
	list<Stock> stocks;
	float totalSurface;
	float occupiedSurface;
	list<Order> currentOrders <- [];
	
	/*
	 * Receive a batch
	 */
	reflex receive_batch{
		list<Batch> entering_batch <- (Batch inside self);
		if( !(empty (entering_batch))) {
			ask entering_batch {
				//If the batch is at the right adress
				if( self.target = myself.location ){
					self.breakBulk <- self.computeBreakBulk(myself.totalSurface);
					target <- nil;
				}
				else if (target = nil and self.breakBulk = 0) {
					loop stockBatch over: self.stocks {
						loop stockBuilding over: myself.stocks {
							if( stockBuilding.fdm = self.fdm and stockBuilding.product = stockBatch.product ){
								stockBuilding.ordered <- false;
								stockBuilding.quantity <- stockBuilding.quantity + stockBatch.quantity;
							}
						}
					}
					ask self {
						do die;
					}
				}
			}
 		}
	}
	
	action addOrder(Order order){
		currentOrders <- currentOrders + order;
	}
	
	/*
	 * Receive a request from a logistic provider to restock another building
	 */
	reflex processOrders when: !empty(currentOrders){
		list<Batch> leavingBatch <- [];
		
		// We empty progressively the list of orders after have processed them
		loop while: !empty(currentOrders) {
			Order order <- first(currentOrders);
			// We compare the product and the owner of each stock to the product and owner of this current order
			bool foundStock <- false;
			int i <- 0;
			loop while: i < length(stocks) and !foundStock {
				Stock stock <- stocks[i];
				// If we find the right stock, we had the corresponding quantity within a batch 
				if stock.fdm = order.fdm and stock.product = order.product {
					foundStock <- true;
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
					}
					
					// Looking for a batch which go to the same building
					bool foundBatch <- false;
					int j <- 0;
					loop while: j < length(leavingBatch) and !foundBatch {
						if( (leavingBatch[j] as Batch).target = order.building.location){
							foundBatch <- true;
						}
						j <- j + 1;
					}
					
					// We there is a such Batch, we update it
					if(foundBatch){
						(leavingBatch[j] as Batch).overallQuantity <- (leavingBatch[j] as Batch).overallQuantity + sendedQuantity;
						(leavingBatch[j] as Batch).stocks <- (leavingBatch[j] as Batch).stocks + sendedStock;
					}
					else {
						// else, we create one
						create Batch number: 1 {
							self.target <- order.building.location;
							self.location <- myself.location;
							self.breakBulk <- self.computeBreakBulk(myself.totalSurface);
							self.fdm <- order.fdm;
							self.position <- order.position;
						}
					}
				}
			}
						
			// This order is useless now. We kill it before process the next one
			remove index: 0 from:currentOrders;
			ask order {
				do die;
			}
		}
	}
}