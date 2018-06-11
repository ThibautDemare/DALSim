model SupplyChain

import "Building.gaml"
import "Transporters.gaml"

species SupplyChain schedules: [] {
	LogisticsServiceProvider logisticsServiceProvider;
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
			if stock.lp = supplyChain.logisticsServiceProvider and stock.quantity < (supplyChain.logisticsServiceProvider.threshold)*stock.maxQuantity and stock.status = 0 {
				orders <- orders + makeOrders(stock, b);
			}
		}
		
		loop father over: fathers {
			ask father {
				do recursiveTests(orders);
			}
		}
	}
	
	list<Order> makeOrders(Stock stock, Building b){
		list<Order> orders <- [];
		stock.status <- 1;
		float quantityToOrder <- stock.maxQuantity-stock.quantity;
		float maxQuantityPerOrder <- RoadTransporter[0].maximalTransportedVolume;
		loop while: (quantityToOrder > maxQuantityPerOrder){
			orders <+ createOneOrder(stock, b, maxQuantityPerOrder);
			quantityToOrder <- quantityToOrder - maxQuantityPerOrder;
		}
		
		orders <+ createOneOrder(stock, b, quantityToOrder);
		return orders;
	}
	
	Order createOneOrder(Stock stock, Building b, float q){
		create Order number: 1 returns: o {
			self.product <- stock.product;
			self.quantity <- q;
			self.building <- b;
			self.fdm <- stock.fdm;
			self.position <- myself.position;
			self.reference <- stock;
			self.logisticsServiceProvider <- myself.supplyChain.logisticsServiceProvider;
			self.stepOrderMade <- int(time/3600);
			self.strategy <- myself.supplyChain.logisticsServiceProvider.costsPathStrategy;
		}
		return o[0];
	}
}