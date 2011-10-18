package org.cytoscapeweb.view.layout.ivis.layout.fd
{
	
/*
import java.util.HashSet;
import java.util.Vector;
*/
	
import org.as3commons.collections.Set;
import org.cytoscapeweb.view.layout.ivis.layout.*;
import org.cytoscapeweb.view.layout.ivis.util.*;

/**
 * This class implements common data and functionality for all layout styles
 * that are force-directed.
 *
 * @author: Ugur Dogrusoz
 *
 * Copyright: i-Vis Research Group, Bilkent University, 2007 - present
 */
public /*abstract*/ class FDLayout extends Layout
{
// -----------------------------------------------------------------------------
// Section: Instance variables
// -----------------------------------------------------------------------------
	/**
	 * Ideal length of an edge
	 */
	protected var idealEdgeLength:Number = FDLayoutConstants.DEFAULT_EDGE_LENGTH as Number;

	/**
	 * Constant for calculating spring forces
	 */
	protected var springConstant:Number= FDLayoutConstants.DEFAULT_SPRING_STRENGTH;

	/**
	 * Constant for calculating repulsion forces
	 */
	protected var repulsionConstant:Number=
		FDLayoutConstants.DEFAULT_REPULSION_STRENGTH;

	/**
	 * Constants for calculating gravitation forces
	 */
	protected var gravityConstant:Number= FDLayoutConstants.DEFAULT_GRAVITY_STRENGTH;
	protected var compoundGravityConstant:Number=
		FDLayoutConstants.DEFAULT_COMPOUND_GRAVITY_STRENGTH;

	/**
	 * Factors to determine the ranges within which gravity is not to be applied
	 */
	protected var gravityRangeFactor:Number=
		FDLayoutConstants.DEFAULT_GRAVITY_RANGE_FACTOR;
	protected var compoundGravityRangeFactor:Number=
		FDLayoutConstants.DEFAULT_COMPOUND_GRAVITY_RANGE_FACTOR;

	/**
	 * Threshold for convergence per node
	 */
	public var displacementThresholdPerNode:Number=
		(3.0* (FDLayoutConstants.DEFAULT_EDGE_LENGTH as Number)) / 100;

	/**
	 * Whether or not FR grid variant should be used for repulsion force calculations.
	 */
	protected var useFRGridVariant:Boolean= 
		FDLayoutConstants.DEFAULT_USE_SMART_REPULSION_RANGE_CALCULATION;
	
	/**
	 * Factor used for cooling layout; starts from 1.0 and goes down towards
	 * zero as we approach maximum iterations. Incremental layout might start
	 * with a smaller value.
	 */
	public var coolingFactor:Number= 1.0;
	public var initialCoolingFactor:Number= 1.0;
	
	/**
	 * Total displacement made in this iteration
	 */
	public var totalDisplacement:Number= 0.0;

	/**
	 * Total displacement made in the previous iteration
	 */
	public var oldTotalDisplacement:Number= 0.0;

	/**
	 * Maximum number of layout iterations allowed
	 */
	protected var maxIterations:int= 2500;

	/**
	 * Total number of iterations currently performed
	 */
	protected var totalIterations:int;

	/**
	 * Number of layout iterations that has not been animated (rendered)
	 */
	protected var notAnimatedIterations:int;

	/**
	 * Threshold for convergence (calculated according to graph to be laid out)
	 */
	public var totalDisplacementThreshold:Number;

	/**
	 * Maximum node displacement in allowed in one iteration
	 */
	public var maxNodeDisplacement:Number;
	
	/**
	 * Repulsion range & edge size of a grid
	 */
	protected var repulsionRange:Number;
	
	/**
	 * Screen is divided into grid of squares.
	 * At each iteration, each node is placed in its grid square(s)
	 * Grid is re-calculated after every tenth iteration.
	 */
	protected var grid:Array; // Vector[][]
	
// -----------------------------------------------------------------------------
// Section: Constructors and initialization
// -----------------------------------------------------------------------------
	/**
	 * The constructor creates and associates with this layout a new graph
	 * manager as well.
	 */
	public function FDLayout()
	{
		super();
	}

	/**
	 * This method is used to set all layout parameters to default values.
	 */
	override public function initParameters():void
	{
		super.initParameters();

		var layoutOptionsPack:CoSEOptions =
			LayoutOptionsPack.getInstance().getCoSE();
		
		if (this.layoutQuality == LayoutConstants.DRAFT_QUALITY)
		{
			this.displacementThresholdPerNode += 0.30;
			this.maxIterations *= 0.8;
		}
		else if (this.layoutQuality == LayoutConstants.PROOF_QUALITY)
		{
			this.displacementThresholdPerNode -= 0.30;
			this.maxIterations *= 1.2;
		}

		this.totalIterations = 0;
		this.notAnimatedIterations = 0;
		
		this.useFRGridVariant = layoutOptionsPack.isSmartRepulsionRangeCalc();
	}

// -----------------------------------------------------------------------------
// Section: Remaining methods
// -----------------------------------------------------------------------------
	/**
	 * This method is used to set parameters used by spring embedder.
	 */
	public function initSpringEmbedder():void
	{
		if (this.incremental)
		{
			this.coolingFactor = 0.8;
			this.initialCoolingFactor = 0.8;
			this.maxNodeDisplacement = 
				FDLayoutConstants.MAX_NODE_DISPLACEMENT_INCREMENTAL;
		}
		else
		{
			this.coolingFactor = 1.0;
			this.initialCoolingFactor = 1.0;
			this.maxNodeDisplacement =
				FDLayoutConstants.MAX_NODE_DISPLACEMENT;
		}

		this.maxIterations =
			Math.max(this.getAllNodes().length * 5, this.maxIterations);

		this.totalDisplacementThreshold =
			this.displacementThresholdPerNode * this.getAllNodes().length;
		
		this.repulsionRange = this.calcRepulsionRange();
	}

	/**
	 * This method calculates the spring forces for the ends of each node.
	 */
	public function calcSpringForces():void
	{
		//var lEdges:Array= this.getAllEdges();
		//var edge:FDLayoutEdge;

		//for (var i:int= 0; i < lEdges.length; i++)
		for each (var edge:FDLayoutEdge in this.getAllEdges())
		{
			//edge = FDLayoutEdge(lEdges[i]);
			this.calcSpringForce(edge, edge.idealLength);
		}
	}

	/**
	 * This method calculates the repulsion forces for each pair of nodes.
	 */
	public function calcRepulsionForces():void
	{
		var i:int, j:int;
		var nodeA:FDLayoutNode, nodeB:FDLayoutNode;
		var lNodes:Array = this.getAllNodes();
		var processedNodeSet:Set/*<FDLayoutNode>*/;
		
		if (this.useFRGridVariant)
		{
			// grid is a vector matrix that holds CoSENodes.
			// be sure to convert the Object type to CoSENode.
			
			if (this.totalIterations % FDLayoutConstants.GRID_CALCULATION_CHECK_PERIOD == 1)
			{
				this.grid = this.calcGrid(this.graphManager.getRoot());
				
				// put all nodes to proper grid cells
				for (i = 0; i < lNodes.length; i++)
				{
					nodeA = FDLayoutNode(lNodes[i]);
					this.addNodeToGrid(nodeA, this.grid,
						this.graphManager.getRoot().getLeft(),
						this.graphManager.getRoot().getTop());
				}
			}
			
			processedNodeSet = new Set/*<FDLayoutNode>*/();
			
			// calculate repulsion forces between each nodes and its surrounding
			for (i = 0; i < lNodes.length; i++)
			{
				nodeA = FDLayoutNode(lNodes[i]);
				this.calculateRepulsionForceOfANode(this.grid, nodeA, processedNodeSet);
				processedNodeSet.add(nodeA);
			}			
		}
		else
		{
			for (i = 0; i < lNodes.length; i++)
			{
				nodeA = FDLayoutNode(lNodes[i]);

				for (j = i + 1; j < lNodes.length; j++)
				{
					nodeB = FDLayoutNode(lNodes[j]);

					// If both nodes are not members of the same graph, skip.
					if (nodeA.getOwner() != nodeB.getOwner())
					{
						continue;
					}

					this.calcRepulsionForce(nodeA, nodeB);
				}
			}
		}
	}

	/**
	 * This method calculates gravitational forces to keep components together.
	 */
	public function calcGravitationalForces():void
	{
		var node:FDLayoutNode;
		var lNodes:Array= this.getAllNodesToApplyGravitation();

		for (var i:int= 0; i < lNodes.length; i++)
		{
			node = FDLayoutNode(lNodes[i]);

			this.calcGravitationalForce(node);
		}
	}

	/**
	 * This method updates positions of each node at the end of an iteration.
	 */
	public function moveNodes():void
	{
		//var lNodes:Array = this.getAllNodes();
		//var node:FDLayoutNode;

		//for (var i:int= 0; i < lNodes.length; i++)
		for each (var node:FDLayoutNode in this.getAllNodes())
		{
			//node = FDLayoutNode(lNodes[i]);
			node.move();
		}
	}

	/**
	 * This method calculates the spring force for the ends of input edge based
	 * on the input ideal length.
	 */
	protected function calcSpringForce(edge:LEdge, idealLength:Number):void
	{
		var sourceNode:FDLayoutNode = edge.getSource() as FDLayoutNode;
		var targetNode:FDLayoutNode = edge.getTarget() as FDLayoutNode;
		var length:Number;
		var springForce:Number;
		var springForceX:Number;
		var springForceY:Number;

		// Update edge length

		if (this.uniformLeafNodeSizes &&
			sourceNode.getChild() == null && targetNode.getChild() == null)
		{
			edge.updateLengthSimple();
		}
		else
		{
			edge.updateLength();

			if (edge.isOverlapingSourceAndTarget())
			{
				return;
			}
		}

		length = edge.getLength();

		// Calculate spring forces
		springForce = this.springConstant * (length - idealLength);

	//			// does not seem to be needed
	//			if (Math.abs(springForce) > CoSEConstants.MAX_SPRING_FORCE)
	//			{
	//				springForce = IMath.sign(springForce) * CoSEConstants.MAX_SPRING_FORCE;
	//			}

		// Project force onto x and y axes
		springForceX = springForce * (edge.getLengthX() / length);
		springForceY = springForce * (edge.getLengthY() / length);

		//TODO: remove this dependency!
	//			NodeModel vSourceNode = (NodeModel)sourceNode.vGraphObject;
	//			NodeModel vTargetNode = (NodeModel)targetNode.vGraphObject;
	//
	//			if (vSourceNode.getText().equals("1") || vTargetNode.getText().equals("1"))
	//			{
	//				System.out.printf("\t%s-%s\n",
	//					new Object [] {vSourceNode.getText(), vTargetNode.getText()});
	//			}

		// Apply forces on the end nodes
		sourceNode.springForceX += springForceX;
		sourceNode.springForceY += springForceY;
		targetNode.springForceX -= springForceX;
		targetNode.springForceY -= springForceY;
	}

	/**
	 * This method calculates the repulsion forces for the input node pair.
	 */
	protected function calcRepulsionForce(nodeA:FDLayoutNode, nodeB:FDLayoutNode):void
	{
		var rectA:RectangleD = nodeA.getRect();
		var rectB:RectangleD = nodeB.getRect();
		var overlapAmount:Array = new Array(2); //double[2]
		var clipPoints:Array = new Array(4); //double[4];
		var distanceX:Number;
		var distanceY:Number;
		var distanceSquared:Number;
		var distance:Number;
		var repulsionForce:Number;
		var repulsionForceX:Number;
		var repulsionForceY:Number;
		
		if (rectA.intersects(rectB))
		// two nodes overlap
		{
			// calculate overlap amount in x and y directions
			IGeometry.calcSmallerIntersection(rectA, rectB, overlapAmount);

			if (Math.abs(overlapAmount[0]) < Math.abs(overlapAmount[1]))
			// should repell in x direction to avoid overlap
			{
				if (rectA.x < rectB.x)
				{
					repulsionForceX = (IMath.sign(overlapAmount[0]) *
						FDLayoutConstants.DEFAULT_EDGE_LENGTH +
						overlapAmount[0]) / 2;
				}
				else
				{
					repulsionForceX = -1 * (IMath.sign(overlapAmount[0]) *
						FDLayoutConstants.DEFAULT_EDGE_LENGTH +
						overlapAmount[0]) / 2;
				}

				repulsionForceY = 0.0;
			}
			else
			// should repell in y direction to avoid overlap
			{
				repulsionForceX = 0.0;

				if (rectA.y < rectB.y)
				{
					repulsionForceY = (IMath.sign(overlapAmount[1]) *
						FDLayoutConstants.DEFAULT_EDGE_LENGTH +
						overlapAmount[1]) / 2;
				}
				else
				{
					repulsionForceY = -1 * (IMath.sign(overlapAmount[1]) *
						FDLayoutConstants.DEFAULT_EDGE_LENGTH +
						overlapAmount[1]) / 2;
				}
			}

//					System.out.printf("\toverlap=(%5.1f,%5.1f)\n",
//						new Object [] {overlapAmount[0], overlapAmount[1]});
		}
		else
		// no overlap
		{
			// calculate distance

			if (this.uniformLeafNodeSizes &&
				nodeA.getChild() == null && nodeB.getChild() == null)
			// simply base repulsion on distance of node centers
			{
				distanceX = rectB.getCenterX() - rectA.getCenterX();
				distanceY = rectB.getCenterY() - rectA.getCenterY();
			}
			else
			// use clipping points
			{
				IGeometry.getIntersection(rectA, rectB, clipPoints);

				distanceX = clipPoints[2] - clipPoints[0];
				distanceY = clipPoints[3] - clipPoints[1];
			}

			//TODO: No repulsion range. The grid variant should take care of this...

			if (Math.abs(distanceX) < FDLayoutConstants.MIN_REPULSION_DIST)
			{
				distanceX = IMath.sign(distanceX) *
					FDLayoutConstants.MIN_REPULSION_DIST;
			}

			if (Math.abs(distanceY) < FDLayoutConstants.MIN_REPULSION_DIST)
			{
				distanceY = IMath.sign(distanceY) *
					FDLayoutConstants.MIN_REPULSION_DIST;
			}

			distanceSquared = distanceX * distanceX + distanceY * distanceY;
			distance = Math.sqrt(distanceSquared);

			repulsionForce = this.repulsionConstant / distanceSquared;

//					// does not seem to be needed
//						if (Math.abs(repulsionForce) > CoSEConstants.MAX_REPULSION_FORCE)
//						{
//							repulsionForce = IMath.sign(repulsionForce) * CoSEConstants.MAX_REPULSION_FORCE;
//						}

			// Project force onto x and y axes
			repulsionForceX = repulsionForce * distanceX / distance;
			repulsionForceY = repulsionForce * distanceY / distance;
		}

		// Apply forces on the two nodes
		nodeA.repulsionForceX -= repulsionForceX;
		nodeA.repulsionForceY -= repulsionForceY;
		nodeB.repulsionForceX += repulsionForceX;
		nodeB.repulsionForceY += repulsionForceY;
	}

	/**
	 * This method calculates gravitational force for the input node.
	 */
	protected function calcGravitationalForce(node:FDLayoutNode):void
	{
		//assert node.gravitationForceX == 0&& node.gravitationForceY == 0;

		var ownerGraph:LGraph;
		var ownerCenterX:Number;
		var ownerCenterY:Number;
		var distanceX:Number;
		var distanceY:Number;
		var absDistanceX:Number;
		var absDistanceY:Number;
		var estimatedSize:int;
		
		ownerGraph = node.getOwner();

		ownerCenterX = (ownerGraph.getRight() + ownerGraph.getLeft()) / 2;
		ownerCenterY = (ownerGraph.getTop() + ownerGraph.getBottom()) / 2;
		distanceX = node.getCenterX() - ownerCenterX;
		distanceY = node.getCenterY() - ownerCenterY;
		absDistanceX = Math.abs(distanceX);
		absDistanceY = Math.abs(distanceY);

		// Apply gravitation only if the node is "roughly" outside the
		// bounds of the initial estimate for the bounding rect of the owner
		// graph. We relax (not as much for the compounds) the estimated
		// size here since the initial estimates seem to be rather "tight".

		if (node.getOwner() == this.graphManager.getRoot())
		// in the root graph
		{
			estimatedSize = int((ownerGraph.getEstimatedSize() *
				this.gravityRangeFactor));

			if (absDistanceX > estimatedSize || absDistanceY > estimatedSize)
			{
				node.gravitationForceX = -1 * this.gravityConstant * distanceX;
				node.gravitationForceY = -1 * this.gravityConstant * distanceY;
			}
		}
		else
		// inside a compound
		{
			estimatedSize = int((ownerGraph.getEstimatedSize() *
				this.compoundGravityRangeFactor));

			if (absDistanceX > estimatedSize || absDistanceY > estimatedSize)
			{
				node.gravitationForceX = -1 * this.gravityConstant * distanceX *
					this.compoundGravityConstant;
				node.gravitationForceY = -1 * this.gravityConstant * distanceY *
					this.compoundGravityConstant;
			}
		}

//			System.out.printf("\tgravitation=(%5.1f,%5.1f)\n",
//				new Object [] {node.gravitationForceX, node.gravitationForceY});
	}

	/**
	 * This method inspects whether the graph has reached to a minima. It
	 * returns true if the layout seems to be oscillating as well.
	 */
	protected function isConverged():Boolean
	{
		var converged:Boolean;
		var oscilating:Boolean= false;

		if (this.totalIterations > this.maxIterations / 3)
		{
			oscilating =
				Math.abs(this.totalDisplacement - this.oldTotalDisplacement) < 2;
		}

		converged = this.totalDisplacement < this.totalDisplacementThreshold;

		this.oldTotalDisplacement = this.totalDisplacement;

		return (converged || oscilating);
	}

	/**
	 * This method updates the v-level compound graph coordinates and refreshes
	 * the display if corresponding flag is on.
	 */
	protected function animate():void
	{
		if (this.animationDuringLayout && !this.isSubLayout)
		{
			if (this.notAnimatedIterations == this.animationPeriod)
			{
				this.update();

				this.notAnimatedIterations = 0;
			}
			else
			{
				this.notAnimatedIterations++;
			}
		}
	}
	
// -----------------------------------------------------------------------------
// Section: FR-Grid Variant Repulsion Force Calculation
// -----------------------------------------------------------------------------
	/**
	 * This method creates the empty grid with proper dimensions
	 */
	private function calcGrid(g:LGraph):Array /*Vector[][]*/
	{
		var i:int, j:int;
		var grid:Array; // Vector[][]
		
		var sizeX:int = 0;
		var sizeY:int = 0;
		
		sizeX = Math.ceil((g.getRight() - g.getLeft()) / this.repulsionRange);
		sizeY = Math.ceil((g.getBottom() - g.getTop()) / this.repulsionRange);
		
		grid = new Array(sizeX); //Vector[sizeX][sizeY];
		
		for (i = 0; i < sizeX; i++)
		{
			grid[i] = new Array(sizeY);
		}
		
		for (i = 0; i < sizeX; i++)
		{
			for (j = 0; j < sizeY; j++)
			{
				grid[i][j] = new Array();//new Vector();
			}
		}
		
		return grid;
	}
	
	/**
	 * This method adds input node v to the proper grid squares, 
	 * and also sets the grid start and finish points of v 
	 */
	private function addNodeToGrid(v:FDLayoutNode, 
		grid:Array, /*Vector[][]*/ 
		left:Number, 
		top:Number):void
	{
		var startX:int = 0;
		var finishX:int = 0;
		var startY:int = 0;
		var finishY:int = 0;
		
		startX = Math.floor((v.getRect().x - left) / this.repulsionRange);
		finishX = Math.floor((v.getRect().width + v.getRect().x - left) / this.repulsionRange);
		startY = Math.floor((v.getRect().y - top) / this.repulsionRange);
		finishY = Math.floor((v.getRect().height + v.getRect().y - top) / this.repulsionRange);
		
		for (var i:int = startX; i <= finishX; i++)
		{
			for (var j:int = startY; j <= finishY; j++)
			{
				var vector:Array = grid[i][j] as Array;
				
				vector.push(v);
				v.setGridCoordinates(startX, finishX, startY, finishY); 
			}
		}
	}
	
	/**
	 * This method finds surrounding nodes of nodeA in repulsion range.
	 * And calculates the repulsion forces between nodeA and its surrounding.
	 * During the calculation, ignores the nodes that have already been processed.
	 */
	private function calculateRepulsionForceOfANode(grid:Array, /*Vector[][]*/ 
		nodeA:FDLayoutNode,
		processedNodeSet:Set/*<FDLayoutNode>*/):void
	{
		var i:int, j:int;
		
		if (this.totalIterations % FDLayoutConstants.GRID_CALCULATION_CHECK_PERIOD == 1)
		{
			var surrounding:Set/*<Object>*/ = new Set/*<Object>*/();
			var nodeB:FDLayoutNode;
			
			for (i = (nodeA.startX-1); i < (nodeA.finishX+2); i++)
			{
				for (j = (nodeA.startY-1); j < (nodeA.finishY+2); j++)
				{
					if (!((i < 0) || (j < 0) || (i >= grid.length) || (j >= (grid[0] as Array).length)))
					{
						for each (nodeB in grid[i][j])
						{
							// If both nodes are not members of the same graph, 
							// or both nodes are the same, skip.
							if ((nodeA.getOwner() !== nodeB.getOwner()) 
								|| (nodeA === nodeB))
							{
								continue;
							}
							
							// check if the repulsion force between 
							// nodeA and nodeB has already been calculated
							if (!processedNodeSet.has(nodeB) && !surrounding.has(nodeB))
							{	
								var distanceX:Number= Math.abs(nodeA.getCenterX()-nodeB.getCenterX()) - 
									((nodeA.getWidth()/2) + (nodeB.getWidth()/2));
								var distanceY:Number= Math.abs(nodeA.getCenterY()-nodeB.getCenterY()) - 
									((nodeA.getHeight()/2) + (nodeB.getHeight()/2));
								
								// if the distance between nodeA and nodeB 
								// is less then calculation range
								if ((distanceX <= this.repulsionRange) && (distanceY <= this.repulsionRange))
								{
									//then add nodeB to surrounding of nodeA
									surrounding.add(nodeB);
								}
							}
						}
					}
				}
			}
			nodeA.surrounding = surrounding.toArray();
		}

		for (i = 0; i < nodeA.surrounding.length; i++)
		{
			this.calcRepulsionForce(nodeA, FDLayoutNode(nodeA.surrounding[i]));
		}
	}
	
	/**
	 * This method calculates repulsion range
	 * Also it can be used to calculate the height of a grid's edge
	 */
	protected function calcRepulsionRange():Number
	{
		return 0.0;
	}
}
}