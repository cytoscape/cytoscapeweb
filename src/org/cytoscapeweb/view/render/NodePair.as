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
package org.cytoscapeweb.view.render {
	import flare.vis.data.EdgeSprite;
	import flare.vis.data.NodeSprite;
	
	public class NodePair {
		
		private var _key:String;
		private var _node1:NodeSprite;
		private var _node2:NodeSprite;
		private var _mergedEdge:EdgeSprite;
		private var _edges:Array;
		private var _edgeIndexes:Array;
		
        // =========================================================================================
		
		public function NodePair(node1:NodeSprite, node2:NodeSprite) {
		    this._key = NodePair.createKey(node1, node2);
			this._node1 = node1;
			this._node2 = node2;
			this._edges = new Array();
			this._edgeIndexes = new Array();
		}
		
        // ========[ PUBLIC METHODS ]===============================================================
		
		public function get key():String {
			return this._key;
		}
		
		public function get node1():NodeSprite {
			return this._node1;
		}
		
		public function get node2():NodeSprite {
			return this._node2;
		}
		
		public function get edges():Array {
			return this._edges;
		}
		
		public function addEdge(edge:EdgeSprite):void {
			if (edge != null) {
				this._edges.push(edge);
				this.calculateEdgeAdjacentIndexes(edge);
			}
		}
		
		/**
		 * Return the distance that the informed edge has from an imaginary straight line that
		 * links two nodes by their centers.
		 */
		public function getAdjacentIndex(edge:EdgeSprite):Number {
            for each (var arr:Array in _edgeIndexes) {
                if (arr[0] == edge) {
                    var idx:Number = arr[1];
                    
                    // If the number of edges is even, we have to subtract 0.5
                    // to avoid a larger gap in the middle
                    var corection:Number = idx > 0 ? -0.5 : 0.5;
                    idx = (_edges.length%2 != 0) ? idx : idx + corection;
                    
                    return idx;
                }
            }
            
            return -1;
		}
		
		public function hasNodes(node1:NodeSprite, node2:NodeSprite):Boolean {
			return (this._node1 == node1 && this._node2 == node2) || (this._node1 == node2 && this._node2 == node1);
		}
		
		public static function createKey(node1:NodeSprite, node2:NodeSprite):String {
		    var id1:* = node1.data.id;
		    var id2:* = node2.data.id;
		    var key:String = id1 < id2 ? id1+"::"+id2 : id2+"::"+id1;
		    
		    return key;
	    }

        // ========[ PRIVATE METHODS ]==============================================================
		
        private function calculateEdgeAdjacentIndexes(newEdge:EdgeSprite):void {
            // First, how many edges does this pair of nodes have?
            var count:int = _edgeIndexes.length;

            if (count == 0) {
                // We assume that the first edge has NO gap:
                _edgeIndexes[0] = [newEdge, 0, newEdge.source];
            } else if (count%2 == 0) {
            	// It is NOT the first edge, but so far we had the quantity of added edges are even.
            	// This new edge will make it odd, so we just need to add it in the middle
            	// of the previous ones, in the center:
            	_edgeIndexes.unshift([newEdge, 0, newEdge.source]);
            } else {
                // It is NOT the first edge and it will make it a set of even edges, after added.
                // So we get the edge that was in the middle (idx == 0) and put it in one side:
                var arr1:Array = _edgeIndexes[0];
                var idx1:Number = (count+1)/2;
                
                arr1[1] = idx1;
                
                // Now we put the new edge in the other side. But in order to make the EdgeRenderer
                // render them symmetrically, we need to know whether or not they have the same
                // source node...
                var src1:NodeSprite = arr1[2] as NodeSprite;
                var src2:NodeSprite = newEdge.source;
                
                var idx2:Number = (src1 == src2 ? idx1 * -1 : idx1);
	            
	            _edgeIndexes.push([newEdge, idx2, src2]);
            }
		} 
	}
}