package org.cytoscapeweb.view.layout.ivis.layout
{

//import java.util.*;

import flash.errors.IllegalOperationError;

import org.as3commons.collections.ArrayList;
import org.as3commons.collections.framework.IList;
import org.cytoscapeweb.view.layout.ivis.util.*;

/**
 * This class represents an edge (l-level) for layout purposes.
 *
 * @author Erhan Giral
 * @author Ugur Dogrusoz
 * @author Cihan Kucukkececi
 *
 * Copyright: i-Vis Research Group, Bilkent University, 2007 - present
 */
public class LEdge extends LGraphObject
{
// -----------------------------------------------------------------------------
// Section: Instance variables
// -----------------------------------------------------------------------------
	/*
	 * Source and target nodes of this edge
	 */
	internal /*protected*/ var source:LNode;
	internal /*protected*/ var target:LNode;

	/*
	 * Whether this edge is an intergraph one
	 */
	internal /*protected*/ var _isInterGraph:Boolean;

	/*
	 * The length of this edge ( l = sqrt(x^2 + y^2) )
	 */
	protected var length:Number;
	protected var lengthX:Number;
	protected var lengthY:Number;

	/*
	 * Whether source and target node rectangles intersect, requiring special
	 * treatment
	 */
	protected var _isOverlapingSourceAndTarget:Boolean= false;

	/*
	 * Bend points for this edge
	 */
	protected var bendpoints:ArrayList/*<PointD>*/;

	/*
	 * Lowest common ancestor graph (lca), and source and target nodes in lca
	 */
	internal /*protected*/ var lca:LGraph;
	internal /*protected*/ var sourceInLca:LNode;
	internal /*protected*/ var targetInLca:LNode;

// -----------------------------------------------------------------------------
// Section: Constructors and initializations
// -----------------------------------------------------------------------------
	/*
	 * Constructor
	 */
	public function LEdge(source:LNode,
		target:LNode,
		vEdge:*/*vEdge:Object*/)
	{
		super(vEdge);

		this.bendpoints = new ArrayList();

		this.source = source;
		this.target = target;
	}

// -----------------------------------------------------------------------------
// Section: Accessors
// -----------------------------------------------------------------------------
	/**
	 * This method returns the source node of this edge.
	 */
	public function getSource():LNode
	{
		return this.source;
	}

	/**
	 * This method returns the target node of this edge.
	 */
	public function getTarget():LNode
	{
		return this.target;
	}

	/**
	 * This method returns whether or not this edge is an inter-graph edge.
	 */
	public function isInterGraph():Boolean
	{
		return this._isInterGraph;
	}

	/**
	 * This method returns the length of this edge. Note that this value might
	 * be out-dated at times during a layout operation.
	 */
	public function getLength():Number
	{
		return this.length;
	}

	/**
	 * This method returns the x component of the length of this edge. Note that
	 * this value might be out-dated at times during a layout operation.
	 */
	public function getLengthX():Number
	{
		return this.lengthX;
	}

	/**
	 * This method returns the y component of the length of this edge. Note that
	 * this value might be out-dated at times during a layout operation.
	 */
	public function getLengthY():Number
	{
		return this.lengthY;
	}

	/**
	 * This method returns whether or not this edge has overlapping source and
	 * target.
	 */
	public function isOverlapingSourceAndTarget():Boolean
	{
		return this._isOverlapingSourceAndTarget;
	}

	/**
	 * This method resets the overlapping source and target status of this edge.
	 */
	public function resetOverlapingSourceAndTarget():void
	{
		this._isOverlapingSourceAndTarget = false;
	}

	/**
	 * This method returns the list of bend points of this edge.
	 */
	public function getBendpoints():IList/*<PointD>*/
	{
		return this.bendpoints;
	}

	/**
	 * This method clears all existing bendpoints and sets given bendpoints as 
	 * the new ones.
	 */
	public function reRoute(bendPoints:IList/*<PointD>*/):void
	{
		this.bendpoints.clear();
		
		this.bendpoints.addAllAt(0, bendPoints.toArray());
	}

	public function getLca():LGraph
	{
		return this.lca;
	}

	public function getSourceInLca():LNode
	{
		return this.sourceInLca;
	}

	public function getTargetInLca():LNode
	{
		return this.targetInLca;
	}

// -----------------------------------------------------------------------------
// Section: Remaining methods
// -----------------------------------------------------------------------------
	/**
	 * This method returns the end of this edge different from the input one.
	 */
	public function getOtherEnd(node:LNode):LNode
	{
		if (this.source == (node))
		{
			return this.target;
		}
		else if (this.target == (node))
		{
			return this.source;
		}
		else
		{
		//	throw new IllegalArgumentException(
		//		"Node is not incident " + "with this edge");
			throw new IllegalOperationError(
				"Node is not incident " + "with this edge");
		}
	}

	/**
	 * This method finds the other end of this edge, and returns its ancestor
	 * node, possibly the other end node itself, that is in the input graph. It
	 * returns null if none of its ancestors is in the input graph.
	 */
	public function getOtherEndInGraph(node:LNode, graph:LGraph):LNode
	{
		var otherEnd:LNode= this.getOtherEnd(node);
		var root:LGraph= graph.getGraphManager().getRoot();

		while (true)
		{
			if (otherEnd.getOwner() == graph)
			{
				return otherEnd;
			}

			if (otherEnd.getOwner() == root)
			{
				break;
			}

			otherEnd = otherEnd.getOwner().getParent();
		}

		return null;
	}

	/**
	 * This method updates the length of this edge as well as whether or not the
	 * rectangles representing the geometry of its end nodes overlap.
	 */
	public function updateLength():void
	{
		var clipPointCoordinates:Array = new Array(4); /*double[4]*/

		this._isOverlapingSourceAndTarget =
			IGeometry.getIntersection(this.target.getRect(),
				this.source.getRect(),
				clipPointCoordinates);

		if (!this._isOverlapingSourceAndTarget)
		{
			// target clip point minus source clip point gives us length

			this.lengthX = clipPointCoordinates[0] - clipPointCoordinates[2];
			this.lengthY = clipPointCoordinates[1] - clipPointCoordinates[3];

			if (Math.abs(this.lengthX) < 1.0)
			{
				this.lengthX = IMath.sign(this.lengthX);
			}

			if (Math.abs(this.lengthY) < 1.0)
			{
				this.lengthY = IMath.sign(this.lengthY);
			}

			this.length = Math.sqrt(
				this.lengthX * this.lengthX + this.lengthY * this.lengthY);
		}
	}

	/**
	 * This method updates the length of this edge using the end nodes centers
	 * as opposed to clipping points to simplify calculations involved.
	 */
	public function updateLengthSimple():void
	{
		// target center minus source center gives us length

		this.lengthX = this.target.getCenterX() - this.source.getCenterX();
		this.lengthY = this.target.getCenterY() - this.source.getCenterY();

		if (Math.abs(this.lengthX) < 1.0)
		{
			this.lengthX = IMath.sign(this.lengthX);
		}

		if (Math.abs(this.lengthY) < 1.0)
		{
			this.lengthY = IMath.sign(this.lengthY);
		}

		this.length = Math.sqrt(
			this.lengthX * this.lengthX + this.lengthY * this.lengthY);
	}

// -----------------------------------------------------------------------------
// Section: Testing methods
// -----------------------------------------------------------------------------
	/**
	 * This method prints the topology of this edge.
	 */
	public function printTopology():void
	{
		trace( (this.label == null ? "?" : this.label) + "[" +
			(this.source.label == null ? "?" : this.source.label) + "-" +
			(this.target.label == null ? "?" : this.target.label) + "] ");
	}
}
}