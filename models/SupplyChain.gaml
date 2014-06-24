/**
 *  SupplyChain
 *  Author: Thibaut
 *  Description: 
 */

model SupplyChain


import "./Building.gaml"
import "./Order.gaml"
import "./Stock.gaml"

species SupplyChain {
	LogisticProvider logisticProvider;
	SupplyChainElement root;
	list<SupplyChainElement> leafs <- [];
}

species SupplyChainElement {
	SupplyChain supplyChain;
	Building building;
	list<SupplyChainElement> fathers;
	list<SupplyChainElement> sons;
	int position;
	
	action recursiveTests(list<Order> sonOrders){
		Building b <- building;
		
		// First, we add the orders made by the son in order to process its later
		if(!empty(sonOrders)){
			loop sonOrder over: sonOrders {
				ask b {
					do addOrder(sonOrder);
				}
			}
		}

		// If it is the root then we can stop now
		if(self = supplyChain.root){
			return;
		}
				
		// Now, we can build an order with each product which needs to be restock
		list<Order> orders <- [];
		loop stock over: b.stocks {
			//write "stock.lp = "+stock.lp+" et supplyChain.logisticProvider = "+supplyChain.logisticProvider;
			if stock.lp = supplyChain.logisticProvider and stock.quantity < 0.5*stock.maxQuantity and stock.ordered = false {
				stock.ordered <- true;
				create Order number: 1 returns: o {
					self.product <- stock.product;
					self.quantity <- stock.maxQuantity-stock.quantity;
					self.building <- b;
					self.fdm <- stock.fdm;
					self.position <- myself.position;
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