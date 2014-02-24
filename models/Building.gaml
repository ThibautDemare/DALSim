/**
 *  Building
 *  Author: Thibaut Démare
 *  Description: It is a physical structure that contains a stock and which has a surface. It can receive some batch and simulate a break bulk mechanism.
 */

model Building

import "./Batch.gaml"
import "./Stock.gaml"
		
species Building {
	list<Stock> stocks;
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
				if( self.target = myself.location ){
					self.breakBulk <- self.computeBreakBulk(myself.totalSurface);
					target <- nil;
				}
				else if (target = nil and self.breakBulk = 0) {
					loop stock over: myself.stocks {
						if( stock.product = self.product ){
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
		draw circle(1.5°km) color: rgb("yellow");
	}
}