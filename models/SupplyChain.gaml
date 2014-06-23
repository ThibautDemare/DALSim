/**
 *  SupplyChain
 *  Author: Thibaut
 *  Description: 
 */

model SupplyChain


import "./Building.gaml"

species SupplyChain {
	SupplyChainElement root;
}

species SupplyChainElement {
	Building building;
	list<SupplyChainElement> fathers;
	list<SupplyChainElement> sons;
}