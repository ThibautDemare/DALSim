package skill;

import java.util.HashMap;
import java.util.Map;

import org.graphstream.algorithm.Dijkstra;
import org.graphstream.graph.Edge;
import org.graphstream.graph.EdgeRejectedException;
import org.graphstream.graph.Graph;
import org.graphstream.graph.IdAlreadyInUseException;
import org.graphstream.graph.Node;
import org.graphstream.graph.Path;
import org.graphstream.graph.implementations.MultiGraph;

import com.vividsolutions.jts.geom.Coordinate;
import com.vividsolutions.jts.geom.LineString;
import com.vividsolutions.jts.geom.Point;

import msi.gama.common.interfaces.ILocated;
import msi.gama.common.util.GeometryUtils;
import msi.gama.metamodel.agent.IAgent;
import msi.gama.metamodel.shape.GamaPoint;
import msi.gama.metamodel.shape.ILocation;
import msi.gama.metamodel.shape.IShape;
import msi.gama.metamodel.topology.filter.In;
import msi.gama.metamodel.topology.graph.GraphTopology;
import msi.gama.precompiler.GamlAnnotations.action;
import msi.gama.precompiler.GamlAnnotations.arg;
import msi.gama.precompiler.GamlAnnotations.doc;
import msi.gama.precompiler.GamlAnnotations.getter;
import msi.gama.precompiler.GamlAnnotations.setter;
import msi.gama.precompiler.GamlAnnotations.skill;
import msi.gama.precompiler.GamlAnnotations.var;
import msi.gama.precompiler.GamlAnnotations.vars;
import msi.gama.runtime.GAMA;
import msi.gama.runtime.IScope;
import msi.gama.runtime.exceptions.GamaRuntimeException;
import msi.gama.util.GamaList;
import msi.gama.util.graph.GraphUtilsGraphStream;
import msi.gama.util.graph.IGraph;
import msi.gama.util.graph._Edge;
import msi.gama.util.graph._Vertex;
import msi.gaml.operators.Cast;
import msi.gaml.skills.Skill;
import msi.gaml.types.IType;

@doc("This skill is intended to move an agent on a network according to speed and length attributes on the edges. When The agent is not already on the graph, we assume that the length is an euclidean length and we use a default speed given by the user.")
@vars({
	@var(name = IKeywordMoNAdditional.LENGTH_ATTRIBUTE, type = IType.STRING, doc = @doc("The attribute giving the length of the edge. Becareful : this variable is shared by all moving agent.")),
	@var(name = IKeywordMoNAdditional.SPEED_ATTRIBUTE, type = IType.STRING, doc = @doc("The attribute giving the default speed. Becareful : this variable is shared by all moving agent.")),
	@var(name = IKeywordMoNAdditional.DEFAULT_SPEED, type = IType.FLOAT, doc = @doc("The speed outside the graph.")),
})
@skill(name = IKeywordMoNAdditional.MOVING_ON_NETWORK)
public class MovingOnNetworkSkill extends Skill {
	private static Dijkstra dijkstra = null;
	private Path currentGsPath = null;
	private ILocation currentTarget = null;// We use this variable to know if we already have computed the shortest path
	private static Graph graph = null;
	private static IGraph gamaGraph = null;
	public static String length_attribute = null;
	public static String speed_attribute = null;
	private double remainingTime = 0;
	private boolean agentOutside = true;

	/*
	 * Getters and setters
	 */

	@setter(IKeywordMoNAdditional.GRAPH)
	public void setGraph(final IAgent agent, final IGraph gamaGraph) {
		if(graph == null){
			graph = getGraphstreamGraphFromGamaGraph(gamaGraph);
			MovingOnNetworkSkill.gamaGraph = gamaGraph;
		}
	}

	@getter(IKeywordMoNAdditional.LENGTH_ATTRIBUTE)
	public String getLengthAttribute(final IAgent agent) {
		return (String) agent.getAttribute(IKeywordMoNAdditional.LENGTH_ATTRIBUTE);
	}

