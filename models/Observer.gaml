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

global {
	// Obeservation variables
		// Average  variables
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
	float stockInFinalDest <- 0.0;
	float stockInWarehouse <- 0.0;
		// T1 variables
	int totalNumberOfBatchT1 <- 0;
	int numberOfBatchProviderToLargeT1 <- 0;
	int numberOfBatchLargeToAverageT1 <- 0;
	int numberOfBatchAverageToSmallT1 <- 0;
	int numberOfBatchSmallToFinalT1 <- 0;
	float stockOnRoadsT1 <- 0.0;
	float stockOnRoadsProviderToLargeT1 <- 0.0;
	float stockOnRoadsLargeToAverageT1 <- 0.0;
	float stockOnRoadsAverageToSmallT1 <- 0.0;
	float stockOnRoadsSmallToFinalT1 <- 0.0;
	float stockInFinalDestT1 <- 0.0;
	float stockInWarehouseT1 <- 0.0;
		// T2 variables
	int totalNumberOfBatchT2 <- 0;
	int numberOfBatchProviderToLargeT2 <- 0;
	int numberOfBatchLargeToAverageT2 <- 0;
	int numberOfBatchAverageToSmallT2 <- 0;
	int numberOfBatchSmallToFinalT2 <- 0;
	float stockOnRoadsT2 <- 0.0;
	float stockOnRoadsProviderToLargeT2 <- 0.0;
	float stockOnRoadsLargeToAverageT2 <- 0.0;
	float stockOnRoadsAverageToSmallT2 <- 0.0;
	float stockOnRoadsSmallToFinalT2 <- 0.0;
	float stockInFinalDestT2 <- 0.0;
	float stockInWarehouseT2 <- 0.0;
	
	
	/**
	 * 
	 */
	reflex updateObservationValue {
		// Keep old value in *T1
		numberOfBatchProviderToLargeT1 <- numberOfBatchProviderToLargeT2;
		numberOfBatchLargeToAverageT1 <- numberOfBatchLargeToAverageT2;
		numberOfBatchAverageToSmallT1 <- numberOfBatchAverageToSmallT2;
		numberOfBatchSmallToFinalT1 <- numberOfBatchSmallToFinalT2;
		stockOnRoadsProviderToLargeT2 <- stockOnRoadsProviderToLargeT1;
		stockOnRoadsLargeToAverageT2 <- stockOnRoadsLargeToAverageT1;
		stockOnRoadsAverageToSmallT2 <- stockOnRoadsAverageToSmallT1;
		stockOnRoadsSmallToFinalT2 <- stockOnRoadsSmallToFinalT1;
		stockInFinalDestT1 <- stockInFinalDestT2;
		stockInWarehouseT1 <- stockInWarehouseT2;
		
		// Compute current value in *T2
		totalNumberOfBatchT2 <- length(Batch);
		numberOfBatchProviderToLargeT2 <- 0;
		numberOfBatchLargeToAverageT2 <- 0;
		numberOfBatchAverageToSmallT2 <- 0;
		numberOfBatchSmallToFinalT2 <- 0;
		stockOnRoadsProviderToLargeT2 <- 0.0;
		stockOnRoadsLargeToAverageT2 <- 0.0;
		stockOnRoadsAverageToSmallT2 <- 0.0;
		stockOnRoadsSmallToFinalT2 <- 0.0;
		ask Batch {
			if(self.color = "blue"){
				numberOfBatchProviderToLargeT2 <- numberOfBatchProviderToLargeT2 + 1;
				stockOnRoadsProviderToLargeT2 <- stockOnRoadsProviderToLargeT2 + self.quantity;
			}
			else if(self.color = "green"){
				numberOfBatchLargeToAverageT2 <- numberOfBatchLargeToAverageT2 + 1;
				stockOnRoadsLargeToAverageT2 <- stockOnRoadsLargeToAverageT2 + self.quantity;
			}
			else if(self.color = "orange"){
				numberOfBatchAverageToSmallT2 <- numberOfBatchAverageToSmallT2 + 1;
				stockOnRoadsAverageToSmallT2 <- stockOnRoadsAverageToSmallT2 + self.quantity;
			}
			else if(self.color = "red"){
				numberOfBatchSmallToFinalT2 <- numberOfBatchSmallToFinalT2 + 1;
				stockOnRoadsSmallToFinalT2 <- stockOnRoadsSmallToFinalT2 + self.quantity;
			}
		}
		stockOnRoadsT2 <- stockOnRoadsProviderToLargeT2 + stockOnRoadsLargeToAverageT2 + stockOnRoadsAverageToSmallT2 + stockOnRoadsSmallToFinalT2;
		
		stockInFinalDestT2 <- 0.0;
		ask FinalDestinationManager {
			ask self.building.stocks {
				stockInFinalDestT2 <- stockInFinalDestT2 + self.quantity;
			}
		}
		stockInWarehouseT2 <- 0.0;
		ask Warehouse {
			ask self.stocks {
				stockInWarehouseT2 <- stockInWarehouseT2 + self.quantity;
			}
		}
	}

	/**
	 * 
	 */
	reflex updateAverageObservationValue when: ((time/3600.0) mod 24.0) = 0.0  {
		// Update mean values
		numberOfBatchProviderToLarge <- (numberOfBatchProviderToLargeT2 + numberOfBatchProviderToLargeT1)/2;
		numberOfBatchLargeToAverage <- (numberOfBatchLargeToAverageT2 + numberOfBatchLargeToAverageT1)/2;
		numberOfBatchAverageToSmall <- (numberOfBatchAverageToSmallT2 + numberOfBatchAverageToSmallT1)/2;
		numberOfBatchSmallToFinal <- (numberOfBatchSmallToFinalT2 + numberOfBatchSmallToFinalT1)/2;
		totalNumberOfBatch <- numberOfBatchProviderToLarge + numberOfBatchLargeToAverage + numberOfBatchAverageToSmall + numberOfBatchSmallToFinal;
		
		stockOnRoadsProviderToLarge <- (stockOnRoadsProviderToLargeT2 + stockOnRoadsProviderToLargeT1)/2.0;
		stockOnRoadsLargeToAverage <- (stockOnRoadsLargeToAverageT2 + stockOnRoadsLargeToAverageT1)/2.0;
		stockOnRoadsAverageToSmall <- (stockOnRoadsAverageToSmallT2 + stockOnRoadsAverageToSmallT1)/2.0;
		stockOnRoadsSmallToFinal <- (stockOnRoadsSmallToFinalT2 + stockOnRoadsSmallToFinalT1)/2.0;
		stockOnRoads <- stockOnRoadsProviderToLarge + stockOnRoadsLargeToAverage + stockOnRoadsAverageToSmall + stockOnRoadsSmallToFinal;
		
		stockInFinalDest <- (stockInFinalDestT2 + stockInFinalDestT1)/2.0;
		stockInWarehouse <- (stockInWarehouseT2 + stockInWarehouseT1)/2.0;
	}
	
}