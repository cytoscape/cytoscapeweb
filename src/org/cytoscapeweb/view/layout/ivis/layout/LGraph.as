package org.cytoscapeweb.view.layout.ivis.layout
{
	import org.as3commons.collections.ArrayList;
	import org.as3commons.collections.LinkedList;
	import org.as3commons.collections.Set;
	import org.as3commons.collections.framework.ICollection;
	import org.as3commons.collections.framework.IIterator;
	import org.as3commons.collections.framework.IList;
	import org.cytoscapeweb.view.layout.ivis.util.PointD;
	import org.cytoscapeweb.view.layout.ivis.util.RectangleD;

/*
import java.util.*;
import java.awt.Point;
import java.awt.Rectangle;
*/

/**
 * This class represents a graph (l-level) for layout purposes. A graph
 * maintains a list of nodes and (intra-graph) edges. An l-level graph is always
 * a child of an l-level compound node. The root of the compound graph structure
 * is a child of the root node, which is the only node in a compound structure
 * without an owner graph.
 *
 * @author Erhan Giral
 * @author Ugur Dogrusoz
 * @author Cihan Kucukkececi
 *
 * Copyright: i-Vis Research Group, Bilkent University, 2007 - present
 */
public class LGraph extends LGraphObject
{
// -----------------------------------------------------------------------------
// Section: Instance variables
// -----------------------------------------------------------------------------
	/*
	 * Nodes maintained by this graph
	 */
	private var nodes:IList;

	/*
	 * Edges whose source and target nodes are in this graph
	 */
	private var edges:IList;

	/*
	 * Owner graph manager
	 */
	private var graphManager:LGraphManager;

	/*
	 * Parent node of this graph. This should never be null (the parent of the
	 * root graph is the root node) when this graph is part of a compound
	 * structure (i.e. a graph manager).
	 */
	internal /*protected*/ var parent:LNode;

	/*
	 * Geometry of this graph (i.e. that of its tightest bounding rectangle,
	 * also taking margins into account)
	 */
	private var top:int;
	private var left:int;
	private var bottom:int;
	private var right:int;

	/*
	 * Estimated size of this graph based on estimated sizes of its contents
	 */
	protected var estimatedSize:int = int.MIN_VALUE;

	/*
	 * Whether the graph is connected or not, taking indirect edges (e.g. an
	 * edge connecting a child node of a node of this graph to another node of
	 * this graph) into account.
	 */
	private var _isConnected:Boolean;

// -----------------------------------------------------------------------------
// Section: Constructors and initialization
// -----------------------------------------------------------------------------
	/*
	 * Constructor
	 */
	public function LGraph(parent:LNode,
		graphMgr:LGraphManager,
		vGraph:*,//vGraph:Object,
		layout:Layout = null)
	{
		super(vGraph);
		this.initialize();
		this.parent = parent;
		
		if (layout == null)
		{
			this.graphManager = graphMgr;
		}
		else
		{
			this.graphManager = layout.getGraphManager();
		}
	}

	/*
	 * Alternative constructor
	 */
	/*
	protected function LGraph(parent:LNode, layout:Layout, vGraph:Object)
	{
		super(vGraph);
		this.initialize();
		this.parent = parent;
		this.graphManager = layout.graphManager;
	}
	*/

	private function initialize():void {
		this.edges = new ArrayList();
		this.nodes = new ArrayList();
		this._isConnected = false;
	}

// -----------------------------------------------------------------------------
// Section: Accessors
// -----------------------------------------------------------------------------
	/**
	 * This method returns the list of nodes in this graph.
	 */
	public function getNodes():IList
	{
		return nodes;
	}

	/**
	 * This method returns the list of edges in this graph.
	 */
	public function getEdges():IList
	{
		return edges;
	}

	/**
	 * This method returns the graph manager of this graph.
	 */
	public function getGraphManager():LGraphManager
	{
		return graphManager;
	}

	/**
	 * This method returns the parent node of this graph. If this graph is the
	 * root of the nesting hierarchy, then null is returned.
	 */
	public function getParent():LNode
	{
		return parent;
	}

	/**
	 * This method returns the left of the bounds of this graph. Notice that
	 * bounds are not always up-to-date.
	 */
	public function getLeft():int
	{
		return this.left;
	}

	/**
	 * This method returns the right of the bounds of this graph. Notice that
	 * bounds are not always up-to-date.
	 */
	public function getRight():int
	{
		return this.right;
	}

	/**
	 * This method returns the top of the bounds of this graph. Notice that
	 * bounds are not always up-to-date.
	 */
	public function getTop():int
	{
		return this.top;
	}

	/**
	 * This method returns the bottom of the bounds of this graph. Notice that
	 * bounds are not always up-to-date.
	 */
	public function getBottom():int
	{
		return this.bottom;
	}

	/**
	 * This method returns whether this graph is connected or not.
	 */
	public function isConnected():Boolean
	{
		return this._isConnected;
	}

// -----------------------------------------------------------------------------
// Section: Topology related
// -----------------------------------------------------------------------------
	/**
	 * This methods adds the given node to this graph. We assume this graph has
	 * a proper graph manager.
	 */
	public function addNode(newNode:LNode):LNode
	{
		//assert (this.graphManager != null) : "Graph has no graph mgr!";
		//assert (!this.getNodes().contains(newNode)) : "Node already in graph!";
		newNode.setOwner(this);
		this.getNodes().add(newNode);

		return newNode;
	}

	/**
	 * This methods adds the given edge to this graph with specified nodes as
	 * source and target.
	 */
	public function addEdge(newEdge:LEdge, sourceNode:LNode, targetNode:LNode):LEdge
	{
	//	assert (this.getNodes().contains(sourceNode) &&
	//		(this.getNodes().contains(targetNode))) :
	//			"Source or target not in graph!";
		
	//	assert (sourceNode.owner == targetNode.owner &&
	//		sourceNode.owner == this) :
	//		"Both owners must be this graph!";

		if (sourceNode.getOwner() != targetNode.getOwner())
		{
			return null;
		}
		
		// set source and target
		newEdge.source = sourceNode;
		newEdge.target = targetNode;

		// set as intra-graph edge
		newEdge._isInterGraph = false;

		// add to graph edge list
		this.getEdges().add(newEdge);

		// add to incidency lists
		sourceNode.getEdges().add(newEdge);

		if (targetNode != sourceNode)
		{
			targetNode.getEdges().add(newEdge);
		}
		
		return newEdge;
	}

	/**
	 * This method removes the input node from this graph. If the node has any
	 * incident edges, they are removed from the graph (the graph manager for
	 * inter-graph edges) as well.
	 */
	public function removeNode(node:LNode):void
	{
	//	assert (node != null) : "Node is null!";
	//	assert (node.owner != null && node.owner == this) :
	//		"Owner graph is invalid!";
	//	assert (this.graphManager != null) : "Owner graph manager is invalid!";

		// remove incident edges first (make a copy to do it safely)
		var edgesToBeRemoved:ArrayList = new ArrayList();

		edgesToBeRemoved.addAllAt(0, node.getEdges().toArray());

		var iter:IIterator = edgesToBeRemoved.iterator();
		
		//for each (var edge:LEdge in edgesToBeRemoved)
		while (iter.hasNext())
		{
			var edge:LEdge = iter.next() as LEdge;
			
			if (edge.isInterGraph())
			{
				this.graphManager.removeEdge(edge);
			}
			else
			{
				edge.getSource().getOwner().removeEdge(edge);
			}
		}

		// now the node itself
		//assert (this.nodes.contains(node)) : "Node not in owner node list!";
		this.nodes.remove(node);
	}

	/**
	 * This method removes the input edge from this graph. Should not be used
	 * for inter-graph edges.
	 */
	public function removeEdge(edge:LEdge):void
	{
	//	assert (edge != null) : "Edge is null!";
	//	assert (edge.source != null && edge.target != null) :
	//		"Source and/or target is null!";
	//	assert (edge.source.owner != null && edge.target.owner != null &&
	//		edge.source.owner == this && edge.target.owner == this) :
	//			"Source and/or target owner is invalid!";

		// remove edge from source and target nodes' incidency lists

	//	assert (edge.source.edges.contains(edge) &&
	//		edge.target.edges.contains(edge)) :
	//			"Source and/or target doesn't know this edge!";

		edge.getSource().getEdges().remove(edge);

		if (edge.getTarget() != edge.getSource())
		{
			edge.getTarget().getEdges().remove(edge);
		}

		// remove edge from owner graph's edge list

	//	assert (edge.source.owner.getEdges().contains(edge)) :
	//		"Not in owner's edge list!";

		edge.getSource().getOwner().getEdges().remove(edge);
	}

// -----------------------------------------------------------------------------
// Section: Remaining methods
// -----------------------------------------------------------------------------
	/**
	 * This method calculates, updates and returns the left-top point of this
	 * graph including margins.
	 * 
	 * @return		TODO (PointD instead of Point)
	 */
	public function updateLeftTop():PointD
	{
		var top:int= int.MAX_VALUE;
		var left:int= int.MAX_VALUE;
		var nodeTop:int;
		var nodeLeft:int;

		var iter:IIterator= this.getNodes().iterator();

		//for each (var lNode:LNode in this.getNodes())
		while (iter.hasNext())
		{
			var lNode:LNode = iter.next() as LNode;
			
			nodeTop = lNode.getTop();
			nodeLeft = lNode.getLeft();

			if (top > nodeTop)
			{
				top = nodeTop;
			}

			if (left > nodeLeft)
			{
				left = nodeLeft;
			}
		}

		// Do we have any nodes in this graph?
		if (top == int.MAX_VALUE)
		{
			return null;
		}

		this.left = left - graphMargin;
		this.top =  top - graphMargin;

		// Apply the margins and return the result
		return new PointD(this.left, this.top);
	}

	/**
	 * This method calculates and updates the bounds of this graph including
	 * margins in a recursive manner, so that
	 * all compound nodes in this and lower levels will have up-to-date boundaries.
	 * Recursiveness of the function is controlled by the parameter named "recursive".
	 */
	public function updateBounds(recursive:Boolean):void
	{
		// calculate bounds
		var left:int = int.MAX_VALUE;
		var right:int = -1 * int.MAX_VALUE;
		var top:int = int.MAX_VALUE;
		var bottom:int = -1 * int.MAX_VALUE;
		var nodeLeft:int;
		var nodeRight:int;
		var nodeTop:int;
		var nodeBottom:int;

		var iter:IIterator = this.nodes.iterator();
		
		//for each (var lNode:LNode in this.nodes)
		while (iter.hasNext())
		{
			var lNode:LNode = iter.next() as LNode;
			// if it is a recursive call, and current node is compound
			if (recursive && lNode.getChild() != null)
			{
				lNode.updateBounds();
			}
			
			nodeLeft = lNode.getLeft();
			nodeRight = lNode.getRight();
			nodeTop = lNode.getTop();
			nodeBottom = lNode.getBottom();

			if (left > nodeLeft)
			{
				left = nodeLeft;
			}

			if (right < nodeRight)
			{
				right = nodeRight;
			}

			if (top > nodeTop)
			{
				top = nodeTop;
			}

			if (bottom < nodeBottom)
			{
				bottom = nodeBottom;
			}
		}

		// TODO RectangleD instead of Rectangle
		var boundingRect:RectangleD=
			new RectangleD(left, top, right - left, bottom - top);

		// Do we have any nodes in this graph?
		if (left == int.MAX_VALUE)
		{
			this.left =  this.parent.getLeft();
			this.right = this.parent.getRight();
			this.top =  this.parent.getTop();
			this.bottom = this.parent.getBottom();
		}

		this.left = boundingRect.x - graphMargin;
		this.right = boundingRect.x + boundingRect.width + graphMargin;
		this.top =  boundingRect.y - graphMargin;
		// Label text dimensions are to be added for the bottom of the compound!
		this.bottom = boundingRect.y + boundingRect.height + graphMargin;
	}

	/**
	 * This method returns the bounding rectangle of the given list of nodes. No
	 * margins are accounted for, and it returns a rectangle with top-left set
	 * to Integer.MAX_VALUE if the list is empty.
	 * 
	 * @return		TODO (RectangleD instead of java.awt.Rectangle)
	 */
	public static function calculateBounds(nodes:IList/*<LNode>*/):RectangleD
	{
		var left:int = int.MAX_VALUE;
		var right:int = -int.MAX_VALUE;
		var top:int = int.MAX_VALUE;
		var bottom:int = -int.MAX_VALUE;
		var nodeLeft:int;
		var nodeRight:int;
		var nodeTop:int;
		var nodeBottom:int;

		var iter:IIterator = nodes.iterator();

		//for each (var lNode:LNode in nodes)
		while (iter.hasNext())
		{
			var lNode:LNode = iter.next() as LNode;
			
			nodeLeft = lNode.getLeft();
			nodeRight = lNode.getRight();
			nodeTop = lNode.getTop();
			nodeBottom = lNode.getBottom();

			if (left > nodeLeft)
			{
				left = nodeLeft;
			}

			if (right < nodeRight)
			{
				right = nodeRight;
			}

			if (top > nodeTop)
			{
				top = nodeTop;
			}

			if (bottom < nodeBottom)
			{
				bottom = nodeBottom;
			}
		}

		var boundingRect:RectangleD =
			new RectangleD(left, top, right - left, bottom - top);

		return boundingRect;
	}

	/**
	 * This method returns the depth of the parent node of this graph, if any,
	 * in the inclusion tree (nesting hierarchy).
	 */
	public function getInclusionTreeDepth():int
	{
		if (this == this.graphManager.getRoot())
		{
			return 1;
		}
		else
		{
			return this.parent.getInclusionTreeDepth();
		}
	}

	/**
	 * This method returns estimated size of this graph.
	 */
	public function getEstimatedSize():int
	{
		//assert this.estimatedSize != Integer.MIN_VALUE;
		return this.estimatedSize;
	}

	/*
	 * This method calculates and returns the estimated size of this graph as
	 * well as the estimated sizes of the nodes in this graph recursively. The
	 * estimated size of a graph is based on the estimated sizes of its nodes.
	 * In fact, this value is the exact average dimension for non-compound nodes
	 * and it is a rather rough estimation on the dimension for compound nodes.
	 */
	public function calcEstimatedSize():int
	{
		var size:int= 0;
		var iter:IIterator = this.nodes.iterator();

		//for each (var lNode:LNode in this.nodes)
		while (iter.hasNext())
		{
			var lNode:LNode = iter.next() as LNode;
			size += lNode.calcEstimatedSize();
		}

		if (size == 0)
		{
			this.estimatedSize = LayoutConstants.EMPTY_COMPOUND_NODE_SIZE;
		}
		else
		{
			this.estimatedSize = (size / Math.sqrt(this.nodes.size));
		}

		return this.estimatedSize;
	}

	/**
	 * This method updates whether this graph is connected or not, taking
	 * indirect edges (e.g. an edge connecting a child node of a node of this
	 * graph to another node of this graph) into account.
	 */
	public function updateConnected():void
	{
		if (this.nodes.size == 0)
		{
			this._isConnected = true;
			return;
		}

		var toBeVisited:LinkedList/*<LNode>*/ = new LinkedList/*<LNode>*/();
		var visited:Set/*<LNode>*/ = new Set/*<LNode>*/();
		var currentNode:LNode= this.nodes.itemAt(0) as LNode;
		var neighborEdges:ICollection/*<LEdge>*/;
		var currentNeighbor:LNode;

		
		var iter:IIterator = currentNode.withChildren().iterator();
		
		//toBeVisited.addAll(currentNode.withChildren());
		//for each (obj in currentNode.withChildren())
		while (iter.hasNext())
		{
			toBeVisited.add(iter.next());
		}

		while (toBeVisited.size != 0)
		{
			currentNode = toBeVisited.removeFirst();
			visited.add(currentNode);

			// Traverse all neighbors of this node
			neighborEdges = currentNode.getEdges();
			iter = neighborEdges.iterator();
				
			//for each (var neighborEdge:LEdge in neighborEdges)
			while (iter.hasNext())
			{
				var neighborEdge:LEdge = iter.next() as LEdge;
				
				currentNeighbor =
					neighborEdge.getOtherEndInGraph(currentNode, this);

				// Add unvisited neighbors to the list to visit
				if (currentNeighbor != null &&
					!visited.has(currentNeighbor))
				{
					var iter2:IIterator =
						currentNeighbor.withChildren().iterator();
						
					//toBeVisited.addAll(currentNeighbor.withChildren());
					//for each (obj in currentNeighbor.withChildren())
					while (iter2.hasNext())
					{
						toBeVisited.add(iter2.next());
					}
				}
			}
		}

		this._isConnected = false;

		if (visited.size >= this.nodes.size)
		{
			var noOfVisitedInThisGraph:int= 0;

			iter = visited.iterator();
				
			//for each (var visitedNode:LNode in visited)
			while (iter.hasNext())
			{
				var visitedNode:LNode = iter.next() as LNode;
				
				if (visitedNode.getOwner() == this)
				{
					noOfVisitedInThisGraph++;
				}
			}

			if (noOfVisitedInThisGraph == this.nodes.size)
			{
				this._isConnected = true;
			}
		}
	}
	
	/**
	 * This method reverses the given edge by swapping the source and target
	 * nodes of the edge.
	 * 
	 * @param edge	edge to be reversed
	 */
	public function reverse(edge:LEdge):void
	{
		edge.getSource().getOwner().getEdges().remove(edge);
		edge.getTarget().getOwner().getEdges().add(edge);
		
		var swap:LNode= edge.source;
		edge.source = edge.target;
		edge.target = swap;
	}

// -----------------------------------------------------------------------------
// Section: Testing methods
// -----------------------------------------------------------------------------
	/**
	 * This method prints the topology of this graph.
	 */
	public function printTopology():void
	{
		trace((this.label == null ? "?" : this.label) + ": ");

		trace("Nodes[" + this.nodes.size + "]: ");
		
		for each (var node:LNode in this.nodes.toArray())
		{
			node.printTopology();
		}

		trace("Edges[" + this.edges.size + "]: ");
		
		for each (var edge:LEdge in this.edges.toArray())
		{
			edge.printTopology();
		}
		
		trace();
	}

// -----------------------------------------------------------------------------
// Section: Class methods
// -----------------------------------------------------------------------------
	/**
	 * This method returns the margins of l-level graphs to be applied on the
	 * bounding rectangle of its contents.
	 */
	public static function getGraphMargin():int
	{
		return LGraph.graphMargin;
	}

	/**
	 * This method sets the margins of l-level graphs to be applied on the
	 * bounding rectangle of its contents.
	 */
	public static function setGraphMargin(margin:int):void
	{
		LGraph.graphMargin = margin;
	}

// -----------------------------------------------------------------------------
// Section: Class variables
// -----------------------------------------------------------------------------
	/*
	 * Margins of this graph to be applied on bouding rectangle of its contents
	 */
	protected static var graphMargin:int= LayoutConstants.GRAPH_MARGIN_SIZE;
}
}