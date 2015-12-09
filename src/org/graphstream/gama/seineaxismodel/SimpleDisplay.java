package org.graphstream.gama.seineaxismodel;

import java.io.File;
import java.io.IOException;

import org.graphstream.graph.ElementNotFoundException;
import org.graphstream.graph.Graph;
import org.graphstream.graph.implementations.SingleGraph;
import org.graphstream.stream.GraphParseException;

public class SimpleDisplay {
	public static void main(String[] args){
		Graph graph = new SingleGraph("");
		try {
			graph.read(System.getProperty("user.dir" )+File.separator+"Analyzed_DGS"+File.separator+"supply_chain_for_centrality.dgs");
		} catch (ElementNotFoundException e) {
			e.printStackTrace();
		} catch (IOException e) {
			e.printStackTrace();
		} catch (GraphParseException e) {
			e.printStackTrace();
		}
		// Remove isolated nodes
		int j = 0;
		while(j<graph.getNodeCount()){
			if(graph.getNode(j).getDegree() == 0){
				graph.removeNode(j);
			}
			else{
				j++;
			}
		}
		graph.display(false);
	}
}
