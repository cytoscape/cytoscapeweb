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
package org.cytoscapeweb.model.data {	
	import flash.errors.IllegalOperationError;
	
	
	/**
	 * Abstract class for all visual mapper types.
	 */
	[Bindable]
	public class VizMapperVO {
		
		// ========[ PRIVATE PROPERTIES ]===========================================================
        
        private var _attrName:String;
        private var _propName:String;
        
        // ========[ PUBLIC PROPERTIES ]============================================================
        
        /**
        * Return the data attribute name associated to the VizMapper. 
        */
        public function get attrName():String {
            return _attrName;
        }
        
        public function set attrName(name:String):void {
            _attrName = name;
        }
        
        /**
        * Return visual property name associated to the VizMapper. 
        */
        public function get propName():String {
            return _propName;
        }
        
        internal function set propName(name:String):void {
            _propName = name;
        }
        
        // ========[ CONSTRUCTOR ]==================================================================
        
        public function VizMapperVO(attrName:String, propName:String, self:Object) {
        	if (self != this)
        	   throw new IllegalOperationError("VizMapper is an abstract class and should be instatiated only by its subclasses.");
        	
            _attrName = attrName;
            _propName = propName;
        }
        
        // ========[ PUBLIC METHODS ]===============================================================
		
		/**
		 * Return the visual property value associated with the value inside the informed data object.
		 * Should be implemented by the subclasses.
		 * 
		 * @param data a node or edge data
		 * @return the mapped visual property value
		 */
		public function getValue(data:Object):* {
			return undefined;
		}
		
		/**
		 * Convert a VizMapper instance to a pure Object instance.
		 * Subclasses should override this method.
		 */
		public function toObject():Object {
            return null;
        }
	}
}