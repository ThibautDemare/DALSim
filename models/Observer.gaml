/**
 *  Observer
 *  Author: Thibaut
 *  Description: 
 */

model Observer

import "./FinalDestinationManager.gaml"
import "./Batch.gaml"
import "./Warehouse.gaml"
import "./Parameters.gaml"
import "./Stock.gaml"

global {
	float stockInFinalDest <- 0.0;
	float stockInWarehouse <- 0.0;
	
	int totalNumberOfBatch <- 0;
	int numberOfBatchProviderToLarge <- 0;
	int numberOfBatchLargeToClose <- 0;
	int numberOfBatchCloseToFinal <- 0;
	
	float stockOnRoads <- 0.0;
	float stockOnRoadsProviderToLarge <- 0.0;
	float stockOnRoadsLargeToClose <- 0.0;
	float stockOnRoadsCloseToFinal <- 0.0;
		
	reflex updateStockInBuildings when:((time/3600.0) mod numberOfHoursBeforeTRN) = 0{
		stockInFinalDest <- 0.0;
		ask FinalDestinationManager {
			ask self.building.stocks {
				stockInFinalDest <- stockInFinalDest + self.quantity;
			}
		}
		stockInWarehouse <- 0.0;
		ask Warehouse {
			ask self.stocks {
				stockInWarehouse <- stockInWarehouse + self.quantity;
			}
		}
	}
	
	/**
	 * 
	 */
	reflex updateBatch  {//when:((time/3600.0) mod numberOfHoursBeforeTON) = 0{
		// Init to zero
		totalNumberOfBatch <- 0;
		numberOfBatchProviderToLarge <- 0;
		numberOfBatchLargeToClose <- 0;
		numberOfBatchCloseToFinal <- 0;
		stockOnRoadsProviderToLarge <- 0.0;
		stockOnRoadsLargeToClose <- 0.0;
		stockOnRoadsCloseToFinal <- 0.0;
		
		// Filter the right agents
		ask Batch {
			if(self.position = 0){
				numberOfBatchProviderToLarge <- numberOfBatchProviderToLarge + 1;
				stockOnRoadsProviderToLarge <- stockOnRoadsProviderToLarge + self.overallQuantity;
			}
			else if(self.position = 1){
				numberOfBatchLargeToClose <- numberOfBatchLargeToClose + 1;
				stockOnRoadsLargeToClose <- stockOnRoadsLargeToClose + self.overallQuantity;
			}
			else if(self.position = 2){
				numberOfBatchCloseToFinal <- numberOfBatchCloseToFinal + 1;
				stockOnRoadsCloseToFinal <- stockOnRoadsCloseToFinal + self.overallQuantity;
			}
			totalNumberOfBatch <- totalNumberOfBatch + 1;
			
		}
		stockOnRoads <- stockOnRoadsProviderToLarge + stockOnRoadsLargeToClose + stockOnRoadsCloseToFinal;
	}
}