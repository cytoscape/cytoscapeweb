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
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	import flash.ui.Keyboard;
	import flash.ui.Mouse;
	import flash.utils.ByteArray;
	
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
	import org.cytoscapeweb.model.converters.PDFConverter;
	import org.cytoscapeweb.model.data.VisualStyleVO;
	import org.cytoscapeweb.model.methods.$;
	import org.cytoscapeweb.util.ExternalFunctions;
	import org.cytoscapeweb.util.Utils;
	import org.cytoscapeweb.util.VisualProperties;
	import org.cytoscapeweb.view.components.GraphView;
	import org.cytoscapeweb.view.components.NetworkVisBox;
	import org.cytoscapeweb.view.components.PanZoomBox;
	import org.puremvc.as3.interfaces.INotification;
	    
    /**
     * Top level mediator for the application.
     */
    public class ApplicationMediator extends BaseAppMediator {

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
        private var _isCustomCursor:Boolean = false;
        private var _isMouseOverApp:Boolean = false;
        
        private var _waitMsgLabel:Label;
        
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
        
        private function get networkVisBox():NetworkVisBox {
            return application.networkVisBox;
        }
        
        private function get panZoomBox():PanZoomBox {
            return application.networkVisBox.panZoomBox;
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
            
            _previousWidth = networkVisBox.width;
            _previousHeight = networkVisBox.height;
            resizeChildren();
            
            networkVisBox.addEventListener(ResizeEvent.RESIZE, onNetworkVisBoxResize, false, 0, true);
            application.addEventListener(FlexEvent.APPLICATION_COMPLETE, onCreationComplete, false, 0, true);
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
    
        /**
         * Get the Mediator name.
         * <P>
         * Called by the framework to get the name of this
         * mediator. If there is only one instance, we may
         * define it in a constant and return it here. If
         * there are multiple instances, this method must
         * return the unique name of this instance.</P>
         * 
         * @return String the Mediator name
         */
        override public function getMediatorName():String {
            return NAME;
        }
        
        /**
         * List all notifications this Mediator is interested in.
         * <P>
         * Automatically called by the framework when the mediator
         * is registered with the view.</P>
         * 
         * @return Array the list of Nofitication names
         */
        override public function listNotificationInterests():Array {
            return [ApplicationFacade.EXT_INTERFACE_NOT_AVAILABLE,
                    ApplicationFacade.INDETERMINATE_TASK_START,
                    ApplicationFacade.INDETERMINATE_TASK_COMPLETE,
                    ApplicationFacade.RESOURCE_BUNDLE_CHANGED,
                    ApplicationFacade.GRAPH_DRAWN,
                    ApplicationFacade.CONFIG_CHANGED,
                    ApplicationFacade.UPDATE_CURSOR];
        }

        /**
         * Handle all notifications this Mediator is interested in.
         * <P>
         * Called by the framework when a notification is sent that
         * this mediator expressed an interest in when registered
         * (see <code>listNotificationInterests</code>.</P>
         * 
         * @param INotification a notification 
         */
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
                    break;
                case ApplicationFacade.UPDATE_CURSOR:
                    _cursorOptions = n.getBody();
                    updateCursor(_cursorOptions);
                    break;
                default:
                    break;      
            }
        }
        
        public function applyVisualStyle(style:VisualStyleVO):void {
            var bgColor:uint = style.getValue(VisualProperties.BACKGROUND_COLOR) as uint;
            networkVisBox.graphBox.setStyle("backgroundColor", bgColor);
        }
        
        public function getGraphImage(type:String="png", width:*=null, height:*=null):ByteArray {
            var bytes:ByteArray;

            if (type === "png") {
                var color:uint = configProxy.config.visualStyle.getValue(VisualProperties.BACKGROUND_COLOR);
                var source:BitmapData = new BitmapData(networkVisBox.width, networkVisBox.height, false, color);
                
                // Do not draw the pan-zoom copntrol:
                if (panZoomBox.visible) panZoomBox.visible = false;

                source.draw(networkVisBox);
                
                if (configProxy.panZoomControlVisible) panZoomBox.visible = true;

                var encoder:PNGEncoder = new PNGEncoder();
                bytes = encoder.encode(source);
            } else {
                // PDF:
                var pdfConv:PDFConverter = new PDFConverter(networkVisBox.graphView);
                bytes = pdfConv.convertToPDF(graphProxy.graphData,
                                             configProxy.visualStyle,
                                             configProxy.config,
                                             graphProxy.zoom,
                                             width,
                                             height);
            }
            
            return bytes;
        }
        
        public function showPanZoomControl(visible:Boolean):void {
            panZoomBox.visible = visible;
        }
        
        public function showError(msg:String):void {
            Alert.show(msg, $("error.title"));
        }
        
        // ========[ PRIVATE METHODS ]==============================================================
		
		private function onCreationComplete(evt:FlexEvent):void {
		    // KEY BINDINGS:
            application.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPressed, false, 0, true);
		    
            // Listeners to drag the PAN ZOOM control:
            panZoomBox.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDownPanZoom, false, 0, true);
            panZoomBox.addEventListener(MouseEvent.MOUSE_UP, onMouseUpPanZoom, false, 0, true);
            panZoomBox.addEventListener(DragEvent.DRAG_COMPLETE, onDragCompletePanZoom, false, 0, true);

            application.stage.focus = panZoomBox;
		}
		  
		private function showWaitMessage():void {
			networkVisBox.graphView.visible = false;
		    PopUpManager.addPopUp(waitMsgLabel, application, true);
		    PopUpManager.centerPopUp(waitMsgLabel);
		}
		  
		private function hideWaitMessage():void {
		    PopUpManager.removePopUp(waitMsgLabel);
		    networkVisBox.graphView.visible = true;
		}
		
        public function onKeyPressed(e:KeyboardEvent):void {
            var panX:Number = 0; var panY:Number = 0;
            var amount:Number = 16;

            if (e.keyCode == Keyboard.UP)
                panY = amount;
            else if (e.keyCode == Keyboard.DOWN)
                panY = -amount;
            else if (e.keyCode == Keyboard.LEFT)
                panX = amount;
            else if (e.keyCode == Keyboard.RIGHT)
                panX = -amount;
            else if (e.charCode == 43) // '+'
                panZoomBox.zoomInButton.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
            else if (e.charCode == 45) // '-'
                panZoomBox.zoomOutButton.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
            else if (e.charCode == 42) // '*'
                panZoomBox.zoomFitButton.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
            else if (e.ctrlKey || e.shiftKey)
                updateCursor();
                
            if (panX != 0 || panY != 0)
                sendNotification(ApplicationFacade.PAN_GRAPH, {panX: panX, panY: panY});
        }
        
	    private function onMouseDownPanZoom(evt:MouseEvent):void {
	        evt.stopImmediatePropagation();
	        _dragging = true;
	        panZoomBox.startDrag(false, new Rectangle(0, 0, networkVisBox.width - panZoomBox.width, networkVisBox.height - panZoomBox.height));
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
                if (networkVisBox.graphView != null && networkVisBox.graphView.graphContainer != null)
                    networkVisBox.graphView.graphContainer.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_UP));
                
                // Another workaround: it seems that forcing roll-over node/edge can bubble it up
                // to the application, causing a roll-over app. as well,
                // which can prevent the correct cursor icon to be displayed.
                if (!_isMouseOverApp)
                    application.dispatchEvent(new MouseEvent(MouseEvent.ROLL_OVER));
            }
	    }
	    
	    private function onDragCompletePanZoom(evt:DragEvent):void {
	        _panZoomMoved = true;
	        cachePanZoomAnchors();
	    }
	    
	    private function onNetworkVisBoxResize(evt:ResizeEvent):void {
	        resizeChildren();
	    }
        
        private function onRollOverApplication(evt:MouseEvent):void { trace("<<== ROLL OVER [APP]");
            _isMouseOverApp = true;
            // Workaround to avoid the system cursor to disappear when drag-selecting and the mouse
            // roll out the Flash player area and then over again.
            // That happens when the plus cursor is being displayed.
            if (!_isCustomCursor) Mouse.show();
            // The user might have pressed or released a SHIFT or CTRL key while the mouse
            // was out of the application area:
            updateCursor(_cursorOptions);
            sendNotification(ApplicationFacade.ROLLOVER_EVENT);
        }
        
        private function onRollOutApplication(evt:MouseEvent):void { trace("==>> ROLL OUT [APP]");
            _isMouseOverApp = false;
            hideAllCustomCursors();
            sendNotification(ApplicationFacade.ROLLOUT_EVENT);
        }
	        
	    private function resizeChildren():void {
	        // Resize them:
            networkVisBox.graphBox.width = networkVisBox.width;
            networkVisBox.graphBox.height = networkVisBox.height;
	        
	        // Keep the panZoomBox in a good position:
	        panZoomBox.x = calculatePanZoomBoxX();
	        panZoomBox.y = calculatePanZoomBoxY();
	        cachePanZoomAnchors();
	        
	        _previousWidth = networkVisBox.width;
	        _previousHeight = networkVisBox.height;
	    }
	    
	    private function calculatePanZoomBoxX():Number {
	        // Initially anchored on the right side of the canvas:
	        var x:Number = networkVisBox.width - panZoomBox.width - 6;
	        
	        if (_panZoomMoved) {
	            const MIN_DIST_TO_ANCHOR:Number = Math.min(20, networkVisBox.width/10);
	            
	            if (_panZoomLeftAnchor > MIN_DIST_TO_ANCHOR  && _panZoomRightAnchor > MIN_DIST_TO_ANCHOR) {
	                // Just keep the the right and left paddings with the same proportion:
	                x = _panZoomLeftAnchor * networkVisBox.width / _previousWidth;
	            } else {
	                // If the user previously dragged the panzoom box to really close to the
	                // left or right canvas' border, he probaly wants it to be anchored there:
	                if (_panZoomLeftAnchor < _panZoomRightAnchor) {
	                    // Anchor at LEFT:
	                    x = _panZoomLeftAnchor;
	                } else {
	                    // Anchor at RIGHT:
	                    x = networkVisBox.width - panZoomBox.width - _panZoomRightAnchor;
	                }
	            }
	        }
	        
	        // Don't let the panZoom get out of the canvas!!!
	        if (x > networkVisBox.width) x = networkVisBox.width - panZoomBox.width;
	        if (x < 0) x = 0;
	        
	        return x;
	    }
	    
	    private function calculatePanZoomBoxY():Number {
	        // Initially anchored on the bottom side of the canvas:
	        var y:Number = networkVisBox.height - panZoomBox.height - 6;
	        
	        if (_panZoomMoved) {
	            const MIN_DIST_TO_ANCHOR:Number = Math.min(20, networkVisBox.height/10);
	            
	            if (_panZoomTopAnchor > MIN_DIST_TO_ANCHOR  && _panZoomBottomAnchor > MIN_DIST_TO_ANCHOR) {
	                // Just keep the the top and bottom paddings with the same proportion:
	                y = _panZoomTopAnchor * networkVisBox.height / _previousHeight;
	            } else {
	                // If the user previously dragged the panzoom box to really close to the
	                // top or bottom border, he probaly wants it to be anchored there:
	                if (_panZoomTopAnchor < _panZoomBottomAnchor)
	                    y = _panZoomTopAnchor;
	                else
	                    y = networkVisBox.height - panZoomBox.height - _panZoomBottomAnchor;
	            }
	        }
	        
	        // Don't let the panZoom get out of the canvas!!!
	        if (y > networkVisBox.height) y = networkVisBox.height - panZoomBox.height;
	        if (y < 0) y = 0;
	        
	        return y;
	    }
	    
	    private function cachePanZoomAnchors():void {
	        _panZoomTopAnchor = panZoomBox.y;
	        _panZoomLeftAnchor = panZoomBox.x;
	        _panZoomBottomAnchor = networkVisBox.height - panZoomBox.y - panZoomBox.height;
	        _panZoomRightAnchor = networkVisBox.width - panZoomBox.x - panZoomBox.width;
	        
	        if (_panZoomRightAnchor < 0) _panZoomRightAnchor = 0;
	        if (_panZoomBottomAnchor < 0) _panZoomBottomAnchor = 0;
	    }
	    
        private function updateCursor(options:Object=null):void {
            if (options == null) options = {};
            if (!_isMouseOverApp || options.selecting) return;
            
            if (options.draggingGraph) {
                showClosedHandCursor();
                _isCustomCursor = true;
            } else {
                hideClosedHandCursor();

                if (options.ctrlDown && !options.shiftDown) {
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
            if (_isMouseOverApp && !Utils.isLinux()) {
                if (_cursorIds.openedHand === -1)
                    _cursorIds.openedHand = CursorManager.setCursor(_openedHandCursor, CursorManagerPriority.MEDIUM, -5);
                CursorManager.showCursor();
            }
        }
        
        private function showClosedHandCursor():void {
            if (_isMouseOverApp && !Utils.isLinux()) {
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
