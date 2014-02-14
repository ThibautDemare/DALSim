package org.graphstream.gama.seineaxismodel;

import java.io.IOException;
import java.net.UnknownHostException;

import org.graphstream.stream.netstream.NetStreamReceiver;
import org.graphstream.stream.netstream.NetStreamSender;

public class MainGraphAnalyzer {

	public static void main(String[] args) throws InterruptedException, UnknownHostException, IOException {
		// Receive event
		boolean use_viewer = true;
		
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
		
		if(use_viewer){
			new SimpleNetStreamViewer(receiver1, true);
			new SimpleNetStreamViewer(receiver2, true);
			new SimpleNetStreamViewer(receiver3, true);
			new SimpleNetStreamViewer(receiver4, true);
			new SimpleNetStreamViewer(receiver5, true);
			new SimpleNetStreamViewer(receiver6, true);
			new SimpleNetStreamViewer(receiver7, true);
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
				// A sleep to avoid an overload of the CPU
				Thread.sleep(1000);
			}
		}
	}
}