package org.cytoscapeweb.view.layout.ivis.util
{
/*
import java.awt.geom.Line2D;
import java.awt.Point;
*/

/**
 * This class maintains a list of static geometry related utility methods.
 *
 * @author Ugur Dogrusoz
 * @author Esat Belviranli
 * @author Shatlyk Ashyralyev
 *
 * Copyright: i-Vis Research Group, Bilkent University, 2007 - present
 */
/*abstract*/ public class IGeometry
{
// -----------------------------------------------------------------------------
// Section: Class methods
// -----------------------------------------------------------------------------

	/**
	 * This method calculates the intersection in x and y directions of the two
	 * input rectangles, assuming they do instersect, and returns the result in
	 * the input array.
	 */
	public static function calcSmallerIntersection(rectA:RectangleD,
		rectB:RectangleD,
		overlapAmount:Array):void
	{
		overlapAmount[0] = Math.min(rectA.getRight(), rectB.getRight()) -
			Math.max(rectA.x, rectB.x);
		overlapAmount[1] = Math.min(rectA.getBottom(), rectB.getBottom()) -
			Math.max(rectA.y, rectB.y);
	}

	/**
	 * This method calculates the intersection (clipping) points of the two
	 * input rectangles with line segment defined by the centers of these two
	 * rectangles. The clipping points are saved in the input double array and
	 * whether or not the two rectangles overlap is returned.
	 */
	public static function getIntersection(rectA:RectangleD,
		rectB:RectangleD,
		result:Array):Boolean
	{
		//result[0-1] will contain clipPoint of rectA, result[2-3] will contain clipPoint of rectB

		var p1x:Number= rectA.getCenterX();
		var p1y:Number= rectA.getCenterY();		
		var p2x:Number= rectB.getCenterX();
		var p2y:Number= rectB.getCenterY();
		
		//if two rectangles intersect, then clipping points are centers
		if (rectA.intersects(rectB))
		{
			result[0] = p1x;
			result[1] = p1y;
			result[2] = p2x;
			result[3] = p2y;
			return true;
		}
		
		//variables for rectA
		var topLeftAx:Number= rectA.getX();
		var topLeftAy:Number= rectA.getY();
		var topRightAx:Number= rectA.getRight();
		var bottomLeftAx:Number= rectA.getX();
		var bottomLeftAy:Number= rectA.getBottom();
		var bottomRightAx:Number= rectA.getRight();
		var halfWidthA:Number= rectA.getWidthHalf();
		var halfHeightA:Number= rectA.getHeightHalf();
		
		//variables for rectB
		var topLeftBx:Number= rectB.getX();
		var topLeftBy:Number= rectB.getY();
		var topRightBx:Number= rectB.getRight();
		var bottomLeftBx:Number= rectB.getX();
		var bottomLeftBy:Number= rectB.getBottom();
		var bottomRightBx:Number= rectB.getRight();
		var halfWidthB:Number= rectB.getWidthHalf();
		var halfHeightB:Number= rectB.getHeightHalf();

		//flag whether clipping points are found
		var clipPointAFound:Boolean= false;
		var clipPointBFound:Boolean= false;
		

		// line is vertical
		if (p1x == p2x)
		{
			if(p1y > p2y)
			{
				result[0] = p1x;
				result[1] = topLeftAy;
				result[2] = p2x;
				result[3] = bottomLeftBy;
				return false;
			}
			else if(p1y < p2y)
			{
				result[0] = p1x;
				result[1] = bottomLeftAy;
				result[2] = p2x;
				result[3] = topLeftBy;
				return false;
			}
			else
			{
				//not line, return null;
			}
		}
		// line is horizontal
		else if (p1y == p2y)
		{
			if(p1x > p2x)
			{
				result[0] = topLeftAx;
				result[1] = p1y;
				result[2] = topRightBx;
				result[3] = p2y;
				return false;
			}
			else if(p1x < p2x)
			{
				result[0] = topRightAx;
				result[1] = p1y;
				result[2] = topLeftBx;
				result[3] = p2y;
				return false;
			}
			else
			{
				//not valid line, return null;
			}
		}
		else
		{
			//slopes of rectA's and rectB's diagonals
			var slopeA:Number= rectA.height / rectA.width;
			var slopeB:Number= rectB.height / rectB.width;
			
			//slope of line between center of rectA and center of rectB
			var slopePrime:Number= (p2y - p1y) / (p2x - p1x);
			var cardinalDirectionA:int;
			var cardinalDirectionB:int;
			var tempPointAx:Number;
			var tempPointAy:Number;
			var tempPointBx:Number;
			var tempPointBy:Number;
			
			//determine whether clipping point is the corner of nodeA
			if((-slopeA) == slopePrime)
			{
				if(p1x > p2x)
				{
					result[0] = bottomLeftAx;
					result[1] = bottomLeftAy;
					clipPointAFound = true;
				}
				else
				{
					result[0] = topRightAx;
					result[1] = topLeftAy;
					clipPointAFound = true;
				}
			}
			else if(slopeA == slopePrime)
			{
				if(p1x > p2x)
				{
					result[0] = topLeftAx;
					result[1] = topLeftAy;
					clipPointAFound = true;
				}
				else
				{
					result[0] = bottomRightAx;
					result[1] = bottomLeftAy;
					clipPointAFound = true;
				}
			}
			
			//determine whether clipping point is the corner of nodeB
			if((-slopeB) == slopePrime)
			{
				if(p2x > p1x)
				{
					result[2] = bottomLeftBx;
					result[3] = bottomLeftBy;
					clipPointBFound = true;
				}
				else
				{
					result[2] = topRightBx;
					result[3] = topLeftBy;
					clipPointBFound = true;
				}
			}
			else if(slopeB == slopePrime)
			{
				if(p2x > p1x)
				{
					result[2] = topLeftBx;
					result[3] = topLeftBy;
					clipPointBFound = true;
				}
				else
				{
					result[2] = bottomRightBx;
					result[3] = bottomLeftBy;
					clipPointBFound = true;
				}
			}
			
			//if both clipping points are corners
			if(clipPointAFound && clipPointBFound)
			{
				return false;
			}
			
			//determine Cardinal Direction of rectangles
			if(p1x > p2x)
			{
				if(p1y > p2y)
				{
					cardinalDirectionA = getCardinalDirection(slopeA, slopePrime, 4);
					cardinalDirectionB = getCardinalDirection(slopeB, slopePrime, 2);
				}
				else
				{
					cardinalDirectionA = getCardinalDirection(-slopeA, slopePrime, 3);
					cardinalDirectionB = getCardinalDirection(-slopeB, slopePrime, 1);
				}
			}
			else
			{
				if(p1y > p2y)
				{
					cardinalDirectionA = getCardinalDirection(-slopeA, slopePrime, 1);
					cardinalDirectionB = getCardinalDirection(-slopeB, slopePrime, 3);
				}
				else
				{
					cardinalDirectionA = getCardinalDirection(slopeA, slopePrime, 2);
					cardinalDirectionB = getCardinalDirection(slopeB, slopePrime, 4);
				}
			}
			//calculate clipping Point if it is not found before
			if(!clipPointAFound)
			{
				switch(cardinalDirectionA)
				{
					case 1:
						tempPointAy = topLeftAy;
						tempPointAx = p1x + ( -halfHeightA ) / slopePrime;
						result[0] = tempPointAx;
						result[1] = tempPointAy;
						break;
					case 2:
						tempPointAx = bottomRightAx;
						tempPointAy = p1y + halfWidthA * slopePrime;
						result[0] = tempPointAx;
						result[1] = tempPointAy;
						break;
					case 3:
						tempPointAy = bottomLeftAy;
						tempPointAx = p1x + halfHeightA / slopePrime;
						result[0] = tempPointAx;
						result[1] = tempPointAy;
						break;
					case 4:
						tempPointAx = bottomLeftAx;
						tempPointAy = p1y + ( -halfWidthA ) * slopePrime;
						result[0] = tempPointAx;
						result[1] = tempPointAy;
						break;
				}
			}
			if(!clipPointBFound)
			{
				switch(cardinalDirectionB)
				{
					case 1:
						tempPointBy = topLeftBy;
						tempPointBx = p2x + ( -halfHeightB ) / slopePrime;
						result[2] = tempPointBx;
						result[3] = tempPointBy;
						break;
					case 2:
						tempPointBx = bottomRightBx;
						tempPointBy = p2y + halfWidthB * slopePrime;
						result[2] = tempPointBx;
						result[3] = tempPointBy;
						break;
					case 3:
						tempPointBy = bottomLeftBy;
						tempPointBx = p2x + halfHeightB / slopePrime;
						result[2] = tempPointBx;
						result[3] = tempPointBy;
						break;
					case 4:
						tempPointBx = bottomLeftBx;
						tempPointBy = p2y + ( -halfWidthB ) * slopePrime;
						result[2] = tempPointBx;
						result[3] = tempPointBy;
						break;
				}
			}
			
		}
		
		return false;
	}
	
	/**
	 * This method returns in which cardinal direction does input point stays
	 * 1: North
	 * 2: East
	 * 3: South
	 * 4: West
	 */
	private static function getCardinalDirection(slope:Number,
		slopePrime:Number,
		line:int):int
	{
		if (slope > slopePrime)
		{
			return line;
		}
		else
		{
			return 1+ line % 4;
		}
	}
	
	/**
	 * This method calculates the intersection of the two lines defined by
	 * point pairs (s1,s2) and (f1,f2).
	 */
	public static function getLineIntersection(s1:PointD, s2:PointD,
		f1:PointD, f2:PointD):PointD
	{
		var x1:int= s1.x;
		var y1:int= s1.y;
		var x2:int= s2.x;
		var y2:int= s2.y;
		var x3:int= f1.x;
		var y3:int= f1.y;
		var x4:int= f2.x;
		var y4:int= f2.y;

		var x:int, y:int; // intersection point

		var a1:int, a2:int, b1:int, b2:int, c1:int, c2:int; // coefficients of line eqns.

		var denom:int;

		a1 = y2 - y1;
		b1 = x1 - x2;
		c1 = x2 * y1 - x1 * y2;  // { a1*x + b1*y + c1 = 0 is line 1 }

		a2 = y4 - y3;
		b2 = x3 - x4;
		c2 = x4 * y3 - x3 * y4;  // { a2*x + b2*y + c2 = 0 is line 2 }

		denom = a1 * b2 - a2 * b1;

		if (denom == 0)
		{
			return null;
		}

		x = (b1 * c2 - b2 * c1) / denom;
		y = (a2 * c1 - a1 * c2) / denom;

		return new PointD(x, y);
	}

	/**
	 * This method finds and returns the angle of the vector from the + x-axis
	 * in clockwise direction (compatible w/ Java coordinate system!).
	 */
	public static function angleOfVector(Cx:Number, Cy:Number,
		Nx:Number, Ny:Number):Number
	{
		var C_angle:Number;

		if (Cx != Nx)
		{
			C_angle = Math.atan((Ny - Cy) / (Nx - Cx));

			if (Nx < Cx)
			{
				C_angle += Math.PI;
			}
			else if (Ny < Cy)
			{
				C_angle += TWO_PI;
			}
		}
		else if (Ny < Cy)
		{
			C_angle = ONE_AND_HALF_PI; // 270 degrees
		}
		else
		{
			C_angle = HALF_PI; // 90 degrees
		}

//		assert 0.0 <= C_angle && C_angle < TWO_PI;

		return C_angle;
	}

	/**
	 * This method converts the given angle in radians to degrees.
	 */
	public static function radian2degree(rad:Number):Number
	{
		return 180.0* rad / Math.PI;
	}

	/**
	 * This method checks whether the given two line segments (one with point
	 * p1 and p2, the other with point p3 and p4) intersect at a point other
	 * than these points.
	 */
	public static function doIntersect(p1:PointD, p2:PointD,
		p3:PointD, p4:PointD):Boolean
	{
		/* TODO find a method for linesIntersect
		var result:Boolean = Line2D.linesIntersect(p1.x, p1.y,
			p2.x, p2.y, p3.x, p3.y,
			p4.x, p4.y);

		*/
		var result:Boolean = false;
		
		return result;
	}

	private static function testClippingPoints():void
	{
		var rectA:RectangleD= new RectangleD(5, 6, 2, 4);
		var rectB:RectangleD;
		
		rectB = new RectangleD(0, 4, 1, 4);
		findAndPrintClipPoints(rectA, rectB);
		
		rectB = new RectangleD(1, 4, 1, 2);
		findAndPrintClipPoints(rectA, rectB);
	
		rectB = new RectangleD(1, 3, 3, 2);
		findAndPrintClipPoints(rectA, rectB);
//----------------------------------------------		
		rectB = new RectangleD(2, 3, 2, 4);
		findAndPrintClipPoints(rectA, rectB);
		
		rectB = new RectangleD(3, 3, 2, 2);
		findAndPrintClipPoints(rectA, rectB);
		
		rectB = new RectangleD(3, 2, 4, 2);
		findAndPrintClipPoints(rectA, rectB);
//----------------------------------------------		
		rectB = new RectangleD(6, 3, 2, 2);
		findAndPrintClipPoints(rectA, rectB);
//----------------------------------------------		
		rectB = new RectangleD(9, 2, 4, 2);
		findAndPrintClipPoints(rectA, rectB);
		
		rectB = new RectangleD(9, 3, 2, 2);
		findAndPrintClipPoints(rectA, rectB);
		
		rectB = new RectangleD(8, 3, 2, 4);
		findAndPrintClipPoints(rectA, rectB);
//----------------------------------------------
		rectB = new RectangleD(11, 3, 3, 2);
		findAndPrintClipPoints(rectA, rectB);
		
		rectB = new RectangleD(11, 4, 1, 2);
		findAndPrintClipPoints(rectA, rectB);
		
		rectB = new RectangleD(10, 4, 1, 4);
		findAndPrintClipPoints(rectA, rectB);
//----------------------------------------------
		rectB = new RectangleD(10, 5, 2, 2);
		findAndPrintClipPoints(rectA, rectB);
		
		rectB = new RectangleD(9, 4.5, 2, 4);
		findAndPrintClipPoints(rectA, rectB);
		
		rectB = new RectangleD(10, 5.8, 0.4, 2);
		findAndPrintClipPoints(rectA, rectB);
//----------------------------------------------		
		rectB = new RectangleD(11, 6, 2, 2);
		findAndPrintClipPoints(rectA, rectB);
//----------------------------------------------
		rectB = new RectangleD(10, 7.8, 0.4, 2);
		findAndPrintClipPoints(rectA, rectB);
		
		rectB = new RectangleD(9, 7.5, 1, 4);
		findAndPrintClipPoints(rectA, rectB);
		
		rectB = new RectangleD(10, 7, 2, 2);
		findAndPrintClipPoints(rectA, rectB);
//----------------------------------------------
		rectB = new RectangleD(10, 9, 2, 6);
		findAndPrintClipPoints(rectA, rectB);
		
		rectB = new RectangleD(11, 9, 2, 4);
		findAndPrintClipPoints(rectA, rectB);
		
		rectB = new RectangleD(12, 8, 4, 2);
		findAndPrintClipPoints(rectA, rectB);
//----------------------------------------------
		rectB = new RectangleD(7, 9, 2, 4);
		findAndPrintClipPoints(rectA, rectB);
		
		rectB = new RectangleD(8, 9, 4, 2);
		findAndPrintClipPoints(rectA, rectB);
		
		rectB = new RectangleD(10, 9, 2, 2);
		findAndPrintClipPoints(rectA, rectB);
//----------------------------------------------
		rectB = new RectangleD(6, 10, 2, 2);
		findAndPrintClipPoints(rectA, rectB);
//----------------------------------------------
		rectB = new RectangleD(3, 8, 4, 2);
		findAndPrintClipPoints(rectA, rectB);
		
		rectB = new RectangleD(3, 9, 2, 2);
		findAndPrintClipPoints(rectA, rectB);

		rectB = new RectangleD(2, 8, 4, 4);
		findAndPrintClipPoints(rectA, rectB);
//----------------------------------------------
		rectB = new RectangleD(2, 8, 2, 2);
		findAndPrintClipPoints(rectA, rectB);
		
		rectB = new RectangleD(1, 8, 2, 4);
		findAndPrintClipPoints(rectA, rectB);
	
		rectB = new RectangleD(1, 8.5, 1, 4);
		findAndPrintClipPoints(rectA, rectB);
//----------------------------------------------
		rectB = new RectangleD(3, 7, 2, 2);
		findAndPrintClipPoints(rectA, rectB);
		
		rectB = new RectangleD(1, 7.5, 1, 4);
		findAndPrintClipPoints(rectA, rectB);
		
		rectB = new RectangleD(3, 7.8, 0.4, 2);
		findAndPrintClipPoints(rectA, rectB);
//----------------------------------------------
		rectB = new RectangleD(1, 6, 2, 2);
		findAndPrintClipPoints(rectA, rectB);
//----------------------------------------------		
		rectB = new RectangleD(3, 5.8, 0.4, 2);
		findAndPrintClipPoints(rectA, rectB);
		
		rectB = new RectangleD(1, 5, 1, 3);
		findAndPrintClipPoints(rectA, rectB);
		
		rectB = new RectangleD(1, 4, 3, 3);
		findAndPrintClipPoints(rectA, rectB);
//----------------------------------------------
		rectB = new RectangleD(4, 4, 3, 3);
//		findAndPrintClipPoints(rectA, rectB);
		
		rectB = new RectangleD(5, 6, 2, 4);
//		findAndPrintClipPoints(rectA, rectB);
	}
	
	private static function findAndPrintClipPoints(rectA:RectangleD,
		rectB:RectangleD):void
	{
		trace("---------------------");
		var clipPoints:Array = new Array(4); /*double[4];*/
		
		trace("RectangleA  X: " + rectA.x + "  Y: " + rectA.y + "  Width: " + rectA.width + "  Height: " + rectA.height);
		trace("RectangleB  X: " + rectB.x + "  Y: " + rectB.y + "  Width: " + rectB.width + "  Height: " + rectB.height);
		IGeometry.getIntersection(rectA, rectB, clipPoints);

		trace("Clip Point of RectA X:" + clipPoints[0] + " Y: " + clipPoints[1]);
		trace("Clip Point of RectB X:" + clipPoints[2] + " Y: " + clipPoints[3]);	
	}
	
	/*
	 * Main method for testing purposes.
	 */
	public static function main(args:Array):void
	{
		testClippingPoints();	
	}

// -----------------------------------------------------------------------------
// Section: Class Constants
// -----------------------------------------------------------------------------
	/**
	 * Some useful pre-calculated constants
	 */
	public static const HALF_PI:Number= 0.5* Math.PI;
	public static const ONE_AND_HALF_PI:Number= 1.5* Math.PI;
	public static const TWO_PI:Number= 2.0* Math.PI;
	public static const THREE_PI:Number= 3.0* Math.PI;
}
}