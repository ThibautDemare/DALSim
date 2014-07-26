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
	
	/*
	 * Some variables and functions to call some reflex
	 */
	 
	// Minimum stock of the final destination in percentage before ordered a restock
	float minimumStockFinalDestPercentage <- 0.05;
	// The probability to change sometimes of logistic provider
	float probabilityToChangeLogisticProvider <- 0.9;
	// The numbers of hours between each calls to the reflex "updateCurrentInertia"
	float numberOfHoursBeforeUCI <- 720.0;
	// The numbers of hours between each calls to the reflex "decreasingStocks"
	float numberOfHoursBeforeDS <- 24.0;
	// The numbers of hours between each calls to the reflex "testRestockNeeded"
	float numberOfHoursBeforeTRN <- 24.0;
	// The numbers of hours between each calls to the reflex "processOrders"
	float numberofHoursBeforePO <- 24.0;
	
	int sizeOfStockLocalWarehouse <- 2.0;
	int sizeOfStockLargeWarehouse <- 4.0;
	
	float threshold <- 0.5;
	
	/**
	 * The final destinations are separated in 4 ordered sets. To each final destinations of these sets, we associate a decreasing rate of 
	 * stocks according to the number of customer computed by the Huff model. The more the customers there are, the more the decreasing 
	 * rate allows a large consumption.
	 */
	action init_decreasingRateOfStocks {
		list<FinalDestinationManager> dests <- FinalDestinationManager sort_by each.huffValue;
		int i <- 0;
		int ld <- length(dests);
		loop while: i < ld {
			FinalDestinationManager fdm <- dests[i];
			if(i<length(dests)/4){
				fdm.decreasingRateOfStocks <- 9;
			}
			else if(i<length(dests)*2/4){
				fdm.decreasingRateOfStocks <- 7;
			}
			else if(i<length(dests)*3/4){
				fdm.decreasingRateOfStocks <- 5;
			}
			else {
				fdm.decreasingRateOfStocks <- 3;
			}
			i <- i + 1;
		}
	}
}