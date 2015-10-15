/**
 *  Stock
 *  Author: Thibaut Démare
 *  Description: Total or partial stock of a given product
 */

model Stock

import "./Building.gaml"

species Stock schedules: [] {
	int product;
	float quantity;
	float maxQuantity;
	int status <- 0; // = 0 : a restock has not been asked; = 1 the restock has been asked; = 2 : ?? no idea ?? ; = 3 : a building is processing the order to restock
	FinalDestinationManager fdm;
	LogisticProvider lp;
	int stepWithNoStock <- 0;
	int stepWithStock <- 0;
	Building building;
	
	reflex updateStepWithNoStock {
		if(quantity = 0){
			stepWithNoStock <- stepWithNoStock + 1;
			stepWithStock <- 0;
		}
		else{
			stepWithNoStock <- 0;
			stepWithStock <- stepWithStock + 1;
		}
	}
}