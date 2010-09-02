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
    import flash.events.Event;
    import flash.events.KeyboardEvent;
    import flash.events.MouseEvent;
    import flash.events.TimerEvent;
    import flash.ui.Keyboard;
    import flash.utils.Timer;
    
    import mx.controls.Button;
    import mx.controls.sliderClasses.Slider;
    import mx.events.SliderEvent;
    
    import org.cytoscapeweb.ApplicationFacade;
    import org.cytoscapeweb.view.components.PanZoomBox;
    import org.puremvc.as3.interfaces.INotification;
        
    /**
     * 
     */
    public class PanZoomMediator extends BaseMediator {

        // ========[ CONSTANTS ]====================================================================
        
        /** Cannonical name of the Mediator. */
        public static const NAME:String = "PanZoomMediator";
        
        // ========[ PRIVATE PROPERTIES ]===========================================================
        
        private var _panTimer:Timer = new Timer(16);
        private var _pressedPanButton:Button;
        private var _ignoreZoomChange:Boolean;
        
        private function get panZoomBox():PanZoomBox {
            return viewComponent as PanZoomBox;
        }
        
        private function get zoomSlider():Slider {
            return panZoomBox.zoomSlider;
        }
        
        // ========[ CONSTRUCTOR ]==================================================================
        
        public function PanZoomMediator(viewComponent:Object) {
            super(NAME, viewComponent, this);

            panZoomBox.addEventListener(Event.ADDED_TO_STAGE, onComplete, false, 0 , true);

            // Setup Zoom Slider:
            panZoomBox.setZoomRange(configProxy.minZoom, configProxy.maxZoom);

            // Panning events:
            panZoomBox.panButton.addEventListener(MouseEvent.CLICK, onPanToggleClick, false, 0, true);
            
            var panButtons:Array = [panZoomBox.panDownButton, panZoomBox.panLeftButton, 
                                    panZoomBox.panRightButton, panZoomBox.panUpButton];
            
            for each (var bt:Button in panButtons) {
            	bt.addEventListener(MouseEvent.MOUSE_DOWN, onPanMouseDown, false, 0, true);
            	bt.addEventListener(MouseEvent.MOUSE_UP, onPanMouseUp, false, 0, true);
            	bt.addEventListener(MouseEvent.ROLL_OUT, onPanMouseUp, false, 0, true);
            	// This click listener is only usefull for clicking the button through
            	// the keyboard (e.g. pressing "space" when focus is on a pan button):
            	bt.addEventListener(MouseEvent.CLICK, onPanClick, false, 0, true);
            }
            
            // Zoomming events:
            zoomSlider.addEventListener(SliderEvent.CHANGE, onZoomSliderChange);
            panZoomBox.zoomInButton.addEventListener(MouseEvent.CLICK, onZoomInClick, false, 0, true);
            panZoomBox.zoomOutButton.addEventListener(MouseEvent.CLICK, onZoomOutClick, false, 0, true);
            panZoomBox.zoomFitButton.addEventListener(MouseEvent.CLICK, onZoomFitClick, false, 0, true);
            panZoomBox.zoomInButton.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown, false, 0, true);
            panZoomBox.zoomOutButton.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown, false, 0, true);
            panZoomBox.zoomFitButton.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown, false, 0, true);
            
            // To avoid dragging the panZoomBox while pressing its buttons or the slider:
            zoomSlider.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown, false, 0, true);
        }

        // ========[ PUBLIC METHODS ]===============================================================
        
        override public function getMediatorName():String {
            return NAME;
        }
        
        override public function listNotificationInterests():Array {
            return [ApplicationFacade.ZOOM_CHANGED,
                    ApplicationFacade.ENABLE_GRAB_TO_PAN];
        }

        override public function handleNotification(note:INotification):void {
            switch (note.getName()) {
                case ApplicationFacade.ZOOM_CHANGED:
                    // Avoid infinit loops:
                    zoomSlider.removeEventListener(SliderEvent.CHANGE, onZoomSliderChange);
                    var scale:Number = note.getBody() as Number;
                    panZoomBox.scale = scale;
                    zoomSlider.addEventListener(SliderEvent.CHANGE, onZoomSliderChange);
                    graphProxy.zoom = scale;
                    break;
                case ApplicationFacade.ENABLE_GRAB_TO_PAN:
                    panZoomBox.panButton.selected = note.getBody();
                    configProxy.grabToPanEnabled = note.getBody();
                    break;
                default:
                    break;
            }
        }
        
        // ========[ PRIVATE METHODS ]==============================================================

        private function onComplete(evt:Event):void {
            // Initialization stuff here...
        }

	    private function onPanToggleClick(e:MouseEvent):void {
            e.stopImmediatePropagation();
            var bt:Button = e.target as Button;
            sendNotification(ApplicationFacade.ENABLE_GRAB_TO_PAN, bt.selected);
	    }
	    
	    private function onPanMouseDown(e:Event):void {
            e.stopImmediatePropagation();
	    	_pressedPanButton = e.target as Button;
	    	_panTimer.addEventListener(TimerEvent.TIMER, onPanTimerTick, false, 0, true);
	    	_panTimer.start();
	    }
	    
	    private function onPanMouseUp(e:Event):void {
	    	_panTimer.stop();
	    	_panTimer.removeEventListener(TimerEvent.TIMER, onPanTimerTick);
	    	e.stopImmediatePropagation();
	    }
	    
	    private function onPanClick(e:MouseEvent):void {
	    	doPanning(e.target as Button, 16);
	    }
	    
	    private function onPanTimerTick(e:TimerEvent):void {
            doPanning(_pressedPanButton, 8);
	    }
	    
	    private function doPanning(target:Button, amount:int = 8):void {
	    	var panX:Number = 0; var panY:Number = 0;
            
            if (target == panZoomBox.panUpButton) { panY = -amount; }
            else if (target == panZoomBox.panDownButton) { panY = amount; }
            else if (target == panZoomBox.panRightButton) { panX = amount; }
            else if (target == panZoomBox.panLeftButton) { panX = -amount; }
            
            sendNotification(ApplicationFacade.PAN_GRAPH, {panX: panX, panY: panY});
	    }
	    
	    private function onPanCenterClick(e:Event):void {
	        sendNotification(ApplicationFacade.CENTER_GRAPH);
	    }
	    
	    private function onZoomSliderChange(e:SliderEvent):void {
            sendNotification(ApplicationFacade.ZOOM_GRAPH, e.value/panZoomBox.ZOOM_FACTOR);
	    }
	    
	    private function onZoomInClick(e:Event):void {
	        var zoomValue:Number = Math.round(graphProxy.zoom*panZoomBox.ZOOM_FACTOR*10)/10;
	        
	        if (zoomValue < zoomSlider.maximum) {
                var tickValues:Array = zoomSlider.tickValues;
                for (var i:int = 0; i < tickValues.length - 1; i++) {trace(i+" : "+ zoomValue+" - "+tickValues[i]+" | "+tickValues[i+1]);
                	// Get the next larger tick value of the pre-defined range:
                	if (zoomValue >= tickValues[i] && zoomValue < tickValues[i+1]) {
                		zoomValue = tickValues[i+1];
                		break;
                	}
                }
                zoomSlider.dispatchEvent(new SliderEvent(SliderEvent.CHANGE, true, false, -1, zoomValue));
	        }
	    }
	    
	    private function onZoomOutClick(e:Event):void {
	        var zoomValue:Number = Math.round(graphProxy.zoom*panZoomBox.ZOOM_FACTOR*10)/10;
	        
	        if (zoomValue > zoomSlider.minimum) {
                var tickValues:Array = zoomSlider.tickValues;
                for (var i:int = tickValues.length-1; i >= 0; i--) {
                    // Get the next lower tick value of the pre-defined range:
                    if (zoomValue <= tickValues[i] && zoomValue > tickValues[i-1]) {
                        zoomValue = tickValues[i-1];
                        break;
                    }
                }
                zoomSlider.dispatchEvent(new SliderEvent(SliderEvent.CHANGE, true, false, -1, zoomValue));
	        }
	    }
	    
        private function onZoomFitClick(e:Event):void {
            sendNotification(ApplicationFacade.ZOOM_GRAPH_TO_FIT);
        }
        
        private function onMouseDown(e:Event):void {
        	e.stopImmediatePropagation();
        }
    }
}
