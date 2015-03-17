package gama.extensions.analysenetwork;

import java.util.HashMap;
import java.util.Map;

import msi.gama.metamodel.agent.IAgent;
import msi.gama.metamodel.shape.IShape;
import msi.gama.metamodel.topology.filter.In;
import msi.gama.metamodel.topology.graph.GraphTopology;
import msi.gama.runtime.GAMA;
import msi.gama.runtime.IScope;
import msi.gama.runtime.exceptions.GamaRuntimeException;
import msi.gama.util.graph.GraphUtilsGraphStream;
import msi.gama.util.graph.IGraph;
import msi.gama.util.graph._Edge;
import msi.gama.util.graph._Vertex;
import msi.gaml.expressions.IExpression;
import msi.gaml.operators.Cast;

import org.graphstream.graph.Edge;
import org.graphstream.graph.EdgeRejectedException;
import org.graphstream.graph.Graph;
import org.graphstream.graph.IdAlreadyInUseException;
import org.graphstream.graph.Node;
import org.graphstream.graph.implementations.MultiGraph;

import com.vividsolutions.jts.geom.Coordinate;

public class Tools {
	/**
	 * Return the Graphstream graph corresponding to the GAMA graph.
	 * If it is the first call, the GS graph is build and then it is saved into an attribute of the simulation.a
	 * @param scope the scope of the simulation
	 * @param gama_graph the GAMA graph that must be converted into a GS graph
	 * @param length_attribute the length attribute name on the edges
	 * @param speed_attribute the speed attribute name on the edges
	 * @return the Graphstream graph corresponding to the GAMA graph. 
	 */
	public static Graph getGraph(final IScope scope, IGraph gama_graph, String length_attribute, String speed_attribute){
		Graph graph;
		if(scope.getSimulationScope().hasAttribute("gaml.extensions.analysenetwork.gs_graph"))
			graph = (Graph) scope.getSimulationScope().getAttribute("gaml.extensions.analysenetwork.gs_graph");
		else
			graph = Tools.getGraphstreamGraphFromGamaGraph(gama_graph, scope, length_attribute, speed_attribute);
		scope.getSimulationScope().setAttribute("gaml.extensions.analysenetwork.gs_graph", graph);
		return graph;
	}
	
