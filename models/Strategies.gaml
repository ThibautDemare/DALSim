/**
 *  Strategies
 *  Author: Thibaut
 *  Description: List the different strategies that the agents can adopt
 */

model Strategies

import "./Warehouse.gaml"
import "./Building.gaml"
import "./FinalDestinationManager.gaml"
import "./LogisticProvider.gaml"
import "./Parameters.gaml"
import "./SeineAxisModel.gaml"

global {
	/*
	 * Strategy 1 : More or less dumb strategy. The selection of the closest/largest warehouse is made according to a probability
	 */

	/**
	 * Return a small warehouse according to the position of the final destination : the more the warehouse is close to the final destination, the more he has a chance to be selected.
	 */
	Warehouse findWarehouseLvl1Strat1(FinalDestinationManager fdm, int sizeOfStock, list<SupplyChainElement> lvl1Warehouses, list<SupplyChainElement> lvl2Warehouses){
		list<Warehouse> lw <- copy(Warehouse) sort_by (fdm distance_to each);

		// Remove the ones which cannot welcome the stocks of the customer because they are already a warehouse of level 2
		int i <- 0;
		loop while: i < length(lw) {
			if(lvl2Warehouses contains lw[i]){
				remove index: i from: lw;
			}
			else{
				i <- i + 1;
			}
		}

		int f <- ((rnd(10000)/10000)^32)*(length(lw)-1);
		// I assume that there is always at least one warehouse which has a free space greater than the occupied surface of the stock to outsource.
		// According to results, it doesn't seem foolish.
		loop while:
				( (lw[f] as Building).surfaceUsedForLH - (lw[f] as Building).occupiedSurface) <= 0 or
				( (lw[f] as Building).surfaceUsedForLH - (lw[f] as Building).occupiedSurface - (fdm.building as Building).occupiedSurface * sizeOfStock)	< 0 {
			f <- ((rnd(10000)/10000)^32)*(length(lw)-1);
		}
		return lw[f];/**/
		//return one_of(average_warehouse);
	}
	
	/**
	 * Return a large warehouse : the more the warehouse has a big free surface, the more he has a chance to be selected.
	 */
	Warehouse findWarehouseLvl2Strat1(FinalDestinationManager fdm, int sizeOfStock, list<SupplyChainElement> lvl1Warehouses, list<SupplyChainElement> lvl3Warehouses){
		list<Warehouse> lw <- copy(Warehouse) sort_by (each.surfaceUsedForLH-each.occupiedSurface);

		// Remove the ones which cannot welcome the stocks of the customer because they are already a warehouse of level 1
		int i <- 0;
		loop while: i < length(lw) {
			if(lvl1Warehouses contains lw[i]){
				remove index: i from: lw;
			}
			else{
				i <- i + 1;
			}
		}

		int f <- ((rnd(10000)/10000)^6)*(length(lw)-1);
		// I assume that there is always at least one warehouse which has a free space greater than the occupied surface of the stock to outsource.
		// It probably needs a piece of code to avoid problem of no free available surface
		loop while:
				( (lw[(length(lw)-1) - f] as Building).surfaceUsedForLH - (lw[(length(lw)-1) - f] as Building).occupiedSurface ) <= 0 or
				(   (lw[(length(lw)-1) - f] as Building).surfaceUsedForLH - 
					(lw[(length(lw)-1) - f] as Building).occupiedSurface - 
					((fdm.building as Building).occupiedSurface * sizeOfStock)
				) < 0 {
			f <- ((rnd(10000)/10000)^6)*(length(lw)-1);
		}
		return lw[(length(lw)-1) - f];/**/
		//return one_of(large_warehouse);
	}

	/*
	 * Strategy 2 : more or less smart strategy : select the closest/largest according to the accessibility of the warehouse
	 */
	 
	/**
	 * Stratégie pour trouver un entrepot de proximité :
	 * On crée la liste de tous les entrepots
	 * On supprime ceux qui n'ont pas la capacité d'entreposer la marchandise
	 * On sélectionne les 10/20/50/100 (paramétre à définir) plus proches
	 * on choisit celui qui a la plus grande valeur d'accessibilité
	 */
	Warehouse findWarehouseLvl1Strat2(FinalDestinationManager fdm, int sizeOfStock, list<SupplyChainElement> lvl1Warehouses, list<SupplyChainElement> lvl2Warehouses){
		// We inform GAMA that each warehouse must be consider connected to the network in order to compute the Shimbel index
		bool success <- connect_to(list(Warehouse), road_network, "length", "speed", 70°m/°s);
		if(first(Warehouse).accessibility < 0){
			ask Warehouse {
				self.accessibility <- shimbel_index(self, road_network, "length", "speed", 70°m/°s);
			}
		}

		list<Warehouse> lw <- copy(list(Warehouse));

		// Remove the ones which cannot welcome the stocks of the customer because they are already a warehouse of level 2
		int i <- 0;
		loop while: i < length(lw) {
			if(lvl2Warehouses contains lw[i]){
				remove index: i from: lw;
			}
			else{
				i <- i + 1;
			}
		}

		// Remove the ones which cannot welcome the stocks of the customer because they don't have enough space
		i <- 0;
		loop while: i < length(lw) {
			if(( lw[i] as Building).surfaceUsedForLH - (lw[i] as Building).occupiedSurface - ((fdm.building as Building).occupiedSurface * sizeOfStock ) < 0) {
				remove index: i from: lw;
			}
			else{
				i <- i + 1;
			}
		}

		// Delete the farest ones
		lw <- lw sort_by (fdm distance_to each);
		i <- 0;
		loop while: i < length(lw) {
			if( i > numberWarehouseSelected) {
				remove index: i from: lw;
			}
			i <- i + 1;
		}

		// Look at the list of warehouses of level 1
		// if one of those warehouses is in the remaining list of close warehouses, then we return this warehouse (we already filtered the unfree warehouses)
		i <- 0;
		loop while: i < length(lw) {
			if(lvl1Warehouses contains lw[i]){
				return lw[i];
			}
			else{
				i <- i + 1;
			}
		}

		// Return the most accessible (in the case of the Shimbel index, the most accessible has the lowest value of accessibility
		lw <- lw sort_by (each.accessibility);
		return lw[0];
	}
	
	/**
	 * Stratégie pour trouver un entrepot de grande taille
	 * On crée la liste de tous les entrepots
	 * On supprime ceux qui n'ont pas la capacité d'entreposer la marchandise
	 * On sélectionne les 10/20/50/100 (paramétre à définir) ayant la plus grande valeur d'accessibilité (ou plutot les plus grand?)
	 * On choisit le plus proche?/le plus large/celui ayant la plus grande valeur d'accessibilité? => à tester
	 */
	Warehouse findWarehouseLvl2Strat2(FinalDestinationManager fdm, int sizeOfStock, list<SupplyChainElement> lvl1Warehouses, list<SupplyChainElement> lvl2Warehouses){
		// We inform GAMA that each warehouse must be consider connected to the network in order to compute the Shimbel index
		bool success <- connect_to(list(Warehouse), road_network, "length", "speed", 70°m/°s);
		if(first(Warehouse).accessibility < 0){
			ask Warehouse {
				self.accessibility <- shimbel_index(self, road_network, "length", "speed", 70°m/°s);
			}
		}
		
		list<Warehouse> lw <- copy(list(Warehouse));

		// Remove the ones which cannot welcome the stocks of the customer because they are already a warehouse of level 1
		int i <- 0;
		loop while: i < length(lw) {
			if(lvl1Warehouses contains lw[i]){
				remove index: i from: lw;
			}
			else{
				i <- i + 1;
			}
		}

		// Remove the ones which cannot welcome the stocks of the customer because they don't have enough space
		i <- 0;
		loop while: i < length(lw) {
			if(( lw[i] as Building).surfaceUsedForLH - (lw[i] as Building).occupiedSurface - ((fdm.building as Building).occupiedSurface * sizeOfStock ) < 0) {
				remove index: i from: lw;
			}
			else{
				i <- i + 1;
			}
		}

		// Delete the smallest ones
		i <- 0;
		loop while: i < length(lw) {
			if( length(lw) - i < numberWarehouseSelected) {
				remove index: i from: lw;	
			}
			i <- i + 1;
		}
		// We only keep the most accessible warehouses
		lw <- lw sort_by (each.accessibility);
		i <- 0;
		loop while: i < length(lw) {
			if( i > numberWarehouseSelected) {
				remove index: i from: lw;
			}
			i <- i + 1;
		}

		// Look at the list of warehouses of level 1
		// if one of those warehouses is in the remaining list of close warehouses, then we return this warehouse (we already filtered the unfree warehouses)
		i <- 0;
		loop while: i < length(lw) {
			if(lvl2Warehouses contains lw[i]){
				return lw[i];
			}
			else{
				i <- i + 1;
			}
		}

		// Return the most accessible (in the case of the Shimbel index, the most accessible has the lowest value of accessibility
		lw <- lw sort_by (each.accessibility);
		return lw[0];
	}
	
	
	/*
	 * Strategy 3 : dumb strategy : select the closest/largest warehouse
	 */
	 
	/**
	 * Stratégie pour trouver un entrepot de proximité :
	 * On crée la liste de tous les entrepots
	 * On supprime ceux qui n'ont pas la capacité d'entreposer la marchandise
	 * On sélectionne le plus proche
	 */
	Warehouse findWarehouseLvl1Strat3(FinalDestinationManager fdm, int sizeOfStock, list<SupplyChainElement> lvl2Warehouses){
		list<Warehouse> lw <- copy(list(Warehouse));
		
		// Remove the ones that cannot welcome the stocks of the customer
		int i <- 0;
		loop while: i < length(lw) {
			if(( lw[i] as Building).surfaceUsedForLH - (lw[i] as Building).occupiedSurface - ((fdm.building as Building).occupiedSurface * sizeOfStock ) < 0) {
				remove index: i from: lw;	
			}
			else{
				i <- i + 1;
			}
		}

		// Remove the ones which cannot welcome the stocks of the customer because they are already a warehouse of level 2
		int i <- 0;
		loop while: i < length(lw) {
			if(lvl2Warehouses contains lw[i]){
				remove index: i from: lw;
			}
			else{
				i <- i + 1;
			}
		}

		// return the closest ones
		lw <- lw sort_by (fdm distance_to each);
		return lw[0];
	}
	
	/**
	 * Stratégie pour trouver un entrepot de grande taille
	 * On crée la liste de tous les entrepots
	 * On supprime ceux qui n'ont pas la capacité d'entreposer la marchandise
	 * On choisit le plus large
	 */
	Warehouse findWarehouseLvl2Strat3(FinalDestinationManager fdm, int sizeOfStock, list<SupplyChainElement> lvl1Warehouses){
		list<Warehouse> lw <- copy(list(Warehouse));
		
		// Remove the ones which cannot welcome the stocks of the customer because they are already a warehouse of level 1
		int i <- 0;
		loop while: i < length(lw) {
			if(lvl1Warehouses contains lw[i]){
				remove index: i from: lw;
			}
			else{
				i <- i + 1;
			}
		}

		// Remove the ones that cannot welcome the stocks of the customer
		int i <- 0;
		loop while: i < length(lw) {
			if(( lw[i] as Building).surfaceUsedForLH - (lw[i] as Building).occupiedSurface - ((fdm.building as Building).occupiedSurface * sizeOfStock ) < 0) {
				remove index: i from: lw;	
			}
			else{
				i <- i + 1;
			}
		}

		// return the largest one
		lw <- lw sort_by (each.surfaceUsedForLH - each.occupiedSurface);
		return lw[length(lw) - 1];
	}

	/*
	 * Strategy 4 : pure random selection
	 */

	/**
	 * Select randomly a warehouse
	 */
	Warehouse findWarehouseLvl1Strat4(FinalDestinationManager fdm, int sizeOfStock, list<SupplyChainElement> lvl2Warehouses){
		return pureRandom(fdm, sizeOfStock, lvl2Warehouses);
	}

	/**
	 * Select randomly a warehouse
	 */
	Warehouse findWarehouseLvl2Strat4(FinalDestinationManager fdm, int sizeOfStock, list<SupplyChainElement> lvl1Warehouses){
		return pureRandom(fdm, sizeOfStock, lvl1Warehouses);
	}

	Warehouse pureRandom(FinalDestinationManager fdm, int sizeOfStock, list<SupplyChainElement> otherLvlWarehouses){
		list<Warehouse> lw <- copy(list(Warehouse));

		// Remove the ones that cannot welcome the stocks of the customer
		int i <- 0;
		loop while: i < length(lw) {
			if(( lw[i] as Building).surfaceUsedForLH - (lw[i] as Building).occupiedSurface - ((fdm.building as Building).occupiedSurface * sizeOfStock ) < 0) {
				remove index: i from: lw;
			}
			else{
				i <- i + 1;
			}
		}

		// Remove the ones which cannot welcome the stocks of the customer because they are already a warehouse of level 2
		int i <- 0;
		loop while: i < length(lw) {
			if(otherLvlWarehouses contains lw[i]){
				remove index: i from: lw;
			}
			else{
				i <- i + 1;
			}
		}

		return one_of(lw);
	}
}