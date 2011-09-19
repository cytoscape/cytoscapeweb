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
	import flare.data.DataUtil;
	import flare.util.Colors;
	
	import flash.geom.Point;
	import flash.system.Capabilities;
	import flash.utils.ByteArray;
	
	import mx.utils.StringUtil;
	
	
	public class Utils {

        // ========[ CONSTANTS ]====================================================================

        private static const _COLORS:Object = {
            maroon:  "#800000",
            red:     "#ff0000",
            orange:  "#ffA500",
            yellow:  "#ffff00",
            olive:   "#808000",
            purple:  "#800080",
            fuchsia: "#ff00ff",
            white:   "#ffffff",
            lime:    "#00ff00",
            green:   "#008000",
            navy:    "#000080",
            blue:    "#0000ff",
            aqua:    "#00ffff",
            teal:    "#008080",
            black:   "#000000",
            silver:  "#c0c0c0",
            gray:    "#808080"
        };

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
		 * @param the color as string - e.g. "#f5f5f5", "f5f5f5", "rgb(255,255,255)" or even "#fa0"
		 * @return the RGB color as uint - e.g. 0xf5f5f5.
		 */
        public static function rgbColorAsUint(color:String):uint {
            color = StringUtil.trim(""+color).toLowerCase();
            
            // Is is a keywork (e.g. "white")?
            var key:String = color;
            color = _COLORS[key];
            if (color == null) color = key; // Not a keyword!
            
            if (color == null) {
                color = "0";
            } else if (color.search(/rgb\(\s*\d+?\s*,\s*\d+?\s*,\s*\d+?\s*\)/i) === 0) { // e.g. rgb(255, 255, 255)
                // TODO: functional rgb with percent "rgb(100%,100%,100%)"
                color = color.replace(/rgb/i, "").replace("(", "").replace(")", "");
                var rgb:Array = color.split(",");
                
                if (rgb.length === 3) {
                    var c:uint = Colors.rgba( uint(StringUtil.trim(rgb[0])), 
                                              uint(StringUtil.trim(rgb[1])),
                                              uint(StringUtil.trim(rgb[2])) );
                    // Convert to hexadecimal format:
                    color = rgbColorAsString(c);
                } else {
                    color = "0";
                }
            }
            
            // Convert the hexadecimal format to a number:
            color = StringUtil.trim(color).replace("#", "");
            
            if (color.length === 3) { // Three-digit RGB notation?
                color = color.charAt(0) + color.charAt(0) + 
                        color.charAt(1) + color.charAt(1) + 
                        color.charAt(2) + color.charAt(2);
            }
            if (color.length !== 6) color = "0";

            
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
         * Adapted from: http://www.baconandgames.com/2010/02/22/intersection-of-an-ellipse-and-a-line-in-as3/
         * @param p1 The start point of the line.
         * @param p2 The end point of the line.
         * @param ep: The ellipse position.
         * @param width: Width of the ellipse at its widest horizontal point.
         * @param height: Height of the ellipse at its tallest point.
         * @return The intersection point. Returns null if there is no intersection.
         */
        public static function lineIntersectEllipse(p1:Point, p2:Point, ep:Point, width:Number, height:Number):Point {
            var arr:Array = [];
            
            var sort:Boolean=false;
            
            var a:Number = width/2; // radius x
            var b:Number = height/2; // radius y
            
            var x:Number = ep.x; // horizontal position of the ellipse.
            var y:Number = ep.y; // vertical position of the ellipse
            var center:Point = new Point(x+a, y+b);
            
             // normailze points (ie, make everything relative to (0,0))
            var p1Norm:Point = new Point(p1.x-center.x,-(p1.y-center.y));
            var p2Norm:Point = new Point(p2.x-center.x,-(p2.y-center.y));           
            // get the slope - y = mx+b
            var m:Number = (p2Norm.y-p1Norm.y)/(p2Norm.x-p1Norm.x);
            // get the slope intercept
            var si:Number = p2Norm.y-(m*p2Norm.x);
            // get the coefficients
            var A:Number = (b*b)+(a*a*m*m);
            var B:Number = 2*a*a*si*m;
            var C:Number = a*a*si*si-a*a*b*b; 
            // vars to hold the new points
            var p3:Point = new Point();
            var p4:Point = new Point();
            // we're going to use the quadratic equation to find x, so let's see what's going to be under the radicand first
            // depending on this value, we can potentially skip a few calculations
            var radicand:Number = (B*B)-(4*A*C);
            
            // returns true if pt is between anchor1 and anchor2
            var isBetweenPoints:Function = function(anchor1:Point, anchor2:Point, pt:Point):Boolean {
                var xMin:Number;
                var xMax:Number;
                var yMin:Number;
                var yMax:Number;
                // determine the x bounds
                if (anchor1.x < anchor2.x) {
                    xMin = anchor1.x;
                    xMax = anchor2.x;
                } else {
                    xMin = anchor2.x;
                    xMax = anchor1.x;
                }
                // determine the y bounds
                if (anchor1.y < anchor2.y) {
                    yMin = anchor1.y;
                    yMax = anchor2.y;
                } else {
                    yMin = anchor2.y;
                    yMax = anchor1.y;
                }
                // if between those values, point is between the anchors
                return (pt.x <= xMax && pt.x >= xMin && pt.y <= yMax && pt.y >= yMin) ? true : false;
            };
            
            var distanceBetweenPoints:Function = function(p1:Point, p2:Point):Number {
                var dx:Number = p2.x - p1.x, dy:Number = p2.y - p1.y;
                return Math.pow(dx * dx + dy * dy, .5);
            }

            if (radicand >= 0) {
                // solve for x values - using the quadratic equation
                p3.x = (-B-Math.sqrt(radicand))/(2*A);
                p4.x = (-B+Math.sqrt(radicand))/(2*A);
                // calculate y, since we know it's on the line at that point (otherwise there would be no intersection)
                p3.y = m*p3.x+si;
                p4.y = m*p4.x+si;               
                // revert to flash coordinate system
                p3.x += center.x;
                p3.y = -p3.y+center.y;
                p4.x += center.x;
                p4.y = -p4.y+center.y;
                
                // add to array of points   
                // only return points of the intersection that exist on the line between p1 and p2
                if (isBetweenPoints(p1,p2,p3)) arr.push(p3);
                if (isBetweenPoints(p1,p2,p4)) arr.push(p4);
             
                if (sort && arr.length > 1) {
                    // make sure that index 0 contains the closer point
                    if (distanceBetweenPoints(p1,arr[0]) > distanceBetweenPoints(p1,arr[1])) {
                        arr.reverse();
                    }
                }
            } else if (radicand == 0) {
                // in this case both points will result in the same, so we only need to calculate one point
                p3.x = (-B-Math.sqrt(radicand))/(2*A);  
                p3.y = m*p3.x+si;               
                // revert to flash coordinate system
                p3.x += center.x;
                p3.y = -p3.y+center.y;
                // add to array of points               
                if (isBetweenPoints(p1,p2,p3)) arr.push(p3);
            }
            
            return arr[0];
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
        
        /**
         * Simple linear interpolation between two points (see http://www.cubic.org/docs/bezier.htm).
         */
        public static function lerp(a:Point, b:Point, t:Number):Point {
            var p:Point = new Point();
            p.x = a.x + (b.x-a.x)*t;
            p.y = a.y + (b.y-a.y)*t;
            return p;
        }

        /**
         * Evaluate a point on a cubic bezier-curve. t goes from 0 to 1.0.
         * DeCasteljau Algorithm (see http://www.cubic.org/docs/bezier.htm).
         * 
         * @param a The start point of the curve.
         * @param b The first control point of the bezier.
         * @param c The second control point of the bezier.
         * @param d The end point.
         */
        public static function cubicBezierPoint(a:Point, b:Point, c:Point, d:Point, t:Number):Point {
            var ab:Point = lerp(a,b,t);
            var bc:Point = lerp(b, c, t);
            var cd:Point = lerp(c, d, t);
            var abbc:Point = lerp(ab, bc, t);
            var bccd:Point = lerp(bc, cd, t);
            var p:Point = lerp(abbc, bccd, t);
            return p;
        }

        public static function dataType(value:*):int {
            var type:int = DataUtil.OBJECT;
            if (value is Boolean)      type = DataUtil.BOOLEAN;
            else if (value is int)     type = DataUtil.INT;
            else if (value is Number)  type = DataUtil.NUMBER;
            else if (value is String)  type = DataUtil.STRING;
            
            return type;
        }

        public static function isLinux():Boolean {
            return Capabilities.os.toLowerCase().indexOf("linux") != -1;
        }
        
        public static function isMacOS():Boolean {
            return Capabilities.os.indexOf("Mac OS") != -1;
        }
    }
}