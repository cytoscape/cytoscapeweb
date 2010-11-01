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
    
    import flare.data.DataSchema;
    import flare.data.DataSet;
    import flare.data.DataUtil;
    import flare.vis.data.Data;
    import flare.vis.data.EdgeSprite;
    import flare.vis.data.NodeSprite;
    
    import flexunit.framework.TestCase;
    
    import org.cytoscapeweb.fixtures.Fixtures;
    import org.cytoscapeweb.util.Groups;
    
    public class ExternalObjectConverterTest extends TestCase {

        public function testConvertToDataSet():void {
            // Empty networks:
            // --------------------------------------------------------------
            var n:*, ds:DataSet, ns:DataSchema, es:DataSchema, nodes:Array, nd:Array, ed:Array;
            
            var networks:Array = [ null, 
                                  {},
                                  { schema: {}, data: {} },
                                  { schema: { nodes: [], edges: [] }, data: { nodes: [], edges: [] } } 
                                 ];
            
            for each (n in networks) {
                ds = ExternalObjectConverter.convertToDataSet(n);
                assertMinNodesSchema(ds.nodes.schema);
                assertMinEdgesSchema(ds.edges.schema);
                assertEmptyGraph(ds);
            }
        
            // A simple network:
            // --------------------------------------------------------------
            n = {
                schema: {
                    nodes: [
                        { name: "id", type: "number" }, // WRONG! Should be string and will be ignored
                        { name: "score", type: "number", defValue: -1 }
                    ],
                    edges: [
                        { name: "source", type: "string", defValue: "1" },    // Should ignore defValue
                        { name: "directed", type: "boolean", defValue: true }, // Not mandatory, but should use defValue
                        { name: "weight", type: "number" }
                    ]
                },
                data: {
                    nodes: [
                        { id: 1, score: 1.11 }, // Should convert id to string
                        { id: "2", score: 2.22 },
                        { id: "3", score: 3.33 }
                    ],
                    edges: [
                        { id: "e1", source: "1", target: "2", weight: 0.5 },
                        { id: "e2", source: "2", target: 3, weight: 0.5 }, // Should convert target to string
                        { id: "e3", source: 3, target: "3", weight: 0.25, directed: false } // Should convert source to string
                    ]
                }
            };
            
            ds = ExternalObjectConverter.convertToDataSet(n);
            
            // Schema:
            ns = ds.nodes.schema;
            es = ds.edges.schema;
            
            assertMinNodesSchema(ns);
            assertEquals(DataUtil.NUMBER, ns.getFieldByName("score").type);
            assertEquals(-1, ns.getFieldByName("score").defaultValue);
            
            assertMinEdgesSchema(es, true);
            assertEquals(undefined, es.getFieldByName(ExternalObjectConverter.SOURCE).defaultValue);
            assertEquals(DataUtil.NUMBER, es.getFieldByName("weight").type);
            assertEquals(DataUtil.BOOLEAN, es.getFieldByName(ExternalObjectConverter.DIRECTED).type);
            
            // Data
            nd = ds.nodes.data;
            ed = ds.edges.data;
            
            assertEquals(n.data.nodes.length, nd.length);
            assertEquals(n.data.edges.length, ed.length);
            
            for each (var e:Object in ed) {
                assertEquals(e.id !== "e3", e.directed);
            }
            
                        
            // TODO: test values!
        }
        
        public function testToExtObject():void {
            var data:Data = Fixtures.getData(Fixtures.GRAPHML_SIMPLE);
            var o:Object, k:*;
            
            var props:Array = ["data","shape","borderColor","borderWidth","opacity","visible","color","x","y"];
            var attrs:Array = ["id"];
            
            for each (var n:NodeSprite in data.nodes) {
                o = ExternalObjectConverter.toExtObject(n);
                assertEquals(Groups.NODES, o.group);
                
                for each (k in props) assertTrue("Node property: " + k, o.hasOwnProperty(k));
                for each (k in attrs) assertTrue("Node data attribute: " + k, + o.data.hasOwnProperty(k));
                
                assertEquals(n.data.id, o.data.id);
            }
            
            props = ["data","color","width","opacity","visible","sourceArrowShape","targetArrowShape",
                     "sourceArrowColor","targetArrowColor","curvature","merged"];
            attrs = ["id","source","target","directed"];
            
            for each (var e:EdgeSprite in data.edges) {
                o = ExternalObjectConverter.toExtObject(e);
                assertEquals(Groups.EDGES, o.group);
                
                for each (k in props) assertTrue("Edge property: " + k, o.hasOwnProperty(k));
                for each (k in attrs) assertTrue("Edge data attribute: " + k, o.data.hasOwnProperty(k));
                
                assertEquals(e.data.id, o.data.id);
                assertEquals(e.source.data.id, o.data.source);
                assertEquals(e.target.data.id, o.data.target);
            }
        }
        
        private function assertMinNodesSchema(s:DataSchema):void {
            assertEquals(DataUtil.STRING, s.getFieldByName(ExternalObjectConverter.ID).type);
        }
        
        private function assertMinEdgesSchema(s:DataSchema, directed:Boolean=false):void {
            assertEquals(DataUtil.STRING, s.getFieldByName(ExternalObjectConverter.ID).type);
            assertEquals(DataUtil.STRING, s.getFieldByName(ExternalObjectConverter.SOURCE).type);
            assertEquals(DataUtil.STRING, s.getFieldByName(ExternalObjectConverter.TARGET).type);
            assertEquals(DataUtil.BOOLEAN, s.getFieldByName(ExternalObjectConverter.DIRECTED).type);
            assertEquals(directed, s.getFieldByName(ExternalObjectConverter.DIRECTED).defaultValue);
        }
        
        private function assertEmptyGraph(ds:DataSet):void {
            assertEquals(0, ds.nodes.data.length);
            assertEquals(0, ds.edges.data.length);
        }
    }
}