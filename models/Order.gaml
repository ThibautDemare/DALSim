model Order

import "LogisticsServiceProvider.gaml"

species Order schedules: [] {
	int product; // The kind of goods ordered
	float quantity; // the ordered quantity
	Building building; // which building has made the order
	LogisticsServiceProvider logisticsServiceProvider; // the LSP who manages the ordered goods
	int position;// The position in the supply chain
	FinalConsignee fdm; // The FDM who posseses these goods
	Stock reference; // a reference to the stock which suffer of stock shortage
	date stepOrderMade; // when does the order has been made
	string strategy;
}