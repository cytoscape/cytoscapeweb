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
    import flare.data.DataField;
    import flare.data.DataSchema;
    import flare.data.DataUtil;
    import flare.vis.data.Data;
    import flare.vis.data.EdgeSprite;
    import flare.vis.data.NodeSprite;
    
    import flexunit.framework.TestCase;
    
    import org.cytoscapeweb.util.DataSchemaUtils;
    
    
    public class InteractionVOTest extends TestCase {
        
        // ========[ PRIVATE PROPERTIES ]===========================================================
        
        private var data:Data;
        private var src:NodeSprite;
        private var tgt:NodeSprite;
        private var edge1:EdgeSprite;
        private var edge2:EdgeSprite;
        private var edge3:EdgeSprite;
        private var interaction:InteractionVO;
        private var edgesSchema:DataSchema;
        // ========[ PUBLIC METHODS ]===============================================================
        
        override public function setUp():void {
            data = new Data(false);
            
            src = data.addNode({ id: "n1" });
            tgt = data.addNode({ id: "n2" });
            
            edge1 = data.addEdgeFor(src, tgt, true, { id: "e1", source: "n1", target: "n2", directed: true,
                                                      s: "a", i: 1, n: 0.5, b: false });
            edge2 = data.addEdgeFor(src, tgt, false, { id: "e2", source: "n1", target: "n2", directed: false,
                                                       s: "b", i: 2, n: 1.5, b: true });
            edge3 = data.addEdgeFor(tgt, src, true, { id: "e3", source: "n2", target: "n1", directed: true });
            
            edgesSchema = DataSchemaUtils.minimumEdgeSchema();
            edgesSchema.addField(new DataField("s", DataUtil.STRING));
            edgesSchema.addField(new DataField("i", DataUtil.INT));
            edgesSchema.addField(new DataField("n", DataUtil.NUMBER));
            edgesSchema.addField(new DataField("b", DataUtil.BOOLEAN));
            
            interaction = new InteractionVO(src, tgt, edgesSchema);
        }
        
        public function testGetKey():void {
            var key1:String = InteractionVO.createKey(src, tgt);
            var key2:String = InteractionVO.createKey(tgt, src);
            
            assertNotNull(key1);
            assertEquals(key1, key2);
            assertEquals(key1, interaction.key);
        }
        
        public function testGetNodes():void {
            assertEquals(src, interaction.node1);
            assertEquals(tgt, interaction.node2);
        }
        
        public function testGetEdges():void {
            assertEquals(3, interaction.edges.length);
        }
        
        public function testGetMergedEdge():void {
            var me:EdgeSprite = interaction.mergedEdge;
            
            assertTrue(me.props.$merged);
            assertEquals(3, me.props.$edges.length);
            assertEquals(3, me.props.$getFilteredEdges().length);
        }
        
        public function testCurvatureFactors():void {
            assertEquals(0, edge1.props.$curvatureFactor);
            assertEquals(-1, edge2.props.$curvatureFactor);
            assertEquals(-1, edge3.props.$curvatureFactor); // would be +1, but it is inverted (tgt->src)
        }
        
        public function testIsLoop():void {
            assertFalse(interaction.loop);
            interaction = new InteractionVO(src, src, edgesSchema);
            assertTrue(interaction.loop);
        }
        
        public function testHasNodes():void {
            assertTrue(interaction.hasNodes(tgt, src));
            assertTrue(interaction.hasNodes(src, tgt));
            assertFalse(interaction.hasNodes(src, src));
            assertFalse(interaction.hasNodes(tgt, tgt));
        }
        
        public function testGetMergedEdgeData():void {
            var me:EdgeSprite = interaction.mergedEdge;
            
            // should never be merged
            assertNull(me.data.id); // not created yet
            assertTrue(me.data.source is String);
            assertTrue(me.data.target is String);
            assertFalse(me.data.directed); // always undirected
            
            // s
            assertStrictlyEquals(null, me.data.s[0]);
            assertEquals("a", me.data.s[1]);
            assertEquals("b", me.data.s[2]);
            // i
            assertEquals(3, me.data.i);
            // n
            assertEquals(2.0, me.data.n);
            // b
            assertTrue(me.data.b);
        }
        
        public function testUpdateMergedEdgeData():void {
            var me:EdgeSprite = interaction.mergedEdge;
            
            edge3.data.s = "c";
            edge3.data.i = 2;
            edge2.data.b = false;
            
            interaction.update(edgesSchema);
            
            assertEquals("c", me.data.s[0]);
            assertEquals(5, me.data.i);
            assertFalse(me.data.b);
        }
    }
}