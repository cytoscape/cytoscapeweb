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
package org.cytoscapeweb.view.render {
	import flare.util.Shapes;
	import flare.vis.data.DataSprite;
	import flare.vis.data.render.ShapeRenderer;
	
	import flash.display.Graphics;
	import flash.geom.Rectangle;
	
	import org.cytoscapeweb.util.NodeShapes;
	

    public class NodeRenderer extends ShapeRenderer {
    	
        private static var _instance:NodeRenderer = new NodeRenderer();
        /** Static AppNodeRenderer instance. */
        public static function get instance():NodeRenderer { return _instance; }        

        public function NodeRenderer(defaultSize:Number = 6) {
            this.defaultSize = defaultSize;
        }
        
        /** @inheritDoc */
        public override function render(d:DataSprite):void {
            var lineAlpha:Number = d.lineAlpha;
            var fillAlpha:Number = d.fillAlpha;
            var size:Number = d.size * defaultSize;
            
            var g:Graphics = d.graphics;
            g.clear();
            if (fillAlpha > 0) {
                // Using a bit mask to avoid transparent mdes when fillcolor=0xffffffff.
                // See https://sourceforge.net/forum/message.php?msg_id=7393265
                g.beginFill(0xffffff & d.fillColor, fillAlpha);
            }
            if (lineAlpha > 0 && d.lineWidth > 0) {
                g.lineStyle(d.lineWidth, d.lineColor, lineAlpha);
            }

            switch (d.shape) {
                case null:
                    break;
                case NodeShapes.RECTANGLE:
                    g.drawRect(-size/2, -size/2, size, size);
                    break;
                case NodeShapes.TRIANGLE:
                case NodeShapes.DIAMOND:
                case NodeShapes.HEXAGON:
                case NodeShapes.OCTAGON:
                case NodeShapes.PARALLELOGRAM:
                    var r:Rectangle = new Rectangle(-size/2, -size/2, size, size);
                    var points:Array = NodeShapes.getDrawPoints(r, d.shape);
                    Shapes.drawPolygon(g, points);
                    break;
                case NodeShapes.ROUND_RECTANGLE:
                    g.drawRoundRect(-size/2, -size/2, size, size, size/2, size/2);
                    break;
                case NodeShapes.ELLIPSE:
                default:
                    Shapes.drawCircle(g, size/2);
            }
            
            if (fillAlpha > 0) g.endFill();
        }       
    }
}