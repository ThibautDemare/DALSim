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
		if not (empty (entering_batch)) {
			ask entering_batch {
				//If the batch is at the right adress
				if first(supplyChain) = myself and target != nil{
					self.breakBulk <- rnd(22)+2;// A break bulk can take between 2 and 24 hours.
					// If there is others step 
					if length(supplyChain) >= 2 {
						remove first(supplyChain) from: supplyChain;
						self.target <- first(supplyChain).location;
					}
					else {
						target <- nil;
					}
				}
				
			}
 		}
	}
	
	aspect base {
		draw circle(1.5°km) color: rgb("yellow");
	}
}