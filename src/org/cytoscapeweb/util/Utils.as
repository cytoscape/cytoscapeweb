/*
  This file is part of Cytoscape Web.
  Copyright (c) 2009, The Cytoscape Consortium (www.cytoscape.org)

  The Cytoscape Consortium is:
    - Agilent Technologies
    - Institut Pasteur
    - Institute for Systems Biology
    - Memorial Sloan-Kettering Cancer Center
    - National Center for Integrative Biomedical Informatics
    - Unilever
    - University of California San Diego
    - University of California San Francisco
    - University of Toronto

  This library is free software; you can redistribute it and/or
  modify it under the terms of the GNU Lesser General Public
  License as published by the Free Software Foundation; either
  version 2.1 of the License, or (at your option) any later version.

  This library is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
  Lesser General Public License for more details.

  You should have received a copy of the GNU Lesser General Public
  License along with this library; if not, write to the Free Software
  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
*/
package org.cytoscapeweb.util {
	import flare.util.Colors;
	
	import flash.geom.Point;
	import flash.system.Capabilities;
	import flash.utils.ByteArray;
	
	import mx.utils.StringUtil;
	
	
	public class Utils {

        // ========[ CONSTRUCTOR ]==================================================================
        
        /**
         * This constructor will throw an error, as this is an abstract class. 
         */
        public function Utils() {
             throw new Error("This is an abstract class.");
        }

        // ========[ PUBLIC METHODS ]===============================================================

		/**
		 * Convert a RGB color from number to the hexadecimal string code.
		 * @param the color as integer - e.g. 0xf5f5f5;
		 * @return the RGB color as String - e.g. "f5f5f5".
		 */
        public static function rgbColorAsString(color:uint):String {
        	// First, remove the alpha from the color:
        	if (color > 0xffffff) color -= 0xff000000;
        	
    	    // Get the RGB color as String:
            var r:String = Colors.r(color).toString(16);
            if (r.length < 2) r = "0" + r;
            var g:String = Colors.g(color).toString(16);
            if (g.length < 2) g = "0" + g;
            var b:String = Colors.b(color).toString(16);
            if (b.length < 2) b = "0" + b;
            
            return "#"+r+g+b;
        }
        
		/**
		 * @param the color as string - e.g. "#f5f5f5" or just "f5f5f5";
		 * @return the RGB color as uint - e.g. 0xf5f5f5.
		 */
        public static function rgbColorAsUint(color:String):uint {
            if (color == null) color = "0";
            color = StringUtil.trim(color).replace("#", "");
            return uint("0x"+color);
        }
        
        /**
         *  
         */
        public static function format(text:String, data:Object):String {
            if (text != null && StringUtil.trim(text) != "") {
                const DELIMITER:* = /\${.*}/;
                var idx:int = 0;

                while ((idx = text.search(DELIMITER)) != -1) {
                    var tag:String = text.substring(idx, text.indexOf("}", idx)+1);
                    var attr:String = StringUtil.trim(tag.substring(2, tag.length-1));
                    var value:* = data[attr];
                    text = text.replace(tag, value);
                }
            }
            
            return text;
        }

        /**
         * Returns the orthogonal point of an Isosceles triangle that has its base defined
         * by the line from p1 to p2 and "h" as its height.
         */
        public static function orthogonalPoint(h:Number, p1:Point, p2:Point):Point {
            var diff:Point = new Point(p1.x-p2.x, p1.y-p2.y);
            var normal:Point = new Point(diff.y, -diff.x);
            normal.normalize(1);
            var mid:Point = new Point((p1.x + p2.x)/2, (p1.y + p2.y)/2);
            
            return new Point(mid.x + normal.x * h, mid.y + normal.y * h);
        }
        
        /**
         * Converts a quadratic bezier curve to a cubic one.
         * 
         * @param a the starting point of the curve
         * @param b the control point of the quadratic bezier
         * @param c the ending point of the curve
         * @param d1 point in which to store the first control point of the cubic bezier
         * @param d2 point in which to store the second control point of the cubic bezier
         */
        public static function quadraticToCubic(a:Point, b:Point, c:Point, d1:Point, d2:Point):void {         
			// if:   quadratic bezier = (x1, y1), (x2,y2), (x3, y3)
			// then: cubic bezier     = (x1, y1), (x1 + 2/3 (x2 - x1) , y1 + 2/3 (y2 - y1)), (x2 + 1/3 (x3 - x2) , y2 + 1/3 (y3 - y2))(x3,y3)
            d1.x = (a.x + 2/3*(b.x - a.x));
            d1.y = (a.y + 2/3*(b.y - a.y));
            d2.x = (b.x + 1/3*(c.x - b.x));
            d2.y = (b.y + 1/3*(c.y - b.y));
            
        }
      
        /**
         * Code found here:
         * http://www.actionscript.org/forums/showpost.php3?p=794474&postcount=4
         * 
         * Determines a new color between two given colors.
         * 
         * @param fromColor The first color.
         * @param toColor The second color.
         * @param progress The amount between the two colors to generate
         *        the new color where 0 is equal to fromColor and 1 equal to toColor.
         * @return  The color between fromColor and toColor based on progress.
         */
        public static function interpolateColor(fromColor:uint, toColor:uint, progress:Number):uint {
            var q:Number = 1-progress;
            var fromA:uint = (fromColor >> 24) & 0xFF;
            var fromR:uint = (fromColor >> 16) & 0xFF;
            var fromG:uint = (fromColor >>  8) & 0xFF;
            var fromB:uint =  fromColor        & 0xFF;
            var toA:uint = (toColor >> 24) & 0xFF;
            var toR:uint = (toColor >> 16) & 0xFF;
            var toG:uint = (toColor >>  8) & 0xFF;
            var toB:uint =  toColor        & 0xFF;
            
            var resultA:uint = fromA*q + toA*progress;
            var resultR:uint = fromR*q + toR*progress;
            var resultG:uint = fromG*q + toG*progress;
            var resultB:uint = fromB*q + toB*progress;
            
            var resultColor:uint = resultA << 24 | resultR << 16 | resultG << 8 | resultB;
            
            return resultColor;
        }
        
        public static function clone(obj:Object):Object {
            var result:Object = null;
            
            if (obj != null) {
                var buffer:ByteArray = new ByteArray();
                buffer.writeObject(obj);
                buffer.position = 0;
                result = buffer.readObject();
            }
            
            return result;
        }
        
        /**
         * Code found here:
         * http://keith-hair.net/blog/2008/08/05/line-to-circle-intersection-data/
         * 
         * @param A The start point of the line.
         * @param B The end point of the line.
         * @param C The center of the circle.
         * @param r The radius of the circle.
         * @return An Object with the following properties:
         *   enter       -Intersection Point entering the circle.
         *   exit        -Intersection Point exiting the circle.
         *   inside      -Boolean indicating if the points of the line are inside the circle.
         *   tangent     -Boolean indicating if line intersect at one point of the circle.
         *   intersects  -Boolean indicating if there is an intersection of the points and the circle.
         *
         * If both "enter" and "exit" are null, or "intersects" == false, it indicates there is no intersection.
         * This is a customization of the intersectCircleLine Javascript function found here:
         * http://www.kevlindev.com/gui/index.htm
         */
        public static function lineIntersectCircle(A:Point, B:Point, C:Point, r:Number=1):Object {
            var result:Object = { inside: false, tangent: false, intersects: false,
                                  enter: null, exit: null }

            var a:Number = (B.x - A.x) * (B.x - A.x) + (B.y - A.y) * (B.y - A.y);
            var b:Number = 2 * ((B.x - A.x) * (A.x - C.x) +(B.y - A.y) * (A.y - C.y));
            var cc:Number = C.x * C.x + C.y * C.y + A.x * A.x + A.y * A.y - 2 * (C.x * A.x + C.y * A.y) - r * r;
            var deter:Number = b * b - 4 * a * cc;
            
            if (deter > 0 ) {
                var e:Number = Math.sqrt(deter);
                var u1:Number = (-b + e) / (2 * a);
                var u2:Number = (-b - e) / (2 * a);
                if ((u1 < 0 || u1 > 1) && (u2 < 0 || u2 > 1)) {
                    if ((u1 < 0 && u2 < 0) || (u1 > 1 && u2 > 1))
                        result.inside = false;
                    else
                        result.inside = true;
                } else {
                    if (0 <= u2 && u2 <= 1)
                        result.enter = Point.interpolate (A, B, 1 - u2);
                    if (0 <= u1 && u1 <= 1)
                        result.exit = Point.interpolate (A, B, 1 - u1);

                    result.intersects = true;
                    
                    if (result.exit != null && result.enter != null && result.exit.equals (result.enter)) {
                        result.tangent = true;
                    }
                }
            }
            
            return result;
        }
        
        /**
         * Calculates a point along a quadratic bezier curve.
         * 
         * @param a The start point of the curve.
         * @param b The end point.
         * @param c The control point of the bezier.
         * @param t the interpolation fraction along the curve (between 0 and 1)
         */
        public static function bezierPoint(a:Point, b:Point, c:Point, t:Number):Point {
            var x:Number = bezierPos(a.x, b.x, c.x, t);
            var y:Number = bezierPos(a.y, b.y, c.y, t);
            return new Point(x, y);
        }
        
        public static function bezierPos(a:Number, b:Number, c:Number, t:Number):Number {
            return a*(1-t)*(1-t) + 2*c*(1-t)*t + b*t*t;
        }

        public static function isLinux():Boolean {
            return Capabilities.os.toLowerCase().indexOf("linux") != -1;
        }
    }
}