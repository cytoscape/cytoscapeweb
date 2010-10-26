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
	
	
	public class DiscreteVizMapperVO extends VizMapperVO {
		
		// ========[ PRIVATE PROPERTIES ]===========================================================

        private var _entries:Object = {};

		// ========[ PUBLIC PROPERTIES ]============================================================
		
		public function get distinctValues():Array {
		    var values:Array = [];
		    var lookup:Object = {};
		    
		    if (_entries != null) {
		        for (var k:* in _entries) {
	                var v:* = _entries[k];
	                
                    if (!lookup[v]) {
                        values.push(v);
                        lookup[v] = true;
                    }
		        }
		    }
		    
		    return values;
		}
		
		// ========[ CONSTRUCTOR ]==================================================================
		
		public function DiscreteVizMapperVO(attrName:String, propName:String) {
			super(attrName, propName, this);
		}
		
		// ========[ PUBLIC METHODS ]===============================================================
		
		public override function getValue(data:Object):* {
			var value:*;
			
			if (data != null)
                value = _entries[data[attrName]]
			
			return value;
		}
		
        public override function toObject():Object {
            var obj:Object = { attrName: attrName };
            
            var arr:Array = [];
            for (var attrValue:* in _entries) {
                var propValue:* = _entries[attrValue];
                propValue = VisualProperties.toExportValue(propName, propValue);
                arr.push({attrValue: attrValue, value: propValue});
            }
            obj.entries = arr;
            
            return obj;
        }
        
        public function addEntry(attrValue:*, propValue:*):void {
            _entries[attrValue] = propValue;
        }
		
		public static function fromObject(propName:String, obj:Object):DiscreteVizMapperVO {
            var mapper:DiscreteVizMapperVO = new DiscreteVizMapperVO(obj.attrName, propName);
            var arr:Array = obj.entries;
            
            for each (var entry:Object in arr) {
                var attrValue:* = entry.attrValue;
                var propValue:* = entry.value;
                propValue = VisualProperties.parseValue(propName, propValue);
                mapper.addEntry(attrValue, propValue);
            }
            
            return mapper;
        }
	}
}