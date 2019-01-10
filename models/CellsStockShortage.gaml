model CellsStockShortage

import "Stock.gaml"

grid cell_stock_shortage width:50 height:50  {
	rgb color <- rgb(255,255,255,0.0);
	float nb_stock_shortage;
	float nb_stock;
	list<float> ratios <- [];

	reflex coloration {
		nb_stock_shortage <- 0;
		nb_stock <- 0;
		list<Building> buildings <- (Building inside self);// + (Warehouse inside self);

		loop b over: buildings {
			ask (b as Building).stocks {
				myself.nb_stock <- myself.nb_stock + 1;
				if(self.quantity = 0){
					myself.nb_stock_shortage <- myself.nb_stock_shortage + 1;
				}
			}
		}

		float ratio <- 0;
		if(nb_stock = 0 or nb_stock_shortage = 0){
			ratios <- ratios + 0;
		}
		else{
			ratio <- nb_stock_shortage/nb_stock;
			ratios <- ratios + ratio;
		}

		if(length(ratios) > 72) { // 168 = 7 days
			remove index: 0 from: ratios;
		}

		int i <- 0;
		float sum <- 0.0;
		loop while: i < length(ratios) {
			sum <- sum + ratios[i];
			i <- i + 1;
		}
		ratio <- sum / length(ratios);

		if(ratio = 0){
			color <- rgb(255,255,255,0.1);
		}
		else if(ratio < 0.025){
			color <- rgb(102,194,164,0.5);
		}
		else if(ratio < 0.07){
			color <- rgb(65,174,118,0.8);
		}
		else if(ratio < 0.15){
			color <- rgb(35,139,69,0.8);
		}
		else{
			color <- rgb(0,88,36,0.8);
		}
	}
}