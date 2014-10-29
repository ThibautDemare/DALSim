package skill;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.HashMap;
import java.util.List;
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
	@var(name = IKeywordMoNAdditional.LENGTH_ATTRIBUTE, type = IType.STRING, init = "'length'", doc = @doc("The attribute giving the length of the edge. Be careful : this variable is shared by all moving agent.")),
	@var(name = IKeywordMoNAdditional.SPEED_ATTRIBUTE, type = IType.STRING, init = "'speed'", doc = @doc("The attribute giving the default speed. Be careful : this variable is shared by all moving agent.")),
	@var(name = IKeywordMoNAdditional.DEFAULT_SPEED, type = IType.FLOAT, init = "19.4444", doc = @doc("The speed outside the graph ((in meter/second). Default : 70km/h.")),
	@var(name = IKeywordMoNAdditional.GRAPH, type = IType.GRAPH, doc = @doc("The graph or network on which the agent moves.")),
})
@skill(name = IKeywordMoNAdditional.MOVING_ON_NETWORK)
public class MovingOnNetworkSkill extends Skill {
	/*
	 * Static variables
	 */
	private static Dijkstra dijkstra = null;
	private static Graph graph = null;
	private static IGraph gamaGraph = null;
	private static String length_attribute = null;
	private static String speed_attribute = null;

	/*
	 * Non-static variables
	 */
	private double remainingTime;
	private boolean agentFromOutsideToInside;
	private boolean agentInside;
	private boolean agentFromInsideToOutside;
	private boolean agentOnANode;
	private List<Edge> currentGsPathEdge;
	private List<Node> currentGsPathNode;
	private ILocation currentTarget;

	/*
	 * Getters and setters
	 */

	@setter(IKeywordMoNAdditional.GRAPH)
	public void setGraph(final IAgent agent, final IGraph gamaGraph) {
		if(gamaGraph != null && (graph == null || graph.getEdge(0).getAttribute("gama_time").equals("NaN"))){ // If the graph is null or if its edges do not contain a right value of gama_time
			graph = getGraphstreamGraphFromGamaGraph(gamaGraph);
			MovingOnNetworkSkill.gamaGraph = gamaGraph;
		}
		else {
			dijkstra = null;
			graph = null;
			MovingOnNetworkSkill.gamaGraph = null;
		}
	}

	@getter(IKeywordMoNAdditional.LENGTH_ATTRIBUTE)
	public String getLengthAttribute(final IAgent agent) {
		return (String) agent.getAttribute(IKeywordMoNAdditional.LENGTH_ATTRIBUTE);
	}

	@setter(IKeywordMoNAdditional.LENGTH_ATTRIBUTE)
	public void setLengthAttribute(final IAgent agent, final String s) {
		length_attribute = s;
		agent.setAttribute(IKeywordMoNAdditional.LENGTH_ATTRIBUTE, s);
	}

	@getter(IKeywordMoNAdditional.SPEED_ATTRIBUTE)
	public String getSpeedAttribute(final IAgent agent) {
		return (String) agent.getAttribute(IKeywordMoNAdditional.SPEED_ATTRIBUTE);
	}

	@setter(IKeywordMoNAdditional.SPEED_ATTRIBUTE)
	public void setSpeedAttribute(final IAgent agent, final String s) {
		speed_attribute = s;
		agent.setAttribute(IKeywordMoNAdditional.SPEED_ATTRIBUTE, s);
	}

	@getter(IKeywordMoNAdditional.DEFAULT_SPEED)
	public Double getDefaultSpeed(final IAgent agent) {
		return (Double) agent.getAttribute(IKeywordMoNAdditional.DEFAULT_SPEED);
	}

	@setter(IKeywordMoNAdditional.DEFAULT_SPEED)
	public void setDefaultSpeed(final IAgent agent, final double s) {
		agent.setAttribute(IKeywordMoNAdditional.DEFAULT_SPEED, s);
	}

	/*
	 * Actions/methods
	 */

