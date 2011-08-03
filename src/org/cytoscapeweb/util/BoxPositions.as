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
    import mx.utils.StringUtil;
    
    
    /**
     * Abstract utility class defining names of positions for boxes.
     */
    public class BoxPositions {
        
        // ========[ CONSTANTS ]====================================================================
        
        public static const TOP_LEFT:String = "topLeft";
        public static const TOP_CENTER:String = "topCenter";
        public static const TOP_RIGHT:String = "topRight";
        
        public static const MIDDLE_LEFT:String = "middleLeft";
        public static const MIDDLE_CENTER:String = "middleCenter";
        public static const MIDDLE_RIGHT:String = "middleRight";

        public static const BOTTOM_LEFT:String = "bottomLeft";
        public static const BOTTOM_CENTER:String = "bottomCenter";
        public static const BOTTOM_RIGHT:String = "bottomRight";
        
        // ========[ CONSTRUCTOR ]==================================================================
        
        /**
         * This constructor will throw an error, as this is an abstract class. 
         */
        public function BoxPositions() {
            throw new Error("This is an abstract class.");
        }
        
        // ========[ PUBLIC METHODS ]===============================================================

        public static function parse(s:String):String {
            if (s != null) s = StringUtil.trim(s.toLowerCase());

            switch (s) {
                case TOP_LEFT.toLowerCase():      return TOP_LEFT;
                case TOP_CENTER.toLowerCase():    return TOP_CENTER;
                case TOP_RIGHT.toLowerCase():     return TOP_RIGHT;
                case MIDDLE_LEFT.toLowerCase():   return MIDDLE_LEFT;
                case MIDDLE_CENTER.toLowerCase(): return MIDDLE_CENTER;
                case MIDDLE_RIGHT.toLowerCase():  return MIDDLE_RIGHT;
                case BOTTOM_LEFT.toLowerCase():   return BOTTOM_LEFT;
                case BOTTOM_CENTER.toLowerCase(): return BOTTOM_CENTER;
                case BOTTOM_RIGHT.toLowerCase():
                default:                          return BOTTOM_RIGHT;
            }
        }
        
        // ========[ PRIVATE METHODS ]==============================================================

    }
}
