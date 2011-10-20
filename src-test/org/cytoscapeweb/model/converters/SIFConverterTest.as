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
    
    import flare.data.DataField;
    import flare.data.DataSchema;
    import flare.data.DataSet;
    import flare.data.DataUtil;
    import flare.vis.data.Data;
    import flare.vis.data.EdgeSprite;
    import flare.vis.data.NodeSprite;
    
    import flash.utils.ByteArray;
    import flash.utils.IDataOutput;
    
    import flexunit.framework.TestCase;
    
    import org.cytoscapeweb.fixtures.Fixtures;
    
    public class SIFConverterTest extends TestCase {
     
        public function testRead():void {
            var toTest:Array = [Fixtures.SIF_TABS, Fixtures.SIF_SPACES];
            var id:String;
            
            for each (var fixture:Class in toTest) {
                var input:ByteArray = new (fixture)() as ByteArray;
                
                var converter:SIFConverter = new SIFConverter();
                var ds:DataSet = converter.read(input);
                
                // Test schemas:
                var nodeAttrs:Array = ["id", "label"];
                var edgeAttrs:Array = ["id", "label", "interaction", "directed", "source", "target"];
                
                testSchema(ds.nodes.schema, nodeAttrs);
                testSchema(ds.edges.schema, edgeAttrs);
                
                // Test nodes/edges data:
                var nodesData:Array = ds.nodes.data;
                var edgesData:Array = ds.edges.data;
                
                assertEquals(7, nodesData.length);
                assertEquals(8, edgesData.length);
                
                var tuple:Object;
                var nodesMap:Object = {}, edgesMap:Object = {};
                var sif:String = Fixtures.getFixtureAsString(fixture);
                
                // Nodes:
                for each (tuple in nodesData) {
                    if (tuple is NodeSprite) tuple = tuple.data;
                    nodesMap[tuple.id] = tuple;
                    assertEquals(tuple.id, tuple.label);
                    // Each node data must have come from the SIF file:
                    assertTrue(sif.indexOf(tuple.id) !== -1);
                }
                // To verify duplicated nodes, which would be incorrect:
                var count:int = 0;
                for (var k:String in nodesMap) { count++; }
                assertEquals(count, nodesData.length);
                
                // The same for edges:
                for each (tuple in edgesData) {
                    if (tuple is EdgeSprite) tuple = tuple.data;
                    id = tuple.source + " (" + tuple.interaction + ") " + tuple.target;
                    assertEquals(id, tuple.id);
                    assertNotNull(tuple.interaction);
                    assertEquals(tuple.interaction, tuple.label);
                    assertFalse(tuple.directed);
                    edgesMap[id] = tuple;
                }

                count = 0;
                for (k in edgesMap) { count++; }
                assertEquals(count, edgesData.length);
            }
        }
        
        public function testWriteWithDefaultFields():void {
            var ds:DataSet = Fixtures.getDataSet(Fixtures.GRAPHML_SIMPLE);
            var data:Data = Data.fromDataSet(ds);
            var nodes:Array = data.nodes.toDataArray();
            var edges:Array = data.edges.toDataArray();
            var n:Object, e:Object;

            var out:IDataOutput = new SIFConverter().write(ds);
            var sif:String = "" + out;
            
            // Does the generated SIF contain all nodes and edges?
            for each (n in nodes) {
                assertTrue("Missing node: " + n.id, sif.indexOf(n.id) > -1);
            }
            for each (e in edges) {
                var inter:String = e.hasOwnProperty("interaction") ? e.interaction : e.id;
                var line:String = e.source + "\t" + inter + "\t" + e.target;
                assertTrue("Missing line: " + line, sif.indexOf(line) > -1);
            }
            
            // If we parse the SIF file again, will it generate the same graph?
            var ds2:DataSet = new SIFConverter().parse(sif);
            var data2:Data = Data.fromDataSet(ds2);
            var nodes2:Array = data2.nodes.toDataArray();
            var edges2:Array = data2.edges.toDataArray();
            
            assertEquals(nodes.length, nodes2.length);
            assertEquals(edges.length, edges2.length);
        }
        
        public function testWriteWithCustomFields():void {
            var ds:DataSet = Fixtures.getDataSet(Fixtures.GRAPHML_SIMPLE);
            var data:Data = Data.fromDataSet(ds);
            var nodes:Array = data.nodes.toDataArray();
            var edges:Array = data.edges.toDataArray();
            var n:Object, e:Object;

            var out:IDataOutput = new SIFConverter().write(ds);
            var sif:String = "" + out;
            
            // Does the generated SIF contain all nodes and edges?
            for each (n in nodes) {
                assertTrue("Missing node: " + n.id, sif.indexOf(n.id) > -1);
            }
            
            // If we parse the SIF file again, will it generate the same graph?
            var ds2:DataSet = new SIFConverter().parse(sif);
            var data2:Data = Data.fromDataSet(ds2);
            var nodes2:Array = data2.nodes.toDataArray();
            var edges2:Array = data2.edges.toDataArray();
            
            assertEquals(nodes.length, nodes2.length);
            assertEquals(edges.length, edges2.length);
        }
        
        // ========[ PRIVATE METHODS ]==============================================================
        
        private function testSchema(schema:DataSchema, attrNames:Array):void {
            for each (var attr:String in attrNames) {
                var field:DataField = schema.getFieldByName(attr);
                assertNotNull(field);   
                
                if (attr === "directed") {
                    assertEquals(field.type, DataUtil.BOOLEAN);
                    assertEquals(field.defaultValue, false);
                } else {
                    assertEquals(field.type, DataUtil.STRING);
                    assertNull(field.defaultValue);
                }
            }
        }
    }
}