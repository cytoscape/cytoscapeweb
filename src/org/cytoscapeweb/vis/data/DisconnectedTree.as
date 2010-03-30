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
package org.cytoscapeweb.vis.data {
    import flare.vis.data.EdgeSprite;
    import flare.vis.data.NodeSprite;
    import flare.vis.data.Tree;
    
    import org.cytoscapeweb.util.GraphUtils;
        
    /**
     * Data structure for managing a collection of visual data objects in a
     * tree (hierarchy) structure.
     * This version was created to handle disconnected components.
     */
    public class DisconnectedTree extends Tree {

        /** @inheritDoc */
        public override function addChild(p:NodeSprite, c:NodeSprite=null):NodeSprite {           
            if (GraphUtils.isFilteredOut(p))
                throw new ArgumentError("Parent node cannot be filtered out!");
            return super.addChild(p, c);
        }
        
        /** @inheritDoc */
        public override function addChildEdge(e:EdgeSprite):EdgeSprite {
            if (GraphUtils.isFilteredOut(e))
                throw new ArgumentError("Edge cannot be filtered out!");
            return super.addChildEdge(e);
        }
        
//        /** @inheritDoc */
//        public override function removeNode(n:NodeSprite):Boolean {
//            if (n==_root) {
//                clear(); return true;
//            } else {
//                return removeEdge(parentEdge(n));
//            }
//        }
//        
//        /** @inheritDoc */
//        public override function removeEdge(e:EdgeSprite):Boolean {
//            if (e==null || !_edges.contains(e)) return false;
//            
//            // disconnect tree
//            var c:NodeSprite = (parentNode(e.target) == e.source ? e.target : e.source);
//            var p:NodeSprite = parentNode(c);
//            var i:int = c.parentIndex;
//            p.removeChildEdge(e);
//            
//            // walk disconnected segment to fire updates
//            c.visitTreeDepthFirst(function(n:NodeSprite):void {
//                _edges.remove(parentEdge(n));
//                _nodes.remove(n);
//            });
//            _edges.remove(e);
//            
//            // update parent index values
//            for (; i < childDegree(p); ++i) {
//                childNode(p, i).parentIndex = i;
//            }
//            return true;    
//        }
        
//        /** @inheritDoc */
//        public override function countLeaves():int {
//            var leaves:int = 0;
//            for each (var ns:NodeSprite in nodes) {
//                if (childDegree(ns) == 0) ++leaves;
//            }
//            return leaves;
//        }

//        /** @inheritDoc */
//        public override function swapWithParent(n:NodeSprite):void {
//            var p:NodeSprite = parentNode(n), gp:NodeSprite;
//            var e:EdgeSprite, ge:EdgeSprite, idx:int;
//            if (p==null) return;
//            
//            gp = parentNode(p);
//            ge = parentEdge(p);
//            idx = p.parentIndex;
//            
//            // swap parent edge
//            e = parentEdge(n);
//            p.removeChild(n);
//            p.parentEdge = e;
//            p.parentIndex = n.addChildEdge(e);
//            
//            // connect to grandparents
//            if (gp==null) {
//                n.parentIndex = -1;
//                n.parentEdge = null;
//            } else {
//                if (ge.source == gp) {
//                    ge.target = n;
//                } else {
//                    ge.source = n;
//                }
//                n.parentIndex = idx;
//                n.parentEdge = ge;
//            }
//        }
        
        // -----------------------------------------------------------------------------------------
        
//        private var _treeParams:/*node->Object*/Object;
        
//        private function setTreeParams():void {
//            _treeParams = {};
//            for each (var n:NodeSprite in nodes) {
//                _treeParams[n] = {};
//                _treeParams[n].childEdges = [];
//                
//                var cd:uint = 0;
//                n.visitEdges(function(e:EdgeSprite):Boolean {
//                   if (!GraphUtils.isFilteredOut(e)) {
//                       _treeParams[n].childEdges.push(e);
//                       cd++;
//                   }
//                   return false; 
//                }, NodeSprite.CHILD_LINKS);
//            }
//        }
        
        public function childEdges(n:NodeSprite):Array {
            var edges:Array = [];
            
            if (n != null) {
                n.visitEdges(function(e:EdgeSprite):Boolean {
                   if (!GraphUtils.isFilteredOut(e)) {
                       edges.push(e);
                   }
                   return false; 
                }, NodeSprite.CHILD_LINKS);
            }

            return edges;
        }
        
        public function childDegree(n:NodeSprite):uint {
            return childEdges(n).length;
        }
        
        /** The previous sibling of this node in the tree structure. */
        public function prevNode(n:NodeSprite):NodeSprite {
            var p:NodeSprite = parentNode(n), i:int = n.parentIndex-1;
            if (p == null || GraphUtils.isFilteredOut(p) || i < 0) return null;
            var c:NodeSprite = childNode(p, i);
            if (c === n || c === p) c = null;
            return c;
        }
        
        /** The next sibling of this node in the tree structure. */
        public function nextNode(n:NodeSprite):NodeSprite {
            var p:NodeSprite = parentNode(n), i:int = n.parentIndex+1;
            if (p == null || GraphUtils.isFilteredOut(p) || i > childDegree(p)) return null;
            var c:NodeSprite = childNode(p, i);
            if (c === n || c === p) c = null;
            return c;         
        }
        
        /** Gets the child node at the specified position */
        public function childNode(n:NodeSprite, i:uint):NodeSprite {
            var edges:Array = childEdges(n);
            var other:NodeSprite;
            if (edges != null && edges.length > i) other = edges[i].other(n);
            if (other === n) other = null;
            if (other != null && GraphUtils.isFilteredOut(other)) other = null;
            return other;
        }
        public function childEdge(n:NodeSprite, i:uint):EdgeSprite {
            var edges:Array = childEdges(n);
            var e:EdgeSprite;
            if (edges != null && edges.length > i) e = edges[i];
            if (e != null && GraphUtils.isFilteredOut(e)) e = null;
            return e;
        }
        
        public function parentNode(n:NodeSprite):NodeSprite {
            var e:EdgeSprite = parentEdge(n);
            var other:NodeSprite;
            if (e != null) other = e.other(n);
            if (other === n) other = null;
            if (other != null && GraphUtils.isFilteredOut(other)) other = null;
            return other;
        }
        
        public function parentEdge(n:NodeSprite):EdgeSprite {
            var e:EdgeSprite = n.parentEdge;
            if (e != null && GraphUtils.isFilteredOut(e)) e = null;
            return e;
        }
        
        /** The first child of this node in the tree structure. */
        public function firstChildNode(n:NodeSprite):NodeSprite {
            return childDegree(n) > 0 ? childEdges(n)[0].other(n) : null;
        }
        
        /** The last child of this node in the tree structure. */
        public function lastChildNode(n:NodeSprite):NodeSprite {
            var len:uint = childDegree(n);
            return len > 0 ? childEdges(n)[len-1].other(n) : null;
        }

    }
}