	@setter(IKeywordMoNAdditional.LENGTH_ATTRIBUTE)
	public void setLengthAttribute(final IAgent agent, final String s) {
		agent.setAttribute(IKeywordMoNAdditional.LENGTH_ATTRIBUTE, s);
	}

	@getter(IKeywordMoNAdditional.SPEED_ATTRIBUTE)
	public String getSpeedAttribute(final IAgent agent) {
		return (String) agent.getAttribute(IKeywordMoNAdditional.SPEED_ATTRIBUTE);
	}

	@setter(IKeywordMoNAdditional.SPEED_ATTRIBUTE)
	public void setSpeedAttribute(final IAgent agent, final String s) {
		agent.setAttribute(IKeywordMoNAdditional.SPEED_ATTRIBUTE, s);
	}

	@getter(IKeywordMoNAdditional.DEFAULT_SPEED)
	public Float getDefaultSpeed(final IAgent agent) {
		return (Float) agent.getAttribute(IKeywordMoNAdditional.DEFAULT_SPEED);
	}

	@setter(IKeywordMoNAdditional.DEFAULT_SPEED)
	public void setDefaultSpeed(final IAgent agent, final Float s) {
		agent.setAttribute(IKeywordMoNAdditional.DEFAULT_SPEED, s);
	}

	/*
	 * Actions/methods
	 */

	@action(
			name = "goto",
			args = {
					@arg(name = "target", type = { IType.AGENT, IType.POINT, IType.GEOMETRY }, optional = false, doc = @doc("the location or entity towards which to move.")),
					@arg(name = "on", type = IType.GRAPH, optional = true, doc = @doc("the agent moves inside this graph")),
			},
			doc =
			@doc(value = "moves the agent towards the target passed in the arguments.", returns = "the path followed by the agent.", examples = { "do goto target: (one_of road).location on: road_network;" })
			)
	public GamaList gotoAction(final IScope scope) throws GamaRuntimeException {
		final IAgent agent = getCurrentAgent(scope);

		// If the user does not have given the "on" argument, so he must have set the graph before (if not, we throw an error)
		if(graph == null){
			final Object on = scope.getArg("on", IType.GRAPH);
			if(on == null){
				throw GamaRuntimeException.error("You have not declare a graph on which the agent can move.");
			}
			setGraph(agent, (IGraph)on);
		}
		// The source is the current location of the current agent
		final ILocation source = agent.getLocation().copy(scope);
		// The target is the location of the thing passing through argument (an agent or a point or a geometry)
		final ILocation target = findTargetLocation(scope);

		if(currentTarget != target){
			// Need to compute the path
			currentGsPath = computeShortestPath(scope, source, target);
			currentTarget = target;
		}
		// The path has been computed, we need to know how many time the agent has in order to make the move.
		remainingTime = scope.getClock().getStep();

		// Move the agent from outside the network to inside (when he is not already on the network).
		movingFromOutsideToInside(scope, agent);

		// Move the agent inside the network (and get the agent edges that the agent has traveled) (when the agent is already on the network and can still move).
		GamaList gl = movingInside(scope, agent);

		// Move the agent from inside the network to outside (when the target must and can leave the network).
		movingInsideToOutside();

		return gl;
	}

