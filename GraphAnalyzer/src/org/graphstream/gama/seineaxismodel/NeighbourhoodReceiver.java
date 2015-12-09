package org.graphstream.gama.seineaxismodel;

import java.io.IOException;
import java.net.UnknownHostException;

import org.graphstream.gama.seineaxismodel.sinkadapters.SimpleSinkAdapter;
import org.graphstream.stream.netstream.NetStreamReceiver;

public class NeighbourhoodReceiver {
	public static void main(String[] args) throws InterruptedException, UnknownHostException, IOException {
		
		NetStreamReceiver receiver = new NetStreamReceiver(2003);
		new SimpleSinkAdapter(receiver);
		
		// We don't use the viewer so the events are not pump. We need to do it manually.
		while(true){
			receiver.getDefaultStream().pump();
			// A sleep to avoid an overload of the CPU
			Thread.sleep(1000);
		}
	}
}
