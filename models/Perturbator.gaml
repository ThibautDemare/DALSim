/**
 *  Perturbator
 *  Author: Thibaut
 *  Description: 
 */

model Perturbator

import "./Road.gaml"
import "./Provider.gaml"

global {

	action block_roads {
		Road selected_agent <- Road closest_to #user_location;
		ask selected_agent {
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

	// This function uses an adaptation of the Huff model to compute the supposed attractivity of a port perceived by a logistic provider
	// It is represented by a probability to choose a port instead of another one.
	action update_proba_to_choose_provider {
		matrix<float> p <- 0.0 as_matrix( {length(Provider), length(LogisticProvider)} );
		matrix<float> sum <- 0.0 as_matrix( {length(LogisticProvider), 1} );

		// Firstly : We start initiating the probability of a customer at i to go at the shop at j, and we compute the sum
		int ld <- length(Provider);
		int lw <- length(LogisticProvider);
		int i <- 0;
		int j <- 0;

		// Update the attractiveness defined by the users
		ask Provider {
			if(self.port = "LE HAVRE"){
				self.attractiveness <- LHAttractiveness;
			}
			else{
				self.attractiveness <- AntAttractiveness;
			}
		}

		loop while: i < ld {
			j <- 0;
			loop while: j < lw {
				float dist;
				ask Batch[0] {
					dist <- compute_path_length2(Provider[i], LogisticProvider[j]);
				}
				p[i, j] <- (  (Provider[i] as Provider).attractiveness ) / (dist*dist) ;
				sum[j, 0] <- sum[j, 0] + p[i, j];
				j <- j + 1;
			}
			i <- i + 1;
		}

		// Secondly, we compute the number of customers at i going to the shop i
		i <- 0;
		j <- 0;
		loop while: i < ld {
			j <- 0;
			loop while: j < lw {
				p[i, j] <- (p[i, j] / sum[j, 0]) ;//The attractiveness is used in order to add a virtual weigth to the provider.
				if( (Provider[i] as Provider).port = "ANTWERP" ){
					(LogisticProvider[j]).probaAnt <-   p[i, j]; //(w[j]).huffValue
					ask (LogisticProvider[j]) {
						do updateSupplyChainProvider;
					}
				}
				j <- j + 1;
			}
			i <- i + 1;
		}
	}
	
	/*
	 * Scenarios
	 */
	
	reflex scenario1 {
		if(cycle = 500){
			LHAttractiveness <- 1.0;
			AntAttractiveness <- 3.0;
			do update_proba_to_choose_provider;
		}
		else if(cycle = 1000){
			LHAttractiveness <- 5.0;
			AntAttractiveness <- 1.0;
			do update_proba_to_choose_provider;
		}
//		else if(cycle = 2250){
//			LHAttractiveness <- 3.0;
//			AntAttractiveness <- 1.0;
//			do update_proba_to_choose_provider;
//		}
	}
}