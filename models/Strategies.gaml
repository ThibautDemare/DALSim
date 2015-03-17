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
	 * Strategy 1
	 */

	/**
	 * Return a small warehouse according to the position of the final destination : the more the warehouse is close to the final destination, the more he has a chance to be selected.
	 */
	Warehouse findWarehouseLvl1Strat1(FinalDestinationManager fdm, int sizeOfStock){
		list<Warehouse> lsw <- Warehouse sort_by (fdm distance_to each);
		int f <- ((rnd(10000)/10000)^32)*(length(lsw)-1);
		// I assume that there is always at least one warehouse which has a free space greater than the occupied surface of the stock to outsource.
		// According to results, it doesn't seem foolish.
		loop while:
				( (lsw[f] as Building).surfaceUsedForLH - (lsw[f] as Building).occupiedSurface) <= 0 or
				( (lsw[f] as Building).surfaceUsedForLH - (lsw[f] as Building).occupiedSurface - (fdm.building as Building).occupiedSurface * sizeOfStock)	< 0 {
			f <- ((rnd(10000)/10000)^32)*(length(lsw)-1);
		}
		return lsw[f];/**/
		//return one_of(average_warehouse);
	}
	
	/**
	 * Return a large warehouse : the more the warehouse has a big free surface, the more he has a chance to be selected.
	 */
	Warehouse findWarehouseLvl3Strat1(FinalDestinationManager fdm, int sizeOfStock){
		list<Warehouse> llw <- Warehouse sort_by (each.surfaceUsedForLH-each.occupiedSurface);
		int f <- ((rnd(10000)/10000)^6)*(length(llw)-1);
		// I assume that there is always at least one warehouse which has a free space greater than the occupied surface of the stock to outsource.
		// It probably needs a piece of code to avoid problem of no free available surface
		loop while:
				( (llw[(length(llw)-1) - f] as Building).surfaceUsedForLH - (llw[(length(llw)-1) - f] as Building).occupiedSurface ) <= 0 or
				(   (llw[(length(llw)-1) - f] as Building).surfaceUsedForLH - 
					(llw[(length(llw)-1) - f] as Building).occupiedSurface - 
					((fdm.building as Building).occupiedSurface * sizeOfStock)
				) < 0 {
			f <- ((rnd(10000)/10000)^6)*(length(llw)-1);
		}
		return llw[(length(llw)-1) - f];/**/
		//return one_of(large_warehouse);
	}

	/*
	 * Strategy 2
	 */
	 
	/**
	 * Stratégie pour trouver un entrepot de proximité :
	 * On crée la liste de tous les entrepots
	 * On supprime ceux qui n'ont pas la capacité d'entreposer la marchandise
	 * On sélectionne les 10/20/50/100 (paramétre à définir) plus proches
	 * on choisit celui qui a la plus grande valeur d'accessibilité
	 */
	Warehouse findWarehouseLvl1Strat2(FinalDestinationManager fdm, int sizeOfStock){
		// We inform GAMA that each warehouse must be consider connected to the network in order to compute the Shimbel index
		bool success <- connect_to(list(Warehouse), road_network, "length", "speed", 70°m/°s);
		if(first(Warehouse).accessibility < 0){
			ask Warehouse {
				self.accessibility <- shimbel_index(self, road_network, "length", "speed", 70°m/°s);
			}
		}
		
		list<Warehouse> lw <- list(Warehouse);
		
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

		// Delete the farest ones
		lw <- lw sort_by (fdm distance_to each);
		i <- 0;
		loop while: i < length(lw) {
			if( i > numberWarehouseSelected) {
				remove index: i from: lw;	
			}
			i <- i + 1;
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
	Warehouse findWarehouseLvl3Strat2(FinalDestinationManager fdm, int sizeOfStock){
		// We inform GAMA that each warehouse must be consider connected to the network in order to compute the Shimbel index
		bool success <- connect_to(list(Warehouse), road_network, "length", "speed", 70°m/°s);
		if(first(Warehouse).accessibility < 0){
			ask Warehouse {
				self.accessibility <- shimbel_index(self, road_network, "length", "speed", 70°m/°s);
			}
		}
		
		list<Warehouse> lw <- list(Warehouse);
		
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
		
		// Return the most accessible (in the case of the Shimbel index, the most accessible has the lowest value of accessibility
		lw <- lw sort_by (each.accessibility);
		return lw[0];
	}
	
	
	/*
	 * Strategy 3
	 */
	 
	/**
	 * Stratégie pour trouver un entrepot de proximité :
	 * On crée la liste de tous les entrepots
	 * On supprime ceux qui n'ont pas la capacité d'entreposer la marchandise
	 * On sélectionne le plus proche
	 */
	Warehouse findWarehouseLvl1Strat3(FinalDestinationManager fdm, int sizeOfStock){
		list<Warehouse> lw <- list(Warehouse);
		
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

		// return the closest ones
		lw <- lw sort_by (fdm distance_to each);
		return lw[0];
	}
	
	/**
	 * Stratégie pour trouver un entrepot de grande taille
	 * On crée la liste de tous les entrepots
	 * On supprime ceux qui n'ont pas la capacité d'entreposer la marchandise
	 * On sélectionne les 10/20/50/100 (paramétre à définir) ayant la plus grande valeur d'accessibilité (ou plutot les plus grand?)
	 * On choisit le plus proche?/le plus large/celui ayant la plus grande valeur d'accessibilité? => à tester
	 */
	Warehouse findWarehouseLvl3Strat3(FinalDestinationManager fdm, int sizeOfStock){
		list<Warehouse> lw <- list(Warehouse);
		
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
}