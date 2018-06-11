model Experiments

import "Parameters.gaml"
import "Networks.gaml"
import "Perturbator.gaml"
import "CellsStockShortage.gaml"

experiment 'No ouput' type: gui {
	
}

experiment 'traffic' type: gui {
	output {
		display 'traffic' autosave: false refresh:every(1) {
			species Road aspect: geom;
			species MaritimeLine aspect: geom;
			species RiverLine aspect: geom;
			species Vehicle aspect: base;
		}
	}
}

experiment 'No output but save results' type: gui {
	parameter "saver" var: saveObservations <- true;
}

experiment 'Scenario: block roads' type: gui {

	user_command print_blocked_road action:print_blocked_road;

	output {
		display display_warehouse autosave: true refresh:every(1) {
			species Road aspect: geom;
			species MaritimeLine aspect: geom;
			species RiverLine aspect: geom;
			event [mouse_down] action: block_one_road;
		}
	}
}

experiment 'Scenario: update attractiveness' type: gui {
	parameter "saver" var: saveObservations <- true;
	parameter "Le Havre's attractiveness" var: LHAttractiveness <- 1.0;
	parameter "Antwerp's attractiveness" var: AntAttractiveness <- 3.0;
	
	user_command Update_Ports_Attractiveness action:update_proba_to_choose_provider;

	output {
		display display_lp autosave: true refresh:every(1) {
			species Road aspect: geom;
			species MaritimeLine aspect: geom;
			species RiverLine aspect: geom;
			species LogisticsServiceProvider aspect: base;
		}
	}
}

