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
	output {
		file name: "stocks_warehouses" type: text data: ""+ ((time/3600.0) as int) + "; " +stockInWarehouse + ";" + freeSurfaceInWarehouse + ";";
		
		file name: "stocks_final_dests" type: text data: ""+ ((time/3600.0) as int) + "; " + ";" + stockInFinalDest + ";" + freeSurfaceInFinalDest + ";";
		
		file name: "cumulative_number_batches" type: text data: ""+ ((time/3600.0) as int) + "; " + 
			cumulativeNumberOfBatch + ";" + cumulativeNumberOfBatchProviderToLarge + ";" + cumulativeNumberOfBatchLargeToClose + ";" + cumulativeNumberOfBatchCloseToFinal + ";";
			
		file name: "cumulative_stock_on_roads" type: text data: ""+ ((time/3600.0) as int) + "; " + 
			cumulativeStockOnRoads + ";" + cumulativeStockOnRoadsProviderToLarge + ";" + cumulativeStockOnRoadsLargeToClose + ";" + cumulativeStockOnRoadsCloseToFinal + ";";
		
		file name: "number_batches" type: text data: ""+ ((time/3600.0) as int) + "; " + 
			totalNumberOfBatch + ";" + numberOfBatchProviderToLarge + ";" + numberOfBatchLargeToClose + ";" + numberOfBatchCloseToFinal + ";";
			
		file name: "stock_on_roads" type: text data: ""+ ((time/3600.0) as int) + "; " + 
			stockOnRoads + ";" + stockOnRoadsProviderToLarge + ";" + stockOnRoadsLargeToClose + ";" + stockOnRoadsCloseToFinal;
	}
}

experiment exp_one_display type: gui {
	output {
		display all {
			species Provider aspect: base;
			species Warehouse aspect: base;
			species FinalDestinationManager aspect: base;
			species Batch aspect: base;
			species Road aspect: geom;
		}
	}
}

experiment exp_separate_displays type: gui {
	output {
		display display_FinalDestinationManager {
			species Batch aspect: base;
			species Provider aspect: base;
			species FinalDestinationManager aspect: base;
			species Road aspect: geom; 			
		}
		display display_Warehouse {
			species Batch aspect: base;
			species Provider aspect: base;
			species Warehouse aspect: base;
			species Road aspect: geom; 
		}
		display display_LogisticProvider {
			species Batch aspect: base;
			species Provider aspect: base;
			species LogisticProvider aspect: base;
			species Road aspect: geom; 
		}
		display batch_road {
			species Batch aspect: little_base;
			species Road aspect: geom; 
		}
	}
}

experiment exp_chart type: gui {
	output {
		/*display chart_number_of_batch refresh_every: 1 {
			chart  "Number of batches" type: series {
				data "Total number of batch" value: totalNumberOfBatch color: rgb('purple') ;
				data "Number of batch going from the provider to a large warehouse" value: numberOfBatchProviderToLarge color: rgb('blue') ;
				data "Number of batch going from a large warehouse to an average one" value: numberOfBatchLargeToClose color: rgb('green') ;
				data "Number of batch going from a small warehouse to a final destination" value: numberOfBatchCloseToFinal color: rgb('red') ;
			}
		}/**/
		
		display chart_cumulative_number_of_batch refresh_every: 1 {
			chart  "Cumulative number of batches" type: series {
				data "Cumulative number of batch" value: cumulativeNumberOfBatch color: rgb('blue') ;
				data "Cumulative number of batch going from the provider to a large warehouse" value: cumulativeNumberOfBatchProviderToLarge color: rgb('blue') ;
				data "Cumulative number of batch going from a large warehouse to an average one" value: cumulativeNumberOfBatchLargeToClose color: rgb('green') ;
				data "Cumulative number of batch going from a small warehouse to a final destination" value: cumulativeNumberOfBatchCloseToFinal color: rgb('red') ;
			}
		}/**/
		
		/*display chart_stock_on_roads refresh_every: 1 {
			chart  "Stock quantity within batches" type: series {
				data "Total quantity of goods within batches" value: stockOnRoads color: rgb('purple') ;
				data "Quantity of goods within batches going from the provider to a large warehouse" value: stockOnRoadsProviderToLarge color: rgb('blue') ;
				data "Quantity of goods within batches going from a large warehouse to a average one" value: stockOnRoadsLargeToClose color: rgb('green') ;
				data "Quantity of goods within batches going from a small warehouse to a final destination" value: stockOnRoadsCloseToFinal color: rgb('red') ;
			}
		}/**/
		
		display chart_cumulative_stock_on_roads refresh_every: 1 {
			chart  "Cumulative stock quantity within batches" type: series {
				data "Cumulative quantity of goods within batches" value: cumulativeStockOnRoads color: rgb('blue') ;
				data "Cumulative quantity of goods within batches going from the provider to a large warehouse" value: cumulativeStockOnRoadsProviderToLarge color: rgb('blue') ;
				data "Cumulative quantity of goods within batches going from a large warehouse to a average one" value: cumulativeStockOnRoadsLargeToClose color: rgb('green') ;
				data "Cumulative quantity of goods within batches going from a small warehouse to a final destination" value: cumulativeStockOnRoadsCloseToFinal color: rgb('red') ;
			}
		}/**/
		
		/*display chart_total_stock_in_final_dest refresh_every: 1 {
			chart  "Stock quantity in final destinations" type: series {
				data "Total stock quantity in final destinations" value: stockInFinalDest color: rgb('green') ;
				data "Total free surface in final destinations" value: freeSurfaceInFinalDest color: rgb('blue') ;
			}
		}/**/
		
		/*display chart_total_stock_in_warehouse refresh_every: 1 {
			chart  "Stock quantity in warehouses" type: series {
				data "Total stock quantity in warehouses" value: stockInWarehouse color: rgb('orange') ;
				data "Total free surface in warehouses" value: freeSurfaceInWarehouse color: rgb('blue') ;
			}
		}/**/
		
		display chart_number_empty_stock_final_dest refresh_every: 1 {
			chart  "Number of empty stock in final destinations" type: series {
				data "Number of empty stock in final destinations" value: numberofEmptyStockInFinalDests color: rgb('green') ;
			}
		}/**/
		
		display chart_number_empty_stock_warehouses refresh_every: 1 {
			chart  "Number of empty stock in warehouses" type: series {
				data "Number of empty stock in warehouses" value: numberOfEmptyStockInWarehouses color: rgb('green') ;
			}
		}/**/
	}
}