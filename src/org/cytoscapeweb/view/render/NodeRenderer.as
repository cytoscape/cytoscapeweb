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
	import flare.vis.data.EdgeSprite;
	import flare.vis.data.NodeSprite;
	import flare.vis.data.render.ShapeRenderer;
	
	import flash.display.BitmapData;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	import flash.utils.setTimeout;
	
	import mx.utils.StringUtil;
	
	import org.cytoscapeweb.ApplicationFacade;
	import org.cytoscapeweb.model.ConfigProxy;
	import org.cytoscapeweb.model.GraphProxy;
	import org.cytoscapeweb.util.NodeShapes;
	

    public class NodeRenderer extends ShapeRenderer {
    	
        private static var _instance:NodeRenderer = new NodeRenderer();
        public static function get instance():NodeRenderer { return _instance; }

        // ========[ CONSTRUCTOR ]==================================================================

        public function NodeRenderer(defaultSize:Number = 6) {
            this.defaultSize = defaultSize;
        }
        
        // ========[ PRIVATE PROPERTIES ]===========================================================
        
        private var _imgCache:ImageCache = ImageCache.instance;
        
        private var _graphProxy:GraphProxy;
        protected function get graphProxy():GraphProxy {
            if (_graphProxy == null)
                _graphProxy = ApplicationFacade.getInstance().retrieveProxy(GraphProxy.NAME) as GraphProxy;
            return _graphProxy;
        }
        
        private var _configProxy:ConfigProxy;
        protected function get configProxy():ConfigProxy {
            if (_configProxy == null)
                _configProxy = ApplicationFacade.getInstance().retrieveProxy(ConfigProxy.NAME) as ConfigProxy;
            return _configProxy;
        }
        
        // ========[ PUBLIC METHODS ]===============================================================
        
        /** @inheritDoc */
        public override function render(d:DataSprite):void {trace("RENDER NODE: " + d.data.id);
            var lineAlpha:Number = d.lineAlpha;
            var fillAlpha:Number = d.fillAlpha;
            var size:Number = d.size * defaultSize;
            
            var g:Graphics = d.graphics;
            g.clear();
            
            // Just to prevent rendering issues when drawing large bitmaps on small nodes:
            d.cacheAsBitmap = d.props.imageUrl != null;
            
            if (lineAlpha > 0 && d.lineWidth > 0) {
                var pixelHinting:Boolean = d.shape === NodeShapes.ROUND_RECTANGLE;
                g.lineStyle(d.lineWidth, d.lineColor, lineAlpha, pixelHinting);
            }
            
            if (fillAlpha > 0) {
                // 1. Draw the background color:
                // Using a bit mask to avoid transparent mdes when fillcolor=0xffffffff.
                // See https://sourceforge.net/forum/message.php?msg_id=7393265
                g.beginFill(0xffffff & d.fillColor, fillAlpha);
                drawShape(d, d.shape, size);
                g.endFill();
                
                // 2. Draw an image on top:
                drawImage(d, size);
            }
            
            // To prevent gaps between the node and its edges when the node has the
            // border width changed on mouseover or selection
            NodeSprite(d).visitEdges(function(e:EdgeSprite):Boolean {
               e.dirty();
               return false; 
            }, NodeSprite.GRAPH_LINKS);
        }
        
        // ========[ PRIVATE METHODS ]==============================================================
        
        private function drawShape(s:Sprite, shape:String, size:Number):void {
            var g:Graphics = s.graphics;
            
            switch (shape) {
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
                case NodeShapes.V:
                    var r:Rectangle = new Rectangle(-size/2, -size/2, size, size);
                    var points:Array = NodeShapes.getDrawPoints(r, shape);
                    Shapes.drawPolygon(g, points);
                    break;
                case NodeShapes.ROUND_RECTANGLE:
                    g.drawRoundRect(-size/2, -size/2, size, size, size/2, size/2);
                    break;
                case NodeShapes.ELLIPSE:
                default:
                    Shapes.drawCircle(g, size/2);
            }
        }
        
        private function drawImage(d:DataSprite, size:Number):void {
            var url:String = d.props.imageUrl;
            
            if (size > 0 && url != null && StringUtil.trim(url).length > 0) {
                // Load the image into the cache first?
                if (!_imgCache.contains(url)) {trace("Will load IMAGE...");
                    _imgCache.loadImage(url);
                }
                if (_imgCache.isLoaded(url)) {trace(" .LOADED :-)");
                    draw();
                } else {trace(" .NOT loaded :-(");
                    drawWhenLoaded();
                }

                function drawWhenLoaded():void {
                    setTimeout(function():void {trace(" .TIMEOUT: Checking again...");
                        if (_imgCache.isLoaded(url)) draw();
                        else if (!_imgCache.isBroken(url)) drawWhenLoaded();
                    }, 50);
                }
                
                function draw():void {trace("Will draw: " + d.data.id);
                    // Get the image from cache:
                    var bd:BitmapData = _imgCache.getImage(url);
                    
                    if (bd != null) {
                        var bmpSize:Number = Math.min(bd.height, bd.width);
                        var scale:Number = size/bmpSize;

                        var m:Matrix = new Matrix();
                        m.scale(scale, scale);
                        m.translate(-(bd.width*scale)/2, -(bd.height*scale)/2);
                        
                        d.graphics.beginBitmapFill(bd, m, false, true);
                        drawShape(d, d.shape, size);
                        d.graphics.endFill();
                    }
                }
            }
        }
    }
}