	@action(
			name = "goto",
			args = {
					@arg(name = IKeywordMoNAdditional.TARGET, type = { IType.AGENT, IType.POINT, IType.GEOMETRY }, optional = false, doc = @doc("the location or entity towards which to move.")),
					@arg(name = IKeywordMoNAdditional.ON, type = IType.GRAPH, optional = true, doc = @doc("the agent moves inside this graph.")),
					@arg(name = IKeywordMoNAdditional.LENGTH_ATTRIBUTE, type = IType.STRING, optional = true, doc = @doc("the name of the variable containing the length of an edge.")),
					@arg(name = IKeywordMoNAdditional.SPEED_ATTRIBUTE, type = IType.STRING, optional = true, doc = @doc("the name of the varaible containing the speed on an edge."))
			},
			doc =
			@doc(value = "moves the agent towards the target passed in the arguments.", returns = "the path followed by the agent.", examples = { "do goto target: (one_of road).location on: road_network;" })
			)
	public GamaList gotoAction(final IScope scope) throws GamaRuntimeException {
		final IAgent agent = getCurrentAgent(scope);

		init(scope, agent);

		// The source is the current location of the current agent
		final ILocation source = agent.getLocation().copy(scope);
		// The target is the location of the thing passing through argument (an agent or a point or a geometry)
		final ILocation target = findTargetLocation(scope);

		if(currentTarget != target){
			// Need to compute the path
			computeShortestPath(scope, source, target);
			currentTarget = target;
			agentFromOutsideToInside = true;
			agentInside = false;
			agentFromInsideToOutside = false;
			agentOnANode = false;
		}
		// The path has been computed, we need to know how many time the agent has in order to make the move.
		remainingTime = scope.getClock().getStep();

		// Move the agent from outside the network to inside (when he is not already on the network).
		movingFromOutsideToInside(scope, agent);

		// Move the agent inside the network (and get the agent edges that the agent has traveled) (when the agent is already on the network and can still move).
		GamaList gl = movingInside(scope, agent, target);

		// Move the agent from inside the network to outside (when the target must and can leave the network).
		movingFromInsideToOutside(scope, agent, target);

		agent.setAttribute("agentFromOutsideToInside", agentFromOutsideToInside);
		agent.setAttribute("agentInside", agentInside);
		agent.setAttribute("agentFromInsideToOutside", agentFromInsideToOutside);
		agent.setAttribute("agentOnANode", agentOnANode);
		agent.setAttribute("currentGsPathEdge", currentGsPathEdge);
		agent.setAttribute("currentGsPathNode", currentGsPathNode);
		agent.setAttribute("currentTarget", currentTarget);

		return gl;
	}

