/**
 *  Building
 *  Author: Thibaut Démare
 *  Description: Iit is a physical structure that contains a stock and that has a surface. It can receive some batch and simulate a break bulk mechanism.
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
					self.breakBulk <- rnd(22)+2;// A break bulk can take between 2 and 24 hours.
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