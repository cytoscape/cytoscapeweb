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
    
    public class VisualPropertiesTest extends TestCase {
        
        // ========[ TESTS ]========================================================================
        
        public function testAbstractClass():void {
            var failed:Boolean = true;
            
            try {
                new VisualProperties();
            } catch (err:Error) {
                failed = false;
            }
            
            if (failed) fail("Should not be able to instantiate VisualProperties");
        }
        
        public function testParseValue():void {
            assertEquals(0xeeffee, VisualProperties.parseValue(VisualProperties.BACKGROUND_COLOR, "eeffee"));
            assertEquals(null, VisualProperties.parseValue(VisualProperties.BACKGROUND_COLOR, null));
            assertEquals(0xffeeffee, VisualProperties.parseValue(VisualProperties.NODE_COLOR, "#eeffee"));
            assertEquals(0xff000000, VisualProperties.parseValue(VisualProperties.NODE_COLOR, "000000"));
            assertEquals(0xff000000, VisualProperties.parseValue(VisualProperties.NODE_COLOR, "#000000"));
            assertEquals(null, VisualProperties.parseValue(VisualProperties.EDGE_COLOR, null));
            assertEquals(null, VisualProperties.parseValue(VisualProperties.EDGE_COLOR, undefined));
            
            assertEquals(32, VisualProperties.parseValue(VisualProperties.NODE_SIZE, 32));
            assertEquals(32, VisualProperties.parseValue(VisualProperties.NODE_SIZE, "  32.0 "));
            assertEquals(0.8, VisualProperties.parseValue(VisualProperties.NODE_ALPHA, "0.8"));
            assertEquals(0, VisualProperties.parseValue(VisualProperties.EDGE_CURVATURE, ""));
            assertEquals(0, VisualProperties.parseValue(VisualProperties.EDGE_CURVATURE, " "));
            assertEquals(null, VisualProperties.parseValue(VisualProperties.EDGE_CURVATURE, null));
            assertEquals(null, VisualProperties.parseValue(VisualProperties.EDGE_WIDTH, undefined));
            
            assertEquals("1.15", VisualProperties.parseValue(VisualProperties.NODE_TOOLTIP_TEXT, 1.15));
            assertEquals(" ", VisualProperties.parseValue(VisualProperties.NODE_TOOLTIP_TEXT, " "));
            assertEquals(null, VisualProperties.parseValue(VisualProperties.NODE_TOOLTIP_TEXT, null));
            assertEquals(null, VisualProperties.parseValue(VisualProperties.NODE_TOOLTIP_TEXT, undefined));
            
            assertEquals(NodeShapes.ELLIPSE, VisualProperties.parseValue(VisualProperties.NODE_SHAPE, 0));
            assertEquals(NodeShapes.ELLIPSE, VisualProperties.parseValue(VisualProperties.NODE_SHAPE, "NotAShape!"));
            assertEquals(NodeShapes.ELLIPSE, VisualProperties.parseValue(VisualProperties.NODE_SHAPE, ""));
            assertEquals(null, VisualProperties.parseValue(VisualProperties.NODE_SHAPE, null));
            assertEquals(null, VisualProperties.parseValue(VisualProperties.NODE_SHAPE, undefined));
            
            assertEquals(ArrowShapes.NONE, VisualProperties.parseValue(VisualProperties.EDGE_SOURCE_ARROW_SHAPE, 0));
            assertEquals(ArrowShapes.NONE, VisualProperties.parseValue(VisualProperties.EDGE_TARGET_ARROW_SHAPE, "NotAShape!"));
            assertEquals(ArrowShapes.NONE, VisualProperties.parseValue(VisualProperties.EDGE_SOURCE_ARROW_SHAPE, ""));
            assertEquals(null, VisualProperties.parseValue(VisualProperties.EDGE_TARGET_ARROW_SHAPE, null));
            assertEquals(null, VisualProperties.parseValue(VisualProperties.EDGE_SOURCE_ARROW_SHAPE, undefined));
        }
        
        public function testToExportValue():void {
            assertEquals("#eeffee", VisualProperties.toExportValue(VisualProperties.BACKGROUND_COLOR, 0xeeffee));
            assertEquals("#eeffee", VisualProperties.toExportValue(VisualProperties.NODE_COLOR, 0xffeeffee));
            assertEquals("#000000", VisualProperties.toExportValue(VisualProperties.NODE_COLOR, 0));
            assertEquals("#000000", VisualProperties.toExportValue(VisualProperties.NODE_COLOR, null));
            assertEquals("#000000", VisualProperties.toExportValue(VisualProperties.EDGE_COLOR, undefined));
            
            assertEquals(32, VisualProperties.toExportValue(VisualProperties.NODE_SIZE, 32));
            assertEquals(32, VisualProperties.toExportValue(VisualProperties.NODE_SIZE, "  32.0 "));
            assertEquals(0.8, VisualProperties.toExportValue(VisualProperties.NODE_ALPHA, "0.8"));
            assertEquals(0, VisualProperties.toExportValue(VisualProperties.EDGE_CURVATURE, ""));
            assertEquals(0, VisualProperties.toExportValue(VisualProperties.EDGE_CURVATURE, " "));
            assertEquals(0, VisualProperties.toExportValue(VisualProperties.EDGE_CURVATURE, null));
            assertEquals(0, VisualProperties.toExportValue(VisualProperties.EDGE_WIDTH, undefined));
            
            assertEquals("1.15", VisualProperties.toExportValue(VisualProperties.NODE_TOOLTIP_TEXT, 1.15));
            assertEquals(" ", VisualProperties.toExportValue(VisualProperties.NODE_TOOLTIP_TEXT, " "));
            assertEquals("", VisualProperties.toExportValue(VisualProperties.NODE_TOOLTIP_TEXT, null));
            assertEquals("", VisualProperties.toExportValue(VisualProperties.NODE_TOOLTIP_TEXT, undefined));
        }
        
        public function testIsColor():void {
            assertTrue(VisualProperties.isColor(VisualProperties.BACKGROUND_COLOR));
            assertTrue(VisualProperties.isColor(VisualProperties.NODE_COLOR));
            assertTrue(VisualProperties.isColor(VisualProperties.NODE_SELECTION_COLOR));
            assertTrue(VisualProperties.isColor(VisualProperties.NODE_LINE_COLOR));
            assertTrue(VisualProperties.isColor(VisualProperties.NODE_SELECTION_LINE_COLOR));
            assertTrue(VisualProperties.isColor(VisualProperties.NODE_HOVER_GLOW_COLOR));
            assertTrue(VisualProperties.isColor(VisualProperties.NODE_LABEL_GLOW_COLOR));
            assertTrue(VisualProperties.isColor(VisualProperties.EDGE_COLOR));
            assertTrue(VisualProperties.isColor(VisualProperties.EDGE_COLOR_MERGE));
            assertTrue(VisualProperties.isColor(VisualProperties.SELECTION_FILL_COLOR));
            assertTrue(VisualProperties.isColor("Color"));
            
            assertFalse(VisualProperties.isColor(VisualProperties.NODE_ALPHA));
            assertFalse(VisualProperties.isColor(VisualProperties.NODE_LABEL));
            assertFalse(VisualProperties.isColor(VisualProperties.NODE_LABEL_FONT_SIZE));
            assertFalse(VisualProperties.isColor(VisualProperties.EDGE_ALPHA));
            assertFalse(VisualProperties.isColor(VisualProperties.EDGE_SELECTION_GLOW_ALPHA));
            assertFalse(VisualProperties.isColor(VisualProperties.EDGE_CURVATURE));
            assertFalse(VisualProperties.isColor(VisualProperties.EDGE_TOOLTIP_FONT));
            assertFalse(VisualProperties.isColor(VisualProperties.EDGE_TOOLTIP_FONT_SIZE));
            assertFalse(VisualProperties.isColor(VisualProperties.EDGE_WIDTH));
        }
        
        public function testIsNumber():void {
            var tests:Array = [ "nodeWidth", " anotherWIDTH  ", "height", "sizeOfSomething", 
                                "oPAcitY", "xOffset", "edgeCurvature", "tooltip_delay", "glowblur", 
                                "glowStrength" ];
            for each (var s:String in tests) assertTrue(VisualProperties.isNumber(s));
            
            assertFalse(VisualProperties.isNumber(VisualProperties.BACKGROUND_COLOR));
            assertFalse(VisualProperties.isNumber(VisualProperties.NODE_COLOR));
            assertFalse(VisualProperties.isNumber(VisualProperties.NODE_LABEL));
            assertFalse(VisualProperties.isNumber(VisualProperties.NODE_LABEL_FONT_NAME));
            assertFalse(VisualProperties.isNumber(VisualProperties.NODE_SHAPE));
            assertFalse(VisualProperties.isNumber(VisualProperties.EDGE_TARGET_ARROW_SHAPE));
            assertFalse(VisualProperties.isNumber(VisualProperties.EDGE_TOOLTIP_TEXT));
        }
        
        public function testIsString():void {
            assertTrue(VisualProperties.isString(VisualProperties.NODE_LABEL));
            assertTrue(VisualProperties.isString(VisualProperties.NODE_LABEL_FONT_NAME));
            assertTrue(VisualProperties.isString(VisualProperties.NODE_SHAPE));
            assertTrue(VisualProperties.isString(VisualProperties.EDGE_TARGET_ARROW_SHAPE));
            assertTrue(VisualProperties.isString(VisualProperties.EDGE_TOOLTIP_TEXT));
            
            assertFalse(VisualProperties.isString(VisualProperties.NODE_COLOR));
            assertFalse(VisualProperties.isString(VisualProperties.NODE_LINE_WIDTH));
            assertFalse(VisualProperties.isString(VisualProperties.EDGE_CURVATURE));
            assertFalse(VisualProperties.isString(VisualProperties.EDGE_SELECTION_GLOW_STRENGTH));
            assertFalse(VisualProperties.isString(VisualProperties.SELECTION_FILL_ALPHA));
        }
        
        public function testIsGlobal():void {
            assertTrue(VisualProperties.isGlobal("global.anything"));
            
            assertFalse(VisualProperties.isGlobal("fake.global.anything"));
            assertFalse(VisualProperties.isGlobal("Global.anything"));
            assertFalse(VisualProperties.isGlobal("globalFake"));
            assertFalse(VisualProperties.isGlobal("global_anything"));
            assertFalse(VisualProperties.isGlobal(VisualProperties.NODE_COLOR));
            assertFalse(VisualProperties.isGlobal(VisualProperties.EDGE_COLOR));
        }
        
        public function testIsNode():void {
            assertTrue(VisualProperties.isNode("nodes.anything"));
            
            assertFalse(VisualProperties.isNode("fake.node.anything"));
            assertFalse(VisualProperties.isNode("Node.anything"));
            assertFalse(VisualProperties.isNode("nodeFake"));
            assertFalse(VisualProperties.isNode("node_anything"));
            assertFalse(VisualProperties.isNode(VisualProperties.SELECTION_FILL_COLOR));
            assertFalse(VisualProperties.isNode(VisualProperties.EDGE_COLOR));
        }
        
        public function testIsEdge():void {
            assertTrue(VisualProperties.isEdge("edges.anything"));
            
            assertFalse(VisualProperties.isEdge("fake.edge.anything"));
            assertFalse(VisualProperties.isEdge("Edge.anything"));
            assertFalse(VisualProperties.isEdge("edgeFake"));
            assertFalse(VisualProperties.isEdge("edge_anything"));
            assertFalse(VisualProperties.isEdge(VisualProperties.SELECTION_FILL_COLOR));
            assertFalse(VisualProperties.isEdge(VisualProperties.NODE_COLOR));
        }
        
        public static function testIsMergedEdge():void {
            assertTrue(VisualProperties.isMergedEdge("edges.anythingMerge"));
            
            assertFalse(VisualProperties.isMergedEdge("nodes.anythingMerge"));
            assertFalse(VisualProperties.isMergedEdge("global.anythingMerge"));
            assertFalse(VisualProperties.isMergedEdge("edges.mergeAnything"));
            assertFalse(VisualProperties.isMergedEdge("edges.MERGE"));
            assertFalse(VisualProperties.isMergedEdge("mergeEdge"));
        }
    }
}
