/**
 *  TransferredStocks
 *  Author: Thibaut
 *  Description: 
 */

model TransferredStocks

import "./Stock.gaml"

species TransferredStocks schedules: [] {
	list<Stock> stocksLvl1 <- [];
	list<Stock> stocksLvl2 <- [];
}