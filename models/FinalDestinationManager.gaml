/**
 *  FinalDestinationManager
 *  Author: Thibaut Démare
 *  Description: This agent sells his stock and then must order a restock to his logistic provider.
 */

model FinalDestinationManager

import "./LogisticProvider.gaml"
import "./SeineAxisModel.gaml"
import "./Warehouse.gaml"
import "./Batch.gaml"
import "./Building.gaml"
import "./Order.gaml"
import "./Stock.gaml"

species FinalDestinationManager parent: Role{
	LogisticProvider logisticProvider;
	Building building;
	float huffValue;// number of customer according to huff model => this value cant be used like this because the Huff model does not take care of time.
	
	init {
		logisticProvider <- one_of(LogisticProvider);

		create Building number: 1 returns: buildings {
			location <- myself.location;
		}
		
		create Stock number: 5 returns: s;
		ask s {
			pair temp <- one_of(products.pairs);
			product <- temp.key;
			quantity <- rnd(temp.value as int) as float;
			maxQuantity <- temp.value;			
			building <- first(buildings);
		}
		
		ask buildings {
			self.stocks <- s;
			myself.building <- self;
		}
	}
	
	/*
	 * Basic consumption of the stock (it could be more complex if it is based on the size of the neighbor's population)
	 */
	reflex consumption  when: (cycle mod 20) = 0 {//the stock decrease one time by day (60minutes*24hours)
		loop stock over: building.stocks {
			stock.quantity <- stock.quantity - (1+rnd(1));
		}
	}
	
	/*
	 * Check for all product if it needs to be restock
	 * If yes, an order is made to the logistic provider
	 */
	reflex order when: (cycle mod 200) = 0 { //A order is possible one time by day (60minutes*24hours)
		loop stock over: building.stocks {
			if stock.quantity < 0.05*stock.maxQuantity and stock.ordered=false {
				stock.ordered <- true;
				create Order number: 1 returns: b {
					self.product <- stock.product;
					self.quantity <- stock.maxQuantity;
					self.unitVolume <- stock.unitVolume;
					self.supplyChain <- supplyChain + stock.building;
					self.logisticProvider <- myself.logisticProvider;
				}
				
				ask logisticProvider {
					do receive_order(first(b));
				}

			}
		}
	}
	
	/*
	 * Receive a batch of goods
	 * We adjust the corresponding stock quantity
	 */
	reflex receive_batch {
		list<Batch> entering_batch <- (Batch inside self) where (each.target = nil);
		if not (empty (entering_batch)) {
			ask entering_batch {
				if (self.breakBulk = 0) {
					loop stock over: myself.building.stocks {
						if stock.product = self.product {
							stock.ordered <- false;
							stock.quantity <- stock.quantity + self.quantity;
						}
					}
					ask self {
						do die;
					}
				}
			}
		}
	}
	
	aspect base { 
		draw square(1.5°km) color: rgb("blue") ;
	} 
}