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
	import flare.display.DirtySprite;
	import flare.util.Displays;
	import flare.vis.data.Data;
	import flare.vis.data.DataList;
	import flare.vis.data.DataSprite;
	import flare.vis.data.EdgeSprite;
	import flare.vis.data.NodeSprite;
	
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.getTimer;
	
	import mx.core.UIComponent;
	
	import org.cytoscapeweb.events.GraphViewEvent;
	import org.cytoscapeweb.model.data.ConfigVO;
	import org.cytoscapeweb.model.data.VisualStyleVO;
	import org.cytoscapeweb.util.Edges;
	import org.cytoscapeweb.util.GraphUtils;
	import org.cytoscapeweb.util.Nodes;
	import org.cytoscapeweb.util.methods.$each;
	
	public class GraphView extends UIComponent {
        
        // ========[ CONSTANTS ]====================================================================

        // ========[ PRIVATE PROPERTIES ]===========================================================
    
	    private var _style:VisualStyleVO;
	    private var _config:ConfigVO;

        // ========[ PUBLIC PROPERTIES ]============================================================

        public var vis:GraphVis;

		// ========[ CONSTRUCTOR ]==================================================================

		public function GraphView() {
		    doubleClickEnabled = true;
		    
            this.addEventListener(Event.ADDED_TO_STAGE, function(evt:Event):void {
                hitArea = Sprite(parent);
            });
		}
		
		// ========[ PUBLIC METHODS ]===============================================================

        public function draw(data:Data, config:ConfigVO, style:VisualStyleVO, layout:String):void {
            this._config = config;
            this._style = style;
        	hitArea = Sprite(parent);
        	
        	dispatchEvent(new GraphViewEvent(GraphViewEvent.RENDER_INITIALIZE));
            resize();

            createVisualization(data, layout);

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
            vis.bounds = GraphUtils.calculateGraphDimension(vis.data.nodes, name, _style);
            var t:Transition = vis.applyLayout(name);
            par.add(t);
          
            par.addEventListener(TransitionEvent.END, function(evt:TransitionEvent):void {
            	evt.currentTarget.removeEventListener(evt.type, arguments.callee);
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
       		
       		var delta:Number = scale / vis.scaleX;
       		zoomBy(delta);
        }
        
        public function zoomToFit():Number {
       	    // Reset zoom first:
        	if (vis.scaleX != 1)
        	   zoomTo(1);
        	
        	var scale:Number = 1;
            var b:Rectangle = vis.getRealBounds();
            
            var g:Graphics = Sprite(parent).graphics;
            g.clear();
            g.beginFill(0xff0000, 0.4);
            g.drawRect(b.x, b.y, b.width, b.height);
            g.endFill();
            
            var pw:Number = stage.stageWidth;
            var ph:Number = stage.stageHeight;
            
            if (b != null && b.width > 0 && b.height > 0) {
            	var graphEdge:Number = b.width;
            	var canvasEdge:Number = pw;
            	
            	if (b.height/b.width > ph/pw) {
            		graphEdge = b.height;
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
            Displays.panBy(vis, amountX, amountY);
        }
        
        public function centerGraph():void {
            var b:Rectangle = getRealBounds();
            
            if (b != null && b.width > 0 && b.height > 0) {
	            // The new coordinates:
	            var newX:Number = (stage.stageWidth - b.width) / 2;
	            var newY:Number = (stage.stageHeight - b.height) / 2;
	            
	            // The amount to move, considering the new coordinates and the current position:
	            var panX:Number = newX - b.x;
                var panY:Number = newY - b.y;
	            
	            panGraph(panX, panY);
	        }
        }
        
        /**
         * Return the rectangle that represents the bounds of the whole graph (nodes, edges, labels).
         * The width and height are afected by the current zoom value.
         * The x and y are global (refer to the stage).
         */
        public function getRealBounds():Rectangle {
            var b:Rectangle;

            if (vis != null) {
                b = vis.getRealBounds();
                
                var p:Point = vis.localToGlobal(new Point(b.x, b.y));
                b.x = p.x;
                b.y = p.y;
                
                b.width *= vis.scaleX;
                b.height *= vis.scaleY;
            } else {
                b = new Rectangle();
            }
            
            return b;
        }
        
        public function selectNodes(nodes:Array):void {
            // Apply the selected styles immediately,
            // or the rollover highlight would take precedence and the selection one 
            // would be noticed only after a rollout:
            if (nodes != null && nodes.length > 0) {
                for each (var n:NodeSprite in nodes) {
                    highlightSelectedNode(n);
                    bringToFront(n);
                }
            }
        }
        
        public function deselectNodes(nodes:Array):void {
            if (nodes != null && nodes.length > 0) {
                $each(nodes, function(i:uint, n:NodeSprite):void {
                    resetNode(n);
                });
            }
        }
        
        public function selectEdges(edges:Array):void {
            if (edges != null && edges.length > 0) {
                $each(edges, function(i:uint, e:EdgeSprite):void {
                    highlightSelectedEdge(e);
                    // Bring selected edge to front:
                    GraphUtils.bringToFront(e);
                });
                // Bring all nodes to front, too, so no edge will overlap them:
                $each(vis.data.nodes, function(i:uint, n:NodeSprite):void {
                    GraphUtils.bringToFront(n);
                });
            }
        }
        
        public function resetNode(n:NodeSprite):void {
            if (n != null) {
                n.size = Nodes.size(n);
                n.fillColor = Nodes.fillColor(n);
                n.lineWidth = Nodes.lineWidth(n);
                n.lineColor = Nodes.lineColor(n);
                n.alpha = Nodes.alpha(n);  
                n.shape = Nodes.shape(n);
                n.filters = Nodes.filters(n);
            }
        }
        
        public function resetEdge(e:EdgeSprite):void {
            if (e != null) {
                e.shape = Edges.shape(e);
                e.lineWidth = Edges.lineWidth(e);
                e.lineColor = Edges.lineColor(e);
                e.props.sourceArrowColor = Edges.sourceArrowColor(e);
                e.props.targetArrowColor = Edges.targetArrowColor(e);
                e.alpha = Edges.alpha(e);  
                e.arrowType = Edges.targetArrowShape(e);
                e.props.curvature = Edges.curvature(e);
                e.filters = Edges.filters(e);
            }
        }
        
        public function resetAllNodes():void {
            // If no nodes list was provided, we get all the nodes:
            var nodes:DataList = vis.data.nodes;
            
            // Restore node properties:
            //     Note: It is better to set only the properties that are necessary.
            //     I tried data.nodes.setProperties(nodeProperties), but some nodes blinks when
            //     rolling over/out
            nodes.setProperty("lineWidth", Nodes.lineWidth);
            nodes.setProperty("fillColor", Nodes.fillColor);
            nodes.setProperty("lineColor", Nodes.lineColor);
            nodes.setProperty("alpha", Nodes.alpha);
            nodes.setProperty("filters", Nodes.filters);

            DirtySprite.renderDirty();
        }
        
        public function resetAllEdges():void {
            //vis.data.edges.setProperties(Edges.properties);
            for each (var e:EdgeSprite in vis.data.edges) resetEdge(e);
            DirtySprite.renderDirty();
        }

        public function bringAllToFront(nodes:*, edges:*=null):void {
            if (edges != null) {
                for each (var e:EdgeSprite in edges)
                    bringToFront(e);
            }
            if (nodes != null) {
                for each (var n:NodeSprite in nodes)
                    bringToFront(n);
            }
        }
        
        public function bringToFront(ds:DataSprite):void {
            // Bring the node to front, too:
            GraphUtils.bringToFront(ds);
            // Do not forget the node's label!
            GraphUtils.bringToFront(ds.props.label);
        }
        
        public function applyVisualStyle(style:VisualStyleVO):void {
            this._style = style;
            vis.applyVisualStyle(style);
        }
        
        public function updateLabels(group:String=null):void {
            vis.updateLabels(group);
        }
        
        public function update():void {         
            vis.update();
        }
		
        // ========[ PRIVATE METHODS ]==============================================================
		
		private function highlightSelectedNode(n:NodeSprite):void {
            if (n != null) {
                n.fillColor = Nodes.fillColor(n);
                n.lineWidth = Nodes.selectionLineWidth(n);
                n.lineColor = Nodes.lineColor(n);
                n.alpha = Nodes.selectionAlpha(n);
                n.filters = Nodes.filters(n, true);
                DirtySprite.renderDirty();
            }
        }
        
        private function highlightSelectedEdge(e:EdgeSprite):void {
            if (e != null) {
                e.lineWidth = Edges.lineWidth(e);
                e.lineColor = Edges.lineColor(e);
                e.props.sourceArrowColor = Edges.sourceArrowColor(e);
                e.props.targetArrowColor = Edges.targetArrowColor(e);
                e.alpha = Edges.alpha(e);
                e.filters = Edges.filters(e);
                DirtySprite.renderDirty();
            }
        }
		
		/**
         * Zoom the "camera" by the specified scale factor.
         */
        private function zoomBy(scale:Number):void { trace("-> Zoom by: " + scale);            
            if (scale > 0) {
                Displays.zoomBy(vis, scale, stage.stageWidth/2, stage.stageHeight/2);
                // Let others know about the new scale:
                dispatchEvent(new GraphViewEvent(GraphViewEvent.SCALE_CHANGE, vis.scaleX));
            }
        }
		
		private function resize():void {
		    width = stage.stageWidth;
            height = stage.stageHeight;
		}
		
		private function createVisualization(data:Data, layout:String):GraphVis {
		    vis = new GraphVis(data, _config);
		    var b:Rectangle = GraphUtils.calculateGraphDimension(data.nodes, layout, _style);
            vis.bounds = b;

            addChild(vis);
            vis.applyVisualStyle(_style);
            
            return vis;
		}
	}
}