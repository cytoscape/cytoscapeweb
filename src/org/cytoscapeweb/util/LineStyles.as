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
    
    import flash.display.CapsStyle;
    
    import mx.utils.StringUtil;
    

    public class LineStyles {
        
        // ========[ CONSTANTS ]====================================================================
        
        public static const SOLID:String = "SOLID";
        public static const DOT:String = "DOT";
        public static const LONG_DASH:String = "LONG_DASH";
        public static const EQUAL_DASH:String = "EQUAL_DASH";
        
        // ========[ CONSTRUCTOR ]==================================================================
        
        /**
         * This constructor will throw an error, as this is an abstract class. 
         */
        public function LineStyles() {
            throw new Error("This is an abstract class.");
        }
        
        // ========[ PUBLIC METHODS ]===============================================================
        
        public static function getOnLength(e:EdgeSprite, lineStyle:String, scale:Number=1):Number {
            var w:Number = e.lineWidth;

            switch (lineStyle) {
                case DOT:       return 0.5;
                case LONG_DASH: return 4 * w * scale;
                case EQUAL_DASH:
                default:        return 2 * w * scale;
            }
        }
        
        public static function getOffLength(e:EdgeSprite, lineStyle:String, scale:Number=1):Number {
            var w:Number = e.lineWidth;
            return 2 * w * scale;
        }
        
        public static function getCaps(lineStyle:String):String {
            switch (lineStyle) {
                case LONG_DASH:
                case EQUAL_DASH: return CapsStyle.NONE;
                case DOT:
                default:         return CapsStyle.ROUND;
            }
        }
        
        public static function isValid(shape:String):Boolean {
            if (shape != null) shape = StringUtil.trim(shape.toUpperCase());
            
            return shape == SOLID ||
                   shape == DOT ||
                   shape == LONG_DASH ||
                   shape == EQUAL_DASH; 
        }
        
        public static function parse(shape:String):String {
            if (shape != null) shape = StringUtil.trim(shape.toUpperCase());

            switch (shape) {
                case "DOT":        return DOT;
                case "DASH_DOT":
                case "LONG_DASH":  return LONG_DASH;
                case "EQUAL_DASH": return EQUAL_DASH;
                default:           return SOLID;
            }
        }
    }
}