	private void init(final IScope scope, final IAgent agent) {
		agentFromOutsideToInside = true;
		if(agent.hasAttribute("agentFromOutsideToInside"))
			agentFromOutsideToInside = (Boolean) agent.getAttribute("agentFromOutsideToInside");

		agentInside = false;
		if(agent.hasAttribute("agentInside"))
			agentInside = (Boolean) agent.getAttribute("agentInside");

		agentFromInsideToOutside = false;
		if(agent.hasAttribute("agentFromInsideToOutside"))
			agentFromInsideToOutside = (Boolean) agent.getAttribute("agentFromInsideToOutside");

		agentOnANode = false;
		if(agent.hasAttribute("agentOnANode"))
			agentOnANode = (Boolean) agent.getAttribute("agentOnANode");

		currentGsPathEdge = null;
		if(agent.hasAttribute("currentGsPathEdge"))
			currentGsPathEdge = (List<Edge>) agent.getAttribute("currentGsPathEdge");

		currentGsPathNode = null;
		if(agent.hasAttribute("currentGsPathNode"))
			currentGsPathNode = (List<Node>) agent.getAttribute("currentGsPathNode");

		currentTarget = null;// We use this variable to know if we already have computed the shortest path
		if(agent.hasAttribute("currentTarget"))
			currentTarget = (ILocation) agent.getAttribute("currentTarget");

		// If the user has not given the length argument, so he must have set it before (if not, we throw an error)
		if(length_attribute == null || !((String)scope.getArg(IKeywordMoNAdditional.LENGTH_ATTRIBUTE, IType.STRING)).equals(length_attribute) ){
			final Object la = scope.getArg(IKeywordMoNAdditional.LENGTH_ATTRIBUTE, IType.STRING);
			if(la == null){
				throw GamaRuntimeException.error("You have not declare a length attribute.");
			}
			setLengthAttribute(agent, (String)la);
		}

		// If the user has not given the speed argument, so he must have set it before (if not, we throw an error)
		if(speed_attribute == null || !((String)scope.getArg(IKeywordMoNAdditional.SPEED_ATTRIBUTE, IType.STRING)).equals(speed_attribute) ){
			final Object sa = scope.getArg(IKeywordMoNAdditional.SPEED_ATTRIBUTE, IType.STRING);

			if(sa == null){
				throw GamaRuntimeException.error("You have not declare a speed attribute.");
			}
			setSpeedAttribute(agent, (String)sa);
		}

		// If the user has not given the "on" argument, so he must have set the graph before (if not, we throw an error)
		if(graph == null || length_attribute == null || speed_attribute == null || scope.getArg("on", IType.GRAPH) != gamaGraph ){
			final Object on = scope.getArg("on", IType.GRAPH);
			if(on == null){
				throw GamaRuntimeException.error("You have not declare a graph on which the agent can move.");
			}
			setGraph(agent, (IGraph)on);
		}

	}

	private void movingFromOutsideToInside(final IScope scope, final IAgent agent){
		if(agentFromOutsideToInside && remainingTime > 0){
			/*
			 *  First step : find the closest segment to the agent
			 *  Indeed, one edge of the path could be made with more than one segment
			 */
			// The position of the agent
			GamaPoint currentLocation = (GamaPoint) agent.getLocation().copy(scope);
			Point currentPointLocation = (Point) agent.getLocation().copy(scope).getInnerGeometry();
			// The closest road
			IAgent gamaRoad = currentGsPathEdge.get(0).getAttribute("gama_agent");

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
			Coordinate dest = getClosestLocation(new Coordinate(currentPointLocation.getX(), currentPointLocation.getY()), coords[indexBestSegment], coords[indexBestSegment+1]);
			double xc = currentPointLocation.getX();
			double yc = currentPointLocation.getY();

			/*
			 * Third step : move the agent on this point
			 */
			double dist = Math.hypot(xc - dest.x, yc - dest.y);
			double time = dist / getDefaultSpeed(agent);// We use the default speed because the agent is not yet on the network

			if(remainingTime >= time){
				currentLocation.setLocation(dest.x, dest.y);
				agent.setLocation(currentLocation);
				agentFromOutsideToInside = false;
				agentInside = true;
			}
			else{
				double coef = remainingTime / time;
				double x_inter = xc + (dest.x - xc) * coef;
				double y_inter = yc + (dest.y - yc) * coef;
				currentLocation.setLocation(x_inter, y_inter);
				agent.setLocation(currentLocation);
			}

			remainingTime -= time;
		}
	}

