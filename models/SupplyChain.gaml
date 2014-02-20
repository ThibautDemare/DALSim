/**
 *  SupplyChain
 *  Author: Thibaut
 *  Description: 
 */

model SupplyChain


import "./Building.gaml"

species SupplyChain {
	list<Building> buildings;
}