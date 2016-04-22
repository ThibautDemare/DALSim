package org.graphstream.gama.seineaxismodel;

import java.io.BufferedReader;
import java.io.File;
import java.io.IOException;
import java.io.InputStreamReader;

import org.graphstream.graph.ElementNotFoundException;
import org.graphstream.graph.Graph;
import org.graphstream.graph.implementations.SingleGraph;
import org.graphstream.stream.GraphParseException;

public class SimpleDisplay {
	public static void main(String[] args){
		Graph graph = new SingleGraph("");

		try {
			graph.read(System.getProperty("user.dir" )+File.separator+"Analyzed_DGS"+File.separator+"neighborhood_actor_with_region3000.dgs");
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

		//Ask for a SVG save of the display
		System.out.println("============================");
		System.out.println("Do you want to save the display of the connected component in SVG and DGS? [Y]es / [N]o");
		BufferedReader bufferRead = new BufferedReader(new InputStreamReader(System.in));
		String choice = "";
		try {
			choice = bufferRead.readLine();
			if(choice.equals("Y") || choice.equals("y") || choice.equals("Yes") || choice.equals("yes") || choice.equals("YES")){
				//graph.write(System.getProperty("user.dir" )+File.separator+"ConnectedComponents"+File.separator+"subgraph_"+i+".dgs");
				graph.addAttribute("ui.screenshot", System.getProperty("user.dir" )+File.separator+"ConnectedComponents"+File.separator+"subgraph_0.svg");
				System.out.println("Saved.");
			}
			Thread.sleep(1000);
		} catch (Exception e) {
			e.printStackTrace();
		}
	}
}
