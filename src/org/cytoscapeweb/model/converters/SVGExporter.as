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
package org.cytoscapeweb.model.converters { 
    import flare.display.TextSprite;
    import flare.vis.data.DataSprite;
    import flare.vis.data.EdgeSprite;
    import flare.vis.data.NodeSprite;
    
    import flash.display.BitmapData;
    import flash.display.CapsStyle;
    import flash.display.DisplayObject;
    import flash.filters.BitmapFilter;
    import flash.filters.GlowFilter;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import flash.text.TextField;
    import flash.text.TextFormatAlign;
    import flash.utils.ByteArray;
    
    import mx.graphics.codec.PNGEncoder;
    import mx.utils.Base64Encoder;
    
    import org.cytoscapeweb.model.data.ConfigVO;
    import org.cytoscapeweb.model.data.VisualStyleVO;
    import org.cytoscapeweb.util.Anchors;
    import org.cytoscapeweb.util.ArrowShapes;
    import org.cytoscapeweb.util.Fonts;
    import org.cytoscapeweb.util.GraphUtils;
    import org.cytoscapeweb.util.Images;
    import org.cytoscapeweb.util.LineStyles;
    import org.cytoscapeweb.util.NodeShapes;
    import org.cytoscapeweb.util.Utils;
    import org.cytoscapeweb.util.VisualProperties;
    import org.cytoscapeweb.view.components.GraphView;
    import org.cytoscapeweb.view.render.ImageCache;
    import org.cytoscapeweb.vis.data.CompoundNodeSprite;
        
    /**
     * Class that generates an SGV image from the network.
     */
    public class SVGExporter {
        
        // ========[ CONSTANTS ]====================================================================

        private static const GLOW_WIDTH:Number = 3;
        private static const BACKGROUND_CLASS:String = "cw-background";
        private static const NODE_CLASS:String = "cw-node";
        private static const NODE_SHAPE_CLASS:String = "cw-node-shape";
        private static const EDGE_CLASS:String = "cw-edge";
        private static const EDGE_LINE_CLASS:String = "cw-edge-line";

        // ========[ PRIVATE PROPERTIES ]===========================================================
        
        private var _graphView:GraphView;
        private var _style:VisualStyleVO;
        private var _scale:Number;
        private var _shiftX:Number;
        private var _shiftY:Number;
        private var _imgCache:ImageCache = ImageCache.instance;
        
        // ========[ PUBLIC PROPERTIES ]============================================================

        public var margin:Number = 10;

        // ========[ CONSTRUCTOR ]==================================================================
        
        public function SVGExporter(view:GraphView) {
            this._graphView = view;         
        }

        // ========[ PUBLIC METHODS ]===============================================================

        /**
         * @param nodes
         * @param edges Regular or merged edges
         * @param scale The zooming scale applied to the graph.
         * @param showLabels Whether or not labels will be included. 
         * @param width The desired image width in pixels.
         * @param height The desired image height in pixels.
         */
        public function export(nodes:Array,
                               edges:Array,
                               style:VisualStyleVO,
                               config:ConfigVO,
                               scale:Number=1, 
                               width:Number=0, height:Number=0):String {
            _style = style;
            _scale = scale;
            var ds:DataSprite;
            var bounds:Rectangle = _graphView.getRealBounds();
            
            // Width and height depends on the current zooming and
            // we also add a margin to the image:
            var w:Number = bounds.width/_scale + 2*margin;
            var h:Number = bounds.height/_scale + 2*margin;
            
            var hPad:Number = 0
            
            if (width > 0 || height > 0) {
                // If the client asked a custom size image, we need a new scale factor:
                _scale = calculateNewScale(w,  h,  width,  height);
                // Center image horizontally:
                if (width/_scale > w) hPad = (width/_scale - w)/2;
                h = height;
                w = width;
            } else {
                // Otherwise, the other graphics elements don't need to be scaled: 
                _scale = 1;
            }
            
            // Create the root element:
            var svg:String = '<?xml version="1.0" standalone="no"?>' +
                             '<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">' +
                             '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" version="1.1" ' +
                                  'width="'+w+'px" height="'+h+'px" x="0px" y="0px" viewBox="0 0 '+w+' '+h+'" xml:space="preserve">';
            
            // Draw the background:
            var bgColor:String = Utils.rgbColorAsString(_style.getValue(VisualProperties.BACKGROUND_COLOR));
            svg += '<rect class="'+BACKGROUND_CLASS+'" x="0" y="0" width="100%" height="100%" fill="'+bgColor+'"/>';
            
            // Get the shift, in case one or more nodes were dragged or the graph view is not at [0,0]:
            var sp:Point = _graphView.vis.globalToLocal(new Point(bounds.x, bounds.y));
            _shiftX = sp.x - margin - hPad ;
            _shiftY = sp.y - margin;
            
            // Draw edges and nodes:
            if (nodes != null && nodes.length > 0) {
                var elements:Array = nodes.concat(edges);
                // Sort elements by their z-order,
                // so overlapping nodes/edges will have the same position in the generated image:
                elements = GraphUtils.sortByZOrder(elements);
                
                for each (ds in elements) {
                    if (ds is NodeSprite)
                        svg += drawNode(ds as NodeSprite);
                    else
                        svg += drawEdge(ds as EdgeSprite, config.edgeLabelsVisible);
                }
                
                // Node labels always on top:
                if (config.nodeLabelsVisible) {
                    for each (ds in elements) {
                        if (ds is NodeSprite) svg += drawLabel(ds);
                    }
                }
            }
    
            // Close the root element:
            svg += '</svg>';
    
            return svg;
        }
        
        // ========[ PRIVATE METHODS ]==============================================================
        
        private function drawEdge(e:EdgeSprite, labelVisible:Boolean):String {
            var svg:String = '';
            
            if (e.visible && e.lineAlpha > 0 && e.lineWidth > 0) {
                var c:String, a:Number;
                    
                // Edge points:
                var start:Point, end:Point, c1:Point, c2:Point;
                if (e.props.$points != null) {
                    start = e.props.$points.start;
                    end = e.props.$points.end;
                    c1 = e.props.$points.c1;
                    c2 = e.props.$points.c2;
                }
                
                if (start != null && end != null) {
                    start = toImagePoint(start, e);
                    end = toImagePoint(end, e);
                    
                    if (c1 != null) c1 = toImagePoint(c1, e);
                    if (c2 != null) c2 = toImagePoint(c2, e);
                    
                    // Arrows points:
                    var sArrowPoints:Array = toImagePointsArray(e.props.$points.sourceArrow, e);
                    var tArrowPoints:Array = toImagePointsArray(e.props.$points.targetArrow, e);
                    var sJointPoints:Array = toImagePointsArray(e.props.$points.sourceArrowJoint, e);
                    var tJointPoints:Array = toImagePointsArray(e.props.$points.targetArrowJoint, e);
                    
                    var saStyle:Object = ArrowShapes.getArrowStyle(e, e.props.sourceArrowShape, e.props.sourceArrowColor);
                    var taStyle:Object = ArrowShapes.getArrowStyle(e, e.props.targetArrowShape, e.props.targetArrowColor);
                    
                    var w:Number = e.lineWidth * _scale;
                    var loop:Boolean = e.source === e.target;
                    var lineStyle:String = e.props.lineStyle;
                    var solid:Boolean = lineStyle === LineStyles.SOLID;
                    var cap:String = 'butt';
                    var dashArr:String = '';
                    
                    if (!solid) {
                        var onLength:Number = LineStyles.getOnLength(e, lineStyle, _scale);
                        var offLength:Number = LineStyles.getOffLength(e, lineStyle, _scale);
                        dashArr = 'stroke-dasharray="'+onLength+','+offLength+'"';
                        cap = LineStyles.getCaps(lineStyle);
                        if (cap === CapsStyle.ROUND) cap = 'round';
                    }
                    
                    svg += '<g class="'+EDGE_CLASS+'">';
                    
                    // First let's draw any glow (e.g. for selected edges):
                    // -----------------------------------------------------
                    var filters:Array = e.filters;
                    
                    for each (var f:BitmapFilter in filters) {
                        if (f is GlowFilter) {
                            var glow:GlowFilter = f as GlowFilter;
                            var gw:Number = w + (GLOW_WIDTH * _scale);
                            c = Utils.rgbColorAsString(glow.color);
                            a = Math.min(glow.alpha, e.alpha);
                            
                            // The current version of AlivePDF does not support glows, gradients, etc.
                            // So we just draw a bigger shape behind the node:
                            svg += '<g stroke-linejoin="round" stroke-width="'+gw+'" stroke-linecap="'+cap+'" fill="none" stroke-opacity="'+a+'" stroke="'+c+'" '+dashArr+'>';
                            svg += drawEdgeShaft(start, end, c1, c2, loop);
                            svg += '</g>';
                            
                            // Arrow glow:
                            gw = GLOW_WIDTH * _scale;
                            
                            svg += '<g fill="'+c+'" fill-opacity="'+a+'" stroke-linejoin="round" stroke-width="'+gw+'" stroke-linecap="butt" stroke-opacity="'+a+'" stroke="'+c+'">';
                            svg += drawEdgeArrow(saStyle.shape, sArrowPoints, saStyle.height*_scale);
                            svg += drawEdgeArrowJoint(sJointPoints, saStyle.shape);
                            svg += drawEdgeArrow(taStyle.shape, tArrowPoints, taStyle.height*_scale);
                            svg += drawEdgeArrowJoint(tJointPoints, taStyle.shape);
                            svg += '</g>';
                        }
                    }
                    
                    c = Utils.rgbColorAsString(e.lineColor);
                    a = e.alpha;
                    
                    // Draw the edge's line and joints:
                    // -----------------------------------------------------
                    svg += '<g class="'+EDGE_LINE_CLASS+'" stroke-linejoin="round" stroke-width="'+w+'" stroke-linecap="'+cap+'" fill="none" stroke-opacity="'+a+'" stroke="'+c+'" '+dashArr+'>';
                    svg += drawEdgeShaft(start, end, c1, c2, loop);
                    svg += '</g>';
                    
                    // Draw arrow joints:
                    // -----------------------------------------------------
                    svg += '<g fill="'+c+'" fill-opacity="'+a+'" stroke="none">';
                    svg += drawEdgeArrowJoint(sJointPoints, saStyle.shape);
                    svg += drawEdgeArrowJoint(tJointPoints, taStyle.shape);
                    svg += '</g>';
                    
                    // Draw arrows:
                    // -----------------------------------------------------
                    c = Utils.rgbColorAsString(saStyle.color);
                    svg += '<g fill="'+c+'" fill-opacity="'+a+'" stroke="none">';
                    svg += drawEdgeArrow(saStyle.shape, sArrowPoints, saStyle.height*_scale);
                    svg += '</g>';
                    
                    c = Utils.rgbColorAsString(taStyle.color);
                    svg += '<g fill="'+c+'" fill-opacity="'+a+'" stroke="none">';
                    svg += drawEdgeArrow(taStyle.shape, tArrowPoints, taStyle.height*_scale);
                    svg += '</g>';
                    
                    // Close edge group:
                    svg += '</g>';
                    
                    // Edge label:
                    if (labelVisible) svg += drawLabel(e);
                }
            }
            
            return svg;
        }
        
        private function drawNode(n:NodeSprite):String {
            var svg:String = '';
            
            if (n.visible && n.alpha > 0) {
                var c:String, lc:String, a:Number, lw:Number;
                var w:Number, h:Number;
                var nodeSvgShape:String;
                var img:BitmapData;
                
                // Get the Global node point (relative to the stage):
                var np:Point = toImagePoint(new Point(n.x, n.y), n);
                
                svg += '<g class="'+NODE_CLASS+'">';
                
                // First let's draw any node glow (e.g. for selected nodes):
                var filters:Array = n.filters;
                for each (var f:BitmapFilter in filters) {
                    if (f is GlowFilter) {
                        var glow:GlowFilter = f as GlowFilter;
                        lw = GLOW_WIDTH * _scale;
                        lc = Utils.rgbColorAsString(glow.color);
                        a = Math.min(glow.alpha, n.alpha);
                        w = (n.width + GLOW_WIDTH) * _scale;
                        h = (n.height + GLOW_WIDTH) * _scale;
                        
                        // The current version of AlivePDF does not support glows, gradients, etc.
                        // So we just draw a bigger shape behind the node:
                        svg += '<g fill="none" stroke="'+lc+'" stroke-linejoin="round" stroke-width="'+lw+'" stroke-linecap="butt" stroke-opacity="'+a+'">';
                        svg += drawNodeShape(n.shape, np.x, np.y, w, h, true);
                        svg += '</g>';
                    }
                }
                
                // Then draw the node:
                lw = n.lineWidth*_scale;
                lc = Utils.rgbColorAsString(n.lineColor);
                c = Utils.rgbColorAsString(n.fillColor);
                a = n.alpha;
                w = (n.width - n.lineWidth) * _scale;
                h = (n.height - n.lineWidth) * _scale;
 
                svg += '<g class="'+NODE_SHAPE_CLASS+'" fill="'+c+'" opacity="'+a+'" stroke="'+lc+'" stroke-linejoin="round" stroke-width="'+lw+'" stroke-linecap="butt" stroke-opacity="'+a+'">';
                
                // Basic node shape
                svg += (nodeSvgShape = drawNodeShape(n.shape, np.x, np.y, w, h, n.props.transparent));
                
                // Node image, if any:
                img = _imgCache.getImage(n.props.imageUrl);
                
                if (img != null) {
                    // Rescale image:
                    img = Images.resizeToFill(img, new Rectangle(0, 0, w, h));
                    
                    // Encode as PNG and get bytes as Base64:
                    var encoder:PNGEncoder = new PNGEncoder();
                    var ba:ByteArray = encoder.encode(img);
                    var b64Enc:Base64Encoder = new Base64Encoder();
                    b64Enc.encodeBytes(ba);
                    var b64:String = b64Enc.toString();
                    
                    svg += '<clipPath id="clipNode_'+n.data.id+'">';
                    svg += nodeSvgShape;
                    svg += '</clipPath>';
                    svg += '<g clip-path="url(#clipNode_'+n.data.id+')">';
                    svg += '<g transform="matrix(1, 0, 0, 1, '+(np.x-w/2)+', '+(np.y-h/2)+')">';
                    svg += '<image x="0" y="0" width="'+img.width+'" height="'+img.height+'" xlink:href="data:image/PNG;base64,'+b64+'"/>';
                    svg += '</g>';
                    svg += '</g>';
                }
                
                svg += '</g>'; // Close node shape groupd
                svg += '</g>'; // Close node group
            }
            
            return svg;
        }
        
        private function drawLabel(ds:DataSprite):String {
            var svg:String = '';
            var lbl:TextSprite = ds.props.label;
                
            if (lbl != null && lbl.visible && lbl.alpha > 0) {
                var text:String = lbl.text;
                var lblSize:int = Math.round(lbl.size*_scale);
                var filter:Object, gf:GlowFilter;
                
                if (text != null && text != "" && lblSize >= 1) {
                    var field:TextField = lbl.textField;
                    var lines:Array = text.split("\r");
    
                    // ATTENTION!!!
                    // It seems that Flash does not convert points to pixels correctly. 
                    // See: - http://alarmingdevelopment.org/?p=66
                    //      - http://www.actionscript.org/forums/showthread.php3?p=821842
                    // I found out that the text height is usually 28% smaller than the label size.
                    var textHeight:Number = lbl.size * 0.72 * _scale;
                    textHeight *= 1.25; // vertical spacing between lines
                    var textWidth:Number = field.textWidth * _scale;
    
                    // Get the Global label point (relative to the stage):
                    var p:Point = toImagePoint(new Point(lbl.x, lbl.y), lbl);
                    var hAnchor:String = Anchors.CENTER;
                    var vAnchor:String = Anchors.MIDDLE;
                    
                    if (ds is CompoundNodeSprite
                        && (ds as CompoundNodeSprite).isInitialized()) {
                        hAnchor = _style.getValue(VisualProperties.C_NODE_LABEL_HANCHOR, ds.data);
                        vAnchor = _style.getValue(VisualProperties.C_NODE_LABEL_VANCHOR, ds.data);
                    } else if (ds is NodeSprite) {
                        hAnchor = _style.getValue(VisualProperties.NODE_LABEL_HANCHOR, ds.data);
                        vAnchor = _style.getValue(VisualProperties.NODE_LABEL_VANCHOR, ds.data);
                    }
    
                    var hpad:Number = 2 * _scale;
                    switch (hAnchor) {
                        case Anchors.LEFT:   p.x += hpad; break;
                        case Anchors.RIGHT:  p.x -= hpad; break;
                    }
                    
                    // Vertical anchor:
                    // The label height is different from the real text height, because
                    // there is a margin between the text and the text field border:
                    var vpad:Number = 2 * _scale;
                    switch (vAnchor) {
                        case Anchors.TOP:
                            p.y -= textHeight/2;
                            p.y += ( textHeight/4 + vpad );
                            break;
                        case Anchors.MIDDLE:
                            p.y -= ( (textHeight/2) * lines.length );
                            p.y -= textHeight/6;
                            break;
                        case Anchors.BOTTOM:
                            p.y -= ( (textHeight * lines.length) + vpad );
                            break;
                    }
    
                    var style:String = lbl.italic ? 'italic': 'normal';
                    var weight:String = lbl.bold ? 'bold' : 'normal';
                    
                    // Choose the most similar font:
                    var family:String = lbl.font;
                    if (family == Fonts.SANS_SERIF) family = 'sans-serif';
                    else if (family == Fonts.SERIF) family = 'serif';
                    else if (family == Fonts.TYPEWRITER) family = 'courier';
                    
                    var c:String = Utils.rgbColorAsString(lbl.color);
                    var a:Number = ds.alpha;
                    var ta:String = getTextAnchor(lbl);
                    
                    // Glow filter:
                    var sc:String = "none", so:Number = 0, sw:Number = 0;
                    var filters:Array = lbl.filters;
                    
                    if (filters != null) {
                        for each (filter in filters) {
                            if (filter is GlowFilter) {
                                gf = filter as GlowFilter;
                                so = gf.alpha;
                                
                                if (so > 0) {
                                    sc = Utils.rgbColorAsString(gf.color);
                                    sw = Math.max(0.1, gf.blurX);
                                    
                                    drawText(so);
                                }
                            }
                        }
                    }
                    
                    // TODO: use filters instead, when Safari and IE supports it
                    drawText(0);
    
                    function drawText(so:Number):void {                
                        svg += '<text font-family="'+family+'" font-style="'+style+'" font-weight="'+weight+'"' +
                                    ' stroke="'+sc+'" stroke-width="'+sw+'" stroke-opacity="'+so+'" stroke-linejoin="round" fill="'+c+'"' +
                                    ' fill-opacity="'+a+'" font-size="'+lblSize+'" x="'+p.x+'" y="'+p.y+'" style="text-anchor:'+ta+';">';
                        
                        if (lines.length > 0) {
                            for (var i:int = 0; i < lines.length; i++) {
                                var ln:String = lines[i];
                                svg += '<tspan style="text-anchor:'+ta+';" x="'+p.x+'" dy="'+textHeight+'">'+ln+'</tspan>';
                            }
                        } else {
                            svg += text;
                        }
                    
                        svg += '</text>';
                    }
                }
            }
            
            return svg;
        }
        
        private function drawNodeShape(shape:String, x:Number, y:Number, w:Number, h:Number, transparent:Boolean):String {
            var svg:String = '';
            var r:Rectangle = new Rectangle(x-w/2, y-h/2, w, h);
            var fillOpacity:String = transparent ?  ' fill-opacity="0"' : '';
            
            switch (shape) {
                case NodeShapes.ELLIPSE:
                    svg += '<ellipse cx="'+x+'" cy="'+y+'" rx="'+(w/2)+'" ry="'+(h/2)+'"'+fillOpacity+'/>';
                    break;
                case NodeShapes.RECTANGLE:
                    svg += '<rect x="'+(x-w/2)+'" y="'+(y-h/2)+'" width="'+w+'" height="'+h+'"'+fillOpacity+'/>';
                    break;
                case NodeShapes.ROUND_RECTANGLE:
                    // corners (and control points), clockwise:
                    var x1:Number = x - w/2, y1:Number = y - h/2;
                    var x2:Number = x + w/2, y2:Number = y1;
                    var x3:Number = x2,      y3:Number = y + h/2;
                    var x4:Number = x1,      y4:Number = y3;
                    // rounded corner width/height:
                    var w4:Number = NodeShapes.getRoundRectCornerRadius(w, h);
                    var h4:Number = w4;
                    
                    svg += '<path d="M'+(x1+w4)+','+(y1) +
                                   ' L'+(x2-w4)+','+(y2) +
                                   ' Q'+(x2)+','+(y2)+' '+(x2)+','+(y2+h4) +
                                   ' L'+(x3)+','+(y4-h4) +
                                   ' Q'+(x3)+','+(y3)+' '+(x3-w4)+','+(y3) +
                                   ' L'+(x4+w4)+','+(y4) +
                                   ' Q'+(x4)+','+(y4)+' '+(x4)+','+(y4-h4) +
                                   ' L'+(x1)+','+(y1+h4) +
                                   ' Q'+(x1)+','+(y1)+' '+(x1+w4)+','+(y1)+'"'+
                                   fillOpacity+'/>';
                    break;
                default:
                    var points:Array = NodeShapes.getDrawPoints(r, shape);
                    var pp:String = '';
                    for (var i:int = 0; i < points.length; i += 2) pp += (points[i]+','+points[i+1]+' ');
                    svg += '<polygon points="'+pp+'"'+fillOpacity+'/>';
            }
            
            return svg;
        }
        
        private function drawEdgeShaft(start:Point, end:Point, c1:Point, c2:Point, loop:Boolean):String {
            var svg:String = '<path d="M'+start.x+','+start.y+' ';
            
            if (c1 != null) {
                // Curve:
                if (c2 != null) {
                    // Cubic bezier:
                    if (loop) {
                        // Invert control points:
                        var p:Point = c1.clone();
                        c1 = c2.clone();
                        c2 = p;
                    }
                    svg += 'C'+c1.x+","+c1.y+" "+c2.x+","+c2.y+" "+end.x+','+end.y;
                } else {
                    // Quadratic bezier:
                    svg += 'Q'+c1.x+","+c1.y+" "+end.x+','+end.y;
                }
            } else {
                // Line:
                svg += 'L'+end.x+','+end.y;
            }
            svg += '"/>';
            
            return svg;
        }
        
        private function drawEdgeArrow(shape:String, points:Array, diameter:Number=0):String {
            var svg:String = '';
            
            if (points != null && points.length > 0) {
                if (shape === ArrowShapes.CIRCLE) {
                    var center:Point = points[0];
                    svg += '<circle cx="'+center.x+'" cy="'+center.y+'" r="'+(diameter/2)+'"/>';
                } else if (shape === ArrowShapes.ARROW) {
                    var p1:Point = points[0];
                    var c1:Point = points[1];
                    var p2:Point = points[2];
                    var p3:Point = points[3];
                    var c2:Point = points[4];
                    svg += '<path d="M'+p1.x+','+p1.y +
                                   ' Q'+c1.x+','+c1.y+' '+p2.x+','+p2.y +
                                   ' L'+p3.x+','+p3.y +
                                   ' Q'+c2.x+','+c2.y+' '+p1.x+','+p1.y+'"/>';
                } else {
                    // Draw a polygon:
                    var pp:String = '';
                    for each (var p:Point in points) pp += (p.x+','+p.y+' ');
                    svg += '<polygon points="'+pp+'"/>';
                }
            }
            
            return svg;
        }
        
        private function drawEdgeArrowJoint(points:Array, arrowShape:String):String {
            var svg:String = '';
            
            if (points != null && points.length > 0) {
                switch (arrowShape) {
                    case ArrowShapes.CIRCLE:
                        if (points.length > 4) {
                            svg += '<path d="M'+points[0].x+','+points[0].y +
                                           ' L'+points[1].x+','+points[1].y +
                                           ' L'+points[2].x+','+points[2].y +
                                           ' L'+points[3].x+','+points[2].y +
                                           ' Q'+points[4].x+','+points[4].y+' '+points[0].x+','+points[0].y+'"/>';
                        }
                        break;
                    default:
                        var pp:String = '';
                        for each (var p:Point in points) pp += (p.x+','+p.y+' ');
                        svg += '<polygon points="'+pp+'"/>';
                        break;
                }
            }
            
            return svg;
        }
        
        /**
         * It converts a sprite coordinate to its correspondent element in the PDF.
         */
        private function toImagePoint(p:Point, display:DisplayObject):Point {
            // Get the Global point (relative to the stage):
            var ip:Point = display.parent.localToGlobal(p);
            // Get the local point, relative to the graph container:
            ip = _graphView.vis.globalToLocal(ip);
            // Remove the shift:
            ip.x -= _shiftX;
            ip.y -= _shiftY;
            ip.x *= _scale;
            ip.y *= _scale;
            
            return ip;
        }
        
        private function toImagePointsArray(points:Array, display:DisplayObject):Array {
            var arr:Array;
            
            if (points != null) {
                arr = [];
                for each (var p:Point in points) {
                   arr.push(toImagePoint(p, display));
                }
            }
            
            return arr;
        }

        private function calculateNewScale(w:Number, h:Number, newW:Number, newH:Number):Number {
            if (newW == 0) newW = w;
            if (newH == 0) newH = h;
            
            var graphEdge:Number = w; 
            var pageEdge:Number = newW;
            
            if (h/w > newH/newW) {
                graphEdge = h;
                pageEdge = newH;
            }
     
            return pageEdge / graphEdge;
        }
        
        private function getTextAnchor(lbl:TextSprite):String {
            var ta:String = 'middle';
     
            if (lbl.textFormat.align === TextFormatAlign.LEFT) ta = 'start';
            else if (lbl.textFormat.align === TextFormatAlign.RIGHT) ta = 'end';
     
            return ta;
        }
    }
}