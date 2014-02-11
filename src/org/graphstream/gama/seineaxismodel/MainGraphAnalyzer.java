package org.graphstream.gama.seineaxismodel;

import java.io.IOException;
import java.net.UnknownHostException;

import org.graphstream.stream.netstream.NetStreamReceiver;
import org.graphstream.stream.netstream.NetStreamSender;

public class MainGraphAnalyzer {

	public static void main(String[] args) throws InterruptedException, UnknownHostException, IOException {
		// Receive event
		
		NetStreamReceiver receiver1 = new NetStreamReceiver(2001);
		new SimpleNetStreamViewer(receiver1, true);
		new SimpleSinkAdapter(receiver1);
		
		NetStreamReceiver receiver2 = new NetStreamReceiver(2002);
		new SimpleNetStreamViewer(receiver2, true);
		new SimpleSinkAdapter(receiver2);
		
		NetStreamReceiver receiver3 = new NetStreamReceiver(2003);
		new SimpleNetStreamViewer(receiver3, true);
		new SimpleSinkAdapter(receiver3);
		
		NetStreamReceiver receiver4 = new NetStreamReceiver(2004);
		new SimpleNetStreamViewer(receiver4, true);
		new SimpleSinkAdapter(receiver4);
		
		NetStreamReceiver receiver5 = new NetStreamReceiver(2005);
		new SimpleNetStreamViewer(receiver5, true);
		new SimpleSinkAdapter(receiver5);
		
		NetStreamReceiver receiver6 = new NetStreamReceiver(2006);
		new SimpleNetStreamViewer(receiver6, true);
		new SimpleSinkAdapter(receiver6);
		
		NetStreamReceiver receiver7 = new NetStreamReceiver(2007);
		new SimpleNetStreamViewer(receiver7, true);
		new SimpleSinkAdapter(receiver7);
		
	}

}