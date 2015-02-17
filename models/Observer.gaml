/**
 *  Observer
 *  Author: Thibaut
 *  Description: 
 */

model Observer

import "./FinalDestinationManager.gaml"
import "./LogisticProvider.gaml"
import "./Batch.gaml"
import "./Warehouse.gaml"
import "./Building.gaml"
import "./Parameters.gaml"
import "./Stock.gaml"

global {
	int numberofEmptyStockInFinalDests <- 0;
	int numberOfEmptyStockInWarehouses <- 0;
	
	float stockInFinalDest <- 0.0;
	float freeSurfaceInFinalDest <- 0.0;
	float stockInWarehouse <- 0.0;
	float freeSurfaceInWarehouse <- 0.0;
	
	int totalNumberOfBatch <- 0;
	int cumulativeNumberOfBatch <- 0;
	int numberOfBatchProviderToLarge <- 0;
	int cumulativeNumberOfBatchProviderToLarge <- 0;
	int numberOfBatchLargeToClose <- 0;
	int cumulativeNumberOfBatchLargeToClose <- 0;
	int numberOfBatchCloseToFinal <- 0;
	int cumulativeNumberOfBatchCloseToFinal <- 0;
	
	float stockOnRoads <- 0.0;
	float cumulativeStockOnRoads <- 0.0;
	float stockOnRoadsProviderToLarge <- 0.0;
	float cumulativeStockOnRoadsProviderToLarge <- 0.0;
	float stockOnRoadsLargeToClose <- 0.0;
	float cumulativeStockOnRoadsLargeToClose <- 0.0;
	float stockOnRoadsCloseToFinal <- 0.0;
	float cumulativeStockOnRoadsCloseToFinal <- 0.0;
	
	reflex updateStockInBuildings {
		do computeStockInFinalDests;
		do computeStockInWarehouses;
	}
	
	action computeStockInFinalDests{
		stockInFinalDest <- 0.0;
		freeSurfaceInFinalDest <- 0.0;
		numberofEmptyStockInFinalDests <- 0;
		float totalNumberOfStock <- 0.0;
		ask FinalDestinationManager {
			float tempStock <- 0.0;
			ask self.building.stocks {
				stockInFinalDest <- stockInFinalDest + self.quantity;
				tempStock <- tempStock + self.quantity;
				totalNumberOfStock <- totalNumberOfStock + 1;
				if(self.quantity = 0){
					numberofEmptyStockInFinalDests <- numberofEmptyStockInFinalDests + 1;
				}
			}
			freeSurfaceInFinalDest <- freeSurfaceInFinalDest + (surface - tempStock);
		}
	}
	
	action computeStockInWarehouses {
		stockInWarehouse <- 0.0;
		freeSurfaceInWarehouse <- 0.0;
		numberOfEmptyStockInWarehouses <- 0;
		float totalNumberOfStock <- 0.0;
		ask Warehouse {
			float tempStock <- 0.0;
			ask self.stocks {
				stockInWarehouse <- stockInWarehouse + self.quantity;
				tempStock <- tempStock + self.quantity;
				totalNumberOfStock <- totalNumberOfStock + 1;
				if(self.quantity = 0){
					numberOfEmptyStockInWarehouses <- numberOfEmptyStockInWarehouses + 1;
				}
			}
			freeSurfaceInWarehouse <- freeSurfaceInWarehouse + (surfaceUsedForLH - tempStock);
		}
	}
	
	/**
	 * 
	 */
	reflex updateBatch  {
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
			cumulativeNumberOfBatch <- cumulativeNumberOfBatch + 1;
			
		}
		stockOnRoads <- stockOnRoadsProviderToLarge + stockOnRoadsLargeToClose + stockOnRoadsCloseToFinal;
		cumulativeStockOnRoads <- cumulativeStockOnRoads + stockOnRoads;
	}

	reflex update_average_time_to_deliver {
		int i <- 0;
		int sum <- 0;
		ask LogisticProvider {
			int j <- 0;
			loop while: j<length(timeToDeliver) {
				sum <- sum + timeToDeliver[j];
				j <- j + 1;
				i <- i + 1;
			}
		}
		if(i > 0){
			write (sum/i);
		}
	}
}