package org.graphstream.gama.seineaxismodel.analyzers;

import org.graphstream.algorithm.APSP;
import org.graphstream.algorithm.Centroid;
import org.graphstream.algorithm.Eccentricity;
import org.graphstream.graph.Edge;
import org.graphstream.graph.Graph;
import org.graphstream.graph.Node;
import org.graphstream.graph.implementations.SingleGraph;
import org.graphstream.stream.SinkAdapter;
import org.graphstream.stream.netstream.NetStreamReceiver;

public class SimpleSinkAdapter extends SinkAdapter {
	
	private Graph graph;

	public SimpleSinkAdapter(NetStreamReceiver receiver) {
		graph = new SingleGraph("test", false, false);
		receiver.getDefaultStream().addSink(graph);
		receiver.getDefaultStream().addSink(this);
	}

	@Override
	public void stepBegins(String sourceId, long timeId, double step) {
		
	}

	public Graph getGraph() {
		return graph;
	}

	public void setGraph(Graph graph) {
		this.graph = graph;
	}
}