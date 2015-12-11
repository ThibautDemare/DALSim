/**
 *  Experiments
 *  Author: Thibaut
 *  Description: 
 */

model Experiments


import "./Observer.gaml"

import "./Road.gaml"
import "./Warehouse.gaml"
import "./LogisticProvider.gaml"
import "./Provider.gaml"
import "./FinalDestinationManager.gaml"
import "./Batch.gaml"

experiment exp_no_output type: gui {
	
}

experiment exp_save_results type: gui {
	parameter "saver" var: saveObservations <- true;
}

experiment exp_all type: gui {
	parameter "saver" var: saveObservations <- true;

	output {
		display display_grid_stock_shortage autosave: true refresh:every(1) {
			species Road aspect: geom;
			species Warehouse aspect: base_condition;
			species FinalDestinationManager aspect: base;
			species Provider aspect: base;
			grid cell_stock_shortage;
			species Batch aspect: little_base;
		}
	}

	output {
		display chart_number_of_batch refresh:every(1) {
			chart  "Number of batches" type: series {
				data "Total number of batch" value: totalNumberOfBatch color: rgb('purple') ;
				data "Number of batch going from the provider to a large warehouse" value: numberOfBatchProviderToLarge color: rgb('blue') ;
				data "Number of batch going from a large warehouse to an average one" value: numberOfBatchLargeToClose color: rgb('green') ;
				data "Number of batch going from a small warehouse to a final destination" value: numberOfBatchCloseToFinal color: rgb('red') ;
			}
		}/**/

		display chart_cumulative_number_of_batch refresh:every(1) {
			chart  "Cumulative number of batches" type: series {
				data "Cumulative number of batch" value: cumulativeNumberOfBatch color: rgb('blue') ;
				data "Cumulative number of batch going from the provider to a large warehouse" value: cumulativeNumberOfBatchProviderToLarge color: rgb('blue') ;
				data "Cumulative number of batch going from a large warehouse to an average one" value: cumulativeNumberOfBatchLargeToClose color: rgb('green') ;
				data "Cumulative number of batch going from a small warehouse to a final destination" value: cumulativeNumberOfBatchCloseToFinal color: rgb('red') ;
			}
		}/**/

		display chart_stock_on_roads refresh:every(1) {
			chart  "Stock quantity within batches" type: series {
				data "Total quantity of goods within batches" value: stockOnRoads color: rgb('purple') ;
				data "Quantity of goods within batches going from the provider to a large warehouse" value: stockOnRoadsProviderToLarge color: rgb('blue') ;
				data "Quantity of goods within batches going from a large warehouse to a average one" value: stockOnRoadsLargeToClose color: rgb('green') ;
				data "Quantity of goods within batches going from a small warehouse to a final destination" value: stockOnRoadsCloseToFinal color: rgb('red') ;
			}
		}/**/

		display chart_cumulative_stock_on_roads refresh:every(1) {
			chart  "Cumulative stock quantity within batches" type: series {
				data "Cumulative quantity of goods within batches" value: cumulativeStockOnRoads color: rgb('blue') ;
				data "Cumulative quantity of goods within batches going from the provider to a large warehouse" value: cumulativeStockOnRoadsProviderToLarge color: rgb('blue') ;
				data "Cumulative quantity of goods within batches going from a large warehouse to a average one" value: cumulativeStockOnRoadsLargeToClose color: rgb('green') ;
				data "Cumulative quantity of goods within batches going from a small warehouse to a final destination" value: cumulativeStockOnRoadsCloseToFinal color: rgb('red') ;
			}
		}/**/

		display chart_total_stock_in_final_dest refresh:every(1) {
			chart  "Stock quantity in final destinations" type: series {
				data "Total stock quantity in final destinations" value: stockInFinalDest color: rgb('green') ;
				data "Total free surface in final destinations" value: freeSurfaceInFinalDest color: rgb('blue') ;
			}
		}/**/

		display chart_total_stock_in_warehouse refresh:every(1) {
			chart  "Stock quantity in warehouses" type: series {
				data "Total stock quantity in warehouses" value: stockInWarehouse color: rgb('green') ;
				data "Total free surface in warehouses" value: freeSurfaceInWarehouse color: rgb('blue') ;
			}
		}/**/

		display chart_number_empty_stock_final_dest refresh:every(1) {
			chart  "Number of empty stock in final destinations" type: series {
				data "Number of empty stock in final destinations" value: numberofEmptyStockInFinalDests color: rgb('green') ;
			}
		}/**/

		display chart_number_empty_stock_warehouses refresh:every(1) {
			chart  "Number of empty stock in warehouses" type: series {
				data "Number of empty stock in warehouses" value: numberOfEmptyStockInWarehouses color: rgb('green') ;
			}
		}/**/

		display chart_averageTimeToDeliver refresh:every(1) {
			chart  "Average time that the LPs took to deliver goods somewhere" type: series {
				data "Average time that the LPs took to deliver goods somewhere" value: averageTimeToDeliver color: rgb('green') ;
			}
		}/**/

		display chart_averageTimeToBeDelivered refresh:every(1) {
			chart  "Average time that the LPs took to deliver goods to FDMs" type: series {
				data "Average time that the LPs took to deliver goods to FDMs" value: averageTimeToBeDelivered color: rgb('green') ;
			}
		}/**/

		display chart_strategyShare refresh:every(1) {
			chart  "Share of the different strategies adopted" type: series {
				data "Strategy 1" value: nbLPStrat1 color: rgb('green') ;
				data "Strategy 2" value: nbLPStrat2 color: rgb('red') ;
				data "Strategy 3" value: nbLPStrat3 color: rgb('blue') ;
				data "Strategy 4" value: nbLPStrat4 color: rgb('orange') ;
			}
		}/**/

		display chart_stockAwaiting refresh:every(1) {
			chart "Blocking level to make goods enter or leave buildings" type: series {
				data "Number of stocks awaiting to enter a building" value: nbStocksAwaitingToEnter color: rgb('green') ;
				data "Number of stocks awaiting to leave a building" value: nbStocksAwaitingToLeave color: rgb('red') ;
			}
		}/**/
	}
}