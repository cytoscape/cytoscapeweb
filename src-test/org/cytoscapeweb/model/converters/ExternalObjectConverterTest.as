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
    import org.cytoscapeweb.model.error.CWError;
    import org.cytoscapeweb.util.DataSchemaUtils;
    import org.cytoscapeweb.util.Groups;
    
    public class ExternalObjectConverterTest extends TestCase {

        public function testNormalizeDataValue():void {
            /*
            if (value === undefined) value = defValue !== undefined ? defValue : null;

            // Validate and normalize numeric values:
            if (type === DataUtil.INT) {
                if (value == null || value is String || isNaN(value))
                    throw new CWError("Invalid data type ("+(typeof value)+") for field of type 'int': " + value,
                                      ErrorCodes.INVALID_DATA_CONVERSION);
            } else if (type === DataUtil.NUMBER) {
                if (value === undefined) value = null;
                
                if (value != null && isNaN(value))
                    throw new CWError("Invalid data type ("+(typeof value)+") for field of type 'number': " + value,
                                      ErrorCodes.INVALID_DATA_CONVERSION);
            } else if (type === DataUtil.BOOLEAN) {
                if (! (value is Boolean))
                    throw new CWError("Invalid data type ("+(typeof value)+") for field of type 'boolean': " + value,
                                      ErrorCodes.INVALID_DATA_CONVERSION);
            } else if (type === DataUtil.STRING) {
                if (value != null && !(value is String))
                    throw new CWError("Invalid data type ("+(typeof value)+") for field of type 'string': " + value,
                                      ErrorCodes.INVALID_DATA_CONVERSION);
            }
            */
            
            // Valid values:
            assertEquals(3, ExternalObjectConverter.normalizeDataValue(3, DataUtil.INT));
            assertEquals(3.33, ExternalObjectConverter.normalizeDataValue(3.33, DataUtil.NUMBER));
            assertEquals(false, ExternalObjectConverter.normalizeDataValue(false, DataUtil.BOOLEAN));
            assertEquals(true, ExternalObjectConverter.normalizeDataValue(true, DataUtil.BOOLEAN));
            assertEquals("A_VAL", ExternalObjectConverter.normalizeDataValue("A_VAL", DataUtil.STRING));
            
            // OBJECT should accept anything
            var now:Date = new Date();
            assertEquals(now, ExternalObjectConverter.normalizeDataValue(now, DataUtil.OBJECT));
            assertEquals("A_VAL", ExternalObjectConverter.normalizeDataValue("A_VAL", DataUtil.OBJECT));
            assertEquals(10, ExternalObjectConverter.normalizeDataValue(10, DataUtil.OBJECT));
            assertEquals(10.4, ExternalObjectConverter.normalizeDataValue(10.4, DataUtil.OBJECT));
            assertEquals(true, ExternalObjectConverter.normalizeDataValue(true, DataUtil.OBJECT));
            
            // Truncate a Number to int:
            assertEquals(2, ExternalObjectConverter.normalizeDataValue(2.95, DataUtil.INT));
            
            // This types accept NULL:
            assertNull(ExternalObjectConverter.normalizeDataValue(undefined, DataUtil.STRING));
            assertNull(ExternalObjectConverter.normalizeDataValue(undefined, DataUtil.OBJECT));
            assertNull(ExternalObjectConverter.normalizeDataValue(undefined, DataUtil.NUMBER));
            
            // Test invalid values:
            
            // INT
            try {
                ExternalObjectConverter.normalizeDataValue(null, DataUtil.INT);
                fail("Should throw Error when setting null to 'int' field!");
            } catch (err:CWError) { }
            try {
                ExternalObjectConverter.normalizeDataValue('', DataUtil.INT);
                fail("Should throw Error when setting empty string to 'int' field!");
            } catch (err:CWError) { }
            try {
                ExternalObjectConverter.normalizeDataValue('0', DataUtil.INT);
                fail("Should throw Error when setting string to 'int' field!");
            } catch (err:CWError) { }
            try {
                ExternalObjectConverter.normalizeDataValue(false, DataUtil.INT);
                fail("Should throw Error when setting boolean to 'int' field!");
            } catch (err:CWError) { }
            try {
                ExternalObjectConverter.normalizeDataValue({}, DataUtil.INT);
                fail("Should throw Error when setting object to 'int' field!");
            } catch (err:CWError) { }
            
            // BOOLEAN
            try {
                ExternalObjectConverter.normalizeDataValue(null, DataUtil.BOOLEAN);
                fail("Should throw Error when setting null to 'boolean' field!");
            } catch (err:CWError) { }
            try {
                ExternalObjectConverter.normalizeDataValue('', DataUtil.BOOLEAN);
                fail("Should throw Error when setting empty string to 'boolean' field!");
            } catch (err:CWError) { }
            try {
                ExternalObjectConverter.normalizeDataValue('false', DataUtil.BOOLEAN);
                fail("Should throw Error when setting string to 'boolean' field!");
            } catch (err:CWError) { }
            try {
                ExternalObjectConverter.normalizeDataValue(0, DataUtil.BOOLEAN);
                fail("Should throw Error when setting number to 'boolean' field!");
            } catch (err:CWError) { }
            try {
                ExternalObjectConverter.normalizeDataValue({}, DataUtil.BOOLEAN);
                fail("Should throw Error when setting object to 'boolean' field!");
            } catch (err:CWError) { }
            
            // NUMBER
            try {
                ExternalObjectConverter.normalizeDataValue('0', DataUtil.NUMBER);
                fail("Should throw Error when setting string to 'number' field!");
            } catch (err:CWError) { }
            try {
                ExternalObjectConverter.normalizeDataValue(false, DataUtil.NUMBER);
                fail("Should throw Error when setting boolean to 'number' field!");
            } catch (err:CWError) { }
            try {
                ExternalObjectConverter.normalizeDataValue({}, DataUtil.NUMBER);
                fail("Should throw Error when setting object to 'number' field!");
            } catch (err:CWError) { }
        }

        public function testConvertToDataSet():void {
            // Empty networks:
            // --------------------------------------------------------------
            var network:*, ds:DataSet, ns:DataSchema, es:DataSchema, nodes:Array, nd:Array, ed:Array;
            
            var networks:Array = [ null, 
                                  {},
                                  { schema: {}, data: {} },
                                  { schema: { nodes: [], edges: [] }, data: { nodes: [], edges: [] } } 
                                 ];
            
            for each (network in networks) {
                ds = ExternalObjectConverter.convertToDataSet(network);
                assertMinNodesSchema(ds.nodes.schema);
                assertMinEdgesSchema(ds.edges.schema);
                assertEmptyGraph(ds);
            }
        
            // A simple network:
            // --------------------------------------------------------------
            var now:Date = new Date();
            
            network = {
                dataSchema: {
                    nodes: [
                        { name: "id", type: "number" }, // WRONG! Should be string and will be ignored
                        { name: "label", type: "string" },
                        { name: "score", type: "number", defValue: -1 },
                        { name: "ranking", type: "int" },
                        { name: "date", type: "object", defValue: now }
                    ],
                    edges: [
                        { name: "source", type: "string", defValue: "1" },    // Should ignore defValue
                        { name: "directed", type: "boolean", defValue: true }, // Not mandatory, but should use defValue
                        { name: "weight", type: "number" }
                    ]
                },
                data: {
                    nodes: [
                        { id: "1", label: "Node 1", score: 1.11, date: new Date(2010, 1, 1) },
                        { id: "2", label: "Node 2", score: 2.22 },
                        { id: "3", label: "Node 3", score: 3.33 }
                    ],
                    edges: [
                        { id: "e1", source: "1", target: "2", weight: 0.5 },
                        { id: "e2", source: "2", target: "3", weight: 0.5 },
                        { id: "e3", source: "3", target: "3", weight: 0.25, directed: false }
                    ]
                }
            };
            
            ds = ExternalObjectConverter.convertToDataSet(network);
            
            // Test schema:
            // --------------------
            ns = ds.nodes.schema;
            es = ds.edges.schema;
            
            // Nodes Schema:
            assertMinNodesSchema(ns);
            
            assertEquals(DataUtil.NUMBER, ns.getFieldByName("score").type);
            assertEquals(-1, ns.getFieldByName("score").defaultValue);
            
            assertEquals(DataUtil.INT, ns.getFieldByName("ranking").type);
            assertEquals(0, ns.getFieldByName("ranking").defaultValue);
            
            assertEquals(DataUtil.STRING, ns.getFieldByName("label").type);
            assertTrue(null === ns.getFieldByName("label").defaultValue);
            
            assertEquals(DataUtil.OBJECT, ns.getFieldByName("date").type);
            assertTrue(now === ns.getFieldByName("date").defaultValue);
            
            // Edges schema
            assertMinEdgesSchema(es, true);
            
            assertTrue(null === es.getFieldByName(DataSchemaUtils.SOURCE).defaultValue);
            
            assertEquals(DataUtil.NUMBER, es.getFieldByName("weight").type);
            assertTrue(null === es.getFieldByName("weight").defaultValue);
            
            assertEquals(DataUtil.BOOLEAN, es.getFieldByName(DataSchemaUtils.DIRECTED).type);
            
            // Test Data:
            // --------------------
            nd = ds.nodes.data;
            ed = ds.edges.data;
            
            assertEquals(network.data.nodes.length, nd.length);
            assertEquals(network.data.edges.length, ed.length);
            
            for each (var n:Object in nd) {
                if (n is NodeSprite) n = n.data;
                assertTrue(n.id is String);
                assertTrue(n.label is String);
                assertTrue(n.score is Number);
                assertTrue(n.ranking is int);
                assertTrue(n.date is Date);
                assertEquals((n.id !== "1"), (n.date == now));
            }
            for each (var e:Object in ed) {
                assertTrue(e.id is String);
                assertTrue(e.weight is Number);
                assertTrue(e.directed is Boolean);
                assertEquals(e.id !== "e3", e.directed);
            }
        }
        
        public function testToExtObject():void {
            var data:Data = Fixtures.getData(Fixtures.GRAPHML_SIMPLE);
            var o:Object, k:*;
            
            // NODES
            var props:Array = ["data","shape","borderColor","borderWidth","opacity","visible","color",
                               "x","y","rawX","rawY","size","width","height","zIndex"/*, "degree", "indegree", "outdegree"*/];
            var attrs:Array = ["id","parent"];
            
            for each (var n:NodeSprite in data.nodes) {
                o = ExternalObjectConverter.toExtElement(n, 1);
                assertEquals(Groups.NODES, o.group);
                
                for each (k in props) assertTrue("Node property: " + k, o.hasOwnProperty(k));
                for each (k in attrs) assertTrue("Node data attribute: " + k, + o.data.hasOwnProperty(k));
                
                assertEquals(n.data.id, o.data.id);
            }
            
            // EDGES
            props = ["data","color","width","opacity","visible","sourceArrowShape","targetArrowShape",
                     "sourceArrowColor","targetArrowColor","curvature","merged","zIndex"];
            attrs = ["id","source","target","directed"];
            
            for each (var e:EdgeSprite in data.edges) {
                o = ExternalObjectConverter.toExtElement(e, 1);
                assertEquals(Groups.EDGES, o.group);
                
                for each (k in props) assertTrue("Edge property: " + k, o.hasOwnProperty(k));
                for each (k in attrs) assertTrue("Edge data attribute: " + k, o.data.hasOwnProperty(k));
                
                assertEquals(e.data.id, o.data.id);
                assertEquals(e.source.data.id, o.data.source);
                assertEquals(e.target.data.id, o.data.target);
            }
        }
        
        private function assertMinNodesSchema(s:DataSchema):void {
            assertEquals(DataUtil.STRING, s.getFieldByName(DataSchemaUtils.ID).type);
        }
        
        private function assertMinEdgesSchema(s:DataSchema, directed:Boolean=false):void {
            assertEquals(DataUtil.STRING, s.getFieldByName(DataSchemaUtils.ID).type);
            assertEquals(DataUtil.STRING, s.getFieldByName(DataSchemaUtils.SOURCE).type);
            assertEquals(DataUtil.STRING, s.getFieldByName(DataSchemaUtils.TARGET).type);
            assertEquals(DataUtil.BOOLEAN, s.getFieldByName(DataSchemaUtils.DIRECTED).type);
            assertEquals(directed, s.getFieldByName(DataSchemaUtils.DIRECTED).defaultValue);
        }
        
        private function assertEmptyGraph(ds:DataSet):void {
            assertEquals(0, ds.nodes.data.length);
            assertEquals(0, ds.edges.data.length);
        }
    }
}