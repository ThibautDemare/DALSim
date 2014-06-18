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
	file name: "results" type: text data: ""+ ((time/3600.0) as int) + "; " +
		stockInWarehouse + ";" + stockInFinalDest + ";" +
		totalNumberOfBatch + ";" + numberOfBatchProviderToLarge + ";" + numberOfBatchLargeToAverage + ";" + numberOfBatchAverageToSmall + ";" + numberOfBatchSmallToFinal + ";" + 
		stockOnRoads + ";" + stockOnRoadsProviderToLarge + ";" + stockOnRoadsLargeToAverage + ";" + stockOnRoadsAverageToSmall + ";" + stockOnRoadsSmallToFinal;
	}
}

experiment exp_one_display type: gui {
	output {
		display all {
			species Batch aspect: base;
			species Provider aspect: base;
			species Warehouse aspect: base;
			species FinalDestinationManager aspect: base;
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
		display chart_number_of_batch_ refresh_every: 24 {
			chart  "Number of batch of a supply chains with three intermediaries warehouses" type: series {
				data "Total number of batch" value: totalNumberOfBatch color: rgb('purple') ;
				data "Number of batch going from the provider to a large warehouse" value: numberOfBatchProviderToLarge color: rgb('blue') ;
				data "Number of batch going from a large warehouse to an average one" value: numberOfBatchLargeToAverage color: rgb('green') ;
				data "Number of batch going from an average warehouse to a small one" value: numberOfBatchAverageToSmall color: rgb('orange') ;
				data "Number of batch going from a small warehouse to a final destination" value: numberOfBatchSmallToFinal color: rgb('red') ;
			}
		}
		
		display chart_stock_on_roads refresh_every: 24 {
			chart  "Stock quantity within batch of a supply chains with two intermediaries warehouses" type: series {
				data "Total quantity of goods within batches" value: stockOnRoads color: rgb('purple') ;
				data "Quantity of goods within batches going from the provider to a large warehouse" value: stockOnRoadsProviderToLarge color: rgb('blue') ;
				data "Quantity of goods within batches going from a large warehouse to a average one" value: stockOnRoadsLargeToAverage color: rgb('green') ;
				data "Quantity of goods within batches going from a average warehouse to a small one" value: stockOnRoadsAverageToSmall color: rgb('orange') ;
				data "Quantity of goods within batches going from a small warehouse to a final destination" value: stockOnRoadsSmallToFinal color: rgb('red') ;
			}
		}
		/**/
		
		/*
		display chart_average_stock_on_roads refresh_every: 24 {
			chart "Stock quantity on road" type: series {
				data "Average stock quantity on road" value: stockOnRoads color: rgb('red') ;
			}
		}
		display chart_average_stock_in_final_dest refresh_every: 24 {
			chart  "Stock quantity in final destinations" type: series {
				data "Average stock quantity in final destinations" value: stockInFinalDest color: rgb('green') ;
			}
		}
		display chart_average_stock_in_warehouse refresh_every: 24 {
			chart  "Stock quantity in warehouses" type: series {
				data "Average stock quantity in warehouses" value: stockInWarehouse color: rgb('orange') ;
			}
		}*/
	}
}