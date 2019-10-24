model Experiments

import "Parameters.gaml"
import "Networks.gaml"
import "Perturbator.gaml"
import "CellsStockShortage.gaml"

global {
	// colorblind safe colors
	rgb divergingCol1 <- rgb("#a6cee3"); // light blue
	rgb divergingCol2 <- rgb("#1f78b4"); // blue
	rgb divergingCol3 <- rgb("#b2df8a"); // light green
	rgb divergingCol4 <- rgb("#33a02c"); // green

	rgb divergingCol5 <- rgb("#D81B60");// pink //rgb(95, 130, 10); // green
	rgb divergingCol6 <- rgb("#1E88E5");// blue //rgb(49, 130, 189); // blue
	rgb divergingCol7 <- rgb("#FFC107");// yellow //rgb(160, 55, 100); // purple
	rgb divergingCol8 <- rgb("#004D40");// green 

	string pathPreviousSim <- "/saveSimu.gsim";
	bool saveSimulation <- false; // Use by some experiments. It indicates if we should save the state of the simulation at the end.
	int savedSteps <- -1;// Use by some experiments, if saveSimulation = true. It indicates when we should save the state of the simulation.
	bool saveAgents <- false; // Use by some experiments. It indicates if we should save the state of the agents.
	int savedAgents <- -1;// Use by some experiments, if saveSimulation = true. It indicates when we should save the state of the agents.

	reflex storeSimulation when: saveSimulation {
		if(savedSteps > 0 and cycle mod savedSteps){
			write "================ START SAVE SIMULATION - " + cycle;
			write "Save of simulation : " + save_simulation("saveSimu_"+cycle+".gsim");
			write "================ END SAVE SIMULATION - " + cycle;
		}
	}

	reflex storeAgent when: saveAgents {
		if(savedAgents > 0 and cycle mod savedAgents){
			write "================ START SAVE  - " + cycle;
			save "costsPathStrategy; threshold; averageCosts; cumulateCosts; adoptedSelectingWarehouseStrategy; provider.port; nbCustomers; region; department" to: "LogisticsServiceProvider.csv" type: "csv" rewrite:true;
			ask LogisticsServiceProvider{
				save [costsPathStrategy, threshold, averageCosts, cumulateCosts, adoptedSelectingWarehouseStrategy, provider.port, length(customers), region, department] to: "LogisticsServiceProvider.csv" type: "csv" rewrite:false;
			}
			save "surface; localAverageCosts; localWarehousingCosts; averageCostsOfNeighbors; localVolumeNormalizedAverageCosts; localAverageNbStockShortagesLastSteps; region; department" to: "FinalConsignee.csv" type: "csv" rewrite:true;
			ask FinalConsignee {
				save [surface, localAverageCosts, localWarehousingCosts, averageCostsOfNeighbors, localVolumeNormalizedAverageCosts, localAverageNbStockShortagesLastSteps, region, department] to: "FinalConsignee.csv" type: "csv" rewrite:false;
			}
			write "================ END SAVE AGENTS - " + cycle;
		}
	}

	action backupSim {
		if(cycle mod 100 = 0 ){
			write "================ START SAVE SIMULATION - " + cycle;
			write "Save of simulation : " + save_simulation("backup_simu_"+cycle+".gsim");
			write "================ END SAVE SIMULATION - " + cycle;
		}
	}
}

experiment 'Docker' type: gui {
	parameter "saver" var: saveObservations <- true;
	parameter "pathBD" var: pathBD <- "/bd/Used/";
	parameter "CSVFolderPath" var: CSVFolderPath <- "/CSV/";
	parameter "saveSimulation" var: saveSimulation <- false;
	parameter "savedSteps" var: savedSteps <- [];
	parameter "saveAgents" var: saveAgents <- false;
	parameter "savedAgents" var: savedAgents <- [];

	reflex reflexBackup {
		ask world {
			do backupSim;
		}
	}
}

experiment 'Docker from previous simulation' type: gui {
	parameter "saver" var: saveObservations <- true;
	parameter "pathBD" var: pathBD <- "/bd/Used/";
	parameter "CSVFolderPath" var: CSVFolderPath <- "/CSV/";
	parameter "saveSimulation" var: saveSimulation <- false;
	parameter "savedSteps" var: savedSteps <- [];
	parameter "saveAgents" var: saveAgents <- false;
	parameter "savedAgents" var: savedAgents <- [];
	parameter "pathPreviousSim" var: pathPreviousSim <-  "/saveSimu.gsim";

	action _init_ {
		create simulation from: saved_simulation_file(pathPreviousSim);
	}

	reflex reflexBackup {
		ask world {
			do backupSim;
		}
	}
}

experiment 'Docker with traffic screenshots' type: gui {
	parameter "saver" var: saveObservations <- true;
	parameter "pathBD" var: pathBD <- "/bd/Used/";
	parameter "CSVFolderPath" var: CSVFolderPath <- "/CSV/";
	parameter "saveSimulation" var: saveSimulation <- false;
	parameter "savedSteps" var: savedSteps <- [];
	parameter "saveAgents" var: saveAgents <- false;
	parameter "savedAgents" var: savedAgents <- [];

	reflex reflexBackup {
		ask world {
			do backupSim;
		}
	}

	output {
		// The size of these two displays is due to the size of the calc I apply on the snapshots when I generate a video
		display 'Road traffic' autosave:{1061,988} refresh:every(1) {
			species Country aspect: geom;
			species Road aspect: geom;
		}
		display 'Maritime and River traffic' autosave:{1061,988} refresh:every(1) {
			species Country aspect: geom;
			species MaritimeLine aspect: geom;
			species RiverLine aspect: geom;
			species SecondaryTerminal aspect:geom;
			species RiverTerminal aspect:geom;
			species MaritimeRiverTerminal aspect:geom;
		}
	}
}

experiment 'No ouput' type: gui {

}

