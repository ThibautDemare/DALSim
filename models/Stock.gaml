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
	int status <- false;
	FinalDestinationManager fdm;
	LogisticProvider lp;
	int stepWithNoStock <- 0;
	Building building;
	
	reflex updateStepWithNoStock {
		if(quantity = 0){
			stepWithNoStock <- stepWithNoStock + 1;
		}
		else{
			stepWithNoStock <- 0;
		}
	}
}