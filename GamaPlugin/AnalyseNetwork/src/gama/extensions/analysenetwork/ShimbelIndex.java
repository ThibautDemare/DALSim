package gama.extensions.analysenetwork;

import java.util.ArrayList;
import java.util.Collections;

import org.graphstream.algorithm.APSP;
import org.graphstream.algorithm.Algorithm;
import org.graphstream.algorithm.Dijkstra;
import org.graphstream.algorithm.APSP.APSPInfo;
import org.graphstream.graph.Graph;
import org.graphstream.graph.Node;
import org.graphstream.graph.Path;

public class ShimbelIndex implements Algorithm {
/*
http://www.isprs.org/proceedings/XXXV/congress/comm7/papers/199.pdf
 */
	protected Graph graph;
	protected boolean isDirected = true;
	protected String weightAttributeName = "length";
	protected Dijkstra dijkstra;
	
	@Override
	public void init(Graph graph) {
		this.graph = graph;
	}

	/**
	 * Compute the Shimbel index just for every nodes. To do so, it uses the APSP algorithm.
	 */
	@Override
	public void compute() {
		APSP apsp = new APSP();
        apsp.init(graph);
        apsp.setDirected(isDirected);
        apsp.setWeightAttributeName(weightAttributeName);
        apsp.compute();
	}

	/**
	 * Compute the Shimbel index just for one source node. To do so, it uses the Dijkstra's algorithm.
	 * @param n the source node
	 */
	public void compute(Node n){
		dijkstra = new Dijkstra(Dijkstra.Element.EDGE, "dijkstra_result", weightAttributeName);
		dijkstra.init(graph);
		dijkstra.setSource(n);
		dijkstra.compute();
	}

	public void compute(Node n, ArrayList<Node> destinations){
		// TODO
	}

	public double getNodeMeasure(Node n, ArrayList<Node> destinations){
		double nodeMeasure = 0.0;
        for(Node dest : destinations){
        	if(dest != n){
        		Path p = dijkstra.getPath(dest);
        		nodeMeasure += p.getPathWeight(weightAttributeName);
        	}
        }
		return nodeMeasure;
	}

	public double getNodeMeasure(Node n){
		double nodeMeasure = 0.0;
        for(Node dest : graph){
        	if(dest != n){
        		Path p = dijkstra.getPath(dest);
        		nodeMeasure += p.getPathWeight(weightAttributeName);
        	}
        }
		return nodeMeasure;
	}
	
	public String getWeightAttributeName() {
		return weightAttributeName;
	}

	public void setWeightAttributeName(String weightAttributeName) {
		this.weightAttributeName = weightAttributeName;
	}
}
