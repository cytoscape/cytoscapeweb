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
	import flash.events.Event;
	    
    /**
    * Events passed between the Graph View component and its mediator.
    */
    public class GraphViewEvent extends ApplicationEvent {
        
        public static const RENDER_INITIALIZE:String = "graph_render_initialize";
        public static const RENDER_COMPLETE:String = "graph_render_complete";
        public static const LAYOUT_INITIALIZE:String = "graph_layout_initialize";
        public static const LAYOUT_COMPLETE:String = "graph_layout_complete";
        public static const SCALE_CHANGE:String = "graph_scale_change";
        public static const RENDER_PROGRESS_UPDATE:String = "graph_render_progress_update";

        public function GraphViewEvent(type:String, data:Object = null, bubbles:Boolean = false, cancelable:Boolean = false) { 
            super(type, data, bubbles, cancelable);
        }
        
        public override function clone():Event { 
            return new GraphViewEvent(type, data, bubbles, cancelable);
        }
    }
}
