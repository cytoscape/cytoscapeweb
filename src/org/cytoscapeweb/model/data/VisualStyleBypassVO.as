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
    import org.cytoscapeweb.util.Groups;
    import org.cytoscapeweb.util.VisualProperties;


    /**
     * Visual mapping bypass.
     */
    [Bindable]
    public class VisualStyleBypassVO {
        
        // ========[ PRIVATE PROPERTIES ]===========================================================
        
        private var _map:/*{group->{id->{propName->value}}}*/Object;
        
        // ========[ PUBLIC PROPERTIES ]============================================================
        
        // ========[ CONSTRUCTOR ]==================================================================
        
        public function VisualStyleBypassVO() {
            _map = {};
            _map[Groups.NODES] = {};
            _map[Groups.EDGES] = {};
        }
        
        // ========[ PUBLIC METHODS ]===============================================================
        
        /**
         * Return the visual property value associated with a node or edge.
         * @param propName the visual property name.
         * @param id a node or edge id
         * @return the mapped visual property value
         */
        public function getValue(propName:String, id:*):* {
            var value:*;
            var group:String = VisualProperties.getGroup(propName);
            
            if (group != null) {
                var idMap:Object = _map[group];
                
                if (idMap != null) {
                    var props:Object = idMap[id];
                    if (props != null)
                        value = props[propName];
                }
            }
            
            return value;
        }
        
        /**
         * Set a visual property value associated with a node or edge.
         * @param propName the visual property name.
         * @param id a node or edge id
         * @param value the visual property value.
         */
        public function setValue(propName:String, id:*, value:*):void {
            var group:String = VisualProperties.getGroup(propName);
            
            if ((group === Groups.NODES || group === Groups.EDGES) && id != null && propName != null) {
                var idMap:Object = _map[group];
                var propMap:Object = idMap[id];
                
                if (propMap == null) {
                    propMap = {};
                    idMap[id] = propMap;
                }
                propMap[propName] = value;
            }
        }
        
        public function getValuesSet(propName:String):Array {
// TODO: TEST!!!
            var values:Array = [];
            var lookup:Object = {};
            var group:String = VisualProperties.getGroup(propName);
            var idMap:Object = _map[group];
            
            for each (var propMap:Object in idMap) {
                var v:* = propMap[propName];
                
                if (v !== undefined && !lookup[v]) {
                    values.push(v);
                    lookup[v] = true;
                }
            }
            
            return values;
        }
        
        public function isEmpty():Boolean {
            var k:*;
            for (k in _map[Groups.NODES]) return false;
            for (k in _map[Groups.EDGES]) return false;
            return true;
        }
        
        public function toObject():Object {
            var obj:Object = { nodes: {}, edges: {} };
            var groups:Array = [Groups.NODES, Groups.EDGES];

            for each (var grName:String in groups) {
                var gr:Object = _map[grName];
                
                for (var id:* in gr) {
                    var props:Object = gr[id];
                    var objProps:Object = obj[grName][id];
                    
                    if (objProps == null) {
                        objProps = {};
                        obj[grName][id] = objProps;
                    }
                    
                    for (var pName:String in props) {
                        var value:* = props[pName];
                        value = VisualProperties.toExportValue(pName, value);
                        
                        pName = pName.replace(grName+".", "");
                        objProps[pName] = value;
                    }
                }
            }
            
            return obj;
        }
        
        public static function fromObject(obj:Object):VisualStyleBypassVO {
            var bypass:VisualStyleBypassVO = new VisualStyleBypassVO();
            var grName:String, id:*, pName:String, value:*;

            if (obj != null) {
                for (grName in obj) {
                    var idMap:Object = obj[grName]; 
                    
                    for (id in idMap) {
                        var propMap:Object = idMap[id];
                        
                        for (pName in propMap) {
                            value = propMap[pName];
                            pName = grName + "." + pName;
                            value = VisualProperties.parseValue(pName, value);
                            bypass.setValue(pName, id, value);
                        }
                    }
                }
            }
            
            return bypass;
        }
    }
}
