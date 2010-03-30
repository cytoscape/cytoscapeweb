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
	import flare.util.Maths;
	
	import org.cytoscapeweb.util.Utils;
	import org.cytoscapeweb.util.VisualProperties;
    

    public class ContinuousVizMapperVO extends VizMapperVO {
        
        // ========[ PRIVATE PROPERTIES ]===========================================================
        
        private var _dataList:Array;
        
        // Scale values:
        private var _minValue:Number;
        private var _maxValue:Number;
        // Attribute values:
        private var _minAttrValue:Number;
        private var _maxAttrValue:Number;
        
        // ========[ PUBLIC PROPERTIES ]============================================================
        
        public function get dataList():Array {
            return _dataList;
        }
        
        /**
         * @param list Nodes or edges data objects.  
         */
        public function set dataList(list:Array):void {
            _dataList = list;
            buildScale();
        }
        
        public function get minValue():Number {
            return _minValue;
        }
        
        public function get maxValue():Number {
            return _maxValue;
        }
        
        // ========[ CONSTRUCTOR ]==================================================================
        
        public function ContinuousVizMapperVO(attrName:String,
                                              propName:String,
                                              minValue:Number,
                                              maxValue:Number) {
            super(attrName, propName, this);
            this._minValue = minValue;
            this._maxValue = maxValue;
        }
        
        // ========[ PUBLIC METHODS ]===============================================================
        
        public override function getValue(data:Object):* {
        	var attrValue:Number = data[attrName] as Number;
        	if (dataList == null) return undefined;
        	
        	if (attrValue < _minAttrValue)      attrValue = _minAttrValue;
        	else if (attrValue > _maxAttrValue) attrValue = _maxAttrValue;
        	
        	var value:*;
        	var f:Number = Maths.invLinearInterp(attrValue, _minAttrValue, _maxAttrValue);
        	
        	// So far, it uses only a LINEAR INTERPOLATION:
        	if (VisualProperties.isColor(propName)) {
        	    value = Utils.interpolateColor(_minValue, _maxValue, f);
        	} else {
            	value = Maths.linearInterp(f, _minValue, _maxValue);
            }
        	
            return value;
        }
        
        public override function toObject():Object {
            var obj:Object = new Object();
            obj.attrName = attrName;
            obj.minValue = VisualProperties.toExportValue(propName, minValue);
            obj.maxValue = VisualProperties.toExportValue(propName, maxValue);
            
            return obj;
        }

        public static function fromObject(propName:String, obj:Object):ContinuousVizMapperVO {
            var attrName:String = obj.attrName;
            var min:Number = VisualProperties.parseValue(propName, obj.minValue) as Number;
            var max:Number = VisualProperties.parseValue(propName, obj.maxValue) as Number;
            
            return new ContinuousVizMapperVO(attrName, propName, min, max);
        }
        
        // ========[ PRIVATE METHODS ]==============================================================
        
        private function buildScale():void {
            _maxAttrValue = _minAttrValue = 0;
            
            if (dataList != null && dataList.length > 0) {
	            _maxAttrValue = Number.NEGATIVE_INFINITY;
	            _minAttrValue = Number.POSITIVE_INFINITY;
	            
	            for each (var dt:Object in dataList) {
	                var value:Number = dt[attrName] as Number;
	                _maxAttrValue = Math.max(_maxAttrValue, value);
	                _minAttrValue = Math.min(_minAttrValue, value);
	            }
            }
        }
    }
}