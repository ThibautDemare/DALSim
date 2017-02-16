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
	int status <- 0; // = 0 : a restock has not been asked; = 1 the restock has been asked; = 2 : ?? no idea - was it used before? ?? ; = 3 : a building is processing the order to restock
	FinalDestinationManager fdm;
	LogisticProvider lp;
	Building building;
	int stepWithNoStock <- 0; // Used to detect bug in the simulation : if a stock never has a restock, then there is a bug somewhere. Bugs in ABM can be hard to detect...
	int stepWithStock <- 0;
	 
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