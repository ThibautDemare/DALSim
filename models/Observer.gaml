model Observer

import "FinalDestinationManager.gaml"

global {
	string date_simu_starts <- nil;

	bool saveObservations <- true;

	int nbLPStrat1 <- 0;
	int nbLPStrat2 <- 0;
	int nbLPStrat3 <- 0;
	int nbLPStrat4 <- 0;

	int nbStocksAwaitingToEnterBuilding;
	int nbStocksAwaitingToEnterWarehouse;
	int nbStocksAwaitingToLeaveWarehouse;
	int nbStocksAwaitingToLeaveProvider;

	list<float> averagesNbStockShortages <- [];
	float averageNbStockShortages <- 0.0;

	int numberofEmptyStockInFinalDests <- 0;
	int numberOfEmptyStockInWarehouses <- 0;
	
	float stockInFinalDest <- 0.0;
	float freeSurfaceInFinalDest <- 0.0;
	float stockInWarehouse <- 0.0;
	float freeSurfaceInWarehouse <- 0.0;
	
//	int totalNumberOfBatch <- 0;
//	int cumulativeNumberOfBatch <- 0;
//	int numberOfBatchProviderToLarge <- 0;
//	int cumulativeNumberOfBatchProviderToLarge <- 0;
//	int numberOfBatchLargeToClose <- 0;
//	int cumulativeNumberOfBatchLargeToClose <- 0;
//	int numberOfBatchCloseToFinal <- 0;
//	int cumulativeNumberOfBatchCloseToFinal <- 0;
//	
//	float stockOnRoads <- 0.0;
//	float cumulativeStockOnRoads <- 0.0;
//	float stockOnRoadsProviderToLarge <- 0.0;
//	float cumulativeStockOnRoadsProviderToLarge <- 0.0;
//	float stockOnRoadsLargeToClose <- 0.0;
//	float cumulativeStockOnRoadsLargeToClose <- 0.0;
//	float stockOnRoadsCloseToFinal <- 0.0;
//	float cumulativeStockOnRoadsCloseToFinal <- 0.0;
//
//	float averageGoodsQuantityPerBatch <- 0.0;
//	float sumGoods <- 0.0;

	// These variables are used to measure the efficiency of the logistic provider to deliver quickly the goods
	float averageTimeToDeliver <- 0.0;
	float averageTimeToBeDelivered <- 0.0;

	float averageCosts;

	int nbHavre;
	int nbAntwerp;

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
				if(self.quantity <= 0){
					nbStockShortages <- nbStockShortages + 1.0;
				}
				tempStock <- tempStock + self.quantity;
				totalNumberOfStock <- totalNumberOfStock + 1;
				if(self.quantity = 0){
					numberofEmptyStockInFinalDests <- numberofEmptyStockInFinalDests + 1;
				}
			}
			self.localNbStockShortagesLastSteps <- localNbStockShortagesLastSteps + nbStockShortages;
			freeSurfaceInFinalDest <- freeSurfaceInFinalDest + (surface - tempStock);
		}
	}

	reflex updateNbStockAwaiting {
		nbStocksAwaitingToEnterBuilding <- 0;
		ask Building {
			nbStocksAwaitingToEnterBuilding <- nbStocksAwaitingToEnterBuilding + length(entering_stocks);
		}
		nbStocksAwaitingToEnterWarehouse <- 0;
		ask Warehouse {
			nbStocksAwaitingToEnterWarehouse <- nbStocksAwaitingToEnterWarehouse + length(entering_stocks);
		}
		nbStocksAwaitingToLeaveWarehouse <- 0;
		ask Warehouse {
			nbStocksAwaitingToLeaveWarehouse <- nbStocksAwaitingToLeaveWarehouse + length(currentOrders);
		}
		nbStocksAwaitingToLeaveProvider <- 0;
		ask Provider {
			nbStocksAwaitingToLeaveProvider <- nbStocksAwaitingToLeaveProvider + length(currentOrders);
		}
	}

	/*
	 * This reflex updates every step the average efficiency of every logistic provider, but also the estimated efficiency at the FDM level.
	 */
	reflex updateAverageLPEfficiency {
		float currentNbStockShortages <- 0;
		ask FinalDestinationManager {
			int i <- 0;
			self.localAverageNbStockShortagesLastSteps <- 0;
			loop while: i < length(localNbStockShortagesLastSteps) {
				self.localAverageNbStockShortagesLastSteps <- self.localAverageNbStockShortagesLastSteps + localNbStockShortagesLastSteps[i];
				i <- i + 1;
			}
			self.localAverageNbStockShortagesLastSteps <- self.localAverageNbStockShortagesLastSteps / length(localNbStockShortagesLastSteps);
			currentNbStockShortages <- currentNbStockShortages + self.localAverageNbStockShortagesLastSteps;
		}
		currentNbStockShortages <- currentNbStockShortages / length(FinalDestinationManager);
		averagesNbStockShortages <- averagesNbStockShortages + 0.0;
		if(length(averagesNbStockShortages) > nbStepsConsideredForLPEfficiency){
			remove index: 0 from: averagesNbStockShortages;
		}
		averagesNbStockShortages[length(averagesNbStockShortages)-1] <- averagesNbStockShortages[length(averagesNbStockShortages)-1] + currentNbStockShortages;
		int i <- 0;
		averageNbStockShortages <- 0.0;
		loop while: i < length(averagesNbStockShortages) {
			averageNbStockShortages <- averagesNbStockShortages + averagesNbStockShortages[i];
			i <- i + 1;
		}
		averageNbStockShortages <- averageNbStockShortages / length(averagesNbStockShortages);
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
			freeSurfaceInWarehouse <- freeSurfaceInWarehouse + (totalSurface - tempStock);
		}
	}
	
	/**
	 * 
	 */
