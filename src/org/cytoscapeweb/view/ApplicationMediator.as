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
    import flash.display.BitmapData;
    import flash.events.Event;
    import flash.events.KeyboardEvent;
    import flash.events.MouseEvent;
    import flash.geom.Matrix;
    import flash.geom.Rectangle;
    import flash.ui.Keyboard;
    import flash.ui.Mouse;
    
    import mx.controls.Alert;
    import mx.controls.Button;
    import mx.controls.Label;
    import mx.events.DragEvent;
    import mx.events.FlexEvent;
    import mx.events.ResizeEvent;
    import mx.graphics.codec.PNGEncoder;
    import mx.managers.CursorManager;
    import mx.managers.CursorManagerPriority;
    import mx.managers.PopUpManager;
    
    import org.cytoscapeweb.ApplicationFacade;
    import org.cytoscapeweb.model.converters.PDFExporter;
    import org.cytoscapeweb.model.converters.SVGExporter;
    import org.cytoscapeweb.model.data.VisualStyleVO;
    import org.cytoscapeweb.model.methods.$;
    import org.cytoscapeweb.util.BoxPositions;
    import org.cytoscapeweb.util.ExternalFunctions;
    import org.cytoscapeweb.util.Utils;
    import org.cytoscapeweb.util.VisualProperties;
    import org.cytoscapeweb.view.components.GraphView;
    import org.cytoscapeweb.view.components.PanZoomBox;
    import org.puremvc.as3.interfaces.INotification;
    
    
    public class ApplicationMediator extends BaseMediator {

        // ========[ CONSTANTS ]====================================================================

        /** Cannonical name of the Mediator. */
        public static const NAME:String = "ApplicationMediator";
        
        // ========[ PRIVATE PROPERTIES ]===========================================================
        
        [Embed(source="/assets/images/icons/opened_hand.png")]
        private var _openedHandCursor:Class;
        [Embed(source="/assets/images/icons/closed_hand.png")]
        private var _closedHandCursor:Class;
        
        private var _cursorIds:Object = { openedHand: -1, closedHand: -1 };
        private var _cursorOptions:Object;
        private var _customCursorsEnabled:Boolean = true;
        private var _isCustomCursor:Boolean = false;
        private var _overApp:Boolean = false;
        private var _overPanZoom:Boolean = false;
        
        private var _waitMsgLabel:Label;
        private var _executingTasks:uint = 0;
        
        /** Flag that indicates whether or not the PanZoomBox has been dragged. */
        private var _panZoomMoved:Boolean;
        private var _dragging:Boolean;
        
        // The new relation between the bounds of the panZoomBox and the canvas borders.
        // They will be usefull to determine the new position of the panZoomBox after resizing the canvas.
        private var _panZoomRightAnchor:Number;
        private var _panZoomLeftAnchor:Number;
        private var _panZoomTopAnchor:Number;
        private var _panZoomBottomAnchor:Number;
        
        private var _previousWidth:Number;
        private var _previousHeight:Number;
        
        private function get application():CytoscapeWeb {
            return viewComponent as CytoscapeWeb;
        }
        
        private function get graphView():GraphView {
            return application.graphView;
        }
        
        private function get panZoomBox():PanZoomBox {
            return application.panZoomBox;
        }
        
        private function get waitMsgLabel():Label {
            if (_waitMsgLabel == null) {
                _waitMsgLabel = new Label();
                _waitMsgLabel.text = $("global.wait");
                _waitMsgLabel.styleName = "infoLabel";
            }
            
            return _waitMsgLabel;
        }

        // ========[ CONSTRUCTOR ]==================================================================
   
        public function ApplicationMediator(viewComponent:Object) {
            super(NAME, viewComponent, this);
            
            _previousWidth = application.width;
            _previousHeight = application.height;
            resizeChildren();
            
            application.addEventListener(ResizeEvent.RESIZE, onAppResize, false, 0, true);
            application.addEventListener(FlexEvent.APPLICATION_COMPLETE, onApplicationComplete, false, 0, true);
            application.addEventListener(MouseEvent.ROLL_OVER, onRollOverApplication, false, 0, true);
            application.addEventListener(MouseEvent.ROLL_OUT, onRollOutApplication, false, 0, true);
            
            // Register the MOUSE_UP event on every button, just to dispatch to the graph canvas,
            // allowing a drag-selection or graph-panning to end:
            var panButtons:Array = [panZoomBox.panDownButton, panZoomBox.panLeftButton, 
                                    panZoomBox.panRightButton, panZoomBox.panUpButton];
            for each (var bt:Button in panButtons) {
                bt.addEventListener(MouseEvent.MOUSE_UP, onMouseUpPanZoom, false, 0, true);
            }
        }

        // ========[ PUBLIC METHODS ]===============================================================
    
        /** @inheritDoc */
        override public function getMediatorName():String {
            return NAME;
        }
        
        /** @inheritDoc */
        override public function listNotificationInterests():Array {
            return [ApplicationFacade.EXT_INTERFACE_NOT_AVAILABLE,
                    ApplicationFacade.INDETERMINATE_TASK_START,
                    ApplicationFacade.INDETERMINATE_TASK_COMPLETE,
                    ApplicationFacade.RESOURCE_BUNDLE_CHANGED,
                    ApplicationFacade.GRAPH_DRAWN,
                    ApplicationFacade.CONFIG_CHANGED,
                    ApplicationFacade.UPDATE_CURSOR,
                    ApplicationFacade.ENABLE_CUSTOM_CURSORS];
        }

        /** @inheritDoc */
        override public function handleNotification(n:INotification):void {
            switch (n.getName()) {
                case ApplicationFacade.INDETERMINATE_TASK_START:
                    showWaitMessage();
                    break;
                case ApplicationFacade.INDETERMINATE_TASK_COMPLETE:
                    hideWaitMessage();
                    break;
                case ApplicationFacade.RESOURCE_BUNDLE_CHANGED:
                    // Update labels, tooltips, etc:
                    panZoomBox.executeBindings(true);
                    break;
                case ApplicationFacade.GRAPH_DRAWN:
                    sendNotification(ApplicationFacade.CALL_EXTERNAL_INTERFACE, { functionName: ExternalFunctions.READY });
                case ApplicationFacade.CONFIG_CHANGED:
                    panZoomBox.visible = configProxy.panZoomControlVisible;
                    panZoomBox.x = calculatePanZoomBoxX();
                    panZoomBox.y = calculatePanZoomBoxY();
                    break;
                case ApplicationFacade.UPDATE_CURSOR:
                    _cursorOptions = n.getBody();
                    updateCursor(_cursorOptions);
                    break;
                case ApplicationFacade.ENABLE_CUSTOM_CURSORS:
                    _customCursorsEnabled = n.getBody();
                    configProxy.customCursorsEnabled = _customCursorsEnabled;
                    if (_customCursorsEnabled === true) updateCursor(_cursorOptions);
                    else hideAllCustomCursors();
                    break;
                default:
                    break;      
            }
        }
        
        public function applyVisualStyle(style:VisualStyleVO):void {
            var bgColor:uint = style.getValue(VisualProperties.BACKGROUND_COLOR) as uint;
            application.graphBox.setStyle("backgroundColor", bgColor);
        }
        
        public function getGraphImage(type:String="png", width:Number=0, height:Number=0):* {
            var image:*;
            var scale:Number = graphProxy.zoom;
            type = type != null ? type.toLowerCase() : "png";

            // Otherwise, it may draw the shapes incorrectly, or labels might have wrong alignment:
            if (scale !== 1) graphView.zoomTo(1);

            if (type === "png") {
                var bounds:Rectangle = graphView.vis.getRealBounds();
                
                // At least 1 pixel:
                var w:int = Math.max(bounds.width, 1);
                var h:int = Math.max(bounds.height, 1);
                
                // Maximum pixel count (http://kb2.adobe.com/cps/496/cpsid_49662.html)
                var pcount:int = w * h;
                const MAX_PCOUNT:Number = 0xFFFFFF;
                const MAX_PSIDE:Number = 8191;
                var f:Number = 1;
                
                if (pcount > MAX_PCOUNT)
                    f = f * MAX_PCOUNT/pcount;
                
                var maxSide:int = Math.max(w, h);
                
                if (maxSide > MAX_PSIDE)
                    f = f * MAX_PSIDE/maxSide;
                
                if (f < 1) {
                    w *= f;
                    h *= f;
                }
                
                // Draw the image:
                var color:uint = configProxy.config.visualStyle.getValue(VisualProperties.BACKGROUND_COLOR);
                var source:BitmapData = new BitmapData(w, h, false, color);
                var matrix:Matrix = new Matrix(1, 0, 0, 1, -bounds.x, -bounds.y);
                matrix.scale(f, f);
                source.draw(graphView.vis, matrix);

                var encoder:PNGEncoder = new PNGEncoder();
                image = encoder.encode(source);
            } else {
                var edges:Array = configProxy.edgesMerged ? graphProxy.mergedEdges 
                                                          : graphProxy.edges;
                if (type === "pdf") {
                    var pdfExp:PDFExporter = new PDFExporter(graphView);
                    image = pdfExp.export(graphProxy.nodes,
                                          edges,
                                          configProxy.visualStyle,
                                          configProxy.config,
                                          graphProxy.zoom,
                                          width,
                                          height);
                } else {
                    var svgConv:SVGExporter = new SVGExporter(graphView);
                    image = svgConv.export(graphProxy.nodes,
                                           edges,
                                           configProxy.visualStyle,
                                           configProxy.config,
                                           graphProxy.zoom,
                                           width,
                                           height);
                }
            }
            
            // Set previous scale:
            if (scale != graphProxy.zoom) graphView.zoomTo(scale);
            return image;
        }
        
        public function showPanZoomControl(visible:Boolean):void {
            panZoomBox.visible = visible;
        }
        
        public function showError(msg:String):void {
            Alert.show(msg, $("error.title"));
        }
        
        // ========[ PRIVATE METHODS ]==============================================================
        
        private function onApplicationComplete(evt:FlexEvent):void {
            // KEY BINDINGS:
            application.stage.addEventListener(Event.DEACTIVATE, onDeactivate);
            application.stage.addEventListener(Event.ACTIVATE, onActivate);
            application.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown, false, 0, true);
            
            // Listeners to drag the PAN ZOOM control:
            panZoomBox.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDownPanZoom, false, 0, true);
            panZoomBox.addEventListener(MouseEvent.MOUSE_UP, onMouseUpPanZoom, false, 0, true);
            panZoomBox.addEventListener(MouseEvent.ROLL_OVER, onRollOverPanZoom, false, 0, true);
            panZoomBox.addEventListener(MouseEvent.ROLL_OUT, onRollOutPanZoom, false, 0, true);
            panZoomBox.addEventListener(DragEvent.DRAG_COMPLETE, onDragCompletePanZoom, false, 0, true);

            application.stage.focus = graphView;
            
            // Tell the client application that Cytoscape Web is ready:
            sendNotification(ApplicationFacade.CALL_EXTERNAL_INTERFACE, { functionName: ExternalFunctions.COMPLETE });
        }
          
        private function showWaitMessage():void {
            if (_executingTasks++ === 0) {
                graphView.visible = false;
                PopUpManager.addPopUp(waitMsgLabel, application, true);
                PopUpManager.centerPopUp(waitMsgLabel);
            }
        }
          
        private function hideWaitMessage():void {
            if (--_executingTasks === 0) {
                PopUpManager.removePopUp(waitMsgLabel);
                graphView.visible = true;
            }
        }
        
        private function onActivate(evt:Event):void {
            sendNotification(ApplicationFacade.ACTIVATE_EVENT);
        }
        
        private function onDeactivate(evt:Event):void {
            sendNotification(ApplicationFacade.DEACTIVATE_EVENT);
        }
        
        private function onKeyDown(evt:KeyboardEvent):void {
            var panX:Number = 0; var panY:Number = 0;
            var amount:Number = 16;

            if (evt.keyCode == Keyboard.UP)
                panY = -amount;
            else if (evt.keyCode == Keyboard.DOWN)
                panY = amount;
            else if (evt.keyCode == Keyboard.LEFT)
                panX = -amount;
            else if (evt.keyCode == Keyboard.RIGHT)
                panX = amount;
            else if (evt.charCode == 43) // '+'
                panZoomBox.zoomInButton.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
            else if (evt.charCode == 45) // '-'
                panZoomBox.zoomOutButton.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
            else if (evt.charCode == 42) // '*'
                panZoomBox.zoomFitButton.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
                
            if (panX != 0 || panY != 0)
                sendNotification(ApplicationFacade.PAN_GRAPH, {panX: panX, panY: panY});
        }
        
        private function onMouseDownPanZoom(evt:MouseEvent):void {
            evt.stopImmediatePropagation();
            _dragging = true;
            panZoomBox.startDrag(false, new Rectangle(0, 0, application.width - panZoomBox.width, application.height - panZoomBox.height));
        }
        
        private function onMouseUpPanZoom(evt:MouseEvent):void {
            if (_dragging) {
                panZoomBox.stopDrag();
                _dragging = false;
                panZoomBox.dispatchEvent(new DragEvent(DragEvent.DRAG_COMPLETE));
            } else {
                if (graphProxy.rolledOverNode != null) {
                    // Workaround to force a ROLL OUT event on a rolled over node, because when a node is
                    // behind the pan-zoom control, the node's roll out event won't buble up:
                    graphProxy.rolledOverNode.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_UP));
                    graphProxy.rolledOverNode.dispatchEvent(new MouseEvent(MouseEvent.ROLL_OUT));
                }
                if (graphProxy.rolledOverEdge != null) {
                    // Same thing...
                    graphProxy.rolledOverEdge.dispatchEvent(new MouseEvent(MouseEvent.ROLL_OUT));
                }
                // To force the end of a drag-selection or graph panning:
                if (graphView != null && graphView.vis != null)
                    graphView.vis.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_UP));
                
                // Another workaround: it seems that forcing roll-over node/edge can bubble it up
                // to the application, causing a roll-over app. as well,
                // which can prevent the correct cursor icon to be displayed.
                if (!_overApp)
                    application.dispatchEvent(new MouseEvent(MouseEvent.ROLL_OVER));
            }
        }
        
        private function onRollOverPanZoom(evt:MouseEvent):void {
            _overPanZoom = true;
            updateCursor();
        }
        
        private function onRollOutPanZoom(evt:MouseEvent):void {
            _overPanZoom = false;
            updateCursor();
        }
        
        private function onDragCompletePanZoom(evt:DragEvent):void {
            _panZoomMoved = true;
            cachePanZoomAnchors();
        }
        
        private function onAppResize(evt:ResizeEvent):void {
            resizeChildren();
        }
        
        private function onRollOverApplication(evt:MouseEvent):void { trace("<<== ROLL OVER [APP]");
            _overApp = true;
            // Workaround to avoid the system cursor to disappear when drag-selecting and the mouse
            // roll out the Flash player area and then over again.
            // That happens when the plus cursor is being displayed.
            if (!_isCustomCursor) Mouse.show();
            // The user might have pressed or released the SHIFT key while the mouse
            // was out of the application area:
            updateCursor(_cursorOptions);
            sendNotification(ApplicationFacade.ROLLOVER_EVENT);
        }
        
        private function onRollOutApplication(evt:MouseEvent):void { trace("==>> ROLL OUT [APP]");
            _overApp = false;
            hideAllCustomCursors();
            sendNotification(ApplicationFacade.ROLLOUT_EVENT);
        }
            
        private function resizeChildren():void {
            // Resize them:
            application.graphBox.width = application.width;
            application.graphBox.height = application.height;
            
            // Keep the panZoomBox in a good position:
            panZoomBox.x = calculatePanZoomBoxX();
            panZoomBox.y = calculatePanZoomBoxY();
            cachePanZoomAnchors();
            
            _previousWidth = application.width;
            _previousHeight = application.height;
        }
        
        private function calculatePanZoomBoxX():Number {
            // Initially anchored on one edge of the canvas:
            var x:Number;
            const HPAD:int = 6;
            var position:String = configProxy.panZoomControlPosition;
            
            switch (position) {
                case BoxPositions.TOP_LEFT:
                case BoxPositions.MIDDLE_LEFT:
                case BoxPositions.BOTTOM_LEFT:
                    x = HPAD;
                    break;
                case BoxPositions.TOP_CENTER:
                case BoxPositions.MIDDLE_CENTER:
                case BoxPositions.BOTTOM_CENTER:
                    x = application.width/2 - panZoomBox.width/2;
                    break;
                case BoxPositions.TOP_RIGHT:
                case BoxPositions.MIDDLE_RIGHT:
                case BoxPositions.BOTTOM_RIGHT:
                default:
                    x = application.width - panZoomBox.width - HPAD;
            }
            
            if (_panZoomMoved) {
                const MIN_DIST_TO_ANCHOR:Number = Math.min(20, application.width/10);
                
                if (_panZoomLeftAnchor > MIN_DIST_TO_ANCHOR  && _panZoomRightAnchor > MIN_DIST_TO_ANCHOR) {
                    // Just keep the the right and left paddings with the same proportion:
                    x = _panZoomLeftAnchor * application.width / _previousWidth;
                } else {
                    // If the user previously dragged the panzoom box to really close to the
                    // left or right canvas' border, he probaly wants it to be anchored there:
                    if (_panZoomLeftAnchor < _panZoomRightAnchor) {
                        // Anchor at LEFT:
                        x = _panZoomLeftAnchor;
                    } else {
                        // Anchor at RIGHT:
                        x = application.width - panZoomBox.width - _panZoomRightAnchor;
                    }
                }
            }
            
            // Don't let the panZoom get out of the canvas!!!
            if (x > application.width) x = application.width - panZoomBox.width;
            if (x < 0) x = 0;
            
            return x;
        }
        
        private function calculatePanZoomBoxY():Number {
            // Initially anchored on one edge of the canvas:
            var y:Number;
            const VPAD:int = 6;
            var position:String = configProxy.panZoomControlPosition;
            
            switch (position) {
                case BoxPositions.TOP_LEFT:
                case BoxPositions.TOP_CENTER:
                case BoxPositions.TOP_RIGHT:
                    y = VPAD;
                    break;
                case BoxPositions.MIDDLE_LEFT:
                case BoxPositions.MIDDLE_CENTER:
                case BoxPositions.MIDDLE_RIGHT:
                    y = application.height/2 - panZoomBox.height/2;
                    break;
                case BoxPositions.BOTTOM_LEFT:
                case BoxPositions.BOTTOM_CENTER:
                case BoxPositions.BOTTOM_RIGHT:
                default:
                    y = application.height - panZoomBox.height - VPAD;
            }
            
            if (_panZoomMoved) {
                const MIN_DIST_TO_ANCHOR:Number = Math.min(20, application.height/10);
                
                if (_panZoomTopAnchor > MIN_DIST_TO_ANCHOR  && _panZoomBottomAnchor > MIN_DIST_TO_ANCHOR) {
                    // Just keep the the top and bottom paddings with the same proportion:
                    y = _panZoomTopAnchor * application.height / _previousHeight;
                } else {
                    // If the user previously dragged the panzoom box to really close to the
                    // top or bottom border, he probaly wants it to be anchored there:
                    if (_panZoomTopAnchor < _panZoomBottomAnchor)
                        y = _panZoomTopAnchor;
                    else
                        y = application.height - panZoomBox.height - _panZoomBottomAnchor;
                }
            }
            
            // Don't let the panZoom get out of the canvas!!!
            if (y > application.height) y = application.height - panZoomBox.height;
            if (y < 0) y = 0;
            
            return y;
        }
        
        private function cachePanZoomAnchors():void {
            _panZoomTopAnchor = panZoomBox.y;
            _panZoomLeftAnchor = panZoomBox.x;
            _panZoomBottomAnchor = application.height - panZoomBox.y - panZoomBox.height;
            _panZoomRightAnchor = application.width - panZoomBox.x - panZoomBox.width;
            
            if (_panZoomRightAnchor < 0) _panZoomRightAnchor = 0;
            if (_panZoomBottomAnchor < 0) _panZoomBottomAnchor = 0;
        }
        
        private function updateCursor(options:Object=null):void {
            if (options == null) options = {};
            if (!_overApp || options.selecting) return;
            
            if (options.draggingGraph || options.draggingComponent) {
                showClosedHandCursor();
                _isCustomCursor = true;
            } else {
                hideClosedHandCursor();

                if ( !_overPanZoom &&
                     configProxy.grabToPanEnabled && 
                     graphProxy.rolledOverNode == null && graphProxy.rolledOverEdge == null ) {
                    showOpenedHandCursor();
                    _isCustomCursor = true;
                } else {
                    hideOpenedHandCursor();
                    _isCustomCursor = false;
                }
            }
        }
        
        private function showOpenedHandCursor():void {
            // On most of the major Linux distributions the system cursor cannot be hidden!
            if (_overApp && _customCursorsEnabled && !Utils.isLinux()) {
                if (_cursorIds.openedHand === -1)
                    _cursorIds.openedHand = CursorManager.setCursor(_openedHandCursor, CursorManagerPriority.MEDIUM, -5);
                CursorManager.showCursor();
            }
        }
        
        private function showClosedHandCursor():void {
            if (_overApp && _customCursorsEnabled && !Utils.isLinux()) {
                if (_cursorIds.closedHand === -1)
                    _cursorIds.closedHand = CursorManager.setCursor(_closedHandCursor, CursorManagerPriority.HIGH, -5);
                CursorManager.showCursor();
            }
        }
        
        private function hideOpenedHandCursor():void {
            if (_cursorIds.openedHand !== -1) {
                CursorManager.removeCursor(_cursorIds.openedHand);
                _cursorIds.openedHand = -1;
            }
        }
        
        private function hideClosedHandCursor():void {
            if (_cursorIds.closedHand !== -1) {
                CursorManager.removeCursor(_cursorIds.closedHand);
                _cursorIds.closedHand = -1;
            }
        }
        
        private function hideAllCustomCursors():void {
            hideClosedHandCursor();
            hideOpenedHandCursor();
            Mouse.show();
        }
    }
}
