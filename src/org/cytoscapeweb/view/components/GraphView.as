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
    
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    
    import mx.core.UIComponent;
    
    import org.cytoscapeweb.events.GraphViewEvent;
    import org.cytoscapeweb.model.data.ConfigVO;
    import org.cytoscapeweb.model.data.VisualStyleVO;
    import org.cytoscapeweb.util.CompoundNodes;
    import org.cytoscapeweb.util.Edges;
    import org.cytoscapeweb.util.GraphUtils;
    import org.cytoscapeweb.util.Groups;
    import org.cytoscapeweb.util.Layouts;
    import org.cytoscapeweb.util.Nodes;
    import org.cytoscapeweb.util.Utils;
    import org.cytoscapeweb.util.methods.$each;
    import org.cytoscapeweb.vis.data.CompoundNodeSprite;
    
    public class GraphView extends UIComponent {
        
        // ========[ CONSTANTS ]====================================================================

        // ========[ PRIVATE PROPERTIES ]===========================================================
    
        private var _style:VisualStyleVO;
        private var _config:ConfigVO;

        // ========[ PUBLIC PROPERTIES ]============================================================

        public var vis:GraphVis;
        
        public function get viewCenter():Point {
            var vc:Point = new Point(stage.stageWidth/2, stage.stageHeight/2); // canvas center
            vc = vis.globalToLocal(vc); // in case vis is not positioned in (0,0)
            
            var b:Rectangle = vis.getRealBounds();
            vc.x -= b.x;
            vc.y -= b.y;
            vc.x *= vis.scaleX;
            vc.y *= vis.scaleX;
            
            return vc;
        }

        // ========[ CONSTRUCTOR ]==================================================================

        public function GraphView() {
            doubleClickEnabled = true;
            
            this.addEventListener(Event.ADDED_TO_STAGE, function(evt:Event):void {
                hitArea = Sprite(parent);
            });
        }
        
        // ========[ PUBLIC METHODS ]===============================================================

        public function draw(data:Data, config:ConfigVO, style:VisualStyleVO,
                             scale:Number, viewCenter:Point):void {
            this._config = config;
            this._style = style;
            hitArea = Sprite(parent);
            
            dispatchEvent(new GraphViewEvent(GraphViewEvent.RENDER_INITIALIZE));
            resize();

            createVisualization(data, config.currentLayout.name);

            if (scale !== 1.0)
                scale = zoomTo(scale);
            
            // -----------------------------
            var par:Parallel = applyLayout(config.currentLayout);
            
            par.addEventListener(TransitionEvent.END, function(evt:TransitionEvent):void {
                evt.currentTarget.removeEventListener(evt.type, arguments.callee);
                evt.currentTarget.dispose();
                dispatchEvent(new GraphViewEvent(GraphViewEvent.RENDER_COMPLETE));
                
                // Set the view center:
                if (viewCenter != null && config.currentLayout.options.fitToScreen == false) {
                    var cc:Point = new Point(stage.stageWidth/2, stage.stageHeight/2); // canvas center
                    cc = vis.globalToLocal(cc); // in case vis is not positioned in (0,0)
                    
                    var vc:Point = vis.globalToLocal(viewCenter);
                    
                    // We cannot assume the graph was aligned at (0,0)!
                    var gb:Rectangle = vis.getRealBounds();
                    vc.x -= gb.x;
                    vc.y -= gb.y;
                    
                    // Move the center of the viewport to the specified position (it actually moves vis)
                    var dx:Number = (cc.x - vc.x)*scale;
                    var dy:Number = (cc.y - vc.y)*scale;
                    panGraph(dx, dy);
                }
            });
            par.play();
        }

        public function applyLayout(layout:Object):Parallel {
            dispatchEvent(new GraphViewEvent(GraphViewEvent.LAYOUT_INITIALIZE));
            resize();
            
            var par:Parallel = new Parallel();
            vis.bounds = GraphUtils.calculateGraphDimension(vis.data.nodes, name);
            var t:Transition = vis.applyLayout(layout);
            par.add(t);
          
            par.addEventListener(TransitionEvent.END, function(evt:TransitionEvent):void {
                evt.currentTarget.removeEventListener(evt.type, arguments.callee);
                
                var layout:Object = _config.currentLayout;
                if (layout.name !== Layouts.PRESET || layout.options.fitToScreen === true) {
                    zoomToFit();
                    centerGraph();
                }
                
                if (Utils.isLinux()) DirtySprite.renderDirty();
                
                dispatchEvent(new GraphViewEvent(GraphViewEvent.LAYOUT_COMPLETE));
            });
            
            return par;
        }

        /**
        * Zoom the "camera" until it reaches the required scale.
        * @return The actual scale value after the zooming is executed.
        */
        public function zoomTo(scale:Number):Number { trace("-> Zoom to: " + scale);
            if (scale < _config.minZoom)
                scale = _config.minZoom;
            else if (scale > _config.maxZoom)
                scale = _config.maxZoom;
            
            var delta:Number = scale / vis.scaleX;
            zoomBy(delta);
            
            return scale;
        }
        
        public function zoomToFit():Number {
            // Reset zoom first:
            if (vis.scaleX != 1)
               zoomTo(1);
            
            var scale:Number = 1;
            var b:Rectangle = vis.getRealBounds();
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
                if (n is CompoundNodeSprite && (n as CompoundNodeSprite).isInitialized()) {
                    n.size = CompoundNodes.size(n);
                    n.fillColor = CompoundNodes.fillColor(n);
                    n.lineWidth = CompoundNodes.lineWidth(n);
                    n.lineColor = CompoundNodes.lineColor(n);
                    n.alpha = CompoundNodes.alpha(n);
                    n.props.transparent = CompoundNodes.transparent(n);
                    n.shape = CompoundNodes.shape(n);
                    n.filters = CompoundNodes.filters(n);
                } else {
                    n.size = Nodes.size(n);
                    n.fillColor = Nodes.fillColor(n);
                    n.lineWidth = Nodes.lineWidth(n);
                    n.lineColor = Nodes.lineColor(n);
                    n.alpha = Nodes.alpha(n);  
                    n.props.transparent = Nodes.transparent(n);
                    n.shape = Nodes.shape(n);
                    n.filters = Nodes.filters(n);
                }
                
                if (n.props.label != null) {
                    n.props.label.alpha = n.alpha;
                }
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
                e.props.lineStyle = Edges.lineStyle(e);
                e.props.curvature = Edges.curvature(e);
                e.filters = Edges.filters(e);
                if (e.props.label != null) e.props.label.alpha = e.alpha;
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
        }
        
        public function resetAllEdges():void {
            for each (var e:EdgeSprite in vis.data.edges) resetEdge(e);
        }

        public function bringAllToFront(nodes:*, edges:*=null):void {
            if (edges != null) {
                for each (var e:EdgeSprite in edges) bringToFront(e);
            }
            if (nodes != null) {
                for each (var n:NodeSprite in nodes) bringToFront(n);
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
            vis.refreshVisualProperties(style);
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
                if (n is CompoundNodeSprite && (n as CompoundNodeSprite).isInitialized()) {
                    n.fillColor = CompoundNodes.fillColor(n);
                    n.lineWidth = CompoundNodes.selectionLineWidth(n);
                    n.lineColor = CompoundNodes.lineColor(n);
                    n.alpha = CompoundNodes.selectionAlpha(n);
                    n.props.transparent = CompoundNodes.transparent(n);
                    n.filters = CompoundNodes.filters(n, true);
                } else {
                    n.fillColor = Nodes.fillColor(n);
                    n.lineWidth = Nodes.selectionLineWidth(n);
                    n.lineColor = Nodes.lineColor(n);
                    n.alpha = Nodes.selectionAlpha(n);
                    n.props.transparent = Nodes.transparent(n);
                    n.filters = Nodes.filters(n, true);
                }
                
                if (n.props.label != null) {
                    n.props.label.alpha = n.alpha;
                }
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
                if (e.props.label != null) e.props.label.alpha = e.alpha;
            }
        }
        
        /**
         * Zoom the "camera" by the specified scale factor.
         */
        private function zoomBy(scale:Number):void {
            if (scale > 0) {
                var prevScale:Number = vis.scaleX;
                Displays.zoomBy(vis, scale, stage.stageWidth/2, stage.stageHeight/2);
                
                // Update node labels and compound bounds when zooming in, because there is a
                // precision problem if the labeler runs when the scale is near zero,
                // which causes misaligned labels later.
                if (prevScale < 0.5) {
                    if (_config.nodeLabelsVisible) {
                        if (vis.nodeLabeler.enabled) {
                            vis.nodeLabeler.operate();
                        }
                        if (vis.compoundNodeLabeler.enabled) {
                            vis.compoundNodeLabeler.operate();
                            vis.updateAllCompoundBounds();
                        }
                    }
                }
                
                // Let others know about the new scale:
                dispatchEvent(new GraphViewEvent(GraphViewEvent.SCALE_CHANGE, vis.scaleX));
            }
        }
        
        private function resize():void {
            width = stage.stageWidth;
            height = stage.stageHeight;
        }
        
        private function createVisualization(data:Data, layoutName:String):GraphVis {
            vis = new GraphVis(data, _config);
            addChild(vis);
            
            vis.refreshVisualProperties(_style);
            vis.bounds = GraphUtils.calculateGraphDimension(data.nodes, layoutName);
            
            return vis;
        }
    }
}