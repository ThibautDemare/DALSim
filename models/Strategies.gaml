model Strategies

import "Warehouse.gaml"
import "Building.gaml"
import "Networks.gaml"

global {
	/*
	 * Strategy 1 : More or less dumb strategy. The selection of the closest/largest warehouse is made according to a probability
	 */

	/**
	 * Return a small warehouse according to the position of the final destination : the more the warehouse is close to the final destination, the more he has a chance to be selected.
	 */
	Warehouse findWarehouseLvl1Strat1(FinalConsignee fdm, int sizeOfStock, list<Warehouse> lvl2Warehouses){
		list<Warehouse> lw <- copy(Warehouse);

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

		lw <- lw sort_by (fdm distance_to each);

		int f <- ((rnd(10000)/10000)^6)*(length(lw)-1);
		// I assume that there is always at least one warehouse which has a free space greater than the occupied surface of the stock to outsource.
		// According to results, it doesn't seem foolish.
		loop while:
				( (lw[f] as Building).totalSurface - (lw[f] as Building).occupiedSurface) <= 0 or
				( (lw[f] as Building).totalSurface - (lw[f] as Building).occupiedSurface - (fdm.building as Building).occupiedSurface * sizeOfStock)	< 0 {
			f <- ((rnd(10000)/10000)^6)*(length(lw)-1);
		}
		return lw[f];/**/
	}
	
	/**
	 * Return a large warehouse : the more the warehouse has a big free surface, the more he has a chance to be selected.
	 */
	Warehouse findWarehouseLvl2Strat1(FinalConsignee fdm, int sizeOfStock, list<Warehouse> lvl1Warehouses){
		list<Warehouse> lw <- copy(Warehouse);

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

		lw <- lw sort_by (each.totalSurface-each.occupiedSurface);

		int f <- ((rnd(10000)/10000)^6)*(length(lw)-1);
		// I assume that there is always at least one warehouse which has a free space greater than the occupied surface of the stock to outsource.
		// It probably needs a piece of code to avoid problem of no free available surface
		loop while:
				( (lw[(length(lw)-1) - f] as Building).totalSurface - (lw[(length(lw)-1) - f] as Building).occupiedSurface ) <= 0 or
				(   (lw[(length(lw)-1) - f] as Building).totalSurface - 
					(lw[(length(lw)-1) - f] as Building).occupiedSurface - 
					((fdm.building as Building).occupiedSurface * sizeOfStock)
				) < 0 {
			f <- ((rnd(10000)/10000)^6)*(length(lw)-1);
		}
		return lw[(length(lw)-1) - f];/**/
	}

	/*
	 * Strategy 2 : select the closest/largest according to the accessibility of the warehouse
	 */
	 
	/**
	 * Stratégie pour trouver un entrepot de proximité :
	 * On crée la liste de tous les entrepots
	 * On supprime ceux qui n'ont pas la capacité d'entreposer la marchandise
	 * On sélectionne les 10/20/50/100 (paramétre à définir) plus proches
	 * on choisit celui qui a la plus grande valeur d'accessibilité
	 */
	Warehouse findWarehouseLvl1Strat2(FinalConsignee fdm, int sizeOfStock, list<Warehouse> lvl1Warehouses, list<Warehouse> lvl2Warehouses){
		// We inform GAMA that each warehouse must be consider connected to the network in order to compute the Shimbel index
		bool success <- connect_to(list(Warehouse), road_network, "length", "speed", 70°m/°s);
		if(first(Warehouse).accessibility < 0){
			int i <- 0;
			ask Warehouse {
				self.accessibility <- shimbel_index(self, road_network, "length", "speed", 70°m/°s);
				i <- i + 1;
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
			if(( lw[i] as Building).totalSurface - (lw[i] as Building).occupiedSurface - ((fdm.building as Building).occupiedSurface * sizeOfStock ) < 0) {
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
			if( i >= numberWarehouseSelected) {
				remove index: i from: lw;
			}
			else {
				i <- i + 1;
			}
		}

		// Look at the list of warehouses of level 1
		// if one of those warehouses is in the remaining list of close warehouses, then we return this warehouse (we already filtered the unfree warehouses)
		i <- 0;
		bool notfound <- true;
		Warehouse toreturn <- nil;
		loop while: i < length(lw) and notfound {
			if(lvl1Warehouses contains lw[i]){
				notfound <- false;
				toreturn <- lw[i];
			}
			else{
				i <- i + 1;
			}
		}

		// It seems that since the new version of gama, I can't return the warehouse in the previous loop... It return nil even if lw[i] is not nil.
		if(!notfound){
			return toreturn;
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
	Warehouse findWarehouseLvl2Strat2(FinalConsignee fdm, int sizeOfStock, list<Warehouse> lvl1Warehouses, list<Warehouse> lvl2Warehouses){
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
			if(( lw[i] as Building).totalSurface - (lw[i] as Building).occupiedSurface - ((fdm.building as Building).occupiedSurface * sizeOfStock ) < 0) {
				remove index: i from: lw;
			}
			else{
				i <- i + 1;
			}
		}

		// Delete the smallest ones
		lw <- lw sort_by (each.totalSurface - each.occupiedSurface);
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

		// Look at the list of warehouses of level 2
		// if one of those warehouses is in the remaining list of close warehouses, then we return this warehouse (we already filtered the unfree warehouses)
		i <- 0;
		bool notfound <- true;
		Warehouse toreturn <- nil;
		loop while: i < length(lw) and notfound {
			if(lvl2Warehouses contains lw[i]){
				notfound <- false;
				toreturn <- lw[i];
			}
			else{
				i <- i + 1;
			}
		}

		// It seems that since the new version of gama, I can't return the warehouse in the previous loop... It return nil even if lw[i] is not nil.
		if(!notfound){
			return toreturn;
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
	Warehouse findWarehouseLvl1Strat3(FinalConsignee fdm, int sizeOfStock, list<Warehouse> lvl2Warehouses){
		list<Warehouse> lw <- copy(list(Warehouse));
		
		// Remove the ones that cannot welcome the stocks of the customer
		int i <- 0;
		loop while: i < length(lw) {
			if(( lw[i] as Building).totalSurface - (lw[i] as Building).occupiedSurface - ((fdm.building as Building).occupiedSurface * sizeOfStock ) < 0) {
				remove index: i from: lw;	
			}
			else{
				i <- i + 1;
			}
		}

		// Remove the ones which cannot welcome the stocks of the customer because they are already a warehouse of level 2
		i <- 0;
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
	Warehouse findWarehouseLvl2Strat3(FinalConsignee fdm, int sizeOfStock, list<Warehouse> lvl1Warehouses){
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
		i <- 0;
		loop while: i < length(lw) {
			if(( lw[i] as Building).totalSurface - (lw[i] as Building).occupiedSurface - ((fdm.building as Building).occupiedSurface * sizeOfStock ) < 0) {
				remove index: i from: lw;	
			}
			else{
				i <- i + 1;
			}
		}

		// return the largest one
		lw <- lw sort_by (each.totalSurface - each.occupiedSurface);
		return lw[length(lw) - 1];
	}

	/*
	 * Strategy 4 : pure random selection
	 */

	/**
	 * Select randomly a warehouse
	 */
	Warehouse findWarehouseLvl1Strat4(FinalConsignee fdm, int sizeOfStock, list<Warehouse> lvl2Warehouses){
		return pureRandom(fdm, sizeOfStock, lvl2Warehouses);
	}

	/**
	 * Select randomly a warehouse
	 */
	Warehouse findWarehouseLvl2Strat4(FinalConsignee fdm, int sizeOfStock, list<Warehouse> lvl1Warehouses){
		return pureRandom(fdm, sizeOfStock, lvl1Warehouses);
	}

	Warehouse pureRandom(FinalConsignee fdm, int sizeOfStock, list<Warehouse> otherLvlWarehouses){
		list<Warehouse> lw <- copy(list(Warehouse));

		// Remove the ones that cannot welcome the stocks of the customer
		int i <- 0;
		loop while: i < length(lw) {
			if(( lw[i] as Building).totalSurface - (lw[i] as Building).occupiedSurface - ((fdm.building as Building).occupiedSurface * sizeOfStock ) < 0) {
				remove index: i from: lw;
			}
			else{
				i <- i + 1;
			}
		}

		// Remove the ones which cannot welcome the stocks of the customer because they are already a warehouse of level 2
		i <- 0;
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