experiment 'Every output' type: gui {
	parameter "saver" var: saveObservations <- true;
	parameter "Le Havre's attractiveness" var: LHAttractiveness <- 1.0;
	parameter "Antwerp's attractiveness" var: AntAttractiveness <- 3.0;
	user_command Update_Ports_Attractiveness action:update_proba_to_choose_provider;

	output {
		display 'All agents' autosave: false refresh:every(1) {
			species Road aspect: geom;
			species MaritimeLine aspect: geom;
			species RiverLine aspect: geom;
			species Warehouse aspect: base;
			species FinalDestinationManager aspect: base;
			species Provider aspect: base;
			species LogisticsServiceProvider aspect: simple_base;
			species Vehicle aspect: base;
		}

		display 'FC and LSP' autosave: false refresh:every(1) {
			species Road aspect: geom;
			species MaritimeLine aspect: geom;
			species RiverLine aspect: geom;
			species Warehouse aspect: base;
			species FinalDestinationManager aspect: base;
			species Provider aspect: base;
		}
		
		display 'Ports attractiveness and LSP' autosave: false refresh:every(1) {
			species Road aspect: geom;
			species MaritimeLine aspect: geom;
			species RiverLine aspect: geom;
			species LogisticsServiceProvider aspect: base;
		}/**/

		display 'Grid with stock shortages' autosave: false refresh:every(1) {
			species Road aspect: geom;
			species MaritimeLine aspect: geom;
			species RiverLine aspect: geom;
			species Warehouse aspect: base_condition;
			species FinalDestinationManager aspect: base;
			species Provider aspect: base;
			grid cell_stock_shortage;
			species Vehicle aspect: base;
		}

		display 'Traffic' autosave: true refresh:every(1) {
			species Road aspect: geom;
			species MaritimeLine aspect: geom;
			species RiverLine aspect: geom;
			event [mouse_down] action: block_one_road;
		}

		/*display 'Number of Vehicles' refresh:every(1) {
			chart  "Number of batches" type: series {
				data "Total number of batch" value: totalNumberOfBatch color: rgb('purple') ;
				data "Number of batch going from the provider to a large warehouse" value: numberOfBatchProviderToLarge color: rgb('blue') ;
				data "Number of batch going from a large warehouse to an average one" value: numberOfBatchLargeToClose color: rgb('green') ;
				data "Number of batch going from a small warehouse to a final destination" value: numberOfBatchCloseToFinal color: rgb('red') ;
			}
		}/**/

		/*display 'Cumulative number of Vehicles' refresh:every(1) {
			chart  "Cumulative number of batches" type: series {
				data "Cumulative number of batch" value: cumulativeNumberOfBatch color: rgb('blue') ;
				data "Cumulative number of batch going from the provider to a large warehouse" value: cumulativeNumberOfBatchProviderToLarge color: rgb('blue') ;
				data "Cumulative number of batch going from a large warehouse to an average one" value: cumulativeNumberOfBatchLargeToClose color: rgb('green') ;
				data "Cumulative number of batch going from a small warehouse to a final destination" value: cumulativeNumberOfBatchCloseToFinal color: rgb('red') ;
			}
		}/**/

		/*display 'Stocks in transportation' refresh:every(1) {
			chart  "Stock quantity within batches" type: series {
				data "Total quantity of goods within batches" value: stockOnRoads color: rgb('purple') ;
				data "Quantity of goods within batches going from the provider to a large warehouse" value: stockOnRoadsProviderToLarge color: rgb('blue') ;
				data "Quantity of goods within batches going from a large warehouse to a average one" value: stockOnRoadsLargeToClose color: rgb('green') ;
				data "Quantity of goods within batches going from a small warehouse to a final destination" value: stockOnRoadsCloseToFinal color: rgb('red') ;
			}
		}/**/

		/*display 'Cumulative stocks in transportation' refresh:every(1) {
			chart  "Cumulative stock quantity within batches" type: series {
				data "Cumulative quantity of goods within batches" value: cumulativeStockOnRoads color: rgb('blue') ;
				data "Cumulative quantity of goods within batches going from the provider to a large warehouse" value: cumulativeStockOnRoadsProviderToLarge color: rgb('blue') ;
				data "Cumulative quantity of goods within batches going from a large warehouse to a average one" value: cumulativeStockOnRoadsLargeToClose color: rgb('green') ;
				data "Cumulative quantity of goods within batches going from a small warehouse to a final destination" value: cumulativeStockOnRoadsCloseToFinal color: rgb('red') ;
			}
		}/**/

		display 'Stocks in final destination' refresh:every(1) {
			chart  "Stock quantity in final destinations" type: series {
				data "Total stock quantity in final destinations" value: stockInFinalDest color: rgb('green') ;
				data "Total free surface in final destinations" value: freeSurfaceInFinalDest color: rgb('blue') ;
			}
		}/**/

		display 'Stocks in warehouses' refresh:every(1) {
			chart  "Stock quantity in warehouses" type: series {
				data "Total stock quantity in warehouses" value: stockInWarehouse color: rgb('green') ;
				data "Total free surface in warehouses" value: freeSurfaceInWarehouse color: rgb('blue') ;
			}
		}/**/

		display 'Empty stocks in final destination' refresh:every(1) {
			chart  "Number of empty stock in final destinations" type: series {
				data "Number of empty stock in final destinations" value: numberofEmptyStockInFinalDests color: rgb('green') ;
			}
		}/**/

		display 'Empty stocks in warehouses' refresh:every(1) {
			chart  "Number of empty stock in warehouses" type: series {
				data "Number of empty stock in warehouses" value: numberOfEmptyStockInWarehouses color: rgb('green') ;
			}
		}/**/

		display 'Average time to deliver goods somewhere' refresh:every(1) {
			chart  "Average time that the LPs took to deliver goods somewhere" type: series {
				data "Average time that the LPs took to deliver goods somewhere" value: averageTimeToDeliver color: rgb('green') ;
			}
		}/**/

		display 'Average time to deliver goods to final destinations' refresh:every(1) {
			chart  "Average time that the LPs took to deliver goods to FDMs" type: series {
				data "Average time that the LPs took to deliver goods to FDMs" value: averageTimeToBeDelivered color: rgb('green') ;
			}
		}/**/

		display 'Share of the different strategies adopted' refresh:every(1) {
			chart  "Share of the different strategies adopted" type: series {
				data "Strategy 1 (closest/largest warehouse according to a probability)" value: nbLPStrat1 color: rgb('green') ;
				data "Strategy 2 (closest/largest warehouse according to its accessibility)" value: nbLPStrat2 color: rgb('red') ;
				data "Strategy 3 (closest/largest warehouse)" value: nbLPStrat3 color: rgb('blue') ;
				data "Strategy 4 (pure random)" value: nbLPStrat4 color: rgb('orange') ;
			}
		}/**/

		display 'Share of the different strategies adopted (smoothed)' refresh:every(1) {
			chart  "Share of the different strategies adopted" type: series {
				data "Strategy 1 (closest/largest warehouse according to a probability)" value: averageStrat1 color: rgb('green') ;
				data "Strategy 2 (closest/largest warehouse according to its accessibility)" value: averageStrat2 color: rgb('red') ;
				data "Strategy 3 (closest/largest warehouse)" value: averageStrat3 color: rgb('blue') ;
				data "Strategy 4 (pure random)" value: averageStrat4 color: rgb('orange') ;
			}
		}/**/

		display 'Share of the different strategies adopted per threshold' refresh:every(1) {
			chart  "Share of the different strategies adopted" type: series {
				data "Strategy 1 (closest/largest warehouse according to a probability) - Low threshold" value: nbLPStrat1LowThreshold color: rgb(7,127,47) ;
				data "Strategy 1 (closest/largest warehouse according to a probability) - Low medium threshold" value: nbLPStrat1LowMediumThreshold color: rgb(41,204,95) ;
				data "Strategy 1 (closest/largest warehouse according to a probability) - High medium threshold" value: nbLPStrat1HighMediumThreshold color: rgb(51,255,119) ;
				data "Strategy 1 (closest/largest warehouse according to a probability) - High threshold)" value: nbLPStrat1HighThreshold color: rgb(99,255,151) ;

				data "Strategy 2 (closest/largest warehouse according to its accessibility) - Low threshold" value: nbLPStrat2LowThreshold color: rgb(127,11,0) ;
				data "Strategy 2 (closest/largest warehouse according to its accessibility) - Low medium threshold" value: nbLPStrat2LowMediumThreshold color: rgb(204,54,41) ;
				data "Strategy 2 (closest/largest warehouse according to its accessibility) - High medium threshold" value: nbLPStrat2HighMediumThreshold color: rgb(255,68,51) ;
				data "Strategy 2 (closest/largest warehouse according to its accessibility) - High threshold)" value: nbLPStrat2HighThreshold color: rgb(255,112,99) ;

				data "Strategy 3 (closest/largest warehouse) - Low threshold" value: nbLPStrat3LowThreshold color: rgb(0,30,127) ;
				data "Strategy 3 (closest/largest warehouse) - Low medium threshold" value: nbLPStrat3LowMediumThreshold color: rgb(55,85,204) ;
				data "Strategy 3 (closest/largest warehouse) - High medium threshold" value: nbLPStrat3HighMediumThreshold color: rgb(69,106,255) ;
				data "Strategy 3 (closest/largest warehouse) - High threshold)" value: nbLPStrat3HighThreshold color: rgb(137,161,255) ;

				data "Strategy 4 (pure random) - Low threshold" value: nbLPStrat4LowThreshold color: rgb(112,38,127) ;
				data "Strategy 4 (pure random) - Low medium threshold" value: nbLPStrat4LowMediumThreshold color: rgb(168,0,204) ;
				data "Strategy 4 (pure random) - High medium threshold" value: nbLPStrat4HighMediumThreshold color: rgb(210,0,255) ;
				data "Strategy 4 (pure random) - High threshold)" value: nbLPStrat4HighThreshold color: rgb(224,76,255) ;

			}
		}/**/

		display 'Average threshold' refresh:every(1) {
			chart  "Average threshold" type: series {
				data "Average threshold (in percentage)" value: averageThreshold*100 color: rgb('blue') ;
			}
		}/**/

		display 'Stocks awating to leave providers and warehouses' refresh:every(1) {
			chart "Blocking level to make goods leave buildings" type: series {
				data "Number of stocks awaiting to leave warehouses" value: nbStocksAwaitingToLeaveWarehouse color: rgb('blue') ;
				data "Number of stocks awaiting to leave providers" value: nbStocksAwaitingToLeaveProvider color: rgb('violet') ;
			}
		}/**/

		display "Stocks awating to enter warehouses or final destination's building" refresh:every(1) {
			chart "Blocking level to make goods enter buildings" type: series {
				data "Number of stocks awaiting to enter buildings" value: nbStocksAwaitingToEnterBuilding color: rgb('green') ;
				data "Number of stocks awaiting to enter warehouses" value: nbStocksAwaitingToEnterWarehouse color: rgb('red') ;
			}
		}/**/

		display 'Average costs' refresh:every(1) {
			chart "Average Costs" type: series {
				data "average costs" value: averageCosts color: rgb('green') ;
			}
		}/**/

		display 'Competition between Le Havre and Antwerp' refresh:every(1) {
			chart "Competition between the ports of Le Havre and Antwerp" type: series {
				data "Number of LP using Le Havre" value: nbHavre color: rgb('green') ;
				data "Number of LP using Antwerp" value: nbAntwerp color: rgb('red') ;
			}
		}/**/
	}
}