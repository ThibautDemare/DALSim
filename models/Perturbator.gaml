model Perturbator

import "Networks.gaml"
import "Vehicle.gaml"
import "Provider.gaml"
import "LogisticsServiceProvider.gaml"
import "Parameters.gaml"

global {

	action block_one_road {
		Road selected_agent <- Network closest_to #user_location;
		ask selected_agent {
			if(blocked){
				// Need to unblock the road
				blocked <- false;
				ask forwardingAgent {
					do unblock_edge edge:myself;
				}
			}
			else {
				// Need to block the road
				blocked <- true;
				ask forwardingAgent {
					do block_edge edge:myself;
				}
			}
		}
	}

	action print_blocked_road {
		ask Road {
			if(blocked){
				write name;
			}
		}
	}

	// This function uses an adaptation of the Huff model to compute the supposed attractivity of a port perceived by a logistic provider
	// It is represented by a probability to choose a port instead of another one.
	action update_proba_to_choose_provider {
		matrix<float> p <- 0.0 as_matrix( {length(Provider), length(LogisticsServiceProvider)} );
		matrix<float> sum <- 0.0 as_matrix( {length(LogisticsServiceProvider), 1} );

		// Firstly : We start initiating the probability of a customer at i to go at the shop at j, and we compute the sum
		int ld <- length(Provider);
		int lw <- length(LogisticsServiceProvider);
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
				dist <- Provider[i] distance_to LogisticsServiceProvider[j];
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
					(LogisticsServiceProvider[j]).probaAnt <-   p[i, j]; //(w[j]).huffValue
					ask (LogisticsServiceProvider[j]) {
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

	///////////////////////////////////////////////////////////////////////////////////////////////////////////
	// This scenario the attractiveness of the ports of Le Havre and Antwerp  at steps 500 and 1000 //
	///////////////////////////////////////////////////////////////////////////////////////////////////////////

	reflex scenario_attractiveness when: allowScenarioAttractiveness {
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
	}

	/////////////////////////////////////////////////////////////////////////////////////
	// This scenario blocks some roads at steps 500 and 1000 on the Antwerp-Paris axis //
	/////////////////////////////////////////////////////////////////////////////////////

	action block_some_roads(list<string> roads){
		int i <- 0;
		loop while: i < length(roads){
			int j <- 0;
			loop while: j < length(Road) {
				if(Road[j].name = roads[i]){
					if(!Road[j].blocked){
						// Need to block the road
						Road[j].blocked <- true;
						ask forwardingAgent {
							do block_edge edge:myself;
						}
					}
				}
				j <- j + 1;
			}
			i <- i + 1;
		}
	}

	reflex scenario_block_roads when: allowScenarioBlockRoads {
		if(cycle = 500){
			list<string> roads <- ["Road3900", "Road4069", "Road4517", "Road4526", "Road5547", "Road5548", "Road5602", "Road5808", "Road8750", "Road8753", "Road8970", "Road8982", "Road8999", "Road9024", "Road9647"];
			do block_some_roads(roads);
		}
		else if(cycle = 1000){
			list<string> roads <- ["Road3900", "Road3905", "Road4018", "Road4069", "Road4080", "Road4081", "Road4517", "Road4526", "Road5491", "Road5492", "Road5547", "Road5548", "Road5602", "Road5604", "Road5632", "Road5723", "Road5742", "Road5808", "Road5897", "Road5902", "Road5904", "Road8750", "Road8753", "Road8950", "Road8958", "Road8970", "Road8982", "Road8999", "Road9024", "Road9055", "Road9075", "Road9647", "Road9657", "Road9696", "Road9697", "Road9707", "Road9716"];
			do block_some_roads(roads);
		}
	}

	////////////////////////////////////////////////////////////////////////////////////////////
	// This scenario blocks the Canal Seine-Nord at the beginning and unblocks it at step 500 //
	////////////////////////////////////////////////////////////////////////////////////////////

	reflex scenario_canal_seine_nord when: allowScenarionCanalSeineNord {
		if(cycle = cycleWhenOpenCanalSeineNord){
			ask canalSeineNord {
				ask forwardingAgent {
					do unblock_edge edge:myself;
				}
			}
		}
	}
}