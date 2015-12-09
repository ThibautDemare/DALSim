/**
 *  Parameters
 *  Author: Thibaut
 *  Description: 
 */

model Parameters


import "./SeineAxisModel.gaml"
import "./FinalDestinationManager.gaml"

global {
	float step <- 60 °mn;//60 minutes per step
	
	bool localStrategy <- true;
	int globalAdoptedStrategy <- 2;
	int numberWarehouseSelected <- 15;

	/*
	 * Some variables and functions to call some reflex
	 */
	 
	// The minimal number of days a final destination manager must wait before he can decide if he wants to change of logistic provider
	int minimalNumberOfHoursOfContract <- 336;
	// This is the number of step considered to compute the logistic provider efficiency
	int numberOfStepConsideredForLPEfficiency <- 336; // number of steps for two weeks
	// The numbers of hours between each calls to the reflex "decreasingStocks"
	float numberOfHoursBeforeDS <- 24.0;
	// The numbers of hours between each calls to the reflex "testRestockNeeded"
	float numberOfHoursBeforeTRN <- 24.0;
	// The numbers of hours between each calls to the reflex "processOrders"
	float numberofHoursBeforePO <- 24.0;
	
	int sizeOfStockLocalWarehouse <- 2;
	int sizeOfStockLargeWarehouse <- 3;
	
	float threshold <- 0.3;
	
	/**
	 * Each final destination manager is associated to a rate of decreasing of his stocks.
	 * This rate is computed thanks to a linear function according to the previously computed Huff value associated to the building.
	 * The more the Huff value is high, the more the stocks decrease quickly, the more the rate is down
	 */
	float valForMinHuff <- 6.0;
	float valForMaxHuff <- 4.0;
	action init_decreasingRateOfStocks {
		list<FinalDestinationManager> dests <- FinalDestinationManager sort_by each.huffValue;
		int i <- 0;
		int ld <- length(dests);
		loop while: i < ld {
			FinalDestinationManager fdm <- dests[i];
			fdm.decreasingRateOfStocks <- round(((valForMaxHuff-valForMinHuff) / (length(dests)-1)) * (i) + valForMinHuff);
			i <- i + 1;
		}
	}
}