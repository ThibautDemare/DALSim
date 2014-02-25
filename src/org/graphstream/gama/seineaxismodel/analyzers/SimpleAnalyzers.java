package org.graphstream.gama.seineaxismodel.analyzers;

import java.io.File;
import java.io.IOException;

import org.graphstream.algorithm.BetweennessCentrality;
import org.graphstream.algorithm.Toolkit;
import org.graphstream.graph.Edge;
import org.graphstream.graph.ElementNotFoundException;
import org.graphstream.graph.Graph;
import org.graphstream.graph.Node;
import org.graphstream.graph.implementations.SingleGraph;
import org.graphstream.stream.GraphParseException;

public class SimpleAnalyzers {

	public static void updateNode(Graph g, String att) {
		double min = Double.POSITIVE_INFINITY;
		double max = Double.NEGATIVE_INFINITY;

		// Obtain the maximum and minimum values.
		for(Node n: g.getEachNode()) {
			double passes = n.getNumber(att);
			max = Math.max(max, passes);
			min = Math.min(min, passes);
		}

		// Set the colors.
		for(Node n: g.getEachNode()) {
			if(n.hasAttribute(att)){
				double passes = n.getNumber(att);
				double color;
				if(max==min)
					color = 0.;
				else
					color = ((passes-min)/(max-min));
				n.setAttribute("ui.color", color);
				n.changeAttribute("ui.style", "fill-mode: dyn-plain; fill-color: blue, red; size: 4px;");
			}
		}
	}

	public static void updateEdge(Graph g, String att) {
		Double min = Double.POSITIVE_INFINITY;
		Double max = Double.NEGATIVE_INFINITY;
		// Obtain the maximum and minimum values.
		for(Edge e: g.getEachEdge()) {
			double passes = e.getNumber(att);
			max = Math.max(max, passes);
			min = Math.min(min, passes);
		}

		// Set the colors.
		for(Edge e: g.getEachEdge()) {
			if(e.hasAttribute(att)){
				double passes = e.getNumber(att);
				double color;
				if(max==min)
					color = 0.;
				else
					color = ((passes-min)/(max-min));
				e.setAttribute("ui.color", color);
				e.changeAttribute("ui.style", "fill-mode: dyn-plain; fill-color: blue, red; size: 1px;");
			}
		}
	}

	/**
	 * Update the coloration of the elements of the graph
	 */
	public static void updateGraph(Graph g, String att) {
		updateNode(g, att);
		updateEdge(g, att);
	}

	public static void betweennessCentrality(Graph g){
		BetweennessCentrality bcb = new BetweennessCentrality();
		bcb.setUnweighted();
		bcb.setCentralityAttributeName("BetweennessCentrality");
		bcb.init(g);
		bcb.compute();
	}

	public static void main(String args[]){
		//String name = "actor";boolean display = true;
		String name = "neighborhood_all";boolean display = true;
		//String name = "neighborhood_warehouse";boolean display = true;
		//String name = "neighborhood_final_destination";boolean display = true;
		//String name = "neighborhood_logistic_provider";boolean display = true;
		//String name = "neighborhood_warehouse_final";boolean display = true;
		//String name = "neighborhood_logistic_final";boolean display = true;
		//String name = "road_network";boolean display = false;
		//String name = "supply_chain";boolean display = true;

		Graph graph = new SingleGraph("");
		try {
			graph.read(System.getProperty("user.dir" )+File.separator+"DGS"+File.separator+name+".dgs");
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
		
		System.out.println("Average degree : " + Toolkit.averageDegree(graph));
		System.out.println("Density : " + Toolkit.density(graph));
		System.out.println("Diameter : " + Toolkit.diameter(graph));
		System.out.println("Average clustering coefficients : " + Toolkit.averageClusteringCoefficient(graph));
		System.out.println("Start computation of betweenness centrality");
		betweennessCentrality(graph);
		updateGraph(graph, "BetweennessCentrality");
		graph.display(display);
	}
}
