/**
 *  Stock
 *  Author: Thibaut Démare
 *  Description: Total or partial stock of a given product
 */

model Stock

import "./Building.gaml"

species Stock schedules:[]{
	int product;
	float quantity;
	float maxQuantity;
	int status <- false;
	FinalDestinationManager fdm;
	LogisticProvider lp;
}