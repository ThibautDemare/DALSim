package org.graphstream.gama.seineaxismodel.analyzers;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.PrintWriter;
import java.io.UnsupportedEncodingException;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Collections;
import java.util.Comparator;
import java.util.Iterator;

import org.graphstream.algorithm.BetweennessCentrality;
import org.graphstream.algorithm.ConnectedComponents;
import org.graphstream.algorithm.ConnectedComponents.ConnectedComponent;
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

	public static void buildCSV(Graph graph, String file) throws FileNotFoundException, UnsupportedEncodingException{
		PrintWriter writer_degreeDistribution = new PrintWriter(System.getProperty("user.dir" )+File.separator+"CSV_Graphs_Measures"+File.separator+"degreeDistribution_"+file+".csv", "UTF-8");
		int[] degreeDistribution = (int[])graph.getAttribute("DegreeDistribution");
		for(int i = 0; i < degreeDistribution.length; i++){
			writer_degreeDistribution.println(i+"; "+degreeDistribution[i]);
		}
		writer_degreeDistribution.close();

		PrintWriter writer_betweennessCentrality = new PrintWriter(System.getProperty("user.dir" )+File.separator+"CSV_Graphs_Measures"+File.separator+"betweennessCentrality_"+file+".csv", "UTF-8");
		ArrayList<Node> nodes = new ArrayList<Node>(graph.getNodeSet());
		Collections.sort(nodes, new BetweennessComparator());
		for(int i = 0; i < nodes.size() ; i++){
			writer_betweennessCentrality.println(i+"; "+nodes.get(i).getNumber("BetweennessCentrality"));
		}
		writer_betweennessCentrality.close();
		
		PrintWriter writer_sizeConnectedComponentsDistribution = new PrintWriter(System.getProperty("user.dir" )+File.separator+"CSV_Graphs_Measures"+File.separator+"sizeConnectedComponentsDistribution_"+file+".csv", "UTF-8");
		int[] sizeConnectedComponentsDistribution = graph.getAttribute("SizeConnectedComponentsDistribution");
		for(int i = 0; i < sizeConnectedComponentsDistribution.length; i++){
			writer_sizeConnectedComponentsDistribution.println(i+"; "+sizeConnectedComponentsDistribution[i]);
		}
		writer_sizeConnectedComponentsDistribution.close();
		
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

				System.out.println("Compute distribution of size of connected components");
				ConnectedComponents ccs = new ConnectedComponents();
				ccs.init(graph);
				ccs.setCountAttribute("connectedComponent");
				ccs.compute();
				// Get size of each connected components
				ArrayList<Integer> sizeConnectedComponents = new ArrayList<Integer>();
				Iterator<ConnectedComponent> it = ccs.iterator();
				int maxSize = 0;
				while(it.hasNext()){
					int i = 0;
					ConnectedComponent cc = it.next();
					for(Node n : cc.getEachNode()){
						i++;
					}
					if(maxSize < i)
						maxSize = i;
					sizeConnectedComponents.add(i);
				}
				// Compute distribution
				int[] connectedComponentsDistribution = new int[maxSize+1];
				for(int i = 0; i<sizeConnectedComponents.size(); i++){
					connectedComponentsDistribution[sizeConnectedComponents.get(i)]++;
				}
				graph.addAttribute("SizeConnectedComponentsDistribution", connectedComponentsDistribution);
				
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
					buildCSV(graph, name+"_"+destination_file);
				} catch (FileNotFoundException e1) {
					// TODO Auto-generated catch block
					e1.printStackTrace();
				} catch (UnsupportedEncodingException e1) {
					// TODO Auto-generated catch block
					e1.printStackTrace();
				}

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

	public static class BetweennessComparator implements Comparator<Element>{
		public BetweennessComparator(){
			super();
		}

		public int compare(Element n1, Element n2) {
			double nb1 = n1.getNumber("BetweennessCentrality");
			double nb2 = n2.getNumber("BetweennessCentrality");
			if(nb1>nb2)
				return -1;
			else if(nb1 == nb2)
				return 0;
			else
				return 1;
		}

	}
}
