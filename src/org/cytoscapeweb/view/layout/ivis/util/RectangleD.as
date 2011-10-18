package org.cytoscapeweb.view.layout.ivis.util
{
/**
 * This class implements a double-precision rectangle.
 *
 * @author Ugur Dogrusoz
 * @author Shatlyk Ashyralyev
 *
 * Copyright: i-Vis Research Group, Bilkent University, 2007 - present
 */
public class RectangleD
{
// -----------------------------------------------------------------------------
// Section: Instance variables
// -----------------------------------------------------------------------------
	/**
	 * Geometry of rectangle
	 */
	public var x:Number;
	public var y:Number;
	public var width:Number;
	public var height:Number;
	
// -----------------------------------------------------------------------------
// Section: Constructors and Initialization
// -----------------------------------------------------------------------------
	
	/**
	 * Constructor
	 */	
	public function RectangleD(x:Number = 0.0, y:Number = 0.0,
		width:Number = 0.0, height:Number = 0.0)
	{
		this.x = x;
		this.y = y;		
		this.height = height;
		this.width = width;
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

	public function getWidth():Number
	{
		return width;
	}

	public function setWidth(width:Number):void
	{
		this.width = width;
	}

	public function getHeight():Number
	{
		return height;
	}

	public function setHeight(height:Number):void
	{
		this.height = height;
	}
	
// -----------------------------------------------------------------------------
// Section: Remaining methods
// -----------------------------------------------------------------------------

	public function getRight():Number
	{
		return this.x + this.width;
	}
	
	public function getBottom():Number
	{
		return this.y + this.height;
	}
	
	public function intersects(a:RectangleD):Boolean
	{
		if (this.getRight() < a.x)
		{
			return false;
		}

		if (this.getBottom() < a.y)
		{
			return false;
		}

		if (a.getRight() < this.x)
		{
			return false;
		}

		if (a.getBottom() < this.y)
		{
			return false;
		}

		return true;
	}
	
	public function getCenterX():Number
	{
		return this.x + this.width / 2;
	}
	
	public function getCenterY():Number
	{
		return this.y + this.height / 2;
	}
	
	public function getWidthHalf():Number
	{
		return this.width / 2;
	}
	
	public function getHeightHalf():Number
	{
		return this.height / 2;
	}
}
}