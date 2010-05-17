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
    import flare.vis.data.EdgeSprite;
    
    import mx.utils.StringUtil;
    

    public class ArrowShapes {
        
        // ========[ CONSTANTS ]====================================================================
        
        public static const NONE:String = "NONE";
        public static const ARROW:String = "ARROW";
        public static const DELTA:String = "DELTA";
        public static const DIAMOND:String = "DIAMOND";
        public static const T:String = "T";
        public static const CIRCLE:String = "CIRCLE";
        
        // ========[ CONSTRUCTOR ]==================================================================
        
        /**
         * This constructor will throw an error, as this is an abstract class. 
         */
        public function ArrowShapes() {
            throw new Error("This is an abstract class.");
        }
        
        // ========[ PUBLIC METHODS ]===============================================================
        
        public static function getArrowStyle(e:EdgeSprite, shape:String, color:uint):Object {
            var style:Object = new Object();
            style.shape = shape;
            style.color =  0xffffff & color;
            style.alpha = e.lineAlpha;
            style.gap = 0;
            
            // DELTA or ARROW:
            
            style.width = Math.max(e.arrowWidth, e.arrowWidth * Math.sqrt(e.lineWidth));
            style.width = Math.max(style.width, 1.5 * e.lineWidth);
            
            style.height = 2 * style.width;

            switch (shape) {
                case CIRCLE:
                    style.width = style.height = style.height/2; // diameter
                    break;
                case DIAMOND:
                    style.width *= 2;
                    break;
                case T:
                    style.width += style.width / Math.sqrt(e.lineWidth);
                    style.gap = Math.max(2, style.height/4);
                    style.height = Math.max(1, style.gap/3);
                    break;
            }

            return style;
        }
        
        public static function isValid(shape:String):Boolean {
            if (shape != null) shape = StringUtil.trim(shape.toUpperCase());
            
            return shape == NONE ||
                   shape == DELTA ||
                   shape == ARROW ||
                   shape == DIAMOND ||
                   shape == T ||
                   shape == CIRCLE; 
        }
        
        public static function parse(shape:String):String {
            if (shape != null) shape = StringUtil.trim(shape.toUpperCase());

            switch (shape) {
                case "DELTA":
                case "TRIANGLE": return DELTA;
                case "ARROW":    return ARROW;
                case "DIAMOND":  return DIAMOND;
                case "T":        return T;
                case "CIRCLE":      
                case "ELLIPSE":  return CIRCLE;
                default:         return NONE;
            }
        }
    }
}