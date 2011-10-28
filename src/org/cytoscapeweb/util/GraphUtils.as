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
    import flare.display.TextSprite;
    import flare.util.Geometry;
    import flare.vis.data.Data;
    import flare.vis.data.DataList;
    import flare.vis.data.DataSprite;
    import flare.vis.data.EdgeSprite;
    import flare.vis.data.NodeSprite;
    
    import flash.display.DisplayObject;
    import flash.display.DisplayObjectContainer;
    import flash.display.Sprite;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import flash.text.TextField;
    import flash.utils.Dictionary;
    
    import org.cytoscapeweb.util.methods.$each;
    import org.cytoscapeweb.view.layout.PackingAlgorithms;
    import org.cytoscapeweb.vis.data.CompoundNodeSprite;
    
    
    public class GraphUtils {
        
        // ========[ CONSTRUCTOR ]==================================================================
        
        /**
         * This constructor will throw an error, as this is an abstract class. 
         */
        public function GraphUtils() {
             throw new Error("This is an abstract class.");
        }

        // ========[ PUBLIC METHODS ]===============================================================
        
        /**
         * Brings the given display object to the front of the stage. This
         * function does not taken compound nodes into account. Use bringToFront 
         * function for full compatibility with compound graphs.
         * 
         * @param d     DisplayObject to bring to front
         */
        public static function toFront(d:DisplayObject):void {
            if (d != null) {
                var p:DisplayObjectContainer = d.parent;
                if (p != null)
                    p.setChildIndex(d, p.numChildren-1);
            }
        }
        
        /**
         * Brings the given display object to the front of the stage. If the
         * given display object is a CompoundNodeSprite, also brings all
         * its children and edges inside the compound node to the front.
         * 
         * @param d     DisplayObject to bring to front 
         */ 
        public static function bringToFront(d:DisplayObject):void {
            if (d != null) {
                if (d is CompoundNodeSprite) {
                    var cns:CompoundNodeSprite = d as CompoundNodeSprite;
                    
                    // bring the compound node sprite as well as all its
                    // children and the edges inside the compound to the front.
                    GraphUtils.toFront(cns);
                    
                    if (cns.isInitialized() && !cns.allChildrenInvisible()) {
                        for each (var ns:NodeSprite in cns.getNodes()) {
                            GraphUtils.toFront(ns);
                            
                            if (ns is CompoundNodeSprite) {
                                GraphUtils.bringToFront(ns as CompoundNodeSprite);
                            }
                            
                            ns.visitEdges(toFront);
                        }
                    }
                } else {
                    GraphUtils.toFront(d);
                }
            }
        }
        
        /**
         * If the given data sprite is filtered out, returns true. If a 
         * NodeSprite itself is not filtered out, but at least one of its
         * parents is filtered out, then the node is also considered as
         * filtered out. Similarly, if an EdgeSprite is not filtered out, but
         * either its source or target is filtered out, then the edge is also
         * considered as filtered out.
         * 
         * @param ds    DataSprite to be checked
         * @return      true if filtered out, false otherwise
         */
        public static function isFilteredOut(ds:DataSprite):Boolean {
            var filtered:Boolean = ds.props.$filteredOut;
            var cn:CompoundNodeSprite, parent:CompoundNodeSprite;
            
            if (ds is EdgeSprite) {
                var e:EdgeSprite = EdgeSprite(ds);
                
                // if an edge is not filtered out, but either its target or
                // its source is filtered out, then the edge should also  filtered out
                filtered = filtered || isFilteredOut(e.source) || isFilteredOut(e.target);
            } else if (ds is CompoundNodeSprite) {
                cn = ds as CompoundNodeSprite;
                // if a node is not filtered out, but at least one of its
                // parents is filtered out, then the node should also be filtered out
                for each (parent in CompoundNodes.getParents(cn)) {
                    if (parent.props.$filteredOut) {
                        filtered = true;
                        break;
                    }
                }
            }
            
            return filtered;
        }
        
        public static function getBounds(nodes:*, edges:*,
                                         ignoreNodeLabels:Boolean,
                                         ignoreEdgeLabels:Boolean):Rectangle {
            var bounds:Rectangle = new Rectangle();
            
            const PAD:Number = 2;
            var minX:Number = Number.POSITIVE_INFINITY, minY:Number = Number.POSITIVE_INFINITY;
            var maxX:Number = Number.NEGATIVE_INFINITY, maxY:Number = Number.NEGATIVE_INFINITY;
            var lbl:TextSprite;
            var fld:TextField;

            if (nodes != null && nodes.length > 0) {
                // First, consider the NODES bounds:
                $each(nodes, function(i:uint, n:NodeSprite):void {
                    if (!isFilteredOut(n)) {
                        // The node size (its shape must have the same height and width; e.g. a circle)
                        var w:Number = n.width;
                        var h:Number = n.height;
                        var w2:Number = w/2, h2:Number = h/2;
                        
                        // Verify MIN and MAX x/y again:
                        minX = Math.min(minX, (n.x - w2));
                        minY = Math.min(minY, (n.y - h2));
                        maxX = Math.max(maxX, (n.x + w2));
                        maxY = Math.max(maxY, (n.y + h2));
                        
                        // Consider the LABELS bounds, too:
                        var lbl:TextSprite = n.props.label;
                        if (!ignoreNodeLabels && lbl != null) {
                            // The alignment values are done by the text field, not the label...
                            fld = lbl.textField;
                            minX = Math.min(minX, lbl.x + fld.x);
                            maxX = Math.max(maxX, (lbl.x + lbl.width + fld.x));
                            minY = Math.min(minY, lbl.y + fld.y);
                            maxY = Math.max(maxY, (lbl.y + lbl.height + fld.y));
                        }
                    }
                });
            }
            
            if (edges != null && edges.length > 0) {
                // Also mesure edge bounds:
                $each(edges, function(i:uint, e:EdgeSprite):void {
                    if (!isFilteredOut(e)) {
                        // Edge LABELS first, to avoid checking edges that are already inside the bounds:
                        lbl = e.props.label;
                        if (!ignoreEdgeLabels && lbl != null) {
                            fld = lbl.textField;
                            minX = Math.min(minX, lbl.x + fld.x);
                            maxX = Math.max(maxX, (lbl.x + lbl.width + fld.x));
                            minY = Math.min(minY, lbl.y + fld.y);
                            maxY = Math.max(maxY, (lbl.y + lbl.height + fld.y));
                        }
                        
                        if (e.props.$points != null && e.props.$points.c1 != null) {
                            var c1:Point = e.props.$points.c1;
                            var c2:Point = e.props.$points.c2 != null ? e.props.$points.c2 : c1;
                            
                            if (c1.x < minX || c1.y < minY || c1.x > maxX || c1.y > maxY ||
                                c2.x < minX || c2.y < minY || c2.x > maxX || c2.y > maxY) {
                                var p1:Point = e.props.$points.start;
                                var p2:Point = e.props.$points.end;
                                // Alwasys check a few points along the bezier curve to see
                                // if any of them is out of the bounds:
                                var mp:Point, f:Number;
                                
                                if (e.source === e.target) {
                                    // Loop...
                                    var cc1:Point = new Point();
                                    var cc2:Point = new Point();
                                    var cc3:Point = new Point();
                                    mp = new Point();
                                    var w:Number = e.lineWidth/2;
                                    
                                    for (f = 0.1; f < 1.0; f += 0.1) {
                                        Geometry.cubicCoeff(p1, c2, c1, p2, cc1, cc2, cc3);
                                        mp = Geometry.cubic(f, p1, cc1, cc2, cc3, mp);
                                        minX = Math.min(minX, mp.x - w);
                                        maxX = Math.max(maxX, mp.x + w);
                                        minY = Math.min(minY, mp.y - w);
                                        maxY = Math.max(maxY, mp.y + w);
                                    }
                                } else {
                                    for (f = 0.1; f < 1.0; f += 0.1) {
                                        mp = Utils.bezierPoint(p1, p2, c1, f);
                                        minX = Math.min(minX, mp.x);
                                        maxX = Math.max(maxX, mp.x);
                                        minY = Math.min(minY, mp.y);
                                        maxY = Math.max(maxY, mp.y);
                                    }
                                }
                            }
                        }
                    }
                });
            }
            
            if (minX === Number.POSITIVE_INFINITY) minX = 0;
            if (minY === Number.POSITIVE_INFINITY) minY = 0;
            if (maxX === Number.NEGATIVE_INFINITY) maxX = 0;
            if (maxY === Number.NEGATIVE_INFINITY) maxY = 0;
            
            bounds.x = minX - PAD;
            bounds.y = minY - PAD;
            bounds.width = maxX - bounds.x + PAD;
            bounds.height = maxY - bounds.y + PAD;
            
            return bounds;
        }
        
        public static function repackDisconnected(dataList:Array,
                                                  width:Number,
                                                  ignoreNodeLabels:Boolean,
                                                  ignoreEdgeLabels:Boolean):void {         
            if (dataList.length < 2) return;
            
            var boundsList:Array = [];
            var lookup:Dictionary = new Dictionary();
            var data:Data;
            var area:Number = 0;
           
            for each (data in dataList) {
                // The real subgraph bounds:
                var b:Rectangle = getBounds(data.nodes, data.edges,
                                            ignoreNodeLabels, ignoreEdgeLabels);
                boundsList.push(b);

                // Just to get the correct subgraph later:
                lookup[data] = b.clone();
                
                // If there is a subgraph that is wider than the whole canvas,
                // use its width in the packing bounds:
                if (b.width > width) width = b.width;
                area += b.width * b.height;
            }
            
            boundsList.sort(function(a:Rectangle, b:Rectangle):int {
                return a.width < b.width ? -1 : (a.width > b.width ? 1 : 0);
            }, Array.DESCENDING);
            
            // Adjust the bounds width:
            if (dataList.length > 50)
                width = Math.max(width, 1.4 * Math.sqrt(area));
            
            // More than 8 subgraphs decreases performance when using "fill by stripes":
            if (boundsList.length <= 7)
                boundsList = PackingAlgorithms.fillByStripes(width, boundsList);
            else
                boundsList = PackingAlgorithms.fillByOneColumn(width, boundsList);
            
            for (var i:uint = 0; i < boundsList.length; i++) {
                var rect:Rectangle = boundsList[i];

                for each (data in dataList) {
                    b = lookup[data];

                    // Get the correct subgraph for this "packed" bounds:
                    if (b != null && rect.width == b.width && rect.height == b.height) {
                        delete lookup[data];

                        // Set the new coordinates:
                        $each(data.nodes, function(i:uint, n:NodeSprite):void {
                            n.x += (rect.x - b.x);
                            n.y += (rect.y - b.y);
                        });
                        break;
                    }
                }
            }
        }
        
        public static function separateDisconnected(data:Data):Array {
            var dataList:Array = [];
            var visited:Dictionary = new Dictionary();
            
            // Get any node to start searching:
            $each(data.nodes, function(i:uint, n:NodeSprite):void {
                if (!visited[n] && !isFilteredOut(n)) {
                    var d:Data = new Data(data.directedEdges);
                    depthFirst(n, visited, d);
                    dataList.push(d);
                }
            });
            
            return dataList;
        }
        
        public static function depthFirst(nodeOrigin:NodeSprite, visited:Dictionary, data:Data):void {
            var toVisit:Array = [nodeOrigin];

            while (toVisit.length > 0) {
                var node:NodeSprite = toVisit.pop();
                
                if (!visited[node]) {
                    visited[node] = true;
                    
                    if (!node.props.$filteredOut) {
                        data.addNode(node);
                        
                        node.visitEdges(function(e:EdgeSprite):Boolean {
                            if (e.props.$merged && !isFilteredOut(e)) {
                                var otherNode:NodeSprite = e.other(node);
                                if (!data.contains(e)) {
                                    // Adde the merged edge:
                                    data.addEdge(e);
                                    // Add its edges as well:
                                    var edges:Array = e.props.$edges;
                                    for each (var ee:EdgeSprite in edges) {
                                        data.addEdge(ee);
                                    }
                                }
                                if (!visited[otherNode]) {
                                    toVisit.push(otherNode);
                                }
                            }
                            return false;
                        });
                        
                        if (node is CompoundNodeSprite) {
                            var cns:CompoundNodeSprite = node as CompoundNodeSprite;
                            
                            // include all non-visited children
                            for each (var child:NodeSprite in CompoundNodes.getChildren(cns)) {
                                if (!visited[child]) {
                                    toVisit.push(child);
                                }
                            }
                            
                            // include all non-visited parents
                            for each (var parent:NodeSprite in CompoundNodes.getParents(cns)) {
                                if (!visited[parent]) {
                                    toVisit.push(parent);
                                }
                            }
                        }
                    }
                }
            }
        }
        
        public static function calculateGraphDimension(nodes:DataList, layout:String):Rectangle {            
            // The minimum square edge when we have only one node:
            var side:Number = 40;
            var numNodes:Number = nodes.length;
            var n:NodeSprite;
            
            for each (n in nodes) {
                if (GraphUtils.isFilteredOut(n)) numNodes--;
            }
            
            if (numNodes > 1) {
                if (layout === Layouts.CIRCLE || layout === Layouts.RADIAL) {
                    // Based on the desired distance between the adjacent nodes, imagine an inscribed 
                    // regular polygon that has N sides, and then calculate the circle radius:
                    // 1. number of sides = number of nodes:
                    var N:Number = nodes.length;
                    // 2. Each side should have a desired size (distance between the adjacent nodes):
                    var S:Number = 0;
                    for each (n in nodes) {
                        if (!GraphUtils.isFilteredOut(n)) {
                            S = Math.max(n.width, n.height);
                        }
                    }
                    if (isNaN(S)) S = 40;
                    
                    if (numNodes === 2) {
                        side = 2.1 * S;
                    } else {
                        // 3. If we connect two adjacent vertices to the center, the angle between these two 
                        // lines is 360/N degrees, or 2*pi/N radians:
                        var theta:Number = 2 * Math.PI / N;
                        // 4. To find the circle diameter, using Trigonometry:
                        // sin(theta/2) = opposite/hypotenuse
                        side = (2 * S) / Math.sin(theta/2);
                    }
                } else if (layout === Layouts.FORCE_DIRECTED) {
                    var area:Number = 0;
                    for each (n in nodes) {
                        if (!GraphUtils.isFilteredOut(n)) {
                            var s:Number = Math.max(n.width, n.height);
                            area += 9 * s * s;
                        }
                    }
                    side = Math.sqrt(area);
                }
            }
            
            return new Rectangle(0, 0, side, side);
        }
        
        public static function sortByZOrder(sprites:Array):Array {
            var sorted:Array = sprites.concat();
            
            sorted.sort(function(a:Sprite, b:Sprite):int {
                var z1:int = a.parent.getChildIndex(a);
                var z2:int = b.parent.getChildIndex(b);
                
                return z1 < z2 ? -1 : (z1 > z2 ? 1 : 0);
            });
            
            return sorted;
        }
    }
}