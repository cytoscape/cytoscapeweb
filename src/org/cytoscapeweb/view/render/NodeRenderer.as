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
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Graphics;
	import flash.display.PixelSnapping;
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
                if (_imgCache.isLoaded(url)) {trace("% LOADED :-)");
                    draw();
                } else {trace("% NOT loaded :-(");
                    drawWhenLoaded();
                }

                function drawWhenLoaded():void {
                    setTimeout(function():void {trace("TIMEOUT: Checking again...");
                        if (_imgCache.isLoaded(url)) draw();
                        else if (!_imgCache.isBroken(url)) drawWhenLoaded();
                    }, 50);
                }
                
                function draw():void {trace("Will DRAW...: " + d.data.id);
                    // Get the image from cache:
                    var bd:BitmapData = _imgCache.getImage(url);
                    
                    if (bd != null) {
                        var bmpSize:Number = Math.max(bd.height, bd.width);
                        var maxZoom:Number = configProxy.maxZoom;
                        
                        // Reduce the image, if it is too large, to avoid some rendering issues:
//                        const MAX_BMP_SCALE:uint = 30;
//                        var zoom:Number = graphProxy.zoom;
//                        var maxBmpSize:Number = size * zoom * MAX_BMP_SCALE;
//                        
//                        if (bmpSize > maxBmpSize) {
//                            bd = resizeBitmap(bd, maxBmpSize/bmpSize);
//                            bmpSize = Math.max(bd.height, bd.width);
//                        }
                        
                        bd = resizeBitmapToFit(bd, size*maxZoom, size*maxZoom);
                        bmpSize = Math.max(bd.height, bd.width);
                        
                        var scale:Number =  size/bmpSize;

                        var m:Matrix = new Matrix();
                        m.scale(scale, scale);
                        m.translate(-(bd.width*scale)/2, -(bd.height*scale)/2);
                        
                        var b:Bitmap = new Bitmap();
                        
                        d.graphics.beginBitmapFill(bd, m, false, true);
                        drawShape(d, d.shape, size);
                        d.graphics.endFill();
                    }
                }
            }
        }
        
        private function resizeBitmapToFit(bd:BitmapData, nw:Number, nh:Number):BitmapData {
            if (bd.width > 0 && bd.height > 0) {
                var w:Number = bd.width;
                var h:Number = bd.height;
                var originalRatio:Number = w/h;
                var maxRatio:Number = nw/nh;
                var scale:Number;
                
                if (originalRatio > maxRatio) { // scale by width
                    scale = nw/w;
                } else { // scale by height
                    scale = nh/h;
                }
                
                var m:Matrix = new Matrix();
                m.scale(scale, scale);
                m.translate(nw/2-(w*scale)/2, nh/2-(h*scale)/2);
                
                var bd2:BitmapData = new BitmapData(nw, nh, true, 0x000000);
                bd2.draw(bd, m, null, null, null, true);
    
                var bmp:Bitmap = new Bitmap(bd2, PixelSnapping.NEVER, true);
                return bmp.bitmapData;
            }
            
            return bd;
        }
        
//        private function resizeBitmap(bd:BitmapData, scale:Number):BitmapData {   
//            var matrix:Matrix = new Matrix();
//            matrix.scale(scale, scale);
//            
//            var bd2:BitmapData = new BitmapData(bd.width * scale, bd.height * scale, true, 0x000000);
//            bd2.draw(bd, matrix, null, null, null, true);
//
//            var bmp:Bitmap = new Bitmap(bd2, PixelSnapping.NEVER, true);
//            
//            return bmp.bitmapData;
//        }
    }
}