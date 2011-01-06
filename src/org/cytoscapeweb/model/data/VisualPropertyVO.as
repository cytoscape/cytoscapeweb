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
	
	[Bindable]
	public class VisualPropertyVO {
		
		// ========[ PRIVATE PROPERTIES ]===========================================================
		
		private var _name:String;
		private var _defaultValue:*;
		private var _vizMapper:VizMapperVO;
		
		// ========[ PUBLIC PROPERTIES ]============================================================

		public function get name():String {
			return _name;
		}
		
		public function get defaultValue():* {
            var val:* = _defaultValue;
            
            if (val == null && vizMapper is ContinuousVizMapperVO)
                val = ContinuousVizMapperVO(vizMapper).minValue;
            
            return val;
		}
		
		public function set defaultValue(value:*):void {
            _defaultValue = value;
		}
		
		public function get vizMapper():VizMapperVO {
            return _vizMapper;
        }
        
		public function set vizMapper(mapper:VizMapperVO):void {
            if (mapper != null) mapper.propName = name;
            _vizMapper = mapper;
        }
		
		// ========[ CONSTRUCTOR ]==================================================================
		
		public function VisualPropertyVO(name:String, defaultValue:*=null, vizMapper:VizMapperVO=null) {
			this._name = name;
			this.defaultValue = defaultValue;
			this.vizMapper = vizMapper;
		}
		
		// ========[ PUBLIC METHODS ]===============================================================
		
		/**
         * Return the visual property value associated with the informed graph data.
         * If there's a VizMapper associated with this property, it first tries to get a value
         * from the mapper.
         * If there's no mapper or the mapper has no value for the informed data,
         * it just returns the default value.
         * 
         * @param data a node or edge data object
         * @return the visual property value
         */
		public function getValue(data:Object):* {
			var value:*;

            if (!isGlobalProperty() && vizMapper != null)
                value = vizMapper.getValue(data);
            if (value == null)
                value = defaultValue;
                
            return value;
        }
        
		public function isGlobalProperty():Boolean {
            return VisualProperties.isGlobal(name);
        }
        
		public function isNodeProperty():Boolean {
            return VisualProperties.isNode(name);
        }
        
		public function isEdgeProperty():Boolean {
            return VisualProperties.isEdge(name);
        }
        
		public function isMergedEdgeProperty():Boolean {
            return VisualProperties.isMergedEdge(name);
        }
        
		public function isNumber():Boolean {
            return VisualProperties.isNumber(name);
        }
        
		public function isString():Boolean {
            return VisualProperties.isString(name);
        }
        
		public function isColor():Boolean {
            return VisualProperties.isColor(name);
        }
        
        public function toObject():Object {
            var obj:Object = {};
            
            if (vizMapper != null) {
                obj.defaultValue = VisualProperties.toExportValue(name, defaultValue);
                var mapper:Object = vizMapper.toObject();
                
                if (vizMapper is DiscreteVizMapperVO)
                    obj.discreteMapper = mapper;
                else if (vizMapper is ContinuousVizMapperVO)
                    obj.continuousMapper = mapper;
                else if (vizMapper is PassthroughVizMapperVO)
                    obj.passthroughMapper = mapper;
                else
                    obj.customMapper = mapper;
            } else {
                obj = VisualProperties.toExportValue(name, defaultValue);
            }
            
            return obj;
        }
        
        public static function fromObject(name:String, prop:Object):VisualPropertyVO {
            var vp:VisualPropertyVO = null;
            
            if (name != null && prop != null) {
                var defValue:* = null;
                var mapper:VizMapperVO = null;
    
                if (prop.hasOwnProperty("discreteMapper"))
                    mapper = DiscreteVizMapperVO.fromObject(name, prop.discreteMapper);
                else if (prop.hasOwnProperty("continuousMapper"))
                    mapper = ContinuousVizMapperVO.fromObject(name, prop.continuousMapper);
                else if (prop.hasOwnProperty("passthroughMapper"))
                    mapper = PassthroughVizMapperVO.fromObject(name, prop.passthroughMapper);
                else if (prop.hasOwnProperty("customMapper"))
                    mapper = CustomVizMapperVO.fromObject(name, prop.customMapper);
                
                if (prop.hasOwnProperty("defaultValue"))
                    defValue = prop.defaultValue;
                else if (mapper == null)
                    defValue = prop;
                
                defValue = VisualProperties.parseValue(name, defValue);
                
                vp = new VisualPropertyVO(name, defValue);
                
                if (!VisualProperties.isGlobal(name))
                    vp.vizMapper = mapper;
            }
            
            return vp;
        }

        // ========[ PRIVATE METHODS ]==============================================================

	}
}