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
    
    import flare.data.DataSet;
    import flare.data.DataTable;
    import flare.vis.data.Data;
    
    import flash.utils.IDataOutput;
    
    import flexunit.framework.TestCase;
    
    import org.cytoscapeweb.fixtures.Fixtures;
    import org.cytoscapeweb.model.data.GraphicsDataTable;
    import org.cytoscapeweb.model.data.VisualStyleVO;
    import org.cytoscapeweb.util.ArrowShapes;
    import org.cytoscapeweb.util.Fonts;
    import org.cytoscapeweb.util.NodeShapes;
    import org.cytoscapeweb.util.VisualProperties;
    
    public class XGMMLConverterTest extends TestCase {
        
        public function testConvertToXgmml():void {
            var ds:DataSet = Fixtures.getDataSet(Fixtures.GRAPHML_SIMPLE);
            
            var data:Data = Data.fromDataSet(ds);
            var nodesDt:DataTable = new GraphicsDataTable(data.nodes, ds.nodes.schema);
            var edgesDt:DataTable = new GraphicsDataTable(data.edges, ds.edges.schema);
            
            // Have to recreate the dataset, because this one contains GraphicsDataTable objects:
            ds = new DataSet(nodesDt, edgesDt);
            
            var out:IDataOutput = new XGMMLConverter(new VisualStyleVO()).write(ds);
            var xgmml:XML = XML("" + out);
            
            var ns:Namespace =  new Namespace(XGMMLConverter.DEFAULT_NAMESPACE);
            var nodesXml:XMLList = xgmml.ns::node;
            var edgesXml:XMLList = xgmml.ns::edge;
            
            assertEquals("Number of <node> tags incorrect!", data.nodes.length, nodesXml.length());
            assertEquals("Number of <edge> tags incorrect!", data.edges.length, edgesXml.length());
            
            for each (var n:XML in nodesXml) {
                assertTrue(n.@id.length() == 1);
                assertTrue(n.@label.length() == 1);
                assertTrue(n.ns::graphics.length() == 1);
                
                var g:XML = n.ns::graphics[0];
                // *** TODO: Test visual attributes according to VizMapper:
                assertEquals(NodeShapes.ELLIPSE, g.@type);
            }
            
            for each (var e:XML in edgesXml) {
                assertTrue(e.@label.length() == 1);
                assertTrue(e.@source.length() == 1);
                assertTrue(e.@target.length() == 1);
                assertTrue(e.@weight.length() == 1);
                assertTrue(e.ns::graphics.length() == 1);
                
                // *** TODO: Tests visual attributes according to VizMapper:
            }
        }
        
        public function testParseValue():void {
            // Device fonts:
            const F1:String = "Default-0-12";
            const F2:String = "SansSerif-0-08";
            const F3:String = "SansSerif.bold-10-8";
            const F4:String = "Serif.Bold-0-102";
            const F5:String = "Monospaced-000-024";
            // OS fonts:
            const F6:String = "ArialNarrow-Bold-0-012";
            const F7:String = "ACaslonPro-Regular-0-8";
            const F8:String = "LucidaBright-Italic-10-24";
            // Unrecognizable fonts:
            const F9:String = "-0-012";
            const F10:String = ".bold-0-8";
            
            var tests:Array = [
                { prop: VisualProperties.BACKGROUND_COLOR, value: "f53377", res: 0xf53377 },
                { prop: VisualProperties.NODE_COLOR, value: "556677", res: 0xff556677 },
                { prop: VisualProperties.NODE_SIZE, value: "36", res: 36 },
                // FONT NAME:
                { prop: VisualProperties.NODE_LABEL_FONT_NAME, value: F1, res: Fonts.SANS_SERIF },
                { prop: VisualProperties.NODE_LABEL_FONT_NAME, value: F2, res: Fonts.SANS_SERIF },
                { prop: VisualProperties.NODE_LABEL_FONT_NAME, value: F3, res: Fonts.SANS_SERIF },
                { prop: VisualProperties.NODE_LABEL_FONT_NAME, value: F4, res: Fonts.SERIF },
                { prop: VisualProperties.NODE_LABEL_FONT_NAME, value: F5, res: Fonts.TYPEWRITER },
                { prop: VisualProperties.NODE_LABEL_FONT_NAME, value: F6, res: "ArialNarrow-Bold" },
                { prop: VisualProperties.NODE_LABEL_FONT_NAME, value: F7, res: "ACaslonPro-Regular" },
                { prop: VisualProperties.NODE_LABEL_FONT_NAME, value: F8, res: "LucidaBright-Italic" },
                { prop: VisualProperties.NODE_LABEL_FONT_NAME, value: F9, res: Fonts.SANS_SERIF },
                { prop: VisualProperties.NODE_LABEL_FONT_NAME, value: F10, res: Fonts.SANS_SERIF },
                // FONT SIZE:
                { prop: VisualProperties.NODE_LABEL_FONT_SIZE, value: F1, res: 12 },
                { prop: VisualProperties.NODE_LABEL_FONT_SIZE, value: F2, res: 8 },
                { prop: VisualProperties.NODE_LABEL_FONT_SIZE, value: F3, res: 8 },
                { prop: VisualProperties.NODE_LABEL_FONT_SIZE, value: F4, res: 102 },
                { prop: VisualProperties.NODE_LABEL_FONT_SIZE, value: F5, res: 24 },
                { prop: VisualProperties.NODE_LABEL_FONT_SIZE, value: F6, res: 12 },
                { prop: VisualProperties.NODE_LABEL_FONT_SIZE, value: F7, res: 8 },
                { prop: VisualProperties.NODE_LABEL_FONT_SIZE, value: F8, res: 24 },
                { prop: VisualProperties.NODE_LABEL_FONT_SIZE, value: F9, res: 12 },
                { prop: VisualProperties.NODE_LABEL_FONT_SIZE, value: F10, res: 8 },
                // ARROW SHAPES:
                { prop: VisualProperties.EDGE_SOURCE_ARROW_SHAPE, value: 0, res: ArrowShapes.NONE },
                { prop: VisualProperties.EDGE_SOURCE_ARROW_SHAPE, value: 3, res: ArrowShapes.DELTA },
                { prop: VisualProperties.EDGE_SOURCE_ARROW_SHAPE, value: 9, res: ArrowShapes.DIAMOND },
                { prop: VisualProperties.EDGE_SOURCE_ARROW_SHAPE, value: 12, res: ArrowShapes.CIRCLE },
                { prop: VisualProperties.EDGE_SOURCE_ARROW_SHAPE, value: 15, res: ArrowShapes.T },
                { prop: VisualProperties.EDGE_TARGET_ARROW_SHAPE, value: 0, res: ArrowShapes.NONE },
                { prop: VisualProperties.EDGE_TARGET_ARROW_SHAPE, value: 3, res: ArrowShapes.DELTA },
                { prop: VisualProperties.EDGE_TARGET_ARROW_SHAPE, value: 9, res: ArrowShapes.DIAMOND },
                { prop: VisualProperties.EDGE_TARGET_ARROW_SHAPE, value: 12, res: ArrowShapes.CIRCLE },
                { prop: VisualProperties.EDGE_TARGET_ARROW_SHAPE, value: 15, res: ArrowShapes.T }
            ];
            
            for each (var t:Object in tests) {
                var v:* = XGMMLConverter.parseValue(t.prop, t.value);
                assertEquals(t.res, v);
            }
        }
    }
}