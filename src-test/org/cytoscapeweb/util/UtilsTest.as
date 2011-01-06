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
package org.cytoscapeweb.util {
	import flexunit.framework.TestCase;	
	
    public class UtilsTest extends TestCase {
        
        // ========[ TESTS ]========================================================================
        
        public function testRgbColorAsString():void {
        	var color:uint = 0x000000;
        	assertEquals("#000000", Utils.rgbColorAsString(color));
        	color = 0x010b0c;
        	assertEquals("#010b0c", Utils.rgbColorAsString(color));
        	color = 0xfafbc0;
        	assertEquals("#fafbc0", Utils.rgbColorAsString(color));
        	color = 0xffffff;
        	assertEquals("#ffffff", Utils.rgbColorAsString(color));
        }
        
        public function testRgbColorAsUint():void {
        	// Hexadecimal RGB
        	assertEquals(0xffffff, Utils.rgbColorAsUint("#ffffff"));
        	// Should accept with leading "#"...
        	assertEquals(0xf3e5a4, Utils.rgbColorAsUint("#f3e5a4"));
        	// Should trim...
        	assertEquals(0x00ff00, Utils.rgbColorAsUint("  00ff00 "));
        	// Both "#" and spaces...
        	assertEquals(0x000000, Utils.rgbColorAsUint(" #000000"));
        	// Should accept 3-digit notation
        	assertEquals(0xffbb00, Utils.rgbColorAsUint("#fb0"));
        	// Invalid color == 0
        	assertEquals(0, Utils.rgbColorAsUint("#fb"));
        	// Invalid
        	assertEquals(0, Utils.rgbColorAsUint("rgb(aaa,ccc)"));
        	// Should accept rgb(r,g,b)
        	assertEquals(0xff00ff, Utils.rgbColorAsUint("rgb(255,0,255)"));
        	// Should accept RGB(r,g,b) with spaces
        	assertEquals(0xff00ff, Utils.rgbColorAsUint("RGB(  255 , 0 , 255  )"));
        	// RGB<SPACE>(r,g,b) is invalid
        	assertEquals(0, Utils.rgbColorAsUint("RGB (  255 , 0 , 255  )"));
        	// Some color keywords:
        	assertEquals(0x800000, Utils.rgbColorAsUint("maroon"));
        	assertEquals(0xff0000, Utils.rgbColorAsUint("red"));
        	assertEquals(0xffffff, Utils.rgbColorAsUint("white"));
        	assertEquals(0x000000, Utils.rgbColorAsUint("black"));
        	assertEquals(0xc0c0c0, Utils.rgbColorAsUint(" SILVER  "));
        	assertEquals(0x808080, Utils.rgbColorAsUint("gray"));
        }
        
        public function testFormat():void {
            var data:Object = { attr0: 1, attr1: "test", attr2: "'OK'", attr3: 0.57, attr4: "${attr1}" };

            var tests:Array = [
//                  TODO: Ignore scaped delimiter (e.g. "\${...}") and avoid recursive attr values:
//                  {input: "${attr4} --${attr2}-- ${attr4}!", output: "${attr1} --'OK'-- ${attr1}!"}, // no loop!
//                  {input: "\\${Nothing to replace}...", output: "\\${Nothing to replace}..."},
//                  {input: "\\\u0024{Nothing to replace}...", output: "\\\u0024{Nothing to replace}..."},

                // 1. Plain text - no tags:
                {input: null, output: null, data: data},
                {input: "", output: "", data: data},
                {input: " Nothing to replace...", output: " Nothing to replace...", data: data},
                {input: "${Nothing to replace...", output: "${Nothing to replace...", data: data},
                // 2. Simple tags - no functions:
                {input: "${attr0}: This ${attr1} is ${attr2}!", output: "1: This test is 'OK'!", data: data},
                {input: " {${attr0} -> This ${attr1} is ${attr2}}", output: " {1 -> This test is 'OK'}", data: data},
                {input: "{${ attr0 }} != {${ attr3}} => ${attr2}", output: "{1} != {0.57} => 'OK'", data: data},
                {input: "${attr3} == ${attr3}", output: "0.57 == 0.57", data: data},
                {input: "${attr0}: ${attr2}, ${attr2}", output: "1: 'OK', 'OK'", data: data}
            ];
        	
        	for each (var item:Object in tests) {
                assertEquals(item.output, Utils.format(item.input, item.data));
        	}
        }
	}
}