	private GamaList movingInside(final IScope scope, final IAgent agent, final ILocation target){
		if(agentInside && remainingTime > 0){
			GamaPoint currentLocation = (GamaPoint) agent.getLocation().copy(scope);
			// It follows the path on the graph, node by node
			GamaList gl = new GamaList();
			if(remainingTime <= 0)
				gl.add(currentGsPathEdge.get(0).getAttribute("gama_agent"));

			// Does the agent need to reach the next Node?
			if(!agentOnANode){
				moveAlongEdge(scope, agent, target, currentGsPathEdge.get(0));
				// Moreover, if the agent is at the last part of its path, and if he has some remaining time, then, it means that he will leave the network
				if(currentGsPathEdge.size()== 1 && remainingTime >= 0){
					// Thus, we pop the current edge of the path and the node (the last ones)
					gl.add(currentGsPathEdge.remove(0).getAttribute("gama_agent"));
					currentGsPathNode.remove(0);
					agentFromInsideToOutside = true;
					agentInside = false;
				}
			}

			if(currentGsPathNode.isEmpty()){
				agentFromInsideToOutside = true;
				agentInside = false;
			}

			while(remainingTime > 0 && !currentGsPathEdge.isEmpty()){
				Edge edge = currentGsPathEdge.get(0);
				double time = edge.getNumber(getLengthAttribute(agent))*100000 / (edge.getNumber(getSpeedAttribute(agent))*1000/3600);
				// currentGsPath.size()== 1 when the agent is at the end of the path,
				// therefore it must stop before the next node in order to leave the network
				// But he can also stop before the end of an edge if he has not enough remaining time
				if(currentGsPathEdge.size()== 1 || remainingTime < time){
					// The moving agent stops between two nodes somewhere on the edge
					// Move the agent to this "somewhere"
					moveAlongEdge(scope, agent, target, edge);
					// Moreover, if the agent is at the last part of its path, and if he has some remaining time, then, it means that he will leave the network
					if(currentGsPathEdge.size()== 1 && remainingTime >= 0){
						// Thus, we pop the current edge of the path and the node (the last ones)
						currentGsPathEdge.remove(0);
						currentGsPathNode.remove(0);
						agentFromInsideToOutside = true;
						agentInside = false;
					}
				}
				else{
					agentOnANode = true;
					// We continue to move the agent to the next node
					((IAgent)edge.getAttribute("gama_agent")).setAttribute("color", "blue");
					currentGsPathEdge.remove(0);
					// Set the location of the agent to the next node
					if(currentGsPathNode.get(0).hasAttribute("gama_agent"))
						currentLocation = new GamaPoint(((IAgent)currentGsPathNode.get(0).getAttribute("gama_agent")).getLocation());
					else
						currentLocation = new GamaPoint( currentGsPathNode.get(0).getNumber("x"), currentGsPathNode.get(0).getNumber("y"));
					currentGsPathNode.remove(0);
					//We set the location of the agent in order to make the move
					agent.setLocation(currentLocation);
					remainingTime -= time;
				}
				// We add the gama agent associated to this edge
				gl.add(edge.getAttribute("gama_agent"));
			}
			// We return the list of edges that the agent has traveled.
			return gl;
		}
		// The agent can't move within the network. We return an empty list
		return null;
	}

	private void movingFromInsideToOutside(final IScope scope, final IAgent agent, final ILocation target){
		if(agentFromInsideToOutside && remainingTime > 0){
			GamaPoint currentLocation = (GamaPoint) agent.getLocation().copy(scope);
			// Compute the time needed to go to the next side of the segment
			double x_agent = currentLocation.getX();
			double y_agent = currentLocation.getY();

			double x_target = target.getX();
			double y_target = target.getY();

			if(x_agent != x_target || y_agent != y_target){
				double dist = Math.hypot(x_agent - x_target, y_agent - y_target);
				double time = dist / getDefaultSpeed(agent);

				// Move the agent
				if(remainingTime >= time){
					currentLocation.setLocation(x_target, y_target);
					agent.setLocation(currentLocation);
				}
				else{
					double coef = remainingTime / time;
					double x_inter = x_agent + (x_target - x_agent) * coef;
					double y_inter = y_agent + (y_target - y_agent) * coef;
					currentLocation.setLocation(x_inter, y_inter);
				}
				agent.setLocation(currentLocation);
				remainingTime -= time;
			}
		}
	}

