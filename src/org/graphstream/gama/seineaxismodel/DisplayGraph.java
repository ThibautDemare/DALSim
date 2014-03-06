package org.graphstream.gama.seineaxismodel;

import java.io.File;
import java.io.IOException;
import java.util.Collection;

import org.graphstream.algorithm.Toolkit;
import org.graphstream.graph.Element;
import org.graphstream.graph.ElementNotFoundException;
import org.graphstream.graph.Graph;
import org.graphstream.graph.Node;
import org.graphstream.graph.implementations.SingleGraph;
import org.graphstream.stream.GraphParseException;

public class DisplayGraph {

	public static void updateNode(Graph g, String att) {
		updateElement(g.getEachNode(), att);
	}

	public static void updateEdge(Graph g, String att) {
		updateElement(g.getEachEdge(), att);
	}

	public static void updateElement( Iterable<? extends Element> elements, String att) {
		Double min = Double.POSITIVE_INFINITY;
		Double max = Double.NEGATIVE_INFINITY;
		// Obtain the maximum and minimum values.
		for(Element e: elements) {
			double passes = e.getNumber(att);
			max = Math.max(max, passes);
			min = Math.min(min, passes);
		}
		// Set the colors.
		for(Element e: elements) {
			if(e.hasAttribute(att)){
				double passes = e.getNumber(att);
				double color;
				if(max==min)
					color = 0.;
				else
					color = ((passes-min)/(max-min));
				e.setAttribute("ui.color", color);
				if(e instanceof Node)
					e.changeAttribute("ui.style", "fill-mode: dyn-plain; fill-color: blue, red; size: 4px;");
				else
					e.changeAttribute("ui.style", "fill-mode: dyn-plain; fill-color: blue, red; size: 1px;");
			}
			else{
				if(e instanceof Node)
					e.changeAttribute("ui.style", "fill-color: blue, red; size: 4px;");
				else
					e.changeAttribute("ui.style", "fill-color: blue, red; size: 1px;");
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
		boolean[] displays = {
				true, 
				true, 
				true, 
				true, 
				true, 
				true, 
				true, 
				false, 
				true
		};
		String folder = "Analyzed_DGS";
		//String folder = "DGS";
		for(int i = 0; i<names.length; i++){
			Graph graph = new SingleGraph("");
			try {
				graph.read(System.getProperty("user.dir" )+File.separator+folder+File.separator+names[i]+".dgs");
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
			updateGraph(graph, "BetweennessCentrality");
			graph.display(displays[i]);
			graph.addAttribute("ui.title", names[i]);
		}
	}
}