	/**
	 * Return the Graphstream node associated to the GAMA agent. 
	 * Moreover, if it is the first call with this agent in parameter, then a GS node is created and is connected to closest GS nodes. 
	 * The edges which make the connections contain the real length and the time to make the travel.
	 * @param scope the scope of the simulation
	 * @param gama_agent the agent who is associated to the node we are looking for
	 * @param gama_graph the GAMA graph that must be converted into a GS graph
	 * @param graph the Graphstream graph corresponding to the GAMA graph.
	 * @param default_speed the default speed used outside the network to move from the agent to the nodes of the network
	 * @return the Graphstream node associated to the GAMA agent
	 */
	public static Node getNode(final IScope scope, IAgent gama_agent, IGraph gama_graph, Graph graph, double default_speed){
		Node gs_agent = graph.getNode(gama_agent.toString());
		if(gs_agent == null){
			gs_agent = Tools.connectAgent(gama_graph, graph, gama_agent, scope, default_speed);
		}
		scope.getSimulationScope().setAttribute("gaml.extensions.analysenetwork.gs_graph", graph);
		return gs_agent;
	}
	/**
	 * Takes a gama graph as an input, returns a graphstream graph as
	 * close as possible. Preserves double links (multi graph).
	 * Copy of the method of GraphUtilsGraphStream but we save the gama agent in each edges/nodes and the graphstream edge in each gama edge agent
	 * @param gamaGraph
	 * @return The Graphstream graph
	 */
	public static Graph getGraphstreamGraphFromGamaGraph(final IGraph gamaGraph, IScope scope, String length_attribute, String speed_attribute) {
		Map<Object, Node> gamaNode2graphStreamNode = new HashMap<Object, Node>(gamaGraph._internalNodesSet().size());
		Graph g = new MultiGraph("gs-graph");
		// add nodes
		for ( Object v : gamaGraph._internalVertexMap().keySet() ) {
			_Vertex vertex = (_Vertex) gamaGraph._internalVertexMap().get(v);
			Node n = g.addNode(v.toString());
			gamaNode2graphStreamNode.put(v, n);
			if ( v instanceof IAgent ) {
				IAgent a = (IAgent) v;
				n.addAttribute("gama_agent", a);
				for ( Object key : a.getAttributes().keySet() ) {
					Object value = GraphUtilsGraphStream.preprocessGamaValue(a.getAttributes().get(key));
					if(value != null)
						n.addAttribute(key.toString(), value.toString());
				}
			}

			if ( v instanceof IShape ) {
				IShape sh = (IShape) v;
				n.setAttribute("x", sh.getLocation().getX());
				n.setAttribute("y", sh.getLocation().getY());
				n.setAttribute("z", sh.getLocation().getZ());
			}
		}

		// add edges
		for ( Object edgeObj : gamaGraph._internalEdgeMap().keySet() ) {
			_Edge edge = (_Edge) gamaGraph._internalEdgeMap().get(edgeObj);
			try {
				Edge e = // We call the function where we give the nodes object directly, is it more efficient than give the string id? Because, if no, we don't need the "gamaNode2graphStreamNode" map...
						g.addEdge(edgeObj.toString(), gamaNode2graphStreamNode.get(edge.getSource()), gamaNode2graphStreamNode.get(edge.getTarget()),
								gamaGraph.isDirected() );// till now, directionality of an edge depends on the whole gama graph
				if ( edgeObj instanceof IAgent ) {
					IAgent a = (IAgent) edgeObj;
					// e know a
					e.addAttribute("gama_agent", a);
					for ( Object key : a.getAttributes().keySet() ) {
						Object value = GraphUtilsGraphStream.preprocessGamaValue(a.getAttributes().get(key));
						if(value != null)
							e.addAttribute(key.toString(), value.toString());
					}
					e.addAttribute("gama_time", e.getNumber(length_attribute) * e.getNumber(speed_attribute));
					// a know e
					a.setAttribute("gaml.extensions.analysenetwork.graphstream_edge", e);
				}
			} catch (EdgeRejectedException e) {
				GAMA.reportError(GamaRuntimeException
						.warning("an edge was rejected during the transformation, probably because it was a double one"),
						true);
			} catch (IdAlreadyInUseException e) {
				GAMA.reportError(GamaRuntimeException
						.warning("an edge was rejected during the transformation, probably because it was a double one"),
						true);
			}

		}

		// some basic tests for integrity
		if ( gamaGraph.getVertices().size() != g.getNodeCount() ) {
			GAMA.reportError(
					GamaRuntimeException.warning("The exportation ran without error, but an integrity test failed: " +
							"the number of vertices is not correct(" + g.getNodeCount() + " instead of " +
							gamaGraph.getVertices().size() + ")"), true);
		}
		if ( gamaGraph.getEdges().size() != g.getEdgeCount() ) {
			GAMA.reportError(
					GamaRuntimeException.warning("The exportation ran without error, but an integrity test failed: " +
							"the number of edges is not correct(" + g.getEdgeCount() + " instead of " +
							gamaGraph.getEdges().size() + ")"), true);
		}
		
		return g;
	}
	
