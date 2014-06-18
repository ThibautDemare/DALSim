/**
 *  Observer
 *  Author: Thibaut
 *  Description: 
 */

model Observer

import "./SeineAxisModel.gaml"
import "./FinalDestinationManager.gaml"
import "./Batch.gaml"
import "./Warehouse.gaml"
import "./Building.gaml"
import "./Parameters.gaml"

global {
	float stockInFinalDest <- 0.0;
	float stockInWarehouse <- 0.0;
	
	int totalNumberOfBatch <- 0;
	int numberOfBatchProviderToLarge <- 0;
	int numberOfBatchLargeToAverage <- 0;
	int numberOfBatchAverageToSmall <- 0;
	int numberOfBatchSmallToFinal <- 0;
	
	float stockOnRoads <- 0.0;
	float stockOnRoadsProviderToLarge <- 0.0;
	float stockOnRoadsLargeToAverage <- 0.0;
	float stockOnRoadsAverageToSmall <- 0.0;
	float stockOnRoadsSmallToFinal <- 0.0;
		
	reflex updateStockInBuildings when:((time/3600.0) mod numberOfHoursBeforeTON) = 0{
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
		numberOfBatchLargeToAverage <- 0;
		numberOfBatchAverageToSmall <- 0;
		numberOfBatchSmallToFinal <- 0;
		stockOnRoadsProviderToLarge <- 0.0;
		stockOnRoadsLargeToAverage <- 0.0;
		stockOnRoadsAverageToSmall <- 0.0;
		stockOnRoadsSmallToFinal <- 0.0;
		
		// Filter the right agents
		ask Batch {
			if(self.color = "blue"){
				numberOfBatchProviderToLarge <- numberOfBatchProviderToLarge + 1;
				stockOnRoadsProviderToLarge <- stockOnRoadsProviderToLarge + self.quantity;
			}
			else if(self.color = "green"){
				numberOfBatchLargeToAverage <- numberOfBatchLargeToAverage + 1;
				stockOnRoadsLargeToAverage <- stockOnRoadsLargeToAverage + self.quantity;
			}
			else if(self.color = "orange"){
				numberOfBatchAverageToSmall <- numberOfBatchAverageToSmall + 1;
				stockOnRoadsAverageToSmall <- stockOnRoadsAverageToSmall + self.quantity;
			}
			else if(self.color = "red"){
				numberOfBatchSmallToFinal <- numberOfBatchSmallToFinal + 1;
				stockOnRoadsSmallToFinal <- stockOnRoadsSmallToFinal + self.quantity;
			}
			totalNumberOfBatch <- totalNumberOfBatch + 1;
			
		}
		stockOnRoads <- stockOnRoadsProviderToLarge + stockOnRoadsLargeToAverage + stockOnRoadsAverageToSmall + stockOnRoadsSmallToFinal;
	}
}