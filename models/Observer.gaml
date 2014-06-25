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
	int cumulativeNumberOfBatchProviderToLarge <- 0;
	int numberOfBatchLargeToClose <- 0;
	int cumulativeNumberOfBatchLargeToClose <- 0;
	int numberOfBatchCloseToFinal <- 0;
	int cumulativeNumberOfBatchCloseToFinal <- 0;
	
	float stockOnRoads <- 0.0;
	float stockOnRoadsProviderToLarge <- 0.0;
	float cumulativeStockOnRoadsProviderToLarge <- 0.0;
	float stockOnRoadsLargeToClose <- 0.0;
	float cumulativeStockOnRoadsLargeToClose <- 0.0;
	float stockOnRoadsCloseToFinal <- 0.0;
	float cumulativeStockOnRoadsCloseToFinal <- 0.0;
	
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
	reflex updateBatch  when:(time/3600.0) > 200{
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
			if(self.position = 1){
				numberOfBatchProviderToLarge <- numberOfBatchProviderToLarge + 1;
				cumulativeNumberOfBatchProviderToLarge <- cumulativeNumberOfBatchProviderToLarge + 1;
				stockOnRoadsProviderToLarge <- stockOnRoadsProviderToLarge + self.overallQuantity;
				cumulativeStockOnRoadsProviderToLarge <- cumulativeStockOnRoadsProviderToLarge + self.overallQuantity;
			}
			else if(self.position = 2){
				numberOfBatchLargeToClose <- numberOfBatchLargeToClose + 1;
				cumulativeNumberOfBatchLargeToClose <- cumulativeNumberOfBatchLargeToClose + 1;
				stockOnRoadsLargeToClose <- stockOnRoadsLargeToClose + self.overallQuantity;
				cumulativeStockOnRoadsLargeToClose <- cumulativeStockOnRoadsLargeToClose + self.overallQuantity;
			}
			else if(self.position = 3){
				numberOfBatchCloseToFinal <- numberOfBatchCloseToFinal + 1;
				cumulativeNumberOfBatchCloseToFinal <- cumulativeNumberOfBatchCloseToFinal + 1;
				stockOnRoadsCloseToFinal <- stockOnRoadsCloseToFinal + self.overallQuantity;
				cumulativeStockOnRoadsCloseToFinal <- cumulativeStockOnRoadsCloseToFinal + self.overallQuantity;
			}
			totalNumberOfBatch <- totalNumberOfBatch + 1;
			
		}
		stockOnRoads <- stockOnRoadsProviderToLarge + stockOnRoadsLargeToClose + stockOnRoadsCloseToFinal;
	}
}