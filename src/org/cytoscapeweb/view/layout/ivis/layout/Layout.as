package org.cytoscapeweb.view.layout.ivis.layout
{

/*
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Iterator;
import java.util.LinkedList;
import java.util.List;
import java.util.Set;
import java.awt.Dimension;
import java.awt.Point;
*/

import flash.errors.IllegalOperationError;

import org.as3commons.collections.ArrayList;
import org.as3commons.collections.LinkedList;
import org.as3commons.collections.Map;
import org.as3commons.collections.Set;
import org.as3commons.collections.framework.ICollection;
import org.as3commons.collections.framework.IIterator;
import org.as3commons.collections.framework.IList;
import org.as3commons.collections.framework.core.AbstractList;
import org.cytoscapeweb.view.layout.ivis.util.DimensionD;
import org.cytoscapeweb.view.layout.ivis.util.PointD;
import org.cytoscapeweb.view.layout.ivis.util.Transform;

/**
 * This class lays out the associated graph model (LGraphManager, LGraph, LNode,
 * and LEdge). The framework also lets the users associate each l-level node and
 * edge with a view node and edge, respectively. It makes the necessary
 * callbacks (update methods) so that the results can be copied back to the
 * associated view object when layout is finished. Users are also given an
 * opportunity to perform any pre and post layout operations with respective
 * methods.
 *
 * @author Ugur Dogrusoz
 * @author Cihan Kucukkececi
 * @author Selcuk Onur Sumer
 *
 * Copyright: i-Vis Research Group, Bilkent University, 2007 - present
 */
public /*abstract*/ class Layout
{
// -----------------------------------------------------------------------------
// Section: Instance variables
// -----------------------------------------------------------------------------
	/**
	 * Layout Quality: 0:proof, 1:default, 2:draft
	 */
	protected var layoutQuality:int = LayoutConstants.DEFAULT_QUALITY;

	/**
	 * Whether layout should create bendpoints as needed or not
	 */
	protected var createBendsAsNeeded:Boolean =
		LayoutConstants.DEFAULT_CREATE_BENDS_AS_NEEDED;

	/**
	 * Whether layout should be incremental or not
	 */
	protected var incremental:Boolean = LayoutConstants.DEFAULT_INCREMENTAL;

	/**
	 * Whether we animate from before to after layout node positions
	 */
	public var animationOnLayout:Boolean=
		LayoutConstants.DEFAULT_ANIMATION_ON_LAYOUT;

	/**
	 * Whether we animate the layout process or not
	 */
	protected var animationDuringLayout:Boolean =
		LayoutConstants.DEFAULT_ANIMATION_DURING_LAYOUT;

	/**
	 * Number iterations that should be done between two successive animations
	 */
	protected var animationPeriod:int =
		LayoutConstants.DEFAULT_ANIMATION_PERIOD;

	/**
	 * Whether or not leaf nodes (non-compound nodes) are of uniform sizes. When
	 * they are, both spring and repulsion forces between two leaf nodes can be
	 * calculated without the expensive clipping point calculations, resulting
	 * in major speed-up.
	 */
	protected var uniformLeafNodeSizes:Boolean =
		LayoutConstants.DEFAULT_UNIFORM_LEAF_NODE_SIZES;

	/*
	 * Geometric abstraction of the compound graph
	 */
	protected var graphManager:LGraphManager;

	/*
	 * Whether layout is finished or not
	 */
	private var isLayoutFinished:Boolean;

	/*
	 * Whether this layout is a sub-layout of another one (e.g. CoSE called
	 * within CiSE for laying out the cluster graph)
	 */
	public var isSubLayout:Boolean;
	
	/**
	 * This is used for creation of bendpoints by using dummy nodes and edges.
	 * Maps an LEdge to its dummy bendpoint path.
	 */
	protected var edgeToDummyNodes:Map = new Map();

	/**
	 * Indicates whether the layout is called remotely or not.
	 */
	protected var isRemoteUse:Boolean;
	
// -----------------------------------------------------------------------------
// Section: Constructors and initializations
// -----------------------------------------------------------------------------
	/**
	 * The constructor creates and associates with this layout a new graph
	 * manager as well.
	 * 
	 * @param isRemote	indicates whether this layout is called remotely
	 */
	public function Layout(isRemoteUse:Boolean = false)
	{
		this.graphManager = this.newGraphManager();
		this.isLayoutFinished = false;
		this.isSubLayout = false;
		this.isRemoteUse = isRemoteUse;
	//	assert (this.graphManager != null);
	}
	
// -----------------------------------------------------------------------------
// Section: Accessor methods
// -----------------------------------------------------------------------------
	/**
	 * This method returns the associated graph manager.
	 */
	public function getGraphManager():LGraphManager
	{
		return this.graphManager;
	}

	/**
	 * This method returns the array of all nodes in associated graph manager.
	 */
	public function getAllNodes():Array/*Object[]*/
	{
		return this.graphManager.getAllNodes();
	}

	/**
	 * This method returns the array of all edges in associated graph manager.
	 */
	public function getAllEdges():Array/*Object[]*/
	{
		return this.graphManager.getAllEdges();
	}

	/**
	 * This method returns the array of all nodes to which gravitation should be
	 * applied.
	 */
	public function getAllNodesToApplyGravitation():Array/*Object[]*/
	{
		return this.graphManager.getAllNodesToApplyGravitation();
	}

// -----------------------------------------------------------------------------
// Section: Topology related
// -----------------------------------------------------------------------------
	/*
	 * This method creates a new graph manager associated with this layout.
	 */
	protected function newGraphManager():LGraphManager
	{
		var gm:LGraphManager= new LGraphManager(this);
		this.graphManager = gm;
		return gm;
	}

	/**
	 * This method creates a new graph associated with the input view graph.
	 */
	public function newGraph(vGraph:*/*vGraph:Object*/):LGraph
	{
		return new LGraph(null, this.graphManager, vGraph);
	}

	/**
	 * This method creates a new node associated with the input view node.
	 */
	public function newNode(vNode:*/*vNode:Object*/):LNode
	{
		return new LNode(this.graphManager, vNode);
	}

	/**
	 * This method creates a new edge associated with the input view edge.
	 */
	public function newEdge(vEdge:*/*vEdge:Object*/):LEdge
	{
		return new LEdge(null, null, vEdge);
	}

// -----------------------------------------------------------------------------
// Section: Remaining methods
// -----------------------------------------------------------------------------
	/**
	 * This method coordinates the layout operation. It returns true upon
	 * success, false otherwise.
	 */
	public function runLayout():Boolean
	{
		this.isLayoutFinished = false;

		if (!this.isSubLayout)
		{
			this.doPreLayout();
		}

		this.initParameters();
		var isLayoutSuccessfull:Boolean;
		
		if ((this.graphManager.getRoot() == null) 
			|| this.graphManager.getRoot().getNodes().size == 0)
		{
			isLayoutSuccessfull = false;
		}
		else
		{
			// TODO calculate execution time
			var startTime:Number= 0;
			
			if (!this.isSubLayout)
			{
				// startTime = System.currentTimeMillis();
			}
			
			isLayoutSuccessfull = this.layout();
			
			if (!this.isSubLayout)
			{
				//var endTime:Number = System.currentTimeMillis();
				//var excTime:Number = endTime - startTime;
				
				//trace("Total execution time: " + excTime + " miliseconds.");
			}
		}
		
		if (isLayoutSuccessfull)
		{
			if (!this.isSubLayout)
			{
				this.doPostLayout();
			}
		}

		this.isLayoutFinished = true;

		return isLayoutSuccessfull;
	}

	/**
	 * This method performs the operations required before layout.
	 */
	public function doPreLayout():void
	{
		
	}

	/**
	 * This method performs the operations required after layout.
	 */
	public function doPostLayout():void
	{
		// assert !isSubLayout : "Should not be called on sub-layout!";
		// Propagate geometric changes to v-level objects
		this.transform();
		this.update();
	}

	/**
	 * This method is the main method of the layout algorithm; each new layout
	 * algorithm must implement this method. It should return whether layout is
	 * successful or not.
	 */
	public /*abstract*/ function layout():Boolean
	{
		throw new IllegalOperationError("abstract function must be overriden");  
	}

	/**
	 * This method updates the geometry of the target graph according to
	 * calculated layout.
	 */
	public function update():void
	{	
		//trace("edges to update: " + this.graphManager.getAllEdges().length);
		//trace("nodes to update: " + this.graphManager.getRoot().getNodes().size);
		
		// update bend points
		if(this.createBendsAsNeeded)
		{
			this.createBendpointsFromDummyNodes();
			
			// reset all edges, since the topology has changed
			this.graphManager.resetAllEdges();
		}
		
		// perform edge, node and root updates if layout is not called
		// remotely
		
		if (!this.isRemoteUse)
		{
			// update all edges
			for each (var edge:LEdge in this.graphManager.getAllEdges())
			{
				this.updateEdge(edge);
			}
			
			var iter:IIterator =
				this.graphManager.getRoot().getNodes().iterator();
			
			// recursively update nodes 
			//for each (var node:LNode in this.graphManager.getRoot().getNodes())
			while(iter.hasNext())
			{
				this.updateNode(iter.next() as LNode);
			}
			
			// update root graph
			this.updateGraph(this.graphManager.getRoot());
		}
	}
	
	/**
	 * This method is called for updating the geometry of the view node
	 * associated with the input node when layout finishes.
	 */
	public function updateNode(node:LNode):void
	{
		if (node.getChild() != null)
		{
			// since node is compound, recursively update child nodes
			for each (var lNode:LNode in node.getChild().getNodes())
			{
				this.updateNode(lNode);
			}
		}
		
		// if the l-level node is associated with a v-level graph object,
		// then it is assumed that the v-level node implements the
		// interface Updatable.

		if (node.vGraphObject != null)
		{
			// cast to Updatable without any type check
			var vNode:Updatable= node.vGraphObject as Updatable;
			
			// call the update method of the interface 
			vNode.update(node);
		}
	}

	/**
	 * This method is called for updating the geometry of the view edge
	 * associated with the input edge when layout finishes.
	 */
	public function updateEdge(edge:LEdge):void
	{
		// if the l-level edge is associated with a v-level graph object,
		// then it is assumed that the v-level edge implements the
		// interface Updatable.

		if (edge.vGraphObject != null)
		{
			// cast to Updatable without any type check
			var vEdge:Updatable= edge.vGraphObject as Updatable;
			
			// call the update method of the interface 
			vEdge.update(edge);
		}
	}
	
	/**
	 * This method is called for updating the geometry of the view graph
	 * associated with the input graph when layout finishes.
	 */
	public function updateGraph(graph:LGraph):void
	{
		// if the l-level graph is associated with a v-level graph object,
		// then it is assumed that the v-level object implements the
		// interface Updatable.
		
		if (graph.vGraphObject != null)
		{
			// cast to Updatable without any type check
			var vGraph:Updatable= graph.vGraphObject as Updatable;
			
			// call the update method of the interface 
			vGraph.update(graph);
		}
	}

	/**
	 * This method is used to set all layout parameters to default values
	 * determined at compile time.
	 */
	public function initParameters():void
	{
		if (!this.isSubLayout)
		{
			var layoutOptionsPack:GeneralOptions=
				LayoutOptionsPack.getInstance().getGeneral();

			this.layoutQuality = layoutOptionsPack.getLayoutQuality();

			this.animationDuringLayout =
				layoutOptionsPack.isAnimationDuringLayout();
			this.animationPeriod =
				Layout.transform(layoutOptionsPack.getAnimationPeriod(),
					LayoutConstants.DEFAULT_ANIMATION_PERIOD);
			this.animationOnLayout = layoutOptionsPack.isAnimationOnLayout();

			this.incremental = layoutOptionsPack.isIncremental();
			this.createBendsAsNeeded = layoutOptionsPack.isCreateBendsAsNeeded();
			this.uniformLeafNodeSizes =
				layoutOptionsPack.isUniformLeafNodeSizes();
		}

		if (this.animationDuringLayout)
		{
			animationOnLayout = false;
		}

		LGraph.setGraphMargin(LayoutConstants.GRAPH_MARGIN_SIZE);
	}

	/**
	 * This method transforms the LNodes in the associated LGraphManager so that
	 * upper-left corner of the drawing starts at the input coordinate. If the
	 * input point is null, then transforms the LNodes in the associated
	 * LGraphManager so that upper-left corner of the drawing is (0, 0).
	 * The goal is to avoid negative coordinates that are not allowed when 
	 * displaying by shifting the drawing as necessary.
	 */
	public function transform(newLeftTop:PointD = null):void
	{
		// create a transformation object (from Eclipse to layout). When an
		// inverse transform is applied, we get upper-left coordinate of the
		// drawing or the root graph at given input coordinate (some margins
		// already included in calculation of left-top).

		var trans:Transform = new Transform();
		var leftTop:PointD = this.graphManager.getRoot().updateLeftTop(); // leftTop:Point -> PointD 

		if (newLeftTop == null)
		{
			newLeftTop = new PointD(0, 0);
		}
		
		if (leftTop != null)
		{
			trans.setWorldOrgX(newLeftTop.x);
			trans.setWorldOrgY(newLeftTop.y);

			trans.setDeviceOrgX(leftTop.x);
			trans.setDeviceOrgY(leftTop.y);

			var nodes:Array= this.getAllNodes();
			var node:LNode;

			for (var i:int= 0; i < nodes.length; i++)
			{
				node = nodes[i] as LNode;
				node.transform(trans);
			}
		}
	}

	/**
	 * This method determines the initial positions of leaf nodes in the
	 * associated l-level compound graph structure randomly. Non-empty compound
	 * nodes get their initial positions (and dimensions) from their contents,
	 * thus no calculations should be done for them!
	 */
	public function positionNodesRandomly():void
	{
		// assert !this.incremental;
		this.randomlyPositionNodes(this.getGraphManager().getRoot());
		this.getGraphManager().getRoot().updateBounds(true);
	}

	/**
	 * Auxiliary method for positioning nodes randomly.
	 */
	private function randomlyPositionNodes(graph:LGraph):void
	{
		var childGraph:LGraph;
		
		var iter:IIterator = graph.getNodes().iterator(); 
		
		while (iter.hasNext())
		{
			var lNode:LNode = iter.next() as LNode;
				
			childGraph = lNode.getChild();

			if (childGraph == null)
			{
				lNode.scatter();
			}
			else if (childGraph.getNodes().size == 0)
			{
				lNode.scatter();
			}
			else
			{
				this.randomlyPositionNodes(childGraph);
				lNode.updateBounds();
			}
		}
	}

	/**
	 * This method returns a list of trees where each tree is represented as a
	 * list of l-nodes. The method returns a list of size 0 when:
	 * - The graph is not flat or
	 * - One of the component(s) of the graph is not a tree.
	 */
	public function getFlatForest():ArrayList/*<ArrayList<LNode>>*/
	{
		var flatForest:ArrayList/*<ArrayList<LNode>>*/ =
			new ArrayList/*<ArrayList<LNode>>*/();
		var isForest:Boolean= true;

		// Quick reference for all nodes in the graph manager associated with
		// this layout. The list should not be changed.
		var allNodes:IList/*<LNode>*/ = this.graphManager.getRoot().getNodes();

		// First be sure that the graph is flat
		var isFlat:Boolean= true;

		for (var i:int= 0; i < allNodes.size; i++)
		{
			if ((allNodes.itemAt(i) as LNode).getChild() != null)
			{
				isFlat = false;
			}
		}

		// Return empty forest if the graph is not flat.
		if (!isFlat)
		{
			return flatForest;
		}

		// Run BFS for each component of the graph.

		var visited:Set/*<LNode>*/ = new Set/*<LNode>*/();
		var toBeVisited:LinkedList/*<LNode>*/ = new LinkedList/*<LNode>*/();
		var parents:Map/*<LNode, LNode>*/ = new Map/*<LNode, LNode>*/();
		var unProcessedNodes:LinkedList/*<LNode>*/ = new LinkedList/*<LNode>*/();

		var iter:IIterator = allNodes.iterator();
		
		//unProcessedNodes.addAll(allNodes);
		//for each (var obj:* in allNodes)
		while (iter.hasNext())
		{
			unProcessedNodes.add(iter.next());
		}

		// Each iteration of this loop finds a component of the graph and
		// decides whether it is a tree or not. If it is a tree, adds it to the
		// forest and continued with the next component.

		while (unProcessedNodes.size > 0 && isForest)
		{
			toBeVisited.add(unProcessedNodes.first);

			// Start the BFS. Each iteration of this loop visits a node in a
			// BFS manner.
			while (toBeVisited.size != 0 && isForest)
			{
				var currentNode:LNode = toBeVisited.removeFirst() as LNode//.poll();
				visited.add(currentNode);

				// Traverse all neighbors of this node
				var neighborEdges:ICollection/*<LEdge>*/ = currentNode.getEdges();

				iter = neighborEdges.iterator();
				
				//for each (var lEdge:LEdge in neighborEdges)
				while (iter.hasNext())
				{
					var lEdge:LEdge = iter.next() as LEdge;
					var currentNeighbor:LNode = lEdge.getOtherEnd(currentNode);

					// If BFS is not growing from this neighbor.
					if (parents.itemFor(currentNode) !== currentNeighbor)
					{
						// We haven't previously visited this neighbor.
						if (!visited.has(currentNeighbor))
						{
							toBeVisited.addLast(currentNeighbor);
							parents.add(currentNeighbor, currentNode);
						}
						// Since we have previously visited this neighbor and
						// this neighbor is not parent of currentNode, given
						// graph contains a component that is not tree, hence
						// it is not a forest.
						else
						{
							isForest = false;
							break;
						}
					}
				}
			}

			if (!isForest)
			// The graph contains a component that is not a tree. Empty
			// previously found trees. The method will end.
			{
				flatForest.clear();
			}
			else
			// Save currently visited nodes as a tree in our forest. Reset
			// visited and parents lists. Continue with the next component of
			// the graph, if any.
			{
				//flatForest.add(new ArrayList/*<LNode>*/(visited));
				
				var newList:ArrayList = new ArrayList();				
				newList.addAllAt(0, visited.toArray());
				flatForest.add(newList);
				
				iter = visited.iterator();
				
				//for each (var node:LNode in visited)
				//unProcessedNodes.removeAll(visited);
				while (iter.hasNext())
				{
					unProcessedNodes.remove(iter.next());
				}
				
				visited.clear();
				parents.clear();
			}
		}

		return flatForest;
	}

	/**
	 * This method creates dummy nodes (an l-level node with minimal dimensions)
	 * for the given edge (one per bendpoint). The existing l-level structure
	 * is updated accordingly.
	 */
	public function createDummyNodesForBendpoints(edge:LEdge):IList
	{
		var dummyNodes:IList= new ArrayList();
		var prev:LNode= edge.getSource();
		
		var graph:LGraph= this.graphManager.calcLowestCommonAncestor(
			edge.getSource(), edge.getTarget());

		var dummyEdge:LEdge;
		var dummyNode:LNode;
		
		for (var i:int= 0; i < edge.getBendpoints().size; i++)
		{
			// create new dummy node
			dummyNode = this.newNode(null);
			dummyNode.setRect(new PointD(0,0), new DimensionD(1,1)); // Point & Dimension -> PD & DD
			
			graph.addNode(dummyNode);

			// create new dummy edge between prev and dummy node
			dummyEdge = this.newEdge(null);
			this.graphManager.addEdge(dummyEdge, prev, dummyNode);

			dummyNodes.add(dummyNode);
			prev = dummyNode;
		}

		dummyEdge = this.newEdge(null);
		this.graphManager.addEdge(dummyEdge, prev, edge.getTarget());

		this.edgeToDummyNodes.add(edge, dummyNodes);
		
		// remove real edge from graph manager if it is inter-graph
		if (edge.isInterGraph())
		{
			this.graphManager.removeEdge(edge);
		}
		// else, remove the edge from the current graph
		else
		{
			graph.removeEdge(edge);
		}
		
		return dummyNodes;
	}
	
	/**
	 * This method creates bendpoints for edges from the dummy nodes
	 * at l-level.
	 */
	public function createBendpointsFromDummyNodes():void
	{
		var edges:ArrayList= new ArrayList();
		
		edges.addAllAt(0, this.graphManager.getAllEdges());
		edges.addAllAt(0, this.edgeToDummyNodes.keysToArray());

		var iter:IIterator = edges.iterator();
		
		//for each (var lEdge:LEdge in edges)
		while (iter.hasNext())
		{
			var lEdge:LEdge = iter.next() as LEdge;
			
			if (lEdge.getBendpoints().size > 0)
			{
				var path:IList = this.edgeToDummyNodes.itemFor(lEdge) as IList;

				for (var i:int= 0; i < path.size; i++)
				{
					var dummyNode:LNode = path.itemAt(i) as LNode;
					var p:PointD= new PointD(dummyNode.getCenterX(),
							dummyNode.getCenterY());

					// update bendpoint's location according to dummy node
					
					var ebp:PointD = lEdge.getBendpoints().itemAt(i) as PointD;
					ebp.x = p.x;
					ebp.y = p.y;
					
					// remove the dummy node, dummy edges incident with this
					// dummy node is also removed (within the remove method)
					dummyNode.getOwner().removeNode(dummyNode);					
				}
				
				// add the real edge to graph
				this.graphManager.addEdge(lEdge, lEdge.getSource(), lEdge.getTarget());
			}
		}
	}
	
// -----------------------------------------------------------------------------
// Section: Class methods
// -----------------------------------------------------------------------------
	/**
	 * This method transforms the input slider value into an actual parameter
	 * value using two separate linear functions (one from 0 to 50, other from
	 * 50 to 100), where default slider value (50) maps to the default value of
	 * the associated actual parameter. Minimum and maximum slider values map to
	 * 1/10 and 10 fold of this default value, respectively.
	 */
	public static function transform(sliderValue:int, 
		defaultValue:Number,
		minDiv:Number = NaN,
		maxMul:Number = NaN):Number
	{
		if (isNaN(minDiv) || isNaN(maxMul))
		{
			var a:Number, b:Number;
			
			if (sliderValue <= 50)
			{
				a = 9.0* defaultValue / 500.0;
				b = defaultValue / 10.0;
			}
			else
			{
				a = 9.0* defaultValue / 50.0;
				b = -8* defaultValue;
			}
			
			return (a * sliderValue + b);
		}
		else
		{
			var value:Number= defaultValue;
			
			if (sliderValue <= 50)
			{
				var minValue:Number= defaultValue / minDiv;
				value -= ((defaultValue - minValue) / 50) * (50- sliderValue);
			}
			else
			{
				var maxValue:Number= defaultValue * maxMul;
				value += ((maxValue - defaultValue) / 50) * (sliderValue - 50);
			}
			
			return value;
		}
	}
	
	/**
	 * This method takes a list of lists, where each list contains l-nodes of a
	 * tree. Center of each tree is return as a list of.
	 */
	public static function findCenterOfEachTree(listofLists:IList/*<List>*/):IList/*<LNode>*/
	{
		var centers:ArrayList/*<LNode>*/ = new ArrayList/*<LNode>*/();

		for (var i:int = 0; i < listofLists.size; i++)
		{
			var list:IList/*<LNode>*/ = listofLists.itemAt(i) as IList;
			var center:LNode = findCenterOfTree(list);
			centers.addAt(i, center);
		}

		return centers;
	}

	/**
	 * This method finds and returns the center of the given nodes, assuming
	 * that the given nodes form a tree in themselves.
	 */
	public static function findCenterOfTree(nodes:IList/*<LNode>*/):LNode
	{
		var list:ArrayList/*<LNode>*/ = new ArrayList/*<LNode>*/();
		list.addAllAt(0, nodes.toArray());

		var removedNodes:ArrayList/*<LNode>*/ = new ArrayList/*<LNode>*/();
		var remainingDegrees:Map/*<LNode, Integer>*/  =
			new Map/*<LNode, Integer>*/();
		var foundCenter:Boolean= false;
		var centerNode:LNode= null;

		if (list.size == 1 || list.size == 2)
		{
			foundCenter = true;
			centerNode = list.itemAt(0) as LNode;
		}

		var iter:IIterator = list.iterator();
		var node:LNode;
		
		//for each (node in list)
		while (iter.hasNext())
		{
			node = iter.next() as LNode;
			var degree:int = node.getNeighborsList().size;
			
			// TODO put method can be implemented
			// remainingDegrees.put(node , degree)
			if(! remainingDegrees.add(node , degree))
			{
				remainingDegrees.replaceFor(node , degree)
			}

			if (degree == 1)
			{
				removedNodes.add(node);
			}
		}

		var tempList:ArrayList/*<LNode>*/ = new ArrayList/*<LNode>*/();
		tempList.addAllAt(0, removedNodes.toArray());

		while (!foundCenter)
		{
			var tempList2:ArrayList/*<LNode>*/ = new ArrayList/*<LNode>*/();
			tempList2.addAllAt(0, tempList.toArray());
			
			// removeAll is not same as it is in Java!!!
			//tempList.removeAll(tempList);
			
			tempList.clear();

			iter = tempList2.iterator();
			
			//for each (node in tempList2)
			while (iter.hasNext())
			{
				node = iter.next() as LNode;
				list.remove(node);

				var neighbours:Set/*<LNode>*/  = node.getNeighborsList();
				
				var iter2:IIterator = neighbours.iterator();
				
				//for each (var neighbor:LNode in neighbours)
				while (iter2.hasNext())
				{
					var neighbor:LNode = iter2.next() as LNode;
					
					if (!removedNodes.has(neighbor))
					{
						var otherDegree:int = remainingDegrees.itemFor(neighbor) as int;
						var newDegree:int = otherDegree - 1;

						if (newDegree == 1)
						{
							tempList.add(neighbor);
						}

						// TODO put method can be implemented
						//remainingDegrees.put(neighbor, newDegree);
						if(! remainingDegrees.add(node , degree))
						{
							remainingDegrees.replaceFor(node , degree)
						}
						
					}
				}
			}

			removedNodes.addAllAt(0, tempList.toArray());

			if (list.size == 1 || list.size == 2)
			{
				foundCenter = true;
				centerNode = list.itemAt(0) as LNode;
			}
		}

		return centerNode;
	}

// -----------------------------------------------------------------------------
// Section: Class variables
// -----------------------------------------------------------------------------
	/**
	 * Used for deterministic results on consecutive executions of layout.
	 */
	public static const RANDOM_SEED:Number= 1;
	
// -----------------------------------------------------------------------------
// Section: Coarsening
// -----------------------------------------------------------------------------
	/**
	 * During the coarsening process, this layout may be referenced by two graph managers
	 * this setter function grants access to change the currently being used graph manager
	 */
	public function setGraphManager(gm:LGraphManager):void
	{
		this.graphManager = gm;
	}
}
}