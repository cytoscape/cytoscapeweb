package org.cytoscapeweb.view.layout.ivis.util
{
/**
 * This class implements a double-precision point.
 *
 * @author Ugur Dogrusoz
 * @author Onur Sumer
 *
 * Copyright: i-Vis Research Group, Bilkent University, 2007 - present
 */
public class PointD
{
// -----------------------------------------------------------------------------
// Section: Instance variables
// -----------------------------------------------------------------------------
	/**
	 * Geometry of point
	 */
	public var x:Number;
	public var y:Number;

// -----------------------------------------------------------------------------
// Section: Constructors and Initialization
// -----------------------------------------------------------------------------
	/**
	 * Constructor
	 */	
	public function PointD(x:Number = 0.0, y:Number = 0.0)
	{
		this.x = x;
		this.y = y;		
	}

// -----------------------------------------------------------------------------
// Section: Accessors
// -----------------------------------------------------------------------------
	public function getX():Number
	{
		return x;
	}

	public function setX(x:Number):void
	{
		this.x = x;
	}

	public function getY():Number
	{
		return y;
	}

	public function setY(y:Number):void
	{
		this.y = y;
	}

	
// -----------------------------------------------------------------------------
// Section: Remaining methods
// -----------------------------------------------------------------------------
	public function getDifference(pt:PointD):DimensionD
	{
		return new DimensionD(this.x - pt.x, this.y - pt.y);
	}

	public function getCopy():PointD
	{
		return new PointD(this.x, this.y);
	}

	public function translate(dim:DimensionD):PointD
	{
		this.x += dim.width;
		this.y += dim.height;
		
		return this;
	}
	
	
}
}