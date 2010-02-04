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
    import flare.display.TextSprite;
    import flare.vis.data.DataSprite;
    import flare.vis.data.EdgeSprite;
    import flare.vis.data.NodeSprite;
    import flare.vis.events.SelectionEvent;
    
    import flash.display.DisplayObject;
    import flash.display.Sprite;
    import flash.events.KeyboardEvent;
    import flash.events.MouseEvent;
    import flash.ui.Keyboard;
    
    import org.cytoscapeweb.ApplicationFacade;
    import org.cytoscapeweb.events.DragEvent;
    import org.cytoscapeweb.events.GraphViewEvent;
    import org.cytoscapeweb.model.data.VisualStyleVO;
    import org.cytoscapeweb.util.Edges;
    import org.cytoscapeweb.util.ExternalFunctions;
    import org.cytoscapeweb.util.GraphUtils;
    import org.cytoscapeweb.util.Groups;
    import org.cytoscapeweb.util.Nodes;
    import org.cytoscapeweb.util.VisualProperties;
    import org.cytoscapeweb.view.components.GraphView;
    import org.cytoscapeweb.view.components.SubGraphView;
    import org.cytoscapeweb.view.controls.EnclosingSelectionControl;
    import org.cytoscapeweb.view.controls.EventDragControl;
    import org.puremvc.as3.interfaces.INotification;


    public class GraphMediator extends BaseAppMediator {
    
        // ========[ CONSTANTS ]====================================================================
    
        /** Cannonical name of the Mediator. */
        public static const NAME:String = "GraphMediator";
        
        // ========[ PRIVATE PROPERTIES ]===========================================================

        private var _isMouseOverContainer:Boolean;
        private var _draggingNode:Boolean;
        private var _draggingGraph:Boolean;
        private var _selecting:Boolean;
        private var _ctrlDown:Boolean;
        private var _shiftDown:Boolean;
        
        private function get graphContainer():Sprite {
            return graphView.graphContainer;
        }
        
        private var _dragControl:EventDragControl;
        
        private function get dragControl():EventDragControl {
            if (_dragControl == null) {
                _dragControl = new EventDragControl(NodeSprite);
	            _dragControl.addEventListener(DragEvent.START, onDragNodeStart);
	            _dragControl.addEventListener(DragEvent.STOP, onEndDragNode);
	            _dragControl.addEventListener(DragEvent.DRAG, onDragNode);
            }
            
            return _dragControl;
        }
        
        private var _selectionControl:EnclosingSelectionControl;
        
        private function get selectionControl():EnclosingSelectionControl {
            if (_selectionControl == null) {
                _selectionControl = new EnclosingSelectionControl(DataSprite, 
                                                                  onSelect, onDeselect,
                                                                  graphView.graphContainer);
                _selectionControl.fireImmediately = false;
                // Set visual properties according to current style:
                setStyleToSelectionControl(configProxy.visualStyle);
                // It is important to attach it here, or the first attempt to use the
                // drag-selection will not work:
                selectionControl.attach(graphContainer);
            }
            
            return _selectionControl;
        }
        
        private function get _graphScale():Number {
            return graphContainer.scaleX;
        }
   
        // ========[ PUBLIC PROPERTIES ]============================================================
   
        public function get graphView():GraphView {
            return viewComponent as GraphView;
        }
   
        // ========[ CONSTRUCTOR ]==================================================================
   
        public function GraphMediator(viewComponent:Object) {
            super(NAME, viewComponent, this);
            graphView.addEventListener(GraphViewEvent.RENDER_INITIALIZE, onRenderInitialize, false, 0, true);
            graphView.addEventListener(GraphViewEvent.SCALE_CHANGE, onScaleChange, false, 0, true);
            graphContainer.addEventListener(MouseEvent.ROLL_OVER, onRollOverContainer, false, 0, true);
            graphContainer.addEventListener(MouseEvent.ROLL_OUT, onRollOutContainer, false, 0, true);
        }

        // ========[ PUBLIC METHODS ]===============================================================

        override public function getMediatorName():String {
            return NAME;
        }
        
        override public function listNotificationInterests():Array {
            return [ApplicationFacade.PAN_GRAPH, ApplicationFacade.CENTER_GRAPH];
        }

        override public function handleNotification(note:INotification):void {
            switch (note.getName()) {
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
            graphView.draw(graphProxy.dataList,
                           configProxy.config,
                           configProxy.visualStyle,
                           configProxy.currentLayout);
        }
        
        public function applyVisualStyle(style:VisualStyleVO):void {
            //sendNotification(ApplicationFacade.INDETERMINATE_TASK_START);
            graphView.applyVisualStyle(style);
            setStyleToSelectionControl(style);
            //sendNotification(ApplicationFacade.INDETERMINATE_TASK_COMPLETE);
        }
        
        public function applyVisualBypass(style:VisualStyleVO):void {
            // TODO: make it faster (do not have to reapply everything)
            graphView.applyVisualStyle(style);
        }
        
        public function applyLayout(name:String):void {
            var par:Parallel = graphView.applyLayout(name);
            par.play();
        }
        
        public function mergeEdges(merge:Boolean):void {
            graphView.resetAllEdges();
            graphView.updateLabels(Groups.EDGES);
        }
        
        public function updateLabels():void {
            graphView.updateLabels();
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
                    graphView.resetAllEdges();
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
                graphView.resetAllEdges();
            } else {
                for each (var e:EdgeSprite in edges) graphView.deselectEdge(e);
            }
        }
        
        public function updateFilteredNodes():void {
            for each (var n:NodeSprite in graphProxy.graphData.nodes) {
                n.visible = Nodes.visible(n);
            }
            for each (var sg:SubGraphView in graphView.subGraphs) {
                sg.data.edges.setProperties(Edges.properties);
                updateLabels();
            }
        }
        
        public function updateFilteredEdges():void {
            for each (var sg:SubGraphView in graphView.subGraphs) {
                // Apply all properties again, because just setting visible is not enough,
                // since merged edges styles must be updated.
                sg.data.edges.setProperties(Edges.properties);
                sg.updateLabels(Groups.EDGES);
            }
        }

        public function resetDataSprite(ds:DataSprite):void {
            var sg:SubGraphView = graphView.getSubGraphOf(ds);
            if (sg != null) sg.resetDataSprite(ds);
        }
        
        public function zoomGraphTo(scale:Number):void {
            graphView.zoomTo(scale);
            if (graphProxy.rolledOverNode != null) {
                // If zooming while mouse still over a node (e.g. using the keyboard to zoom),
                // its label size may be wrong, so let's reset it:
                rescaleNodeLabel(graphProxy.rolledOverNode, true);
            }
        }
        
        public function zoomGraphToFit():void {
            graphView.zoomToFit();
            graphView.centerGraph();
            if (graphProxy.rolledOverNode != null) {
                // If zooming while mouse still over a node (e.g. using the keyboard to zoom),
                // its label size may be wrong, so let's reset it:
                rescaleNodeLabel(graphProxy.rolledOverNode, true);
            }
        }
        
        // ========[ PRIVATE METHODS ]==============================================================

        private function onRenderInitialize(evt:GraphViewEvent):void {
            graphView.addEventListener(GraphViewEvent.LAYOUT_INITIALIZE, onLayoutInitialize, false, 0, true);
            graphView.addEventListener(GraphViewEvent.RENDER_COMPLETE, onRenderComplete, false, 0, true);
        }

        private function onRenderComplete(evt:GraphViewEvent):void {
            addListeners();
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
            // TODO: should be handled by a command instead?
            if (extProxy.hasListener("layout")) {
                var body:Object = { functionName: ExternalFunctions.INVOKE_LISTENERS, 
                                    argument: { type: "layout", value: configProxy.currentLayout } };
                sendNotification(ApplicationFacade.CALL_EXTERNAL_INTERFACE, body);
            }
        }
        
        private function addListeners():void {
            for each (var sg:SubGraphView in graphView.subGraphs) {
                // First, add all the initial listeners to each NODE:
                // --------------------------------------------------
                for each (var n:NodeSprite in sg.data.nodes) {
                    n.addEventListener(MouseEvent.ROLL_OVER, onRollOverNode, false, 0, true);
                    n.doubleClickEnabled = true;
                    n.addEventListener(MouseEvent.DOUBLE_CLICK, onDoubleClickNode, false, 0, true);
					n.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDownNode, false, 0, true);
                }
                // Then, add listeners EDGES:
                // --------------------------------------------------
                for each (var e:EdgeSprite in sg.data.edges) {
                    e.addEventListener(MouseEvent.ROLL_OVER, onRollOverEdge, false, 0, true);
                    e.addEventListener(MouseEvent.ROLL_OUT, onRollOutEdge, false, 0, true);
                    e.doubleClickEnabled = true;
                    e.addEventListener(MouseEvent.DOUBLE_CLICK, onDoubleClickEdge, false, 0, true);
                    e.addEventListener(MouseEvent.CLICK, onClickEdge, false, 0, true);
                }
            }
            
            dragControl.attach(graphContainer);
            
            // Then add the CONTAINER listeners:
            // ---------------------------------
            // 1. KEY events:
            graphContainer.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown, false, 0, true);
            graphContainer.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp, false, 0, true);
            // 2. DRAG the whole graph:
            graphContainer.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDownContainer, false, 0, true);
            // 3. Click:
            graphContainer.addEventListener(MouseEvent.CLICK, onClickContainer, false, 0, true);
            // 4. 2-Click:
            graphContainer.addEventListener(MouseEvent.DOUBLE_CLICK, onDoubleClickContainer, false, 0, true);
            
            // Zooming is performed either by scrolling the mouse wheel or by 
            // clicking and dragging vertically while the control key is pressed.
            // NOTE: I don't want to use, because it interferes with other drag actions - e.g.
            //       dragging nodes and the SelectionControl.
            //new PanZoomControl().attach(graphView);
        }
        
        // CONTAINER listener functions:
        // -----------------------------------------------------------------------------------------
        private function onKeyDown(evt:KeyboardEvent):void { trace("* Key DOWN :: " + evt.keyCode);
            var dirty:Boolean = _isMouseOverContainer || _selecting || _draggingGraph;
            
            if (evt.keyCode === Keyboard.CONTROL) {
                _ctrlDown = true;
                if (dirty) updateCursor();
            } else if (evt.keyCode === Keyboard.SHIFT) {
                _shiftDown = true;
                if (!_ctrlDown && dirty)
                    updateCursor();
            }
        }
        
        private function onKeyUp(evt:KeyboardEvent):void { trace("* Key UP :: " + evt.keyCode);
            if (evt.keyCode === Keyboard.CONTROL) {
                _ctrlDown = false;
                if (_isMouseOverContainer) updateCursor();
            } else if (evt.keyCode === Keyboard.SHIFT) {
                _shiftDown = false;
                if (_isMouseOverContainer) updateCursor();
            }
        }

        private function onRollOverContainer(evt:MouseEvent):void { trace("<<<< Roll OVER [Container]");
            _isMouseOverContainer = true;
            // Workaround to avoid the system cursor to disappear when drag-selecting and the mouse
            // roll out the Flash player area and then over again.
            // That happens when the plus cursor is being displayed.
            updateCursor();
        }
        
        private function onRollOutContainer(evt:MouseEvent):void { trace(">>>> Roll OUT [Container]");
            _isMouseOverContainer = false;
            if (!_selecting && !_draggingNode && !_draggingGraph)
                sendNotification(ApplicationFacade.UPDATE_CURSOR);
        }
        
        private function onMouseDownContainer(evt:MouseEvent):void { trace("* Mouse DOWN [Container]");
            if (_ctrlDown && !_shiftDown) {
                // PANNING the whole graph...
                _draggingGraph = true
                updateCursor();

                selectionControl.detach();
                graphContainer.startDrag();
                graphContainer.addEventListener(MouseEvent.MOUSE_UP, onMouseUpToStopPanning, false, 0, true);
            } else {
                updateCursor();
            	// Add the SELECTION CONTROL again:
                selectionControl.detach();
                selectionControl.attach(graphContainer);
	
            	if (_shiftDown) {
            		// If SHIFT is pressed, add selected nodes to the selection group, thus
            		// ignoring the previously selected ones in order to avoid deselecting them
            		// "accidentally" when the selection rectangle encloses an already selected node:
            		selectionControl.filter = function(d:DisplayObject):Boolean {
            		    // TODO: filter edges OR nodes based on config param
            			return d is DataSprite && !DataSprite(d).props.$selected;
            		}
            	} else if (graphProxy.rolledOverEdge == null) {
            		// TODO: edges OR nodes based on config param
            		selectionControl.filter = DataSprite;
            		graphContainer.addEventListener(MouseEvent.MOUSE_UP, onMouseUpToDeselect, false, 0, true);
            	}

                graphContainer.addEventListener(MouseEvent.MOUSE_MOVE, onDragSelectionStart, false, 0, true);
            }
        }
        
        private function onMouseUpToDeselect(evt:MouseEvent):void { trace("* Mouse UP / Deselect all [Container]");
            evt.currentTarget.removeEventListener(evt.type, arguments.callee);
            graphContainer.removeEventListener(MouseEvent.MOUSE_MOVE, onDragSelectionStart);
            sendNotification(ApplicationFacade.DESELECT_ALL, Groups.NONE);
        }
        
        private function onMouseUpToStopPanning(evt:MouseEvent):void { trace("* Mouse UP / STOP PANNING [Container]");
            evt.currentTarget.removeEventListener(evt.type, arguments.callee);
            graphContainer.removeEventListener(MouseEvent.MOUSE_MOVE, onDragSelectionStart);
            graphContainer.stopDrag();
            _draggingGraph = false;
            if (_isMouseOverContainer) updateCursor();
            else sendNotification(ApplicationFacade.UPDATE_CURSOR);
        }
        
        private function onClickContainer(evt:MouseEvent):void { trace("* Click [Container]");
            sendNotification(ApplicationFacade.CLICK_EVENT);
        }
        
        private function onDoubleClickContainer(evt:MouseEvent):void { trace("* 2-CLICK [Container]");
            if (!_shiftDown && !_ctrlDown) sendNotification(ApplicationFacade.DOUBLE_CLICK_EVENT);
        }
        
        private function onDragSelectionStart(evt:MouseEvent):void { trace("* Drag Selection START [Container]");
            evt.currentTarget.removeEventListener(evt.type, arguments.callee);
            graphContainer.addEventListener(MouseEvent.MOUSE_UP, onDragSelectionEnd, false, 0, true);
            graphContainer.removeEventListener(MouseEvent.MOUSE_UP, onMouseUpToDeselect);

            // If SHIFT key is pressed, keep the previously selected elements.
            // Otherwise, deselect everything first:
            if (!_shiftDown) sendNotification(ApplicationFacade.DESELECT_ALL, Groups.NONE);
            _selecting = true;
        }
        
        private function onDragSelectionEnd(evt:MouseEvent):void { trace("* Drag Selection END [Container]");
            evt.currentTarget.removeEventListener(evt.type, arguments.callee);
            _selecting = false;
            if (_isMouseOverContainer) updateCursor();
            else sendNotification(ApplicationFacade.UPDATE_CURSOR);
        }
        
        // NODE listener functions:
        // -----------------------------------------------------------------------------------------
        private function onRollOverNode(evt:MouseEvent):void {
            if (_draggingNode || _draggingGraph || _selecting) return;

            var n:NodeSprite = evt.target as NodeSprite;
            sendNotification(ApplicationFacade.ROLLOVER_EVENT, n);
            n.addEventListener(MouseEvent.ROLL_OUT, onRollOutNode, false, 0, true);
            
            // When zoom < 100%, increase the label size to make it readable:
            if (_graphScale < 1) rescaleNodeLabel(n);
        }
        
        private function onRollOutNode(evt:MouseEvent):void {
            if (_draggingNode || _draggingGraph || _selecting) return;

            var n:NodeSprite = evt.target as NodeSprite;
            sendNotification(ApplicationFacade.ROLLOUT_EVENT, n);
            
            n.removeEventListener(MouseEvent.ROLL_OUT, onRollOutNode);
            evt.stopImmediatePropagation();

            rescaleNodeLabel(n, true);
        }
        
        private function onMouseDownNode(evt:MouseEvent):void { trace("** Mouse DOWN [node]");
            var n:NodeSprite = evt.target as NodeSprite;
            n.addEventListener(MouseEvent.MOUSE_UP, onMouseUpNode, false, 0, true);
            n.addEventListener(MouseEvent.CLICK, onClickNode, false, 0, true);
            // Remove the SELECTION CONTROL:
            selectionControl.detach();
            // To avoid clicking the container:
            graphContainer.removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDownContainer);

            var sg:SubGraphView = graphView.getSubGraphOf(n);
            if (sg != null) {   
                // Bring the subgraph and the node to front:
                graphView.bringNodeToFront(n);

                // Dragging a subgraph?
                if (_ctrlDown) {
                    GraphUtils.bringToFront(sg);
                    sg.startDrag();
                    sg.showDragRectangle();
                    _draggingGraph = true;
                    updateCursor();
                    evt.stopImmediatePropagation();
                }
            }
        }
        
        private function onMouseUpNode(evt:MouseEvent):void { trace("** Mouse UP [node]");
            evt.currentTarget.removeEventListener(evt.type, arguments.callee);
            var n:NodeSprite = evt.target as NodeSprite;
            
            if (_draggingGraph) {
                // We don't want a click action when user is not really clicking the node,
                // but just using it to drag the disconnected component.
                var sg:SubGraphView = graphView.getSubGraphOf(n);
                if (sg != null) {
                    sg.stopDrag();
                    sg.hideDragRectangle();
                }
                _draggingGraph = false;
                updateCursor();
            }
            
            // Return the MOUSE DOWN to the Container, so panning is possible again:
            graphContainer.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDownContainer, false, 0, true);
        }
        
        private function onClickNode(evt:MouseEvent):void { trace("** CLICK [node]");
            evt.currentTarget.removeEventListener(evt.type, arguments.callee);
            evt.stopImmediatePropagation();
            
            if (!_draggingGraph && !evt.ctrlKey) {
                var n:NodeSprite = evt.target as NodeSprite;
                sendNotification(ApplicationFacade.CLICK_EVENT, n);
    
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
            if (!_shiftDown && !_ctrlDown) {
                var n:NodeSprite = evt.target as NodeSprite;
                sendNotification(ApplicationFacade.DOUBLE_CLICK_EVENT, n);
            }
            evt.stopImmediatePropagation();
        }
        
        private function onDragNodeStart(evt:DragEvent):void { trace("== START Drag Node");
            _draggingNode = true;
            updateCursor();
            evt.node.removeEventListener(MouseEvent.CLICK, onClickNode);
        }
        
        private function onEndDragNode(evt:DragEvent):void { trace("== END Drag Node");
            _draggingNode = false;
            updateCursor();
        }
        
        private function onDragNode(evt:DragEvent):void {
            var curNode:NodeSprite = evt.node;
            
            if (curNode.props.$selected) {
	            // Drag the other selected nodes as well:
	            for each (var n:NodeSprite in graphProxy.selectedNodes) {
	            	if (n != curNode) {
		            	n.x += evt.amountX;
		            	n.y += evt.amountY;
		            }
	            }
            }
            // Necessary for Linux!
            // ###########################################################
            graphView.update();
            // ###########################################################
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
        }
        
        private function onRollOutEdge(evt:MouseEvent):void {
            evt.stopImmediatePropagation();
            var e:EdgeSprite = evt.target as EdgeSprite;
            sendNotification(ApplicationFacade.ROLLOUT_EVENT, e);
        }
        
        private function onClickEdge(evt:MouseEvent):void { trace("** Click [edge]");
            if (!_draggingGraph && !_ctrlDown) {
                var edge:EdgeSprite = evt.target as EdgeSprite;
                if (edge == null) return;
                
                sendNotification(ApplicationFacade.CLICK_EVENT, edge);
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
            graphContainer.removeEventListener(MouseEvent.MOUSE_MOVE, onDragSelectionStart);
            evt.stopImmediatePropagation();
        }
        
        private function onDoubleClickEdge(evt:MouseEvent):void { trace("** 2-CLICK [edge] : " + evt.target);
            if (!_shiftDown && !_ctrlDown) {
                var e:EdgeSprite = evt.target as EdgeSprite;
                sendNotification(ApplicationFacade.DOUBLE_CLICK_EVENT, e);
            }
            graphContainer.removeEventListener(MouseEvent.MOUSE_MOVE, onDragSelectionStart);
            evt.stopImmediatePropagation();
        }
        
        // OTHER functions:
        // -----------------------------------------------------------------------------------------
        
        private function rescaleNodeLabel(n:NodeSprite, reset:Boolean=false):void {
            if (n != null && configProxy.config.nodeLabelsVisible) {
                var label:TextSprite = n.props.label as TextSprite;
                if (label != null) {
                    var fsize:Number = configProxy.visualStyle.getValue(VisualProperties.NODE_LABEL_FONT_SIZE, n.data) as Number;
                    if (reset)
                        label.size = fsize;
                    else if (_graphScale < 1)
                        label.size = fsize / _graphScale;
                        
                    var sg:SubGraphView = graphView.getSubGraphOf(n);
                    sg.nodeLabeler.operate();
                }
            }
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
                _selectionControl.fillColor = style.getDefaultValue(VisualProperties.SELECTION_FILL_COLOR) as uint;
            if (style.hasVisualProperty(VisualProperties.SELECTION_FILL_ALPHA))
                _selectionControl.fillAlpha = style.getDefaultValue(VisualProperties.SELECTION_FILL_ALPHA) as Number;
            if (style.hasVisualProperty(VisualProperties.SELECTION_LINE_COLOR))
                _selectionControl.lineColor = style.getDefaultValue(VisualProperties.SELECTION_LINE_COLOR) as uint;
            if (style.hasVisualProperty(VisualProperties.SELECTION_LINE_ALPHA))
                _selectionControl.lineAlpha = style.getDefaultValue(VisualProperties.SELECTION_LINE_ALPHA) as Number;
            if (style.hasVisualProperty(VisualProperties.SELECTION_LINE_WIDTH))
                _selectionControl.lineWidth = style.getDefaultValue(VisualProperties.SELECTION_LINE_WIDTH) as Number;
        }
        
        private function updateCursor():void {
            sendNotification(ApplicationFacade.UPDATE_CURSOR, { selecting: _selecting,
                                                                draggingNode: _draggingNode,
                                                                draggingGraph: _draggingGraph,
                                                                shiftDown: _shiftDown,
                                                                ctrlDown: _ctrlDown });
        }
    }
}
