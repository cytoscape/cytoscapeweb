package org.cytoscapeweb.view.layout.ivis.layout.cose
{

/*
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashSet;
import java.util.LinkedList;
import java.util.List;
import java.util.Set;
import java.awt.*;
*/
	
import org.as3commons.collections.ArrayList;
import org.as3commons.collections.LinkedList;
import org.as3commons.collections.Set;
import org.as3commons.collections.framework.IIterator;
import org.as3commons.collections.framework.IList;
import org.as3commons.collections.framework.core.AbstractList;
import org.cytoscapeweb.view.layout.ivis.layout.*;
import org.cytoscapeweb.view.layout.ivis.layout.fd.*;
import org.cytoscapeweb.view.layout.ivis.util.*;

/**TODO:
 * use of randomness to beat local minima
 * grid-variant
 * parallelization
 */

/**
 * This class implements the overall layout process for the CoSE algorithm.
 * Details of this algorithm can be found in the following article:
 * 		U. Dogrusoz, E. Giral, A. Cetintas, A. Civril, and E. Demir,
 * 		"A Layout Algorithm For Undirected Compound Graphs",
 * 		Information Sciences, 179, pp. 980994, 2009.
 *
 * @author Ugur Dogrusoz
 * @author Erhan Giral
 * @author Cihan Kucukkececi
 * @author Alper Karacelik
 * 
 * Copyright: i-Vis Research Group, Bilkent University, 2007 - present
 */
public class CoSELayout extends FDLayout
{
// -----------------------------------------------------------------------------
// Section: Instance variables
// -----------------------------------------------------------------------------
	/**
	 * Whether or not smart calculation of ideal edge lengths should be
	 * performed. When true, ideal edge length values take sizes of end nodes
	 * into account as well as depths of end nodes (how many levels of compounds
	 * does each edge need to go through from source to target, if any).
	 */
	protected var useSmartIdealEdgeLengthCalculation:Boolean=
		CoSEConstants.DEFAULT_USE_SMART_IDEAL_EDGE_LENGTH_CALCULATION;

	/**
	 * Whether or not multi-level scaling should be used to speed up layout
	 */
	protected var useMultiLevelScaling:Boolean=
		CoSEConstants.DEFAULT_USE_MULTI_LEVEL_SCALING;
	
	/**
	 * Level of the current graph manager in the coarsening process
	 */
	private var level:int;
	
	/**
	 * Total level number
	 */
	private var noOfLevels:int;
	
	/**
	 * Holds all graph managers (M0 to Mk)
	 */
	private var MList:ArrayList/*<CoSEGraphManager>*/;

// -----------------------------------------------------------------------------
// Section: Constructors and initializations
// -----------------------------------------------------------------------------
	/**
	 * The constructor creates and associates with this layout a new graph
	 * manager as well.
	 */
	public function CoSELayout()
	{
		super();
	}

	/**
	 * This method creates a new graph manager associated with this layout.
	 */
	override protected function newGraphManager():LGraphManager
	{
		var gm:LGraphManager= new CoSEGraphManager(this);
		this.graphManager = gm;
		return gm;
	}
	
	/**
	 * This method creates a new graph associated with the input view graph.
	 */
	override public function newGraph(vGraph:*/*vGraph:Object*/):LGraph
	{
		return new CoSEGraph(null, this.graphManager, vGraph);
	}

	/**
	 * This method creates a new node associated with the input view node.
	 */
	override public function newNode(vNode:*/*vNode:Object*/):LNode
	{
		return new CoSENode(this.graphManager, vNode);
	}

	/**
	 * This method creates a new edge associated with the input view edge.
	 */
	override public function newEdge(vEdge:*/*vEdge:Object*/):LEdge
	{
		return new CoSEEdge(null, null, vEdge);
	}

	/**
	 * This method is used to set all layout parameters to default values.
	 */
	override public function initParameters():void
	{
		super.initParameters();

		if (!this.isSubLayout)
		{
			var layoutOptionsPack:CoSEOptions =
				LayoutOptionsPack.getInstance().getCoSE();

			if (layoutOptionsPack.getIdealEdgeLength() < 10)
			{
				this.idealEdgeLength = 10;
			}
			else
			{
				this.idealEdgeLength = layoutOptionsPack.getIdealEdgeLength();
			}

			this.useSmartIdealEdgeLengthCalculation =
				layoutOptionsPack.isSmartEdgeLengthCalc();
			this.useMultiLevelScaling =
				layoutOptionsPack.isMultiLevelScaling();
			this.springConstant =
				Layout.transform(layoutOptionsPack.getSpringStrength(),
					FDLayoutConstants.DEFAULT_SPRING_STRENGTH, 5.0, 5.0);
			this.repulsionConstant =
				Layout.transform(layoutOptionsPack.getRepulsionStrength(),
					FDLayoutConstants.DEFAULT_REPULSION_STRENGTH, 5.0, 5.0);
			this.gravityConstant =
				Layout.transform(layoutOptionsPack.getGravityStrength(),
					FDLayoutConstants.DEFAULT_GRAVITY_STRENGTH);
			this.compoundGravityConstant =
				Layout.transform(layoutOptionsPack.getCompoundGravityStrength(),
					FDLayoutConstants.DEFAULT_COMPOUND_GRAVITY_STRENGTH);
			this.gravityRangeFactor =
				Layout.transform(layoutOptionsPack.getGravityRange(),
					FDLayoutConstants.DEFAULT_GRAVITY_RANGE_FACTOR);
			this.compoundGravityRangeFactor =
				Layout.transform(layoutOptionsPack.getCompoundGravityRange(),
					FDLayoutConstants.DEFAULT_COMPOUND_GRAVITY_RANGE_FACTOR);
		}
	}
		
// -----------------------------------------------------------------------------
// Section: Layout!
// -----------------------------------------------------------------------------
	/**
	 * This method performs layout on constructed l-level graph. It returns true
	 * on success, false otherwise.
	 */
	override public function layout():Boolean
	{
		var createBendsAsNeeded:Boolean= LayoutOptionsPack.getInstance().
			getGeneral().isCreateBendsAsNeeded();

		if (createBendsAsNeeded)
		{
			this.createBendpoints();
			
			// reset edge list, since the topology has changed
			this.graphManager.resetAllEdges();
		}
		
		if (this.useMultiLevelScaling && !this.incremental)
		{
			return this.multiLevelScalingLayout();
		}
		else
		{
			this.level = 0;
			return this.classicLayout();
		}
	}

	/**
	 * This method applies multi-level scaling during layout
	 */
	private function multiLevelScalingLayout():Boolean
	{
		var gm:CoSEGraphManager= this.graphManager as CoSEGraphManager;

		//TODO: Remove comments after testing
		//GraphMLWriter graphMLWriter;
		
		// Start coarsening process
		
		// save graph managers M0 to Mk in an array list
		this.MList = gm.coarsenGraph();

		this.noOfLevels = MList.size - 1;
		this.level = this.noOfLevels;
		
		while (this.level >= 0)
		{
			this.graphManager = gm = this.MList.itemAt(this.level) as CoSEGraphManager;
			
			// TODO: remove after testing
			//this.transform();
			//graphMLWriter = new GraphMLWriter("D:\\workspace\\research_work\\chied2x\\graphs\\rome\\level_" + 
			//	this.level + "_(before).graphml");
			//graphMLWriter.saveGraph(this.graphManager);
			
			trace("@" + this.level + "th level, with " + gm.getRoot().getNodes().size + " nodes. ");
			this.classicLayout();

			// TODO: remove after testing
			//this.transform();
			//graphMLWriter = new GraphMLWriter("D:\\workspace\\research_work\\chied2x\\graphs\\rome\\level_" + 
			//	this.level + "_(after).graphml");
			//graphMLWriter.saveGraph(this.graphManager);
			
			// after finishing layout of first (coarsest) level,
			this.incremental = true;
			
			if (this.level >= 1)
			{	
				this.uncoarsen(); // also makes initial placement for Mi-1
			}
			
			// reset total iterations
			this.totalIterations = 0;
			
			this.level--;
		}
		
		this.incremental = false;
		return true;
	}
	
	/**
	 * This method uses classic layout method (without multi-scaling)
	 * @return
	 */
	private function classicLayout():Boolean
	{
		this.calculateNodesToApplyGravitationTo();
	
		this.graphManager.calcLowestCommonAncestors();
		this.graphManager.calcInclusionTreeDepths();
	
		this.graphManager.getRoot().calcEstimatedSize();
		this.calcIdealEdgeLengths();
	
		if (!this.incremental)
		{
			var forest:ArrayList/*<ArrayList<LNode>>*/ = this.getFlatForest();
	
			if (forest.size > 0)
			// The graph associated with this layout is flat and a forest
			{
				this.positionNodesRadially(forest);
			}
			else
			// The graph associated with this layout is not flat or a forest
			{
				this.positionNodesRandomly();
			}
		}
	
		this.initSpringEmbedder();
		this.runSpringEmbedder();
	
		trace("Classic CoSE layout finished after " +
			this.totalIterations + " iterations");
		
		return true;
	}
	
	/**
	 * This method performs the actual layout on the l-level compound graph. An
	 * update() needs to be called for changes to be propogated to the v-level
	 * compound graph.
	 */
	public function runSpringEmbedder():void
	{
//		if (!this.incremental)
//		{
//			CoSELayout.randomizedMovementCount = 0;
//			CoSELayout.nonRandomizedMovementCount = 0;
//		}

//		this.updateAnnealingProbability();

		do
		{
			this.totalIterations++;

			if (this.totalIterations % FDLayoutConstants.CONVERGENCE_CHECK_PERIOD == 0)
			{
				if (this.isConverged())
				{
					break;
				}

				this.coolingFactor = this.initialCoolingFactor *
					((this.maxIterations - this.totalIterations) / (this.maxIterations as Number));
				
//				this.updateAnnealingProbability();
			}

			this.totalDisplacement = 0;

			this.graphManager.updateBounds();
			this.calcSpringForces();
			this.calcRepulsionForces();
			this.calcGravitationalForces();
			this.moveNodes();

			this.animate();
		}
		while (this.totalIterations < this.maxIterations);
	}

	/**
	 * This method finds and forms a list of nodes for which gravitation should
	 * be applied. For connected graphs (root graph or compounds / child graphs)
	 * there is no need to apply gravitation. While doing so, each graph in the
	 * associated graph manager is marked as connected or not.
	 */
	public function calculateNodesToApplyGravitationTo():void
	{
		var nodeList:LinkedList= new LinkedList();
		var graph:LGraph;
		
		var graphIter:IIterator = this.graphManager.getGraphs().iterator();
		
		//for each (var obj:* in this.graphManager.getGraphs())
		while (graphIter.hasNext())
		{
			graph = graphIter.next() as LGraph;

			graph.updateConnected();

			if (!graph.isConnected())
			{
				var nodeIter:IIterator = graph.getNodes().iterator();
				
				// nodeList.addAll(graph.getNodes());
				//for each (var item:* in graph.getNodes())
				while (nodeIter.hasNext())
				{
					nodeList.add(nodeIter.next());
				}
			}
		}

		this.graphManager.setAllNodesToApplyGravitation(nodeList);

//		// Use this to apply the idea for flat graphs only
//		if (this.graphManager.getGraphs().size() == 1)
//		{
//			LGraph root = this.graphManager.getRoot();
//			assert this.graphManager.getGraphs().get(0) == root;
//
//			root.updateConnected();
//
//			if (!root.isConnected())
//			{
//				this.graphManager.setAllNodesToApplyGravitation(
//					this.graphManager.getAllNodes());
//			}
//			else
//			{
//				this.graphManager.setAllNodesToApplyGravitation(new LinkedList());
//			}
//		}
//		else
//		{
//			this.graphManager.setAllNodesToApplyGravitation(
//				this.graphManager.getAllNodes());
//		}
	}

	/**
	 * This method creates bendpoints multi-edges which are incident to same  
	 * source and target nodes, and for all edges that have the same node as 
	 * both source and target.
	 */
	private function createBendpoints():void
	{
		var edges:ArrayList = new ArrayList();
		edges.addAllAt(0, this.graphManager.getAllEdges());
		var visited:Set = new Set();

		for (var i:int= 0; i < edges.size; i++)
		{
			var edge:LEdge= edges.itemAt(i) as LEdge;

			if (!visited.has(edge))
			{
				var source:LNode = edge.getSource();
				var target:LNode = edge.getTarget();

				if (source == target)
				{
					edge.getBendpoints().add(new PointD());
					edge.getBendpoints().add(new PointD());
					this.createDummyNodesForBendpoints(edge);
					visited.add(edge);
				}
				else
				{
					var edgeList:ArrayList= new ArrayList();
					
					edgeList.addAllAt(0, target.getEdgeListToNode(source).toArray());
					edgeList.addAllAt(0, source.getEdgeListToNode(target).toArray());
					

					if (!visited.has(edgeList.itemAt(0)))
					{
						if (edgeList.size > 1)
						{
							for(var k:int = 0; k < edgeList.size; k++)
							{
								var multiEdge:LEdge = edgeList.itemAt(k) as LEdge;
								multiEdge.getBendpoints().add(new PointD());
								this.createDummyNodesForBendpoints(multiEdge);
							}
						}

						var iter:IIterator = edgeList.iterator(); 
						
						//visited.addAll(edgeList);
						//for each (var obj:* in edgeList)
						while(iter.hasNext())
						{
							visited.add(iter.next());
						}
					}
				}
			}

			if (visited.size == edges.size)
			{
				break;
			}
		}
	}
	
	/**
	 * This method calculates the ideal edge length of each edge based on the
	 * depth and dimension of the ancestor nodes in the lowest common ancestor
	 * graph of the edge's end nodes. We assume depth and dimension of each node
	 * has already been calculated.
	 */
	private function calcIdealEdgeLengths():void
	{
		var edge:CoSEEdge;
		var lcaDepth:int;
		var source:LNode;
		var target:LNode;
		var sizeOfSourceInLca:int;
		var sizeOfTargetInLca:int;

		for each (var obj:* in this.graphManager.getAllEdges())
		{
			edge = obj as CoSEEdge;

			edge.idealLength = this.idealEdgeLength;

			if (edge.isInterGraph())
			{
				source = edge.getSource();
				target = edge.getTarget();

				sizeOfSourceInLca = edge.getSourceInLca().getEstimatedSize();
				sizeOfTargetInLca = edge.getTargetInLca().getEstimatedSize();

				if (this.useSmartIdealEdgeLengthCalculation)
				{
					edge.idealLength +=	sizeOfSourceInLca + sizeOfTargetInLca -
						2* LayoutConstants.SIMPLE_NODE_SIZE;
				}

				lcaDepth = edge.getLca().getInclusionTreeDepth();

				edge.idealLength += FDLayoutConstants.DEFAULT_EDGE_LENGTH *
					FDLayoutConstants.PER_LEVEL_IDEAL_EDGE_LENGTH_FACTOR *
						(source.getInclusionTreeDepth() +
							target.getInclusionTreeDepth() - 2* lcaDepth);
			}

//			NodeModel vSourceNode = (NodeModel)(edge.getSource().vGraphObject);
//			NodeModel vTargetNode = (NodeModel)(edge.getTarget().vGraphObject);
//
//			System.out.printf("\t%s-%s: %5.1f\n",
//				new Object [] {vSourceNode.getText(), vTargetNode.getText(), edge.idealLength});
		}
	}

	/**
	 * This method performs initial positioning of given forest radially. The
	 * final drawing should be centered at the gravitational center.
	 */
	protected function positionNodesRadially(forest:ArrayList/*<ArrayList<LNode>>*/):void
	{
		// We tile the trees to a grid row by row; first tree starts at (0,0)
		var currentStartingPoint:PointD = new PointD(0, 0); // (PointD instead of PointD)
		var numberOfColumns:int = Math.ceil(Math.sqrt(forest.size));
		var height:int = 0;
		var currentY:int = 0;
		var currentX:int = 0;
		var point:PointD = new PointD(0, 0);

		for (var i:int = 0; i < forest.size; i++)
		{
			if (i % numberOfColumns == 0)
			{
				// Start of a new row, make the x coordinate 0, increment the
				// y coordinate with the max height of the previous row
				currentX = 0;
				currentY = height;

				if (i !=0)
				{
					currentY += CoSEConstants.DEFAULT_COMPONENT_SEPERATION;
				}

				height = 0;
			}

			var tree:ArrayList/*<LNode>*/ = forest.itemAt(i) as ArrayList;

			// Find the center of the tree
			var centerNode:LNode = Layout.findCenterOfTree(tree);

			// Set the staring point of the next tree
			currentStartingPoint.x = currentX;
			currentStartingPoint.y = currentY;

			// Do a radial layout starting with the center
			point =
				CoSELayout.radialLayout(tree, centerNode, currentStartingPoint);

			if (point.y > height)
			{
				height = int(point.y);
			}

			currentX = int((point.x + CoSEConstants.DEFAULT_COMPONENT_SEPERATION));
		}

		this.transform(
			new PointD(LayoutConstants.WORLD_CENTER_X - point.x / 2,
				LayoutConstants.WORLD_CENTER_Y - point.y / 2));
	}

	/**
	 * This method positions given nodes according to a simple radial layout
	 * starting from the center node. The top-left of the final drawing is to be
	 * at given location. It returns the bottom-right of the bounding rectangle
	 * of the resulting tree drawing.
	 * 
	 * @param startingPoint		(PointD instead of Point)
	 */
	private static function radialLayout(tree:ArrayList/*<LNode>*/,
		centerNode:LNode,
		startingPoint:PointD):PointD
	{
		var radialSep:Number= Math.max(maxDiagonalInTree(tree),
			CoSEConstants.DEFAULT_RADIAL_SEPARATION);
		CoSELayout.branchRadialLayout(centerNode, null, 0, 359, 0, radialSep);
		var bounds:RectangleD = LGraph.calculateBounds(tree); // Rectangle to RD

		var transform:Transform= new Transform();
		transform.setDeviceOrgX(bounds.getX()); // bounds.getMinX() -> bounds.getX()
		transform.setDeviceOrgY(bounds.getY()); // bounds.getMinY() -> bounds.getY()
		transform.setWorldOrgX(startingPoint.x);
		transform.setWorldOrgY(startingPoint.y);

		var iter:IIterator = tree.iterator(); 
		
		//for each (var node:LNode in tree)
		while (iter.hasNext())
		{
			var node:LNode = iter.next() as LNode;
			node.transform(transform);
		}

		// bounds.getMaxX() -> bounds.getX() + bounds.getWidth()
		// bounds.getMaxY() -> bounds.getY() + bounds.getHeight()
		var bottomRight:PointD=
			new PointD(bounds.getX() + bounds.width, bounds.getY() + bounds.height);

		return transform.inverseTransformPoint(bottomRight);
	}

	/**
	 * This method is recursively called for radial positioning of a node,
	 * between the specified angles. Current radial level is implied by the
	 * distance given. Parent of this node in the tree is also needed.
	 */
	private static function branchRadialLayout(node:LNode,
		parentOfNode:LNode,
		startAngle:Number, endAngle:Number,
		distance:Number, radialSeparation:Number):void
	{
		// First, position this node by finding its angle.
		var halfInterval:Number = ((endAngle - startAngle) + 1) / 2;

		if (halfInterval < 0)
		{
			halfInterval += 180;
		}

		var nodeAngle:Number= (halfInterval + startAngle) % 360;
		var teta:Number= (nodeAngle * IGeometry.TWO_PI) / 360;

		// Make polar to java cordinate conversion.
		var x:Number= distance * Math.cos(teta);
		var y:Number= distance * Math.sin(teta);

		node.setCenter(x, y);

		// Traverse all neighbors of this node and recursively call this
		// function.

		var neighborEdges:LinkedList/*<LEdge>*/  = new LinkedList/*<LEdge>*/();
		var iter:IIterator = node.getEdges().iterator();
		
		//for each (var obj:* in node.getEdges())
		while (iter.hasNext())
		{
			neighborEdges.add(iter.next());
		}
		
		var childCount:int = neighborEdges.size;

		if (parentOfNode != null)
		{
			childCount--;
		}

		var branchCount:int= 0;

		var incEdgesCount:int = neighborEdges.size;
		var startIndex:int;

		var edges:IList = node.getEdgesBetween(parentOfNode);

		// If there are multiple edges, prune them until there remains only one
		// edge.
		while (edges.size > 1)
		{
			neighborEdges.remove(edges.removeAt(0));
			incEdgesCount--;
			childCount--;
		}

		if (parentOfNode != null)
		{
			// assert edges.size() == 1;
			
			// find the index of edges.itemAt(0) in neighborEdges
			
			var idx:int;
			var neighborArray:Array = neighborEdges.toArray();
			
			for (idx = 0; idx < neighborArray.length; idx++)
			{
				if (neighborArray[idx] === edges.itemAt(0))
				{
					break;
				}
			}
			
			//startIndex = (neighborEdges.indexOf(edges.itemAt(0)) + 1) % incEdgesCount;
			startIndex = (idx + 1) % incEdgesCount;
		}
		else
		{
			startIndex = 0;
		}

		var stepAngle:Number= Math.abs(endAngle - startAngle) / childCount;

		for (var i:int= startIndex;
			branchCount != childCount;
			i = (++i) % incEdgesCount)
		{
			var currentNeighbor:LNode =
				(neighborEdges.toArray()[i] as LEdge).getOtherEnd(node);

			// Don't back traverse to root node in current tree.
			if (currentNeighbor == parentOfNode)
			{
				continue;
			}

			var childStartAngle:Number=
				(startAngle + branchCount * stepAngle) % 360;
			var childEndAngle:Number= (childStartAngle + stepAngle) % 360;

			branchRadialLayout(currentNeighbor,
					node,
					childStartAngle, childEndAngle,
					distance + radialSeparation, radialSeparation);

			branchCount++;
		}
	}

	/**
	 * This method finds the maximum diagonal length of the nodes in given tree.
	 */
	private static function maxDiagonalInTree(tree:ArrayList/*<LNode>*/):Number
	{
		var maxDiagonal:Number= Number.MIN_VALUE;

		for (var i:int = 0; i < tree.size; i++)
		{
			var node:LNode = tree.itemAt(i) as LNode;
			var diagonal:Number= node.getDiagonal();

			if (diagonal > maxDiagonal)
			{
				maxDiagonal = diagonal;
			}
		}

		return maxDiagonal;
	}

	// -----------------------------------------------------------------------------
	// Section: Multi-level Scaling
	// -----------------------------------------------------------------------------
	
	/**
	 * This method un-coarsens Mi to Mi-1 and makes initial placement for Mi-1
	 */
	public function uncoarsen():void
	{
		for each (var obj:* in this.graphManager.getAllNodes())
		{
			var v:CoSENode= CoSENode(obj);
			// set positions of v.pred1 and v.pred2
			v.getPred1().setLocation(v.getLeft(), v.getTop());
			
			if (v.getPred2() != null)
			{
				// TODO: check 
				/*
				double w = v.getPred1().getRect().width;
				double l = this.idealEdgeLength;
				v.getPred2().setLocation((v.getPred1().getLeft()+w+l), (v.getPred1().getTop()+w+l));
				*/
				v.getPred2().setLocation(v.getLeft()+this.idealEdgeLength, 
					v.getTop()+this.idealEdgeLength);
			}
		}
	}
	
// -----------------------------------------------------------------------------
// Section: FR-Grid Variant Repulsion Force Calculation
// -----------------------------------------------------------------------------
	
	/**
	 * This method calculates the repulsion range
	 * Also it can be used to calculate the height of a grid's edge
	 */
	override protected function calcRepulsionRange():Number
	{
		// formula is 2 x (level + 1) x idealEdgeLength
		return (2* ( this.level+1) * this.idealEdgeLength);
	}
	
// -----------------------------------------------------------------------------
// Section: Temporary methods (especially for testing)
// -----------------------------------------------------------------------------

	//TODO: Remove the method after testing
	/**
	 * This method checks if there is a node with null vGraphObject
	 */
	private function checkVGraphObjects():Boolean
	{
		var obj:*;
		
		if (this.graphManager.getAllEdges() == null)
		{
			trace("Edge list is null!");
		}
		if (this.graphManager.getAllNodes() == null)
		{
			trace("Node list is null!");
		}
		if (this.graphManager.getGraphs() == null)
		{
			trace("Graph list is null!");
		}
		for each (obj in this.graphManager.getAllEdges())
		{
			var e:CoSEEdge= obj as CoSEEdge;
			//NodeModel nm = (NodeModel) v.vGraphObject;
			
			if (e.vGraphObject == null)
			{
				trace("Edge(Source): " + e.getSource().getRect() + " has null vGraphObject!");
				return false;
			}
		}
		
		for each (obj in this.graphManager.getAllNodes())
		{
			var v:CoSENode= obj as CoSENode;
			//NodeModel nm = (NodeModel) v.vGraphObject;
			
			if (v.vGraphObject == null)
			{
				trace("Node: " + v.getRect() + " has null vGraphObject!");
				return false;
			}
		}
		
		var iter:IIterator = this.graphManager.getGraphs().iterator();
		
		//for each (obj in this.graphManager.getGraphs())
		while (iter.hasNext())
		{
			var l:LGraph = iter.next() as LGraph;
			
			if (l.vGraphObject == null)
			{
				trace("Graph with " + l.getNodes().size + " nodes has null vGraphObject!");
				return false;
			}
		}
		
		return true;
	}
//	private void updateAnnealingProbability()
//	{
//		CoSELayout.annealingProbability = Math.pow(Math.E,
//			CoSELayout.annealingConstant / this.coolingFactor);
//	}
}
}
