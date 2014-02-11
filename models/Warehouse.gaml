/**
 *  Warehouse
 *  Author: Thibaut Démare
 *  Description: A warehouse contains some batch of goods and is owned by a logistic provider
 */

model Warehouse

import "./Building.gaml"
import "./LogisticProvider.gaml"

species Warehouse parent: Building{
	LogisticProvider logisticProvider;
	list<Batch> batchs;
	
	float huffValue;
	
	init {
		logisticProvider <- nil;
	}
}
