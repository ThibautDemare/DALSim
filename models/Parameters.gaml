model Parameters

import "FinalConsignee.gaml"
import "Warehouse.gaml" 
import "LogisticsServiceProvider.gaml"

global {
	float step <- 60 #mn;//60 minutes per step
	date starting_date <- date([2018,6,5,11,0,0]);// 5 Juin 2018 11h00

	// Selecting Warehouse Strategies
	bool isLocalSelectingWarehouseStrategies <- false;
	int globalSelectingWarehouseStrategies <- 1;
	list<int> possibleSelectingWarehouseStrategies <- [1, 2, 3, 4]; //[1];//[1, 4];// [1, 2, 3, 4] // 1 : biased random selection - 2 : accessibility - 3 : closest/largest - 4 : pure random selection
	int numberWarehouseSelected <- 10;

	// Cost path strategies
	bool isLocalCostPathStrategy <- false;
	list<string> possibleCostPathStrategies <- ['financial_costs','travel_time'];
	string globalCostPathStrategy <- 'financial_costs';
	int costsMemory <- 50; // size of the arrays used to compute costs of LSP by FC (=> equal to the number of deliveries made)
	int neighborsDistance <- 10°km;

	// Parameters relative to the threshold used by LSPs to decide when to restock
	bool localThreshold <- false;
	float minlocalThreshold <- 0.05;
	float maxlocalThreshold <- 0.2;
	float globalThreshold <- 0.15;

	// Parameters relative to the ability of the final consignee to switch of LSP
	bool isLocalLSPSwitcStrat <- false;
	list<int> possibleLSPSwitcStrats <- [1, 2, 3]; // 1 : NbStockShortages - 2 : TimeToBeDelivered - 3 : Costs
	int globalLSPSwitchStrat <- 3;
	bool allowLSPSwitch <- true;

	// Attractiveness parameters
	float LHAttractiveness;
	float AntAttractiveness;

	/*
	 * Allow or disallow the execution of scenarios
	 */
	bool allowScenarioAttractiveness <- false;
	bool allowScenarioBlockRoads <- false;
	bool allowScenarionCanalSeineNord <- false;
	int cycleWhenOpenCanalSeineNord <- 1000;

	/*
	 * Some variables and functions to call some reflex
	 */
	 
	// The minimal number of days a final destination manager must wait before he can decide if he wants to change of logistic provider
	int minimalNumberOfHoursOfContract <- 336; // number of steps for two weeks
	// The number of steps considered to compute the logistic provider efficiency
	int nbStepsConsideredForLPEfficiency <- 96; // 4 days
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

	/**
	 * Each final destination manager is associated to a rate of decreasing of his stocks.
	 * This rate is computed thanks to a linear function according to the previously computed Huff value associated to the building.
	 * The more the Huff value is high, the more the stocks decrease quickly, the more the rate is down
	 */
	float valForMinHuff <- 6.0;
	float valForMaxHuff <- 2.0;
	action init_decreasingRateOfStocks {
		list<FinalConsignee> dests <- FinalConsignee sort_by each.huffValue;
		int i <- 0;
		int ld <- length(dests);
		loop while: i < ld {
			FinalConsignee fdm <- dests[i];
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
			w.cost <- rnd(valForMaxCost - valForMinCost) + valForMinCost;// round(((valForMaxCost-valForMinCost) / (length(lw)-1)) * (i) + valForMinCost);
			i <- i + 1;
		}
	}
}