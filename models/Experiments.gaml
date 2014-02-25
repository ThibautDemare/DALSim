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
		file name: "results" type: text data: ""+(time/3600.0) + "; " + stockInWarehouseT2 + ";" + stockInFinalDestT2 + ";" + numberOfBatchLargeToAverageT2 + ";" + numberOfBatchAverageToSmallT2 + ";" + numberOfBatchSmallToFinalT2 + ";" + numberOfBatchProviderToLargeT2 + ";" + totalNumberOfBatchT2 + "; " + stockOnRoadsProviderToLargeT2 + "; " + stockOnRoadsLargeToAverageT2 + "; " + stockOnRoadsAverageToSmallT2 + "; " + stockOnRoadsSmallToFinalT2 + ";" + stockOnRoadsT2;
		file name: "results_average" type: text data: ""+(time/3600.0) + "; " + stockInWarehouse + ";" + stockInFinalDest + ";" + numberOfBatchLargeToAverage + ";" + numberOfBatchAverageToSmall + ";" + numberOfBatchSmallToFinal + ";" + numberOfBatchProviderToLarge + ";" + totalNumberOfBatch + "; " + stockOnRoadsProviderToLarge + "; " + stockOnRoadsLargeToAverage + "; " + stockOnRoadsAverageToSmall + "; " + stockOnRoadsSmallToFinal + ";" + stockOnRoads;
	}
}

experiment exp_display type: gui {
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
		display chart_average_number_of_batch refresh_every: 24 {
			chart  "Number of batch" type: series {
				data "Average total number of batch" value: totalNumberOfBatch color: rgb('purple') ;
				data "Average number of batch going from the provider to a large warehouse" value: numberOfBatchProviderToLarge color: rgb('blue') ;
				data "Average number of batch going from a large warehouse to an average one" value: numberOfBatchLargeToAverage color: rgb('green') ;
				data "Average number of batch going from an average warehouse to a small one" value: numberOfBatchAverageToSmall color: rgb('orange') ;
				data "Average number of batch going from a small warehouse to a final destination" value: numberOfBatchSmallToFinal color: rgb('red') ;
			}
		}
		
		display chart_number_of_batch {
			chart  "Number of batch" type: series {
				data "Number of batch" value: totalNumberOfBatchT2 color: rgb('purple') ;
				data "Number of batch going from the provider to a large warehouse" value: numberOfBatchProviderToLargeT2 color: rgb('blue') ;
				data "Number of batch going from a large warehouse to an average one" value: numberOfBatchLargeToAverageT2 color: rgb('green') ;
				data "Number of batch going from an average warehouse to a small one" value: numberOfBatchAverageToSmallT2 color: rgb('orange') ;
				data "Number of batch going from a small warehouse to a final destination" value: numberOfBatchSmallToFinalT2 color: rgb('red') ;
			}
		}
		
		display chart_average_stock_on_roads refresh_every: 24 {
			chart "Stock quantity on road" type: series {
				data "Average stock quantity on road" value: stockOnRoads color: rgb('red') ;
			}
		}
		
		display chart_stock_on_roads {
			chart "Stock quantity on road" type: series {
				data "Stock quantity on road" value: stockOnRoadsT2 color: rgb('red') ;
			}
		}
		
		display chart_average_stock_in_final_dest refresh_every: 24 {
			chart  "Stock quantity in final destinations" type: series {
				data "Average stock quantity in final destinations" value: stockInFinalDest color: rgb('green') ;
			}
		}
		
		display chart_stock_in_final_dest {
			chart  "Stock quantity in final destinations" type: series {
				data "Stock quantity in final destinations" value: stockInFinalDestT2 color: rgb('green') ;
			}
		}
		
		display chart_average_stock_in_warehouse refresh_every: 24 {
			chart  "Stock quantity in warehouses" type: series {
				data "Average stock quantity in warehouses" value: stockInWarehouse color: rgb('orange') ;
			}
		}
		
		display chart_stock_in_warehouse {
			chart  "Stock quantity in warehouses" type: series {
				data "Stock quantity in warehouses" value: stockInWarehouseT2 color: rgb('orange') ;
			}
		}
	}
}