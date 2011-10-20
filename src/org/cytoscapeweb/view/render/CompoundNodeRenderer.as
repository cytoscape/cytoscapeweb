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
	import flare.vis.data.DataSprite;
	
	import flash.display.Graphics;
	import flash.geom.Rectangle;
	
	import org.cytoscapeweb.util.GraphUtils;
	import org.cytoscapeweb.util.NodeShapes;
	import org.cytoscapeweb.vis.data.CompoundNodeSprite;

	/**
	 * This class is specifically designed to render CompoundNodeSprite
	 * instances. However, it may also be used to render NodeSprites since
	 * it extends NodeRenderer.  
	 * 
	 * @author Selcuk Onur Sumer
	 */
	public class CompoundNodeRenderer extends NodeRenderer {
		/**
		 * Singleton instance. 
		 */
		private static var _instance:CompoundNodeRenderer = new CompoundNodeRenderer();
		
		private var _imgCache:ImageCache = ImageCache.instance;
		
		public static function get instance():CompoundNodeRenderer {
			return _instance;
		}
		
		public function CompoundNodeRenderer(defaultSize:Number = 6) {
			super(defaultSize);
		}
		
		/**
		 * Overridden rendering function which is specialized for the
		 * compound node sprites. If the data sprite is not a compound node
		 * sprite, then the rendering is just forwarded to the render method  
		 * of the super class.
		 * 
		 * @param d	data sprite to be rendered
		 */
		public override function render(d:DataSprite):void {
			var ns:CompoundNodeSprite;
			var points:Array;
			var g:Graphics = d.graphics;
			var lineAlpha:Number = d.lineAlpha;
			var fillAlpha:Number = d.fillAlpha;
			
			if (d is CompoundNodeSprite) {
				ns = (d as CompoundNodeSprite);
				
				if (!ns.isInitialized() || ns.bounds == null || ns.allChildrenInvisible()) {
					// no child or bounds set yet, render with default size & shape					
					super.render(d);
				} else {
					g.clear();
					
					if (lineAlpha > 0 && d.lineWidth > 0) {
						var pixelHinting:Boolean = d.shape === NodeShapes.ROUND_RECTANGLE;
						g.lineStyle(d.lineWidth, d.lineColor, lineAlpha, pixelHinting);
					}
					
    				// 1. Draw the background color:
                    // Even if "transparent", we still need to draw a shape,
                    // or the node will not receive mouse events
                    if (d.props.transparent) fillAlpha = 0;
    				// draw the background color:
    				// Using a bit mask to avoid transparent mdes when fillcolor=0xffffffff.
    				// See https://sourceforge.net/forum/message.php?msg_id=7393265
    				g.beginFill(0xffffff & d.fillColor, fillAlpha);
    				this.drawShape(ns, ns.shape, this.adjustBounds(ns));
    				g.endFill();
						
					// 2. draw an image on top
					if (ns.isInitialized()) {
                        drawImage(ns, ns.bounds.width, ns.bounds.height);
					}
				}
				
				// bring (recursively) child nodes & edges inside the compound
				// to the front, otherwise they remain on the back side of
				// the compound node.
				GraphUtils.bringToFront(ns);
				// prevent gaps between this node and its edges
				updateEdges(ns);
				
			} else {
				// if the data sprite is not a compound node, then just call
				// the superclass renderer function.
				super.render(d);
			}
		}
		
		/**
		 * Adjusts the bounds of the given compound node by using local 
		 * coordinates of the given compound node sprite. This function does
		 * not modify the original bounds of the compound. Instead, creates
		 * a new Rectangle instance and applies changes on that instance.
		 * 
		 * @param ns	compound node whose bounds will be adjusted
		 * @return		adjusted bounds as a Rectangle instance
		 */
		private function adjustBounds(ns:CompoundNodeSprite):Rectangle {
			// create a copy of original node bounds
			var bounds:Rectangle = ns.bounds.clone();
			
			// convert bounds from global to local
			bounds.x -= ns.x;
			bounds.y -= ns.y;
			
			// return adjusted bounds
			return bounds;
		}
	}
}