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
	import flare.vis.data.DataList;
	import flare.vis.data.DataSprite;
	import flare.vis.data.EdgeSprite;
	import flare.vis.data.NodeSprite;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.geom.Point;
	import flash.utils.Dictionary;
	
	
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

        public static function depthFirst(nodeOrigin:NodeSprite, edge:EdgeSprite, visited:Dictionary, subGraph:Data):void {
            visited[nodeOrigin] = true;
            subGraph.addNode(nodeOrigin);
            
            nodeOrigin.visitEdges(function(e:EdgeSprite):void {
                if (e.props.$merged) {
                    var n:NodeSprite = e.other(nodeOrigin);
                    if (visited[n]) {
                        if (!subGraph.contains(e)) {
                            // Adde the merged edge:
                            subGraph.addEdge(e);
                            // Add its edges as well:
                            var edges:Array = e.props.$edges;
                            for each (var ee:EdgeSprite in edges) {
                                subGraph.addEdge(ee);
                            }
                        }
                        return;
                    }
                    depthFirst(n, e, visited, subGraph);
                }
            });
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
                    obj.directed = e.directed;
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