	private void movingFromOutsideToInside(final IScope scope, final IAgent agent){
		if(agentOutside && remainingTime > 0){
			/*
			 *  First step : find the closest segment to the agent
			 *  Indeed, one edge of the path could be made with more than one segment
			 */
			// The position of the agent
			GamaPoint currentLocation = (GamaPoint) agent.getLocation().copy(scope);
			Point currentPointLocation = (Point) agent.getLocation().copy(scope).getInnerGeometry();
			// The closest road
			IAgent gamaRoad = currentGsPath.peekEdge().getAttribute("gama_agent");

			// Find the closest segment among the road's
			double distAgentToNetwork = Double.MAX_VALUE;
			Coordinate coords[] = gamaRoad.getInnerGeometry().getCoordinates();
			Coordinate[] tempCoord = new Coordinate[2];
			int indexBestSegment = 0;
			for ( int i = 0; i < coords.length - 1; i++ ) {
				tempCoord[0] = coords[i];
				tempCoord[1] = coords[i + 1];
				LineString segment = GeometryUtils.FACTORY.createLineString(tempCoord);
				double distS = segment.distance(currentPointLocation);
				if ( distS < distAgentToNetwork ) {
					distAgentToNetwork = distS;
					indexBestSegment = i;
				}
			}

			/*
			 * Second step : Find the closest point on this segment
			 */
			// Get coordinates of these different points
			double xa = coords[indexBestSegment].x;
			double ya = coords[indexBestSegment].y;
			double xb = coords[indexBestSegment+1].x;
			double yb = coords[indexBestSegment+1].y;
			double xc = currentPointLocation.getX();
			double yc = currentPointLocation.getY();

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
			double CAB = Math.toDegrees(Math.atan2(ACy, ACx)-Math.atan2(ABy, ABx));
			// The angle between ->BC and ->BA
			double CBA = Math.toDegrees(Math.atan2(BCy, BCx)-Math.atan2(BAy, BAx));

			// Let A and B the nodes of this segment and C be the currentLocation
			// If one of the angles CAB or CBA  is obtuse ( ie.  90 < CAB < 180 or 90 < CBA < 180)
			// 	then the next location is on the segment between C and A (or C and B)
			double x_dest;
			double y_dest;
			if(CAB > 90 ){
				// Between C and A
				x_dest = xa;
				y_dest = ya;
			}
			else if(CBA > 90){
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
			
			/*
			 * Third step : move the agent on this point
			 */
			double dist = Math.hypot(xc - x_dest, yc - y_dest);
			double time = dist * getDefaultSpeed(agent);
			if(remainingTime >= time){
				currentLocation.setLocation(x_dest, y_dest);
				agentOutside = false;
			}
			else{
				// TODO : but actually, it must never be used...
			}
			
			remainingTime -= time;
		}
	}

	private GamaList movingInside(final IScope scope, final IAgent agent){
		if(!agentOutside && remainingTime > 0){
			GamaPoint currentLocation = (GamaPoint) agent.getLocation().copy(scope);
			// Need to reach the next Node
			moveAlongEdge(currentLocation, remainingTime, currentGsPath.peekEdge());

			// Follow the path on the graph, node by node
			GamaList gl = new GamaList();
			while(remainingTime > 0 && !currentGsPath.empty()){
				Edge edge = currentGsPath.peekEdge();
				double time = edge.getNumber(getLengthAttribute(agent)) * edge.getNumber(getSpeedAttribute(agent));
				remainingTime -= time;

				if(currentGsPath.size()== 1 || (remainingTime - time) < 0){
					// The moving agent stop between two nodes somewhere on the edge
					// Compute the location of this "somewhere"
					moveAlongEdge(currentLocation, remainingTime, edge);

					if(currentGsPath.size()== 1){
						// The first case
						// We don't stop moving but we pop the current edge of the path
						currentGsPath.popEdge();
						// We add the gama agent associated to this edge
						gl.add(edge.getArray("gama_agent"));
					}

					if(remainingTime < 0){
						// The second case (or the next one)
						// We stop moving but we do not pop the current edge of the path
						remainingTime = 0;
					}
				}
				else{
					// We continue to move the agent to the next node
					currentGsPath.popEdge();
					// We add the gama agent associated to this edge
					gl.add(edge.getAttribute("gama_agent"));
					// Set the location of the agent to the next node
					currentLocation = edge.getOpposite(currentGsPath.peekNode());
				}

			}

			//We set the location of the agent in order to make the move
			agent.setLocation(currentLocation);
			// We return the list of edges that the agent has traveled.
			return gl;
		}
		// The agent can't move. We return an empty list
		return new GamaList();
	}

	private void movingInsideToOutside(){
		if(!agentOutside && remainingTime > 0){
			
		}
		// TODO
	}

	/**
	 * Move the agent along an edge. There are two possibilities to stop the agent on this edges :
	 * - firstly, there is not enough remaining time to reach the end of this edge.
	 * - secondly, the next move will be to leave the network and reach the target (it is also possible that the agent has not enough time to reach the exit point).
	 * @param currentLoc
	 * @param remainingT
	 * @param e
	 */
	private void moveAlongEdge(ILocation currentLoc, double remainingT, Edge e){
		// Get the geometry
		IShape shape = ((IAgent)(e.getAttribute("gama_agent"))).getGeometry();
		final Coordinate coords[] = shape.getInnerGeometry().getCoordinates();
		// TODO
	}

	private ILocation findTargetLocation(final IScope scope) {
		final Object target = scope.getArg("target", IType.NONE);
		ILocation result = null;
		if ( target != null && target instanceof ILocated ) {
			result = ((ILocated) target).getLocation();
		}
		return result;
	}

	private Path computeShortestPath(final IScope scope, ILocation source, ILocation target){
		if(dijkstra == null){
			dijkstra = new Dijkstra(Dijkstra.Element.EDGE, "result", "gama_time");
			dijkstra.init(graph);
		}

		/*
		 *  Find the graphstream source and target node
		 */
		GraphTopology gt = (GraphTopology)(Cast.asTopology(scope, gamaGraph));
		// Find the source node
		IAgent gamaSourceEdge = gt.getAgentClosestTo(scope, source, In.edgesOf(gt.getPlaces()));
		Edge gsSourceEdge = (Edge)gamaSourceEdge.getAttribute("graphstream_edge");
		Node sourceNode = gsSourceEdge.getNode0();
		// Find the target node
		IAgent gamaTargetEdge = gt.getAgentClosestTo(scope, target, In.edgesOf(gt.getPlaces()));
		Edge gsTargetEdge = (Edge)gamaTargetEdge.getAttribute("graphstream_edge");
		Node targetNode = gsTargetEdge.getNode0();

		/*
		 *  Compute and get the path
		 */
		dijkstra.setSource(sourceNode);
		dijkstra.compute();
		Path path = dijkstra.getPath(targetNode);

		/*
		 * Add closest edge(s)
		 */
		// Add closest source edge to the path if it is missing
		if(!path.contains(gsSourceEdge)){
			path.add(gsSourceEdge);
		}

		// Add closest target edge to the path if it is missing
		if(!path.contains(gsTargetEdge)){
			path.add(gsTargetEdge);
		}
		return path;
	}

	/**
	 * Takes a gama graph as an input, returns a graphstream graph as
	 * close as possible. Preserves double links (multi graph).
	 * Copy of the method of GraphUtilsGraphStream but we save the gama agent in each edges/nodes and the graphstream edge in each gama edge agent
	 * @param gamaGraph
	 * @return The Graphstream graph
	 */
	private static Graph getGraphstreamGraphFromGamaGraph(final IGraph gamaGraph) {
		Graph g = new MultiGraph("tmpGraph", true, false);
		Map<Object, Node> gamaNode2graphStreamNode = new HashMap<Object, Node>(gamaGraph._internalNodesSet().size());

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
					// standard attribute
					n.setAttribute(key.toString(), value.toString());
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
								gamaGraph.isDirected() );// till now,vdirectionality of an edge depends on the whole gama graph
				if ( edgeObj instanceof IAgent ) {
					IAgent a = (IAgent) edgeObj;
					// a know e
					a.setAttribute("graphstream_edge", e);
					// and e know a
					e.addAttribute("gama_agent", a);
					for ( Object key : a.getAttributes().keySet() ) {
						Object value = GraphUtilsGraphStream.preprocessGamaValue(a.getAttributes().get(key));
						e.setAttribute(key.toString(), value.toString());
					}
					e.addAttribute("gama_time", e.getNumber(length_attribute) * e.getNumber(speed_attribute));
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
}
