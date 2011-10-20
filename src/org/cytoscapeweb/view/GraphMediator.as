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
package org.cytoscapeweb.view {
    import flare.animate.Parallel;
    import flare.display.DirtySprite;
    import flare.util.Arrays;
    import flare.vis.data.Data;
    import flare.vis.data.DataSprite;
    import flare.vis.data.EdgeSprite;
    import flare.vis.data.NodeSprite;
    import flare.vis.events.SelectionEvent;
    
    import flash.display.DisplayObject;
    import flash.events.KeyboardEvent;
    import flash.events.MouseEvent;
    import flash.events.TimerEvent;
    import flash.geom.Point;
    import flash.ui.Keyboard;
    import flash.utils.Timer;
    
    import org.cytoscapeweb.ApplicationFacade;
    import org.cytoscapeweb.events.DragEvent;
    import org.cytoscapeweb.events.GraphViewEvent;
    import org.cytoscapeweb.model.data.VisualStyleBypassVO;
    import org.cytoscapeweb.model.data.VisualStyleVO;
    import org.cytoscapeweb.util.CompoundNodes;
    import org.cytoscapeweb.util.Edges;
    import org.cytoscapeweb.util.ExternalFunctions;
    import org.cytoscapeweb.util.Groups;
    import org.cytoscapeweb.util.Nodes;
    import org.cytoscapeweb.util.Utils;
    import org.cytoscapeweb.util.VisualProperties;
    import org.cytoscapeweb.util.methods.$hasListener;
    import org.cytoscapeweb.view.components.GraphView;
    import org.cytoscapeweb.view.components.GraphVis;
    import org.cytoscapeweb.view.controls.EnclosingSelectionControl;
    import org.cytoscapeweb.view.controls.EventDragControl;
    import org.cytoscapeweb.vis.data.CompoundNodeSprite;
    import org.puremvc.as3.interfaces.INotification;


    public class GraphMediator extends BaseMediator {
    
        // ========[ CONSTANTS ]====================================================================
    
        /** Cannonical name of the Mediator. */
        public static const NAME:String = "GraphMediator";
        
        // ========[ PRIVATE PROPERTIES ]===========================================================

        private var _isMouseOverView:Boolean;
        private var _mouseDownViewCounter:uint;
        private var _draggingNode:Boolean;
        private var _draggingGraph:Boolean;
        private var _draggingComponent:Boolean;
        private var _selecting:Boolean;
        private var _shiftDown:Boolean;
        private var _dragAllTimer:Timer;
        
        private var _dragControl:EventDragControl;
        
        private function get dragControl():EventDragControl {
            if (_dragControl == null) {
                _dragControl = new EventDragControl(NodeSprite);
                _dragControl.addEventListener(DragEvent.START, onDragNodeStart);
                _dragControl.addEventListener(DragEvent.STOP, onDragNodeStop);
                _dragControl.addEventListener(DragEvent.DRAG, onDragNode);
            }
            
            return _dragControl;
        }
        
        private var _selectionControl:EnclosingSelectionControl;
        
        private function get selectionControl():EnclosingSelectionControl {
            if (_selectionControl == null) {
                _selectionControl = new EnclosingSelectionControl(DataSprite, 
                                                                  onSelect, onDeselect,
                                                                  graphView);
                _selectionControl.fireImmediately = false;
                // Set visual properties according to current style:
                setStyleToSelectionControl(configProxy.visualStyle);
                // It is important to attach it here, or the first attempt to use the
                // drag-selection will not work:
                _selectionControl.attach(graphView);
                _selectionControl.enabled = false;
            }
            
            return _selectionControl;
        }
        
        private function get _graphScale():Number {
            return vis.scaleX;
        }
        
        private function get dragging():Boolean {
            return _draggingGraph || _draggingComponent || _draggingNode;
        }
   
        // ========[ PUBLIC PROPERTIES ]============================================================
   
        public function get graphView():GraphView {
            return viewComponent as GraphView;
        }
        
        public function get vis():GraphVis {
            return graphView.vis;
        }
   
        // ========[ CONSTRUCTOR ]==================================================================
   
        public function GraphMediator(viewComponent:Object) {
            super(NAME, viewComponent, this);
            graphView.addEventListener(GraphViewEvent.RENDER_INITIALIZE, onRenderInitialize, false, 0, true);
            graphView.addEventListener(GraphViewEvent.SCALE_CHANGE, onScaleChange, false, 0, true);
            graphView.addEventListener(MouseEvent.ROLL_OVER, onRollOverView, false, 0, true);
            graphView.addEventListener(MouseEvent.ROLL_OUT, onRollOutView, false, 0, true);
        }

        // ========[ PUBLIC METHODS ]===============================================================

        /** @inheritDoc */
        override public function getMediatorName():String {
            return NAME;
        }
        
        /** @inheritDoc */
        override public function listNotificationInterests():Array {
            return [ApplicationFacade.PAN_GRAPH,
                    ApplicationFacade.ENABLE_GRAB_TO_PAN,
                    ApplicationFacade.CENTER_GRAPH];
        }

        /** @inheritDoc */
        override public function handleNotification(note:INotification):void {
            switch (note.getName()) {
                case ApplicationFacade.ENABLE_GRAB_TO_PAN:
                    updateCursor();
                    break;
                case ApplicationFacade.PAN_GRAPH:
                    graphView.panGraph(-note.getBody().panX, -note.getBody().panY);
                    break;
                case ApplicationFacade.CENTER_GRAPH:
                    graphView.centerGraph();
                    break;
                default:
                    break;
            }
        }
        
        public function drawGraph():void {
            graphView.draw(graphProxy.graphData,
                           configProxy.config,
                           configProxy.visualStyle, 
                           graphProxy.zoom,
                           graphProxy.viewCenter);
        }
        
        public function applyVisualStyle(style:VisualStyleVO):void {
            graphView.applyVisualStyle(style);
            setStyleToSelectionControl(style);
        }
        
        public function applyVisualBypass(bypass:VisualStyleBypassVO):void {
            vis.refreshVisualProperties();
        }
        
        public function applyLayout(layout:Object):void {
            var par:Parallel = graphView.applyLayout(layout);
            par.play();
        }
        
        public function mergeEdges(merge:Boolean):void {
            vis.data.edges.setProperties(Edges.properties);
            graphView.updateLabels(Groups.EDGES);
        }
        
        public function updateAllCompoundBounds():void {
            if (graphProxy.compoundGraph) {
                vis.updateAllCompoundBounds();
                graphView.updateLabels(Groups.COMPOUND_NODES);
            }
        }
        
        public function updateLabels():void {
            graphView.updateLabels();
            updateAllCompoundBounds();
        }
        
        public function selectNodes(nodes:Array):void {
            if (nodes != null && nodes.length > 0) {
                graphView.selectNodes(nodes);
            }
        }
        
        public function selectEdges(edges:Array):void { 
            if (edges != null && edges.length > 0) {
                if (graphProxy.edgesMerged) {
                    // So merged edges are reset when a regular edge was selected.
                    // TODO: bring merged edges to front too!
                    vis.data.edges.setProperties(Edges.properties);
                } else {
                    graphView.selectEdges(edges);
                }
            }
        }
        
        public function deselectNodes(nodes:Array):void {
            graphView.deselectNodes(nodes);
        }
        
        public function deselectEdges(edges:Array):void {
            if (graphProxy.edgesMerged) {
                // So merged edges are reset when a regular edge was deselected.
                vis.data.edges.setProperties(Edges.properties);
            } else {
                graphView.resetAllEdges();
            }
        }
        
        public function updateView():void {
            vis.data.nodes.setProperties(Nodes.properties);
            vis.data.edges.setProperties(Edges.properties);
            vis.data.group(Groups.COMPOUND_NODES).setProperties(CompoundNodes.properties);
            vis.updateLabels(Groups.NODES);
            vis.updateLabels(Groups.COMPOUND_NODES);
            vis.updateLabels(Groups.EDGES);
            separateDisconnected();
        }
        
        public function updateFilters(updateNodes:Boolean, updateEdges:Boolean,
                                      updateAllProperties:Boolean):void {
            if (updateNodes) {
                if (updateAllProperties) {
                    vis.data.nodes.setProperties(Nodes.properties);
                    vis.data.group(Groups.COMPOUND_NODES).setProperties(CompoundNodes.properties);
                } else {
                    for each (var n:NodeSprite in graphProxy.graphData.nodes) {
                        n.visible = Nodes.visible(n);
                    }
                }
                vis.updateLabels(Groups.NODES);
                vis.updateLabels(Groups.COMPOUND_NODES);
            }
            // When filtering nodes, it may be necessary to show/hide related edges as well:
            if (updateNodes || updateEdges) {
                if (updateAllProperties) {
                    vis.data.edges.setProperties(Edges.properties);
                } else {
                    var edges:* = graphProxy.graphData.edges;
                    var e:EdgeSprite;
                    for each (e in edges) {
                        e.props.curvature = Edges.curvature(e);
                        e.visible = Edges.visible(e);
                    }
                }
                vis.updateLabels(Groups.EDGES);
            }
            separateDisconnected();
            
            // it is required to update compound bounds after filtering in order
            // to keep compound bounds valid with respect to its children
            updateAllCompoundBounds();
            
            // it is also required to operate compound node labeler, to update
            // compound node labels
            if (configProxy.nodeLabelsVisible) {
                vis.compoundNodeLabeler.operate();
            }
        }

        public function resetDataSprite(ds:DataSprite):void {            
            if (ds is NodeSprite) {
                graphView.resetNode(NodeSprite(ds));
            } else if (ds is EdgeSprite) {
                graphView.resetEdge(EdgeSprite(ds));
            }
        }
        
        public function initialize(gr:String, items:Array):void {
            addListeners(items);
            updateDataSprites(gr, items);
            vis.updateLabels(gr);
        }
        
        public function separateDisconnected():void {
            vis.separateDisconnected();
        }
        
        public function dispose(items:Array):void {
            var ds:DataSprite, n:CompoundNodeSprite, child:CompoundNodeSprite;
            var e:EdgeSprite, me:EdgeSprite;
            var stack:Array = items.concat();
            var mergedEdges:Array = [];
            
            // Remove event listeners:
            while (stack.length > 0) {
                ds = stack.pop();
                if (ds.props.$disposed) continue;
                
                trace("Disposing " + ds + " (" + ds.data.id + ")...");
                disposeDataSprite(ds);
                
                if (ds is CompoundNodeSprite) {
                    n = ds as CompoundNodeSprite;
                    
                    // Also dispose its linked edges:
                    n.visitEdges(function(e:EdgeSprite):Boolean {
                        if (!e.props.$disposed) stack.push(e);
                        return false;
                    });
                    
                    if (n.nodesCount > 0) {
                        for each (child in n.getNodes()) {
                            if (!child.props.$disposed) stack.push(child);
                        }
                    }
                } else if (ds is EdgeSprite) { 
                    if (ds.props.$merged && ds.props.$edges != null) {
                        for each (e in ds.props.$edges) {
                            if (!e.props.$disposed) stack.push(e);
                        }
                    } else if (ds.props.$parent != null) {
                        // save for later disposal...
                        if (!ds.props.$parent.props.$disposed)
                            mergedEdges.push(ds.props.$parent);
                    }
                }
            }
            
            var shallDispose:Boolean;
            
            // Finally dispose "empty" mergedEdges:
            for each (me in mergedEdges) {
                if (!me.props.$disposed) {
                    shallDispose = true;
                    
                    for each (e in me.props.$edges) {
                        if (!e.props.$disposed) {
                            shallDispose = false;
                            break;
                        }
                    }
                    
                    if (shallDispose) {
                        trace("Disposing merged Edge (" + me.data.id + ")...");
                        disposeDataSprite(me);
                    }
                }
            }
        }
        
        public function zoomGraphTo(scale:Number):void {
            graphView.zoomTo(scale);
        }
        
        public function zoomGraphToFit():void {
            graphView.zoomToFit();
            graphView.centerGraph();
        }
        
        public function getViewCenter():Point {
            return graphView.viewCenter;
        }
        
        public function updateParentNodes(items:Array):void {
            if (items != null) {
                var ds:DataSprite, parent:CompoundNodeSprite;
                
                for each (ds in items) {
                    if (ds is CompoundNodeSprite) {
                        parent = ds as CompoundNodeSprite;
                        
                        while (parent != null) {trace("update parent >>> " + parent.data.id);
                            // update the bounds of the compound node
                            if (parent.nodesCount > 0) {
                                this.vis.updateCompoundBounds(parent);
                            } else {
                                this.updateDataSprites(Groups.NODES, [parent]);
                            }
                            
                            if (parent.data.parent != null) {
                                parent = this.graphProxy.getNode(parent.data.parent);
                            } else {
                                // reached top, no more parent
                                parent = null;
                            }
                        }
                    }
                }
                
                updateLabels();
            }
        }
        
        public function updateDataSprites(gr:String, items:Array):void {
            var props:Object; 
            
            if (gr === Groups.NODES) {
                props = Nodes.properties;
            } else if (gr === Groups.COMPOUND_NODES) {
                props = CompoundNodes.properties;
            } else {
                props = Edges.properties;
            }
            
            for (var name:String in props) {
                Arrays.setProperty(items, name, props[name], null);
            }
            
            separateDisconnected();
        }
        
        public function updateCompoundNode(cns:CompoundNodeSprite):void {
            if (cns != null) {
                // initialize visual properties
                this.updateDataSprites(Groups.COMPOUND_NODES, [cns]);
                
                if (configProxy.nodeLabelsVisible) {
                    graphView.updateLabels(Groups.NODES);
                }
                
                // update bounds of the target compound node up to  the root
                while (cns != null) {
                    // update the bounds of the compound node
                    this.vis.updateCompoundBounds(cns);
                    // render the compound node with new bounds
                    cns.render();
                    // advance to the next parent node
                    cns = this.graphProxy.getNode(cns.data.parent);
                }
                
                if (configProxy.nodeLabelsVisible) {
                    graphView.updateLabels(Groups.NODES);
                }
            }
        }
        
        // ========[ PRIVATE METHODS ]==============================================================

        private function onRenderInitialize(evt:GraphViewEvent):void {
            graphView.addEventListener(GraphViewEvent.LAYOUT_INITIALIZE, onLayoutInitialize, false, 0, true);
            graphView.addEventListener(GraphViewEvent.RENDER_COMPLETE, onRenderComplete, false, 0, true);
        }

        private function onRenderComplete(evt:GraphViewEvent):void {
            // First, add all the initial listeners to each NODE:
            // --------------------------------------------------
            addListeners(vis.data.nodes);
            addListeners(vis.data.edges);
            
            dragControl.attach(vis);
            
            // Then add the VIEW listeners:
            // ---------------------------------
            // 1. KEY events:
            graphView.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown, false, 0, true);
            graphView.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp, false, 0, true);
            // 2. DRAG the whole graph:
            graphView.stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDownView, false, 0, true);
            // 3. 2-Click:
            graphView.addEventListener(MouseEvent.DOUBLE_CLICK, onDoubleClickView, false, 0, true);
            
            evt.currentTarget.removeEventListener(evt.type, arguments.callee);
            sendNotification(ApplicationFacade.GRAPH_DRAWN);
        }
        
        private function onScaleChange(evt:GraphViewEvent):void {
            sendNotification(ApplicationFacade.ZOOM_CHANGED, evt.data);
        }
        
        private function onLayoutInitialize(evt:GraphViewEvent):void {
            graphView.addEventListener(GraphViewEvent.LAYOUT_COMPLETE, onLayoutComplete, false, 0, true);
            // Remove this listener, because reloading the swf file does not seem to kill it,
            // so it would have two listeners for the same action, after onRenderInitialize is called again:
            evt.currentTarget.removeEventListener(evt.type, arguments.callee);
            sendNotification(ApplicationFacade.INDETERMINATE_TASK_START);
        }
        
        private function onLayoutComplete(evt:GraphViewEvent):void {
            // We don't need this listener anymore:
            evt.currentTarget.removeEventListener(evt.type, arguments.callee);
            sendNotification(ApplicationFacade.INDETERMINATE_TASK_COMPLETE);
            // Add the LAYOUT INITIALIZE listener again:
            graphView.addEventListener(GraphViewEvent.LAYOUT_INITIALIZE, onLayoutInitialize, false, 0, true);
            
            // Call external listener:
            if ($hasListener("layout")) {
                var body:Object = { functionName: ExternalFunctions.INVOKE_LISTENERS, 
                                    argument: { type: "layout", value: configProxy.currentLayout } };
                sendNotification(ApplicationFacade.CALL_EXTERNAL_INTERFACE, body);
            }
        }
        
        private function addListeners(items:*):void {
            for each (var ds:DataSprite in items) {
                ds.doubleClickEnabled = true;
                
                if (ds is NodeSprite) {
                    ds.addEventListener(MouseEvent.ROLL_OVER, onRollOverNode, false, 0, true);
                    ds.addEventListener(MouseEvent.DOUBLE_CLICK, onDoubleClickNode, false, 0, true);
                    ds.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDownNode, false, 0, true);
                } else {
                    ds.addEventListener(MouseEvent.ROLL_OVER, onRollOverEdge, false, 0, true);
                    ds.addEventListener(MouseEvent.ROLL_OUT, onRollOutEdge, false, 0, true);
                    ds.addEventListener(MouseEvent.DOUBLE_CLICK, onDoubleClickEdge, false, 0, true);
                    ds.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDownEdge, false, 0, true);
                }
            }
        }
        
        // VIEW listener functions:
        // -----------------------------------------------------------------------------------------
        private function onKeyDown(evt:KeyboardEvent):void { trace("* Key DOWN :: " + evt.keyCode + "/" + evt.charCode);
            if (evt.keyCode === Keyboard.SHIFT) {
                _shiftDown = true;
                var dirty:Boolean = _isMouseOverView || _selecting || dragging;
                if (dirty) updateCursor();
            }
        }
        
        private function onKeyUp(evt:KeyboardEvent):void { trace("* Key UP :: " + evt.keyCode + "/" + evt.charCode);
            if (evt.keyCode === Keyboard.SHIFT) {
                _shiftDown = false;
                if (_isMouseOverView) updateCursor();
            }
        }

        private function onRollOverView(evt:MouseEvent):void { trace("<<<< Roll OVER [View]");
            _isMouseOverView = true;
            updateCursor();
        }
        
        private function onRollOutView(evt:MouseEvent):void { trace(">>>> Roll OUT [View]");
            _isMouseOverView = false;
            if (!_selecting && !dragging)
                sendNotification(ApplicationFacade.UPDATE_CURSOR);
        }
        
        private function onMouseDownView(evt:MouseEvent):void { trace("* Mouse DOWN [View]");
            if (configProxy.grabToPanEnabled && graphProxy.rolledOverEdge == null) {
                // DRAGGING the whole graph...
                startDragGraph();
            } else if (!configProxy.grabToPanEnabled) {
                _mouseDownViewCounter++;
                
                if (configProxy.mouseDownToDragDelay >= 0) {
                    _dragAllTimer = new Timer(configProxy.mouseDownToDragDelay, 1);
                    _dragAllTimer.addEventListener(TimerEvent.TIMER, function(te:TimerEvent):void {
                       if (!_selecting) { trace("* Hold Mouse DOWN - will drag...");
                           graphView.stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUpToDeselect);
                           graphView.stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUpToClick);
                           graphView.stage.removeEventListener(MouseEvent.MOUSE_MOVE, onDragSelectionStart);
                           startDragGraph();
                       }
                    });
                    _dragAllTimer.start();
                }
                
                // DRAG-SELECTION...
                updateCursor();
                // Add the SELECTION CONTROL again:
                selectionControl.enabled = !dragging;
    
                if (_shiftDown) {
                    // If SHIFT is pressed, add selected nodes to the selection group, thus
                    // ignoring the previously selected ones in order to avoid deselecting them
                    // "accidentally" when the selection rectangle encloses an already selected node:
                    selectionControl.filter = function(d:DisplayObject):Boolean {
                        // TODO: filter edges OR nodes based on config param
                        return d is DataSprite && !DataSprite(d).props.$selected;
                    }
                } else if (!dragging && graphProxy.rolledOverEdge == null) {
                    // TODO: edges OR nodes based on config param
                    selectionControl.filter = DataSprite;
                    graphView.stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUpToDeselect, false, 0, true);
                }

                graphView.stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUpToClick, false, 0, true);
                graphView.stage.addEventListener(MouseEvent.MOUSE_MOVE, onDragSelectionStart, false, 0, true);
            }
        }
        
        private function onMouseUpToClick(evt:MouseEvent):void { trace("* Mouse UP / CLICK [View]");
            evt.currentTarget.removeEventListener(evt.type, arguments.callee);
            if (_dragAllTimer != null && _dragAllTimer.running) _dragAllTimer.stop();
            graphView.stage.removeEventListener(MouseEvent.MOUSE_MOVE, onDragSelectionStart);
            sendNotification(ApplicationFacade.CLICK_EVENT, { mouseX: evt.stageX, mouseY: evt.stageY });
        }
        
        private function onMouseUpToDeselect(evt:MouseEvent):void { trace("* Mouse UP / Deselect all [View]");
            evt.currentTarget.removeEventListener(evt.type, arguments.callee);
            sendNotification(ApplicationFacade.DESELECT_ALL, Groups.NONE);
        }
        
        private function onMouseUpToStopPanning(evt:MouseEvent):void { trace("* Mouse UP / STOP PANNING [View]");
            evt.currentTarget.removeEventListener(evt.type, arguments.callee);
            graphView.stage.removeEventListener(MouseEvent.MOUSE_MOVE, onDragSelectionStart);
            vis.stopDrag();
            _draggingGraph = false;
            if (_isMouseOverView) updateCursor();
            else sendNotification(ApplicationFacade.UPDATE_CURSOR);
        }
        
        private function onDoubleClickView(evt:MouseEvent):void { trace("* 2-CLICK [View]");
            if (_mouseDownViewCounter > 1) {
                if (!_shiftDown && configProxy.grabToPanEnabled)
                    sendNotification(ApplicationFacade.DESELECT_ALL);
                    
                sendNotification(ApplicationFacade.DOUBLE_CLICK_EVENT,
                                 { mouseX: evt.stageX, mouseY: evt.stageY });
            }
        }
        
        private function onDragSelectionStart(evt:MouseEvent):void { trace("* Drag Selection START [View]");
            evt.currentTarget.removeEventListener(evt.type, arguments.callee);
            if (_dragAllTimer != null && _dragAllTimer.running) _dragAllTimer.stop();
            graphView.stage.addEventListener(MouseEvent.MOUSE_UP, onDragSelectionEnd, false, 0, true);
            graphView.stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUpToDeselect);
            graphView.stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUpToClick);
            _mouseDownViewCounter = 0;

            // If SHIFT key is pressed, keep the previously selected elements.
            // Otherwise, deselect everything first:
            if (!_shiftDown) sendNotification(ApplicationFacade.DESELECT_ALL, Groups.NONE);
            _selecting = true;
        }
        
        private function onDragSelectionEnd(evt:MouseEvent):void { trace("* Drag Selection END [View]");
            evt.currentTarget.removeEventListener(evt.type, arguments.callee);
            _selecting = false;
            if (_isMouseOverView) updateCursor();
            else sendNotification(ApplicationFacade.UPDATE_CURSOR);
        }
        
        // NODE listener functions:
        // -----------------------------------------------------------------------------------------
        private function onRollOverNode(evt:MouseEvent):void {
            if (_draggingNode || dragging || _selecting) return;

            var n:NodeSprite = evt.target as NodeSprite;
            n.addEventListener(MouseEvent.ROLL_OUT, onRollOutNode, false, 0, true);
            
            sendNotification(ApplicationFacade.ROLLOVER_EVENT, n);
            updateCursor();
        }
        
        private function onRollOutNode(evt:MouseEvent):void {
            if (dragging || _selecting) return;

            var n:NodeSprite = evt.target as NodeSprite;
            sendNotification(ApplicationFacade.ROLLOUT_EVENT, n);
            
            n.removeEventListener(MouseEvent.ROLL_OUT, onRollOutNode);
            updateCursor();
            evt.stopImmediatePropagation();
        }
        
        private function onMouseDownNode(evt:MouseEvent):void { trace("** Mouse DOWN [node]");
            var n:NodeSprite = evt.target as NodeSprite;
            
            if (configProxy.mouseDownToDragDelay >= 0) {
                _dragAllTimer = new Timer(configProxy.mouseDownToDragDelay, 1);
                _dragAllTimer.addEventListener(TimerEvent.TIMER, function(te:TimerEvent):void {
                    trace("* Hold Mouse DOWN - will drag part...");
                    _draggingComponent = true;
                    updateCursor();
                    vis.showDragRectangle(n);
                    var data:Data = vis.getDisconnectedData(n);
                    graphView.bringAllToFront(data.nodes);
                    graphView.bringToFront(n);
                });
                _dragAllTimer.start();
            }
            
            n.addEventListener(MouseEvent.MOUSE_UP, onMouseUpNode, false, 0, true);
            n.addEventListener(MouseEvent.CLICK, onClickNode, false, 0, true);
            // Remove the SELECTION CONTROL:
            selectionControl.enabled = false;
            // To avoid clicking the background:
            graphView.stage.removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDownView);
            // Bring the target and the node to front:
            graphView.bringToFront(n);
        }
        
        private function onMouseUpNode(evt:MouseEvent):void { trace("** Mouse UP [node]");
            evt.currentTarget.removeEventListener(evt.type, arguments.callee);
            var n:NodeSprite = evt.target as NodeSprite;
            _draggingGraph = false;
            _selectionControl.enabled = true;
            updateCursor();
            // Return the MOUSE DOWN to the View, so panning is possible again:
            graphView.stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDownView, false, 0, true);
        }
        
        private function onClickNode(evt:MouseEvent):void { trace("** CLICK [node]");
            evt.currentTarget.removeEventListener(evt.type, arguments.callee);
            evt.stopImmediatePropagation();
            
            if (!dragging) {
                if (_dragAllTimer != null && _dragAllTimer.running) _dragAllTimer.stop();
                
                var n:NodeSprite = evt.target as NodeSprite;
                sendNotification(ApplicationFacade.CLICK_EVENT,
                                 { target: n, mouseX: evt.stageX, mouseY: evt.stageY });
    
                if (_shiftDown) {
                    // If SHIFT key is pressed, the clicked node is added to the selection group or
                    // removed from it, if already selected:
                    if (n.props.$selected)
                        sendNotification(ApplicationFacade.DESELECT, [n]);
                    else
                        sendNotification(ApplicationFacade.SELECT, [n]);
                } else {
                    // Clear any previous selection and select only the clicked node:
                    sendNotification(ApplicationFacade.DESELECT_ALL, Groups.NONE);
                    sendNotification(ApplicationFacade.SELECT, [n]);
                }
            }
        }
        
        private function onDoubleClickNode(evt:MouseEvent):void { trace("** 2-CLICK [node]");
            var n:NodeSprite = evt.target as NodeSprite;
            if (_dragAllTimer != null && _dragAllTimer.running) _dragAllTimer.stop();
            sendNotification(ApplicationFacade.DOUBLE_CLICK_EVENT,
                             { target: n, mouseX: evt.stageX, mouseY: evt.stageY });
            evt.stopImmediatePropagation();
        }
        
        private function onDragNodeStart(evt:DragEvent):void { trace("== START Drag Node");
            if (!_draggingComponent) {
                if (_dragAllTimer != null && _dragAllTimer.running) _dragAllTimer.stop();
                _draggingNode = true;
                updateCursor();
                this.graphProxy.resetMissingChildren();
            }
            
            evt.node.removeEventListener(MouseEvent.CLICK, onClickNode);
            sendNotification(ApplicationFacade.DRAG_START_EVENT, { target: evt.node });
        }
        
        private function onDragNodeStop(evt:DragEvent):void { trace("== STOP Drag Node");
            if (_draggingComponent) vis.hideDragRectangle();
            _draggingNode = false;
            _draggingComponent = false;
            updateCursor();
            
            // Fix a bug on Safari when mouse-up occurs out of the Flash area, which ends the
            // dragging action without dispatching a MOUSE_UP event before:
            if (evt.node.hasEventListener(MouseEvent.MOUSE_UP)) {
                evt.node.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_UP));
            }
            
            sendNotification(ApplicationFacade.DRAG_STOP_EVENT, { target: evt.node });
        }
        
        private function onDragNode(evt:DragEvent):void {
            var target:NodeSprite = evt.node;
            var nodes:*;
            var children:Array = new Array();
            
            if (_draggingComponent) {
                var data:Data = vis.getDisconnectedData(target);
                nodes = data.nodes;
            } else if (target.props.$selected) {
                // Drag the other selected nodes as well:
                children = children.concat(this.graphProxy.missingChildren);
                children = children.concat(this.graphProxy.selectedNodes);
                
                nodes = children;
            } else {
                if (target is CompoundNodeSprite) {
                    children = children.concat(
                        CompoundNodes.getChildren(target as CompoundNodeSprite));
                }
                
                children = children.concat([target]);
                nodes = children;
            }
            
            updateCursor();
            
            var amountX:Number = evt.amountX;
            var amountY:Number = evt.amountY;
            
            var ns:CompoundNodeSprite;
            var n:CompoundNodeSprite;
            
            // drag all necessary nodes
            for each (n in nodes) {
                if (n != target) {
                    n.x += amountX;
                    n.y += amountY;
                }

                // Move node labels as well, bacause they have "LAYER" policy:
                // It is faster than labeler.operate() or vis.update()!
                if (configProxy.nodeLabelsVisible && n.props.label) {
                    n.props.label.x += amountX;
                    n.props.label.y += amountY;
                }
                
                var parentId:String;
                
                // update parent compound node(s) bounds if necessary
                // if n is target node, then its parents may need to be updated.
                // if n is a selected node, then other selected nodes' parents
                // also need to be updated. (it causes problems to update bounds
                // of a compound node which is also being dragged, therefore
                // bounds updating should only be applied on the compound nodes
                // which are not being dragged)
                if (n == target || n.props.$selected) {
                    ns = n;
                    parentId = ns.data.parent
                    
                    while (parentId != null) {
                        ns = this.graphProxy.getNode(parentId);
                        
                        if (ns != null) {
                            // only update if the parent is not also being dragged
                            if (!ns.props.$selected || (n == target && !n.props.$selected)) {
                                // update the bounds of the compound node
                                this.vis.updateCompoundBounds(ns);
                                
                                // render the compound node with the new bounds
                                ns.render();
                            }
                            
                            parentId = ns.data.parent;
                        } else {
                            // reached top, no more parent
                            parentId = null;
                        }
                    }
                }
                
                // update bound coordinates of dragged compound nodes
                if (n is CompoundNodeSprite) {
                    ns = n as CompoundNodeSprite;
                    
                    if (ns.bounds != null) {
                        ns.bounds.x += amountX;
                        ns.bounds.y += amountY;
                    }
                }
            }
            
            // Necessary for Flash 10.1:
            DirtySprite.renderDirty();
            
            if (Utils.isLinux()) {
                if (configProxy.edgeLabelsVisible) graphView.updateLabels(Groups.EDGES);
            }
            
            if (_draggingComponent) vis.updateDragRectangle(amountX, amountY);
        }
        
        private function onSelect(evt:SelectionEvent):void {
            if (evt.items != null && evt.items.length > 0)
                sendNotification(ApplicationFacade.SELECT, evt.items);
        }
        
        private function onDeselect(evt:SelectionEvent):void {
            if (evt.items != null && evt.items.length > 0)
                sendNotification(ApplicationFacade.DESELECT, evt.items);
        }
        
        // EDGE listener functions:
        // -----------------------------------------------------------------------------------------
        private function onRollOverEdge(evt:MouseEvent):void {
            evt.stopImmediatePropagation();
            var e:EdgeSprite = evt.target as EdgeSprite;
            sendNotification(ApplicationFacade.ROLLOVER_EVENT, e);
            updateCursor();
        }
        
        private function onRollOutEdge(evt:MouseEvent):void {
            evt.stopImmediatePropagation();
            var e:EdgeSprite = evt.target as EdgeSprite;
            sendNotification(ApplicationFacade.ROLLOUT_EVENT, e);
            updateCursor();
        }
        
        private function onMouseDownEdge(evt:MouseEvent):void { trace("** Mouse DOWN [edge]");
            if (!_draggingGraph) {
                var e:EdgeSprite = evt.target as EdgeSprite;
                e.addEventListener(MouseEvent.CLICK, onClickEdge, false, 0, true);
                // Remove the SELECTION CONTROL:
                selectionControl.enabled = false;
            }
        }
        
        private function onClickEdge(evt:MouseEvent):void { trace("** Click [edge]");
            evt.currentTarget.removeEventListener(evt.type, arguments.callee);
            
            if (!_draggingGraph) {
                var edge:EdgeSprite = evt.target as EdgeSprite;
                if (edge == null) return;
                
                sendNotification(ApplicationFacade.CLICK_EVENT,
                                 { target: edge, mouseX: evt.stageX, mouseY: evt.stageY });
                var edgesList:Array = [edge];
    
                if (_shiftDown) {
                    // If SHIFT key is pressed, the clicked edge is added to the selection group or
                    // removed from it, if already selected:
                    if (edge.props.$selected)
                        sendNotification(ApplicationFacade.DESELECT, edgesList);
                    else
                        sendNotification(ApplicationFacade.SELECT, edgesList);
                } else {
                    // Clear any previous selection and select only the clicked edge:
                    sendNotification(ApplicationFacade.DESELECT_ALL, Groups.NONE);
                    sendNotification(ApplicationFacade.SELECT, edgesList);
                }
            }
            
            graphView.stage.removeEventListener(MouseEvent.MOUSE_MOVE, onDragSelectionStart);
            evt.stopImmediatePropagation();
        }
        
        private function onDoubleClickEdge(evt:MouseEvent):void { trace("** 2-CLICK [edge] : " + evt.target);
            var e:EdgeSprite = evt.target as EdgeSprite;
            sendNotification(ApplicationFacade.DOUBLE_CLICK_EVENT,
                             { target: e, mouseX: evt.stageX, mouseY: evt.stageY });
            graphView.stage.removeEventListener(MouseEvent.MOUSE_MOVE, onDragSelectionStart);
            evt.stopImmediatePropagation();
        }
        
        // OTHER functions:
        // -----------------------------------------------------------------------------------------
        
        private function startDragGraph():void {
            _draggingGraph = true;
            _mouseDownViewCounter = 0;
            updateCursor();
            selectionControl.enabled = false;
            vis.startDrag();
            graphView.stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUpToStopPanning, false, 0, true);
        }
        
        private function setStyleToSelectionControl(style:VisualStyleVO):void {
            if (_selectionControl == null) return;
            
            _selectionControl.fillColor = 0x8888ff;
            _selectionControl.fillAlpha = 0.2;
            _selectionControl.lineColor = 0x8888ff;
            _selectionControl.lineAlpha = 0.4;
            _selectionControl.lineWidth = 2;
            
            // Set visual properties according to current style:
            if (style.hasVisualProperty(VisualProperties.SELECTION_FILL_COLOR))
                _selectionControl.fillColor = style.getValue(VisualProperties.SELECTION_FILL_COLOR) as uint;
            if (style.hasVisualProperty(VisualProperties.SELECTION_FILL_ALPHA))
                _selectionControl.fillAlpha = style.getValue(VisualProperties.SELECTION_FILL_ALPHA) as Number;
            if (style.hasVisualProperty(VisualProperties.SELECTION_LINE_COLOR))
                _selectionControl.lineColor = style.getValue(VisualProperties.SELECTION_LINE_COLOR) as uint;
            if (style.hasVisualProperty(VisualProperties.SELECTION_LINE_ALPHA))
                _selectionControl.lineAlpha = style.getValue(VisualProperties.SELECTION_LINE_ALPHA) as Number;
            if (style.hasVisualProperty(VisualProperties.SELECTION_LINE_WIDTH))
                _selectionControl.lineWidth = style.getValue(VisualProperties.SELECTION_LINE_WIDTH) as Number;
        }
        
        private function disposeDataSprite(ds:DataSprite):void {
            // Force a roll-out, to keep things in a good state:
            if (graphProxy.rolledOverNode === ds || graphProxy.rolledOverEdge === ds)
                ds.dispatchEvent(new MouseEvent(MouseEvent.ROLL_OUT));
            
            // Remove event listeners:
            if (ds is NodeSprite) {
                ds.removeEventListener(MouseEvent.ROLL_OVER, onRollOverNode);
                ds.removeEventListener(MouseEvent.ROLL_OUT, onRollOutNode);
                ds.removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDownNode);
                ds.removeEventListener(MouseEvent.MOUSE_UP, onMouseUpNode);
                ds.removeEventListener(MouseEvent.CLICK, onClickNode);
                ds.removeEventListener(MouseEvent.DOUBLE_CLICK, onDoubleClickNode);
                
                // Delete its label:
                if (ds.props.label != null) {
                    vis.labels.removeChild(ds.props.label);
                    ds.props.label = null;
                }
            } else if (ds is EdgeSprite) {
                ds.removeEventListener(MouseEvent.ROLL_OVER, onRollOverEdge);
                ds.removeEventListener(MouseEvent.ROLL_OUT, onRollOutEdge);
                ds.removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDownEdge);
                ds.removeEventListener(MouseEvent.CLICK, onClickEdge);
                ds.removeEventListener(MouseEvent.DOUBLE_CLICK, onDoubleClickEdge);
            }
            
            // Avoinding errors in case the tooltip is about to be shown:
            ds.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_OUT, true, false, 0, 0, vis));
            ds.props.$disposed = true;
        }
        
        private function updateCursor():void {
            // TODO: send separate notifications for "rollover", "drag_start", etc,
            // instead of asking to update the cursor.
            sendNotification(ApplicationFacade.UPDATE_CURSOR, { selecting: _selecting,
                                                                draggingNode: _draggingNode,
                                                                draggingGraph: _draggingGraph,
                                                                draggingComponent: _draggingComponent,
                                                                shiftDown: _shiftDown });
        }
    }
}