//	reflex updateBatch  {
//		// Init to zero
//		totalNumberOfBatch <- 0;
//		numberOfBatchProviderToLarge <- 0;
//		numberOfBatchLargeToClose <- 0;
//		numberOfBatchCloseToFinal <- 0;
//		stockOnRoadsProviderToLarge <- 0.0;
//		stockOnRoadsLargeToClose <- 0.0;
//		stockOnRoadsCloseToFinal <- 0.0;
//		
//		averageGoodsQuantityPerBatch <- 0.0;
//		sumGoods <- 0.0;
//		int nbBatchNotMarked <- 0;
//		// Filter the right agents
//		ask Vehicle {
//			if(!marked){
//				marked <- true;
//				if(self.position = 1){
//					cumulativeNumberOfBatchProviderToLarge <- cumulativeNumberOfBatchProviderToLarge + 1;
//					cumulativeStockOnRoadsProviderToLarge <- cumulativeStockOnRoadsProviderToLarge + self.overallQuantity;
//				}
//				else if(self.position = 2){
//					cumulativeNumberOfBatchLargeToClose <- cumulativeNumberOfBatchLargeToClose + 1;
//					cumulativeStockOnRoadsLargeToClose <- cumulativeStockOnRoadsLargeToClose + self.overallQuantity;
//				}
//				else if(self.position = 3){
//					cumulativeNumberOfBatchCloseToFinal <- cumulativeNumberOfBatchCloseToFinal + 1;
//					cumulativeStockOnRoadsCloseToFinal <- cumulativeStockOnRoadsCloseToFinal + self.overallQuantity;
//				}
//				if(self.position > 0){
//					cumulativeNumberOfBatch <- cumulativeNumberOfBatch + 1;
//					cumulativeStockOnRoads <- cumulativeStockOnRoads + self.overallQuantity;
//				}
//				sumGoods <- sumGoods + self.overallQuantity;
//				nbBatchNotMarked <- nbBatchNotMarked + 1;
//			}
//			if(self.position = 1){
//				numberOfBatchProviderToLarge <- numberOfBatchProviderToLarge + 1;
//				stockOnRoadsProviderToLarge <- stockOnRoadsProviderToLarge + self.overallQuantity;
//			}
//			else if(self.position = 2){
//				numberOfBatchLargeToClose <- numberOfBatchLargeToClose + 1;
//				stockOnRoadsLargeToClose <- stockOnRoadsLargeToClose + self.overallQuantity;
//			}
//			else if(self.position = 3){
//				numberOfBatchCloseToFinal <- numberOfBatchCloseToFinal + 1;
//				stockOnRoadsCloseToFinal <- stockOnRoadsCloseToFinal + self.overallQuantity;
//			}
//			if(self.position > 0){
//				totalNumberOfBatch <- totalNumberOfBatch + 1;
//			}
//		}
//		stockOnRoads <- stockOnRoadsProviderToLarge + stockOnRoadsLargeToClose + stockOnRoadsCloseToFinal;
//		if(nbBatchNotMarked > 0){
//			averageGoodsQuantityPerBatch <- sumGoods / nbBatchNotMarked;
//		}
//		else {
//			averageGoodsQuantityPerBatch <- 0.0;
//		}
//	}

	reflex update_average_time_to_deliver {
		// Update the average time to deliver (at the LPs level)
		int i <- 0;
		int sum <- 0;
		ask LogisticsServiceProvider {
			if(length(customers) > 0){
				int j <- 0;

				loop while: 50 < length(timeToDeliver) {
					remove index: 0 from: timeToDeliver;
				}

				loop while: j<length(timeToDeliver) {
					sum <- sum + timeToDeliver[j];
					j <- j + 1;
					i <- i + 1;
				}

			}
		}

		if(i > 0){
			averageTimeToDeliver <- (sum/i);
		}

		// Update the average time to be delivered (at the FDMs level)
		i <- 0;
		sum <- 0;
		ask FinalDestinationManager {
			int j <- 0;
			int localSum <- 0;

			loop while: 50 < length(localTimeToBeDeliveredLastDeliveries) {
				remove index: 0 from: localTimeToBeDeliveredLastDeliveries;
			}

			loop while: j<length(localTimeToBeDeliveredLastDeliveries) {
				sum <- sum + localTimeToBeDeliveredLastDeliveries[j];
				localSum <- localSum + localTimeToBeDeliveredLastDeliveries[j];
				j <- j + 1;
				i <- i + 1;
			}
			if( length(localTimeToBeDeliveredLastDeliveries) > 0){
				localTimeToBeDelivered <- localSum / length(localTimeToBeDeliveredLastDeliveries);
			}
		}
		if(i > 0){
			averageTimeToBeDelivered <- (sum/i);
		}
	}

	reflex update_average_costs {
		// Update the average costs
		int i <- 0;
		float sum <- 0;
		ask FinalDestinationManager {
			if(length(localTransportationCosts) > 0){
				int j <- 0;
				float localSum <- 0;

				loop while: 50 < length(localTransportationCosts) {
					remove index: 0 from: localTransportationCosts;
				}

				loop while: j<length(localTransportationCosts) {
					localSum <- localSum + localTransportationCosts[j];
					j <- j + 1;
				}
				localAverageCosts <- localWarehousingCosts + localSum / length(localTransportationCosts);
				sum <- sum + localAverageCosts;
				i <- i + 1;
			}
		}
		if(i > 0){
			averageCosts <- (sum/i);
		}
	}

	// Share by number of vehicles
	float sumVehicle;
	float sumRoadVehicle;
	float sumRiverVehicle;
	float sumMaritimeVehicle;
	float shareRoadVehicle;
	float shareRiverVehicle;
	float shareMaritimeVehicle;
	// Share by quantities of goods
	float sumQuantities;
	float sumRoadQuantities;
	float sumRiverQuantities;
	float sumMaritimeQuantities;
	float shareRoadQuantities;
	float shareRiverQuantities;
	float shareMaritimeQuantities;
	reflex averageModeShare {
		sumVehicle <- 0.0;
		sumRoadVehicle <- 0.0;
		sumRiverVehicle <- 0.0;
		sumMaritimeVehicle <- 0.0;

		sumQuantities <- 0.0;
		sumRoadQuantities <- 0.0;
		sumRiverQuantities <- 0.0;
		sumMaritimeQuantities <- 0.0;

		ask RegionObserver {
			sumVehicleRO <- 0.0;
			sumRoadVehicleRO <- 0.0;
			sumRiverVehicleRO <- 0.0;
			sumMaritimeVehicleRO <- 0.0;

			sumQuantitiesRO <- 0.0;
			sumRoadQuantitiesRO <- 0.0;
			sumRiverQuantitiesRO <- 0.0;
			sumMaritimeQuantitiesRO <- 0.0;

			int j <- 0;
			loop while: j < length(buildings) {
				Building b <- buildings[j];

				int i <- 0;
				loop while: i < length(b.nbRoadVehiclesLastSteps) {
					sumVehicle <- sumVehicle + b.nbRoadVehiclesLastSteps[i] + b.nbRiverVehiclesLastSteps[i] + b.nbMaritimeVehiclesLastSteps[i];
					sumRoadVehicle <- sumRoadVehicle + b.nbRoadVehiclesLastSteps[i];
					sumRiverVehicle <- sumRiverVehicle + b.nbRiverVehiclesLastSteps[i];
					sumMaritimeVehicle <- sumMaritimeVehicle + b.nbMaritimeVehiclesLastSteps[i];

					sumVehicleRO <- sumVehicleRO + b.nbRoadVehiclesLastSteps[i] + b.nbRiverVehiclesLastSteps[i] + b.nbMaritimeVehiclesLastSteps[i];
					sumRoadVehicleRO <- sumRoadVehicleRO + b.nbRoadVehiclesLastSteps[i];
					sumRiverVehicleRO <- sumRiverVehicleRO + b.nbRiverVehiclesLastSteps[i];
					sumMaritimeVehicleRO <- sumMaritimeVehicleRO + b.nbMaritimeVehiclesLastSteps[i];

					sumQuantities <- sumQuantities + b.nbRoadQuantitiesLastSteps[i] + b.nbRiverQuantitiesLastSteps[i] + b.nbMaritimeQuantitiesLastSteps[i];
					sumRoadQuantities <- sumRoadQuantities + b.nbRoadQuantitiesLastSteps[i];
					sumRiverQuantities <- sumRiverQuantities + b.nbRiverQuantitiesLastSteps[i];
					sumMaritimeQuantities <- sumMaritimeQuantities + b.nbMaritimeQuantitiesLastSteps[i];

					sumQuantitiesRO <- sumQuantitiesRO + b.nbRoadQuantitiesLastSteps[i] + b.nbRiverQuantitiesLastSteps[i] + b.nbMaritimeQuantitiesLastSteps[i];
					sumRoadQuantitiesRO <- sumRoadQuantitiesRO + b.nbRoadQuantitiesLastSteps[i];
					sumRiverQuantitiesRO <- sumRiverQuantitiesRO + b.nbRiverQuantitiesLastSteps[i];
					sumMaritimeQuantitiesRO <- sumMaritimeQuantitiesRO + b.nbMaritimeQuantitiesLastSteps[i];

					i <- i + 1;
				}
				if(cycle > -1){
					remove index: 0 from: b.nbRoadVehiclesLastSteps;
					remove index: 0 from: b.nbRiverVehiclesLastSteps;
					remove index: 0 from: b.nbMaritimeVehiclesLastSteps;

					remove index: 0 from: b.nbRoadQuantitiesLastSteps;
					remove index: 0 from: b.nbRiverQuantitiesLastSteps;
					remove index: 0 from: b.nbMaritimeQuantitiesLastSteps;
				}
				b.nbRoadVehiclesLastSteps <+ 0;
				b.nbRiverVehiclesLastSteps <+ 0;
				b.nbMaritimeVehiclesLastSteps <+ 0;

				b.nbRoadQuantitiesLastSteps <+ 0;
				b.nbRiverQuantitiesLastSteps <+ 0;
				b.nbMaritimeQuantitiesLastSteps <+ 0;
				j <- j + 1;
			}

			if(sumVehicleRO > 0) {
				shareRoadVehicleRO <- sumRoadVehicleRO / sumVehicleRO;
				shareRiverVehicleRO <- sumRiverVehicleRO / sumVehicleRO;
				shareMaritimeVehicleRO <- sumMaritimeVehicleRO / sumVehicleRO;
			}
			else {
				shareRoadVehicleRO <- 0.0;
				shareRiverVehicleRO <- 0.0;
				shareMaritimeVehicleRO <- 0.0;
			}

			if(sumQuantitiesRO > 0) {
				shareRoadQuantitiesRO <- sumRoadQuantitiesRO / sumQuantitiesRO;
				shareRiverQuantitiesRO <- sumRiverQuantitiesRO / sumQuantitiesRO;
				shareMaritimeQuantitiesRO <- sumMaritimeQuantitiesRO / sumQuantitiesRO;
			}
			else {
				shareRoadQuantitiesRO <- 0.0;
				shareRiverQuantitiesRO <- 0.0;
				shareMaritimeQuantitiesRO <- 0.0;
			}
		}

		if(sumVehicle > 0) {
			shareRoadVehicle <- sumRoadVehicle / sumVehicle;
			shareRiverVehicle <- sumRiverVehicle / sumVehicle;
			shareMaritimeVehicle <- sumMaritimeVehicle / sumVehicle;
		}
		else {
			shareRoadVehicle <- 0.0;
			shareRiverVehicle <- 0.0;
			shareMaritimeVehicle <- 0.0;
		}

		if(sumQuantities > 0) {
			shareRoadQuantities <- sumRoadQuantities / sumQuantities;
			shareRiverQuantities <- sumRiverQuantities / sumQuantities;
			shareMaritimeQuantities <- sumMaritimeQuantities / sumQuantities;
		}
		else {
			shareRoadQuantities <- 0;
			shareRiverQuantities <- 0;
			shareMaritimeQuantities <- 0;
		}
	}

	// Average number of LSP for each strategy
	list<int> listNbLPStrat1 <- [];
	list<int> listNbLPStrat2 <- [];
	list<int> listNbLPStrat3 <- [];
	list<int> listNbLPStrat4 <- [];
	float averageStrat1 <- 0;
	float averageStrat2 <- 0;
	float averageStrat3 <- 0;
	float averageStrat4 <- 0;
	// Strat 1
	float nbLPStrat1LowThreshold;
	float nbLPStrat1LowMediumThreshold;
	float nbLPStrat1HighMediumThreshold;
	float nbLPStrat1HighThreshold;
	// Strat 2
	float nbLPStrat2LowThreshold;
	float nbLPStrat2LowMediumThreshold;
	float nbLPStrat2HighMediumThreshold;
	float nbLPStrat2HighThreshold;
	// Strat 3
	float nbLPStrat3LowThreshold;
	float nbLPStrat3LowMediumThreshold;
	float nbLPStrat3HighMediumThreshold;
	float nbLPStrat3HighThreshold;
	// Strat 4
	float nbLPStrat4LowThreshold;
	float nbLPStrat4LowMediumThreshold;
	float nbLPStrat4HighMediumThreshold;
	float nbLPStrat4HighThreshold;
	reflex countStrategyShare when: time > 0{
		nbLPStrat1 <- 0;
		nbLPStrat2 <- 0;
		nbLPStrat3 <- 0;
		nbLPStrat4 <- 0;

		nbLPStrat1LowThreshold <- 0;
		nbLPStrat1LowMediumThreshold <- 0;
		nbLPStrat1HighMediumThreshold <- 0;
		nbLPStrat1HighThreshold <- 0;

		nbLPStrat2LowThreshold <- 0;
		nbLPStrat2LowMediumThreshold <- 0;
		nbLPStrat2HighMediumThreshold <- 0;
		nbLPStrat2HighThreshold <- 0;

		nbLPStrat3LowThreshold <- 0;
		nbLPStrat3LowMediumThreshold <- 0;
		nbLPStrat3HighMediumThreshold <- 0;
		nbLPStrat3HighThreshold <- 0;

		nbLPStrat4LowThreshold <- 0;
		nbLPStrat4LowMediumThreshold <- 0;
		nbLPStrat4HighMediumThreshold <- 0;
		nbLPStrat4HighThreshold <- 0;

		float inter <- (maxlocalThreshold - minlocalThreshold)/4.0;
		ask FinalDestinationManager {
			if(logisticsServiceProvider.adoptedSelectingWarehouseStrategy = 1){
				nbLPStrat1 <- nbLPStrat1 + 1;
				if(logisticsServiceProvider.threshold < (minlocalThreshold + inter)){
					nbLPStrat1LowThreshold <- nbLPStrat1LowThreshold + 1;
				}
				else if(logisticsServiceProvider.threshold < (minlocalThreshold + 2*inter)){
					nbLPStrat1LowMediumThreshold <- nbLPStrat1LowMediumThreshold + 1;
				}
				else if(logisticsServiceProvider.threshold < (minlocalThreshold + 3*inter)){
					nbLPStrat1HighMediumThreshold <- nbLPStrat1HighMediumThreshold + 1;
				}
				else {
					nbLPStrat1HighThreshold <- nbLPStrat1HighThreshold + 1;
				}
			}
			else if(logisticsServiceProvider.adoptedSelectingWarehouseStrategy = 2){
				nbLPStrat2 <- nbLPStrat2 + 1;
				if(logisticsServiceProvider.threshold < (minlocalThreshold + inter)){
					nbLPStrat2LowThreshold <- nbLPStrat2LowThreshold + 1;
				}
				else if(logisticsServiceProvider.threshold < (minlocalThreshold + 2*inter)){
					nbLPStrat2LowMediumThreshold <- nbLPStrat2LowMediumThreshold + 1;
				}
				else if(logisticsServiceProvider.threshold < (minlocalThreshold + 3*inter)){
					nbLPStrat2HighMediumThreshold <- nbLPStrat2HighMediumThreshold + 1;
				}
				else {
					nbLPStrat2HighThreshold <- nbLPStrat2HighThreshold + 1;
				}
			}
			else if(logisticsServiceProvider.adoptedSelectingWarehouseStrategy = 3){
				nbLPStrat3 <- nbLPStrat3 + 1;
				if(logisticsServiceProvider.threshold < (minlocalThreshold + inter)){
					nbLPStrat3LowThreshold <- nbLPStrat3LowThreshold + 1;
				}
				else if(logisticsServiceProvider.threshold < (minlocalThreshold + 2*inter)){
					nbLPStrat3LowMediumThreshold <- nbLPStrat3LowMediumThreshold + 1;
				}
				else if(logisticsServiceProvider.threshold < (minlocalThreshold + 3*inter)){
					nbLPStrat3HighMediumThreshold <- nbLPStrat3HighMediumThreshold + 1;
				}
				else {
					nbLPStrat3HighThreshold <- nbLPStrat3HighThreshold + 1;
				}
			}
			else if(logisticsServiceProvider.adoptedSelectingWarehouseStrategy = 4){
				nbLPStrat4 <- nbLPStrat4 + 1;
				if(logisticsServiceProvider.threshold < (minlocalThreshold + inter)){
					nbLPStrat4LowThreshold <- nbLPStrat4LowThreshold + 1;
				}
				else if(logisticsServiceProvider.threshold < (minlocalThreshold + 2.0*inter)){
					nbLPStrat4LowMediumThreshold <- nbLPStrat4LowMediumThreshold + 1;
				}
				else if(logisticsServiceProvider.threshold < (minlocalThreshold + 3.0*inter)){
					nbLPStrat4HighMediumThreshold <- nbLPStrat4HighMediumThreshold + 1;
				}
				else {
					nbLPStrat4HighThreshold <- nbLPStrat4HighThreshold + 1;
				}
			}
		}

		listNbLPStrat1 <- listNbLPStrat1 + nbLPStrat1;
		if(length(listNbLPStrat1) > 100 ){
			remove index: 0 from: listNbLPStrat1;
		}
		listNbLPStrat2 <- listNbLPStrat2 + nbLPStrat2;
		if(length(listNbLPStrat2) > 100 ){
			remove index: 0 from: listNbLPStrat2;
		}
		listNbLPStrat3 <- listNbLPStrat3 + nbLPStrat3;
		if(length(listNbLPStrat3) > 100 ){
			remove index: 0 from: listNbLPStrat3;
		}
		listNbLPStrat4 <- listNbLPStrat4 + nbLPStrat4;
		if(length(listNbLPStrat4) > 100 ){
			remove index: 0 from: listNbLPStrat4;
		}
		averageStrat1 <- 0.0;
		averageStrat2 <- 0.0;
		averageStrat3 <- 0.0;
		averageStrat4 <- 0.0;
		int i <- 0;
		loop while: i < length(listNbLPStrat4) {
			averageStrat1 <- averageStrat1 + listNbLPStrat1[i];
			averageStrat2 <- averageStrat2 + listNbLPStrat2[i];
			averageStrat3 <- averageStrat3 + listNbLPStrat3[i];
			averageStrat4 <- averageStrat4 + listNbLPStrat4[i];
			i <- i + 1;
		}
		averageStrat1 <- averageStrat1/length(listNbLPStrat1);
		averageStrat2 <- averageStrat2/length(listNbLPStrat2);
		averageStrat3 <- averageStrat3/length(listNbLPStrat3);
		averageStrat4 <- averageStrat4/length(listNbLPStrat4);
	}

	reflex portsShare {
		nbAntwerp <- 0;
		nbHavre <- 0;
		ask LogisticsServiceProvider {
			if(length(customers) > 0){
				if(provider.port = "ANTWERP"){
					nbAntwerp <- nbAntwerp + 1;
				}
				else {
					nbHavre <- nbHavre + 1;
				}
			}
		}
	}

	float averageThreshold <- 0.0;
	reflex computeAverageThreshold {
		float sum <- 0.0;
		float nbLP <- 0.0;
		ask LogisticsServiceProvider {
			if(length(customers) > 0){
				nbLP <- nbLP + length(customers);
				sum <- sum + threshold*length(customers);
			}
		}
		if(nbLP > 0){
			averageThreshold <- sum/nbLP;
		}
	}

	string CSVFolderPath <- "../results/CSV/";
	reflex saveObservations when: saveObservations {
		if(date_simu_starts = nil) {
			// TODO : when gama dev will have republish  as_system_date "%Y-%M-%D-%h-%m-%s", use it instead
			date_simu_starts <- ""+gama.machine_time;// as_system_date "%Y-%M-%D-%h-%m-%s"; 
		}

		string params <- "_Strats" + possibleSelectingWarehouseStrategies;

		save "" + ((time/3600.0) as int) + ";" +stockInWarehouse + ";" + freeSurfaceInWarehouse + ";"
			to: CSVFolderPath + date_simu_starts + "_stocks_warehouses" + params + ".csv" type: text rewrite: false;
		save "" + ((time/3600.0) as int) + ";" +stockInFinalDest + ";" + freeSurfaceInFinalDest + ";"
			to: CSVFolderPath + date_simu_starts + "_stocks_final_dests" + params  + ".csv" type: text rewrite: false;
//		save "" + ((time/3600.0) as int) + ";" + averageGoodsQuantityPerBatch
//			to: filePath + date_simu_starts + "averageGoodsQuantityPerBatch" + params  + ".csv" type: text rewrite: false;
//		save "" + ((time/3600.0) as int) + ";" + cumulativeNumberOfBatch + ";" + cumulativeNumberOfBatchProviderToLarge + ";" + cumulativeNumberOfBatchLargeToClose + ";" + cumulativeNumberOfBatchCloseToFinal + ";" 
//			to: filePath + date_simu_starts + "_cumulative_number_batches" + params  + ".csv" type: text rewrite: false;
//		save "" + ((time/3600.0) as int) + ";" + cumulativeStockOnRoads + ";" + cumulativeStockOnRoadsProviderToLarge + ";" + cumulativeStockOnRoadsLargeToClose + ";" + cumulativeStockOnRoadsCloseToFinal + ";"
//			to: filePath + date_simu_starts + "_cumulative_stock_on_roads" + params  + ".csv" type: text rewrite: false;
//		save "" + ((time/3600.0) as int) + ";" + totalNumberOfBatch + ";" + numberOfBatchProviderToLarge + ";" + numberOfBatchLargeToClose + ";" + numberOfBatchCloseToFinal + ";"
//			to: filePath + date_simu_starts + "_number_batches" + params  + ".csv" type: text rewrite: false;
//		save "" + ((time/3600.0) as int) + ";" + stockOnRoads + ";" + stockOnRoadsProviderToLarge + ";" + stockOnRoadsLargeToClose + ";" + stockOnRoadsCloseToFinal + ";"
//			to: filePath + date_simu_starts + "_stock_on_roads" + params  + ".csv" type: text rewrite: false;
		save "" + ((time/3600.0) as int) + ";" + numberofEmptyStockInFinalDests + ";"
			to: CSVFolderPath + date_simu_starts + "_number_empty_stock_final_dest" + params  + ".csv" type: text rewrite: false;
		save "" + ((time/3600.0) as int) + ";" + numberOfEmptyStockInWarehouses + ";"
			to: CSVFolderPath + date_simu_starts + "_number_empty_stock_warehouses" + params + ".csv" type: text rewrite: false;
		save "" + ((time/3600.0) as int) + ";" + averageTimeToDeliver + ";"
			to: CSVFolderPath + date_simu_starts + "_average_time_to_deliver" + params  + ".csv" type: text rewrite: false;
		save "" + ((time/3600.0) as int) + ";" + averageTimeToBeDelivered + ";"
			to: CSVFolderPath + date_simu_starts + "_average_time_to_be_delivered" + params  + ".csv" type: text rewrite: false;
		save "" + ((time/3600.0) as int) + ";" + nbLPStrat1 + ";" + nbLPStrat2 + ";" + nbLPStrat3 + ";" + nbLPStrat4 + ";"
			to: CSVFolderPath + date_simu_starts + "_strategies_adoption_share" + params  + ".csv" type: text rewrite: false;
		save "" + ((time/3600.0) as int) + ";" + nbStocksAwaitingToEnterBuilding + ";" + nbStocksAwaitingToEnterWarehouse + ";" + nbStocksAwaitingToLeaveWarehouse + ";" + nbStocksAwaitingToLeaveProvider + ";"
			to: CSVFolderPath + date_simu_starts + "_nb_stocks_awaiting" + params  + ".csv" type: text rewrite: false;
		save "" + ((time/3600.0) as int) + ";" + averageThreshold + ";"
			to: CSVFolderPath + date_simu_starts + "_averageThreshold" + params  + ".csv" type: text rewrite: false;
		save "" + ((time/3600.0) as int) + ";" + nbLPStrat1LowThreshold + ";" + nbLPStrat1LowMediumThreshold + ";" + nbLPStrat1HighMediumThreshold + ";" + nbLPStrat1HighThreshold + ";"
			to: CSVFolderPath + date_simu_starts + "_strat1_threshold_adoption_share" + params  + ".csv" type: text rewrite: false;
		save "" + ((time/3600.0) as int) + ";" + nbLPStrat2LowThreshold + ";" + nbLPStrat2LowMediumThreshold + ";" + nbLPStrat2HighMediumThreshold + ";" + nbLPStrat2HighThreshold + ";"
			to: CSVFolderPath + date_simu_starts + "_strat2_threshold_adoption_share" + params  + ".csv" type: text rewrite: false;
		save "" + ((time/3600.0) as int) + ";" + nbLPStrat3LowThreshold + ";" + nbLPStrat3LowMediumThreshold + ";" + nbLPStrat3HighMediumThreshold + ";" + nbLPStrat3HighThreshold + ";"
			to: CSVFolderPath + date_simu_starts + "_strat3_threshold_adoption_share" + params  + ".csv" type: text rewrite: false;
		save "" + ((time/3600.0) as int) + ";" + nbLPStrat4LowThreshold + ";" + nbLPStrat4LowMediumThreshold + ";" + nbLPStrat4HighMediumThreshold + ";" + nbLPStrat4HighThreshold + ";"
			to: CSVFolderPath + date_simu_starts + "_strat4_threshold_adoption_share" + params  + ".csv" type: text rewrite: false;

		save "" + ((time/3600.0) as int) + ";" + averageCosts
			to: CSVFolderPath + date_simu_starts + "_average_costs" + params  + ".csv" type: text rewrite: false;
		save "" + ((time/3600.0) as int) + ";" + nbHavre + ";" +  nbAntwerp
			to: CSVFolderPath + date_simu_starts + "_competition_between_LH_Antwerp" + params  + ".csv" type: text rewrite: false;
		save "" + ((time/3600.0) as int) + ";" + sumRoadVehicle + ";" +  sumRiverVehicle + ";" +  sumMaritimeVehicle
			to: CSVFolderPath + date_simu_starts + "_share_transport_mode" + params  + ".csv" type: text rewrite: false;
		save "" + ((time/3600.0) as int) + ";" + sumRoadQuantities + ";" +  sumRiverQuantities + ";" +  sumMaritimeQuantities
			to: CSVFolderPath + date_simu_starts + "_share_transport_mode_quantities" + params  + ".csv" type: text rewrite: false;

		do saveShareTransportModeRegion(params, "Basse-Normandie");
		do saveShareTransportModeRegion(params, "Haute-Normandie");
		do saveShareTransportModeRegion(params, "Centre");
		do saveShareTransportModeRegion(params, "Ile-de-France");
		do saveShareTransportModeRegion(params, "Picardie");
		do saveShareTransportModeRegion(params, "Antwerpen");

	}

	action saveShareTransportModeRegion(string params, string n){
		RegionObserver sr <- nil;
		ask RegionObserver {
			if(self.name = n){
				sr <- self;
			}
		}
		save "" + ((time/3600.0) as int) + ";" + sr.sumRoadVehicleRO + ";" +  sr.sumRiverVehicleRO + ";" +  sr.sumMaritimeVehicleRO
			to: CSVFolderPath + date_simu_starts + "_share_transport_mode_" + n + params  + ".csv" type: text rewrite: false;
		save "" + ((time/3600.0) as int) + ";" + sr.sumRoadQuantitiesRO + ";" +  sr.sumRiverQuantitiesRO + ";" +  sr.sumMaritimeQuantitiesRO
			to: CSVFolderPath + date_simu_starts + "_share_transport_mode_quantities_" + n + params  + ".csv" type: text rewrite: false;
	}
}