	/**
	 * Move the agent along an edge. There are two possibilities to stop the agent on this edges :
	 * - firstly, there is not enough remaining time to reach the end of this edge.
	 * - secondly, the next move will be to leave the network and reach the target (it is also possible that the agent has not enough time to reach the exit point).
	 * @param scope the current scope
	 * @param agent the current agent
	 * @param target the final target to reach
	 * @param e the current edge
	 */
	private void moveAlongEdge(final IScope scope, final IAgent agent, final ILocation target, Edge e){
		((IAgent)currentGsPathEdge.get(0).getAttribute("gama_agent")).setAttribute("color", "blue");
		GamaPoint currentLocation = (GamaPoint) agent.getLocation().copy(scope);
		agentOnANode = false;

		// Get the geometry of the edge
		IShape shape = ((IAgent)(e.getAttribute("gama_agent"))).getGeometry();
		final Coordinate coords[] = shape.getInnerGeometry().getCoordinates();
		// And find the segment where the agent is
		int i = 0;
		boolean findSegment = false;
		while( !findSegment && i < coords.length - 1 ) {
			if(belongsToSegment(coords[i], coords[i + 1], new Coordinate(currentLocation.getX(), currentLocation.getY())))
				findSegment = true;
			else
				i++;
		}

		// Determine in which way we must browse the list of segments
		boolean incrementWay = true;
		if(coords[coords.length-1].x != currentGsPathNode.get(0).getNumber("x") || coords[coords.length-1].y != currentGsPathNode.get(0).getNumber("y"))
			incrementWay = false;
		else
			i++;

		// Determine if the agent must stop before the end of the edge because he must leave the network
		// If yes, we look for the segment that the agent must leave
		int indexClosestSegmentToTarget = -1;
		if(e.equals(currentGsPathEdge.get(currentGsPathEdge.size()-1))){
			double distTargetToNetwork = Double.MAX_VALUE;
			Coordinate[] tempCoord = new Coordinate[2];
			for ( int j = 0; j < coords.length - 1; j++ ) {
				tempCoord[0] = coords[j];
				tempCoord[1] = coords[j + 1];
				LineString segment = GeometryUtils.FACTORY.createLineString(tempCoord);
				double distS = segment.distance(target.getInnerGeometry());
				if ( distS < distTargetToNetwork ) {
					distTargetToNetwork = distS;
					indexClosestSegmentToTarget = j;
				}
			}
		}
		// Browse the segment and move progressively the agent on the edge
		do {
			Coordinate dest;
			if(indexClosestSegmentToTarget != -1 && (i == indexClosestSegmentToTarget || (i+1) == indexClosestSegmentToTarget) )
				dest = getClosestLocation(new Coordinate(target.getX(), target.getY()), coords[i], coords[i+1]);
			else 
				dest = coords[i];

			// Compute the time needed to go to the next side of the segment
			double x_agent = currentLocation.getX();
			double y_agent = currentLocation.getY();

			double dist = Math.sqrt((x_agent - dest.x)*(x_agent - dest.x) + (y_agent - dest.y)*(y_agent - dest.y));
			double time = dist / (e.getNumber(getSpeedAttribute(agent))*1000/3600);

			// Move the agent
			if(remainingTime >= time){
				currentLocation.setLocation(dest.x, dest.y);
			}
			else{
				double coef = remainingTime / time;
				double x_inter = x_agent + (dest.x - x_agent) * coef;
				double y_inter = y_agent + (dest.y - y_agent) * coef;
				currentLocation.setLocation(x_inter, y_inter);
			}
			agent.setLocation(currentLocation);
			// Update the remaining time
			remainingTime -= time;

			// Increment or decrement i according to the way that we browse the list of segments
			if(incrementWay)
				i++;
			else
				i--;
		}while(remainingTime > 0 && i >= 0 && i < coords.length);

		if(agent.getLocation().getX() == currentGsPathNode.get(0).getNumber("x") && agent.getLocation().getY() == currentGsPathNode.get(0).getNumber("y")){
			agentOnANode = true;
			currentGsPathEdge.remove(0);
			currentGsPathNode.remove(0);
		}
	}

