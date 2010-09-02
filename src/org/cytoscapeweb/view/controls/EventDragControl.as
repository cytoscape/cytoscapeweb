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
package org.cytoscapeweb.view.controls {

	import flare.vis.controls.Control;
	import flare.vis.data.DataSprite;
	
	import flash.display.InteractiveObject;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	import org.cytoscapeweb.events.DragEvent;
	
	[Event(name="drag", type="DragEvent")]
	[Event(name="start", type="DragEvent")]
	[Event(name="stop", type="DragEvent")]
	[Event(name="mousedown", type="DragEvent")]
	[Event(name="mouseup", type="DragEvent")]
	
	/**
	 * Interactive control for dragging items. A DragControl will enable
	 * dragging of all Sprites in a container object by clicking and dragging
	 * them.
	 * 
	 * In addition, this "extension" of the original DragControl from the flare toolkit 
	 * dispatches the following events occuring during the cycle of dragging one item:
	 * - mouse down     (DragEvent.MOUSEDOWN)
	 * - dragging start (DragEvent.START) 
	 * - dragging       (DragEvent.DRAG)
	 * - dragging stop  (DragEvent.STOP)
	 * - mouse up       (DragEvent.MOUSEUP)
	 * 
	 * @author Original version by <a href="http://goosebumps4all.net">martin dudek</a>.
	 *         Modified for CytoscapeWeb in order to allow dragging multiple nodes.
	 */
	 public class EventDragControl extends Control
	 {
	    private var dragging:Boolean; //flag indicating if the startdrag event has already been dispatched
	    
	    private var _cur:Sprite;
	    
	    private var _mx:Number, _my:Number;
	    
	    /** Indicates if drag should be followed at frame rate only.
	     *  If false, drag events can be processed faster than the frame
	     *  rate, however, this may pre-empt other processing. */
	    public var trackAtFrameRate:Boolean = false;
	    
	    /** The active item currently being dragged. */
	    public function get activeItem():Sprite { return _cur; }
	    
	    /**
	     * Creates a new DragControl.
	     * @param filter a Boolean-valued filter function determining which
	     *  items should be draggable.
	     */     
	    public function EventDragControl(filter:*=null) {
	        this.filter = filter;
	    }
	    
	    /** @inheritDoc */
	    public override function attach(obj:InteractiveObject):void
	    {
	        super.attach(obj);
	        obj.addEventListener(MouseEvent.MOUSE_DOWN, _onMouseDown);
	    }
	    
	    /** @inheritDoc */
	    public override function detach() : InteractiveObject
	    {
	        if (_object != null) {
	            _object.removeEventListener(MouseEvent.MOUSE_DOWN, _onMouseDown);
	        }
	        return super.detach();
	    }
	    
	    private function _onMouseDown(event:MouseEvent) : void {
	        var s:Sprite = event.target as Sprite;
	        if (s==null) return; // exit if not a sprite
	        
	        if (_filter==null || _filter(s)) {
	            _cur = s;
	            _mx = _object.mouseX;
	            _my = _object.mouseY;
	            if (_cur is DataSprite) (_cur as DataSprite).fix();
	
	            _cur.stage.addEventListener(MouseEvent.MOUSE_MOVE, _onDrag);
	            _cur.stage.addEventListener(MouseEvent.MOUSE_UP, _onMouseUp);
	            
	            if (hasEventListener(DragEvent.MOUSEDOWN)) {
	                dispatchEvent(new DragEvent(DragEvent.MOUSEDOWN,_cur));
	            };
	            
	            event.stopPropagation();
	            
	        }
	    }
	    
	    private function _onDrag(event:Event) : void {
	        var x:Number = _object.mouseX;
	        var amountX:Number = 0; 
	        
	        if (x != _mx) {
	        	amountX = x - _mx;
	            _cur.x += amountX;
	            _mx = x;
	        }
	        
	        var y:Number = _object.mouseY;
	        var amountY:Number = 0; 
	        
	        if (y != _my) {
	        	amountY = y - _my;
	            _cur.y += amountY;
	            _my = y;
	        }
	        
	        if (dragging == false) {
	            if (hasEventListener(DragEvent.START)) {
	                dispatchEvent(new DragEvent(DragEvent.START, _cur, amountX, amountY));
	            }
	            dragging = true;
	        }
	        if (hasEventListener(DragEvent.DRAG)) {
	            dispatchEvent(new DragEvent(DragEvent.DRAG, _cur, amountX, amountY));
	        } 
	        
	    }
	    
	    private function _onMouseUp(event:MouseEvent) : void {
	        if (_cur != null) {
	            _cur.stage.removeEventListener(MouseEvent.MOUSE_UP, _onMouseUp);
	            _cur.stage.removeEventListener(MouseEvent.MOUSE_MOVE, _onDrag);
	            
	            dragging = false;
	            
	            if (hasEventListener(DragEvent.STOP)) {
	                dispatchEvent(new DragEvent(DragEvent.STOP,_cur));
	            }
	            
	            if (hasEventListener(DragEvent.MOUSEUP)) {
	                dispatchEvent(new DragEvent(DragEvent.MOUSEUP,_cur));
	            };
	                    
	            if (_cur is DataSprite) (_cur as DataSprite).unfix();
	            
	            event.stopPropagation();
	            
	            
	        }
	        _cur = null;
	    }
	}
}