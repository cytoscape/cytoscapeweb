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
	import flexunit.framework.TestCase;
	
	import org.cytoscapeweb.util.VisualProperties;
	
	
	public class DiscreteVizMapperVOTest extends TestCase {
        
        private var _dt1:Object;
        private var _dt2:Object;
        private var _mapper1:DiscreteVizMapperVO;
        private var _mapper2:DiscreteVizMapperVO;
        
        public override function setUp():void {
        	_dt1 = {
        	   attr1: "A",
        	   attr2: 1
        	};
        	_dt2 = {
        	   attr1: "B",
        	   attr2: 2
        	};
        	_mapper1 = new DiscreteVizMapperVO("attr1", VisualProperties.NODE_COLOR);
        	_mapper2 = new DiscreteVizMapperVO("attr2", VisualProperties.EDGE_WIDTH);
        }
        
        public function testNew():void {
            assertEquals("attr1", _mapper1.attrName);
            assertEquals(VisualProperties.NODE_COLOR, _mapper1.propName);
        }
        
        public function testAddEntry():void {
            _mapper1.addEntry("A", VisualProperties.parseValue(_mapper1.propName, "#ff0000"));
            _mapper1.addEntry("B", VisualProperties.parseValue(_mapper1.propName, "#0000ff"));
            _mapper1.addEntry("C", VisualProperties.parseValue(_mapper1.propName, "00ffff"));
            
            assertEquals(0xffff0000, _mapper1.getValue(_dt1));
            assertEquals(0xff0000ff, _mapper1.getValue(_dt2));
            assertUndefined(_mapper1.getValue(null));
            assertUndefined(_mapper1.getValue({attr3: "C"}));
            
            _mapper2.addEntry(1, VisualProperties.parseValue(_mapper2.propName, 2));
            _mapper2.addEntry(2, VisualProperties.parseValue(_mapper2.propName, 4));
            _mapper2.addEntry(3, VisualProperties.parseValue(_mapper2.propName, 6));
            
            assertEquals(2, _mapper2.getValue(_dt1));
            assertEquals(4, _mapper2.getValue(_dt2));
            assertUndefined(_mapper1.getValue(null));
            assertUndefined(_mapper1.getValue({}));
        }
        
        public function testDistinctValues():void {
            var m:DiscreteVizMapperVO = new DiscreteVizMapperVO("attrName", VisualProperties.NODE_IMAGE);
            m.addEntry(1, "img1");
            m.addEntry(2, "IMG1");
            m.addEntry(3, "img2");
            m.addEntry(4, "img3");
            m.addEntry(5, "img3");
            m.addEntry(6, "img1");
            m.addEntry(7, "img1");
            
            var distinct:Array = m.distinctValues;
            assertEquals(4, distinct.length);
        }
        
        public function testToObject():void {
            _mapper1.addEntry("A", VisualProperties.parseValue(_mapper1.propName, "#ff0000"));
            _mapper1.addEntry("B", VisualProperties.parseValue(_mapper1.propName, "0000ff"));
            
            var obj:Object = _mapper1.toObject();
            assertEquals("attr1", obj.attrName);

            var entries:Array = obj.entries;
            assertEquals(2, entries.length);
            assertEquals("A", entries[1].attrValue);
            
            for each (var entry:Object in entries) {
                if (entry.attrValue === "A")      assertEquals("#ff0000", entry.value);
                else if (entry.attrValue === "B") assertEquals("#0000ff", entry.value);
                else fail("Entries attribute values should be 'A' or 'B'!");
            }
        }
	}
}