	/**
	 * Check if the point C is on the segment delimited by point A and C
	 * @param a The coordinate of the point A
	 * @param b The coordinate of the point B
	 * @param c The coordinate of the point C
	 * @return true if C belongs to the segment AB, false otherwise.
	 */
	private boolean belongsToSegment(final Coordinate a, final Coordinate b, final Coordinate c){
		// Need to use BigDecimal due to error of approximation with double values and Math.sqrt
		BigDecimal ax = new BigDecimal(a.x);
		BigDecimal ay = new BigDecimal(a.y);
		BigDecimal bx = new BigDecimal(b.x);
		BigDecimal by = new BigDecimal(b.y);
		BigDecimal cx = new BigDecimal(c.x);
		BigDecimal cy = new BigDecimal(c.y);
		BigDecimal ac = cx.subtract(ax).pow(2).add(cy.subtract(ay).pow(2));
		if(ac.compareTo(new BigDecimal("0E-52")) == 0 )
			ac = BigDecimal.ZERO;
		else
			ac = sqrt(cx.subtract(ax).pow(2).add(cy.subtract(ay).pow(2)));

		BigDecimal cb = bx.subtract(cx).pow(2).add(by.subtract(cy).pow(2));
		if(cb.compareTo(new BigDecimal("0E-52")) == 0 )
			cb = BigDecimal.ZERO;
		else
			cb = sqrt(bx.subtract(cx).pow(2).add(by.subtract(cy).pow(2)));

		BigDecimal ab = sqrt(bx.subtract(ax).pow(2).add(by.subtract(ay).pow(2)));
		// When all the computations have been done, we can and must use a rounding value (again due to approximation of sqrt function).
		return ac.add(cb).setScale(14, RoundingMode.HALF_UP).equals(ab.setScale(14, RoundingMode.HALF_UP));
	}

	/**
	 * Compute the square root of a BigDecimal number
	 * @param in the variable whose we want to compute its square root
	 * @return The square root of "in"
	 */
	private static BigDecimal sqrt(BigDecimal in){
		int scale = in.scale();
		BigDecimal sqrt = new BigDecimal(1);
		sqrt.setScale(scale + 3, RoundingMode.FLOOR);
		BigDecimal store = new BigDecimal(in.toString());
		boolean first = true;
		do{
			if (!first){
				store = new BigDecimal(sqrt.toString());
			}
			else first = false;
			store.setScale(scale + 3, RoundingMode.FLOOR);
			sqrt = in.divide(store, scale + 3, RoundingMode.FLOOR).add(store).divide(
					BigDecimal.valueOf(2), scale + 3, RoundingMode.FLOOR);
		}while (!store.equals(sqrt));
		return sqrt.setScale(scale, RoundingMode.FLOOR);
	}

	private Coordinate getClosestLocation(Coordinate coordOutNetwork, Coordinate a, Coordinate b){
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

	private ILocation findTargetLocation(final IScope scope) {
		final Object target = scope.getArg("target", IType.NONE);
		if ( target != null && target instanceof ILocated )
			return ((ILocated) target).getLocation();
		return null;
	}

	private void computeShortestPath(final IScope scope, ILocation source, ILocation target){
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
		Path p = dijkstra.getPath(targetNode);

		/*
		 * Add closest edge(s)
		 */

		// Add closest source edge to the path if it is missing
		if(!p.contains(gsSourceEdge)){
			sourceNode = gsSourceEdge.getNode1();
			dijkstra.setSource(sourceNode);
			dijkstra.compute();
			p = dijkstra.getPath(targetNode);
		}

		// Add closest target edge to the path if it is missing
		if(!p.contains(gsTargetEdge)){
			targetNode = gsTargetEdge.getNode1();
			p = dijkstra.getPath(targetNode);
		}

		// just for debug ================================================>
		for(Edge e : p.getEachEdge()){
			IAgent a = (IAgent) e.getAttribute("gama_agent");
			a.setAttribute("color", "red");
		}
		// <===============================================================

		currentGsPathEdge = p.getEdgePath();
		currentGsPathNode = p.getNodePath();
		currentGsPathNode.remove(0);// The first node is useless
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
					// a know e
					a.setAttribute("graphstream_edge", e);
					// and e know a
					e.addAttribute("gama_agent", a);
					for ( Object key : a.getAttributes().keySet() ) {
						Object value = GraphUtilsGraphStream.preprocessGamaValue(a.getAttributes().get(key));
						e.addAttribute(key.toString(), value.toString());
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
