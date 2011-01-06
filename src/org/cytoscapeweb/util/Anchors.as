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
	import flare.display.TextSprite;
	
	import mx.utils.StringUtil;
	
	
    
    /**
     * Abstract utility class defining names of visual attributes.
     */
    public class Anchors {
        
        // ========[ CONSTANTS ]====================================================================
        
        // Vertical anchors
        public static const TOP:String = "top";
        public static const MIDDLE:String = "middle";
        public static const BOTTOM:String = "bottom";

        // Horizontal anchors
        public static const LEFT:String = "left";
        public static const CENTER:String = "center";
        public static const RIGHT:String = "right";
        
        // ========[ CONSTRUCTOR ]==================================================================
        
        /**
         * This constructor will throw an error, as this is an abstract class. 
         */
        public function Anchors() {
            throw new Error("This is an abstract class.");
        }
        
        // ========[ PUBLIC METHODS ]===============================================================
        
        public static function toFlareAnchor(value:String):int {
            //if (value != null) value = StringUtil.trim(value.toLowerCase());
            
            switch (value) {
            	case TOP:    return TextSprite.TOP;
            	case MIDDLE: return TextSprite.MIDDLE;
            	case BOTTOM: return TextSprite.BOTTOM;
            	case LEFT:   return TextSprite.LEFT;
            	case CENTER: return TextSprite.CENTER;
            	case RIGHT:
            	default:     return TextSprite.RIGHT;
            }
        }
        
        // ========[ PRIVATE METHODS ]==============================================================

    }
}