experiment 'traffic' type: gui {
	output {
		display 'traffic' autosave: false refresh:every(1) {
			species Country aspect: geom;
			species Road aspect: geom;
			species MaritimeLine aspect: geom;
			species SecondaryMaritimeLine aspect: geom;
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
			species Country aspect: geom;
			species Road aspect: geom;
			species MaritimeLine aspect: geom;
			species SecondaryMaritimeLine aspect: geom;
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
			species Country aspect: geom;
			species Road aspect: geom;
			species MaritimeLine aspect: geom;
			species SecondaryMaritimeLine aspect: geom;
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
			species Country aspect: geom;
			species RegionObserver aspect: geom;
			species Road aspect: geom;
			species MaritimeLine aspect: geom;
			species SecondaryMaritimeLine aspect: geom;
			species RiverLine aspect: geom;
			species Warehouse aspect: base;
			species FinalConsignee aspect: base;
			species Provider aspect: base;
			species LogisticsServiceProvider aspect: simple_base;
			species Vehicle aspect: base;
		}

		display 'FC and LSP' autosave: false refresh:every(1) {
			species Country aspect: geom;
			species Road aspect: lightGeom;
			species MaritimeLine aspect: lightGeom;
			species SecondaryMaritimeLine aspect: lightGeom;
			species RiverLine aspect: lightGeom;
			species Warehouse aspect: base;
			species FinalConsignee aspect: base;
			species Provider aspect: base;
		}

		display 'FC coloured according to port choice' autosave: false refresh:every(1) {
			species Country aspect: geom;
			species Road aspect: lightGeom;
			species MaritimeLine aspect: lightGeom;
			species SecondaryMaritimeLine aspect: geom;
			species RiverLine aspect: lightGeom;
			species FinalConsignee aspect: aspectPortChoice;
			species Provider aspect: base;
		}

		display 'Ports attractiveness and LSP' autosave: false refresh:every(1) {
			species Country aspect: geom;
			species Road aspect: lightGeom;
			species MaritimeLine aspect: lightGeom;
			species SecondaryMaritimeLine aspect: geom;
			species RiverLine aspect: lightGeom;
			species LogisticsServiceProvider aspect: base;
		}/**/

		display 'Grid with stock shortages' autosave: false refresh:every(1) {
			species Country aspect: geom;
			species Road aspect: lightGeom;
			species MaritimeLine aspect: lightGeom;
			species RiverLine aspect: lightGeom;
			species SecondaryMaritimeLine aspect: geom;
			species Warehouse aspect: base_condition;
			species FinalConsignee aspect: base;
			species Provider aspect: base;
			grid cell_stock_shortage;
			species Vehicle aspect: base;
		}

		display 'Traffic' autosave: true refresh:every(1) {
			species Country aspect: geom;
			species Road aspect: geom;
			species MaritimeLine aspect: geom;
			species SecondaryMaritimeLine aspect: geom;
			species RiverLine aspect: geom;
			event [mouse_down] action: block_one_road;
		}

		display 'Road traffic' autosave: true refresh:every(1) {
			species Country aspect: geom;
			species Road aspect: geom;
			event [mouse_down] action: block_one_road;
		}

		display 'Maritime and River traffic' autosave: true refresh:every(1) {
			species Country aspect: geom;
			species MaritimeLine aspect: geom;
			species RiverLine aspect: geom;
			species SecondaryMaritimeLine aspect: geom;
			species SecondaryTerminal aspect:geom;
			species RiverTerminal aspect:geom;
			species MaritimeRiverTerminal aspect:geom;
			event [mouse_down] action: block_one_road;
		}

		display 'Stocks in final destination' refresh:every(1) {
			chart  "Stock quantity in final destinations" type: series {
				data "Total stock quantity in final destinations" value: stockInFinalDest color: divergingCol2 ;
				data "Total free surface in final destinations" value: freeSurfaceInFinalDest color: divergingCol4 ;
			}
		}/**/

		display 'Stocks in warehouses' refresh:every(1) {
			chart  "Stock quantity in warehouses" type: series {
				data "Total stock quantity in warehouses" value: stockInWarehouse color: divergingCol2 ;
				data "Total free surface in warehouses" value: freeSurfaceInWarehouse color: divergingCol4 ;
			}
		}/**/

		display 'Empty stocks in final destination' refresh:every(1) {
			chart  "Number of empty stock in final destinations" type: series {
				data "Number of empty stock in final destinations" value: numberofEmptyStockInFinalDests color: divergingCol2 ;
			}
		}/**/

		display 'Empty stocks in warehouses' refresh:every(1) {
			chart  "Number of empty stock in warehouses" type: series {
				data "Number of empty stock in warehouses" value: numberOfEmptyStockInWarehouses color: divergingCol2 ;
			}
		}/**/

		display 'Average time to deliver goods somewhere' refresh:every(1) {
			chart  "Average time that the LPs took to deliver goods somewhere" type: series {
				data "Average time that the LPs took to deliver goods somewhere" value: averageTimeToDeliver color: divergingCol2 ;
			}
		}/**/

		display 'Average time to deliver goods to final destinations' refresh:every(1) {
			chart  "Average time that the LPs took to deliver goods to FDMs" type: series {
				data "Average time that the LPs took to deliver goods to FDMs" value: averageTimeToBeDelivered color: divergingCol2 ;
			}
		}/**/

		display 'Average transportation and warehousing costs' refresh:every(1) {
			chart  "Average transportation and warehousing costs" type: series {
				data "Average transportation and warehousing costs" value: averageCosts color: divergingCol2 ;
			}
		}/**/

		display 'Share of mode of transport (number of vehicles)' refresh:every(1) {
			chart  "Share of mode of transport (number of vehicles)" type: series {
				data "Share of road" value: shareRoadVehicle color: divergingCol5 ;
				data "Share of river" value: shareRiverVehicle color: divergingCol6 ;
				data "Share of maritime" value: shareMaritimeVehicle color: divergingCol7 ;
				data "Share of secondary maritime" value: shareSecondaryVehicle color: divergingCol8 ;
			}
		}/**/

		display 'Share of mode of transport (number of vehicles) - Region Basse-Normandie' refresh:every(1) {
			chart  "Share of mode of transport (number of vehicles) - Region Basse-Normandie" type: series {
				RegionObserver sr <- nil;
				ask RegionObserver {
					if(self.name = "Basse-Normandie"){
						sr <- self;
					}
				}
				if(sr!=nil){
					data "Share of road" value: sr.shareRoadVehicleRO * 100.0 color: divergingCol5 ;
					data "Share of river" value: sr.shareRiverVehicleRO * 100.0 color: divergingCol6 ;
					data "Share of maritime" value: sr.shareMaritimeVehicleRO * 100.0 color: divergingCol7 ;
					data "Share of secondary maritime" value: sr.shareSecondaryVehicleRO * 100.0 color: divergingCol8 ;
				}
				else { // At step 0, RegionObserver are not initialized, so, sr = nil
					data "Share of road" value: 0 color: divergingCol5 ;
					data "Share of river" value: 0 color: divergingCol6 ;
					data "Share of maritime" value: 0 color: divergingCol7 ;
					data "Share of secondary maritime" value: 0 color: divergingCol8 ;
				}
			}
		}/**/

		display 'Share of mode of transport (number of vehicles) - Region Centre' refresh:every(1) {
			chart  "Share of mode of transport (number of vehicles) - Region Centre" type: series {
				RegionObserver sr <- nil;
				ask RegionObserver {
					if(self.name = "Centre"){
						sr <- self;
					}
				}
				if(sr!=nil){
					data "Share of road" value: sr.shareRoadVehicleRO * 100.0 color: divergingCol5 ;
					data "Share of river" value: sr.shareRiverVehicleRO * 100.0 color: divergingCol6 ;
					data "Share of maritime" value: sr.shareMaritimeVehicleRO * 100.0 color: divergingCol7 ;
					data "Share of secondary maritime" value: sr.shareSecondaryVehicleRO * 100.0 color: divergingCol8 ;
				}
				else { // At step 0, RegionObserver are not initialized, so, sr = nil
					data "Share of road" value: 0 color: divergingCol5 ;
					data "Share of river" value: 0 color: divergingCol6 ;
					data "Share of maritime" value: 0 color: divergingCol7 ;
					data "Share of secondary maritime" value: 0 color: divergingCol8 ;
				}
			}
		}/**/

		display 'Share of mode of transport (number of vehicles) - Region Haute-Normandie' refresh:every(1) {
			chart  "Share of mode of transport (number of vehicles) - Region Haute-Normandie" type: series {
				RegionObserver sr <- nil;
				ask RegionObserver {
					if(self.name = "Haute-Normandie"){
						sr <- self;
					}
				}
				if(sr!=nil){
					data "Share of road" value: sr.shareRoadVehicleRO * 100.0 color: divergingCol5 ;
					data "Share of river" value: sr.shareRiverVehicleRO * 100.0 color: divergingCol6 ;
					data "Share of maritime" value: sr.shareMaritimeVehicleRO * 100.0 color: divergingCol7 ;
					data "Share of secondary maritime" value: sr.shareSecondaryVehicleRO * 100.0 color: divergingCol8 ;
				}
				else { // At step 0, RegionObserver are not initialized, so, sr = nil
					data "Share of road" value: 0 color: divergingCol5 ;
					data "Share of river" value: 0 color: divergingCol6 ;
					data "Share of maritime" value: 0 color: divergingCol7 ;
					data "Share of secondary maritime" value: 0 color: divergingCol8 ;
				}
			}
		}/**/

		display 'Share of mode of transport (number of vehicles) - Region Ile-de-France' refresh:every(1) {
			chart  "Share of mode of transport (number of vehicles) - Region Ile-de-France" type: series {
				RegionObserver sr <- nil;
				ask RegionObserver {
					if(self.name = "Ile-de-France"){
						sr <- self;
					}
				}
				if(sr!=nil){
					data "Share of road" value: sr.shareRoadVehicleRO * 100.0 color: divergingCol5 ;
					data "Share of river" value: sr.shareRiverVehicleRO * 100.0 color: divergingCol6 ;
					data "Share of maritime" value: sr.shareMaritimeVehicleRO * 100.0 color: divergingCol7 ;
					data "Share of secondary maritime" value: sr.shareSecondaryVehicleRO * 100.0 color: divergingCol8 ;
				}
				else { // At step 0, RegionObserver are not initialized, so, sr = nil
					data "Share of road" value: 0 color: divergingCol5 ;
					data "Share of river" value: 0 color: divergingCol6 ;
					data "Share of maritime" value: 0 color: divergingCol7 ;
					data "Share of secondary maritime" value: 0 color: divergingCol8 ;
				}
			}
		}/**/

		display 'Share of mode of transport (number of vehicles) - Region Picardie' refresh:every(1) {
			chart  "Share of mode of transport (number of vehicles) - Region Picardie" type: series {
				RegionObserver sr <- nil;
				ask RegionObserver {
					if(self.name = "Picardie"){
						sr <- self;
					}
				}
				if(sr!=nil){
					data "Share of road" value: sr.shareRoadVehicleRO * 100.0 color: divergingCol5 ;
					data "Share of river" value: sr.shareRiverVehicleRO * 100.0 color: divergingCol6 ;
					data "Share of maritime" value: sr.shareMaritimeVehicleRO * 100.0 color: divergingCol7 ;
					data "Share of secondary maritime" value: sr.shareSecondaryVehicleRO * 100.0 color: divergingCol8 ;
				}
				else { // At step 0, RegionObserver are not initialized, so, sr = nil
					data "Share of road" value: 0 color: divergingCol5 ;
					data "Share of river" value: 0 color: divergingCol6 ;
					data "Share of maritime" value: 0 color: divergingCol7 ;
					data "Share of secondary maritime" value: 0 color: divergingCol8 ;
				}
			}
		}/**/

		display 'Share of mode of transport (number of vehicles) - Region Antwerp' refresh:every(1) {
			chart  "Share of mode of transport (number of vehicles) - Region Antwerp" type: series {
				RegionObserver sr <- nil;
				ask RegionObserver {
					if(self.name = "Antwerpen"){
						sr <- self;
					}
				}
				if(sr!=nil){
					data "Share of road" value: sr.shareRoadVehicleRO * 100.0 color: divergingCol5 ;
					data "Share of river" value: sr.shareRiverVehicleRO * 100.0 color: divergingCol6 ;
					data "Share of maritime" value: sr.shareMaritimeVehicleRO * 100.0 color: divergingCol7 ;
					data "Share of secondary maritime" value: sr.shareSecondaryVehicleRO * 100.0 color: divergingCol8 ;
				}
				else { // At step 0, RegionObserver are not initialized, so, sr = nil
					data "Share of road" value: 0 color: divergingCol5 ;
					data "Share of river" value: 0 color: divergingCol6 ;
					data "Share of maritime" value: 0 color: divergingCol7 ;
					data "Share of secondary maritime" value: 0 color: divergingCol8 ;
				}
			}
		}/**/

		display 'Share of mode of transport (number of vehicles) - Region Le Havre' refresh:every(1) {
			chart  "Share of mode of transport (number of vehicles) - Region Le Havre" type: series {
				RegionObserver sr <- nil;
				ask RegionObserver {
					if(self.name = "Le Havre"){
						sr <- self;
					}
				}
				if(sr!=nil){
					data "Share of road" value: sr.shareRoadVehicleRO * 100.0 color: divergingCol5 ;
					data "Share of river" value: sr.shareRiverVehicleRO * 100.0 color: divergingCol6 ;
					data "Share of maritime" value: sr.shareMaritimeVehicleRO * 100.0 color: divergingCol7 ;
					data "Share of secondary maritime" value: sr.shareSecondaryVehicleRO * 100.0 color: divergingCol8 ;
				}
				else { // At step 0, RegionObserver are not initialized, so, sr = nil
					data "Share of road" value: 0 color: divergingCol5 ;
					data "Share of river" value: 0 color: divergingCol6 ;
					data "Share of maritime" value: 0 color: divergingCol7 ;
					data "Share of secondary maritime" value: 0 color: divergingCol8 ;
				}
			}
		}/**/

		display 'Share of mode of transport (quantities of goods)' refresh:every(1) {
			chart  "Share of mode of transport (quantities of goods)" type: series {
				data "Share of road" value: shareRoadQuantities * 100 color: divergingCol5 ;
				data "Share of river" value: shareRiverQuantities * 100 color: divergingCol6 ;
				data "Share of maritime" value: shareMaritimeQuantities * 100 color: divergingCol7 ;
				data "Share of secondary maritime" value: shareSecondaryQuantities * 100 color: divergingCol8 ;
			}
		}/**/

		display 'Share of mode of transport (quantities of goods) - Region Basse-Normandie' refresh:every(1) {
			chart  "Share of mode of transport (quantities of goods) - Region Basse-Normandie" type: series {
				RegionObserver sr <- nil;
				ask RegionObserver {
					if(self.name = "Basse-Normandie"){
						sr <- self;
					}
				}
				if(sr!=nil){
					data "Share of road" value: sr.shareRoadQuantitiesRO * 100.0 color: divergingCol5 ;
					data "Share of river" value: sr.shareRiverQuantitiesRO * 100.0 color: divergingCol6 ;
					data "Share of maritime" value: sr.shareMaritimeQuantitiesRO * 100.0 color: divergingCol7 ;
					data "Share of secondary maritime" value: sr.shareSecondaryQuantitiesRO * 100.0 color: divergingCol8 ;
				}
				else { // At step 0, RegionObserver are not initialized, so, sr = nil
					data "Share of road" value: 0 color: divergingCol5 ;
					data "Share of river" value: 0 color: divergingCol6 ;
					data "Share of maritime" value: 0 color: divergingCol7 ;
					data "Share of secondary maritime" value: 0 color: divergingCol8 ;
				}
			}
		}/**/

		display 'Share of mode of transport (quantities of goods) - Region Centre' refresh:every(1) {
			chart  "Share of mode of transport - Region Centre" type: series {
				RegionObserver sr <- nil;
				ask RegionObserver {
					if(self.name = "Centre"){
						sr <- self;
					}
				}
				if(sr!=nil){
					data "Share of road" value: sr.shareRoadQuantitiesRO * 100.0 color: divergingCol5 ;
					data "Share of river" value: sr.shareRiverQuantitiesRO * 100.0 color: divergingCol6 ;
					data "Share of maritime" value: sr.shareMaritimeQuantitiesRO * 100.0 color: divergingCol7 ;
					data "Share of secondary maritime" value: sr.shareSecondaryQuantitiesRO * 100.0 color: divergingCol8 ;
				}
				else { // At step 0, RegionObserver are not initialized, so, sr = nil
					data "Share of road" value: 0 color: divergingCol5 ;
					data "Share of river" value: 0 color: divergingCol6 ;
					data "Share of maritime" value: 0 color: divergingCol7 ;
					data "Share of secondary maritime" value: 0 color: divergingCol8 ;
				}
			}
		}/**/

		display 'Share of mode of transport (quantities of goods) - Region Haute-Normandie' refresh:every(1) {
			chart  "Share of mode of transport - Region Haute-Normandie" type: series {
				RegionObserver sr <- nil;
				ask RegionObserver {
					if(self.name = "Haute-Normandie"){
						sr <- self;
					}
				}
				if(sr!=nil){
					data "Share of road" value: sr.shareRoadQuantitiesRO * 100.0 color: divergingCol5 ;
					data "Share of river" value: sr.shareRiverQuantitiesRO * 100.0 color: divergingCol6 ;
					data "Share of maritime" value: sr.shareMaritimeQuantitiesRO * 100.0 color: divergingCol7 ;
					data "Share of secondary maritime" value: sr.shareSecondaryQuantitiesRO * 100.0 color: divergingCol8 ;
				}
				else { // At step 0, RegionObserver are not initialized, so, sr = nil
					data "Share of road" value: 0 color: divergingCol5 ;
					data "Share of river" value: 0 color: divergingCol6 ;
					data "Share of maritime" value: 0 color: divergingCol7 ;
					data "Share of secondary maritime" value: 0 color: divergingCol8 ;
				}
			}
		}/**/

		display 'Share of mode of transport (quantities of goods) - Region Ile-de-France' refresh:every(1) {
			chart  "Share of mode of transport - Region Ile-de-France" type: series {
				RegionObserver sr <- nil;
				ask RegionObserver {
					if(self.name = "Ile-de-France"){
						sr <- self;
					}
				}
				if(sr!=nil){
					data "Share of road" value: sr.shareRoadQuantitiesRO * 100.0 color: divergingCol5 ;
					data "Share of river" value: sr.shareRiverQuantitiesRO * 100.0 color: divergingCol6 ;
					data "Share of maritime" value: sr.shareMaritimeQuantitiesRO * 100.0 color: divergingCol7 ;
					data "Share of secondary maritime" value: sr.shareSecondaryQuantitiesRO * 100.0 color: divergingCol8 ;
				}
				else { // At step 0, RegionObserver are not initialized, so, sr = nil
					data "Share of road" value: 0 color: divergingCol5 ;
					data "Share of river" value: 0 color: divergingCol6 ;
					data "Share of maritime" value: 0 color: divergingCol7 ;
					data "Share of secondary maritime" value: 0 color: divergingCol8 ;
				}
			}
		}/**/

		display 'Share of mode of transport (quantities of goods) - Region Picardie' refresh:every(1) {
			chart  "Share of mode of transport - Region Picardie" type: series {
				RegionObserver sr <- nil;
				ask RegionObserver {
					if(self.name = "Picardie"){
						sr <- self;
					}
				}
				if(sr!=nil){
					data "Share of road" value: sr.shareRoadQuantitiesRO * 100.0 color: divergingCol5 ;
					data "Share of river" value: sr.shareRiverQuantitiesRO * 100.0 color: divergingCol6 ;
					data "Share of maritime" value: sr.shareMaritimeQuantitiesRO * 100.0 color: divergingCol7 ;
					data "Share of secondary maritime" value: sr.shareSecondaryQuantitiesRO * 100.0 color: divergingCol8 ;
				}
				else { // At step 0, RegionObserver are not initialized, so, sr = nil
					data "Share of road" value: 0 color: divergingCol5 ;
					data "Share of river" value: 0 color: divergingCol6 ;
					data "Share of maritime" value: 0 color: divergingCol7 ;
					data "Share of secondary maritime" value: 0 color: divergingCol8 ;
				}
			}
		}/**/

		display 'Share of mode of transport (quantities of goods) - Region Antwerp' refresh:every(1) {
			chart  "Share of mode of transport - Region Antwerp" type: series {
				RegionObserver sr <- nil;
				ask RegionObserver {
					if(self.name = "Antwerpen"){
						sr <- self;
					}
				}
				if(sr!=nil){
					data "Share of road" value: sr.shareRoadQuantitiesRO * 100.0 color: divergingCol5 ;
					data "Share of river" value: sr.shareRiverQuantitiesRO * 100.0 color: divergingCol6 ;
					data "Share of maritime" value: sr.shareMaritimeQuantitiesRO * 100.0 color: divergingCol7 ;
					data "Share of secondary maritime" value: sr.shareSecondaryQuantitiesRO * 100.0 color: divergingCol8 ;
				}
				else { // At step 0, RegionObserver are not initialized, so, sr = nil
					data "Share of road" value: 0 color: divergingCol5 ;
					data "Share of river" value: 0 color: divergingCol6 ;
					data "Share of maritime" value: 0 color: divergingCol7 ;
					data "Share of secondary maritime" value: 0 color: divergingCol8 ;
				}
			}
		}/**/

		display 'Share of mode of transport (quantities of goods) - Region Le Havre' refresh:every(1) {
			chart  "Share of mode of transport - Region Le Havre" type: series {
				RegionObserver sr <- nil;
				ask RegionObserver {
					if(self.name = "Le Havre"){
						sr <- self;
					}
				}
				if(sr!=nil){
					data "Share of road" value: sr.shareRoadQuantitiesRO * 100.0 color: divergingCol5 ;
					data "Share of river" value: sr.shareRiverQuantitiesRO * 100.0 color: divergingCol6 ;
					data "Share of maritime" value: sr.shareMaritimeQuantitiesRO * 100.0 color: divergingCol7 ;
					data "Share of secondary maritime" value: sr.shareSecondaryQuantitiesRO * 100.0 color: divergingCol8 ;
				}
				else { // At step 0, RegionObserver are not initialized, so, sr = nil
					data "Share of road" value: 0 color: divergingCol5 ;
					data "Share of river" value: 0 color: divergingCol6 ;
					data "Share of maritime" value: 0 color: divergingCol7 ;
					data "Share of secondary maritime" value: 0 color: divergingCol8 ;
				}
			}
		}/**/

		display 'Share of port origin - Region Basse-Normandie' refresh:every(1) {
			chart  "Share of port origin - Region Basse-Normandie" type: series {
				RegionObserver sr <- nil;
				ask RegionObserver {
					if(self.name = "Basse-Normandie"){
						sr <- self;
					}
				}
				if(sr!=nil){
					data "Number of FC choosing Antwerp" value: sr.nbAntwerp color: divergingCol2 ;
					data "Number of FC choosing Le Havre" value: sr.nbHavre color: divergingCol4 ;
				}
				else { // At step 0, RegionObserver are not initialized, so, sr = nil
					data "Number of FC choosing Antwerp" value: 0 color: divergingCol2 ;
					data "Number of FC choosing Le Havre" value: 0 color: divergingCol4 ;
				}
			}
		}/**/

		display 'Share of port origin - Region Centre' refresh:every(1) {
			chart  "Share of port origin - Region Centre" type: series {
				RegionObserver sr <- nil;
				ask RegionObserver {
					if(self.name = "Centre"){
						sr <- self;
					}
				}
				if(sr!=nil){
					data "Number of FC choosing Antwerp" value: sr.nbAntwerp color: divergingCol2 ;
					data "Number of FC choosing Le Havre" value: sr.nbHavre color: divergingCol4 ;
				}
				else { // At step 0, RegionObserver are not initialized, so, sr = nil
					data "Number of FC choosing Antwerp" value: 0 color: divergingCol2 ;
					data "Number of FC choosing Le Havre" value: 0 color: divergingCol4 ;
				}
			}
		}/**/

		display 'Share of port origin - Region Haute-Normandie' refresh:every(1) {
			chart  "Share of port origin - Region Haute-Normandie" type: series {
				RegionObserver sr <- nil;
				ask RegionObserver {
					if(self.name = "Haute-Normandie"){
						sr <- self;
					}
				}
				if(sr!=nil){
					data "Number of FC choosing Antwerp" value: sr.nbAntwerp color: divergingCol2 ;
					data "Number of FC choosing Le Havre" value: sr.nbHavre color: divergingCol4 ;
				}
				else { // At step 0, RegionObserver are not initialized, so, sr = nil
					data "Number of FC choosing Antwerp" value: 0 color: divergingCol2 ;
					data "Number of FC choosing Le Havre" value: 0 color: divergingCol4 ;
				}
			}
		}/**/

		display 'Share of port origin - Region Ile-de-France' refresh:every(1) {
			chart  "Share of port origin - Region Ile-de-France" type: series {
				RegionObserver sr <- nil;
				ask RegionObserver {
					if(self.name = "Ile-de-France"){
						sr <- self;
					}
				}
				if(sr!=nil){
					data "Number of FC choosing Antwerp" value: sr.nbAntwerp color: divergingCol2 ;
					data "Number of FC choosing Le Havre" value: sr.nbHavre color: divergingCol4 ;
				}
				else { // At step 0, RegionObserver are not initialized, so, sr = nil
					data "Number of FC choosing Antwerp" value: 0 color: divergingCol2 ;
					data "Number of FC choosing Le Havre" value: 0 color: divergingCol4 ;
				}
			}
		}/**/

		display 'Share of port origin - Region Picardie' refresh:every(1) {
			chart  "Share of port origin - Region Picardie" type: series {
				RegionObserver sr <- nil;
				ask RegionObserver {
					if(self.name = "Picardie"){
						sr <- self;
					}
				}
				if(sr!=nil){
					data "Number of FC choosing Antwerp" value: sr.nbAntwerp color: divergingCol2 ;
					data "Number of FC choosing Le Havre" value: sr.nbHavre color: divergingCol4 ;
				}
				else { // At step 0, RegionObserver are not initialized, so, sr = nil
					data "Number of FC choosing Antwerp" value: 0 color: divergingCol2 ;
					data "Number of FC choosing Le Havre" value: 0 color: divergingCol4 ;
				}
			}
		}/**/

		display 'Share of port origin - Region Antwerp' refresh:every(1) {
			chart  "Share of port origin - Region Antwerp" type: series {
				RegionObserver sr <- nil;
				ask RegionObserver {
					if(self.name = "Antwerpen"){
						sr <- self;
					}
				}
				if(sr!=nil){
					data "Number of FC choosing Antwerp" value: sr.nbAntwerp color: divergingCol2 ;
					data "Number of FC choosing Le Havre" value: sr.nbHavre color: divergingCol4 ;
				}
				else { // At step 0, RegionObserver are not initialized, so, sr = nil
					data "Number of FC choosing Antwerp" value: 0 color: divergingCol2 ;
					data "Number of FC choosing Le Havre" value: 0 color: divergingCol4 ;
				}
			}
		}/**/

		display 'Share of port origin - Region Le Havre' refresh:every(1) {
			chart  "Share of port origin - Region Le Havre" type: series {
				RegionObserver sr <- nil;
				ask RegionObserver {
					if(self.name = "Le Havre"){
						sr <- self;
					}
				}
				if(sr!=nil){
					data "Number of FC choosing Antwerp" value: sr.nbAntwerp color: divergingCol2 ;
					data "Number of FC choosing Le Havre" value: sr.nbHavre color: divergingCol4 ;
				}
				else { // At step 0, RegionObserver are not initialized, so, sr = nil
					data "Number of FC choosing Antwerp" value: 0 color: divergingCol2 ;
					data "Number of FC choosing Le Havre" value: 0 color: divergingCol4 ;
				}
			}
		}/**/

		display 'Share of the different strategies adopted' refresh:every(1) {
			chart  "Share of the different strategies adopted" type: series {
				data "Strategy 1 (closest/largest warehouse according to a probability)" value: nbLPStrat1 color: divergingCol1 ;
				data "Strategy 2 (closest/largest warehouse according to its accessibility)" value: nbLPStrat2 color: divergingCol2 ;
				data "Strategy 3 (closest/largest warehouse)" value: nbLPStrat3 color: divergingCol3 ;
				data "Strategy 4 (pure random)" value: nbLPStrat4 color: divergingCol4 ;
			}
		}/**/

		display 'Share of the different strategies adopted (smoothed)' refresh:every(1) {
			chart  "Share of the different strategies adopted" type: series {
				data "Strategy 1 (closest/largest warehouse according to a probability)" value: averageStrat1 color: divergingCol1 ;
				data "Strategy 2 (closest/largest warehouse according to its accessibility)" value: averageStrat2 color: divergingCol2 ;
				data "Strategy 3 (closest/largest warehouse)" value: averageStrat3 color: divergingCol3 ;
				data "Strategy 4 (pure random)" value: averageStrat4 color: divergingCol4 ;
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
				data "Average threshold (in percentage)" value: averageThreshold*100 color: divergingCol4 ;
			}
		}/**/

		display 'Stocks awating to leave providers and warehouses' refresh:every(1) {
			chart "Blocking level to make goods leave buildings" type: series {
				data "Number of stocks awaiting to leave warehouses" value: nbStocksAwaitingToLeaveWarehouse color: divergingCol2 ;
				data "Number of stocks awaiting to leave providers" value: nbStocksAwaitingToLeaveProvider color: divergingCol4 ;
			}
		}/**/

		display "Stocks awating to enter warehouses or final destination's building" refresh:every(1) {
			chart "Blocking level to make goods enter buildings" type: series {
				data "Number of stocks awaiting to enter buildings" value: nbStocksAwaitingToEnterBuilding color: divergingCol2 ;
				data "Number of stocks awaiting to enter warehouses" value: nbStocksAwaitingToEnterWarehouse color: divergingCol4 ;
			}
		}/**/

		display 'Average costs' refresh:every(1) {
			chart "Average Costs" type: series {
				data "average costs" value: averageCosts color: divergingCol2 ;
			}
		}/**/

		display 'Competition between Le Havre and Antwerp' refresh:every(1) {
			chart "Competition between the ports of Le Havre and Antwerp" type: series {
				data "Number of LP using Le Havre" value: nbHavre color: divergingCol2 ;
				data "Number of LP using Antwerp" value: nbAntwerp color: divergingCol4 ;
			}
		}/**/

		display "Distribution of number of FC per LSP" type: java2D synchronized: true {
			chart "Distribution of number of FC per LSP"
				type: histogram
				x_label: 'Nb of FC'
				y_label: 'Nb of LSP'
				x_serie_labels: distributionNbFCPerLSPX
			{
				datalist distributionNbFCPerLSPX value: distributionNbFCPerLSPY;
			}
		}/**/

		display 'Traffic evolution on the Canal Seine Nord' refresh:every(1) {
			chart "Traffic evolution on the Canal Seine Nord" type: series {
				data "Traffic evolution on the Canal Seine Nord" value: trafficValueCSN color: divergingCol2 ;
			}
		}/**/

		display 'Share of vehicles leaving terminals per mode of transport - Region Basse-Normandie' refresh:every(1) {
			chart  "Share of vehicles leaving terminals per mode of transport - Region Basse-Normandie" type: series {
				RegionObserver sr <- nil;
				ask RegionObserver {
					if(self.name = "Basse-Normandie"){
						sr <- self;
					}
				}
				if(sr!=nil){
					data "Share of road" value: sr.shareLeavingRoadVehicleRO * 100.0 color: divergingCol5 ;
					data "Share of river" value: sr.shareLeavingRiverVehicleRO * 100.0 color: divergingCol6 ;
					data "Share of maritime" value: sr.shareLeavingMaritimeVehicleRO * 100.0 color: divergingCol7 ;
					data "Share of secondary maritime" value: sr.shareLeavingSecondaryVehicleRO * 100.0 color: divergingCol8 ;
				}
				else { // At step 0, RegionObserver are not initialized, so, sr = nil
					data "Share of road" value: 0 color: divergingCol5 ;
					data "Share of river" value: 0 color: divergingCol6 ;
					data "Share of maritime" value: 0 color: divergingCol7 ;
					data "Share of secondary maritime" value: 0 color: divergingCol8 ;
				}
			}
		}/**/

		display 'Share of vehicles leaving terminals per mode of transport - Region Centre' refresh:every(1) {
			chart  "Share of vehicles leaving terminals per mode of transport - Region Centre" type: series {
				RegionObserver sr <- nil;
				ask RegionObserver {
					if(self.name = "Centre"){
						sr <- self;
					}
				}
				if(sr!=nil){
					data "Share of road" value: sr.shareLeavingRoadVehicleRO * 100.0 color: divergingCol5 ;
					data "Share of river" value: sr.shareLeavingRiverVehicleRO * 100.0 color: divergingCol6 ;
					data "Share of maritime" value: sr.shareLeavingMaritimeVehicleRO * 100.0 color: divergingCol7 ;
					data "Share of secondary maritime" value: sr.shareLeavingSecondaryVehicleRO * 100.0 color: divergingCol8 ;
				}
				else { // At step 0, RegionObserver are not initialized, so, sr = nil
					data "Share of road" value: 0 color: divergingCol5 ;
					data "Share of river" value: 0 color: divergingCol6 ;
					data "Share of maritime" value: 0 color: divergingCol7 ;
					data "Share of secondary maritime" value: 0 color: divergingCol8 ;
				}
			}
		}/**/

		display 'Share of vehicles leaving terminals per mode of transport - Region Haute-Normandie' refresh:every(1) {
			chart  "Share of vehicles leaving terminals per mode of transport - Region Haute-Normandie" type: series {
				RegionObserver sr <- nil;
				ask RegionObserver {
					if(self.name = "Haute-Normandie"){
						sr <- self;
					}
				}
				if(sr!=nil){
					data "Share of road" value: sr.shareLeavingRoadVehicleRO * 100.0 color: divergingCol5 ;
					data "Share of river" value: sr.shareLeavingRiverVehicleRO * 100.0 color: divergingCol6 ;
					data "Share of maritime" value: sr.shareLeavingMaritimeVehicleRO * 100.0 color: divergingCol7 ;
					data "Share of secondary maritime" value: sr.shareLeavingSecondaryVehicleRO * 100.0 color: divergingCol8 ;
				}
				else { // At step 0, RegionObserver are not initialized, so, sr = nil
					data "Share of road" value: 0 color: divergingCol5 ;
					data "Share of river" value: 0 color: divergingCol6 ;
					data "Share of maritime" value: 0 color: divergingCol7 ;
					data "Share of secondary maritime" value: 0 color: divergingCol8 ;
				}
			}
		}/**/

		display 'Share of vehicles leaving terminals per mode of transport - Region Ile-de-France' refresh:every(1) {
			chart  "Share of vehicles leaving terminals per mode of transport - Region Ile-de-France" type: series {
				RegionObserver sr <- nil;
				ask RegionObserver {
					if(self.name = "Ile-de-France"){
						sr <- self;
					}
				}
				if(sr!=nil){
					data "Share of road" value: sr.shareLeavingRoadVehicleRO * 100.0 color: divergingCol5 ;
					data "Share of river" value: sr.shareLeavingRiverVehicleRO * 100.0 color: divergingCol6 ;
					data "Share of maritime" value: sr.shareLeavingMaritimeVehicleRO * 100.0 color: divergingCol7 ;
					data "Share of secondary maritime" value: sr.shareLeavingSecondaryVehicleRO * 100.0 color: divergingCol8 ;
				}
				else { // At step 0, RegionObserver are not initialized, so, sr = nil
					data "Share of road" value: 0 color: divergingCol5 ;
					data "Share of river" value: 0 color: divergingCol6 ;
					data "Share of maritime" value: 0 color: divergingCol7 ;
					data "Share of secondary maritime" value: 0 color: divergingCol8 ;
				}
			}
		}/**/

		display 'Share of vehicles leaving terminals per mode of transport - Region Picardie' refresh:every(1) {
			chart  "Share of vehicles leaving terminals per mode of transport - Region Picardie" type: series {
				RegionObserver sr <- nil;
				ask RegionObserver {
					if(self.name = "Picardie"){
						sr <- self;
					}
				}
				if(sr!=nil){
					data "Share of road" value: sr.shareLeavingRoadVehicleRO * 100.0 color: divergingCol5 ;
					data "Share of river" value: sr.shareLeavingRiverVehicleRO * 100.0 color: divergingCol6 ;
					data "Share of maritime" value: sr.shareLeavingMaritimeVehicleRO * 100.0 color: divergingCol7 ;
					data "Share of secondary maritime" value: sr.shareLeavingSecondaryVehicleRO * 100.0 color: divergingCol8 ;
				}
				else { // At step 0, RegionObserver are not initialized, so, sr = nil
					data "Share of road" value: 0 color: divergingCol5 ;
					data "Share of river" value: 0 color: divergingCol6 ;
					data "Share of maritime" value: 0 color: divergingCol7 ;
					data "Share of secondary maritime" value: 0 color: divergingCol8 ;
				}
			}
		}/**/

		display 'Share of vehicles leaving terminals per mode of transport - Region Antwerp' refresh:every(1) {
			chart  "Share of vehicles leaving terminals per mode of transport - Region Antwerp" type: series {
				RegionObserver sr <- nil;
				ask RegionObserver {
					if(self.name = "Antwerpen"){
						sr <- self;
					}
				}
				if(sr!=nil){
					data "Share of road" value: sr.shareLeavingRoadVehicleRO * 100.0 color: divergingCol5 ;
					data "Share of river" value: sr.shareLeavingRiverVehicleRO * 100.0 color: divergingCol6 ;
					data "Share of maritime" value: sr.shareLeavingMaritimeVehicleRO * 100.0 color: divergingCol7 ;
					data "Share of secondary maritime" value: sr.shareLeavingSecondaryVehicleRO * 100.0 color: divergingCol8 ;
				}
				else { // At step 0, RegionObserver are not initialized, so, sr = nil
					data "Share of road" value: 0 color: divergingCol5 ;
					data "Share of river" value: 0 color: divergingCol6 ;
					data "Share of maritime" value: 0 color: divergingCol7 ;
					data "Share of secondary maritime" value: 0 color: divergingCol8 ;
				}
			}
		}/**/

		display 'Share of vehicles leaving terminals per mode of transport - Region Le Havre' refresh:every(1) {
			chart  "Share of vehicles leaving terminals per mode of transport - Region Le Havre" type: series {
				RegionObserver sr <- nil;
				ask RegionObserver {
					if(self.name = "Le Havre"){
						sr <- self;
					}
				}
				if(sr!=nil){
					data "Share of road" value: sr.shareLeavingRoadVehicleRO * 100.0 color: divergingCol5 ;
					data "Share of river" value: sr.shareLeavingRiverVehicleRO * 100.0 color: divergingCol6 ;
					data "Share of maritime" value: sr.shareLeavingMaritimeVehicleRO * 100.0 color: divergingCol7 ;
					data "Share of secondary maritime" value: sr.shareLeavingSecondaryVehicleRO * 100.0 color: divergingCol8 ;
				}
				else { // At step 0, RegionObserver are not initialized, so, sr = nil
					data "Share of road" value: 0 color: divergingCol5 ;
					data "Share of river" value: 0 color: divergingCol6 ;
					data "Share of maritime" value: 0 color: divergingCol7 ;
					data "Share of secondary maritime" value: 0 color: divergingCol8 ;
				}
			}
		}/**/

		display 'Share of volume leaving terminals per mode of transport - Region Basse-Normandie' refresh:every(1) {
			chart  "Share of volume leaving terminals per mode of transport - Region Basse-Normandie" type: series {
				RegionObserver sr <- nil;
				ask RegionObserver {
					if(self.name = "Basse-Normandie"){
						sr <- self;
					}
				}
				if(sr!=nil){
					data "Share of road" value: sr.shareLeavingRoadQuantitiesRO * 100.0 color: divergingCol5 ;
					data "Share of river" value: sr.shareLeavingRiverQuantitiesRO * 100.0 color: divergingCol6 ;
					data "Share of maritime" value: sr.shareLeavingMaritimeQuantitiesRO * 100.0 color: divergingCol7 ;
					data "Share of secondary maritime" value: sr.shareLeavingSecondaryQuantitiesRO * 100.0 color: divergingCol8 ;
				}
				else { // At step 0, RegionObserver are not initialized, so, sr = nil
					data "Share of road" value: 0 color: divergingCol5 ;
					data "Share of river" value: 0 color: divergingCol6 ;
					data "Share of maritime" value: 0 color: divergingCol7 ;
					data "Share of secondary maritime" value: 0 color: divergingCol8 ;
				}
			}
		}/**/

		display 'Share of volume leaving terminals per mode of transport - Region Centre' refresh:every(1) {
			chart  "Share of volume leaving terminals per mode of transport - Region Centre" type: series {
				RegionObserver sr <- nil;
				ask RegionObserver {
					if(self.name = "Centre"){
						sr <- self;
					}
				}
				if(sr!=nil){
					data "Share of road" value: sr.shareLeavingRoadQuantitiesRO * 100.0 color: divergingCol5 ;
					data "Share of river" value: sr.shareLeavingRiverQuantitiesRO * 100.0 color: divergingCol6 ;
					data "Share of maritime" value: sr.shareLeavingMaritimeQuantitiesRO * 100.0 color: divergingCol7 ;
					data "Share of secondary maritime" value: sr.shareLeavingSecondaryQuantitiesRO * 100.0 color: divergingCol8 ;
				}
				else { // At step 0, RegionObserver are not initialized, so, sr = nil
					data "Share of road" value: 0 color: divergingCol5 ;
					data "Share of river" value: 0 color: divergingCol6 ;
					data "Share of maritime" value: 0 color: divergingCol7 ;
					data "Share of secondary maritime" value: 0 color: divergingCol8 ;
				}
			}
		}/**/

		display 'Share of volume leaving terminals per mode of transport - Region Haute-Normandie' refresh:every(1) {
			chart  "Share of volume leaving terminals per mode of transport - Region Haute-Normandie" type: series {
				RegionObserver sr <- nil;
				ask RegionObserver {
					if(self.name = "Haute-Normandie"){
						sr <- self;
					}
				}
				if(sr!=nil){
					data "Share of road" value: sr.shareLeavingRoadQuantitiesRO * 100.0 color: divergingCol5 ;
					data "Share of river" value: sr.shareLeavingRiverQuantitiesRO * 100.0 color: divergingCol6 ;
					data "Share of maritime" value: sr.shareLeavingMaritimeQuantitiesRO * 100.0 color: divergingCol7 ;
					data "Share of secondary maritime" value: sr.shareLeavingSecondaryQuantitiesRO * 100.0 color: divergingCol8 ;
				}
				else { // At step 0, RegionObserver are not initialized, so, sr = nil
					data "Share of road" value: 0 color: divergingCol5 ;
					data "Share of river" value: 0 color: divergingCol6 ;
					data "Share of maritime" value: 0 color: divergingCol7 ;
					data "Share of secondary maritime" value: 0 color: divergingCol8 ;
				}
			}
		}/**/

		display 'Share of volume leaving terminals per mode of transport - Region Ile-de-France' refresh:every(1) {
			chart  "Share of volume leaving terminals per mode of transport - Region Ile-de-France" type: series {
				RegionObserver sr <- nil;
				ask RegionObserver {
					if(self.name = "Ile-de-France"){
						sr <- self;
					}
				}
				if(sr!=nil){
					data "Share of road" value: sr.shareLeavingRoadQuantitiesRO * 100.0 color: divergingCol5 ;
					data "Share of river" value: sr.shareLeavingRiverQuantitiesRO * 100.0 color: divergingCol6 ;
					data "Share of maritime" value: sr.shareLeavingMaritimeQuantitiesRO * 100.0 color: divergingCol7 ;
					data "Share of secondary maritime" value: sr.shareLeavingSecondaryQuantitiesRO * 100.0 color: divergingCol8 ;
				}
				else { // At step 0, RegionObserver are not initialized, so, sr = nil
					data "Share of road" value: 0 color: divergingCol5 ;
					data "Share of river" value: 0 color: divergingCol6 ;
					data "Share of maritime" value: 0 color: divergingCol7 ;
					data "Share of secondary maritime" value: 0 color: divergingCol8 ;
				}
			}
		}/**/

		display 'Share of volume leaving terminals per mode of transport - Region Picardie' refresh:every(1) {
			chart  "Share of volume leaving terminals per mode of transport - Region Picardie" type: series {
				RegionObserver sr <- nil;
				ask RegionObserver {
					if(self.name = "Picardie"){
						sr <- self;
					}
				}
				if(sr!=nil){
					data "Share of road" value: sr.shareLeavingRoadQuantitiesRO * 100.0 color: divergingCol5 ;
					data "Share of river" value: sr.shareLeavingRiverQuantitiesRO * 100.0 color: divergingCol6 ;
					data "Share of maritime" value: sr.shareLeavingMaritimeQuantitiesRO * 100.0 color: divergingCol7 ;
					data "Share of secondary maritime" value: sr.shareLeavingSecondaryQuantitiesRO * 100.0 color: divergingCol8 ;
				}
				else { // At step 0, RegionObserver are not initialized, so, sr = nil
					data "Share of road" value: 0 color: divergingCol5 ;
					data "Share of river" value: 0 color: divergingCol6 ;
					data "Share of maritime" value: 0 color: divergingCol7 ;
					data "Share of secondary maritime" value: 0 color: divergingCol8 ;
				}
			}
		}/**/

		display 'Share of volume leaving terminals per mode of transport - Region Antwerp' refresh:every(1) {
			chart  "Share of volume leaving terminals per mode of transport - Region Antwerp" type: series {
				RegionObserver sr <- nil;
				ask RegionObserver {
					if(self.name = "Antwerpen"){
						sr <- self;
					}
				}
				if(sr!=nil){
					data "Share of road" value: sr.shareLeavingRoadQuantitiesRO * 100.0 color: divergingCol5 ;
					data "Share of river" value: sr.shareLeavingRiverQuantitiesRO * 100.0 color: divergingCol6 ;
					data "Share of maritime" value: sr.shareLeavingMaritimeQuantitiesRO * 100.0 color: divergingCol7 ;
					data "Share of secondary maritime" value: sr.shareLeavingSecondaryQuantitiesRO * 100.0 color: divergingCol8 ;
				}
				else { // At step 0, RegionObserver are not initialized, so, sr = nil
					data "Share of road" value: 0 color: divergingCol5 ;
					data "Share of river" value: 0 color: divergingCol6 ;
					data "Share of maritime" value: 0 color: divergingCol7 ;
					data "Share of secondary maritime" value: 0 color: divergingCol8 ;
				}
			}
		}/**/

		display 'Share of volume leaving terminals per mode of transport - Region Le Havre' refresh:every(1) {
			chart  "Share of volume leaving terminals per mode of transport - Region Le Havre" type: series {
				RegionObserver sr <- nil;
				ask RegionObserver {
					if(self.name = "Le Havre"){
						sr <- self;
					}
				}
				if(sr!=nil){
					data "Share of road" value: sr.shareLeavingRoadQuantitiesRO * 100.0 color: divergingCol5 ;
					data "Share of river" value: sr.shareLeavingRiverQuantitiesRO * 100.0 color: divergingCol6 ;
					data "Share of maritime" value: sr.shareLeavingMaritimeQuantitiesRO * 100.0 color: divergingCol7 ;
					data "Share of secondary maritime" value: sr.shareLeavingSecondaryQuantitiesRO * 100.0 color: divergingCol8 ;
				}
				else { // At step 0, RegionObserver are not initialized, so, sr = nil
					data "Share of road" value: 0 color: divergingCol5 ;
					data "Share of river" value: 0 color: divergingCol6 ;
					data "Share of maritime" value: 0 color: divergingCol7 ;
					data "Share of secondary maritime" value: 0 color: divergingCol8 ;
				}
			}
		}/**/

		display 'Volume leaving terminals per mode of transport - Region Antwerp' refresh:every(1) {
			chart  "Volume leaving terminals per mode of transport - Region Antwerp" type: series {
				RegionObserver sr <- nil;
				ask RegionObserver {
					if(self.name = "Antwerpen"){
						sr <- self;
					}
				}
				if(sr!=nil){
					data "Volume on road" value: sr.sumLeavingRoadQuantitiesRO color: divergingCol5 ;
					data "Volume on river" value: sr.sumLeavingRiverQuantitiesRO color: divergingCol6 ;
					data "Volume on maritime" value: sr.sumLeavingMaritimeQuantitiesRO color: divergingCol7 ;
					data "Volume on secondary maritime" value: sr.sumLeavingSecondaryQuantitiesRO color: divergingCol8 ;
				}
				else { // At step 0, RegionObserver are not initialized, so, sr = nil
					data "Share of road" value: 0 color: divergingCol5 ;
					data "Share of river" value: 0 color: divergingCol6 ;
					data "Share of maritime" value: 0 color: divergingCol7 ;
					data "Share of secondary maritime" value: 0 color: divergingCol8 ;
				}
			}
		}/**/

		display 'Volume leaving terminals per mode of transport - Region le Havre' refresh:every(1) {
			chart  "Volume leaving terminals per mode of transport - Region Le Havre" type: series {
				RegionObserver sr <- nil;
				ask RegionObserver {
					if(self.name = "Le Havre"){
						sr <- self;
					}
				}
				if(sr!=nil){
					data "Volume on road" value: sr.sumLeavingRoadQuantitiesRO color: divergingCol5 ;
					data "Volume on river" value: sr.sumLeavingRiverQuantitiesRO color: divergingCol6 ;
					data "Volume on maritime" value: sr.sumLeavingMaritimeQuantitiesRO color: divergingCol7 ;
					data "Volume on secondary maritime" value: sr.sumLeavingSecondaryQuantitiesRO color: divergingCol8 ;
				}
				else { // At step 0, RegionObserver are not initialized, so, sr = nil
					data "Share of road" value: 0 color: divergingCol5 ;
					data "Share of river" value: 0 color: divergingCol6 ;
					data "Share of maritime" value: 0 color: divergingCol7 ;
					data "Share of secondary maritime" value: 0 color: divergingCol8 ;
				}
			}
		}/**/

		display 'Occupation moyenne des véhicles (mode routier)' refresh:every(1) {
			chart  "Occupation moyenne des véhicles (mode routier)" type: series {
				data "Occupation moyenne des véhicles (mode routier)" value: averageRoadVehicleOccupancy color: divergingCol1 ;
			}
		}/**/

		display 'Occupation moyenne des véhicles (mode fluvial)' refresh:every(1) {
			chart  "Occupation moyenne des véhicles (mode fluvial)" type: series {
				data "Occupation moyenne des véhicles (mode fluvial)" value: averageRiverVehicleOccupancy color: divergingCol2 ;
			}
		}/**/

		display 'Occupation moyenne des véhicles (mode maritime)' refresh:every(1) {
			chart  "Occupation moyenne des véhicles (mode maritime)" type: series {
				data "Occupation moyenne des véhicles (mode maritime)" value: averageMaritimeVehicleOccupancy color: divergingCol3 ;
			}
		}/**/

		display 'Occupation moyenne des véhicles (mode secondaire)' refresh:every(1) {
			chart  "Occupation moyenne des véhicles (mode secondaire)" type: series {
				data "Occupation moyenne des véhicles (mode secondaire)" value: averageSecondaryVehicleOccupancy color: divergingCol4 ;
			}
		}/**/
	}
}