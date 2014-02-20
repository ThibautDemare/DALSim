/**
 *  Order
 *  Author: Thibaut Démare
 *  Description: This agent simulates the information flow before the real goods is created. We can notice that it contains the supply chain that will be taken by the batch.
 */

model Order

import "./LogisticProvider.gaml"

species Order {
	int product;
	float quantity;
	Building building;
	LogisticProvider logisticProvider;
}