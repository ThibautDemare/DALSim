model Observer

import "FinalConsignee.gaml"

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
		ask FinalConsignee {
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
		ask FinalConsignee {
			int i <- 0;
			self.localAverageNbStockShortagesLastSteps <- 0;
			loop while: i < length(localNbStockShortagesLastSteps) {
				self.localAverageNbStockShortagesLastSteps <- self.localAverageNbStockShortagesLastSteps + localNbStockShortagesLastSteps[i];
				i <- i + 1;
			}
			self.localAverageNbStockShortagesLastSteps <- self.localAverageNbStockShortagesLastSteps / length(localNbStockShortagesLastSteps);
			currentNbStockShortages <- currentNbStockShortages + self.localAverageNbStockShortagesLastSteps;
		}
		currentNbStockShortages <- currentNbStockShortages / length(FinalConsignee);
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

	reflex updateAverageTimeToDeliver {
		// Update the average time to deliver (at the LPs level)
		int i <- 0;
		float sum <- 0;
		ask ((Building as list) + (Warehouse as list)) {
			if(length(stocks) > 0){
				int j <- 0;

				loop while: nbDeliveriesConsideredForTimeToDelivered < length(localTimeToBeDeliveredLastDeliveries) {
					remove index: 0 from: localTimeToBeDeliveredLastDeliveries;
				}

				loop while: j<length(localTimeToBeDeliveredLastDeliveries) {
					sum <- sum + localTimeToBeDeliveredLastDeliveries[j];
					j <- j + 1;
					i <- i + 1;
				}

			}
		}

		if(i > 0){
			averageTimeToDeliver <- (sum/i);
		}
	}

	reflex updateAverageTimeToBeDelivered {
		// Update the average time to be delivered (at the FDMs level)
		int i <- 0;
		float sum <- 0;
		ask ((Building as list)) {
			if(length(stocks) > 0){
				int j <- 0;
				int localSum <- 0;

				loop while: nbDeliveriesConsideredForTimeToDelivered < length(localTimeToBeDeliveredLastDeliveries) {
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
		}
		if(i > 0){
			averageTimeToBeDelivered <- (sum/i);
		}
	}

	reflex update_average_costs {
		// Update the average costs
		int i <- 0;
		float sum <- 0;
		// First we update the costs for each FC
		ask FinalConsignee {
			if(length(localTransportationCosts) > 0){
				int j <- 0;
				float localCostsSum <- 0;
				float localVolumeSum <- 0.0;

				loop while: costsMemory < length(localTransportationCosts) {
					// both arrays have the same size
					remove index: 0 from: localTransportationCosts;
					remove index: 0 from: transportedVolumes;
				}

				loop while: j<length(localTransportationCosts) {
					// again, both arrays have the same size
					localCostsSum <- localCostsSum + localTransportationCosts[j];
					localVolumeSum <- localVolumeSum + transportedVolumes[j];
					j <- j + 1;
				}
				localAverageCosts <-
					// localWarehousingCosts + // If this should be used, we first need to justify how warehousing costs are computed. For now, have higher costs for larger surface is not necessarily realistic.
					localCostsSum / length(localTransportationCosts);
				localVolumeNormalizedAverageCosts <- localAverageCosts / localVolumeSum;
				sum <- sum + localAverageCosts;
				i <- i + 1;
			}
		}
		// Then we compute the average costs of the neighbors of each FC
		ask FinalConsignee {
			averageCostsOfNeighbors <- 0.0;
			if(length(neighbors) = 0) {
				do buildNeighborsList;
			}
			int j <- 0;
			loop while: j<length(neighbors) {
				// again, both arrays have the same size
				averageCostsOfNeighbors <- averageCostsOfNeighbors + neighbors[j].localVolumeNormalizedAverageCosts;
				j <- j + 1;
			}
			averageCostsOfNeighbors <- averageCostsOfNeighbors / length(neighbors);
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
	float sumSecondaryVehicle;
	float shareRoadVehicle;
	float shareRiverVehicle;
	float shareMaritimeVehicle;
	float shareSecondaryVehicle;
	// Share by quantities of goods
	float sumQuantities;
	float sumRoadQuantities;
	float sumRiverQuantities;
	float sumMaritimeQuantities;
	float sumSecondaryQuantities;
	float shareRoadQuantities;
	float shareRiverQuantities;
	float shareMaritimeQuantities;
	float shareSecondaryQuantities;
	reflex averageModeShare {
		sumVehicle <- 0.0;
		sumRoadVehicle <- 0.0;
		sumRiverVehicle <- 0.0;
		sumMaritimeVehicle <- 0.0;
		sumSecondaryVehicle <- 0.0;

		sumQuantities <- 0.0;
		sumRoadQuantities <- 0.0;
		sumRiverQuantities <- 0.0;
		sumMaritimeQuantities <- 0.0;
		sumSecondaryQuantities <- 0.0;

		ask RegionObserver {
			ask myself {
				do updateROBuildingModeShare(myself);
				do updateROTerminalModeShare(myself);
			}
		}
		do cleanNbVehiclesQuantitiesLastSteps;

		if(sumVehicle > 0) {
			shareRoadVehicle <- sumRoadVehicle / sumVehicle;
			shareRiverVehicle <- sumRiverVehicle / sumVehicle;
			shareMaritimeVehicle <- sumMaritimeVehicle / sumVehicle;
			shareSecondaryVehicle <- sumSecondaryVehicle / sumVehicle;
		}
		else {
			shareRoadVehicle <- 0.0;
			shareRiverVehicle <- 0.0;
			shareMaritimeVehicle <- 0.0;
			shareSecondaryVehicle <- 0.0;
		}

		if(sumQuantities > 0) {
			shareRoadQuantities <- sumRoadQuantities / sumQuantities;
			shareRiverQuantities <- sumRiverQuantities / sumQuantities;
			shareMaritimeQuantities <- sumMaritimeQuantities / sumQuantities;
			shareSecondaryQuantities <- sumSecondaryQuantities / sumQuantities;
		}
		else {
			shareRoadQuantities <- 0;
			shareRiverQuantities <- 0;
			shareMaritimeQuantities <- 0;
			shareSecondaryQuantities <- 0;
		}
	}

	action updateROBuildingModeShare(RegionObserver ro) {
		ask ro {
			sumVehicleRO <- 0.0;
			sumRoadVehicleRO <- 0.0;
			sumRiverVehicleRO <- 0.0;
			sumMaritimeVehicleRO <- 0.0;
			sumSecondaryVehicleRO <- 0.0;

			sumQuantitiesRO <- 0.0;
			sumRoadQuantitiesRO <- 0.0;
			sumRiverQuantitiesRO <- 0.0;
			sumMaritimeQuantitiesRO <- 0.0;
			sumSecondaryQuantitiesRO <- 0.0;

			int j <- 0;
			loop while: j < length(buildings) {
				Building b <- buildings[j];
				// Road
				int i <- 0;
				loop while: i < length(b.nbRoadVehiclesLastSteps) {
					sumVehicle <- sumVehicle + b.nbRoadVehiclesLastSteps[i];
					sumRoadVehicle <- sumRoadVehicle + b.nbRoadVehiclesLastSteps[i];

					sumVehicleRO <- sumVehicleRO + b.nbRoadVehiclesLastSteps[i];
					sumRoadVehicleRO <- sumRoadVehicleRO + b.nbRoadVehiclesLastSteps[i];

					sumQuantities <- sumQuantities + b.nbRoadQuantitiesLastSteps[i];
					sumRoadQuantities <- sumRoadQuantities + b.nbRoadQuantitiesLastSteps[i];

					sumQuantitiesRO <- sumQuantitiesRO + b.nbRoadQuantitiesLastSteps[i];
					sumRoadQuantitiesRO <- sumRoadQuantitiesRO + b.nbRoadQuantitiesLastSteps[i];

					i <- i + 1;
				}

				// River
				i <- 0;
				loop while: i < length(b.nbRiverVehiclesLastSteps) {
					sumVehicle <- sumVehicle + b.nbRiverVehiclesLastSteps[i];
					sumRiverVehicle <- sumRiverVehicle + b.nbRiverVehiclesLastSteps[i];

					sumVehicleRO <- sumVehicleRO + b.nbRiverVehiclesLastSteps[i];
					sumRiverVehicleRO <- sumRiverVehicleRO + b.nbRiverVehiclesLastSteps[i];

					sumQuantities <- sumQuantities + b.nbRoadQuantitiesLastSteps[i] + b.nbRiverQuantitiesLastSteps[i];
					sumRiverQuantities <- sumRiverQuantities + b.nbRiverQuantitiesLastSteps[i];

					sumQuantitiesRO <- sumQuantitiesRO + b.nbRiverQuantitiesLastSteps[i];
					sumRiverQuantitiesRO <- sumRiverQuantitiesRO + b.nbRiverQuantitiesLastSteps[i];

					i <- i + 1;
				}

				// Maritime
				i <- 0;
				loop while: i < length(b.nbMaritimeVehiclesLastSteps) {
					sumVehicle <- sumVehicle + b.nbMaritimeVehiclesLastSteps[i];
					sumMaritimeVehicle <- sumMaritimeVehicle + b.nbMaritimeVehiclesLastSteps[i];

					sumVehicleRO <- sumVehicleRO + b.nbMaritimeVehiclesLastSteps[i];
					sumMaritimeVehicleRO <- sumMaritimeVehicleRO + b.nbMaritimeVehiclesLastSteps[i];

					sumQuantities <- sumQuantities + b.nbMaritimeQuantitiesLastSteps[i];
					sumMaritimeQuantities <- sumMaritimeQuantities + b.nbMaritimeQuantitiesLastSteps[i];

					sumQuantitiesRO <- sumQuantitiesRO + b.nbMaritimeQuantitiesLastSteps[i];
					sumMaritimeQuantitiesRO <- sumMaritimeQuantitiesRO + b.nbMaritimeQuantitiesLastSteps[i];

					i <- i + 1;
				}

				// Secondary
				i <- 0;
				loop while: i < length(b.nbSecondaryVehiclesLastSteps) {
					sumVehicle <- sumVehicle + b.nbSecondaryVehiclesLastSteps[i];
					sumSecondaryVehicle <- sumSecondaryVehicle + b.nbSecondaryVehiclesLastSteps[i];

					sumVehicleRO <- sumVehicleRO + b.nbSecondaryVehiclesLastSteps[i];
					sumSecondaryVehicleRO <- sumSecondaryVehicleRO + b.nbSecondaryVehiclesLastSteps[i];

					sumQuantities <- sumQuantities + b.nbSecondaryQuantitiesLastSteps[i];
					sumSecondaryQuantities <- sumSecondaryQuantities + b.nbSecondaryQuantitiesLastSteps[i];

					sumQuantitiesRO <- sumQuantitiesRO + b.nbSecondaryQuantitiesLastSteps[i];
					sumSecondaryQuantitiesRO <- sumSecondaryQuantitiesRO + b.nbSecondaryQuantitiesLastSteps[i];

					i <- i + 1;
				}
				j <- j + 1;
			}

			if(sumVehicleRO > 0) {
				shareRoadVehicleRO <- sumRoadVehicleRO / sumVehicleRO;
				shareRiverVehicleRO <- sumRiverVehicleRO / sumVehicleRO;
				shareMaritimeVehicleRO <- sumMaritimeVehicleRO / sumVehicleRO;
				shareSecondaryVehicleRO <- sumSecondaryVehicleRO / sumVehicleRO;
			}
			else {
				shareRoadVehicleRO <- 0.0;
				shareRiverVehicleRO <- 0.0;
				shareMaritimeVehicleRO <- 0.0;
				shareSecondaryVehicleRO <- 0.0;
			}

			if(sumQuantitiesRO > 0) {
				shareRoadQuantitiesRO <- sumRoadQuantitiesRO / sumQuantitiesRO;
				shareRiverQuantitiesRO <- sumRiverQuantitiesRO / sumQuantitiesRO;
				shareMaritimeQuantitiesRO <- sumMaritimeQuantitiesRO / sumQuantitiesRO;
				shareSecondaryQuantitiesRO <- sumSecondaryQuantitiesRO / sumQuantitiesRO;
			}
			else {
				shareRoadQuantitiesRO <- 0.0;
				shareRiverQuantitiesRO <- 0.0;
				shareMaritimeQuantitiesRO <- 0.0;
				shareSecondaryQuantitiesRO <- 0.0;
			}
		}
	}

	action cleanNbVehiclesQuantitiesLastSteps {
		ask ((Building as list) + (Warehouse as list) + (SecondaryTerminal as list) + (RiverTerminal as list) + (MaritimeRiverTerminal as list)) {
			if(cycle > -1){
				remove index: 0 from: nbRoadVehiclesLastSteps;
				remove index: 0 from: nbRiverVehiclesLastSteps;
				remove index: 0 from: nbMaritimeVehiclesLastSteps;
				remove index: 0 from: nbSecondaryVehiclesLastSteps;

				remove index: 0 from: nbRoadQuantitiesLastSteps;
				remove index: 0 from: nbRiverQuantitiesLastSteps;
				remove index: 0 from: nbMaritimeQuantitiesLastSteps;
				remove index: 0 from: nbSecondaryQuantitiesLastSteps;
				
			}
			nbRoadVehiclesLastSteps <+ 0;
			nbRiverVehiclesLastSteps <+ 0;
			nbMaritimeVehiclesLastSteps <+ 0;
			nbSecondaryVehiclesLastSteps <+ 0;

			nbRoadQuantitiesLastSteps <+ 0;
			nbRiverQuantitiesLastSteps <+ 0;
			nbMaritimeQuantitiesLastSteps <+ 0;
			nbSecondaryQuantitiesLastSteps <+ 0;
		}
	}

	action updateROTerminalModeShare(RegionObserver ro) {
		ask ro {
			sumLeavingVehicleRO <- 0.0;
			sumLeavingRoadVehicleRO <- 0.0;
			sumLeavingRiverVehicleRO <- 0.0;
			sumLeavingMaritimeVehicleRO <- 0.0;
			sumLeavingSecondaryVehicleRO <- 0.0;

			sumLeavingQuantitiesRO <- 0.0;
			sumLeavingRoadQuantitiesRO <- 0.0;
			sumLeavingRiverQuantitiesRO <- 0.0;
			sumLeavingMaritimeQuantitiesRO <- 0.0;
			sumLeavingSecondaryQuantitiesRO <- 0.0;

			int j <- 0;
			loop while: j < length(terminals) {
				Terminal t <- terminals[j];

				sumLeavingVehicleRO <- sumLeavingVehicleRO + length(t.leavingVehicles_maritime) + length(t.leavingVehicles_road) + length(t.leavingVehicles_river);
				sumLeavingRoadVehicleRO <- sumLeavingRoadVehicleRO + length(t.leavingVehicles_road);
				sumLeavingRiverVehicleRO <- sumLeavingRiverVehicleRO + length(t.leavingVehicles_river);
				sumLeavingMaritimeVehicleRO <- sumLeavingMaritimeVehicleRO + length(t.leavingVehicles_maritime);
				sumLeavingSecondaryVehicleRO <- sumLeavingSecondaryVehicleRO + length(t.leavingVehicles_secondary);

				ask t.leavingVehicles_maritime {
					myself.sumLeavingQuantitiesRO <- myself.sumLeavingQuantitiesRO + self.scheduledTransportedVolume;
					myself.sumLeavingMaritimeQuantitiesRO <- myself.sumLeavingMaritimeQuantitiesRO + self.scheduledTransportedVolume;
				}

				ask t.leavingVehicles_road {
					myself.sumLeavingQuantitiesRO <- myself.sumLeavingQuantitiesRO + self.scheduledTransportedVolume;
					myself.sumLeavingRoadQuantitiesRO <- myself.sumLeavingRoadQuantitiesRO + self.scheduledTransportedVolume;
				}

				ask t.leavingVehicles_river {
					myself.sumLeavingQuantitiesRO <- myself.sumLeavingQuantitiesRO + self.scheduledTransportedVolume;
					myself.sumLeavingRiverQuantitiesRO <- myself.sumLeavingRiverQuantitiesRO + self.scheduledTransportedVolume;
				}
				
				ask t.leavingVehicles_secondary {
					myself.sumLeavingQuantitiesRO <- myself.sumLeavingQuantitiesRO + self.scheduledTransportedVolume;
					myself.sumLeavingSecondaryQuantitiesRO <- myself.sumLeavingSecondaryQuantitiesRO + self.scheduledTransportedVolume;
				}
				j <- j + 1;
			}

			if(sumLeavingVehicleRO > 0) {
				shareLeavingRoadVehicleRO <- sumLeavingRoadVehicleRO / sumLeavingVehicleRO;
				shareLeavingRiverVehicleRO <- sumLeavingRiverVehicleRO / sumLeavingVehicleRO;
				shareLeavingMaritimeVehicleRO <- sumLeavingMaritimeVehicleRO / sumLeavingVehicleRO;
				shareLeavingSecondaryVehicleRO <- sumLeavingSecondaryVehicleRO / sumLeavingVehicleRO;
			}
			else {
				shareLeavingRoadVehicleRO <- 0.0;
				shareLeavingRiverVehicleRO <- 0.0;
				shareLeavingMaritimeVehicleRO <- 0.0;
				shareLeavingSecondaryVehicleRO <- 0.0;
			}

			if(sumLeavingQuantitiesRO > 0) {
				shareLeavingRoadQuantitiesRO <- sumLeavingRoadQuantitiesRO / sumLeavingQuantitiesRO;
				shareLeavingRiverQuantitiesRO <- sumLeavingRiverQuantitiesRO / sumLeavingQuantitiesRO;
				shareLeavingMaritimeQuantitiesRO <- sumLeavingMaritimeQuantitiesRO / sumLeavingQuantitiesRO;
				shareLeavingSecondaryQuantitiesRO <- sumLeavingSecondaryQuantitiesRO / sumLeavingQuantitiesRO;
			}
			else {
				shareLeavingRoadQuantitiesRO <- 0.0;
				shareLeavingRiverQuantitiesRO <- 0.0;
				shareLeavingMaritimeQuantitiesRO <- 0.0;
				shareLeavingSecondaryQuantitiesRO <- 0.0;
			}
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
		ask FinalConsignee {
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

	reflex portsSharePerRegion {
		ask RegionObserver {
			nbAntwerp <- 0;
			nbHavre <- 0;
			int i <- 0;
			loop while: i < length(fcs) {
				if(fcs[i].logisticsServiceProvider.provider.port = "ANTWERP") {
					nbAntwerp <- nbAntwerp + 1;
				}
				else {
					nbHavre <- nbHavre + 1;
				}
				i <- i + 1;
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

	list<int> distributionNbFCPerLSPY;
	list<int> distributionNbFCPerLSPX;
	reflex distributionNbFCPerLSP {
		distributionNbFCPerLSPY <- [];
		ask LogisticsServiceProvider {
			int nbCustomers <- length(self.customers);
			loop while: length(distributionNbFCPerLSPY) <= nbCustomers{
				 distributionNbFCPerLSPY <- distributionNbFCPerLSPY + 0;
			}
			distributionNbFCPerLSPY[nbCustomers] <- distributionNbFCPerLSPY[nbCustomers] + 1;
		}

		distributionNbFCPerLSPX <- [];
		int i <- 0;
		loop while: i < length(distributionNbFCPerLSPY) {
			distributionNbFCPerLSPX <- distributionNbFCPerLSPX + i;
			i <- i + 1;
		}
	}

	float trafficValueCSN;
	reflex trafficEvolutionOnCanalSeineNord {
		trafficValueCSN <- 0.0;
		int i <- 0;
		loop while: i < length(canalSeineNord) {
			trafficValueCSN <- trafficValueCSN + canalSeineNord[i].current_volume;
			i <- i + 1;
		}
	}

	float averageRoadVehicleOccupancy <- 0;
	float averageRiverVehicleOccupancy <- 0;
	float averageMaritimeVehicleOccupancy <- 0;
	float averageSecondaryVehicleOccupancy <- 0;
	reflex observeVehiclesOccupancy {
		int sumRoad <- 0;
		int sumRiver <- 0;
		int sumMaritime <- 0;
		int sumSecondary <- 0;
		averageRoadVehicleOccupancy <- 0;
		averageRiverVehicleOccupancy <- 0;
		averageMaritimeVehicleOccupancy <- 0;
		averageSecondaryVehicleOccupancy <- 0;
		ask Vehicle {
			if(readyToMove and destination != nil){
				if(networkType = "road"){
					averageRoadVehicleOccupancy <- averageRoadVehicleOccupancy + currentTransportedVolume;
					sumRoad <- sumRoad + 1;
				}
				else if(networkType = "river"){
					averageRiverVehicleOccupancy <- averageRiverVehicleOccupancy + currentTransportedVolume;
					sumRiver <- sumRiver + 1;
				}
				else if(networkType = "maritime"){
					averageMaritimeVehicleOccupancy <- averageMaritimeVehicleOccupancy + currentTransportedVolume;
					sumMaritime <- sumMaritime + 1;
				}
				else if(networkType = "secondary"){
					averageSecondaryVehicleOccupancy <- averageSecondaryVehicleOccupancy + currentTransportedVolume;
					sumSecondary <- sumSecondary + 1;
				}
			}
		}

		if(sumRoad > 0){
			averageRoadVehicleOccupancy <- averageRoadVehicleOccupancy / sumRoad;
		}
		else {
			averageRoadVehicleOccupancy <- 0;
		}

		if(sumRiver > 0){
			averageRiverVehicleOccupancy <- averageRiverVehicleOccupancy / sumRiver;
		}
		else {
			averageRiverVehicleOccupancy <- 0;
		}

		if(sumMaritime > 0){
			averageMaritimeVehicleOccupancy <- averageMaritimeVehicleOccupancy / sumMaritime;
		}
		else {
			averageMaritimeVehicleOccupancy <- 0;
		}

		if(sumSecondary > 0){
			averageSecondaryVehicleOccupancy <- averageSecondaryVehicleOccupancy / sumSecondary;
		}
		else {
			averageSecondaryVehicleOccupancy <- 0;
		}
	}

	string CSVFolderPath <- "../results/CSV/";
	string csvFilenameParams;

	reflex initCSVFile when: saveObservations and date_simu_starts = nil {
		date n <- date("now");
		date_simu_starts <- ""+ n.year + "-" + n.month + "-" + n.day + "-" + n.hour + "-" + n.minute + "-" + n.second;

		csvFilenameParams <- setParams();

		save "step;stockInWarehouse;freeSurfaceInWarehouse"
			to: CSVFolderPath + date_simu_starts + "_stocks_warehouses" + csvFilenameParams + ".csv" type: text rewrite: false;
		save "step;stockInFinalDest;freeSurfaceInFinalDest"
			to: CSVFolderPath + date_simu_starts + "_stocks_final_dests" + csvFilenameParams  + ".csv" type: text rewrite: false;
		save "step;numberofEmptyStockInFinalDests"
			to: CSVFolderPath + date_simu_starts + "_number_empty_stock_final_dest" + csvFilenameParams  + ".csv" type: text rewrite: false;
		save "step;numberOfEmptyStockInWarehouses"
			to: CSVFolderPath + date_simu_starts + "_number_empty_stock_warehouses" + csvFilenameParams + ".csv" type: text rewrite: false;
		save "step;averageTimeToDeliver"
			to: CSVFolderPath + date_simu_starts + "_average_time_to_deliver" + csvFilenameParams  + ".csv" type: text rewrite: false;
		save "step;averageTimeToBeDelivered"
			to: CSVFolderPath + date_simu_starts + "_average_time_to_be_delivered" + csvFilenameParams  + ".csv" type: text rewrite: false;
		save "step;nbLPStrat1;nbLPStrat2;nbLPStrat3;nbLPStrat4"
			to: CSVFolderPath + date_simu_starts + "_strategies_adoption_share" + csvFilenameParams  + ".csv" type: text rewrite: false;
		save "step;nbStocksAwaitingToEnterBuilding;nbStocksAwaitingToEnterWarehouse;nbStocksAwaitingToLeaveWarehouse;nbStocksAwaitingToLeaveProvider"
			to: CSVFolderPath + date_simu_starts + "_nb_stocks_awaiting" + csvFilenameParams  + ".csv" type: text rewrite: false;
		save "step;averageThreshold"
			to: CSVFolderPath + date_simu_starts + "_averageThreshold" + csvFilenameParams  + ".csv" type: text rewrite: false;
		save "step;nbLPStrat1LowThreshold;nbLPStrat1LowMediumThreshold;nbLPStrat1HighMediumThreshold;nbLPStrat1HighThreshold"
			to: CSVFolderPath + date_simu_starts + "_strat1_threshold_adoption_share" + csvFilenameParams  + ".csv" type: text rewrite: false;
		save "step;nbLPStrat2LowThreshold;nbLPStrat2LowMediumThreshold;nbLPStrat2HighMediumThreshold;nbLPStrat2HighThreshold"
			to: CSVFolderPath + date_simu_starts + "_strat2_threshold_adoption_share" + csvFilenameParams  + ".csv" type: text rewrite: false;
		save "step;nbLPStrat3LowThreshold;nbLPStrat3LowMediumThreshold;nbLPStrat3HighMediumThreshold;nbLPStrat3HighThreshold"
			to: CSVFolderPath + date_simu_starts + "_strat3_threshold_adoption_share" + csvFilenameParams  + ".csv" type: text rewrite: false;
		save "step;nbLPStrat4LowThreshold;nbLPStrat4LowMediumThreshold;nbLPStrat4HighMediumThreshold;nbLPStrat4HighThreshold"
			to: CSVFolderPath + date_simu_starts + "_strat4_threshold_adoption_share" + csvFilenameParams  + ".csv" type: text rewrite: false;
		save "step;averageCosts"
			to: CSVFolderPath + date_simu_starts + "_average_costs" + csvFilenameParams  + ".csv" type: text rewrite: false;
		save "step;nbHavre;nbAntwerp"
			to: CSVFolderPath + date_simu_starts + "_competition_between_LH_Antwerp" + csvFilenameParams  + ".csv" type: text rewrite: false;
		save "step;sumRoadVehicle;sumRiverVehicle;sumMaritimeVehicle;sumSecondaryVehicle"
			to: CSVFolderPath + date_simu_starts + "_share_transport_mode" + csvFilenameParams  + ".csv" type: text rewrite: false;
		save "step;sumRoadQuantities;sumRiverQuantities;sumMaritimeQuantities;sumSecondaryQuantities"
			to: CSVFolderPath + date_simu_starts + "_share_transport_mode_quantities" + csvFilenameParams  + ".csv" type: text rewrite: false;
		save "step;trafficValueCSN"
			to: CSVFolderPath + date_simu_starts + "_traffic_evolution_CSN" + csvFilenameParams  + ".csv" type: text rewrite: false;
		save "step;averageRoadVehicleOccupancy"
			to: CSVFolderPath + date_simu_starts + "_vehicles_occupancy_road" + csvFilenameParams  + ".csv" type: text rewrite: false;
		save "step;averageRiverVehicleOccupancy"
			to: CSVFolderPath + date_simu_starts + "_vehicles_occupancy_river" + csvFilenameParams  + ".csv" type: text rewrite: false;
		save "step;averageMaritimeVehicleOccupancy"
			to: CSVFolderPath + date_simu_starts + "_vehicles_occupancy_maritime" + csvFilenameParams  + ".csv" type: text rewrite: false;
		save "step;averageSecondaryVehicleOccupancy"
			to: CSVFolderPath + date_simu_starts + "_vehicles_occupancy_secondary" + csvFilenameParams  + ".csv" type: text rewrite: false;

		do initCSVFileShareTransportModeRegion(csvFilenameParams, "Basse-Normandie");
		do initCSVFileShareTransportModeRegion(csvFilenameParams, "Haute-Normandie");
		do initCSVFileShareTransportModeRegion(csvFilenameParams, "Centre");
		do initCSVFileShareTransportModeRegion(csvFilenameParams, "Ile-de-France");
		do initCSVFileShareTransportModeRegion(csvFilenameParams, "Picardie");
		do initCSVFileShareTransportModeRegion(csvFilenameParams, "Antwerpen");
		do initCSVFileShareTransportModeRegion(csvFilenameParams, "Le Havre");

		do initCSVFileSharePortOriginRegion(csvFilenameParams, "Basse-Normandie");
		do initCSVFileSharePortOriginRegion(csvFilenameParams, "Haute-Normandie");
		do initCSVFileSharePortOriginRegion(csvFilenameParams, "Centre");
		do initCSVFileSharePortOriginRegion(csvFilenameParams, "Ile-de-France");
		do initCSVFileSharePortOriginRegion(csvFilenameParams, "Picardie");
		do initCSVFileSharePortOriginRegion(csvFilenameParams, "Antwerpen");
		do initCSVFileSharePortOriginRegion(csvFilenameParams, "Le Havre");

	}

	action initCSVFileShareTransportModeRegion(string params, string n){
		RegionObserver sr <- nil;
		int i <- 0;
		bool notfound <- true;
		loop while: i < length(RegionObserver) and notfound {
			if(RegionObserver[i].name = n){
				sr <- RegionObserver[i];
				save "step;" + n +" sumRoadVehicleRO;" + n +" sumRiverVehicleRO;" + n +" sumMaritimeVehicleRO;" + n +" sumSecondaryVehicleRO"
					to: CSVFolderPath + date_simu_starts + "_share_transport_mode_" + n + params  + ".csv" type: text rewrite: false;
				save "step;" + n +" sumRoadQuantitiesRO;" + n +" sumRiverQuantitiesRO;" + n +" sumMaritimeQuantitiesRO;" + n +" sumSecondaryQuantitiesRO"
					to: CSVFolderPath + date_simu_starts + "_share_transport_mode_quantities_" + n + params  + ".csv" type: text rewrite: false;
				notfound <- false;

				save "step;" + n +" sumLeavingRoadVehicleRO;" + n +" sumLeavingRiverVehicleRO;" + n +" sumLeavingMaritimeVehicleRO;" + n +" sumLeavingSecondaryVehicleRO"
					to: CSVFolderPath + date_simu_starts + "_share_leaving_vehicles_per_transport_mode_" + n + params  + ".csv" type: text rewrite: false;
				save "step;" + n +" sumLeavingRoadQuantitiesRO;" + n +" sumLeavingRiverQuantitiesRO;" + n +" sumLeavingMaritimeQuantitiesRO;" + n +" sumLeavingSecondaryQuantitiesRO"
					to: CSVFolderPath + date_simu_starts + "_share_leaving_quantities_per_transport_mode_" + n + params  + ".csv" type: text rewrite: false;
				notfound <- false;
			}
			i <- i + 1;
		}
	}

	action initCSVFileSharePortOriginRegion(string params, string n){
		RegionObserver sr <- nil;
		int i <- 0;
		bool notfound <- true;
		loop while: i < length(RegionObserver) and notfound {
			if(RegionObserver[i].name = n){
				sr <- RegionObserver[i];
				save "step;" + n +" nbAntwerp;" + n +" nbHavre"
					to: CSVFolderPath + date_simu_starts + "_share_port_origin_region_" + n + params  + ".csv" type: text rewrite: false;
				notfound <- false;
			}
			i <- i + 1;
		}
	}

	reflex saveObservations when: saveObservations {

		save "" + ((time/3600.0) as int) + ";" +stockInWarehouse + ";" + freeSurfaceInWarehouse
			to: CSVFolderPath + date_simu_starts + "_stocks_warehouses" + csvFilenameParams + ".csv" type: text rewrite: false;
		save "" + ((time/3600.0) as int) + ";" +stockInFinalDest + ";" + freeSurfaceInFinalDest
			to: CSVFolderPath + date_simu_starts + "_stocks_final_dests" + csvFilenameParams  + ".csv" type: text rewrite: false;
		save "" + ((time/3600.0) as int) + ";" + numberofEmptyStockInFinalDests
			to: CSVFolderPath + date_simu_starts + "_number_empty_stock_final_dest" + csvFilenameParams  + ".csv" type: text rewrite: false;
		save "" + ((time/3600.0) as int) + ";" + numberOfEmptyStockInWarehouses
			to: CSVFolderPath + date_simu_starts + "_number_empty_stock_warehouses" + csvFilenameParams + ".csv" type: text rewrite: false;
		save "" + ((time/3600.0) as int) + ";" + averageTimeToDeliver
			to: CSVFolderPath + date_simu_starts + "_average_time_to_deliver" + csvFilenameParams  + ".csv" type: text rewrite: false;
		save "" + ((time/3600.0) as int) + ";" + averageTimeToBeDelivered
			to: CSVFolderPath + date_simu_starts + "_average_time_to_be_delivered" + csvFilenameParams  + ".csv" type: text rewrite: false;
		save "" + ((time/3600.0) as int) + ";" + nbLPStrat1 + ";" + nbLPStrat2 + ";" + nbLPStrat3 + ";" + nbLPStrat4
			to: CSVFolderPath + date_simu_starts + "_strategies_adoption_share" + csvFilenameParams  + ".csv" type: text rewrite: false;
		save "" + ((time/3600.0) as int) + ";" + nbStocksAwaitingToEnterBuilding + ";" + nbStocksAwaitingToEnterWarehouse + ";" + nbStocksAwaitingToLeaveWarehouse + ";" + nbStocksAwaitingToLeaveProvider
			to: CSVFolderPath + date_simu_starts + "_nb_stocks_awaiting" + csvFilenameParams  + ".csv" type: text rewrite: false;
		save "" + ((time/3600.0) as int) + ";" + averageThreshold
			to: CSVFolderPath + date_simu_starts + "_averageThreshold" + csvFilenameParams  + ".csv" type: text rewrite: false;
		save "" + ((time/3600.0) as int) + ";" + nbLPStrat1LowThreshold + ";" + nbLPStrat1LowMediumThreshold + ";" + nbLPStrat1HighMediumThreshold + ";" + nbLPStrat1HighThreshold
			to: CSVFolderPath + date_simu_starts + "_strat1_threshold_adoption_share" + csvFilenameParams  + ".csv" type: text rewrite: false;
		save "" + ((time/3600.0) as int) + ";" + nbLPStrat2LowThreshold + ";" + nbLPStrat2LowMediumThreshold + ";" + nbLPStrat2HighMediumThreshold + ";" + nbLPStrat2HighThreshold
			to: CSVFolderPath + date_simu_starts + "_strat2_threshold_adoption_share" + csvFilenameParams  + ".csv" type: text rewrite: false;
		save "" + ((time/3600.0) as int) + ";" + nbLPStrat3LowThreshold + ";" + nbLPStrat3LowMediumThreshold + ";" + nbLPStrat3HighMediumThreshold + ";" + nbLPStrat3HighThreshold
			to: CSVFolderPath + date_simu_starts + "_strat3_threshold_adoption_share" + csvFilenameParams  + ".csv" type: text rewrite: false;
		save "" + ((time/3600.0) as int) + ";" + nbLPStrat4LowThreshold + ";" + nbLPStrat4LowMediumThreshold + ";" + nbLPStrat4HighMediumThreshold + ";" + nbLPStrat4HighThreshold
			to: CSVFolderPath + date_simu_starts + "_strat4_threshold_adoption_share" + csvFilenameParams  + ".csv" type: text rewrite: false;
		save "" + ((time/3600.0) as int) + ";" + averageCosts
			to: CSVFolderPath + date_simu_starts + "_average_costs" + csvFilenameParams  + ".csv" type: text rewrite: false;
		save "" + ((time/3600.0) as int) + ";" + nbHavre + ";" +  nbAntwerp
			to: CSVFolderPath + date_simu_starts + "_competition_between_LH_Antwerp" + csvFilenameParams  + ".csv" type: text rewrite: false;
		save "" + ((time/3600.0) as int) + ";" + sumRoadVehicle + ";" +  sumRiverVehicle + ";" +  sumMaritimeVehicle + ";" +  sumSecondaryVehicle
			to: CSVFolderPath + date_simu_starts + "_share_transport_mode" + csvFilenameParams  + ".csv" type: text rewrite: false;
		save "" + ((time/3600.0) as int) + ";" + sumRoadQuantities + ";" +  sumRiverQuantities + ";" +  sumMaritimeQuantities + ";" +  sumSecondaryQuantities
			to: CSVFolderPath + date_simu_starts + "_share_transport_mode_quantities" + csvFilenameParams  + ".csv" type: text rewrite: false;
		save "" + ((time/3600.0) as int) + ";" + averageRoadVehicleOccupancy
			to: CSVFolderPath + date_simu_starts + "_vehicles_occupancy_road" + csvFilenameParams  + ".csv" type: text rewrite: false;
		save "" + ((time/3600.0) as int) + ";" + averageRiverVehicleOccupancy
			to: CSVFolderPath + date_simu_starts + "_vehicles_occupancy_river" + csvFilenameParams  + ".csv" type: text rewrite: false;
		save "" + ((time/3600.0) as int) + ";" + averageMaritimeVehicleOccupancy
			to: CSVFolderPath + date_simu_starts + "_vehicles_occupancy_maritime" + csvFilenameParams  + ".csv" type: text rewrite: false;
		save "" + ((time/3600.0) as int) + ";" + averageSecondaryVehicleOccupancy
			to: CSVFolderPath + date_simu_starts + "_vehicles_occupancy_secondary" + csvFilenameParams  + ".csv" type: text rewrite: false;

		do saveShareTransportModeRegion(csvFilenameParams, "Basse-Normandie");
		do saveShareTransportModeRegion(csvFilenameParams, "Haute-Normandie");
		do saveShareTransportModeRegion(csvFilenameParams, "Centre");
		do saveShareTransportModeRegion(csvFilenameParams, "Ile-de-France");
		do saveShareTransportModeRegion(csvFilenameParams, "Picardie");
		do saveShareTransportModeRegion(csvFilenameParams, "Antwerpen");
		do saveShareTransportModeRegion(csvFilenameParams, "Le Havre");

		do saveSharePortOriginRegion(csvFilenameParams, "Basse-Normandie");
		do saveSharePortOriginRegion(csvFilenameParams, "Haute-Normandie");
		do saveSharePortOriginRegion(csvFilenameParams, "Centre");
		do saveSharePortOriginRegion(csvFilenameParams, "Ile-de-France");
		do saveSharePortOriginRegion(csvFilenameParams, "Picardie");
		do saveSharePortOriginRegion(csvFilenameParams, "Antwerpen");
		do saveSharePortOriginRegion(csvFilenameParams, "Le Havre");

		do saveDistribution(csvFilenameParams, distributionNbFCPerLSPY);

		save "" + ((time/3600.0) as int) + ";" + trafficValueCSN
			to: CSVFolderPath + date_simu_starts + "_traffic_evolution_CSN" + csvFilenameParams  + ".csv" type: text rewrite: false;
	}

	action saveDistribution(string params, list<int> values) {
		string s <- "";
		int i <- 0;
		loop while: i < length(values) {
			s <- s + ";" +values[i];
			i <- i + 1;
		}
		save "" + ((time/3600.0) as int) + s
			to: CSVFolderPath + date_simu_starts + "_distribution_nb_FC_per_LSP_" + params  + ".csv" type: text rewrite: false;
	}

	action saveShareTransportModeRegion(string params, string n){
		RegionObserver sr <- nil;
		int i <- 0;
		bool notfound <- true;
		loop while: i < length(RegionObserver) and notfound {
			if(RegionObserver[i].name = n){
				sr <- RegionObserver[i];
				save "" + ((time/3600.0) as int) + ";" + sr.sumRoadVehicleRO + ";" +  sr.sumRiverVehicleRO + ";" +  sr.sumMaritimeVehicleRO + ";" +  sr.sumSecondaryVehicleRO
					to: CSVFolderPath + date_simu_starts + "_share_transport_mode_" + n + params  + ".csv" type: text rewrite: false;
				save "" + ((time/3600.0) as int) + ";" + sr.sumRoadQuantitiesRO + ";" +  sr.sumRiverQuantitiesRO + ";" +  sr.sumMaritimeQuantitiesRO + ";" +  sr.sumSecondaryQuantitiesRO
					to: CSVFolderPath + date_simu_starts + "_share_transport_mode_quantities_" + n + params  + ".csv" type: text rewrite: false;
				notfound <- false;

				save "" + ((time/3600.0) as int) + ";" + sr.sumLeavingRoadVehicleRO + ";" +  sr.sumLeavingRiverVehicleRO + ";" +  sr.sumLeavingMaritimeVehicleRO + ";" +  sr.sumLeavingSecondaryVehicleRO
					to: CSVFolderPath + date_simu_starts + "_share_leaving_vehicles_per_transport_mode_" + n + params  + ".csv" type: text rewrite: false;
				save "" + ((time/3600.0) as int) + ";" + sr.sumLeavingRoadQuantitiesRO + ";" +  sr.sumLeavingRiverQuantitiesRO + ";" +  sr.sumLeavingMaritimeQuantitiesRO + ";" +  sr.sumLeavingSecondaryQuantitiesRO
					to: CSVFolderPath + date_simu_starts + "_share_leaving_quantities_per_transport_mode_" + n + params  + ".csv" type: text rewrite: false;
				notfound <- false;
			}
			i <- i + 1;
		}
	}

	action saveSharePortOriginRegion(string params, string n){
		RegionObserver sr <- nil;
		int i <- 0;
		bool notfound <- true;
		loop while: i < length(RegionObserver) and notfound {
			if(RegionObserver[i].name = n){
				sr <- RegionObserver[i];
				save "" + ((time/3600.0) as int) + ";" + sr.nbAntwerp + ";" +  sr.nbHavre
					to: CSVFolderPath + date_simu_starts + "_share_port_origin_region_" + n + params  + ".csv" type: text rewrite: false;
				notfound <- false;
			}
			i <- i + 1;
		}
	}

	string setParams {
		string params <- "";
		if(allowScenarionCanalSeineNord){
			params <- params + "_CSN"+allowScenarionCanalSeineNord;
		}
		if(allowScenarioBlockRoads){
			params <- params + "_BR"+allowScenarioBlockRoads;
		}
		if(allowScenarioAttractiveness){
			params <- params + "_Attr"+allowScenarioAttractiveness;
		}
		if(isLocalLSPSwitcStrat) {
			params <- params + "_LSPSwitchStrats"+possibleLSPSwitcStrats;
		}
		else {
			params <- params + "_LSPSwitchStrat"+globalLSPSwitchStrat;
		}
		if(localThreshold) {
			params <- params + "_Thresholds"+minlocalThreshold*100+"-"+maxlocalThreshold*100;
		}
		else {
			params <- params + "_Threshold"+globalThreshold*100;
		}
		if(isLocalCostPathStrategy) {
			params <- params + "_PathStrats"+possibleCostPathStrategies;
		}
		else {
			params <- params + "_PathStrat"+globalCostPathStrategy;
		}
		if(isLocalSelectingWarehouseStrategies) {
			params <- params + "_SelectingWarehouseStrats"+possibleSelectingWarehouseStrategies;
		}
		else {
			params <- params + "_SelectingWarehouseStrat"+globalSelectingWarehouseStrategies;
		}
		return params;
	}
}