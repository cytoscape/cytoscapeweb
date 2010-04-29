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
package org.cytoscapeweb.view.layout {
	import flare.vis.data.NodeSprite;
	import flare.vis.operator.layout.Layout;
	
	import flash.geom.Point;
	
	
	public class PresetLayout extends Layout {
		
		// ========[ PRIVATE PROPERTIES ]===========================================================
		
		private var _points:Object;
		
		// ========[ PUBLIC PROPERTIES ]============================================================
		
		public function get points():Object {
			return _points;
		}
		
        public function set points(points:Object):void {
            if (points != null)
                _points = points;
            else
                _points = {};
        }
        
        // ========[ CONSTRUCTOR ]==================================================================
		
		public function PresetLayout(points:Object=null) {
			this.points = points;
		}
		
		// ========[ PUBLIC METHODS ]===============================================================
		
        public function addPoint(nodeId:String, p:Point):void {
            points[nodeId] = p;
        }

        protected override function layout():void {
            visualization.data.nodes.visit(function(n:NodeSprite):void {
                var p:Point = points[n.data.id];
                if (p != null) {
	                p = visualization.parent.localToGlobal(p);
	                p = visualization.globalToLocal(p);
	                n.x = p.x;
	                n.y = p.y;
                }
            });
        }

	}
}
