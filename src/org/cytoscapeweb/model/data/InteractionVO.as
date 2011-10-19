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
    import flare.vis.data.EdgeSprite;
    import flare.vis.data.NodeSprite;
    
    import org.cytoscapeweb.util.DataSchemaUtils;
    
    public class InteractionVO {
        
        private var _key:String;
        private var _node1:NodeSprite;
        private var _node2:NodeSprite;
        private var _mergedEdge:EdgeSprite;
        
        // =========================================================================================
        
        public function InteractionVO(node1:NodeSprite, node2:NodeSprite, edgesSchema:DataSchema) {
            _key = InteractionVO.createKey(node1, node2);
            
            _node1 = node1;
            _node2 = node2;
            
            // Create merged edge:
            _mergedEdge = new EdgeSprite(node1, node2, false);
            node1.addOutEdge(_mergedEdge);
            node2.addInEdge(_mergedEdge);

            // props attributes and functions
            _mergedEdge.props.$merged = true;
            
            mergedEdge.props.$getDataList = function():Array {
                var dataList:Array = [];
                for each (var e:EdgeSprite in this.$edges) {
                    if (!e.props.$filteredOut) dataList.push(e.data);
                }
                return dataList;
            }
            
            mergedEdge.props.$getFilteredEdges = function():Array {
                var filteredList:Array = [];
                for each (var e:EdgeSprite in this.$edges) {
                    if (!e.props.$filteredOut) filteredList.push(e);
                }
                return filteredList;
            }
            
            update(edgesSchema);
        }
        
        // ========[ PUBLIC METHODS ]===============================================================
        
        public function get key():String {
            return _key;
        }
        
        public function get node1():NodeSprite {
            return _node1;
        }
        
        public function get node2():NodeSprite {
            return _node2;
        }
        
        public function get edges():Array {
            var edges:Array = [];
            node1.visitEdges(function(e:EdgeSprite):Boolean {
                if (!e.props.$merged && hasNodes(e.source, e.target)) {
                    e.props.$parent = _mergedEdge;
                    edges.push(e);
                }
                return false;
            }, loop ? NodeSprite.IN_LINKS : NodeSprite.GRAPH_LINKS);
            
            return edges;
        }
        
        public function get mergedEdge():EdgeSprite {          
            return _mergedEdge;
        }
        
        public function get loop():Boolean {          
            return mergedEdge.source === mergedEdge.target;
        }
        
        public function hasNodes(node1:NodeSprite, node2:NodeSprite):Boolean {
            return (_node1 == node1 && _node2 == node2) || (_node1 == node2 && _node2 == node1);
        }
        
        public function update(edgesSchema:DataSchema, updateData:Boolean=true):void {
            // Merged edge data:
            if (updateData) recreateDataFields(edgesSchema);
            
            // Update merged edge cached data:
            mergedEdge.props.$selected = false;
            mergedEdge.props.$edges = edges;

            var edgesList:Array = mergedEdge.props.$getFilteredEdges();
            var length:int = edgesList.length;
            var e:EdgeSprite;
            
            // Start curve index from left (negative):
            var f:Number = 0;
            if (loop) {
                // When it's a loop, merged edges have curvature, too:
                mergedEdge.props.$curvatureFactor = 1;
            } else {
                f = length%2 === 0 ? (-length/2 - 0.5) : (-Math.floor(length/2) - 1);
            }
            
            var src:NodeSprite;

            for (var i:int = 0; i < length; i++) {
                // Update each edge index:
                
                // Calculate the curvature coefficient that will give the
                // direction and distance of each curve:
                e = edgesList[i];
                f += 1; // adding edges curvature from left to right...

                if (!loop) {
                    // In order to make the EdgeRenderer draw the edges symmetrically,
                    // we need to know whether or not they have the same source node:
                    if (i === 0) src = e.source; // get the first edge as reference
                    e.props.$curvatureFactor = e.source === src ? f : -f; // to correctly invert the curve
                } else {
                    e.props.$curvatureFactor = f;
                }
                
                // Merged edge selection state:
                if (e.props.$selected) mergedEdge.props.$selected = true;
                
                // Merged edge data:
                if (updateData) {
                    for each (var df:DataField in edgesSchema.fields) {
                        if (isMergeable(df)) {
                            var mv:* = mergedEdge.data[df.name];
                            var v:* = e.data[df.name];
                            
                            switch (df.type) {
                                case DataUtil.INT:
                                case DataUtil.NUMBER:
                                    mv += (isNaN(v) ? 0 : v);
                                    break;
                                case DataUtil.BOOLEAN:
                                    mv |= v;
                                    break;
                                default:
                                    mv.push(v !== undefined ? v : null);
                            }
                            
                            _mergedEdge.data[df.name] = mv;
                        }
                    }
                }

                e.dirty();
            }

            // Other cached data:
            mergedEdge.props.$filteredOut = edgesList.length === 0;
            mergedEdge.dirty();
        }
        
        public static function createKey(node1:NodeSprite, node2:NodeSprite):String {
            var id1:* = node1.data.id;
            var id2:* = node2.data.id;
            var key:String = id1 < id2 ? id1+"::"+id2 : id2+"::"+id1;
            
            return key;
        }

        // ========[ PRIVATE METHODS ]==============================================================
        
        private function recreateDataFields(edgesSchema:DataSchema):void {
            var id:String = _mergedEdge.data.id;
            
            _mergedEdge.data = { };
            _mergedEdge.data[DataSchemaUtils.ID] = id;
            _mergedEdge.data[DataSchemaUtils.SOURCE] = node1.data.id;
            _mergedEdge.data[DataSchemaUtils.TARGET] = node2.data.id;
            _mergedEdge.data[DataSchemaUtils.DIRECTED] = false;
            
            var v:*;
            
            for each (var df:DataField in edgesSchema.fields) {
                if (isMergeable(df)) {
                    switch (df.type) {
                        case DataUtil.INT: v = 0; break;
                        case DataUtil.NUMBER: v = 0.0; break;
                        case DataUtil.BOOLEAN: v = false; break;
                        default: v = [];
                    }
                
                    _mergedEdge.data[df.name] = v;
                }
            }
        }
        
        private static function isMergeable(df:DataField):Boolean {
            var n:String = df.name;
            return (n != "id" && n != "source" && n !== "target" &&n !== "directed");
        }
    }
}