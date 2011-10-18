package org.cytoscapeweb.view.layout.ivis.util
{
/**
 * This class implements a double-precision dimension.
 *
 * @author Ugur Dogrusoz
 *
 * Copyright: i-Vis Research Group, Bilkent University, 2007 - present
 */
public class DimensionD
{
// -----------------------------------------------------------------------------
// Section: Instance variables
// -----------------------------------------------------------------------------
	/**
	 * Geometry of dimension
	 */
	public var width:Number;
	public var height:Number;

// -----------------------------------------------------------------------------
// Section: Constructors and Initialization
// -----------------------------------------------------------------------------
	
	/**
	 * Constructor
	 */
	public function DimensionD(width:Number = 0.0, height:Number = 0.0)
	{
		this.height = height;
		this.width = width;
	}

// -----------------------------------------------------------------------------
// Section: Accessors
// -----------------------------------------------------------------------------
	public function getWidth():Number {
		return width;
	}

	public function setWidth(width:Number):void {
		this.width = width;
	}

	public function getHeight():Number {
		return height;
	}

	public function setHeight(height:Number):void {
		this.height = height;
	}
}
}