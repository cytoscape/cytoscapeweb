package org.cytoscapeweb.view.layout.ivis.layout
{
/*
import java.util.*;
import java.awt.Point;
import java.awt.Dimension;
*/
import org.as3commons.collections.ArrayList;
import org.as3commons.collections.LinkedList;
import org.as3commons.collections.Set;
import org.as3commons.collections.framework.ICollection;
import org.as3commons.collections.framework.IIterator;
import org.as3commons.collections.framework.IList;
import org.cytoscapeweb.view.layout.ivis.util.DimensionD;
import org.cytoscapeweb.view.layout.ivis.util.PointD;
import org.cytoscapeweb.view.layout.ivis.util.Random;
import org.cytoscapeweb.view.layout.ivis.util.RectangleD;
import org.cytoscapeweb.view.layout.ivis.util.Transform;

/**
 * This class represents a node (l-level) for layout purposes. A node maintains
 * a list of its incident edges, which includes inter-graph edges. Every node
 * has an owner graph, except for the root node, which resides at the top of the
 * nesting hierarchy along with its child graph (the root graph).
 *
 * @author Erhan Giral
 * @author Ugur Dogrusoz
 * @author Cihan Kucukkececi
 *
 * Copyright: i-Vis Research Group, Bilkent University, 2007 - present
 */
public class LNode extends LGraphObject
{
// -----------------------------------------------------------------------------
// Section: Instance variables
// -----------------------------------------------------------------------------
	/*
	 * Owner graph manager of this node
	 */
	protected var graphManager:LGraphManager;

	/**
	 * Possibly null child graph of this node
	 */
	protected var child:LGraph;

	/*
	 * Owner graph of this node; cannot be null
	 */
	protected var owner:LGraph;

	/*
	 * List of edges incident with this node
	 */
	protected var edges:LinkedList;

	/*
	 * Geometry of this node
	 */
	protected var rect:RectangleD;

	/*
	 * Cluster ID of this node (this is here since it might be needed by layout
	 * styles other than CiSE layout)
	 */
	protected var clusterID:String;

	/*
	 * Estimated initial size (needed for compound node size estimation)
	 */
	private var estimatedSize:int = int.MIN_VALUE;

	/*
	 * Depth of this node in nesting hierarchy. Nodes in the root graph are of
	 * depth 1, nodes in the child graph of a node in the graph are of depth 2,
	 * etc.
	 */
	internal /*protected*/ var inclusionTreeDepth:int = int.MAX_VALUE;

// -----------------------------------------------------------------------------
// Section: Constructors and initialization
// -----------------------------------------------------------------------------
	/*
	 * Constructor
	 */
	/*
	protected function LNode(gm:LGraphManager, vNode:Object)
	{
		super(vNode);
		this.initialize();
		this.graphManager = gm;
		rect = new RectangleD();
	}
	*/
	
	/*
	 * Alternative constructor
	 * TODO using PointD and DimensionD instead of Point and Dimension
	 */
	public function LNode(gm:LGraphManager,
		vNode:*, //vNode:Object,
		loc:PointD = null,
		size:DimensionD = null,
		layout:Layout = null)
	{
		super(vNode);
		this.initialize();
		
		if (layout == null)
		{
			this.graphManager = gm;
		}
		else
		{
			this.graphManager = layout.getGraphManager();
		}
		
		if (loc == null || size == null)
		{
			rect = new RectangleD();
		}
		else
		{
			rect = new RectangleD(loc.x, loc.y, size.width, size.height);
		}
	}

	/*
	 * Alternative constructor
	 */
	/*
	protected function LNode(layout:Layout, vNode:Object)
	{
		super(vNode);
		this.initialize();
		this.graphManager = layout.graphManager;
		rect = new RectangleD();
	}
	*/
	
	public function initialize():void
	{
		this.edges = new LinkedList();
		this.clusterID = null;
	}

// -----------------------------------------------------------------------------
// Section: Accessors
// -----------------------------------------------------------------------------
	/**
	 * This method returns the list of incident edges of this node.
	 */
	public function getEdges():LinkedList
	{
		return this.edges;
	}

	/**
	 * This method returns the child graph of this node, if any. Only compound
	 * nodes will have child graphs.
	 */
	public function getChild():LGraph
	{
		return child;
	}

	/**
	 * This method sets the child graph of this node. Only compound nodes will
	 * have child graphs.
	 */
	public function setChild(child:LGraph):void
	{
	//	assert (child.getGraphManager() == this.graphManager) :
	//		"Child has different graph mgr!";

		this.child = child;
	}

	/**
	 * This method returns the owner graph of this node.
	 */
	public function getOwner():LGraph
	{
	//	assert (this.owner == null || this.owner.getNodes().contains(this));

		return this.owner;
	}

	/**
	 * This method sets the owner of this node as input graph.
	 */
	public function setOwner(owner:LGraph):void
	{
		this.owner = owner;
	}

	/**
	 * This method returns the width of this node.
	 */
	public function getWidth():Number
	{
		return this.rect.width;
	}

	/**
	 * This method sets the width of this node.
	 */
	public function setWidth(width:Number):void
	{
		this.rect.width = width;
	}

	/**
	 * This method returns the height of this node.
	 */
	public function getHeight():Number
	{
		return this.rect.height;
	}

	/**
	 * This method sets the height of this node.
	 */
	public function setHeight(height:Number):void
	{
		this.rect.height = height;
	}

	/**
	 * This method returns the left of this node.
	 */
	public function getLeft():Number
	{
		return this.rect.x;
	}

	/**
	 * This method returns the right of this node.
	 */
	public function getRight():Number
	{
		return this.rect.x + this.rect.width;
	}

	/**
	 * This method returns the top of this node.
	 */
	public function getTop():Number
	{
		return this.rect.y;
	}

	/**
	 * This method returns the bottom of this node.
	 */
	public function getBottom():Number
	{
		return this.rect.y + this.rect.height;
	}

	/**
	 * This method returns the x coordinate of the center of this node.
	 */
	public function getCenterX():Number
	{
		return this.rect.x + this.rect.width / 2;
	}

	/**
	 * This method returns the y coordinate of the center of this node.
	 */
	public function getCenterY():Number
	{
		return this.rect.y + this.rect.height / 2;
	}

	/**
	 * This method returns the center of this node.
	 */
	public function getCenter():PointD
	{
		return new PointD(this.rect.x + this.rect.width / 2,
			this.rect.y + this.rect.height / 2);
	}

	/**
	 * This method returns the location (upper-left corner) of this node.
	 */
	public function getLocation():PointD
	{
		return new PointD(this.rect.x, this.rect.y);
	}

	/**
	 * This method returns the geometry of this node.
	 */
	public function getRect():RectangleD
	{
		return this.rect;
	}

	/**
	 * This method returns the diagonal length of this node.
	 */
	public function getDiagonal():Number
	{
		return Math.sqrt(this.rect.width * this.rect.width +
			this.rect.height * this.rect.height);
	}

	/**
	 * This method returns half the diagonal length of this node.
	 */
	public function getHalfTheDiagonal():Number
	{
		return Math.sqrt(this.rect.height * this.rect.height +
			this.rect.width * this.rect.width) / 2;
	}

	/**
	 * This method sets the geometry of this node.
	 * 
	 * @param upperLeft	TODO (PointD instead of Point)
	 * @param dimension	TODO (DimensionD instead of Dimension)
	 */
	public function setRect(upperLeft:PointD, dimension:DimensionD):void
	{
		this.rect.x = upperLeft.x;
		this.rect.y = upperLeft.y;
		this.rect.width = dimension.width;
		this.rect.height = dimension.height;
	}

	/**
	 * This method sets the center of this node.
	 */
	public function setCenter(cx:Number, cy:Number):void
	{
		this.rect.x = cx - this.rect.width / 2;
		this.rect.y = cy - this.rect.height / 2;
	}

	/**
	 * This method sets the location of this node.
	 */
	public function setLocation(x:Number, y:Number):void
	{
		this.rect.x = x;
		this.rect.y = y;
	}

	/**
	 * This method moves the geometry of this node by specified amounts.
	 */
	public function moveBy(dx:Number, dy:Number):void
	{
		this.rect.x += dx;
		this.rect.y += dy;
	}

	/**
	 * This method returns the cluster ID of this node.
	 */
	public function getClusterID():String
	{
		return this.clusterID;
	}

	/**
	 * This method sets the cluster ID of this node.
	 */
	public function setClusterID(id:String):void
	{
		this.clusterID = id;
	}

// -----------------------------------------------------------------------------
// Section: Remaining methods
// -----------------------------------------------------------------------------
	/**
	 * This method returns all nodes emanating from this node.
	 */
	public function getEdgeListToNode(to:LNode):IList
	{
		var edgeList:IList/*<LEdge>*/ = new ArrayList();

		var iter:IIterator = this.edges.iterator();
		
		//for each (var edge:LEdge in this.edges)
		while (iter.hasNext())
		{
			var edge:LEdge = iter.next() as LEdge;
			
			if (edge.getTarget() == to)
			{
			//	assert (edge.source == this) : "Incorrect edge source!";
				
				edgeList.add(edge);
			}
		}

		return edgeList;
	}

	/**
	 *	This method returns all edges between this node and the given node.
	 */
	public function getEdgesBetween(other:LNode):IList
	{
		var edgeList:IList/*<LEdge>*/ = new ArrayList();

		var iter:IIterator = this.edges.iterator();
		
		//for each (var edge:LEdge in this.edges)
		while (iter.hasNext())
		{
			var edge:LEdge = iter.next() as LEdge;
		//	assert (edge.source == this || edge.target == this) :
		//		"Incorrect edge source and/or target";

			if ((edge.getTarget() == other) || (edge.getSource() == other))
			{
				edgeList.add(edge);
			}
		}

		return edgeList;
	}

	/**
	 * This method returns whether or not input node is a neighbor of this node.
	 */
	public function isNeighbor(node:LNode):Boolean
	{
		var iter:IIterator = this.edges.iterator();
		
		//for each (var edge:LEdge in this.edges)
		while (iter.hasNext())
		{
			var edge:LEdge = iter.next() as LEdge;
			
			if (edge.getSource() == node || edge.getTarget() == node)
			{
				return true;
			}
		}

		return false;
	}

	/**
	 * This method returns a set of neighbors of this node.
	 */
	public function getNeighborsList():Set
	{
		var neighbors:Set/*<LNode>*/ = new Set();

		var iter:IIterator = this.edges.iterator();
		
		//for each (var edge:LEdge in this.edges)
		while (iter.hasNext())
		{
			var edge:LEdge = iter.next() as LEdge;
			
			if (edge.getSource() == (this))
			{
				neighbors.add(edge.getTarget());
			}
			else
			{
			//	assert (edge.target == (this)) : "Incorrect incidency!";
				neighbors.add(edge.getSource());
			}
		}

		return neighbors;
	}

	/**
	 * This method returns a set of successors (outgoing nodes) of this node.
	 */
	public function getSuccessors():Set
	{
		var neighbors:Set/*<LNode>*/ = new Set();/*HashSet();*/

		var iter:IIterator = this.edges.iterator();
		
		//for each (var edge:LEdge in this.edges)
		while (iter.hasNext())
		{
			var edge:LEdge = iter.next() as LEdge;
			
		//	assert (edge.source == (this) || edge.target == (this)) :
		//		"Incorrect incidency!";

			if (edge.getSource() == this)
			{
				neighbors.add(edge.getTarget());
			}
		}

		return neighbors;
	}

	/**
	 * This method forms a list of nodes, composed of this node and its children
	 * (direct and indirect).
	 */
	public function withChildren():ICollection
	{
		var withNeighborsList:LinkedList/*<LNode>*/ = new LinkedList/*<LNode>*/();

		withNeighborsList.add(this);

		if (this.child != null)
		{
			var iter:IIterator = this.child.getNodes().iterator();
			
			// for each (childNode in this.child.getNodes())
			while (iter.hasNext())
			{
				var childNode:LNode = iter.next() as LNode;
			
				var iter2:IIterator = childNode.withChildren().iterator(); 
					
				// withNeighborsList.addAll(childNode.withChildren());
				//for each (var obj:* in childNode.withChildren())
				while (iter2.hasNext())
				{
					withNeighborsList.add(iter2.next());
				}
			}
		}

		return withNeighborsList;
	}

	/**
	 * This method returns the estimated size of this node, taking into account
	 * node margins and whether this node is a compound one containing others.
	 */
	public function getEstimatedSize():int
	{
	//	assert this.estimatedSize != Integer.MIN_VALUE;
		return this.estimatedSize;
	}

	/*
	 * This method calculates the estimated size of this node. If the node is
	 * a compound node, the operation is performed recursively. It also sets the
	 * initial sizes of compound nodes based on this estimate.
	 */
	public function calcEstimatedSize():int
	{
		if (this.child == null)
		{
			return this.estimatedSize =
				((this.rect.width + this.rect.height) / 2);
		}
		else
		{
			this.estimatedSize = this.child.calcEstimatedSize();
			this.rect.width = this.estimatedSize;
			this.rect.height = this.estimatedSize;

			return this.estimatedSize;
		}
	}

	/**
	 * This method positions this node randomly in both x and y dimensions. We
	 * assume the center to be at (WORLD_CENTER_X, WORLD_CENTER_Y).
	 */
	internal /*protected*/ function scatter():void
	{
		var randomCenterX:Number;
		var randomCenterY:Number;

		var minX:Number= -LayoutConstants.INITIAL_WORLD_BOUNDARY;
		var maxX:Number= LayoutConstants.INITIAL_WORLD_BOUNDARY;
		randomCenterX = LayoutConstants.WORLD_CENTER_X +
			(LNode.random.random() * (maxX - minX)) + minX;

		var minY:Number= -LayoutConstants.INITIAL_WORLD_BOUNDARY;
		var maxY:Number= LayoutConstants.INITIAL_WORLD_BOUNDARY;
		randomCenterY = LayoutConstants.WORLD_CENTER_Y +
			(LNode.random.random() * (maxY - minY)) + minY;

		this.rect.x = randomCenterX;
		this.rect.y = randomCenterY;
	}

	/**
	 * This method updates the bounds of this compound node.
	 */
	public function updateBounds():void
	{
	//	assert this.getChild() != null;

		if (this.getChild().getNodes().size != 0)
		{
			// wrap the children nodes by re-arranging the boundaries
			var childGraph:LGraph= this.getChild();
			childGraph.updateBounds(true);

			this.rect.x =  childGraph.getLeft();
			this.rect.y =  childGraph.getTop();

			this.setWidth(childGraph.getRight() - childGraph.getLeft() +
				2* LayoutConstants.COMPOUND_NODE_MARGIN);
			this.setHeight(childGraph.getBottom() - childGraph.getTop() +
				2* LayoutConstants.COMPOUND_NODE_MARGIN +
					LayoutConstants.LABEL_HEIGHT);
		}
	}

	/**
	 * This method returns the depth of this node in the inclusion tree (nesting
	 * hierarchy).
	 */
	public function getInclusionTreeDepth():int
	{
	//	assert this.inclusionTreeDepth != Integer.MAX_VALUE;
		return this.inclusionTreeDepth;
	}

	/**
	 * This method returns all parents (direct or indirect) of this node in the
	 * nesting hierarchy.
	 */
	public function getAllParents():Array /*Vector*/
	{
		var parents:Array= new Array();
		var rootNode:LNode= this.owner.getGraphManager().getRoot().getParent();
		var parent:LNode= this.owner.getParent();

		while (true)
		{
			if (parent != rootNode)
			{
				parents.push(parent);
			}
			else
			{
				break;
			}

			parent = parent.getOwner().getParent();
		}

		parents.push(rootNode);

		return parents;
	}

	/**
	 * This method transforms the layout coordinates of this node using input
	 * transform.
	 */
	public function transform(trans:Transform):void
	{
		var left:Number = this.rect.x;

		if (left > LayoutConstants.WORLD_BOUNDARY)
		{
			left = LayoutConstants.WORLD_BOUNDARY;
		}
		else if (left < -LayoutConstants.WORLD_BOUNDARY)
		{
			left = -LayoutConstants.WORLD_BOUNDARY;
		}

		var top:Number= this.rect.y;

		if (top > LayoutConstants.WORLD_BOUNDARY)
		{
			top = LayoutConstants.WORLD_BOUNDARY;
		}
		else if (top < -LayoutConstants.WORLD_BOUNDARY)
		{
			top = -LayoutConstants.WORLD_BOUNDARY;
		}

		var leftTop:PointD= new PointD(left, top);
		var vLeftTop:PointD= trans.inverseTransformPoint(leftTop);

		this.setLocation(vLeftTop.x, vLeftTop.y);
	}

// -----------------------------------------------------------------------------
// Section: Testing methods
// -----------------------------------------------------------------------------
	/**
	 * This method prints the topology of this node.
	 */
	public function printTopology():void
	{
		var str:String = new String();
		
		str += this.label == null ? "?" : this.label + "{";
		
		var otherEnd:LNode;
		
		for each (var edge:LEdge in this.edges.toArray())
		{
			otherEnd = edge.getOtherEnd(this);
			str += otherEnd.label == null ? "?" : otherEnd.label + ",";
		}
		
		str += "} ";
		
		trace(str);
	}

// -----------------------------------------------------------------------------
// Section: Class variables
// -----------------------------------------------------------------------------
	/*
	 * Used for random initial positioning
	 */
	private static var random:Random = new Random(Layout.RANDOM_SEED);
}
}