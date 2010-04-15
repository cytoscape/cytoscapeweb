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
	import flare.vis.data.Data;
	import flare.vis.data.DataList;
	import flare.vis.data.DataSprite;
	import flare.vis.data.EdgeSprite;
	import flare.vis.data.NodeSprite;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	import flash.utils.Dictionary;
	
	import org.cytoscapeweb.model.data.VisualStyleVO;
	import org.cytoscapeweb.util.methods.$each;
	import org.cytoscapeweb.view.layout.PackingAlgorithms;
	
	
	public class GraphUtils {
		
        // ========[ CONSTRUCTOR ]==================================================================
        
        /**
         * This constructor will throw an error, as this is an abstract class. 
         */
        public function GraphUtils() {
             throw new Error("This is an abstract class.");
        }

        // ========[ PUBLIC METHODS ]===============================================================

        public static function bringToFront(d:DisplayObject):void {
            if (d != null) {
                var p:DisplayObjectContainer = d.parent;
                if (p != null)
                   p.setChildIndex(d, p.numChildren-1);
            }
        }
        
        public static function isFilteredOut(ds:DataSprite):Boolean {
            var b:Boolean = ds.props.$filteredOut;
            
            if (ds is EdgeSprite) {
                var e:EdgeSprite = EdgeSprite(ds);
                b = b || e.source.props.$filteredOut || e.target.props.$filteredOut;
            }
            
            return b;
        }
        
        public static function getBounds(data:Data, 
                                         ignoreNodeLabels:Boolean,
                                         ignoreEdgeLabels:Boolean):Rectangle {

            var bounds:Rectangle = new Rectangle();
            var minX:Number = Number.POSITIVE_INFINITY, minY:Number = Number.POSITIVE_INFINITY;
            var maxX:Number = Number.NEGATIVE_INFINITY, maxY:Number = Number.NEGATIVE_INFINITY;
            var lbl:TextSprite;
            var fld:TextField;

            // First, consider the NODES bounds:
            $each(data.nodes, function(i:uint, n:NodeSprite):void {
                if (!isFilteredOut(n)) {
                    // The node size (its shape must have the same height and width; e.g. a circle)
                    var ns:Number = n.height;
                    // Verify MIN and MAX x/y again:
                    minX = Math.min(minX, (n.x - ns/2));
                    minY = Math.min(minY, (n.y - ns/2));
                    maxX = Math.max(maxX, (n.x + ns/2));
                    maxY = Math.max(maxY, (n.y + ns/2));
                    
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
            
            $each(data.edges, function(i:uint, e:EdgeSprite):void {
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
                    
                    if (e.props.$points != null && e.props.$points.curve != null) {
                        var c:Point = e.props.$points.curve;
                        if (c.x < minX || c.y < minY || c.x > maxX || c.y > maxY) {
                            var p1:Point = e.props.$points.start;
                            var p2:Point = e.props.$points.end;
                            // Alwasys check a few points along the bezier curve to see
                            // if any of them is out of the bounds:
                            var fractions:Array = [0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9];
                            for each (var f:Number in fractions) {
                                var mp:Point = Utils.bezierPoint(p1, p2, c, f);
                                minX = Math.min(minX, mp.x);
                                maxX = Math.max(maxX, mp.x);
                                minY = Math.min(minY, mp.y);
                                maxY = Math.max(maxY, mp.y);
                            }
                        }
                    }
                }
            });
            
            const PAD:Number = 2;
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
           
            for each (data in dataList) {
                // The real subgraph bounds:
                var b:Rectangle = getBounds(data, ignoreNodeLabels, ignoreEdgeLabels);
                boundsList.push(b);

                // Just to get the correct subgraph later:
                lookup[data] = b.clone();
                
                // If there is a subgraph that is wider than the whole canvas,
                // use its width in the packing bounds:
                if (b.width > width) width = b.width;
            }
            
            boundsList.sort(function(a:Rectangle, b:Rectangle):int {
                return a.width < b.width ? -1 : (a.width > b.width ? 1 : 0);
            }, Array.DESCENDING);
            
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
                    }
                }
            }
        }
        
        public static function calculateGraphDimension(nodes:DataList, layout:String, style:VisualStyleVO):Rectangle {            
            // The minimum square edge when we have only one node:
            var side:Number = 40;
            var numNodes:Number = nodes.length;
            
            if (numNodes > 1) {
                if (layout === Layouts.CIRCLE ||
                    layout === Layouts.CIRCLE_TREE ||
                    layout === Layouts.RADIAL) {
                    if (numNodes === 2) {
                        side *= 1.5;
                    } else {
                        // Based on the desired distance between the adjacent nodes, imagine an inscribed 
                        // regular polygon that has N sides, and then calculate the circle radius:
                        // 1. number of sides = number of nodes:
                        var N:Number = nodes.length;
                        // 2. Each side should have a desired size (distance between the adjacent nodes):
                        var S:Number = 18;
                        // 3. If we connect two adjacent vertices to the center, the angle between these two 
                        // lines is 360/N degrees, or 2*pi/N radians:
                        var theta:Number = 2 * Math.PI / N;
                        // 4. To find the circle radius, using Trigonometry:
                        // sin(theta/2) = opposite/hypotenuse
                        var r:Number = S / Math.sin(theta/2) * 2;
                        // 5. Finally, the square side should be the circle diameter (2r):
                        side = 2 * r;
                    }
                } else if (layout === Layouts.FORCE_DIRECTED) {
                    var area:Number = 0;
                    for each (var n:NodeSprite in nodes) {
                        var s:Number = style.getValue(VisualProperties.NODE_SIZE, n.data);
                        area += 9 * s * s;
                    }
                    side = Math.sqrt(area);
                }
            }
            
            return new Rectangle(0, 0, side, side);
        }
        
        public static function toExtObjectsArray(dataSprites:*):Array {
            var arr:Array = null;
                     
            if (dataSprites is DataList || dataSprites is Array) {
                arr = [];
                for each (var ds:DataSprite in dataSprites) {
                    arr.push(toExtObject(ds));
                }
            }

            return arr;
        }
        
        public static function toExtObject(ds:DataSprite):Object {
            var obj:Object = null;

            if (ds != null) {
                // Data (attributes):
                obj = { data: ds.data };

                // Common Visual properties:
                obj.opacity = ds.alpha;
                obj.visible = ds.visible;
                
                if (ds is NodeSprite) {
                    obj.group = Groups.NODES;
                    obj.shape = ds.shape;
                    obj.size = ds.height;
                    obj.color = Utils.rgbColorAsString(ds.fillColor);
                    obj.borderColor = Utils.rgbColorAsString(ds.lineColor);
                    obj.borderWidth = ds.lineWidth;
                    
                    // Global coordinates:
                    var p:Point = new Point(ds.x, ds.y);
                    if (ds.parent) p = ds.parent.localToGlobal(p);
                    obj.x = p.x;
                    obj.y = p.y;
                } else {
                    obj.group = Groups.EDGES;

                    var e:EdgeSprite = EdgeSprite(ds);
                    obj.color = Utils.rgbColorAsString(e.lineColor);
                    obj.width = ds.lineWidth;
                    obj.sourceArrowShape = e.props.sourceArrowShape;
                    obj.targetArrowShape = e.props.targetArrowShape;
                    obj.sourceArrowColor = e.props.sourceArrowColor;
                    obj.targetArrowColor = e.props.targetArrowColor;
                    obj.curvature = e.props.curvature;
                    obj.merged = e.props.$merged ? true : false;
                    
                    if (e.props.$merged) {
                        var ee:Array = e.props.$edges;
                        ee = toExtObjectsArray(ee);
                        obj.edges = ee;
                    }
                }
            }
           
            return obj;
        }
	}
}