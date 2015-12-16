/**
 *  AwaitingStock
 *  Author: Thibaut
 *  Description: 
 */

model AwaitingStock

import "./Stock.gaml"

species AwaitingStock schedules:[] {
	Stock stock;
	int stepOrderMade;
	int position; 
}