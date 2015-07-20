/**
 *  SupplyChain
 *  Author: Thibaut
 *  Description: 
 */

model SupplyChain


import "./Building.gaml"
import "./Order.gaml"
import "./Stock.gaml"
import "./Parameters.gaml"

species SupplyChain schedules: [] {
	LogisticProvider logisticProvider;
	SupplyChainElement root;
	list<SupplyChainElement> leafs <- [];
}

species SupplyChainElement schedules: [] {
	SupplyChain supplyChain;
	Building building;
	list<SupplyChainElement> fathers;
	list<SupplyChainElement> sons;
	int position;
	
	action recursiveTests(list<Order> sonOrders){
		Building b <- building;
		
		// First, we add the orders made by the son in order to process them later
		if(!empty(sonOrders)){
			loop sonOrder over: sonOrders {
				ask b as RestockingBuilding {
					do addOrder(sonOrder);
				}
			}
		}

		// If it is the root then we can stop now
		if(self = supplyChain.root){
			return;
		}
				
		// Now, we can build an order with each product which needs to be restocked
		list<Order> orders <- [];
		loop stock over: b.stocks {
			if stock.lp = supplyChain.logisticProvider and stock.quantity < threshold*stock.maxQuantity and stock.status = 0 {
				stock.status <- 1;
				create Order number: 1 returns: o {
					self.product <- stock.product;
					self.quantity <- stock.maxQuantity-stock.quantity;
					self.building <- b;
					self.fdm <- stock.fdm;
					self.position <- myself.position;
					self.reference <- stock;
					self.logisticProvider <- myself.supplyChain.logisticProvider;
					self.stepOrderMade <- int(time/3600);
				}
				orders <- orders + o;
			}
		}
		
		loop father over: fathers {
			ask father {
				do recursiveTests(orders);
			}
		}
	}
}