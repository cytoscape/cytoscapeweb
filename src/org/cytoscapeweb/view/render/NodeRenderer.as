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
    import flare.display.TextSprite;
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
    import org.cytoscapeweb.model.error.CWError;
    import org.cytoscapeweb.model.methods.error;
    import org.cytoscapeweb.util.ErrorCodes;
    import org.cytoscapeweb.util.NodeShapes;
    

    public class NodeRenderer extends ShapeRenderer {
        
        private static const WRAP_PAD:Number = 5;
        
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
        public override function render(d:DataSprite):void {
            try {
                // Using a bit mask to avoid transparent mdes when fillcolor=0xffffffff.
                // See https://sourceforge.net/forum/message.php?msg_id=7393265
                var fillColor:uint = 0xffffff & d.fillColor;
                var fillAlpha:Number = d.fillAlpha;
                var size:Number = d.size * defaultSize;
                
                var lineColor:uint = d.lineColor;
                var lineAlpha:Number = d.lineAlpha;
                var lineWidth:Number = d.lineWidth;
                
                var w:Number = d.props.width;
                var h:Number = d.props.height;
                
                if (d.props.autoSize) {
                    var lbl:TextSprite = d.props.label;
                    var hf:Number = 1, wf:Number = 1;
                    
                    if (lbl != null && lbl.visible) {
                        w = isNaN(lbl.width) ? 0 : lbl.width;
                        h = isNaN(lbl.height) ? 0 : lbl.height;
                        
                        // TODO: it is just an approximation--calculate more size accurately
                        switch (d.shape) {
                            case NodeShapes.TRIANGLE:      hf = wf = 2.0; break;
                            case NodeShapes.V:             hf = wf = 3.2; break;
                            case NodeShapes.OCTAGON:       hf = wf = 1.4; break;
                            case NodeShapes.HEXAGON:       hf = wf = 1.6; break;
                            case NodeShapes.PARALLELOGRAM: wf = 2.6;      break;
                            case NodeShapes.DIAMOND:       hf = wf = 2.0; break;
                            case NodeShapes.ELLIPSE:       hf = wf = 1.4; break;
                        }
                        
                        w *= wf;
                        h *= hf;
                    } else {
                        w = h = 3 * WRAP_PAD;
                    }
                    
                    w += 2 * WRAP_PAD;
                    h += 2 * WRAP_PAD;
                } else {
                    if (isNaN(w) || w < 0) w = size;
                    if (isNaN(h) || h < 0) h = size;
                }
                
                var g:Graphics = d.graphics;
                g.clear();
                
                // Just to prevent rendering issues when drawing large bitmaps on small nodes:
                d.cacheAsBitmap = d.props.imageUrl != null;
                
                if (isNaN(w) || isNaN(h) || w <= 0 || h <= 0) return;
                
                if (lineAlpha > 0 && lineWidth > 0) {
                    var pixelHinting:Boolean = d.shape === NodeShapes.ROUND_RECTANGLE;
                    g.lineStyle(lineWidth, lineColor, lineAlpha, pixelHinting);
                }
                
                // 1. Draw the background color:
                // Even if "transparent", we still need to draw a shape,
                // or the node will not receive mouse events
                if (d.props.transparent) fillAlpha = 0;
                g.beginFill(fillColor, fillAlpha);
                drawShape(d, d.shape, new Rectangle(-w/2, -h/2, w, h));
                g.endFill();
                
                // 2. Draw an image on top:
                drawImage(d, w, h);
                
                updateEdges(d as NodeSprite);
                
            } catch (err:Error) {
                error(new CWError("Error rendering Node '" + d.data.id +"': " + err.message,
                                  ErrorCodes.RENDERING_ERROR));
            }
        }
        
        // ========[ PRIVATE METHODS ]==============================================================
        
        protected function drawShape(s:Sprite, shape:String, bounds:Rectangle):void {
            var g:Graphics = s.graphics;
            var w:Number = bounds.width;
            var h:Number = bounds.height;
            var x:Number = bounds.x;
            var y:Number = bounds.y;
            
            if (isNaN(w) || isNaN(h)) return;
            
            switch (shape) {
                case null:
                    break;
                case NodeShapes.RECTANGLE:
                    g.drawRect(x, y, w, h);
                    break;
                case NodeShapes.TRIANGLE:
                case NodeShapes.DIAMOND:
                case NodeShapes.HEXAGON:
                case NodeShapes.OCTAGON:
                case NodeShapes.PARALLELOGRAM:
                case NodeShapes.V:
                    var points:Array = NodeShapes.getDrawPoints(bounds, shape);
                    Shapes.drawPolygon(g, points);
                    break;
                case NodeShapes.ROUND_RECTANGLE:
                    var eh:Number = NodeShapes.getRoundRectCornerRadius(w, h) * 2;
                    g.drawRoundRect(x, y, w, h, eh, eh);
                    break;
                case NodeShapes.ELLIPSE:
                default:
                    if (w == h)
                        Shapes.drawCircle(g, w/2);
                    else
                        g.drawEllipse(x, y, w, h);
            }
        }
        
        protected function drawImage(d:DataSprite, w:Number, h:Number):void {
            var url:String = d.props.imageUrl;
            
            if (w > 0 && h > 0 && url != null && StringUtil.trim(url).length > 0) {
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
                        var scale:Number = Math.max(w, h)/bmpSize;

                        var m:Matrix = new Matrix();
                        m.scale(scale, scale);
                        m.translate(-(bd.width*scale)/2, -(bd.height*scale)/2);
                        
                        d.graphics.beginBitmapFill(bd, m, false, true);
                        drawShape(d, d.shape, new Rectangle(-w/2, -h/2, w, h));
                        d.graphics.endFill();
                    }
                }
            }
        }
        
        protected function updateEdges(n:NodeSprite):void {
            // To prevent gaps between the node and its edges when the node has the
            // border width changed on mouseover or selection
            n.visitEdges(function(e:EdgeSprite):Boolean {
               e.dirty();
               return false; 
            }, NodeSprite.GRAPH_LINKS);
        }
    }
}
