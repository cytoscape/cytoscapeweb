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
    import flare.vis.data.Data;
    import flare.vis.data.EdgeSprite;
    import flare.vis.data.NodeSprite;
    
    import flexunit.framework.TestCase;
    
    import org.cytoscapeweb.fixtures.Fixtures; 
    
    public class GraphUtilsTest extends TestCase {
        
        // ========[ TESTS ]========================================================================
        
        public function testToExtObject():void {
            var data:Data = Fixtures.getData(Fixtures.GRAPHML_SIMPLE);
            var o:Object;
            
            var props:Array = ["data","shape","borderColor","borderWidth","opacity","visible",
                                "color","x","y"];
            
            for each (var n:NodeSprite in data.nodes) {
                o = GraphUtils.toExtObject(n);
                assertEquals(Groups.NODES, o.group);
                
                for each (var k:* in props) assertTrue(o.hasOwnProperty(k));
                assertEquals(n.data.id, o.data.id);
            }
            
            props = ["data","color","width","opacity","visible",
                     "directed","sourceArrowShape","targetArrowShape",
                     "sourceArrowColor","targetArrowColor",
                     "curvature","merged"];
            
            for each (var e:EdgeSprite in data.edges) {
                o = GraphUtils.toExtObject(e);
                assertEquals(Groups.EDGES, o.group);
                
                for each (k in props) assertTrue(o.hasOwnProperty(k));
                assertEquals(e.data.id, o.data.id);
                assertEquals(e.source.data.id, o.data.source);
                assertEquals(e.target.data.id, o.data.target);
            }
        }
    }
}
