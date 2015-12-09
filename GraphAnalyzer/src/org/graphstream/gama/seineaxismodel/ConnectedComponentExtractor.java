package org.graphstream.gama.seineaxismodel;

import java.io.BufferedReader;
import java.io.File;
import java.io.IOException;
import java.io.InputStreamReader;
import java.util.ArrayList;
import java.util.Iterator;

import org.graphstream.algorithm.ConnectedComponents;
import org.graphstream.algorithm.ConnectedComponents.ConnectedComponent;
import org.graphstream.graph.Edge;
import org.graphstream.graph.ElementNotFoundException;
import org.graphstream.graph.Graph;
import org.graphstream.graph.Node;
import org.graphstream.graph.implementations.SingleGraph;
import org.graphstream.stream.GraphParseException;
import org.graphstream.ui.swingViewer.Viewer;

public class ConnectedComponentExtractor {
	public static void main(String args[]){
		// Init the graph
		Graph graph = new SingleGraph("");
		try {
			graph.read(System.getProperty("user.dir" )+File.separator+"DGS"+File.separator+"neighborhood_warehouse_with_region_3000.0.dgs");
		} catch (ElementNotFoundException e) {
			e.printStackTrace();
		} catch (IOException e) {
			e.printStackTrace();
		} catch (GraphParseException e) {
			e.printStackTrace();
		}
		graph.display(false);

		// Compute the different connected components
		ConnectedComponents ccs = new ConnectedComponents();
		ccs.init(graph);
		ccs.setCountAttribute("connectedComponent");
		ccs.compute();

		/*
		 *  Extract the five biggest connected component
		 */
		// init vars...
		int sizeCC1 = 0;
		int sizeCC2 = 0;
		int sizeCC3 = 0;
		int sizeCC4 = 0;
		int sizeCC5 = 0;
		ConnectedComponent[] bestCC = new ConnectedComponent[5];
		bestCC[0] = null;
		bestCC[1] = null;
		bestCC[2] = null;
		bestCC[3] = null;
		bestCC[4] = null;
		
		// Determine the five biggest
		Iterator<ConnectedComponent> it = ccs.iterator();
		while(it.hasNext()){
			int i = 0;
			ConnectedComponent cc = it.next();
			for(Node n : cc.getEachNode()){
				i++;
			}
			if(sizeCC1 < i){
				sizeCC5 = sizeCC4;
				sizeCC4 = sizeCC3;
				sizeCC3 = sizeCC2;
				sizeCC2 = sizeCC1;
				sizeCC1 = i;
				bestCC[4] = bestCC[3];
				bestCC[3] = bestCC[2];
				bestCC[2] = bestCC[1];
				bestCC[1] = bestCC[0];
				bestCC[0] = cc;
			}
			else if(sizeCC2 < i){
				sizeCC5 = sizeCC4;
				sizeCC4 = sizeCC3;
				sizeCC3 = sizeCC2;
				sizeCC2 = i;
				bestCC[4] = bestCC[3];
				bestCC[3] = bestCC[2];
				bestCC[2] = bestCC[1];
				bestCC[1] = cc;
			}
			else if(sizeCC3 < i){
				sizeCC5 = sizeCC4;
				sizeCC4 = sizeCC3;
				sizeCC3 = i;
				bestCC[4] = bestCC[3];
				bestCC[3] = bestCC[2];
				bestCC[2] = cc;
			}
			else if(sizeCC4 < i){
				sizeCC5 = sizeCC4;
				sizeCC4 = i;
				bestCC[4] = bestCC[3];
				bestCC[3] = cc;
			}
			else if(sizeCC5 < i){
				sizeCC5 = i;
				bestCC[4] = cc;
			}
		}
		
		// For each of these biggest connected components, extract them into another graph in order to save their display
		Graph[] subgraphs = new SingleGraph[5];
		for(int i = 0; i < bestCC.length; i++){
			ConnectedComponent cc = bestCC[i];
			subgraphs[i] = new SingleGraph("subgraph_"+i, false, true);
			
			int nb_1 = 0;
			int nb_2 = 0;
			int nb_3 = 0;
			int nb_4 = 0;
			int nb_5 = 0;
			
			// color the nodes according to which region they belong to
			for(Node n : cc){
				String style = "";
				Node no = graph.getNode(n.getId());
				if(no.hasAttribute("region")){
					String val = ""+no.getAttribute("region");
					if(val.equals("0")){
						style += "fill-color: DeepPink;";
						nb_2++;
					}
					else if(val.equals("1")){ // Basse-Normandie
						style += "fill-color: CornflowerBlue ;";
						nb_1++;
					}
					else if(val.equals("2")){ // Haute-Normandie
						style += "fill-color: DarkViolet;";
						nb_2++;
					}
					else if(val.equals("3")){ // Centre
						style += "fill-color: LimeGreen;";
						nb_3++;
					}
					else if(val.equals("4")){ // Picardie
						style += "fill-color: DarkOrange;";
						nb_4++;
					}
					else if(val.equals("5")){ // IDF
						style += "fill-color: LightSlateGray;";
						nb_5++;
					}
					no.addAttribute("ui.style", style+"size: 10px;");
					subgraphs[i].addNode(n.getId()).addAttribute("ui.style", no.getAttribute("ui.style"));
				}
			}

			System.out.println("Graphe "+i+" : IDF = "+nb_5+", Haute-Normandie = "+nb_2+", Basse_Normandie = "+nb_1+", Picardie = "+nb_4+", Centre = "+nb_3);
			for(Edge e : cc.getEachEdge()){
				subgraphs[i].addEdge(e.getId(), e.getNode0().getId(), e.getNode1().getId());
			}
			subgraphs[i].display(true);
			
			// Remove the nodes of this component in the original graph to clear it
			for(Node n : subgraphs[i])
				graph.removeNode(n.getId());
			
			//Ask for a SVG save of the display
			System.out.println("============================");
			System.out.println("Do you want to save the display of the connected component in SVG and DGS? [Y]es / [N]o");
			BufferedReader bufferRead = new BufferedReader(new InputStreamReader(System.in));
			String choice = "";
			try {
				choice = bufferRead.readLine();
				if(choice.equals("Y") || choice.equals("y") || choice.equals("Yes") || choice.equals("yes") || choice.equals("YES")){
					subgraphs[i].write(System.getProperty("user.dir" )+File.separator+"ConnectedComponents"+File.separator+"subgraph_"+i+".dgs");
					subgraphs[i].addAttribute("ui.screenshot", System.getProperty("user.dir" )+File.separator+"ConnectedComponents"+File.separator+"subgraph_"+i+".svg");
					System.out.println("Saved.");
				}
				Thread.sleep(1000);
			} catch (Exception e) {
				e.printStackTrace();
			}

		}

	}
	
}
