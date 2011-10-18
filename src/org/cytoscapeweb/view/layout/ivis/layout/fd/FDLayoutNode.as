package org.cytoscapeweb.view.layout.ivis.layout.fd
{

//import java.awt.Dimension;
//import java.awt.Point;

import flash.errors.IllegalOperationError;

import org.cytoscapeweb.view.layout.ivis.layout.LGraphManager;
import org.cytoscapeweb.view.layout.ivis.layout.LNode;
import org.cytoscapeweb.view.layout.ivis.util.DimensionD;
import org.cytoscapeweb.view.layout.ivis.util.PointD;



/**
 * This class implements common data and functionality for nodes of all layout
 * styles that are force-directed.
 *
 * @author: Ugur Dogrusoz
 *
 * Copyright: i-Vis Research Group, Bilkent University, 2007 - present
 */
public /*abstract*/ class FDLayoutNode extends LNode
{
// -----------------------------------------------------------------------------
// Section: Instance variables
// -----------------------------------------------------------------------------
	/*
	 * Spring, repulsion and gravitational forces acting on this node
	 */
	public var springForceX:Number;
	public var springForceY:Number;
	public var repulsionForceX:Number;
	public var repulsionForceY:Number;
	public var gravitationForceX:Number;
	public var gravitationForceY:Number;

	/*
	 * Amount by which this node is to be moved in this iteration
	 */
	public var displacementX:Number;
	public var displacementY:Number;

	/**
	 * Start and finish grid coordinates that this node is fallen into
	 */
	public var startX:int;
	public var finishX:int;
	public var startY:int;
	public var finishY:int;
	
	/**
	 * Geometric neighbors of this node 
	 */
	public var surrounding:Array;
	
// -----------------------------------------------------------------------------
// Section: Constructors and initialization
// -----------------------------------------------------------------------------
	
	/**
	 * Constructor
	 * 
	 * @param loc	TODO (PointD instead of Point)
	 * @param size	TODO (DimensionD instead of Dimension)
	 */
	public function FDLayoutNode(gm:LGraphManager,
		vNode:*,//vNode:Object,
		loc:PointD = null,
		size:DimensionD = null)
	{
		super(gm, vNode, loc, size);
		
		// init values
		
		springForceX = 0;
		springForceY = 0;
		repulsionForceX = 0;
		repulsionForceY = 0;
		gravitationForceX = 0;
		gravitationForceY = 0;
		
		displacementX = 0;
		displacementY = 0;
		
		startX = 0;
		finishX = 0;
		startY = 0;
		finishY = 0;
	}

// -----------------------------------------------------------------------------
// Section: FR-Grid Variant Repulsion Force Calculation
// -----------------------------------------------------------------------------
	/**
	 * This method sets start and finish grid coordinates
	 */
	public function setGridCoordinates(_startX:int, _finishX:int,
		_startY:int, _finishY:int):void
	{
		this.startX = _startX;
		this.finishX = _finishX;
		this.startY = _startY;
		this.finishY = _finishY;

	}

// -----------------------------------------------------------------------------
// Section: Remaining methods
// -----------------------------------------------------------------------------
	/*
	 * This method recalculates the displacement related attributes of this
	 * object. These attributes are calculated at each layout iteration once,
	 * for increasing the speed of the layout.
	 */
	public /*abstract*/ function move():void
	{
		throw new IllegalOperationError("abstract function must be overriden");
	}
}
}