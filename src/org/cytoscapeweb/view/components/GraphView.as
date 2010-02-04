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
package org.cytoscapeweb.view.components {
	import flare.animate.Parallel;
	import flare.animate.Transition;
	import flare.animate.TransitionEvent;
	import flare.util.Displays;
	import flare.vis.data.Data;
	import flare.vis.data.DataList;
	import flare.vis.data.DataSprite;
	import flare.vis.data.EdgeSprite;
	import flare.vis.data.NodeSprite;
	
	import flash.display.Sprite;
	import flash.geom.Rectangle;
	
	import mx.core.UIComponent;
	
	import org.cytoscapeweb.events.GraphViewEvent;
	import org.cytoscapeweb.model.data.ConfigVO;
	import org.cytoscapeweb.model.data.VisualStyleVO;
	import org.cytoscapeweb.util.GraphUtils;
	import org.cytoscapeweb.util.Layouts;
	import org.cytoscapeweb.util.VisualProperties;
	import org.cytoscapeweb.view.layout.PackingAlgorithms;
	
	public class GraphView extends UIComponent {
        
        // ========[ CONSTANTS ]====================================================================

        // ========[ PRIVATE PROPERTIES ]===========================================================
    
	    private var _style:VisualStyleVO;
	    private var _config:ConfigVO;
		private var _background:Sprite;
		private var _graphContainer:Sprite;

        // ========[ PUBLIC PROPERTIES ]============================================================

        public var subGraphs:Array = new Array();

        public function get graphContainer():Sprite {
            if (_graphContainer == null) {
                _graphContainer = new Sprite();
                _graphContainer.doubleClickEnabled = true;
                
                // We create a background sprite and redefine the hit area of the visualization
	            // to use the background instead, so mouse events can work better even if happens
	            // out of the bounds of the visualization rectangle.
	            // It is particularly important when zooming, because we scale the visualization sprite.
                _graphContainer.hitArea = Sprite(parent);
               
                // we draw a background to ensure the region receives mouse events:
                _graphContainer.graphics.beginFill(0xffffff, 0); 
                _graphContainer.graphics.drawRect(0, 0, width, height);
            }
            
            return _graphContainer;
        }

		// ========[ CONSTRUCTOR ]==================================================================

		public function GraphView() {
		}
		
		// ========[ PUBLIC METHODS ]===============================================================

        public function draw(dataList:Array, config:ConfigVO, style:VisualStyleVO, layout:String):void {
            this._config = config;
            this._style = style;
        	
        	dispatchEvent(new GraphViewEvent(GraphViewEvent.RENDER_INITIALIZE));
            resize();
            
            // Add the common background:
            addChild(graphContainer);
            
            // Create the subgraphs (disconnected components) visualizations, even if it has
            // only one connected graph:
            addSubGraphs(dataList);

            // -----------------------------
            var par:Parallel = applyLayout(layout);
            
            par.addEventListener(TransitionEvent.END, function(evt:TransitionEvent):void {
            	evt.currentTarget.removeEventListener(evt.type, arguments.callee);
            	evt.currentTarget.dispose();
                dispatchEvent(new GraphViewEvent(GraphViewEvent.RENDER_COMPLETE));
            });
            par.play();
        }

        public function applyLayout(name:String):Parallel {
            dispatchEvent(new GraphViewEvent(GraphViewEvent.LAYOUT_INITIALIZE));
            
            resize();
            var par:Parallel = new Parallel();

            for each (var sg:SubGraphView in subGraphs) {
                sg.bounds = calculateGraphDimension(sg.data.nodes);
                var t:Transition = sg.applyLayout(name);
                par.add(t);
            }
            
            par.addEventListener(TransitionEvent.END, function(evt:TransitionEvent):void {
            	evt.currentTarget.removeEventListener(evt.type, arguments.callee);
            	
            	if (subGraphs.length > 1 && _config.currentLayout != Layouts.PRESET)
                    repackDisconnected();
            	zoomToFit();
                centerGraph();
                dispatchEvent(new GraphViewEvent(GraphViewEvent.LAYOUT_COMPLETE));
            });
            
            return par;
        }

        /**
        * Zoom the "camera" until it reaches the required scale.
        * @return The actual scale value after the zooming is executed.
        */
        public function zoomTo(scale:Number):void { trace("-> Zoom to: " + scale);
       		if (scale < _config.minZoom)
                scale = _config.minZoom;
            else if (scale > _config.maxZoom)
                scale = _config.maxZoom;
       		
       		var delta:Number = scale / graphContainer.scaleX;
       		zoomBy(delta);
        }
        
        public function zoomToFit():Number {
       	    // Reset zoom first:
        	if (graphContainer.scaleX != 1)
        	   zoomTo(1);
        	
        	var scale:Number = 1;
            var gb:Rectangle = getRealBounds();
            var pw:Number = parent.parent.width;
            var ph:Number = parent.parent.height;
            
            if (gb != null && gb.width > 0 && gb.height > 0) {
            	var graphEdge:Number = gb.width;
            	var canvasEdge:Number = pw;
            	
            	if (gb.height/gb.width > ph/pw) {
            		graphEdge = gb.height;
            		canvasEdge = ph;
            	}
	            if (graphEdge > canvasEdge) {        	
		            scale = canvasEdge / graphEdge;
		            zoomBy(scale);
		        }
	        }

	        return scale;
        }
        
        public function panGraph(amountX:Number, amountY:Number):void {
            Displays.panBy(graphContainer, amountX, amountY);
        }
        
        public function centerGraph():void {
            resize();
            var gb:Rectangle = getRealBounds();
            
            if (gb != null && gb.width > 0 && gb.height > 0) {
	            var minX:Number = gb.x;
	            var minY:Number = gb.y;
	            var maxX:Number = minX + gb.width;
	            var maxY:Number = minY + gb.height;
	            
	            // We stil have to considerate the difference between the graph position and
	            // the container borders, wich means we have to add a possible padding:
	            var padLeft:Number = minX - graphContainer.x;
	            var padTop:Number = minY - graphContainer.y;
	            
	            // The new coordinates:
	            var newX:Number = ((parent.width - gb.width) / 2) - padLeft;
	            var newY:Number = ((parent.height - gb.height) / 2) - padTop;
	            
	            // The amount to move, considering the new coordinates and the current position:
	            var panX:Number = newX - graphContainer.x;
                var panY:Number = newY - graphContainer.y;
	            
	            panGraph(panX, panY);
	        }
        }
        
        /**
         * Return the rectangle that represents the bounds of the whole graph (nodes, edges, labels).
         * The width and height are afected by the current zoom value.
         * The x and y are global (refer to the stage).
         */
        public function getRealBounds():Rectangle {
            var gBounds:Rectangle = new Rectangle();

            if (subGraphs != null) {
	            var minX:Number = Number.POSITIVE_INFINITY, minY:Number = Number.POSITIVE_INFINITY;
	            var maxX:Number = Number.NEGATIVE_INFINITY, maxY:Number = Number.NEGATIVE_INFINITY;
                
                for each (var sg:SubGraphView in subGraphs) {   
                    var sgBounds:Rectangle = sg.getRealBounds();
                    
                    var absX:Number = (sg.x + sgBounds.x) * graphContainer.scaleX + graphContainer.x;
                    var absY:Number = (sg.y + sgBounds.y) * graphContainer.scaleY + graphContainer.y;                    
                    
                    minX = Math.min(minX, absX);
                    minY = Math.min(minY, absY);
                    maxX = Math.max(maxX, (absX + sgBounds.width * graphContainer.scaleX));
                    maxY = Math.max(maxY, (absY + sgBounds.height * graphContainer.scaleY));              
                }
                
                gBounds.x = minX;
                gBounds.y = minY;
                gBounds.width = maxX - minX;
                gBounds.height = maxY - minY;
            }
            
            return gBounds;
        }
        
        public function selectNodes(nodes:Array):void {
            // Apply the selected styles immediately,
            // or the rollover highlight would take precedence and the selection one 
            // would be noticed only after a rollout:
            if (nodes != null && nodes.length > 0) {
                for each (var n:NodeSprite in nodes) {
                    var sg:SubGraphView = getSubGraphOf(n);
                    if (sg != null) {
                        sg.highlightSelectedNode(n);
                        bringNodeToFront(n);
                    }
                }
            }
        }
        
        public function deselectNodes(nodes:Array):void {
            if (nodes != null && nodes.length > 0) {
                for each (var n:NodeSprite in nodes) {
                    var sg:SubGraphView = getSubGraphOf(n);
                    if (sg != null) sg.resetNode(n);
                }
            }
        }
        
        public function selectEdges(edges:Array):void {
            if (edges != null && edges.length > 0) {
                var sg:SubGraphView;
                for each (var e:EdgeSprite in edges) {
                    sg = getSubGraphOf(e);
                    if (sg != null) {
                        sg.highlightSelectedEdge(e);
                        // Bring selected edge to front:
                        GraphUtils.bringToFront(e);
                    }
                }
                // Bring all nodes to front, too, so no edge will overlap them:
                for each (sg in subGraphs) {
                    for each (var n:NodeSprite in sg.data.nodes) GraphUtils.bringToFront(n);
                }
            }
        }
        
        public function deselectEdge(edge:EdgeSprite):void {
            var sg:SubGraphView = getSubGraphOf(edge);
            if (sg != null) sg.resetEdge(edge);
        }
        
        public function resetAllNodes():void {
            for each (var sg:SubGraphView in subGraphs)
            	sg.resetAllNodes();
        }
        
        public function resetAllEdges():void {
            for each (var sg:SubGraphView in subGraphs)
            	sg.resetAllEdges();
        }
        
        public function getSubGraphOf(d:DataSprite):SubGraphView {
        	for each (var sg:SubGraphView in subGraphs) {
                if (sg.data.contains(d)) return sg;
            }
            return null;
        }
        
        /**
         * Bring a node along with its subgraph to front.
         */
        public function bringNodeToFront(n:NodeSprite):void {
            if (n != null) {
	            // First, bring the subgraph to front:
	            GraphUtils.bringToFront(getSubGraphOf(n));
	            // Bring the node to front, too:
	            GraphUtils.bringToFront(n);
	            // Do not forget the node's label!
	            GraphUtils.bringToFront(n.props.label);
            }
        }
        
        public function applyVisualStyle(style:VisualStyleVO):void {
            this._style = style;
            for each (var sg:SubGraphView in subGraphs) {
                sg.applyVisualStyle(style);
            }
        }
        
        public function updateLabels(group:String=null):void {
            for each (var sg:SubGraphView in subGraphs) {
                sg.updateLabels(group);
            }
        }
        
        public function update():void {         
            for each (var sg:SubGraphView in subGraphs) sg.update();
        }
		
        // ========[ PRIVATE METHODS ]==============================================================
		
		/**
         * Zoom the "camera" by the specified scale factor.
         */
        private function zoomBy(scale:Number):void { trace("-> Zoom by: " + scale);            
            if (scale > 0) {
                Displays.zoomBy(graphContainer, scale, parent.width/2, parent.height/2);
                // Let others know about the new scale:
                dispatchEvent(new GraphViewEvent(GraphViewEvent.SCALE_CHANGE, graphContainer.scaleX));
            }
        }
		
		private function resize():void {
		    width = parent.width;
            height = parent.height;
		}
		
		private function repackDisconnected():void {			
			var boundsList:Array = new Array();
			var sg:SubGraphView;
			
            for each (sg in subGraphs) {
                // The real subgraph bounds:
                var sgBounds:Rectangle = sg.getRealBounds();
                boundsList.push(sgBounds);
                // Temp. props attributes, just to get the correct subgraph later:
                sg.props.realWidth = sgBounds.width;
                sg.props.realHeight = sgBounds.height;
            }
            
            // More than 8 subgraphs decreases performance when using "fill by stripes":
            if (boundsList.length <= 7)
                boundsList = PackingAlgorithms.fillByStripes(width, boundsList);
            else
                boundsList = PackingAlgorithms.fillByOneColumn(width, boundsList);
            
            for (var i:int = 0; i < boundsList.length; i++) {
                var rect:Rectangle = Rectangle(boundsList[i]);

                for each (sg in subGraphs) {
                	// Get the correct subgraph for this "packed" bounds:
                	if (rect.width == sg.props.realWidth && rect.height == sg.props.realHeight) {
                		// Set the new coordinates:
		                sg.x = rect.x;
		                sg.y = rect.y;
		                // Remove the temp. props attributes:
		                sg.props.realWidth = null;
                        sg.props.realHeight = null;
                		break;
                	}
                }
            }
		}
		
		private function addSubGraphs(dataList:Array):void {
			// Sort the subgraphs by number of nodes, DESC:
            dataList.sort(function(a:Data, b:Data):int {
                return a.nodes.length < b.nodes.length ? -1 : (a.nodes.length > b.nodes.length ? 1 : 0);
            }, Array.DESCENDING);
            
            // Calculate a minimum or desired dimension for each subgraph bounds:
            var rects:Array = new Array();
            var numNodes:int = 0;
            for each (var dt:Data in dataList) numNodes += dt.nodes.length;
            
            for (var idx:int = 0; idx < dataList.length; idx++) {
                var r:Rectangle = calculateGraphDimension(dataList[idx].nodes);
                rects.push(r);
            }
            
            rects.sort(function(a:Rectangle, b:Rectangle):int {
            	var arA:Number = a.width*a.height;
            	var arB:Number = b.width*b.height;
                return arA < arB ? -1 : (arA > arB ? 1 : 0);
            }, Array.DESCENDING);
            
            for (var i:int = 0; i < dataList.length; i++) {
                var data:Data = dataList[i];                
                var bounds:Rectangle = rects[i];
                
                var sg:SubGraphView = createSubGraph(data, bounds);
            }
		}
		
		private function createSubGraph(data:Data, bounds:Rectangle):SubGraphView {
		    var sgView:SubGraphView = new SubGraphView(data, _config, _style);
            sgView.bounds = bounds;

            // This is necessary to allow all nodes from all visualizations to
            // receive mouse events (is there any other way)?:
            sgView.mouseEnabled = false;
            
            subGraphs.push(sgView);
            graphContainer.addChild(sgView);

            // THIS IS NECESSARY to make ForceDirectedLyout render well,
            // but I don't know why!
            // -----------------------------------------------------------
            sgView.graphics.beginFill(0xffffff, 0);
            sgView.graphics.drawRect(0, 0, bounds.width, bounds.height);
            // -----------------------------------------------------------
            
            return sgView;
		}
		
		private function calculateGraphDimension(nodes:DataList):Rectangle {            
            // The minimum square edge when we have only one node:
            var side:Number = 40;
            var numNodes:Number = nodes.length;
            
            if (numNodes > 1) {
				if (_config.currentLayout === Layouts.CIRCLE ||
				    _config.currentLayout === Layouts.CIRCLE_TREE ||
				    _config.currentLayout === Layouts.RADIAL) {
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
                } else if (_config.currentLayout === Layouts.FORCE_DIRECTED) {
                    var area:Number = 0;
                    for each (var n:NodeSprite in nodes) {
                        var s:Number = _style.getValue(VisualProperties.NODE_SIZE, n.data);
                        area += 9 * s * s;
                    }
                    side = Math.sqrt(area);
                }
            }
			
			// The subgraph area is squared:
			return new Rectangle(0, 0, side, side);
		}
	}
}