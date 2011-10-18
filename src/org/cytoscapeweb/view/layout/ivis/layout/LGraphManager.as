package org.cytoscapeweb.view.layout.ivis.layout
{
	import org.as3commons.collections.ArrayList;
	import org.as3commons.collections.LinkedList;
	import org.as3commons.collections.framework.ICollection;
	import org.as3commons.collections.framework.IIterator;
	import org.as3commons.collections.framework.IList;

//import java.util.*;

/**
 * This class represents a graph manager (l-level) for layout purposes. A graph
 * manager maintains a collection of graphs, forming a compound graph structure
 * through inclusion, and maintains the inter-graph edges. You may refer to the
 * following article for technical details:
 * 		U. Dogrusoz and B. Genc, "A Multi-Graph Approach to Complexity
 * 		Management in Interactive Graph Visualization",
 * 		Computers & Graphics, vol. 30/1, pp. 86-97, 2006.
 *
 * @author Erhan Giral
 * @author Ugur Dogrusoz
 * @author Cihan Kucukkececi
 *
 * Copyright: i-Vis Research Group, Bilkent University, 2007 - present
 */
public class LGraphManager
{
// -----------------------------------------------------------------------------
// Section: Instance variables
// -----------------------------------------------------------------------------
	/*
	 * Graphs maintained by this graph manager, including the root of the
	 * nesting hierarchy
	 */
	private var graphs:IList;

	/*
	 * Inter-graph edges in this graph manager. Notice that all inter-graph
	 * edges go here, not in any of the edge lists of individual graphs (either
	 * source or target node's owner graph).
	 */
	private var edges:IList;

	/*
	 * All nodes (excluding the root node) and edges (including inter-graph
	 * edges) in this graph manager. For efficiency purposes we hold references
	 * of all layout objects that we operate on in arrays. These lists are
	 * generated once we know that the topology of the graph manager is fixed,
	 * immediately before layout starts.
	 */
	private var allNodes:Array;
	private var allEdges:Array;

	/*
	 * Similarly we have a list of nodes for which gravitation should be
	 * applied. This is determined once, prior to layout, and used afterwards.
	 */
	private var allNodesToApplyGravitation:Array;

	/*
	 * The root of the inclusion/nesting hierarchy of this compound structure
	 */
	private var rootGraph:LGraph;

	/*
	 * Layout object using this graph manager
	 */
	private var layout:Layout;

// -----------------------------------------------------------------------------
// Section: Constructors and initialization
// -----------------------------------------------------------------------------
	/*
	 * Constructor
	 */
	public function LGraphManager(layout:Layout = null)
	{
		this.layout = layout;
		this.init();
	}

	private function init():void
	{
		this.graphs = new ArrayList();
		this.edges = new ArrayList();
		this.allNodes = null;
		this.allEdges = null;
		this.allNodesToApplyGravitation = null;
		this.rootGraph = null;
	}

// -----------------------------------------------------------------------------
// Section: Topology related
// -----------------------------------------------------------------------------
	/**
	 * This method adds a new graph to this graph manager and sets as the root.
	 * It also creates the root graph as the parent of the root graph.
	 */
	public function addRoot():LGraph
	{
		this.setRootGraph(this.addGraph(this.layout.newGraph(null),
			this.layout.newNode(null)));
		
		return this.rootGraph;
	}

	/**
	 * This method adds the input graph into this graph manager. The new graph
	 * is associated as the child graph of the input parent node. If the parent
	 * node is null, then the graph is set to be the root.
	 */
	public function addGraph(newGraph:LGraph, parentNode:LNode):LGraph
	{
	//	assert (newGraph != null) : "Graph is null!";
	//	assert (parentNode != null) : "Parent node is null!";
	//	assert (!this.graphs.contains(newGraph)) :
	//		"Graph already in this graph mgr!";

		this.graphs.add(newGraph);

	//	assert (newGraph.parent == null) : "Already has a parent!";
	//	assert (parentNode.child == null) : "Already has a child!";
		newGraph.parent = parentNode;
		parentNode.setChild(newGraph);

		return newGraph;
	}

	/**
	 * This method adds the input edge between specified nodes into this graph
	 * manager. We assume both source and target nodes to be already in this
	 * graph manager.
	 */
	public function addEdge(newEdge:LEdge, sourceNode:LNode, targetNode:LNode):LEdge
	{
		var sourceGraph:LGraph = sourceNode.getOwner();
		var targetGraph:LGraph = targetNode.getOwner();

	//	assert (sourceGraph != null && sourceGraph.getGraphManager() == this ) :
	//		"Source not in this graph mgr!";
	//	assert (targetGraph != null && targetGraph.getGraphManager() == this ) :
	//		"Target not in this graph mgr!";

		if (sourceGraph == targetGraph)
		{
			newEdge._isInterGraph = false;
			return sourceGraph.addEdge(newEdge, sourceNode, targetNode);
		}
		else
		{
			newEdge._isInterGraph = true;

			// set source and target
			newEdge.source = sourceNode;
			newEdge.target = targetNode;

			// add edge to inter-graph edge list
		//	assert (!this.edges.contains(newEdge)) :
		//		"Edge already in inter-graph edge list!";
			this.edges.add(newEdge);

			// add edge to source and target incidency lists
		//	assert (newEdge.source != null && newEdge.target != null) :
		//		"Edge source and/or target is null!";
		//	assert (!newEdge.source.edges.contains(newEdge) &&
		//		!newEdge.target.edges.contains(newEdge)) :
		//			"Edge already in source and/or target incidency list!";

			newEdge.getSource().getEdges().add(newEdge);
			newEdge.getTarget().getEdges().add(newEdge);

			return newEdge;
		}
	}

	/**
	 * This method removes the input graph from this graph manager. 
	 */
	public function removeGraph(graph:LGraph):void
	{
	//	assert (graph.getGraphManager() == this) :
	//		"Graph not in this graph mgr";
	//	assert (graph == this.rootGraph ||
	//		(graph.parent != null && graph.parent.graphManager == this)) :
	//			"Invalid parent node!";

		// first the edges (make a copy to do it safely)
		var edgesToBeRemoved:ArrayList = new ArrayList();

		edgesToBeRemoved.addAllAt(0, graph.getEdges().toArray());

		var iter:IIterator = edgesToBeRemoved.iterator();
		
		//for each (var edge:LEdge in edgesToBeRemoved)
		while (iter.hasNext())
		{
			graph.removeEdge(iter.next() as LEdge);
		}

		// then the nodes (make a copy to do it safely)
		var nodesToBeRemoved:ArrayList = new ArrayList();

		nodesToBeRemoved.addAllAt(0, graph.getNodes().toArray());
		
		iter = nodesToBeRemoved.iterator();
		
		//for each (var node:LNode in nodesToBeRemoved)
		while (iter.hasNext())
		{
			graph.removeNode(iter.next() as LNode);
		}

		// check if graph is the root
		if (graph == this.rootGraph)
		{
			this.setRootGraph(null);
		}

		// now remove the graph itself
		this.graphs.remove(graph);

		// also reset the parent of the graph
		graph.parent = null;
	}

	/**
	 * This method removes the input inter-graph edge from this graph manager.
	 */
	public function removeEdge(edge:LEdge):void
	{
	//	assert (edge != null) : "Edge is null!";
	//	assert (edge.isInterGraph) : "Not an inter-graph edge!";
	//	assert (edge.source != null && edge.target != null) :
	//		"Source and/or target is null!";

		// remove edge from source and target nodes' incidency lists

	//	assert (edge.source.edges.contains(edge) &&
	//		edge.target.edges.contains(edge)) :
	//			"Source and/or target doesn't know this edge!";

		edge.getSource().getEdges().remove(edge);
		edge.getTarget().getEdges().remove(edge);

		// remove edge from owner graph manager's inter-graph edge list

	//	assert (edge.source.owner != null &&
	//		edge.source.owner.getGraphManager() != null) :
	//		"Edge owner graph or owner graph manager is null!";
	//	assert (edge.source.owner.getGraphManager().edges.contains(edge)) :
	//		"Not in owner graph manager's edge list!";

		edge.getSource().getOwner().getGraphManager().edges.remove(edge);
	}

	/**
	 * This method calculates and updates the bounds of the root graph.
	 */
	public function updateBounds():void
	{
		this.rootGraph.updateBounds(true);
	}
// -----------------------------------------------------------------------------
// Section: Accessors
// -----------------------------------------------------------------------------
	/**
	 * This method retuns the list of all graphs managed by this graph manager.
	 */
	public function getGraphs():IList
	{
		return this.graphs;
	}

	/**
	 * This method returns the list of all inter-graph edges in this graph
	 * manager.
	 */
	public function getInterGraphEdges():IList
	{
		return this.edges;
	}

	/**
	 * This method returns the list of all nodes in this graph manager. This
	 * list is populated on demand and should only be called once the topology
	 * of this graph manager has been formed and known to be fixed.
	 */
	public function getAllNodes():Array /*Object[]*/
	{
		if (this.allNodes == null)
		{
			var nodeList:LinkedList = new LinkedList();
			var graphIter:IIterator = this.getGraphs().iterator();				
			
			//for each (var graph:LGraph in this.getGraphs())
			while (graphIter.hasNext())
			{
				var graph:LGraph = graphIter.next() as LGraph;
				
				var nodeIter:IIterator = graph.getNodes().iterator();
				
				//nodeList.addAll(graph.getNodes());				
				//for each (var obj:* in graph.getNodes())
				while (nodeIter.hasNext())
				{
					nodeList.add(nodeIter.next());
				}
			}

			this.allNodes = nodeList.toArray();
		}

		return this.allNodes;
	}

	/**
	 * This method nulls the all nodes array so that it gets re-calculated with
	 * the next invocation of the accessor. Needed when topology changes.
	 */
	public function resetAllNodes():void
	{
		this.allNodes = null;
	}

	/**
	 * This method nulls the all edges array so that it gets re-calculated with
	 * the next invocation of the accessor. Needed when topology changes. 
	 */
	public function resetAllEdges():void
	{
		this.allEdges = null;
	}
	
	/**
	 * This method nulls the all nodes to apply gravition array so that it gets 
	 * re-calculated with the next invocation of the accessor. Needed when
	 * topology changes. 
	 */
	public function resetAllNodesToApplyGravitation():void
	{
		this.allNodesToApplyGravitation = null;
	}
	
	/**
	 * This method returns the list of all edges (including inter-graph edges)
	 * in this graph manager. This list is populated on demand and should only
	 * be called once the topology of this graph manager has been formed and
	 * known to be fixed.
	 */
	public function getAllEdges():Array /*Object[]*/
	{
		if (this.allEdges == null)
		{
			var edgeList:LinkedList= new LinkedList();
			var obj:*;
			
			var iter:IIterator = this.getGraphs().iterator();
			
			//for each (var lGraph:LGraph in this.getGraphs())
			while (iter.hasNext())
			{
				var graph:LGraph = iter.next() as LGraph;
				// edgeList.addAll(lGraph.getEdges());
				
				var nodeIter:IIterator = graph.getEdges().iterator();
				//for each (obj in graph.getEdges())
				while (nodeIter.hasNext())
				{
					edgeList.add(nodeIter.next());
				}
			}

			iter = this.edges.iterator();
			
			// edgeList.addAll(this.edges);
			//for each (obj in this.edges)
			while (iter.hasNext())
			{
				edgeList.add(iter.next());
			}
			
			this.allEdges = edgeList.toArray();
		}

		return this.allEdges;
	}

	/**
	 * This method returns the array of all nodes to which gravitation should be
	 * applied.
	 */
	public function getAllNodesToApplyGravitation():Array /*Object[]*/
	{
		return this.allNodesToApplyGravitation;
	}

	/**
	 * This method sets the array of all nodes to which gravitation should be
	 * applied from the input list.
	 */
	public function setAllNodesToApplyGravitation(nodeList:ICollection,
		nodes:Array = null):void
	{
	//	assert this.allNodesToApplyGravitation == null;

		if (nodes == null)
		{
			this.allNodesToApplyGravitation = nodeList.toArray();
		}
		else
		{
			this.allNodesToApplyGravitation = nodes;
		}
	}

	/**
	 * This method sets the array of all nodes to which gravitation should be
	 * applied from the input array.
	 * 
	 * TODO called by CiSE, not needed for CoSE
	 */
	/*
	public function setAllNodesToApplyGravitation(nodes:Array):void
	{
	//	assert this.allNodesToApplyGravitation == null;
	
		this.allNodesToApplyGravitation = nodes;
	}
	*/

	/**
	 * This method returns the root graph (root of the nesting hierarchy) of
	 * this graph manager. Nesting relations must form a tree.
	 */
	public function getRoot():LGraph
	{
		return this.rootGraph;
	}

	/**
	 * This method sets the root graph (root of the nesting hierarchy) of this
	 * graph manager. Nesting relations must form a tree.
	 * @param graph
	 */
	public function setRootGraph(graph:LGraph):void
	{
	//	assert (graph.getGraphManager() == this) : "Root not in this graph mgr!";

		this.rootGraph = graph;

		// root graph must have a root node associated with it for convenience
		if (graph.parent == null)
		{
			graph.parent = this.layout.newNode("Root node");
		}
	}

	/**
	 * This method returns the associated layout object, which operates on this
	 * graph manager.
	 */
	public function getLayout():Layout
	{
		return this.layout;
	}

	/**
	 * This method sets the associated layout object, which operates on this
	 * graph manager.
	 */
	public function setLayout(layout:Layout):void
	{
		this.layout = layout;
	}

// -----------------------------------------------------------------------------
// Section: Remaining methods
// -----------------------------------------------------------------------------
	/**
	 * This method checks whether one of the input nodes is an ancestor of the
	 * other one (and vice versa) in the nesting tree. Such pairs of nodes
	 * should not be allowed to be joined by edges.
	 */
	public static function isOneAncestorOfOther(firstNode:LNode,
		secondNode:LNode):Boolean
	{
	//	assert firstNode != null && secondNode != null;

		if (firstNode == secondNode)
		{
			return true;
		}

		// Is second node an ancestor of the first one?

		var ownerGraph:LGraph= firstNode.getOwner();
		var parentNode:LNode;

		do
		{
			parentNode = ownerGraph.getParent();

			if (parentNode == null)
			{
				break;
			}

			if (parentNode == secondNode)
			{
				return true;
			}

			ownerGraph = parentNode.getOwner();
			
			if(ownerGraph == null)
			{
				break;
			}
		} while (true);

		// Is first node an ancestor of the second one?

		ownerGraph = secondNode.getOwner();

		do
		{
			parentNode = ownerGraph.getParent();

			if (parentNode == null)
			{
				break;
			}

			if (parentNode == firstNode)
			{
				return true;
			}

			ownerGraph = parentNode.getOwner();
			
			if(ownerGraph == null)
			{
				break;
			}
		} while (true);

		return false;
	}
	
	/**
	 * This method calculates the lowest common ancestor of each edge.
	 */
	public function calcLowestCommonAncestors():void
	{
		var edge:LEdge;
		var sourceNode:LNode;
		var targetNode:LNode;
		var sourceAncestorGraph:LGraph;
		var targetAncestorGraph:LGraph;
		
		for each (edge in this.getAllEdges())
		{
			sourceNode = edge.source;
			targetNode = edge.target;
			edge.lca =  null;
			edge.sourceInLca = sourceNode;
			edge.targetInLca = targetNode;

			if (sourceNode == targetNode)
			{
				edge.lca = sourceNode.getOwner();
				continue;
			}

			sourceAncestorGraph = sourceNode.getOwner();

			while (edge.lca == null)
			{
				targetAncestorGraph = targetNode.getOwner();

				while (edge.lca == null)
				{
					if (targetAncestorGraph == sourceAncestorGraph)
					{
						edge.lca = targetAncestorGraph;
						break;
					}

					if (targetAncestorGraph == this.rootGraph)
					{
						break;
					}
					
				//	assert edge.lca == null;
					edge.targetInLca = targetAncestorGraph.getParent();
					targetAncestorGraph = edge.targetInLca.getOwner();
				}

				if (sourceAncestorGraph == this.rootGraph)
				{
					break;
				}

				if (edge.lca == null)
				{
					edge.sourceInLca = sourceAncestorGraph.getParent();
					sourceAncestorGraph = edge.sourceInLca.getOwner();
				}
			}

			
		//	assert edge.lca != null;
		}
	}

	/**
	 * This method finds the lowest common ancestor of given two nodes.
	 * 
	 * @param firstNode
	 * @param secondNode
	 * @return lowest common ancestor
	 */
	public function calcLowestCommonAncestor(firstNode:LNode,
											 secondNode:LNode):LGraph
	{
		if (firstNode == secondNode)
		{
			return firstNode.getOwner();
		}

		var firstOwnerGraph:LGraph= firstNode.getOwner();

		do
		{
			if (firstOwnerGraph == null)
			{
				break;
			}

			var secondOwnerGraph:LGraph= secondNode.getOwner();
		
			do
			{			
				if (secondOwnerGraph == null)
				{
					break;
				}

				if (secondOwnerGraph == firstOwnerGraph)
				{
					return secondOwnerGraph;
				}
				
				secondOwnerGraph = secondOwnerGraph.getParent().getOwner();
			} while (true);

			firstOwnerGraph = firstOwnerGraph.getParent().getOwner();
		} while (true);

		return firstOwnerGraph;
	}

	/**
	 * This method calculates depth of each node in the inclusion tree (nesting
	 * hierarchy).
	 */
	public function calcInclusionTreeDepths():void
	{
		this.inclusionTreeDepths(this.rootGraph, 1);
	}
	
	/*
	 * Auxiliary method for calculating depths of nodes in the inclusion tree.
	 */
	private function inclusionTreeDepths(graph:LGraph, depth:int):void
	{
		var node:LNode;

		var iter:IIterator = graph.getNodes().iterator();
		
		//for each (node in graph.getNodes())
		while (iter.hasNext())
		{
			node = iter.next() as LNode;
			node.inclusionTreeDepth = depth;

			if (node.getChild() != null)
			{
				this.inclusionTreeDepths(node.getChild(), depth + 1);
			}
		}
	}
	
// -----------------------------------------------------------------------------
// Section: Testing methods
// -----------------------------------------------------------------------------
	/**
	 * This method prints the topology of this graph manager.
	 */
	public function printTopology():void
	{
		this.rootGraph.printTopology();
		
		for each (var graph:LGraph in this.graphs.toArray())
		{
			if (graph != this.rootGraph)
			{
				graph.printTopology();
			}
		}

		trace("Inter-graph edges[" + this.edges.size + "]:");
		
		for each (var edge:LEdge in this.edges.toArray())
		{
			edge.printTopology();
		}

		trace();
		trace();
	}
}
}