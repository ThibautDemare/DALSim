package org.graphstream.gama.seineaxismodel.sinkadapters;

import java.io.IOException;

import org.graphstream.graph.Graph;
import org.graphstream.graph.implementations.SingleGraph;
import org.graphstream.stream.SinkAdapter;
import org.graphstream.stream.netstream.NetStreamReceiver;

public class NeighborhoodSinkAdapater extends SinkAdapter {
	
	private Graph graph;

	public NeighborhoodSinkAdapater(NetStreamReceiver receiver) {
		graph = new SingleGraph("test", false, false);
		receiver.getDefaultStream().addSink(graph);
		receiver.getDefaultStream().addSink(this);
	}

	@Override
	public void stepBegins(String sourceId, long timeId, double step) {
		// Save the graph
		try {
			graph.write(graph.getAttribute("name")+".dgs");
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
	}

	public Graph getGraph() {
		return graph;
	}

	public void setGraph(Graph graph) {
		this.graph = graph;
	}
}
