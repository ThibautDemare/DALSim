/**
 *  LogisticProvider
 *  Author: Thibaut Démare
 *  Description: This agent manage the stock of its warehouses and the orders of his final destinations. His behavior is still simple but can be improve
 */

model LogisticProvider

import "./Provider.gaml"
import "./Warehouse.gaml"
import "./Batch.gaml"
import "./Building.gaml"
import "./Order.gaml"

species LogisticProvider parent: Role {
	list<FinalDestinationManager> finalDestinationManagers;
	list<Warehouse> warehouses_small;
	list<Warehouse> warehouses_average;
	list<Warehouse> warehouses_large;
	list<Order> orders;
	
	/*
	 * Receive order from the FinalDestinationManager
	 */
	action receive_order(Order o){
		add o to: orders;
	}
	
	/*
	 * Send order(s) to Provider according to orders received from FinalDestinationManager
	 */
	reflex order {
		if not (empty (orders)) {
			loop order over: orders {
				/***************************************************************************************************************************************
				 * Test global stock => if it is good, just move stock from a warehouse to another.
				 * But if not, order new stock to provider
				 */
				//if getGlobalStock(stock.product) < 0.05*7
				
				if(length(warehouses_small) > 0){ 
					order.supplyChain <- (one_of(warehouses_small) as list) + order.supplyChain;
				}
				
				if(length(warehouses_average) > 0){
					order.supplyChain <- (one_of(warehouses_average) as list) + order.supplyChain;
				}	
				if(length(warehouses_large) > 0){
					order.supplyChain <- (one_of(warehouses_large) as list) + order.supplyChain;
				}
				/*Warehouse sw <- one_of(warehouses_small);
				loop while: length(sw.stocks)>sw.stockMax {
					sw <- one_of(warehouses_small);
				}
				order.supplyChain <- (one_of(warehouses_small) as list) + order.supplyChain;
				order.supplyChain <- (one_of(warehouses_average) as list) + order.supplyChain;
				order.supplyChain <- (one_of(warehouses_large) as list) + order.supplyChain;
				*/
				if(length(warehouses_small) > 0 or length(warehouses_small) > 0 or length(warehouses_small) > 0){
					ask Provider {
						do receive_order(order: order);
					}
				}
			}
			remove all:Order from: orders;
		}
	}
	
	aspect base { 
		draw square(1.5°km) color: rgb("green") ;
	} 
}