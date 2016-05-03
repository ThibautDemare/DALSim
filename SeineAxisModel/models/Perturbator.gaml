/**
 *  Perturbator
 *  Author: Thibaut
 *  Description: 
 */

model Perturbator

import "./Road.gaml"

global {
	
	action block_roads (point loc, list<Road> selected_agents) {
		ask selected_agents {
			if(blocked){
				// Need to unblock the road
				blocked <- false;
				ask Batch[0] {
					do unblock_road road:myself;
				}
			}
			else {
				// Need to block the road
				blocked <- true;
				ask Batch[0] {
					do block_road road:myself;
				}
			}
		}
	}
}