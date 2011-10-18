package org.cytoscapeweb.view.layout.ivis.layout.cose
{
/*
import java.awt.Dimension;
import java.awt.Point;
import java.util.Iterator;
*/
import org.as3commons.collections.framework.IIterator;
import org.cytoscapeweb.view.layout.ivis.layout.*;
import org.cytoscapeweb.view.layout.ivis.layout.fd.FDLayoutNode;
import org.cytoscapeweb.view.layout.ivis.util.DimensionD;
import org.cytoscapeweb.view.layout.ivis.util.IMath;
import org.cytoscapeweb.view.layout.ivis.util.PointD;

//import org.gvt.model.NodeModel;

/**
 * This class implements CoSE specific data and functionality for nodes.
 *
 * @author Erhan Giral
 * @author Ugur Dogrusoz
 *
 * Copyright: i-Vis Research Group, Bilkent University, 2007 - present
 */
public class CoSENode extends FDLayoutNode
{
// -----------------------------------------------------------------------------
// Section: Instance variables
// -----------------------------------------------------------------------------
	/**
	 * This node is constructed by contracting pred1 and pred2 from Mi-1
	 * next is constructed by contracting this node and another node from Mi
	 */
	private var pred1:CoSENode;
	private var pred2:CoSENode;
	private var next:CoSENode;
	
	/**
	 * Processed flag for CoSENode is needed during the coarsening process
	 * a node can be the next node of two different nodes. 
	 * so it can already be processed during the coarsening process
	 */
	private var processed:Boolean;
	
// -----------------------------------------------------------------------------
// Section: Constructors and initialization
// -----------------------------------------------------------------------------
	
	/**
	 * Constructor
	 * 
	 * @param loc	TODO (PointD instead of Point)
	 * @param size	TODO (DimensionD instead of Dimension)
	 */
	public function CoSENode(gm:LGraphManager,
		vNode:*/*vNode:Object*/,
		loc:PointD = null,
		size:DimensionD = null)
	{
		super(gm, vNode, loc, size);
	}

// -----------------------------------------------------------------------------
// Section: Remaining methods
// -----------------------------------------------------------------------------
	/*
	 * This method recalculates the displacement related attributes of this
	 * object. These attributes are calculated at each layout iteration once,
	 * for increasing the speed of the layout.
	 */
	override public function move():void
	{
		var layout:CoSELayout= CoSELayout(this.graphManager.getLayout());
		this.displacementX = layout.coolingFactor *
			(this.springForceX + this.repulsionForceX + this.gravitationForceX);
		this.displacementY = layout.coolingFactor *
			(this.springForceY + this.repulsionForceY + this.gravitationForceY);

		//var str:String = printf("\t%s@[%5.1f,%5.1f] s=(%5.1f,%5.1f) r=(%5.1f,%5.1f) g=(%5.1f,%5.1f)",
		//	this.label,
		//	this.getLeft(), this.getTop(),
		//	this.springForceX, this.springForceY,
		//	this.repulsionForceX, this.repulsionForceY,
		//	this.gravitationForceX, this.gravitationForceY);
		
		//trace(str);
		
		if (Math.abs(this.displacementX) > layout.maxNodeDisplacement)
		{
//			//TODO: this dependency for debug purposes only!!!
//			NodeModel vNode = (NodeModel)this.vGraphObject;
//
//			System.out.printf("\tabove max %s: %5.1f",
//				new Object [] {vNode.getText(), this.displacementX});
//			System.out.printf("\t%s@[%5.1f,%5.1f] s=(%5.1f,%5.1f) r=(%5.1f,%5.1f) g=(%5.1f,%5.1f)\n",
//				new Object [] {vNode.getText(),
//				this.getLeft(), this.getTop(),
//				this.springForceX, this.springForceY,
//				this.repulsionForceX, this.repulsionForceY,
//				this.gravitationForceX, this.gravitationForceY});

			this.displacementX = layout.maxNodeDisplacement *
				IMath.sign(this.displacementX);
		}

		if (Math.abs(this.displacementY) > layout.maxNodeDisplacement)
		{
//			//TODO: this dependency for debug purposes only!!!
//			NodeModel vNode = (NodeModel)this.vGraphObject;
//
//			System.out.printf("\tabove max %s: %5.1f",
//				new Object [] {vNode.getText(), this.displacementY});
//			System.out.printf("\t%s@[%5.1f,%5.1f] s=(%5.1f,%5.1f) r=(%5.1f,%5.1f) g=(%5.1f,%5.1f)\n",
//				new Object [] {vNode.getText(),
//				this.getLeft(), this.getTop(),
//				this.springForceX, this.springForceY,
//				this.repulsionForceX, this.repulsionForceY,
//				this.gravitationForceX, this.gravitationForceY});

			this.displacementY = layout.maxNodeDisplacement *
				IMath.sign(this.displacementY);
		}

		// Apply simulated annealing here
//		if (Math.random() < CoSELayout.annealingProbability && CoSELayout.simulatedAnnealingOn)
//		{
//			this.displacementX = -this.displacementX;
//			this.displacementY = -this.displacementY;
//
//			CoSELayout.randomizedMovementCount++;
//		}
//		else
//		{
//			CoSELayout.nonRandomizedMovementCount++;
//		}

		if (this.child == null)
		// a simple node, just move it
		{
			this.moveBy(this.displacementX, this.displacementY);
		}
		else if (this.child.getNodes().size == 0)
		// an empty compound node, again just move it
		{
			this.moveBy(this.displacementX, this.displacementY);
		}
		// non-empty compound node, propogate movement to children as well
		else
		{
			this.propogateDisplacementToChildren(this.displacementX,
				this.displacementY);
		}

//		//TODO: this dependency for debug purposes only!!!
//		NodeModel vNode = (NodeModel)this.vGraphObject;
//
//		System.out.printf("\t%s@[%5.1f,%5.1f] s=(%5.1f,%5.1f) r=(%5.1f,%5.1f) g=(%5.1f,%5.1f)\n",
//			new Object [] {vNode.getText(),
//			this.getLeft(), this.getTop(),
//			this.springForceX, this.springForceY,
//			this.repulsionForceX, this.repulsionForceY,
//			this.gravitationForceX, this.gravitationForceY});

		layout.totalDisplacement +=
			Math.abs(this.displacementX) + Math.abs(this.displacementY);

		this.springForceX = 0;
		this.springForceY = 0;
		this.repulsionForceX = 0;
		this.repulsionForceY = 0;
		this.gravitationForceX = 0;
		this.gravitationForceY = 0;
		this.displacementX = 0;
		this.displacementY = 0;
	}

	/*
	 * This method applies the transformation of a compound node (denoted as
	 * root) to all the nodes in its children graph
	 */
	public function propogateDisplacementToChildren(dX:Number, dY:Number):void
	{
		var iter:IIterator = this.getChild().getNodes().iterator();
		
		//for each (var lNode:CoSENode in this.getChild().getNodes())
		while (iter.hasNext())
		{
			var lNode:CoSENode = iter.next() as CoSENode;
			
			lNode.moveBy(dX, dY);
			lNode.displacementX += dX;
			lNode.displacementY += dY;

			if (lNode.getChild() != null)
			{
				lNode.propogateDisplacementToChildren(dX, dY);
			}
		}

		//this.updateBounds();
	}
		
// -----------------------------------------------------------------------------
// Section: Getters and setters
// -----------------------------------------------------------------------------
	public function setPred1(pred1:CoSENode):void {
		this.pred1 = pred1;
	}

	public function getPred1():CoSENode {
		return pred1;
	}

	public function setPred2(pred2:CoSENode):void {
		this.pred2 = pred2;
	}

	public function getPred2():CoSENode {
		return pred2;
	}

	public function setNext(next:CoSENode):void {
		this.next = next;
	}

	public function getNext():CoSENode {
		return next;
	}

	public function setProcessed(processed:Boolean):void {
		this.processed = processed;
	}

	public function isProcessed():Boolean {
		return processed;
	}
}
}