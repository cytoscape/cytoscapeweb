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
    
    
    public class ContinuousVizMapperVOTest extends TestCase {
        
        private const _ATTR_NAME:String = "anAttrName";
        private const _MIN:Number = 0.2;
        private const _MAX:Number = 10;
        private const _XML:XML = <continuous-mapper attr-name={_ATTR_NAME} min-value={_MIN} max-value={_MAX}/>;
        
        private const _MIN_VALUE:Number = -2;
        private const _MAX_VALUE:Number = 400;
        
        private var _dataList:Array;
        private var _values:Array = [-1, 0, _MAX_VALUE, 30, _MIN_VALUE, _MAX_VALUE, 5.5];
        
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
        
        public function testFromObject():void {
            // TODO:
//            var mapper:ContinuousVizMapperVO = ContinuousVizMapperVO.fromXML(_XML);
//            
//            assertEquals(_ATTR_NAME, mapper.attrName);
//            assertEquals(_MIN, mapper.minValue);
//            assertEquals(_MAX, mapper.maxValue);
//            
//            // Test dinamicaly generated values:
//            // -----------------------------------
//            // First, bind the data list to the vizMapper:
//            mapper.dataList = _dataList;
//            
//            for (var i:int = 0; i < _dataList.length; i++) {
//            	var v:Number = _values[i];
//            	var data:Object = _dataList[i];
//            	var f:Number = Maths.invLinearInterp(v, _MIN_VALUE, _MAX_VALUE);
//            	var interpValue:Number = Maths.linearInterp(f, _MIN, _MAX);
//            	
//            	assertEquals(interpValue, mapper.getValue(data));
//            }
//            
//            // Double-check, in case the interpolation done here is incorrect:
//            assertEquals(_MIN, mapper.getValue(_dataList[4]));
//            assertEquals(_MAX, mapper.getValue(_dataList[2]));
        }
    }
}