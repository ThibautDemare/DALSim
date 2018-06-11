model Terminals

import "Building.gaml"

species Terminal parent:Building{	
	aspect geom {
		if(colorValue = -1){
			string col <- "grey"; 
			draw shape + 2°px color: rgb(col) border: rgb(col);
		}
		else {
			draw shape + 2°px color: rgb(255, colorValue, 0) border:rgb(255, colorValue, 0);
		}
	}
}

species MaritimeTerminal parent:Terminal{
	float handling_time_to_maritime;
	float handling_time_from_maritime;
	string col <- "red";
	aspect geom {
		if(colorValue = -1){
			string col <- "grey"; 
			draw shape + 2°px color: rgb(col) border: rgb(col);
		}
		else {
			draw shape + 2°px color: rgb(255, colorValue, 0) border:rgb(255, colorValue, 0);
		}
	}
	
	reflex manageMaritimeComingCommodities {
		int i <- 0;
		loop while:i<length(comingCommodities) {
			if(comingCommodities[i].currentNetwork = 'maritime' and
				comingCommodities[i].incomingDate + handling_time_from_maritime#hour >= current_date
			){
				leavingCommodities <+ comingCommodities[i];
				remove index:i from:comingCommodities;
			}
			else{
				i <- i + 1;
			}
		} 
	}
}

species RiverTerminal parent:Terminal{
	float handling_time_to_river;
	float handling_time_from_river;
	string col <- "red";
	
	reflex manageRiverComingCommodities {
		int i <- 0;
		loop while:i<length(comingCommodities) {
			if(comingCommodities[i].currentNetwork = 'river' and
				comingCommodities[i].incomingDate + handling_time_from_river#hour >= current_date
			){
				leavingCommodities <+ comingCommodities[i];
				remove index:i from:comingCommodities;
			}
			else{
				i <- i + 1;
			}
		} 
	}
	
	aspect geom {
		if(colorValue = -1){
			string col <- "grey"; 
			draw shape + 2°px color: rgb(col) border: rgb(col);
		}
		else {
			draw shape + 2°px color: rgb(255, colorValue, 0) border:rgb(255, colorValue, 0);
		}
	}
}

species MaritimeRiverTerminal parent:Terminal {
	float handling_time_to_maritime;
	float handling_time_from_maritime;
	float handling_time_to_river;
	float handling_time_from_river;
	string col <- "red";
	
	reflex manageMaritimeComingCommodities {
		int i <- 0;
		loop while:i<length(comingCommodities) {
			if(comingCommodities[i].currentNetwork = 'maritime' and
				comingCommodities[i].incomingDate + handling_time_from_maritime#hour >= current_date
			){
				leavingCommodities <+ comingCommodities[i];
				remove index:i from:comingCommodities;
			}
			else{
				i <- i + 1;
			}
		} 
	}
	
	reflex manageRiverComingCommodities {
		int i <- 0;
		loop while:i<length(comingCommodities) {
			if(comingCommodities[i].currentNetwork = 'river' and
				comingCommodities[i].incomingDate + handling_time_from_river#hour >= current_date
			){
				leavingCommodities <+ comingCommodities[i];
				remove index:i from:comingCommodities;
			}
			else{
				i <- i + 1;
			}
		} 
	}

	reflex updateHandlingTimeToRoad when: cycle = 100 {
		handling_time_to_road <- 100000;
	}

	aspect geom {
		if(colorValue = -1){
			string col <- "grey"; 
			draw shape + 2°px color: rgb(col) border: rgb(col);
		}
		else {
			draw shape + 2°px color: rgb(255, colorValue, 0) border:rgb(255, colorValue, 0);
		}
	}
}