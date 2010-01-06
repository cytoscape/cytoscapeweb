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
    
    import flare.vis.data.Data;
    import flare.vis.data.EdgeSprite;
    import flare.vis.data.NodeSprite;
    
    import flexunit.framework.AssertionFailedError;
    import flexunit.framework.TestCase;
    
    import org.cytoscapeweb.fixtures.Fixtures;
    
    
    public class FirstNeighborsVOTest extends TestCase {
        
        // ========[ PRIVATE PROPERTIES ]===========================================================
        
        private var _data:Data;
        private var _fn:FirstNeighborsVO;
        private var _roots:Array;
        
        // ========[ PUBLIC METHODS ]===============================================================
        
        override public function setUp():void {
            _data = Fixtures.getData(Fixtures.GRAPHML_SIMPLE);
            _roots = [];
        }
        
        public function testFailWithNoRoot():void {
            try {
                _fn = new FirstNeighborsVO(null);
                fail("FirstNeighborsVO should not accept null as rootNodes!");
            } catch (err:Error) {
                if (err is AssertionFailedError) throw err;
            }
            try {
                _fn = new FirstNeighborsVO([]);
                fail("FirstNeighborsVO should not accept empty array as rootNodes!");
            } catch (err:Error) {
                if (err is AssertionFailedError) throw err;
            }
        }
        
        public function testOneRoot():void {
            _data.visit(function(n:NodeSprite):Boolean {
                if (n.data.id === "8") _roots.push(n);
                return false
            }, Data.NODES);
            _fn = new FirstNeighborsVO(_roots);
            assertCorrectFirstNeighbors(1, 5, 8, 5);
        }
        
        public function testMoreThanOneRoot():void {
            _data.visit(function(n:NodeSprite):Boolean {
                if (n.data.id === "2" || n.data.id === "7") {
                    _roots.push(n);
                    _roots.push(n); // Let's push twice to test if FirstNeighborsVO will handle it!
                }
                return false
            }, Data.NODES);
            _fn = new FirstNeighborsVO(_roots);
            assertCorrectFirstNeighbors(2, 3, 8, 5);
        }
        
        // ========[ PRIVATE METHODS ]==============================================================
        
        private function assertCorrectFirstNeighbors(nRoots:int, nNeighbors:int, nEdges:int, nMergedEdges:int):void {
            // Test neighbor nodes and edges:
            assertEquals(nNeighbors, _fn.neighbors.length);
            assertEquals(nEdges, _fn.edges.length);
            // TODO: test merged edges:
            //assertEquals(nMergedEdges, _fn.mergedEdges.length);
            
            _roots = _fn.rootNodes;
            for each (n in _roots) {
                assertFalse(_fn.isFirstNeighbor(n));
                n.visitEdges(function(e:EdgeSprite):Boolean {
                    assertTrue(_fn.hasDataSprite(e));
                    assertTrue(_fn.hasDataSprite(e.source));
                    assertTrue(_fn.hasDataSprite(e.target));
                    return false;
                }, NodeSprite.GRAPH_LINKS);
            }
            for each (n in _fn.neighbors) {
                assertTrue(_fn.isFirstNeighbor(n));
                assertFalse(_fn.isRoot(n));
            }
            
            // Test roots:
            assertEquals(nRoots, _fn.rootNodes.length);
            assertTrue(_fn.hasSameRoot(_roots));
            assertFalse(_fn.hasSameRoot(null));
            assertFalse(_fn.hasSameRoot([]));
            assertFalse(_fn.hasSameRoot([_fn.neighbors[0]]));
            assertFalse(_fn.hasSameRoot([_roots[0], _fn.neighbors[0]]));
            
            var n:NodeSprite;
            for each (n in _roots) assertTrue(_fn.isRoot(n));
        }
    }
}
