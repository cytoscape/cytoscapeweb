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
    
    import flash.display.CapsStyle;
    import flash.display.DisplayObject;
    import flash.filters.BitmapFilter;
    import flash.filters.GlowFilter;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import flash.text.TextField;
    import flash.utils.ByteArray;
    
    import org.alivepdf.colors.RGBColor;
    import org.alivepdf.display.Display;
    import org.alivepdf.drawing.Blend;
    import org.alivepdf.drawing.Caps;
    import org.alivepdf.drawing.DashedLine;
    import org.alivepdf.drawing.Joint;
    import org.alivepdf.drawing.WindingRule;
    import org.alivepdf.fonts.CoreFont;
    import org.alivepdf.fonts.FontFamily;
    import org.alivepdf.fonts.Style;
    import org.alivepdf.layout.Layout;
    import org.alivepdf.layout.Orientation;
    import org.alivepdf.layout.Size;
    import org.alivepdf.layout.Unit;
    import org.alivepdf.pages.Page;
    import org.alivepdf.pdf.PDF;
    import org.alivepdf.saving.Method;
    import org.cytoscapeweb.model.data.ConfigVO;
    import org.cytoscapeweb.model.data.VisualStyleVO;
    import org.cytoscapeweb.util.Anchors;
    import org.cytoscapeweb.util.ArrowShapes;
    import org.cytoscapeweb.util.Fonts;
    import org.cytoscapeweb.util.GraphUtils;
    import org.cytoscapeweb.util.LineStyles;
    import org.cytoscapeweb.util.NodeShapes;
    import org.cytoscapeweb.util.Utils;
    import org.cytoscapeweb.util.VisualProperties;
    import org.cytoscapeweb.view.components.GraphView;
    import org.cytoscapeweb.vis.data.CompoundNodeSprite;
        
    /**
     * Class that generates a vectorial image PDF file from the network.
     */
    public class PDFExporter {
        
        // ========[ CONSTANTS ]====================================================================

        private static const GLOW_WIDTH:Number = 3;

        // ========[ PRIVATE PROPERTIES ]===========================================================
        
        private var _graphView:GraphView;
        private var _style:VisualStyleVO;
        private var _scale:Number;
        private var _shiftX:Number;
        private var _shiftY:Number;
        private var _bgColor:RGBColor;
        
        // ========[ PUBLIC PROPERTIES ]============================================================

        public var margin:Number = 10;

        // ========[ CONSTRUCTOR ]==================================================================
        
        public function PDFExporter(view:GraphView) {
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
                               width:Number=0, height:Number=0):ByteArray {
            _style = style;
            _scale = scale;
            var bounds:Rectangle = _graphView.getRealBounds();
            var ds:DataSprite;
            
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
            
            var size:Size = new Size([w, h], "", [0, 0],[0, 0] );
            var orientation:String = Orientation.PORTRAIT;
            
            // Create the PFD document with 1 page:
            var pdf:PDF = new PDF(orientation, Unit.POINT, size);
            pdf.setDisplayMode(Display.FULL_PAGE, Layout.SINGLE_PAGE);
            var page:Page = new Page(orientation, Unit.POINT, size);
            pdf.addPage(page);
            
            // Draw the background:
            _bgColor = new RGBColor(_style.getValue(VisualProperties.BACKGROUND_COLOR));
            pdf.lineStyle(_bgColor, 0, 0);
            pdf.beginFill(_bgColor);
            pdf.drawRect(new Rectangle(0, 0, w, h));
            pdf.endFill();
            pdf.end();
            
            // Get the shift, in case one or more nodes were dragged or the graph view is not at [0,0]:
            var sp:Point = _graphView.vis.globalToLocal(new Point(bounds.x, bounds.y));
            _shiftX = sp.x - margin - hPad ;
            _shiftY = sp.y - margin;
            
            // Draw elements:
            if (nodes != null && nodes.length > 0) {
                var elements:Array = nodes.concat(edges);
                // Sort elements by their z-order,
                // so overlapping nodes/edges will have the same position in the generated image:
                elements = GraphUtils.sortByZOrder(elements);
                
                for each (ds in elements) {
                    if (ds is NodeSprite) drawNode(pdf, ds as NodeSprite);
                    else drawEdge(pdf, ds as EdgeSprite, config.edgeLabelsVisible);
                }
                
                // Node labels always on top:
                if (config.nodeLabelsVisible) {
                    for each (ds in elements) {
                        if (ds is NodeSprite) drawLabel(pdf, ds);
                    }
                }
            }
    
            var bytes:ByteArray = pdf.save(Method.LOCAL);
    
            return bytes;
        }
        
        // ========[ PRIVATE METHODS ]==============================================================
        
        private function drawEdge(pdf:PDF, e:EdgeSprite, labelVisible:Boolean):void {
            if (!e.visible || e.lineAlpha === 0 || e.lineWidth === 0) return;
                
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
                var dashedLine:DashedLine;
                var cap:String = (LineStyles.getCaps(lineStyle) === CapsStyle.ROUND) ? Caps.ROUND : Caps.NONE;
                var dashArr:String = '';
                
                if (!solid) {
                    var onLength:Number = LineStyles.getOnLength(e, lineStyle, _scale);
                    var offLength:Number = LineStyles.getOffLength(e, lineStyle, _scale);
                    dashedLine = new DashedLine([onLength, offLength, onLength, offLength]);
                } else {
                    dashedLine = null;
                }
                
                // First let's draw any glow (e.g. for selected edges):
                // -----------------------------------------------------
                var filters:Array = e.filters;
                for each (var f:BitmapFilter in filters) {
                    if (f is GlowFilter) {
                        var glow:GlowFilter = f as GlowFilter;
                        var gw:Number = w + GLOW_WIDTH*_scale;
                        var gc:RGBColor = new RGBColor(glow.color);
                        var ga:Number = Math.min(glow.alpha, e.alpha);
                        
                        // The current version of AlivePDF does not support glows, gradients, etc.
                        // So we just draw a bigger shape behind the node:
                        pdf.lineStyle(gc, gw, 0, ga, WindingRule.NON_ZERO, Blend.NORMAL, dashedLine, cap, Joint.MITER);
                        drawEdgeShaft(pdf, start, end, c1, c2, loop);
                        
                        // Arrow glow:
                        pdf.lineStyle(gc, GLOW_WIDTH*_scale, 0, ga, WindingRule.NON_ZERO, Blend.NORMAL, null, Caps.NONE, Joint.MITER);
                        pdf.beginFill(gc);
                        drawEdgeArrowJoint(pdf, sJointPoints, saStyle.shape);
                        drawEdgeArrowJoint(pdf, tJointPoints, taStyle.shape);
                        drawEdgeArrow(pdf, saStyle.shape, sArrowPoints, saStyle.height*_scale);
                        drawEdgeArrow(pdf, taStyle.shape, tArrowPoints, taStyle.height*_scale);
                        pdf.endFill();
                    }
                }
                
                // Draw the edge's line:
                // -----------------------------------------------------
                var edgeColor:RGBColor = new RGBColor(e.lineColor);
                pdf.lineStyle(edgeColor, w, 0, e.alpha, WindingRule.NON_ZERO, Blend.NORMAL, dashedLine, cap, Joint.MITER);
                              
                drawEdgeShaft(pdf, start, end, c1, c2, loop);
                
                // Draw arrow joints:
                // -----------------------------------------------------
                pdf.lineStyle(edgeColor, 0, 0, e.alpha, WindingRule.NON_ZERO, Blend.NORMAL, null, Caps.NONE, Joint.MITER);
                
                pdf.beginFill(edgeColor);
                drawEdgeArrowJoint(pdf, sJointPoints, saStyle.shape);
                drawEdgeArrowJoint(pdf, tJointPoints, taStyle.shape);
                pdf.endFill();
                
                // Draw arrows:
                // -----------------------------------------------------
                var saColor:RGBColor = new RGBColor(saStyle.color);
                pdf.lineStyle(saColor, 0, 0, e.alpha, WindingRule.NON_ZERO, Blend.NORMAL, null, Caps.NONE, Joint.MITER);
                pdf.beginFill(saColor);
                drawEdgeArrow(pdf, saStyle.shape, sArrowPoints, saStyle.height*_scale);
                pdf.endFill();
                
                var taColor:RGBColor = new RGBColor(taStyle.color);
                pdf.lineStyle(taColor, 0, 0, e.alpha, WindingRule.NON_ZERO, Blend.NORMAL, null, Caps.NONE, Joint.MITER);
                pdf.beginFill(taColor);
                drawEdgeArrow(pdf, taStyle.shape, tArrowPoints, taStyle.height*_scale);
                pdf.endFill();
                
                // Edge label:
                if (labelVisible) drawLabel(pdf, e);
            }
        }
        
        private function drawNode(pdf:PDF, n:NodeSprite):void {
            if (!n.visible || n.alpha === 0) return;
            
            // Get the Global node point (relative to the stage):
            var np:Point = toImagePoint(new Point(n.x, n.y), n);
            var nw:Number, nh:Number;
            
            // First let's draw any node glow (e.g. for selected nodes):
            var filters:Array = n.filters;
            for each (var f:BitmapFilter in filters) {
                if (f is GlowFilter) {
                    var glow:GlowFilter = f as GlowFilter;
                    var gw:Number = GLOW_WIDTH * _scale;
                    var gc:RGBColor = new RGBColor(glow.color);
                    nw = (n.width + GLOW_WIDTH) * _scale;
                    nh = (n.height + GLOW_WIDTH) * _scale;
                    
                    // The current version of AlivePDF does not support glows, gradients, etc.
                    // So we just draw a bigger shape behind the node:
                    pdf.lineStyle(gc, gw, 0, Math.min(glow.alpha, n.alpha),
                                  WindingRule.NON_ZERO, Blend.NORMAL, null, Caps.ROUND, Joint.ROUND);
                    drawNodeShape(pdf, n.shape, np.x, np.y, nw, nh);
                }
            }
            
            // Then draw the node:
            nw = (n.width - n.lineWidth) * _scale;
            nh = (n.height - n.lineWidth) * _scale;
            
            pdf.lineStyle(new RGBColor(n.lineColor), n.lineWidth*_scale, 0, n.alpha,
                          WindingRule.NON_ZERO, Blend.NORMAL, null, Caps.ROUND, Joint.ROUND);
            
            if (!n.props.transparent) pdf.beginFill(new RGBColor(n.fillColor));
            drawNodeShape(pdf, n.shape, np.x, np.y, nw, nh);
            if (!n.props.transparent) pdf.endFill();
        }
        
        private function drawLabel(pdf:PDF, d:DataSprite):void {
            var hAnchor:String = Anchors.CENTER;
            var vAnchor:String = Anchors.MIDDLE;
            var xOffset:Number = 0;
            var yOffset:Number = 0;
            const HPAD:Number = 2 * _scale;
            const VPAD:Number = 2 * _scale;
            var p:Point;
            var lbl:TextSprite = d.props.label;
                
            if (lbl != null && lbl.visible && lbl.alpha > 0) {
                var text:String = lbl.text;
                var lblSize:int = Math.round(lbl.size*_scale);
                
                if (text != null && text !== "" && lblSize >= 1) {
                    var field:TextField = lbl.textField;
                    var lines:Array = text.split("\r");
                    
                    // ATTENTION!!!
                    // It seems that Flash does not convert points to pixels correctly. 
                    // See: - http://alarmingdevelopment.org/?p=66
                    //      - http://www.actionscript.org/forums/showthread.php3?p=821842
                    // Or maybe the fonts used by the AlivePDF library are different.
                    // So this is a workaround to allow the correct alignment of the labels
                    // in the generated PDF:
                    // I found out that Arial's height is usually 28% smaller than the font size.
                    // Another possible solution would be to embed fonts, but it did not work for me.
                    var textHeight:Number = lbl.size * 0.72 * _scale;
                    var textWidth:Number = field.textWidth * _scale;
                    
                    // Get the Global label point (relative to the stage):
                    
                    if (d is CompoundNodeSprite
                        && (d as CompoundNodeSprite).isInitialized()) {
                        hAnchor = _style.getValue(VisualProperties.C_NODE_LABEL_HANCHOR, d.data);
                        vAnchor = _style.getValue(VisualProperties.C_NODE_LABEL_VANCHOR, d.data);
                        xOffset = _style.getValue(VisualProperties.C_NODE_LABEL_XOFFSET, d.data) * _scale;
                        yOffset = _style.getValue(VisualProperties.C_NODE_LABEL_YOFFSET, d.data) * _scale;
                    } else if (d is NodeSprite) {
                        // If node, calculate the label position from scratch
                        hAnchor = _style.getValue(VisualProperties.NODE_LABEL_HANCHOR, d.data);
                        vAnchor = _style.getValue(VisualProperties.NODE_LABEL_VANCHOR, d.data);
                        xOffset = _style.getValue(VisualProperties.NODE_LABEL_XOFFSET, d.data) * _scale;
                        yOffset = _style.getValue(VisualProperties.NODE_LABEL_YOFFSET, d.data) * _scale;
                    }
                    
                    if (d is NodeSprite) {
                        p = toImagePoint(new Point(d.x, d.y), d);
                        // Flare's label cordinates is relative to the label's upper-left corner (x,y)=(0,0),
                        // but AlivePDF uses the bottom-left corner instead (x,y)=(0,fonSize):
                        p.y += (textHeight + yOffset);
                        p.x += xOffset;
                        
                        switch (hAnchor) {
                            case Anchors.LEFT:
                                p.x += (HPAD + d.width/2);
                                break;
                            case Anchors.CENTER:
                                p.x -= (textWidth/2);
                                break;
                            case Anchors.RIGHT:
                                p.x -= (HPAD + textWidth +  + d.width/2);
                                break;
                        }
                        switch (vAnchor) {
                            case Anchors.TOP:
                                p.y += (VPAD + d.height/2);
                                break;
                            case Anchors.MIDDLE:
                                p.y -= (VPAD + (textHeight*lines.length)/2);
                                break;
                            case Anchors.BOTTOM:
                                p.y -= (VPAD + d.height/2 + textHeight*lines.length);
                                break;
                        }
                    } else {
                        // If edge, just get the actual label position--its always middle-center!
                        p = toImagePoint(new Point(lbl.x, lbl.y), lbl);
                        p.x -= textWidth/2;
                        p.y += textHeight;
                        p.y -= (textHeight * lines.length/2);
                    }
    
                    var style:String = lbl.bold ?
                                       (lbl.italic ? Style.BOLD_ITALIC : Style.BOLD) :
                                       (lbl.italic ? Style.ITALIC : Style.NORMAL);
                    
                    // Choose the most similar font:
                    var fontFamily:String = FontFamily.ARIAL;
                    if (lbl.font == Fonts.SERIF) fontFamily = FontFamily.TIMES;
                    else if (lbl.font == Fonts.TYPEWRITER) fontFamily = FontFamily.COURIER;
                    
                    var font:CoreFont = new CoreFont(fontFamily);
                    // TODO: set BOLD/ITALIC
                    pdf.textStyle(new RGBColor(lbl.color), lbl.alpha);
                    pdf.setFont(font, lblSize);
                    
                    for (var i:int = 0; i < lines.length; i++) {
                        var ln:String = lines[i];
                        var y:Number = p.y + textHeight * i;
                        pdf.addText(ln, p.x, y);
                    }
                }
            }
        }
        
        private function drawNodeShape(pdf:PDF, shape:String, x:Number, y:Number, w:Number, h:Number):void {
                var r:Rectangle = new Rectangle(x-w/2, y-h/2, w, h);
                
                switch (shape) {
                    case NodeShapes.ELLIPSE:
                        pdf.drawEllipse(x, y, w/2, h/2);
                        break;
                    case NodeShapes.ROUND_RECTANGLE:
                        var ew:Number = NodeShapes.getRoundRectCornerRadius(w, h);
                        pdf.drawRoundRect(r, ew);
                        break;
                    default:
                        var points:Array = NodeShapes.getDrawPoints(r, shape);
                        pdf.drawPolygone(points);
                }
        }
        
        private function drawEdgeShaft(pdf:PDF, start:Point, end:Point, c1:Point, c2:Point, loop:Boolean):void {
            // Draw the edge's line:
            pdf.moveTo(start.x, start.y);
            
            if (c1 != null) {
                var ctrl1:Point = new Point();
                var ctrl2:Point = new Point();
                
                if (loop) {
                    // It's already a cubic bezier:
                    ctrl1 = c2;
                    ctrl2 = c1;
                } else {
                    // It's a quadratic bezier - convert to cubic first:
                    Utils.quadraticToCubic(start, c1, end, ctrl1, ctrl2);
                }
                
                // Always draw a cubic bezier:
                pdf.curveTo(ctrl1.x, ctrl1.y, ctrl2.x, ctrl2.y, end.x, end.y);
   
            } else {
                pdf.lineTo(end.x, end.y);
            }

            // Workaround to be able to leave the curve unclosed and change lineStyle
            // (see: http://code.google.com/p/alivepdf/issues/detail?id=81)
            // **************************************************
            pdf.moveTo(start.x, start.y);
            // **************************************************
            pdf.end();
        }
        
        private function drawEdgeArrow(pdf:PDF, shape:String, points:Array, diameter:Number=0):void {
            if (points != null && points.length > 0) {
                if (shape === ArrowShapes.CIRCLE) {
                    var center:Point = points[0];
                    pdf.drawCircle(center.x, center.y, diameter/2);
                    pdf.end();
                } else if (shape === ArrowShapes.ARROW) {
                    var p1:Point = points[0];
                    var c1:Point = points[1];
                    var p2:Point = points[2];
                    var p3:Point = points[3];
                    var c2:Point = points[4];
                    var ctrl1:Point = new Point(), ctrl2:Point = new Point();
                    pdf.moveTo(p1.x, p1.y);
                    Utils.quadraticToCubic(p1, c1, p2, ctrl1, ctrl2);
                    pdf.curveTo(ctrl1.x, ctrl1.y, ctrl2.x, ctrl2.y, p2.x, p2.y);
                    pdf.lineTo(p3.x, p3.y);
                    Utils.quadraticToCubic(p3, c2, p1, ctrl1, ctrl2);
                    pdf.curveTo(ctrl1.x, ctrl1.y, ctrl2.x, ctrl2.y, p1.x, p1.y);
                    pdf.moveTo(p1.x, p1.y);
                    pdf.end();
                } else {
                    // Draw a polygon:
                    var coordinates:Array = [];
                    for each (var p:Point in points) {
                        coordinates.push(p.x);
                        coordinates.push(p.y);
                    }
                    pdf.drawPolygone(coordinates);
                    pdf.moveTo(points[0].x, points[0].y);
                    pdf.end();
                }
            }
        }
        
        private function drawEdgeArrowJoint(pdf:PDF, points:Array, arrowShape:String):void {
            if (points != null && points.length > 0) {
                switch (arrowShape) {
                    case ArrowShapes.CIRCLE:
                        if (points.length > 4) {
                            pdf.moveTo(points[0].x, points[0].y);
                            pdf.lineTo(points[1].x, points[1].y);
                            pdf.lineTo(points[2].x, points[2].y);
                            pdf.lineTo(points[3].x, points[3].y);
                            
                            var ctrl1:Point = new Point();
                            var ctrl2:Point = new Point();
                            Utils.quadraticToCubic(points[0], points[4], points[3], ctrl1, ctrl2);
                            pdf.curveTo(ctrl2.x, ctrl2.y, ctrl1.x, ctrl1.y, points[0].x, points[0].y);
                            pdf.moveTo(points[0].x, points[0].y);
                            pdf.end();
                        }
                        break;
                    default:
                        var coordinates:Array = [];
                        for each (var p:Point in points) {
                            coordinates.push(p.x);
                            coordinates.push(p.y);
                        }
                        pdf.drawPolygone(coordinates);
                        pdf.moveTo(points[0].x, points[0].y);
                        pdf.end();
                        break;
                }
            }
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
    }
}