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
    
    import flexunit.framework.TestCase;
    
    import org.cytoscapeweb.util.VisualProperties;
    
    
    public class ContinuousVizMapperVOTest extends TestCase {
        
        private const _ATTR_NAME:String = "anAttrName";
        private const _MIN:Number = 0.2;
        private const _MAX:Number = 1;
        private const _MIN_ATTR_VALUE:Number = -2;
        private const _MAX_ATTR_VALUE:Number = 400;
        private var _values:Array = [-1, 0, _MAX_ATTR_VALUE, 30, _MIN_ATTR_VALUE, _MAX_ATTR_VALUE, 5.5];
        private var _dataList:Array;
        
        public function ContinuousVizMapperVOTest() {
            _dataList = new Array();
            
            for each (var v:Object in _values) {
                var data:Object = new Object();
                data["fake1"] = "fakevalue1";
                data[_ATTR_NAME] = v; // This is the one that matters!
                data["fake2"] = 2;
                
                _dataList.push(data);
            }
        }
        
        public function testConversions():void {
            var data:Object;
            var i:int;
            var v:Number;
            
            // Test conversion FROM OBJECT:
            // -----------------------------------
            var mapper:ContinuousVizMapperVO = ContinuousVizMapperVO.fromObject(
                VisualProperties.EDGE_WIDTH,
                { attrName: _ATTR_NAME, minValue: _MIN, maxValue: _MAX, minAttrValue: 0.001, maxAttrValue: 0.88 });
                
            assertEquals(_ATTR_NAME, mapper.attrName);
            assertEquals(_MIN, mapper.minValue);
            assertEquals(_MAX, mapper.maxValue);
            assertEquals(0.001, mapper.minAttrValue);
            assertEquals(0.88, mapper.maxAttrValue);
            
            // Test conversion TO OBJECT:
            // -----------------------------------
            var obj:Object = mapper.toObject();
            assertEquals(_ATTR_NAME, obj.attrName);
            assertEquals(_MIN, obj.minValue);
            assertEquals(_MAX, obj.maxValue);
            assertEquals(0.001, obj.minAttrValue);
            assertEquals(0.88, obj.maxAttrValue);
            
            // Test dinamicaly generated values:
            // -----------------------------------
            mapper = ContinuousVizMapperVO.fromObject(
                VisualProperties.EDGE_WIDTH, { attrName: _ATTR_NAME, minValue: _MIN, maxValue: _MAX });
                
            mapper.dataList = _dataList;
            
            // Min/Max attr. values from data list:
            assertEquals(_MIN_ATTR_VALUE, mapper.minAttrValue);
            assertEquals(_MAX_ATTR_VALUE, mapper.maxAttrValue);
            
            obj = mapper.toObject();
            assertUndefined(obj.minAttrValue); // Dynamic range!
            assertUndefined(obj.maxAttrValue);
            
            // Test interpolated values:
            for (i = 0; i < _dataList.length; i++) {
            	v = _values[i];
            	data = _dataList[i];
            	var f:Number = Maths.invLinearInterp(v, _MIN_ATTR_VALUE, _MAX_ATTR_VALUE);
            	var interpValue:Number = Maths.linearInterp(f, _MIN, _MAX);
            	
            	assertEquals(interpValue, mapper.getValue(data));
            }
            
            // Double-check, in case the interpolation done here is incorrect:
            assertEquals(_MIN, mapper.getValue(_dataList[4]));
            assertEquals(_MAX, mapper.getValue(_dataList[2]));
            
            
            // Test with specified scale's MIN/MAX values:
            // -------------------------------------------
            mapper = ContinuousVizMapperVO.fromObject(
                VisualProperties.EDGE_WIDTH,
                { attrName: _ATTR_NAME, minValue: _MIN, maxValue: _MAX, minAttrValue: 0, maxAttrValue: 10 });
                
            mapper.dataList = _dataList;
            
            // Test interpolated values:
            for (i = 0; i < _dataList.length; i++) {
                data = _dataList[i];
                v = mapper.getValue(data);
                assertTrue(v >= 0 && v <= 10);
            }
        }
    }
}