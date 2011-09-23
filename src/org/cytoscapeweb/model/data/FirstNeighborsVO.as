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
    import flare.vis.data.DataSprite;
    import flare.vis.data.EdgeSprite;
    import flare.vis.data.NodeSprite;
    
    import org.cytoscapeweb.model.converters.ExternalObjectConverter;
    import org.cytoscapeweb.util.GraphUtils;
    

    public class FirstNeighborsVO {
        
        // ========[ CONSTANTS ]====================================================================

        // ========[ PRIVATE PROPERTIES ]===========================================================

        private var _rootNodes:/*NodeSprite*/Array = [];
        private var _neighbors:/*NodeSprite*/Array = [];
        private var _edges:/*EdgeSprite*/Array = [];
        private var _mergedEdges:/*EdgeSprite*/Array = [];
        private var _map:/*DataSprite->Boolean*/Object = {};

        // ========[ PUBLIC PROPERTIES ]============================================================
        
        /**
         * @return Array of NodeSprite objects that are root nodes.
         */
        public function get rootNodes():Array {
            return _rootNodes;
        }
        
        /**
         * @return Array of NodeSprite objects that are first neighbors (except root nodes).
         */
        public function get neighbors():Array {
            return _neighbors
        }
        
        /**
         * @return Array of EdgeSprite objects that links the neighbor nodes to one or more
         *         root nodes.
         */
        public function get edges():Array {
            return _edges;
        }
        
        /**
         * @return Array of "merged" EdgeSprite objects that links the neighbor nodes to one or more
         *         root nodes.
         */
        public function get mergedEdges():Array {
            return _mergedEdges;
        }

        // ========[ CONSTRUCTOR ]==================================================================
        
        public function FirstNeighborsVO(roots:/*NodeSprite*/Array, ignoreFilteredOut:Boolean=false) {
            if (roots == null || roots.length === 0)
                throw Error("The root nodes must be informed.");
            
            for each (var r:NodeSprite in roots) {
                // Add root nodes first:
                if (_map[r] === undefined && !(ignoreFilteredOut && GraphUtils.isFilteredOut(r))) {
                    // true indicates it's a root node!
                    _map[r] = true;
                    _rootNodes.push(r);
                }
            }
            for each (var n:NodeSprite in _rootNodes) {    
                n.visitEdges(function(e:EdgeSprite):Boolean {
                    if (_map[e] === undefined && !(ignoreFilteredOut && GraphUtils.isFilteredOut(e))) {
                        _map[e] = false;
                        
                        if (_map[e.source] === undefined) {
                            _map[e.source] = false;
                            _neighbors.push(e.source);
                        }
                        if (_map[e.target] === undefined) {
                            _map[e.target] = false;
                            _neighbors.push(e.target);
                        }
                        
                        if (e.props.$merged) {
                            _mergedEdges.push(e);
                        } else {
                            _edges.push(e);
                        }
                    }
                    return false;
                }, NodeSprite.GRAPH_LINKS);
            }
        }
        
        // ========[ PUBLIC METHODS ]===============================================================
        
        public function hasDataSprite(ds:DataSprite):Boolean {
            return _map[ds] !== undefined;
        }
        
        public function hasSameRoot(nodes:Array):Boolean {
            var same:Boolean = true;
            
            if (nodes == null || nodes.length === 0) {
                same = false;
            } else {
                for each (var n:NodeSprite in nodes) {
                    if (!_map[n]) {
                        same = false;
                        break;
                    }
                }
            }
            
            return same;
        }
        
        public function isRoot(n:NodeSprite):Boolean {
            return _map[n] === true;
        }
        
        public function isFirstNeighbor(n:NodeSprite):Boolean {
            return _map[n] === false;
        }
        
        public function toObject(zoom:Number):Object {
            var obj:Object = {};
            
            obj.rootNodes = ExternalObjectConverter.toExtElementsArray(rootNodes, zoom);
            obj.neighbors = ExternalObjectConverter.toExtElementsArray(neighbors, zoom);
            obj.edges = ExternalObjectConverter.toExtElementsArray(edges, zoom);
            obj.mergedEdges = ExternalObjectConverter.toExtElementsArray(mergedEdges, zoom);
            
            return obj;
        }

        // ========[ PRIVATE METHODS ]==============================================================

    }
}
