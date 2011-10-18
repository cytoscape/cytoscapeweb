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
    
    import flash.geom.Rectangle;
    
    import mx.utils.StringUtil;
    

    public class NodeShapes {
        
        // ========[ CONSTANTS ]====================================================================
        
        public static const ELLIPSE:String = "ELLIPSE";
        public static const RECTANGLE:String = "RECTANGLE";
        public static const DIAMOND:String = "DIAMOND";
        public static const TRIANGLE:String = "TRIANGLE";
        public static const HEXAGON:String = "HEXAGON";
        public static const OCTAGON:String = "OCTAGON";
        public static const PARALLELOGRAM:String = "PARALLELOGRAM";
        public static const ROUND_RECTANGLE:String = "ROUNDRECT";
        public static const V:String = "VEE";
        
        // ========[ CONSTRUCTOR ]==================================================================
        
        /**
         * This constructor will throw an error, as this is an abstract class. 
         */
        public function NodeShapes() {
            throw new Error("This is an abstract class.");
        }
        
        // ========[ PUBLIC METHODS ]===============================================================
        
        public static function getDrawPoints(bounds:Rectangle, shape:String):Array {
            var points:Array = [];
            var xR:Number = bounds.right, yB:Number = bounds.bottom;
            var xL:Number = bounds.left,  yT:Number = bounds.top;
            var w:Number = bounds.width;
            var h:Number = bounds.height;
            var w2:Number = w/2, h2:Number = h/2;
            var w3:Number = w/3, h3:Number = h/3;
            
            if (bounds != null) {
                switch (shape) {
                    case NodeShapes.ELLIPSE:
                        break;
                    case NodeShapes.TRIANGLE:
                        points = [ xL,    yB,
                                   xL+w2, yT,
                                   xR,    yB ];
                        break;
                    case NodeShapes.DIAMOND:
                        points = [ xL,    yT+h2,
                                   xL+w2, yT,
                                   xR,    yT+h2,
                                   xL+w2, yB ];
                        break;
                    case NodeShapes.HEXAGON:
                        points = [ xL,    yT+h2,
                                   xL+w3, yT,
                                   xR-w3, yT,
                                   xR,    yT+h2,
                                   xR-w3, yB,
                                   xL+w3, yB ];
                        break;
                    case NodeShapes.OCTAGON:
                        points = [ xL,    yB-h3,
                                   xL,    yT+h3,
                                   xL+w3, yT,
                                   xR-w3, yT,
                                   xR,   yT+h3,
                                   xR,   yB-h3,
                                   xR-w3, yB,
                                   xL+w3, yB ];
                        break;
                    case NodeShapes.PARALLELOGRAM:
                        points = [ xL,    yT,
                                   xR-w3, yT,
                                   xR,    yB,
                                   xL+w3, yB ];
                        break;
                    case NodeShapes.ROUND_RECTANGLE:
                        var h4:Number = getRoundRectCornerRadius(w, h);
                        var w4:Number = h4;
                        // The round corners are not included:
                        points = [ xL,    yB-h4,
                                   xL,    yT+h4,
                                   xL+w4, yT,
                                   xR-w4, yT,
                                   xR,    yT+h4,
                                   xR,    yB-h4,
                                   xR-w4, yB,
                                   xL+w4, yB ];
                        break;
                    case NodeShapes.V:
                        points = [ xL,    yT,
                                   xL+w2, yT+h3,
                                   xR,    yT,
                                   xL+w2, yB ]
                        break;
                    case NodeShapes.RECTANGLE:
                    default:
                        points = [ xL, yT,
                                   xR, yT,
                                   xR, yB,
                                   xL, yB ];
                }
            }
            
            return points;
        }
        
        public static function getRoundRectCornerRadius(width:Number, height:Number):Number {
            return Math.min(width, height)/8;
        }
        
        public static function isValid(shape:String):Boolean {
            if (shape != null) shape = StringUtil.trim(shape.toUpperCase());
            
            return shape === ELLIPSE ||
                   shape === RECTANGLE ||
                   shape === DIAMOND ||
                   shape === TRIANGLE ||
                   shape === HEXAGON ||
                   shape === OCTAGON ||
                   shape === PARALLELOGRAM ||
                   shape === ROUND_RECTANGLE ||
                   shape === V;
        }
        
        public static function parse(shape:String):String {
            if (shape != null) shape = StringUtil.trim(shape.toUpperCase());
            
            switch (shape) {
                case "DIAMOND":           return DIAMOND;
                case "HEXAGON":           return HEXAGON;
                case "OCTAGON":           return OCTAGON;
                case "SQUARE":
                case "BOX":
                case "RECT":
                case "RECTANGLE":         return RECTANGLE;
                case "ROUNDRECT":
                case "ROUND_RECT":
                case "ROUND_RECTANGLE":
                case "ROUNDED_RECTANGLE": return ROUND_RECTANGLE;
                case "TRIANGLE":          return TRIANGLE;
                case "RHOMBUS":
                case "PARALLELOGRAM":     return PARALLELOGRAM;
                case "V":
                case "VEE":               return V;
                default:                  return ELLIPSE;
            }
        }
        
        // ========[ PRIVATE METHODS ]==============================================================

    }
}