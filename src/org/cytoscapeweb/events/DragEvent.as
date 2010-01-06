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
package org.cytoscapeweb.events {
	
	import flare.vis.events.DataEvent;
	
	import flash.display.Sprite;
	
	/**
	 * Events fired by the EventDragControl on 
	 * - mouse down
	 * - dragging start 
	 * - dragging 
	 * - dragging stop
	 * - mouse up
	 * 
	 * @author Original version by <a href="http://goosebumps4all.net">martin dudek</a>.
	 *         Modified for Cytoscape Web to include the amount of movement. 
	 */
	public class DragEvent extends DataEvent {
		
	    /** An EventDragControl drag event. */
	    public static const DRAG:String  = "dragging";
	    /** An EventDragControl drag start event. */
	    public static const START:String = "dragging_start";
	    /** An EventDragControl drag stop event. */
	    public static const STOP:String  = "dragging_stop";
	    
	    /** An EventDragControl mouse down event. */
	    public static const MOUSEDOWN:String = "dragging_control_mouse_down";
	    /** An EventDragControl mouse up event. */
	    public static const MOUSEUP:String   = "dragging_control_mouse_up";
	    
	    public var amountX:Number;
	    public var amountY:Number;
	    
	     /**
	      * Creates a new DragEvent.
	      * @param type the event type (DRAG,START,STOP,MOUSEDOWN or MOUSEUP)
	      * @param item the datasprite on which the event occured
	      */
	    public function DragEvent(type:String, item:Sprite, amountX:Number=0, amountY:Number=0) {
	        super(type,item);
	        this.amountX = amountX;
	        this.amountY = amountY;
	    }
	} 
}