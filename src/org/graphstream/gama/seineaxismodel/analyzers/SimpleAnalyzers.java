package org.graphstream.gama.seineaxismodel.analyzers;

import java.io.File;
import java.io.IOException;

import org.graphstream.algorithm.BetweennessCentrality;
import org.graphstream.algorithm.Toolkit;
import org.graphstream.graph.Edge;
import org.graphstream.graph.Element;
import org.graphstream.graph.ElementNotFoundException;
import org.graphstream.graph.Graph;
import org.graphstream.graph.Node;
import org.graphstream.graph.implementations.SingleGraph;
import org.graphstream.stream.GraphParseException;

public class SimpleAnalyzers {

	public static void betweennessCentrality(Graph g){
		BetweennessCentrality bcb = new BetweennessCentrality();
		bcb.setUnweighted();
		bcb.setCentralityAttributeName("BetweennessCentrality");
		bcb.init(g);
		bcb.compute();
	}

	/**
	 * Clean a graph deleting all attributes in listAttributesNames
	 * @param g the graph
	 * @param listAttributesNames the list of attribute which must be deleted
	 */
	public static void clearAll(Graph g, String[] listAttributesNames){
		// Remove attributes in nodes
		for(Node n : g.getEachNode()){
			for(String s : listAttributesNames){
				if(n.hasAttribute(s))
					n.removeAttribute(s);
			}
		}

		// Remove attributes in edges
		for(Edge e : g.getEachEdge()){
			for(String s : listAttributesNames){
				if(e.hasAttribute(s))
					e.removeAttribute(s);
			}
		}
	}

	public static void main(String args[]){
		String[] names = {
				"actor", 
				"neighborhood_all", 
				"neighborhood_warehouse", 
				"neighborhood_final_destination", 
				"neighborhood_logistic_provider", 
				"neighborhood_warehouse_final", 
				"neighborhood_logistic_final", 
				"road_network", 
				"supply_chain"
		};
		String[] destination_files = {
				"FinalDestinationManager",
				"FinalDestinationManager_subset_Paris_1",
				"FinalDestinationManager_subset_Paris_20",
				"FinalDestinationManager_subset_Paris_190",
				"FinalDestinationManager_subset_scattered_24",
				"FinalDestinationManager_subset_scattered_592"
		};

		for(String name : names){
			for(String destination_file : destination_files){
				Graph graph = new SingleGraph("");
				try {
					graph.read(System.getProperty("user.dir" )+File.separator+"DGS"+File.separator+name+"_"+destination_file+".dgs");
				} catch (ElementNotFoundException e) {
					// TODO Auto-generated catch block
					e.printStackTrace();
				} catch (IOException e) {
					// TODO Auto-generated catch block
					e.printStackTrace();
				} catch (GraphParseException e) {
					// TODO Auto-generated catch block
					e.printStackTrace();
				}
	
				System.out.println("Analysis of '"+name+"_"+destination_file+"'.");
	
				System.out.println("Number of nodes : "+graph.getNodeCount());
				graph.addAttribute("NodeNumber", graph.getNodeCount());
	
				System.out.println("Number of edges : "+graph.getEdgeCount());
				graph.addAttribute("EdgeNumber", graph.getEdgeCount());
	
				double ade = Toolkit.averageDegree(graph);
				System.out.println("Average degree : " + ade);
				graph.addAttribute("AverageDegree", ade);
	
				double de = Toolkit.density(graph);
				System.out.println("Density : " + de);
				graph.addAttribute("Density", de);
	
				double di = Toolkit.diameter(graph);
				System.out.println("Diameter : " + di);
				graph.addAttribute("Diameter", di);
	
				double acc = Toolkit.averageClusteringCoefficient(graph);
				System.out.println("Average clustering coefficients : " + acc);
				graph.addAttribute("AverageClusteringCoefficients", acc);
	
				double dad = Toolkit.degreeAverageDeviation(graph);
				System.out.println("Degree average deviation : " + dad);
				graph.addAttribute("DegreeAverageDeviation", dad);
	
				System.out.println("Compute degree distribution...");
				graph.addAttribute("DegreeDistribution", Toolkit.degreeDistribution(graph));
	
				System.out.println("Compute betweenness centrality...");
				betweennessCentrality(graph);
	
				System.out.println("Analysis of '"+name+"' ended");
	
				System.out.println("Clear graph...");
				String[] listAttributesNames = {
						"brandes.d",
						"brandes.sigma",
						"brandes.delta",
						"brandes.P"
				};
				System.out.println("Saving data...");
				SimpleAnalyzers.clearAll(graph, listAttributesNames);
	
				try {
					graph.write(System.getProperty("user.dir" )+File.separator+"Analyzed_DGS"+File.separator+graph.getAttribute("name")+".dgs");
				} catch (IOException e) {
					// TODO Auto-generated catch block
					e.printStackTrace();
				}
			}
		}
		System.out.println("All analysis have been done");
	}
}
