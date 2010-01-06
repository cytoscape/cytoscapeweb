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
    
    import org.cytoscapeweb.util.ArrowShapes;
    import org.cytoscapeweb.util.NodeShapes;
    import org.cytoscapeweb.util.Utils;
    import org.cytoscapeweb.util.VisualProperties;
    
    
    public class VisualStyleVOTest extends TestCase {
        
        private var _style:VisualStyleVO;
        private var _defValues:Object;
        private var _mappers:Object;
        private var _dataList:Array;
        private var _propsNumber:int = 0;
        
        private var _simpleStyle:Object = {
                global: { backgroundColor: "#f5f533" },
                nodes:  { shape: NodeShapes.TRIANGLE, color: "#838fa6", opacity: 0.5, selectionColor: "#ff0000" },
                edges:  { color: "#9e7ba5", width: 2 }
        };
        private var _complexStyle:Object = {
                global: {
                    backgroundColor: "#ffffff",
                    tooltipDelay: 1000
                },
                nodes: {
                    color: { defaultValue: "#fbfbfb",
                             discreteMapper: {
                                 attrName: "ATTR_1",
                                 entries: [ { attrValue: "A",  value: "#838fa6" },
                                            { attrValue: "B", value: "#fdfdfa" } ]
                             }
                    },
                    opacity: 1,
                    size: 6,
                    borderColor: "#000000",
                    tooltipFontColor: "#00ff00",
                    tooltipBackgroundColor: "#fafafa",
                    selectionLineColor: "#cccc00",
                    selectionLineWidth: 2,
                    hoverGlowColor: "#aae6ff",
                    hoverGlowOpacity: 0.6
                },
                edges: {
                    color: { defaultValue: "#999999",
                                 discreteMapper: {
                                    attrName: "ATTR_2",
                                    entries: [ { attrValue: 10, value: "#9e7ba5" },
                                               { attrValue: 20, value: "#717cff" },
                                               { attrValue: 30, value: "#73c6cd" } ]
                                 }
                    },
                    width: 3,
                    mergeWidth: 2,
                    opacity: 1,
                    tooltipFontColor: "#000000",
                    curvature: 40
                }
        };
        
        public override function setUp():void {
            _defValues = {};
            _defValues[VisualProperties.BACKGROUND_COLOR] = 0xeeffff;
            _defValues[VisualProperties.SELECTION_FILL_ALPHA] = 0.15;
            _defValues[VisualProperties.NODE_COLOR] = 0xffffffff;
            _defValues[VisualProperties.NODE_LABEL_FONT_COLOR] = 0xff00ff33;
            _defValues[VisualProperties.NODE_LABEL_FONT_NAME] = "Courier";
            _defValues[VisualProperties.NODE_LINE_COLOR] = 0x337799;
            _defValues[VisualProperties.NODE_SHAPE] = NodeShapes.RECTANGLE;
            _defValues[VisualProperties.NODE_SIZE] = 4;
            _defValues[VisualProperties.NODE_SELECTION_COLOR] = 0xffff00;
            _defValues[VisualProperties.NODE_LINE_COLOR] = 0x337799;
            _defValues[VisualProperties.EDGE_COLOR] = 0xff777700;
            _defValues[VisualProperties.EDGE_COLOR_MERGE] = 0xff654987;
            _defValues[VisualProperties.EDGE_CURVATURE] = 36;
            _defValues[VisualProperties.EDGE_TARGET_ARROW_SHAPE] = ArrowShapes.DIAMOND;
            _defValues[VisualProperties.EDGE_WIDTH] = 2;
            _defValues[VisualProperties.EDGE_WIDTH_MERGE] = 1;
            
            _dataList = [ { ATTR_1: "A", ATTR_2: 0.50, ATTR_3: NodeShapes.DIAMOND },
                          { ATTR_1: "B", ATTR_2: 0.18, ATTR_3: NodeShapes.RECTANGLE },
                          { ATTR_1: "C", ATTR_2: 0.87, ATTR_3: NodeShapes.ELLIPSE },
                          { ATTR_1: "D", ATTR_2: 0.27, ATTR_3: NodeShapes.TRIANGLE } ];
            
            _mappers = {};
            var cm:ContinuousVizMapperVO, dm:DiscreteVizMapperVO, pm:PassthroughVizMapperVO;
            
            dm = new DiscreteVizMapperVO("ATTR_1", VisualProperties.EDGE_COLOR);
            dm.addEntry("A", 0xff333333);
            dm.addEntry("D", 0xff555555);
            dm.addEntry("C", 0xff777777);
            _mappers[VisualProperties.EDGE_COLOR] = dm;
            
            cm = new ContinuousVizMapperVO("ATTR_2", VisualProperties.NODE_SIZE, 2, 10);
            cm.dataList = _dataList;
            _mappers[VisualProperties.NODE_SIZE] = cm;
            
            pm = new PassthroughVizMapperVO("ATTR_3", VisualProperties.NODE_SHAPE);
            _mappers[VisualProperties.NODE_SHAPE] = pm;
            
            _style = new VisualStyleVO();
            
            for (var p:* in _defValues) {
                var vp:VisualPropertyVO = new VisualPropertyVO(p, _defValues[p], _mappers[p]);
                _style.addVisualProperty(vp);
                _propsNumber++;
            }
        }
        
        // ========[ TESTS ]========================================================================
        
        public function testNew():void {
            var vs:VisualStyleVO = new VisualStyleVO();
            assertNotNull(vs.properties);
        }

        public function testGetVisualProperty():void {
            for (var p:* in _defValues) {
                var vp:VisualPropertyVO = _style.getVisualProperty(p);
                assertEquals(p, vp.name);
                assertEquals(_style.properties[p], vp);
            }
        }
        
        public function testAddVisualProperty():void {
            var style:VisualStyleVO = new VisualStyleVO();
            try {
                style.addVisualProperty(null);
            } catch (err:Error) {
                fail("Should have ignored a null value!");
            }
            
            assertNull(style.getVisualProperty(VisualProperties.NODE_SELECTION_COLOR));
            var vp:VisualPropertyVO = new VisualPropertyVO(VisualProperties.NODE_SELECTION_COLOR, 0xffff0000);
            style.addVisualProperty(vp);
            assertEquals(vp, style.getVisualProperty(VisualProperties.NODE_SELECTION_COLOR));
        }
        
        public function testGetDefaultValue():void {
            for (var p:* in _defValues) {
                assertEquals(_defValues[p], _style.getDefaultValue(p));
            }
        }
        
        public function testGetValue():void {
            for (var p:* in _defValues) {
                for each (var data:Object in _dataList) {
                    var mapper:VizMapperVO = _style.getVisualProperty(p).vizMapper;
                    
                    if (mapper == null || mapper.getValue(data) == null) {
                        assertEquals(_defValues[p], _style.getValue(p));
                        assertEquals(_defValues[p], _style.getValue(p, data));
                    } else {
                        assertNotNull(_style.getValue(p, data));
                        assertEquals(mapper.getValue(data), _style.getValue(p, data));
                    }
                }
            }
        }
        
        public function testHasVisualProperty():void {
            assertFalse(_style.hasVisualProperty("global.fakeValue"));
            for (var p:* in _defValues) assertTrue(_style.hasVisualProperty(p));
        }
        
        public function testHasVizMapper():void {
            assertFalse(_style.hasVizMapper(VisualProperties.BACKGROUND_COLOR));
            for (var p:* in _mappers) assertTrue(_style.hasVizMapper(p));
        }
        
        public function testGetPropertiesAsArray():void {
            var props:Array = _style.getPropertiesAsArray();
            assertEquals(_propsNumber, props.length);
            for each (var vp:VisualPropertyVO in props) {
                assertEquals(vp, _style.properties[vp.name]);
            }
        }
        
        public function testToObject():void {
            var obj:Object = _style.toObject();
            
            var grName:String, pName:String;
            var arr:Array = _style.getPropertiesAsArray();
            for each (var vp:VisualPropertyVO in arr) {
                var tokens:Array = vp.name.split(".");
                grName = tokens[0];
                pName = tokens[1];
                var ov:* = obj[grName][pName];
                var vv:*;

                if (ov is Number || ov is String) {
                    vv = _style.getDefaultValue(vp.name);
                    if (VisualProperties.isColor(vp.name)) vv = Utils.rgbColorAsString(vv);
                    
                    assertEquals(vv, ov);
                } else {
                    // TODO: VIZMAPPER...
                }
            }
            
            var count:int = 0;
            for (grName in obj) {
                var props:Object = obj[grName];
                for (pName in props) {
                    pName = grName+"."+pName;
                    assertNotNull(_style.getVisualProperty(pName));
                    count++;
                }
            }
            assertEquals(arr.length, count);
        }

        public function testFromObject():void {
            // 1. Empty Object:
            var style:VisualStyleVO = VisualStyleVO.fromObject({});
            // There must be some default props (let's test only some important ones):
            assertTrue(style.getValue(VisualProperties.BACKGROUND_COLOR) > 0);
            assertTrue(style.getValue(VisualProperties.NODE_SELECTION_COLOR) === undefined);
            assertTrue(style.getValue(VisualProperties.EDGE_SELECTION_COLOR) === undefined);
            assertTrue(style.getValue(VisualProperties.NODE_SELECTION_GLOW_ALPHA) > 0);
            assertTrue(style.getValue(VisualProperties.EDGE_SELECTION_GLOW_ALPHA) > 0);
            assertTrue(style.getValue(VisualProperties.EDGE_CURVATURE) > 0);
            assertTrue(style.getValue(VisualProperties.SELECTION_LINE_ALPHA) > 0);
            assertTrue(style.getValue(VisualProperties.NODE_ALPHA) > 0);
            assertTrue(style.getValue(VisualProperties.NODE_SIZE) > 0);
            assertTrue(style.getValue(VisualProperties.EDGE_ALPHA) > 0);
            assertTrue(style.getValue(VisualProperties.EDGE_WIDTH) > 0);
            
            // 2. Simple Object:
            style = VisualStyleVO.fromObject(_simpleStyle);
            
            assertEquals(0xf5f533, style.getValue(VisualProperties.BACKGROUND_COLOR));
            assertEquals(0xffff0000, style.getValue(VisualProperties.NODE_SELECTION_COLOR));
            assertEquals(_simpleStyle.nodes.shape, style.getValue(VisualProperties.NODE_SHAPE));
            assertEquals(0xff838fa6, style.getValue(VisualProperties.NODE_COLOR));
            assertEquals(_simpleStyle.nodes.opacity, style.getValue(VisualProperties.NODE_ALPHA));
            assertEquals(0xff9e7ba5, style.getValue(VisualProperties.EDGE_COLOR));
            assertEquals(_simpleStyle.edges.width, style.getValue(VisualProperties.EDGE_WIDTH));
            
            // 3. A More Complex Object:
            // The given object's properties must overwrite the default ones.
            
            // Merge with the default one:
            var obj:Object = Utils.clone(VisualStyleVO._DEFAULT_OBJ);
            var propNames:Array = [];
            var pName:*
            
            for (var grName:* in _complexStyle) {
                var props:Object = _complexStyle[grName];
                for (pName in props) {
                    var p:Object = props[pName];
                    obj[grName][pName] = p;
                    propNames.push(grName+"."+pName);
                }
            }
            
            var style1:VisualStyleVO = VisualStyleVO.fromObject(obj);
            var style2:VisualStyleVO = VisualStyleVO.fromObject(_complexStyle);
            
            var props1:Array = style1.getPropertiesAsArray();
            var props2:Array = style2.getPropertiesAsArray();

            for each (pName in propNames) {
                var vp1:VisualPropertyVO = style1.getVisualProperty(pName);
                var vp2:VisualPropertyVO = style2.getVisualProperty(pName);
                assertNotNull(vp1);
                assertNotNull(vp2);
                assertEquals(vp1.defaultValue, vp2.defaultValue);
                if (vp1.vizMapper != null)
                    assertEquals(vp1.vizMapper.attrName, vp2.vizMapper.attrName);

                for each (var data:Object in _dataList)
                    assertEquals(style1.getValue(pName, data), style2.getValue(pName, data));
            }
        }
        
        public function testDefaultVisualStyle():void {
            var style1:VisualStyleVO = VisualStyleVO.fromObject(VisualStyleVO._DEFAULT_OBJ);
            var style2:VisualStyleVO = VisualStyleVO.defaultVisualStyle();
            var style3:VisualStyleVO = VisualStyleVO.defaultVisualStyle();
            // Different instances - should not cache:
            assertTrue(style1 !== style2);
            assertTrue(style2 !== style3);
            
            var props:Array = style1.getPropertiesAsArray();
            assertTrue(props.length > 0);
            
            for each (var vp1:VisualPropertyVO in props) {
                var vp2:VisualPropertyVO = style2.getVisualProperty(vp1.name);
                assertNotNull(vp2);
                if (vp1.vizMapper == null) assertNull(vp2.vizMapper);
                else assertNotNull(vp2.vizMapper);
            }
        }
    }
}