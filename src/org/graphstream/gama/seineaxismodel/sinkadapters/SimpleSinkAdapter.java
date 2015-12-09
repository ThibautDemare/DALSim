package org.graphstream.gama.seineaxismodel.sinkadapters;

import java.io.File;
import java.io.IOException;

import org.graphstream.graph.Graph;
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
		// Save the graph
		try {
			graph.write(System.getProperty("user.dir" )+File.separator+"DGS"+File.separator+graph.getAttribute("name")+".dgs");
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
		System.out.println("The graph '"+graph.getAttribute("name")+"' has been saved.");
	}

	public Graph getGraph() {
		return graph;
	}

	public void setGraph(Graph graph) {
		this.graph = graph;
	}
}