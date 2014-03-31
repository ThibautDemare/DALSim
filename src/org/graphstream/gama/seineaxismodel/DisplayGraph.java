package org.graphstream.gama.seineaxismodel;

import java.io.BufferedReader;
import java.io.File;
import java.io.IOException;
import java.io.InputStreamReader;
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
		// The list of existing graph
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
		// Which kind of graph we want to display
		boolean[] displays = {
				true, 
				false, 
				false, 
				false, 
				false, 
				false, 
				false, 
				false, 
				false
		};
		// Which final_destination shapefile have been use graph we want to display
		boolean display_final = true;
		boolean[] displays_final = {
				false, 
				false, 
				true, 
				false, 
				false, 
				false
		};
		// Comment/uncomment which graph you want (previously analyzed or not)
		//String folder = "Analyzed_DGS";
		String folder = "DGS";
		
		// If the node alone need to be deleted of the displayed graph
		//boolean deleteNodeAlone = false;
		boolean deleteNodeAlone = true;
		
		for(int i = 0; i<names.length; i++){
			if(displays[i]){
				String name = names[i];
				if(display_final){
					for(int j = 0; j<displays_final.length; j++){
						if(displays_final[j])
							name = name+"_"+destination_files[j];
					}
				}
				Graph graph = new SingleGraph("");
				try {
					graph.read(System.getProperty("user.dir" )+File.separator+"DGS"+File.separator+name+".dgs");
				} catch (ElementNotFoundException e) {
					e.printStackTrace();
				} catch (IOException e) {
					e.printStackTrace();
				} catch (GraphParseException e) {
					e.printStackTrace();
				}

				if(deleteNodeAlone){
					int j = 0;
					while(j<graph.getNodeCount()){
						if(graph.getNode(j).getDegree() == 0){
							graph.removeNode(j);
						}
						else{
							j++;
						}
					}
				}
				
				// Print measures (if it has been computed)
				System.out.println("Number of nodes : "+graph.getNodeCount());				
				System.out.println("Number of edges : "+graph.getEdgeCount());
				if(folder.equals("Analyzed_DGS")){
					System.out.println("Average degree : " + graph.getAttribute("AverageDegree"));
					System.out.println("Density : " + graph.getAttribute("Density"));
					System.out.println("Diameter : " + graph.getAttribute("Diameter"));
					System.out.println("Average clustering coefficients : " + graph.getAttribute("AverageClusteringCoefficients"));
					System.out.println("Degree average deviation : " + graph.getAttribute("DegreeAverageDeviation"));
					updateGraph(graph, "BetweennessCentrality");
				}

				graph.addAttribute("ui.title", names[i]);
				graph.display(true);

				//Ask for a SVG save of the display
				System.out.println("============================");
				System.out.println("Do you want to save the display in SVG? [Y]es / [N]o");
				BufferedReader bufferRead = new BufferedReader(new InputStreamReader(System.in));
				String choice = "";
				try {
					choice = bufferRead.readLine();
				} catch (IOException e) {
					e.printStackTrace();
				}
				if(choice.equals("Y") || choice.equals("y") || choice.equals("Yes") || choice.equals("yes") || choice.equals("YES")){
					graph.addAttribute("ui.screenshot", System.getProperty("user.dir" )+File.separator+"SVG_Screenshots"+File.separator+names[i]+".svg");
					System.out.println("Saved.");
				}
			}
		}
	}
}
