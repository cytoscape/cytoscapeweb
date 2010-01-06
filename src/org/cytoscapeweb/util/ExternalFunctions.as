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
    
    
    /**
     * Abstract utility class defining the names of the available external interface functions.
     */
    public class ExternalFunctions {
        
        // ========[ CONSTANTS ]====================================================================
        
        public static const BEFORE_COMPLETE:String = "_onBeforeComplete";
        public static const COMPLETE:String = "_onComplete";
        public static const READY:String = "_onReady";
        
        public static const INVOKE_LISTENERS:String = "_invokeListeners";
        public static const INVOKE_CONTEXT_MENU_CALLBACK:String = "_invokeContextMenuCallback";
        public static const HAS_LISTENER:String = "_hasListener";
        public static const DISPATCH:String = "_dispatch";
        
        // ========[ PRIVATE PROPERTIES ]===========================================================
        
        private static var _jsonFunctions:Array = [INVOKE_LISTENERS, INVOKE_CONTEXT_MENU_CALLBACK];
        
        // ========[ CONSTRUCTOR ]==================================================================
        
        /**
         * This constructor will throw an error, as this is an abstract class.
         */
        public function ExternalFunctions() {
            throw new Error("This is an abstract class.");
        }
        
        // ========[ PUBLIC METHODS ]===============================================================
        
        public static function isJSON(functioName:String):Boolean {
            return functioName != null && _jsonFunctions.indexOf(functioName) !== -1;
        }
        
        // ========[ PRIVATE METHODS ]==============================================================

    }
}