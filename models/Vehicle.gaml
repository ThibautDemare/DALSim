model Vehicle

import "Networks.gaml"
import "Building.gaml"

species Vehicle skills:[MovingOnNetwork] {

	bool marked <- false;// useful for the Observer in order to avoid to count the batch two times
	float pathLength <- -1;

	date departureDate; // date de départ du véhicule
	graph newtork; // réseau sur lequel le véhicule se déplace
	Building destination; // Destination
	Building source; // where the vehicle comes from
	list<Commodity> scheduledCommodities; // marchandises qui devraient être transportées
	list<Commodity> transportedCommodities; // commodities really transported
	float currentTransportedVolume; // quantité de marchandise actuellement transportees
	bool readyToMove <- false;
	string networkType;
	float colorValue <- -1;
	
	action init_networks {
		do add_network name:"maritime" network:maritime_network length_attribute:"length" speed_attribute:"speed";
		do add_network name:"river" network:river_network length_attribute:"length" speed_attribute:"speed";
		do add_network name:"road" network:road_network length_attribute:"length" speed_attribute:"speed";
	}
	
	reflex authorizeDeparture when: departureDate != nil and 
		(departureDate = current_date or (departureDate < current_date and departureDate > current_date-1#hour))
		and !readyToMove {
		currentTransportedVolume <- 0;
		// We check if the shceduled commodities are really in the building before we leave it
		int j <- 0;
		loop while: j < length(scheduledCommodities) {
			int i <- 0;
			loop while: i < length(source.leavingCommodities) {
				if(scheduledCommodities[j] = source.leavingCommodities[i]){
					transportedCommodities <+ scheduledCommodities[j];
					currentTransportedVolume <- currentTransportedVolume + scheduledCommodities[j].volume;
					scheduledCommodities[j].currentNetwork <- networkType;
				}
				i <- i + 1;
			}
			j <- j + 1;
		}
		if(length(transportedCommodities) = 0){
			write "There is nothing to carry";
			write "\tDeparture date : "+departureDate;
			write "\tcurrent_date : "+current_date;
			write "\tscheduledCommodities[0] : "+scheduledCommodities[0];
			write "\tnetworkType : "+networkType;
			do die;// There are no commodities to transport. No need to move, the scheduled commodities will have to register another vehicle 
		}
		readyToMove <- true;
	}

	reflex move when: readyToMove and destination != nil {
		do go_to destination:destination.location mark:currentTransportedVolume;

		if(location = destination.location){
			int j <- 0;
			loop while: j < length(transportedCommodities) {
				transportedCommodities[j].location <- location;
				transportedCommodities[j].incomingDate <- current_date;
				ask destination {
					do receiveCommodity(myself.transportedCommodities[j], myself.networkType);
				}
				j <- j + 1;
			}
			
			destination <- nil;
			do die;
		}
	}

	aspect base {
		if(colorValue = -1){
			if(destination != nil){
				string col <- "red"; 
				draw shape + 2°px color: rgb(col) border: rgb(col);	
			}
		}
		else {
			draw shape + 2°px color: rgb(255, colorValue, 0) border:rgb(255, colorValue, 0);
		}
	}
}