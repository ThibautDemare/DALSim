package org.graphstream.gama.seineaxismodel.sinkadapters;

import java.io.File;
import java.io.IOException;
import java.util.Iterator;
import org.graphstream.algorithm.networksimplex.NetworkSimplex;
import org.graphstream.graph.Edge;
import org.graphstream.graph.Graph;
import org.graphstream.graph.Node;
import org.graphstream.graph.implementations.SingleGraph;
import org.graphstream.stream.SinkAdapter;
import org.graphstream.stream.netstream.NetStreamReceiver;

public class OtherSinkAdapter extends SinkAdapter {
	private Graph graph;
	NetworkSimplex ns;	 
	boolean b1 = true;

	public OtherSinkAdapter(NetStreamReceiver receiver) {
		graph = new SingleGraph("test", false, false);
		receiver.getDefaultStream().addSink(graph);
		receiver.getDefaultStream().addSink(this);
	}

	@Override
	public void stepBegins(String sourceId, long timeId, double step) {

		graph.stepBegins(timeId);

		for(Edge e : graph.getEachEdge()){
			e.removeAttribute("ui.class");
			e.removeAttribute("ui.hide");
			e.removeAttribute("ui.stylesheet");
		}

		if(b1 == true){ // Cette étape est effectuée uniquement au premier step
			b1 = false;

			constructGraph();// Appel de la méthode pour la construction du graphe initial

			ns = new NetworkSimplex("supply", "capacity", "cost"); // Création d'une instance NetworkSimplex

			ns.init(graph); // Initialisation du NetworkSimplex avec le graphe initial

			graph.display(false);
		} 


		// Aux steps suivants 

		computeProviderSupply();//l'offre chez le fournisseur est recalculée.

		ns.init(graph);
		ns.compute();



		String stylesheet = "edge { size: 1px; stroke-width: 1px; stroke-mode: plain;} " +
				"edge.result{ size: 2px; fill-color: blue; stroke-width: 1px; stroke-mode: plain; }" +
				"edge.notresult{ size: 0px; fill-color: white; }";
		graph.addAttribute("ui.stylesheet", stylesheet);

		/*try {
			Thread.sleep(1000);

		} catch (InterruptedException e1) {
			// TODO Auto-generated catch block
			e1.printStackTrace();
		}/**/



		System.out.println(ns.getSolutionStatus());// Affiche le status de la solution du NetworkSimplex 
		int cost = (int) ns.getSolutionCost();
		System.out.println("Coût du flot : " + cost); // Affiche la valeur du cout du flot 


		Iterator<Edge> it = graph.getEdgeIterator();		
		while (it.hasNext()) {
			Edge e = it.next();
			int f = ns.getFlow(e);
			if (f == 0) {
				e.addAttribute("ui.hide", true); // cacher les arcs de flot nul
			} else {
				e.addAttribute("ui.label", f); // Afficher le flot sur les autres
				e.addAttribute("ui.class", "result");
				//System.out.println("Flot sur l'arc: " +e.getNode0()+e.getNode1()+":" + f);
			}
		}
		// graph.display(false);
		for (Node n : graph) {                     // afficher l'offre/demande non-satisfaite pour les sommets
			int inf = ns.getInfeasibility(n);
			if (inf != 0) {
				String label = "" + n.getAttribute("ui.label");
				label += " (" + inf + ")";
				n.setAttribute("ui.label", label);
			}
		}

		try {
			graph.write(System.getProperty("user.dir") + File.separator
					+ "DGS" + File.separator + graph.getAttribute("name")
					+ ".dgs");
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}

		for(Node n : graph){
			if(n.hasAttribute("supply")){
				int supply = (int)n.getNumber("supply");
				if(supply < 0){
					n.setAttribute("supply", 0);
				}

			}
		}

		System.out.println("\n\nNouvelle période\n\n");

	} 



	private void constructGraph(){     //Méthode  de construction du graphe complet par niveau

		for (Node n : graph.getEachNode()) {

			if (n.hasAttribute("type")) {
				String typ = n.getAttribute("type");
				String niveau = "";
				if (typ.equals("provider")) {
					niveau = "national";
				} else if (typ.equals("national")) {
					niveau = "regional";
				} else if (typ.equals("regional")) {
					niveau = "local";
				} else if (typ.equals("local")) {
					niveau = "client";
				} 

				for (Node n1 : graph) {
					if (n1.hasAttribute("type")) {
						String typ1 = n1.getAttribute("type");
						if (typ1.equals(niveau)) {
							float capacity= Float.POSITIVE_INFINITY;
							Edge ed = graph.addEdge(n.getId() + n1.getId(), n, n1, true);
							double x0 = ed.getNode0().getNumber("x");
							double y0 = ed.getNode0().getNumber("y");
							double x1 = ed.getNode1().getNumber("x");
							double y1 = ed.getNode1().getNumber("y");
							int d = (int)Math.hypot(x0 - x1, y0 - y1) + 1;
							ed.addAttribute("cost", d);
							System.out.println("length = "+d);
							ed.addAttribute("capacity", capacity);
						}
					}
				}
			}		  			
		}

		Iterator<Node> it1 = graph.iterator();
		while (it1.hasNext()) {
			Node n2 = it1.next();
			if (n2.getDegree() == 0) {
				it1.remove();
			}
		}
	}


	// Méthode de calcul l'offre du Fournisseur ( somme de toutes les demandes des clients)

	private void computeProviderSupply(){
		Node provider = null;
		int sumNegSupply = 0;

		for (Node n : graph) {      // fixer les demandes des noeuds : doivent être des valeurs entières
			n.removeAttribute("ui.label");
			String t = n.getAttribute("type");
			if (t.equals("provider")){
				provider = n;
				provider.addAttribute("supply", -sumNegSupply);
				provider.addAttribute("ui.label", -sumNegSupply);
			}else 
				if (n.hasAttribute("supply")) {
					int s = (int)n.getNumber("supply");  // transformer en int
					if (s < 0){
						sumNegSupply += s;
						n.setAttribute("supply", s);
						n.addAttribute("ui.label", s+" "+n.getId());
						System.out.println("Demande client "+n.getId()+":"+ s);
					}else if(s>0)
						n.setAttribute("supply", s);
					n.addAttribute("ui.label", s);
					System.out.println("Stock "+n.getId()+":" +s);
				}
		}
		provider.addAttribute("supply", -sumNegSupply);   // Pour le fournisseur on met assez pour qu'il puisse satisfaire    
		provider.addAttribute("ui.label", -sumNegSupply); // les demandes à lui seul
		System.out.println("L'offre disponible chez le fournisseur: "+ -sumNegSupply);
	}


}


