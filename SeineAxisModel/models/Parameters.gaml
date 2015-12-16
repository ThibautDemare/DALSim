/**
 *  Parameters
 *  Author: Thibaut
 *  Description: 
 */

model Parameters


import "./SeineAxisModel.gaml"
import "./FinalDestinationManager.gaml"

global {
	float step <- 60 °mn;//60 minutes per step
	
	bool localStrategy <- true;
	int globalAdoptedStrategy <- 3;
	int numberWarehouseSelected <- 15;

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
	int nbStepsBetweenWPO <- 12;
	// The numbers of steps between each calls to the reflex "processOrders" by Provider agents
	int nbStepsBetweenPPO <- 6;
	// The numbers of steps between each calls to the reflex "processEnteringGoods" by Warehouse and Building agents
	int nbStepsBetweenPEG <- 12;
	
	int sizeOfStockLocalWarehouse <- 2;
	int sizeOfStockLargeWarehouse <- 3;
	
	float threshold <- 0.3;
	
	/**
	 * Each final destination manager is associated to a rate of decreasing of his stocks.
	 * This rate is computed thanks to a linear function according to the previously computed Huff value associated to the building.
	 * The more the Huff value is high, the more the stocks decrease quickly, the more the rate is down
	 */
	float valForMinHuff <- 6.0;
	float valForMaxHuff <- 4.0;
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
	 * Each warehouse has a capacity to process order by time unit. This capacity is determined according to the total surface of this warehouse.
	 * Indeed, we assume that the larger the warehouse is, the more it has ressources to process the orders.
	 */
	float valForMinCapacity <- 1.0;
	float valForMaxCapacity <- 4.0;
	action init_Order_Processing_Capacity {
		list<Warehouse> lw <- Warehouse sort_by each.totalSurface;
		int i <- 0;
		int ld <- length(lw);
		loop while: i < ld {
			Warehouse w <- lw[i];
			w.maxProcessOrdersCapacity <- round(((valForMaxCapacity-valForMinCapacity) / (length(lw)-1)) * (i) + valForMinCapacity);
			i <- i + 1;
		}
	}
}