package org.cytoscapeweb.view.layout.ivis.util
{
/**
 * This class is for transforming certain world coordinates to device ones.
 *  
 * Following example transformation translates (shifts) world coordinates by
 * (10,20), scales objects in the world to be twice as tall but half as wide
 * in device coordinates. In addition it flips the y coordinates.
 * 
 *			(wox,woy): world origin (x,y)
 *			(wex,wey): world extension x and y
 *			(dox,doy): device origin (x,y)
 *			(dex,dey): device extension x and y
 *
 *										(dox,doy)=(10,20)
 *											*--------- dex=50
 *											|
 *			 wey=50							|
 *				|							|
 *				|							|
 *				|							|
 *				*------------- wex=100		|
 *			(wox,woy)=(0,0)					dey=-100
 *
 * In most cases, we will set all values to 1.0 except dey=-1.0 to flip the y
 * axis.
 * 
 * @author Ugur Dogrusoz
 *
 * Copyright: i-Vis Research Group, Bilkent University, 2007 - present
 */
public class Transform
{
// ---------------------------------------------------------------------
// Section: Instance variables.
// ---------------------------------------------------------------------
	
	/* World origin and extension */
	private var lworldOrgX:Number;
	private var lworldOrgY:Number;
	private var lworldExtX:Number;
	private var lworldExtY:Number;

	/* Device origin and extension */
	private var ldeviceOrgX:Number;
	private var ldeviceOrgY:Number;
	private var ldeviceExtX:Number;
	private var ldeviceExtY:Number;

// ---------------------------------------------------------------------
// Section: Constructors and initialization.
// ---------------------------------------------------------------------

	/**
	 * Default constructor.
	 */
	public function Transform()
	{
		this.init();
	}

	/**
	 * This method initializes an object of this class.
	 */
	protected function init():void
	{
		lworldOrgX = 0.0;
		lworldOrgY = 0.0;
		ldeviceOrgX = 0.0;
		ldeviceOrgY = 0.0;
		lworldExtX = 1.0;
		lworldExtY = 1.0;
		ldeviceExtX = 1.0;
		ldeviceExtY = 1.0;
	}

// ---------------------------------------------------------------------
// Section: Get/set methods for instance variables.
// ---------------------------------------------------------------------
	
	/* World related */
	
	public function getWorldOrgX():Number {
		return this.lworldOrgX;
	}

	public function setWorldOrgX(wox:Number):void {
		this.lworldOrgX = wox;
	}
	
	public function getWorldOrgY():Number {
		return this.lworldOrgY;
	}

	public function setWorldOrgY(woy:Number):void {
		this.lworldOrgY = woy;
	}
	
	public function getWorldExtX():Number {
		return this.lworldExtX;
	}

	public function setWorldExtX(wex:Number):void {
		this.lworldExtX = wex;
	}
	
	public function getWorldExtY():Number {
		return this.lworldExtY;
	}

	public function setWorldExtY(wey:Number):void {
		this.lworldExtY = wey;
	}

	/* Device related */
	
	public function getDeviceOrgX():Number {
		return this.ldeviceOrgX;
	}

	public function setDeviceOrgX(dox:Number):void {
		this.ldeviceOrgX = dox;
	}
	
	public function getDeviceOrgY():Number {
		return this.ldeviceOrgY;
	}

	public function setDeviceOrgY(doy:Number):void {
		this.ldeviceOrgY = doy;
	}
	
	public function getDeviceExtX():Number {
		return this.ldeviceExtX;
	}

	public function setDeviceExtX(dex:Number):void {
		this.ldeviceExtX = dex;
	}
	
	public function getDeviceExtY():Number {
		return this.ldeviceExtY;
	}

	public function setDeviceExtY(dey:Number):void {
		this.ldeviceExtY = dey;
	}	

// ---------------------------------------------------------------------
// Section: x or y coordinate transformation
// ---------------------------------------------------------------------

	/**
	 * This method transforms an x position in world coordinates to an x
	 * position in device coordinates.
	 */
	public function transformX(x:Number):Number
	{
		var xDevice:Number;
		var worldExtX:Number= this.lworldExtX;

		if (worldExtX != 0.0)
		{
			xDevice = this.ldeviceOrgX +
				((x - this.lworldOrgX) * this.ldeviceExtX / worldExtX);
		}
		else
		{
			xDevice = 0.0;
		}

		return xDevice;
	}

	/**
	 * This method transforms a y position in world coordinates to a y
	 * position in device coordinates.
	 */
	public function transformY(y:Number):Number
	{
		var yDevice:Number;
		var worldExtY:Number= this.lworldExtY;

		if (worldExtY != 0.0)
		{
			yDevice = this.ldeviceOrgY +
				((y - this.lworldOrgY) * this.ldeviceExtY / worldExtY);
		}
		else
		{
			yDevice = 0.0;
		}

		return yDevice;
	}

	/**
	 * This method transforms an x position in device coordinates to an x
	 * position in world coordinates.
	 */
	public function inverseTransformX(x:Number):Number
	{
		var xWorld:Number;
		var deviceExtX:Number= this.ldeviceExtX;

		if (deviceExtX != 0.0)
		{
			xWorld = this.lworldOrgX +
				((x - this.ldeviceOrgX) * this.lworldExtX / deviceExtX);
		}
		else
		{
			xWorld = 0.0;
		}

		return xWorld;
	}

	/**
	 * This method transforms a y position in device coordinates to a y
	 * position in world coordinates.
	 */
	public function inverseTransformY(y:Number):Number
	{
		var yWorld:Number;
		var deviceExtY:Number= this.ldeviceExtY;

		if (deviceExtY != 0.0)
		{
			yWorld = this.lworldOrgY +
				((y - this.ldeviceOrgY) * this.lworldExtY / deviceExtY);
		}
		else
		{
			yWorld = 0.0;
		}

		return yWorld;
	}

// ---------------------------------------------------------------------
// Section: point, dimension and rectagle transformation
// ---------------------------------------------------------------------

	/**
	 * This method transforms the input point from the world coordinate system
	 * to the device coordinate system.
	 */
	public function transformPoint(inPoint:PointD):PointD
	{
		var outPoint:PointD=
			new PointD(this.transformX(inPoint.x),
				this.transformY(inPoint.y));
		
		return outPoint;
	}

	/**
	 * This method transforms the input dimension from the world coordinate 
	 * system to the device coordinate system.
	 */
	public function transformDimension(inDimension:DimensionD):DimensionD
	{
		var outDimension:DimensionD=
			new DimensionD(
				this.transformX(inDimension.width) -
					this.transformX(0.0),
				this.transformY(inDimension.height) -
					this.transformY(0.0));
		
		return outDimension;
	}

	/**
	 * This method transforms the input rectangle from the world coordinate
	 * system to the device coordinate system.
	 */
	public function transformRect(inRect:RectangleD):RectangleD
	{
		var outRect:RectangleD= new RectangleD();
		
		var inRectDim:DimensionD=
			new DimensionD(inRect.width, inRect.height);
		var outRectDim:DimensionD= this.transformDimension(inRectDim);
		outRect.setWidth(outRectDim.width);
		outRect.setHeight(outRectDim.height);
		
		outRect.setX(this.transformX(inRect.x));
		outRect.setY(this.transformY(inRect.y));
		
		return outRect;
	}

	/**
	 * This method transforms the input point from the device coordinate system
	 * to the world coordinate system.
	 */
	public function inverseTransformPoint(inPoint:PointD):PointD
	{
		var outPoint:PointD=
			new PointD(this.inverseTransformX(inPoint.x),
				this.inverseTransformY(inPoint.y));
		
		return outPoint;
	}

	/** 
	 * This method transforms the input dimension from the device coordinate 
	 * system to the world coordinate system.
	 */
	public function inverseTransformDimension(inDimension:DimensionD):DimensionD
	{ 
		var outDimension:DimensionD=
			new DimensionD(
				this.inverseTransformX(inDimension.width -
					this.inverseTransformX(0.0)),
				this.inverseTransformY(inDimension.height -
					this.inverseTransformY(0.0)));
		
		return outDimension;
	}

	/**
	 * This method transforms the input rectangle from the device coordinate
	 * system to the world coordinate system. The result is in the passed 
	 * output rectangle object.
	 */
	public function inverseTransformRect(inRect:RectangleD):RectangleD
	{
		var outRect:RectangleD= new RectangleD();
		
		var inRectDim:DimensionD=
			new DimensionD(inRect.width, inRect.height);
		var outRectDim:DimensionD=
			this.inverseTransformDimension(inRectDim);
		outRect.setWidth(outRectDim.width);
		outRect.setHeight(outRectDim.height);
		
		outRect.setX(this.inverseTransformX(inRect.x));
		outRect.setY(this.inverseTransformY(inRect.y));
		
		return outRect;
	}

// ---------------------------------------------------------------------
// Section: Remaining methods.
// ---------------------------------------------------------------------

	/**
	 * This method adjusts the world extensions of this transform object
	 * such that transformations based on this transform object will 
	 * preserve the aspect ratio of objects as much as possible.
	 */
	public function adjustExtToPreserveAspectRatio():void
	{
		var deviceExtX:Number= this.ldeviceExtX;
		var deviceExtY:Number= this.ldeviceExtY;

		if (deviceExtY != 0.0&&
			deviceExtX != 0.0)
		{
			var worldExtX:Number= this.lworldExtX;
			var worldExtY:Number= this.lworldExtY;

			if (deviceExtY * worldExtX < deviceExtX * worldExtY)
			{
				this.setWorldExtX((deviceExtY > 0.0) ?
					deviceExtX * worldExtY / deviceExtY :
					0.0);
			}
			else
			{
				this.setWorldExtY((deviceExtX > 0.0) ?
					deviceExtY * worldExtX / deviceExtX :
					0.0);
			}
		}
	}

	/**
	 * This method is for testing purposes only!
	 */
	public static function main(args:Array):void
	{
		var trans:Transform= new Transform();
		
		trans.setWorldOrgX(0.0);
		trans.setWorldOrgY(0.0);
		trans.setWorldExtX(100.0);
		trans.setWorldExtY(50.0);
		
		trans.setDeviceOrgX(10.0);
		trans.setDeviceOrgY(20.0);
		trans.setDeviceExtX(50.0);
		trans.setDeviceExtY(-100.0);
		
		var rectWorld:RectangleD= new RectangleD();
		
		rectWorld.x = 12.0;
		rectWorld.y = -25.0;
		rectWorld.width = 150.0;
		rectWorld.height = 150.0;

		var pointWorld:PointD=
			new PointD(rectWorld.x, rectWorld.y);
		var dimWorld:DimensionD=
			new DimensionD(rectWorld.width, rectWorld.height);
		
		var pointDevice:PointD= trans.transformPoint(pointWorld);
		var dimDevice:DimensionD= trans.transformDimension(dimWorld);
		var rectDevice:RectangleD= trans.transformRect(rectWorld);
		
		// The transformed location & dimension should be (16,70) & (75,-300)
	}
}
}