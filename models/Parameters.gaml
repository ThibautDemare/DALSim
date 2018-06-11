model Parameters

import "FinalDestinationManager.gaml"
import "Warehouse.gaml" 
import "LogisticsServiceProvider.gaml"

global {
	float step <- 60 #mn;//60 minutes per step
	date starting_date <- date([2018,6,5,11,0,0]);// 6 Juin 2018 à 11h00

	list<int> possibleStrategies <- [1, 4];// [1, 2, 3, 4]
	int numberWarehouseSelected <- 50;

	bool allowLSPSwitch <- true;

	// Attractiveness parameters
	float LHAttractiveness;
	float AntAttractiveness;

	/*
	 * Allow or disallow the execution of scenarios
	 */
	bool allowScenarioAttractiveness <- false;
	bool allowScenarioBlockRoads <- false;

	/*
	 * Some variables and functions to call some reflex
	 */
	 
	// The minimal number of days a final destination manager must wait before he can decide if he wants to change of logistic provider
	int minimalNumberOfHoursOfContract <- 336;
	// The number of steps considered to compute the logistic provider efficiency
	int nbStepsConsideredForLPEfficiency <- 336; // number of steps for two weeks
	// The numbers of steps between each calls to the reflex "decreasingStocks"
	int nbStepsbetweenDS <- 24;
	// The numbers of steps between each calls to the reflex "testRestockNeeded"
	int nbStepsbetweenTRN <- 24;
	// The numbers of steps between each calls to the reflex "processOrders" by Warehouse agents
	int nbStepsBetweenWPO <- 6;
	// The numbers of steps between each calls to the reflex "processOrders" by Provider agents
	int nbStepsBetweenPPO <- 6;
	// The numbers of steps between each calls to the reflex "processEnteringGoods" by Warehouse and Building agents
	int nbStepsBetweenPEG <- 24;
	
	int sizeOfStockLocalWarehouse <- 2;
	int sizeOfStockLargeWarehouse <- 3;

	bool localThreshold <- false;
	float minlocalThreshold <- 0.15;
	float maxlocalThreshold <- 0.35;
	float globalThreshold <- 0.3;

	action init_threshold {
		ask LogisticsServiceProvider {
			if(localThreshold) {
				threshold <- rnd(minlocalThreshold, maxlocalThreshold);//truncated_gauss({minlocalThreshold, maxlocalThreshold});
			}
			else {
				threshold <- globalThreshold;
			}
		}
	}

	/**
	 * Each final destination manager is associated to a rate of decreasing of his stocks.
	 * This rate is computed thanks to a linear function according to the previously computed Huff value associated to the building.
	 * The more the Huff value is high, the more the stocks decrease quickly, the more the rate is down
	 */
	float valForMinHuff <- 6.0;
	float valForMaxHuff <- 2.0;
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

	/**
	 * We associate a cost to each warehouse according to its surface.
	 */
	float valForMinCost <- 1.0;
	float valForMaxCost <- 100.0;
	action init_cost {
		list<Warehouse> lw <- Warehouse sort_by each.totalSurface;
		int i <- 0;
		int ld <- length(lw);
		loop while: i < ld {
			Warehouse w <- lw[i];
			w.cost <- round(((valForMaxCost-valForMinCost) / (length(lw)-1)) * (i) + valForMinCost);
			i <- i + 1;
		}
	}
}