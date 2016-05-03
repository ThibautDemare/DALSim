package gama.extensions.analysenetwork;

import org.graphstream.graph.Graph;
import org.graphstream.graph.Node;

import msi.gama.metamodel.agent.IAgent;
import msi.gama.precompiler.GamlAnnotations.doc;
import msi.gama.precompiler.GamlAnnotations.example;
import msi.gama.precompiler.GamlAnnotations.operator;
import msi.gama.runtime.IScope;
import msi.gama.util.GamaList;
import msi.gama.util.graph.IGraph;


public class AnalyseGraphElement {
	
	@operator(value = IKeywordANAdditional.SHIMBEL)
	@doc(value = "This operator allows to compute the Shimbel index of an agent outside a graph. It considers that the agent is connected to the network since a moving agent can access the network and move on it.",
		comment = "The user must give the GAMA graph and the gama agent, but also the characteristics of the network that must be taken into account to compute the measure " +
				"(lentgh and speed attribute on the network and default speed outside the network)",
		examples = { @example("shimbel_index(my_agent, my_network, 'length', 'speed', 70�km/�s)") })
	public static Double shimbelIndex(final IScope scope, IAgent gama_agent, IGraph gama_graph, String length_attribute, String speed_attribute, double default_speed) {
		// Step 1 : get the gs graph associated to the gama graph
		Graph graph = Tools.getGraph(scope, gama_graph, length_attribute, speed_attribute);
		
		// Step 2 : get the gs node associated to the agent
		Node gs_agent =Tools. getNode(scope, gama_agent, gama_graph, graph, default_speed);

		// Step 3: compute the measure
		ShimbelIndex si = new ShimbelIndex();
		si.init(graph);
		si.setWeightAttributeName("gama_time");
		si.compute(gs_agent);
		scope.getSimulationScope().setAttribute("gaml.extensions.analysenetworkgs_graph", graph);
		return si.getNodeMeasure(gs_agent);
	}
	
	@operator(value = IKeywordANAdditional.CONNECT_TO)
	@doc(value = "This operator allows to connect agents to a graph in order to take them into account in order to compute measures on graph.",
		comment = "The user must give the GAMA graph and the list gama agents, but also the characteristics of the network that must be taken into account to compute the measure " +
				"(lentgh and speed attribute on the network and default speed outside the network)",
		examples = { @example("connect_to(my_agents, my_network, 'length', 'speed', 70�km/�s)")})
	public static boolean connectTo(final IScope scope, GamaList<IAgent> gama_agents, IGraph gama_graph, String length_attribute, String speed_attribute, double default_speed) {
		Graph graph = Tools.getGraph(scope, gama_graph, length_attribute, speed_attribute);
		for(IAgent gama_agent : gama_agents){
			Tools.getNode(scope, gama_agent, gama_graph, graph, default_speed);
		}
		return true;
	}
}