	/**
	 * Create a gs node corresponding to a gama agent, and connect it the gs graph
	 * @param gama_graph the GAMA representation of the network
	 * @param gs_graph the Graphstream representation of the network
	 * @param agent the GAMA agent
	 * @param scope the scope of the simulation when the call is made
	 * @param default_speed the default speed of agent outside the network
	 * @return the GS node created
	 */
	public static Node connectAgent(IGraph gama_graph, Graph gs_graph, IAgent agent, IScope scope,  double default_speed){
		// Create the node associated to the agent
		Node gs_agent = gs_graph.addNode(agent.toString());
		gs_agent.addAttribute("x", agent.getLocation().getX());
		gs_agent.addAttribute("y", agent.getLocation().getY());
		gs_agent.addAttribute("gama_agent", agent);
		agent.setAttribute("gaml.extensions.analysenetwork.gs_node", gs_agent);
		
		// Get the closest edge
		GraphTopology gt = (GraphTopology)(Cast.asTopology(scope, gama_graph));
		IAgent gamaClosestEdge = gt.getAgentClosestTo(scope, agent, In.edgesOf(gt.getPlaces()));
		Edge gsClosestEdge = (Edge)gamaClosestEdge.getAttribute("gaml.extensions.analysenetwork.graphstream_edge");
		Node closestNode1 = gsClosestEdge.getNode0();
		Node closestNode2 = gsClosestEdge.getNode1();
		
		// Determine the closest point from the agent to the network in order to compute the length from the agent to the two nodes belonging to the edge
		Coordinate coord = getClosestLocation(new Coordinate(agent.getLocation().getX(), agent.getLocation().getY()), 
				new Coordinate(closestNode1.getNumber("x"), closestNode1.getNumber("y")),
				new Coordinate(closestNode2.getNumber("x"), closestNode2.getNumber("y")));

		// If the closest point is one of these nodes, then we connect the agent only to this point
		if(coord.x == closestNode1.getNumber("x") && coord.y == closestNode1.getNumber("y")) {
			Edge e = gs_graph.addEdge(agent.toString()+"_"+closestNode1.getId(), closestNode1, gs_agent);
			e.addAttribute("length", Math.hypot(closestNode1.getNumber("x")-gs_agent.getNumber("x"), closestNode1.getNumber("y")-gs_agent.getNumber("y")));
			e.addAttribute("speed", default_speed);
			e.addAttribute("gama_time", e.getNumber("length")*e.getNumber("speed"));
		}
		else if(coord.x == closestNode2.getNumber("x") && coord.y == closestNode2.getNumber("y")){
			Edge e = gs_graph.addEdge(agent.toString()+"_"+closestNode2.getId(), closestNode2, gs_agent);
			e.addAttribute("length", Math.hypot(closestNode2.getNumber("x")-gs_agent.getNumber("x"), closestNode2.getNumber("y")-gs_agent.getNumber("y")));
			e.addAttribute("speed", default_speed);
			e.addAttribute("gama_time", e.getNumber("length")*e.getNumber("speed"));
		}
		else{
			// the agent is connected to both nodes
			Edge e1 = gs_graph.addEdge(agent.toString()+"_"+closestNode1.getId(), closestNode1, gs_agent);
			Edge e2 = gs_graph.addEdge(agent.toString()+"_"+closestNode2.getId(), closestNode2, gs_agent);
			
			double lengthToEdge =  Math.hypot(gs_agent.getNumber("x")-coord.x, gs_agent.getNumber("y")-coord.y);
			double lengthCoordToN1 = Math.hypot(closestNode1.getNumber("x")-coord.x, closestNode1.getNumber("y")-coord.y);
			double lengthCoordToN2 = Math.hypot(closestNode2.getNumber("x")-coord.x, closestNode2.getNumber("y")-coord.y);
			
			e1.addAttribute("length", lengthToEdge + lengthCoordToN1);
			e1.addAttribute("gama_time", lengthCoordToN1*gsClosestEdge.getNumber("speed") + lengthToEdge*default_speed);
			e1.addAttribute("speed", e1.getNumber("length")/e1.getNumber("gama_time"));
			
			e2.addAttribute("length", lengthToEdge + lengthCoordToN2);
			e2.addAttribute("gama_time", lengthCoordToN1*gsClosestEdge.getNumber("speed") + lengthToEdge*default_speed);
			e2.addAttribute("speed", e2.getNumber("length")/e2.getNumber("gama_time"));
		}
		return gs_agent;
	}
	
	private static Coordinate getClosestLocation(Coordinate coordOutNetwork, Coordinate a, Coordinate b){
		// Get coordinates of these different points
		double xa = a.x;
		double ya = a.y;
		double xb = b.x;
		double yb = b.y;
		double xc = coordOutNetwork.x;
		double yc = coordOutNetwork.y;

		// Compute coordinates of vectors
		// CA Vector
		double ACy = yc - ya;
		double ACx = xc - xa;
		// AB vector
		double ABy = yb - ya;
		double ABx = xb - xa;
		// CB vector
		double BCy = yc - yb;
		double BCx = xc - xb;
		// BA vector
		double BAy = ya - yb;
		double BAx = xa - xb;

		// Compute the angles
		// The angle between ->AC and ->AB
		double CAB = Math.abs( Math.toDegrees(Math.atan2(ACy, ACx)-Math.atan2(ABy, ABx)) );
		// The angle between ->BC and ->BA
		double CBA = Math.abs( Math.toDegrees(Math.atan2(BCy, BCx)-Math.atan2(BAy, BAx)) );

		// Let A and B the nodes of this segment and C be the currentLocation
		// If one of the angles CAB or CBA  is obtuse ( ie.  90 < CAB < 180 or 90 < CBA < 180)
		// 	then the next location is on the segment between C and A (or C and B)
		double x_dest;
		double y_dest;
		if(CAB >= 90 ){
			// Between C and A
			x_dest = xa;
			y_dest = ya;
		}
		else if(CBA >= 90){
			// Between C and B
			x_dest = xb;
			y_dest = yb;
		}
		else {
			// Let H be the orthographic projection of C on AB (thus we have : (CH) _|_ (AB) )
			// The next location is on the segment between C and H
			// Compute unit vector
			double xv = (xb-xa);
			double yv = (yb- ya);
			// Compute distance
			double AH = ( (xc-xa)*xv + (yc-ya)*yv ) / ( Math.sqrt(xv*xv +yv*yv) );
			x_dest = xa + ( AH / (Math.sqrt(xv*xv +yv*yv)) ) * xv;
			y_dest = ya + ( AH / (Math.sqrt(xv*xv +yv*yv)) ) * yv;
		}

		return new Coordinate(x_dest, y_dest);
	}
}
