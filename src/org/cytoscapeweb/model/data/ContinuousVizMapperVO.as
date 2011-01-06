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
        private var _dynamicMin:Boolean = true;
        private var _dynamicMax:Boolean = true;
        
        // ========[ PUBLIC PROPERTIES ]============================================================
        
        public function get dataList():Array {
            return _dataList;
        }
        
        /**
         * @param list Nodes or edges data objects.  
         */
        public function set dataList(list:Array):void {
            _dataList = list;
            if (_dynamicMin || _dynamicMax) buildScale();
        }
        
        public function get minValue():Number {
            return _minValue;
        }
        
        public function get maxValue():Number {
            return _maxValue;
        }
        
        public function get minAttrValue():Number {
            return _minAttrValue;
        }
        
        public function get maxAttrValue():Number {
            return _maxAttrValue;
        }
        
        // ========[ CONSTRUCTOR ]==================================================================
        
        public function ContinuousVizMapperVO(attrName:String,
                                              propName:String,
                                              minValue:Number,
                                              maxValue:Number,
                                              minAttrValue:Number=NaN,
                                              maxAttrValue:Number=NaN) {
            super(attrName, propName, this);
            _minValue = minValue;
            _maxValue = maxValue;
            _minAttrValue = minAttrValue;
            _maxAttrValue = maxAttrValue;
            _dynamicMin = isNaN(minAttrValue);
            _dynamicMax = isNaN(maxAttrValue);
        }
        
        // ========[ PUBLIC METHODS ]===============================================================
        
        public override function getValue(data:Object):* {
        	var val:* = data[attrName];
        	if (val == null || isNaN(val) || dataList == null) return undefined;
        	
        	var attrValue:Number = val as Number;
        	
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
            if (!_dynamicMin) obj.minAttrValue = minAttrValue;
            if (!_dynamicMax) obj.maxAttrValue = maxAttrValue;
            
            return obj;
        }

        public static function fromObject(propName:String, obj:Object):ContinuousVizMapperVO {
            var attrName:String = obj.attrName;
            var min:Number = VisualProperties.parseValue(propName, obj.minValue) as Number;
            var max:Number = VisualProperties.parseValue(propName, obj.maxValue) as Number;
            
            var minAttr:Number, maxAttr:Number;
            if (!isNaN(obj.minAttrValue)) minAttr = Number(obj.minAttrValue);
            if (!isNaN(obj.maxAttrValue)) maxAttr = Number(obj.maxAttrValue);
            
            return new ContinuousVizMapperVO(attrName, propName, min, max, minAttr, maxAttr);
        }
        
        // ========[ PRIVATE METHODS ]==============================================================
        
        private function buildScale():void {
//            _maxAttrValue = _minAttrValue = 0;
            
            if (dataList != null && dataList.length > 0) {
                if (_dynamicMin) _minAttrValue = Number.POSITIVE_INFINITY;
	            if (_dynamicMax) _maxAttrValue = Number.NEGATIVE_INFINITY;
	            
	            if (_dynamicMin || _dynamicMax) {
    	            for each (var dt:Object in dataList) {
    	                var value:Number = dt[attrName] as Number;
    	                if (_dynamicMin) _minAttrValue = Math.min(_minAttrValue, value);
    	                if (_dynamicMax) _maxAttrValue = Math.max(_maxAttrValue, value);
    	            }
    	        }
            }
        }
    }
}