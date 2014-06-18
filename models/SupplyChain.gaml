/**
 *  SupplyChain
 *  Author: Thibaut
 *  Description: 
 */

model SupplyChain


import "./Building.gaml"

species SupplyChain {
	FinalDestinationManager fdm;
	list<Building> buildings;
}