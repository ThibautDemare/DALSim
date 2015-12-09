package org.graphstream.gama.seineaxismodel;

import java.io.File;
import java.io.IOException;
import java.net.UnknownHostException;

import org.graphstream.gama.seineaxismodel.sinkadapters.SimpleSinkAdapter;
import org.graphstream.graph.implementations.SingleGraph;
import org.graphstream.stream.file.FileSinkDGS;
import org.graphstream.stream.netstream.NetStreamReceiver;
import org.graphstream.stream.netstream.NetStreamSender;

public class MainReceiver {

	public static void main(String[] args) throws InterruptedException, UnknownHostException, IOException {
		// Receive event
		boolean use_viewer = false;
		
		NetStreamReceiver receiver1 = new NetStreamReceiver(2001);
		new SimpleSinkAdapter(receiver1);
		
		NetStreamReceiver receiver2 = new NetStreamReceiver(2002);
		new SimpleSinkAdapter(receiver2);
		
		NetStreamReceiver receiver3 = new NetStreamReceiver(2003);
		new SimpleSinkAdapter(receiver3);
		
		NetStreamReceiver receiver4 = new NetStreamReceiver(2004);
		new SimpleSinkAdapter(receiver4);
		
		NetStreamReceiver receiver5 = new NetStreamReceiver(2005);
		new SimpleSinkAdapter(receiver5);
		
		NetStreamReceiver receiver6 = new NetStreamReceiver(2006);
		new SimpleSinkAdapter(receiver6);
		
		NetStreamReceiver receiver7 = new NetStreamReceiver(2007);
		new SimpleSinkAdapter(receiver7);
		
		NetStreamReceiver receiver8 = new NetStreamReceiver(2008);
		new SimpleSinkAdapter(receiver8);
		
		NetStreamReceiver receiver9 = new NetStreamReceiver(2009);
		//new SimpleSinkAdapter(receiver9);
		SingleGraph graph = new SingleGraph("test", false, false);
		receiver9.getDefaultStream().addSink(graph);
		FileSinkDGS fileSink = new FileSinkDGS();
		graph.addSink(fileSink);
		String fileName = "C:"+File.separator+"Users"+File.separator+"Thibaut"+File.separator+"Desktop"+File.separator
					+"Th�se"+File.separator+"Workspaces"+File.separator+"Gama_model"+File.separator+"SeineAxisModel"
					+File.separator+"results"+File.separator+"DGS"+File.separator+"supply_chain_for_centrality.dgs";
		try {
			fileSink.begin(fileName);
		} catch (IOException e) {
			e.printStackTrace();
		}
		
		if(use_viewer){
			new SimpleNetStreamViewer(receiver1, true);
			new SimpleNetStreamViewer(receiver2, true);
			new SimpleNetStreamViewer(receiver3, true);
			new SimpleNetStreamViewer(receiver4, true);
			new SimpleNetStreamViewer(receiver5, true);
			new SimpleNetStreamViewer(receiver6, true);
			new SimpleNetStreamViewer(receiver7, true);
			new SimpleNetStreamViewer(receiver8, false);
			new SimpleNetStreamViewer(receiver9, true);
		}
		else{
			// We don't use the viewer so the events are not pump. We need to do it manually.
			while(true){
				receiver1.getDefaultStream().pump();
				receiver2.getDefaultStream().pump();
				receiver3.getDefaultStream().pump();
				receiver4.getDefaultStream().pump();
				receiver5.getDefaultStream().pump();
				receiver6.getDefaultStream().pump();
				receiver7.getDefaultStream().pump();
				receiver8.getDefaultStream().pump();
				receiver9.getDefaultStream().pump();
				try {
					fileSink.flush();
				} catch (IOException e) {
					e.printStackTrace();
				}
				// A sleep to avoid an overload of the CPU
				Thread.sleep(1000);
			}
		}
	}
}