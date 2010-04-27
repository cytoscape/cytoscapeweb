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
    import org.cytoscapeweb.util.VisualProperties;
    import org.cytoscapeweb.util.methods.$extFunction;
    

    public class CustomVizMapperVO extends VizMapperVO {
        
        // ========[ PRIVATE PROPERTIES ]===========================================================
        
        // ========[ PUBLIC PROPERTIES ]============================================================
        
        public function get functionName():String {
            return attrName;
        }
        
        // ========[ CONSTRUCTOR ]==================================================================
        
        public function CustomVizMapperVO(functionName:String, propName:String) {
            super(functionName, propName, this);
        }
        
        // ========[ PUBLIC METHODS ]===============================================================
        
        public override function getValue(data:Object):* {
            // Call an external JavaScript function:
            var value:* = $extFunction(functionName, data, true);
            value = VisualProperties.parseValue(propName, value);
            
            return value;
        }
        
        public override function toObject():Object {
            return { functionName: attrName };
        }
        
        public static function fromObject(propName:String, obj:Object):CustomVizMapperVO {
            return new CustomVizMapperVO(obj.functionName, propName);
        }
        
        // ========[ PRIVATE METHODS ]==============================================================

    }
}
