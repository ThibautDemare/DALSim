package org.graphstream.gama.seineaxismodel;

import java.awt.Color;
import java.io.BufferedReader;
import java.io.File;
import java.io.IOException;
import java.io.InputStreamReader;

import org.graphstream.graph.Element;
import org.graphstream.graph.Graph;
import org.graphstream.graph.Node;
import org.graphstream.graph.implementations.DefaultGraph;
import org.graphstream.stream.SinkAdapter;
import org.graphstream.stream.file.FileSource;
import org.graphstream.stream.file.FileSourceFactory;

public class DisplayDynamicGraph {
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
			if(passes > 0 && passes <min)
				min = passes;
		}
		// Set the colors.
		for(Element e: elements) {
			if(e.hasAttribute(att)){
				double passes = e.getNumber(att);
				double color;
				if(max==min)
					color = 1.;
				else
					color = ((passes-min)/(max-min));
				Color c = Color.getHSBColor((float)(1./(100.*(color))), 0.8f, 0.8f);
				String s = "rgb("+c.getRed()+", "+c.getGreen()+", "+c.getBlue()+");";
				if(e instanceof Node)
					e.changeAttribute("ui.style", "fill-color:"+s+" size: 1px;");
				else
					e.changeAttribute("ui.style", "fill-color:"+s+" size: 3px;");
				
			}
			else{
				if(e instanceof Node)
					e.changeAttribute("ui.style", "fill-color: black; size: 1px;");
				else
					e.changeAttribute("ui.style", "fill-color: black; size: 1px;");
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
	
	public static void main(String ... args) throws IOException {
		String filePath = "C:"+File.separator+"Users"+File.separator+"Thibaut"+File.separator+"Desktop"+File.separator
				+"Thèse"+File.separator+"Workspaces"+File.separator+"Gama_model"+File.separator+"SeineAxisModel"
				+File.separator+"results"+File.separator+"DGS"+File.separator+"Network_step638.dgs";
		Graph g = new DefaultGraph("g");
		g.setAutoCreate(true);
		g.setStrict(false);
		g.display(false);
		
		FileSource fs = FileSourceFactory.sourceFor(filePath);

		fs.addSink(g);
		
		GraphListener gl = new DisplayDynamicGraph.GraphListener();
		g.addSink(gl);
		
		try {
			fs.begin(filePath);
			int i = 0;
			while (fs.nextStep()) {
				if(i > 0){
					//updateGraph(g, "current_marks");
					//updateGraph(g, "cumulative_marks");
					//updateGraph(g, "current_nb_agents");
					updateGraph(g, "cumulative_nb_agents");
				}
				else{
					for(Node n : g){
						n.setAttribute("y", n.getNumber("y")*-1);
					}
				}
				//Ask for a SVG save of the display
				System.out.println("============================");
				System.out.println("Current step : "+gl.currentStep);
				System.out.println("Do you want to save the display in SVG? [Y]es");
				BufferedReader bufferRead = new BufferedReader(new InputStreamReader(System.in));
				String choice = "";
				try {
					choice = bufferRead.readLine();
				} catch (IOException e) {
					e.printStackTrace();
				}
				if(choice.equals("Y") || choice.equals("y") || choice.equals("Yes") || choice.equals("yes") || choice.equals("YES")){
					g.addAttribute("ui.screenshot", System.getProperty("user.dir" )+File.separator+"SVG_Screenshots"+File.separator+"step_"+ gl.currentStep +".svg");
					System.out.println("Saved.");
				}
				i++;
			}
			System.out.println("End. There was "+i+" steps");
		} catch( IOException e) {
			e.printStackTrace();
		}
		
		try {
			fs.end();
		} catch( IOException e) {
			e.printStackTrace();
		} finally {
			fs.removeSink(g);
		}
	}
	
	protected static class GraphListener extends SinkAdapter {
		protected double currentStep;
		public void stepBegins(String sourceId, long timeId, double step) {
			currentStep = step;
		}
		
	}
}
