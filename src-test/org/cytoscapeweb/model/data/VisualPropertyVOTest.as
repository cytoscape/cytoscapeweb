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
    
    import org.cytoscapeweb.util.NodeShapes;
    import org.cytoscapeweb.util.VisualProperties;
    
    
    public class VisualPropertyVOTest extends TestCase {

        public override function setUp():void {
        }
        
        // ========[ TESTS ]========================================================================
        
        public function testNew():void {
            var vp:VisualPropertyVO = new VisualPropertyVO(VisualProperties.BACKGROUND_COLOR);
            assertEquals(VisualProperties.BACKGROUND_COLOR, vp.name);
            assertNull(vp.defaultValue);
            assertNull(vp.vizMapper);
            
            var mapper:PassthroughVizMapperVO = new PassthroughVizMapperVO("attr", VisualProperties.EDGE_CURVATURE);
            vp = new VisualPropertyVO(VisualProperties.NODE_COLOR, 0xff00ffff, mapper);
            assertEquals(VisualProperties.NODE_COLOR, vp.name);
            assertEquals(vp.name, mapper.propName);
            assertEquals(0xff00ffff, vp.defaultValue);
            assertEquals(mapper, vp.vizMapper);
        }

        public function testToObject():void {
            var tests:Array = [
                { prop: VisualProperties.BACKGROUND_COLOR },
                { prop: VisualProperties.NODE_SIZE },
                { prop: VisualProperties.NODE_LABEL },
                { prop: VisualProperties.BACKGROUND_COLOR, def: 0xe5f0f0f0 },
                { prop: VisualProperties.NODE_SIZE, def: 6 },
                { prop: VisualProperties.NODE_TOOLTIP_TEXT, def: "A Tooltip" },
                { prop: VisualProperties.NODE_SHAPE, def: NodeShapes.ELLIPSE, mapper: new DiscreteVizMapperVO("id", VisualProperties.NODE_SHAPE) },
                { prop: VisualProperties.NODE_SIZE, def: 24, mapper: new ContinuousVizMapperVO("weight", VisualProperties.NODE_SIZE, 12, 36) },
                { prop: VisualProperties.NODE_LABEL, mapper: new PassthroughVizMapperVO("label", VisualProperties.NODE_LABEL) },
                { prop: VisualProperties.EDGE_TOOLTIP_TEXT, mapper: new CustomVizMapperVO("edgeTooltipMapper", VisualProperties.EDGE_TOOLTIP_TEXT) }
            ];
            
            for each (var t:Object in tests) {
                var vp:VisualPropertyVO = new VisualPropertyVO(t.prop, t.def, t.mapper);
                var obj:Object = vp.toObject();
                if (t.mapper == null) {
                    assertStrictlyEquals(VisualProperties.toExportValue(t.prop, t.def), obj);
                } else {
                    assertStrictlyEquals(VisualProperties.toExportValue(t.prop, t.def), obj.defaultValue);
                    
                    if (t.mapper is DiscreteVizMapperVO)
                        assertNotNull(obj.discreteMapper);
                    else if (t.mapper is ContinuousVizMapperVO)
                        assertNotNull(obj.continuousMapper);
                    else if (t.mapper is PassthroughVizMapperVO)
                        assertNotNull(obj.passthroughMapper);
                    else
                        assertNotNull(obj.customMapper);
                }
            }
        }
    }
}
