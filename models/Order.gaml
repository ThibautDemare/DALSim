/**
 *  Order
 *  Author: Thibaut Démare
 *  Description: This agent simulates the information flow before the real goods is created. We can notice that it contains the supply chain that will be taken by the batch.
 */

model Order

import "./LogisticProvider.gaml"

species Order schedules: [] {
	int product; // The kind of goods ordered
	float quantity; // the ordered quantity
	Building building; // which building has made the order
	LogisticProvider logisticProvider; // the LSP who manages the ordered goods
	int position;// The position in the supply chain
	FinalDestinationManager fdm; // The FDM who posseses these goods
	Stock reference; // a reference to the stock which suffer of stock shortage
	int stepOrderMade; // when does the order has been made
}