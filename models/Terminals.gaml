model Terminals

import "Building.gaml"

species Terminal parent:Building{	
	string col <- "grey";
	aspect geom {
		if(colorValue = -1){ 
			draw shape + 2°px color: rgb(col) border: rgb(col);
		}
		else {
			draw shape + 2°px color: rgb(255, colorValue, 0) border:rgb(255, colorValue, 0);
		}
	}
}

species SecondaryTerminal parent:Terminal{
	float handling_time_to_secondary;
	float handling_time_from_secondary;
	string col <- "red";

	reflex manageSecondaryComingCommodities {
		int i <- 0;
		loop while:i<length(comingCommodities) {
			if(comingCommodities[i].currentNetwork = 'secondary' and
				comingCommodities[i].incomingDate + handling_time_from_secondary#hour >= current_date
			){
				leavingCommodities <+ comingCommodities[i];
				remove index:i from:comingCommodities;
			}
			else{
				i <- i + 1;
			}
		} 
	}

	float getHandlingTimeFrom(string nt){
		if(nt = "road"){
			return handling_time_from_road;
		}
		return handling_time_from_secondary;
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

	float getHandlingTimeFrom(string nt){
		if(nt = "road"){
			return handling_time_from_road;
		}
		// else : nt = "river"
		return handling_time_from_river;
	}
}

species MaritimeRiverTerminal parent:Terminal {
	float handling_time_to_maritime;
	float handling_time_from_maritime;
	float handling_time_to_secondary;
	float handling_time_from_secondary;
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

	reflex manageSecondaryComingCommodities {
		int i <- 0;
		loop while:i<length(comingCommodities) {
			if(comingCommodities[i].currentNetwork = 'secondary' and
				comingCommodities[i].incomingDate + handling_time_from_secondary#hour >= current_date
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

	float getHandlingTimeFrom(string nt){
		if(nt = "road"){
			return handling_time_from_road;
		}
		if(nt = "maritime"){
			return handling_time_from_maritime;
		}
		if(nt = "secondary"){
			return handling_time_from_secondary;
		}
		// else : nt = "river"
		return handling_time_from_river;
	}
}