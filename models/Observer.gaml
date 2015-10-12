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
	list<float> averagesLPEfficiency <- [];
	float averageLPEfficiency <- 0.0;
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
	
	float averageTimeToDeliver <- 0.0;

	reflex updateStockInBuildings {
		do computeStockInFinalDests;
		do computeStockInWarehouses;
	}
	
	/*
	 * This method computes the free surface of every final destination, the surface used, and the number of stock shortages
	 * This number of stock shortages is stored in an array 'lpEfficiencies' in order to used it as a perforamnce measure of the logistic provider collaborating with the final destination manager.
	 */
	action computeStockInFinalDests{
		stockInFinalDest <- 0.0;
		freeSurfaceInFinalDest <- 0.0;
		numberofEmptyStockInFinalDests <- 0;
		float totalNumberOfStock <- 0.0;
		ask FinalDestinationManager {
			float tempStock <- 0.0;
			float nbStockShortages <- 0.0;
			ask self.building.stocks {
				stockInFinalDest <- stockInFinalDest + self.quantity;
				if(self.quantity = 0){
					nbStockShortages <- nbStockShortages + 1.0;
				}
				tempStock <- tempStock + self.quantity;
				totalNumberOfStock <- totalNumberOfStock + 1;
				if(self.quantity = 0){
					numberofEmptyStockInFinalDests <- numberofEmptyStockInFinalDests + 1;
				}
			}
			self.localLPEfficiencies <- localLPEfficiencies + nbStockShortages;
			freeSurfaceInFinalDest <- freeSurfaceInFinalDest + (surface - tempStock);
		}
	}
	
	/*
	 * This reflex updates every step the average efficiency of every logistic provider, but also the estimated efficiency at the FDM level.
	 */
	reflex updateAverageLPEfficiency {
		float currentLPEfficiency <- 0;
		ask FinalDestinationManager {
			int i <- 0;
			self.localAverageLPEfficiency <- 0;
			loop while: i < length(localLPEfficiencies) {
				self.localAverageLPEfficiency <- self.localAverageLPEfficiency + localLPEfficiencies[i];
				i <- i + 1;
			}
			self.localAverageLPEfficiency <- self.localAverageLPEfficiency / length(localLPEfficiencies);
			currentLPEfficiency <- currentLPEfficiency + self.localAverageLPEfficiency;
		}
		currentLPEfficiency <- currentLPEfficiency / length(FinalDestinationManager);
		averagesLPEfficiency <- averagesLPEfficiency + 0.0;
		if(length(averagesLPEfficiency) > numberOfStepConsideredForLPEfficiency){
			remove index: 0 from: averagesLPEfficiency;
		}
		averagesLPEfficiency[length(averagesLPEfficiency)-1] <- averagesLPEfficiency[length(averagesLPEfficiency)-1] + currentLPEfficiency;
		int i <- 0;
		averageLPEfficiency <- 0.0;
		loop while: i < length(averagesLPEfficiency) {
			averageLPEfficiency <- averageLPEfficiency + averagesLPEfficiency[i];
			i <- i + 1;
		}
		averageLPEfficiency <- averageLPEfficiency / length(averagesLPEfficiency);
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
			averageTimeToDeliver <- (sum/i);
		}
	}
}