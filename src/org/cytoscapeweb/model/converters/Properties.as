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
package org.cytoscapeweb.model.converters {
    
    import mx.utils.StringUtil;
    
    public class Properties {
        
        public var values:Object = {};
        
        public function Properties(props:String) {
            if (props != null || props !== "") {   
                var lines:Array = props.split("\n");
                
                for each (var line:String in lines) {
                    if (line.length > 1 && line.charAt(0) != "#") {
                        var parts:Array = line.split("=");
                        var property:String = StringUtil.trim(parts[0]);
                        var value:String = (parts.length > 1) ? parts[1] : "";
                        
                        if (property.length > 0)
                            values[property] = StringUtil.trim(value);
                    }
                }
            }
        }

        public function hasProperty(name:String):Boolean {
            return values.hasOwnProperty(name);
        }
        
        public function getProperty(name:String):String {
            if (values.hasOwnProperty(name)) return values[name];
            return null;
        }
        
        public function serialize():String {
            var serialized:String = "";
            if (values == null) return serialized;
            
            for (var property:String in values) {
                serialized += property + "=" +  String(values[property]) + "\n";
            }
            
            return serialized;
        }
                
    }
}