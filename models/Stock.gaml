/**
 *  Stock
 *  Author: Thibaut Démare
 *  Description: Total or partial stock of a given product
 */

model Stock

import "./Building.gaml"

species Stock {
	int product;
	float quantity;
	float maxQuantity;
	float unitVolume;
	bool ordered <- false;
	Building building;
}