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
    import flare.vis.data.Data;
    import flare.vis.data.DataList;
    import flare.vis.data.DataSprite;
    import flare.vis.data.EdgeSprite;
    import flare.vis.data.NodeSprite;
    
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
    import org.cytoscapeweb.util.NodeShapes;
    import org.cytoscapeweb.util.Utils;
    import org.cytoscapeweb.util.VisualProperties;
    import org.cytoscapeweb.view.components.GraphView;
        
    /**
     * Class that generates a vectorial image PDF file from the network.
     */
    public class PDFConverter {
        
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
        
        public function PDFConverter(view:GraphView) {
            this._graphView = view;         
        }

        // ========[ PUBLIC METHODS ]===============================================================

        /**
         * @param graphData
         * @param scale The zooming scale applied to the graph.
         * @param showLabels Whether or not labels will be included. 
         * @param width The desired image width in pixels.
         * @param height The desired image height in pixels.
         */
        public function convertToPDF(graphData:Data,
                                     style:VisualStyleVO,
                                     config:ConfigVO,
                                     scale:Number=1, 
                                     width:Number=0, height:Number=0):ByteArray {
            _style = style;
            _scale = scale;
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
            
            // Draw:
            drawEdges(pdf, graphData.edges);
            if (config.edgeLabelsVisible) drawLabels(pdf, graphData.edges);
            drawNodes(pdf, graphData.nodes);
            if (config.nodeLabelsVisible) drawLabels(pdf, graphData.nodes);
    
            var bytes:ByteArray = pdf.save(Method.LOCAL);
    
            return bytes;
        }
        
        // ========[ PRIVATE METHODS ]==============================================================
        
        private function drawEdges(pdf:PDF, edges:DataList):void {
            var sortedEdges:Array = sortByZOrder(edges);
            
            for each (var e:EdgeSprite in sortedEdges) {
                if (!e.visible || e.lineAlpha === 0 || e.lineWidth === 0) continue;
                
                // Edge points:
                var start:Point, end:Point, curve:Point;
                if (e.props.$points != null) {
                    start = e.props.$points.start;
                    end = e.props.$points.end;
                    curve = e.props.$points.curve;
                }
                
                if (start != null && end != null) {
                    start = toImagePoint(start, e);
                    end = toImagePoint(end, e);
                    
                    if (curve != null) {
                        curve = toImagePoint(curve, e);
                    }
                    
                    // Arrows points:
                    var sArrowPoints:Array = toImagePointsArray(e.props.$points.sourceArrow, e);
                    var tArrowPoints:Array = toImagePointsArray(e.props.$points.targetArrow, e);
                    var sJointPoints:Array = toImagePointsArray(e.props.$points.sourceArrowJoint, e);
                    var tJointPoints:Array = toImagePointsArray(e.props.$points.targetArrowJoint, e);
                    
                    var saStyle:Object = ArrowShapes.getArrowStyle(e, e.props.sourceArrowShape, e.props.sourceArrowColor);
                    var taStyle:Object = ArrowShapes.getArrowStyle(e, e.props.targetArrowShape, e.props.targetArrowColor);
                    
                    var w:Number = e.lineWidth * _scale;
                    
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
                            pdf.lineStyle(gc, gw, 0, ga);
                            drawEdgeShaft(pdf, start, end, curve);
                            
                            // Arrow glow:
                            pdf.lineStyle(gc, GLOW_WIDTH*_scale, 0, ga);
                            pdf.beginFill(gc);
                            drawEdgeArrowJoint(pdf, sJointPoints, saStyle.shape);
                            drawEdgeArrowJoint(pdf, tJointPoints, taStyle.shape);
                            drawEdgeArrow(pdf, sArrowPoints, saStyle.height*_scale);
                            drawEdgeArrow(pdf, tArrowPoints, taStyle.height*_scale);
                            pdf.endFill();
                        }
                    }
                    
                    // Draw the edge's line:
                    // -----------------------------------------------------
                    var edgeColor:RGBColor = new RGBColor(e.lineColor);
                    pdf.lineStyle(edgeColor, w, 0, e.alpha, WindingRule.NON_ZERO, Blend.NORMAL, null, Caps.NONE, Joint.MITER);
                                  
                    drawEdgeShaft(pdf, start, end, curve);
                    
                    // Draw arrow joints:
                    // -----------------------------------------------------
                    pdf.lineStyle(edgeColor, 0, 0, e.alpha);
                    
                    pdf.beginFill(edgeColor);
                    drawEdgeArrowJoint(pdf, sJointPoints, saStyle.shape);
                    pdf.endFill();
                    pdf.beginFill(edgeColor);
                    drawEdgeArrowJoint(pdf, tJointPoints, taStyle.shape);
                    pdf.endFill();
                    
                    // Draw arrows:
                    // -----------------------------------------------------
                    var saColor:RGBColor = new RGBColor(saStyle.color);
                    pdf.lineStyle(saColor, 0, 0, e.alpha);
                    pdf.beginFill(saColor);
                    drawEdgeArrow(pdf, sArrowPoints, saStyle.height*_scale);
                    pdf.endFill();
                    
                    var taColor:RGBColor = new RGBColor(taStyle.color);
                    pdf.lineStyle(taColor, 0, 0, e.alpha);
                    pdf.beginFill(taColor);
                    drawEdgeArrow(pdf, tArrowPoints, taStyle.height*_scale);
                    pdf.endFill();
                }
            }
        }
        
        private function drawNodes(pdf:PDF, nodes:DataList):void {
            // First, sort nodes by their z-order,
            // so overlapping nodes will have the same position in the generated image:
            var sortedNodes:Array = sortByZOrder(nodes);
            
            for each (var n:NodeSprite in sortedNodes) {
                if (!n.visible || n.alpha === 0) continue;
                
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
                        drawNode(pdf, n.shape, np.x, np.y, nw, nh);
                    }
                }
                
                // Then draw the node:
                nw = (n.width - n.lineWidth) * _scale;
                nh = (n.height - n.lineWidth) * _scale;
                
                pdf.lineStyle(new RGBColor(n.lineColor), n.lineWidth*_scale, 0, n.alpha,
                              WindingRule.NON_ZERO, Blend.NORMAL, null, Caps.ROUND, Joint.ROUND);
                pdf.beginFill(new RGBColor(n.fillColor));
                drawNode(pdf, n.shape, np.x, np.y, nw, nh);
                pdf.endFill();
            }
        }
        
        private function drawLabels(pdf:PDF, data:DataList):void {
            for each (var d:DataSprite in data) {
                var lbl:TextSprite = d.props.label;
                
                if (lbl != null && lbl.visible && lbl.alpha > 0) {
                    var text:String = lbl.text;
                    var lblSize:int = Math.round(lbl.size*_scale);
                    
                    if (text == null || text === "" || lblSize < 1) continue;
                    var field:TextField = lbl.textField;

                    // ATTENTION!!!
                    // It seems that Flash does not convert points to pixels correctly. 
                    // See: - http://alarmingdevelopment.org/?p=66
                    //      - http://www.actionscript.org/forums/showthread.php3?p=821842
                    // Or maybe the fonts used by the AlivePDF library are different.
                    // So this is a workaround to allow the correct alignment of the labels
                    // in the generated PDF:
                    // I found out that Arial's height is usually 28% smaller than the font size.
                    // Another possible solution would be to embed fonts, but it did not work for me.
                    var textHeight:Number = lbl.size * 0.72;
                    var textWidth:Number = field.textWidth;

                    // Get the Global label point (relative to the stage):
                    var p:Point = toImagePoint(new Point(lbl.x, lbl.y), lbl);

                    var xOffset:Number = 0;
                    var yOffset:Number = 0;
                    var hAnchor:String = Anchors.CENTER;
                    var vAnchor:String = Anchors.MIDDLE;
                    
                    if (d is NodeSprite) {
                        xOffset = _style.getValue(VisualProperties.NODE_LABEL_XOFFSET, d.data) * _scale;
                        yOffset = _style.getValue(VisualProperties.NODE_LABEL_YOFFSET, d.data) * _scale;
                        hAnchor = _style.getValue(VisualProperties.NODE_LABEL_HANCHOR, d.data);
                        vAnchor = _style.getValue(VisualProperties.NODE_LABEL_VANCHOR, d.data);
                    }

                    var hpad:Number = 2;
                    switch (hAnchor) {
                        case Anchors.LEFT:   p.x += hpad * _scale; break;
                        case Anchors.CENTER: p.x -= (textWidth/2)*_scale; break;
                        case Anchors.RIGHT:  p.x -= (textWidth + hpad)*_scale; break;
                    }
                    // Vertical anchor:
                    // The label height is different from the real text height, because
                    // there is a margin between the text and the text field border:
                    switch (vAnchor) {
                        case Anchors.TOP:    p.y += (field.height - textHeight)/2 * _scale; break;
                        case Anchors.MIDDLE: p.y -= textHeight/2 * _scale; break;
                        case Anchors.BOTTOM: p.y -= d.height/2 * _scale; break;
                    }
                    
                    // Flare's label cordinates is relative to the label's upper-left corner (x,y)=(0,0),
                    // but AlivePDF uses the bottom-left corner instead (x,y)=(0,fonSize):
                    p.y += textHeight*_scale;
                    
                    // Finally, add the offsets:
                    p.x += xOffset;
                    p.y += yOffset;

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
                    pdf.addText(text, p.x, p.y);
                }
            }
        }
        
        private function drawNode(pdf:PDF, shape:String, x:Number, y:Number, w:Number, h:Number):void {
                var r:Rectangle = new Rectangle(x-w/2, y-h/2, w, h);
                
                switch (shape) {
                    case NodeShapes.ELLIPSE:
                        pdf.drawCircle(x, y, h/2);
                        break;
                    case NodeShapes.ROUND_RECTANGLE:
                        pdf.drawRoundRect(r, w/4);
                        break;
                    default:
                        var points:Array = NodeShapes.getDrawPoints(r, shape);
                        pdf.drawPolygone(points);
                }
        }
        
        private function drawEdgeShaft(pdf:PDF, start:Point, end:Point, curve:Point):void {
            // Draw the edge's line:
            pdf.moveTo(start.x, start.y);
            
            if (curve == null) {
                pdf.lineTo(end.x, end.y);
            } else {
                // Convert the quadratic to a cubic bezier:
                var ctrl1:Point = new Point();
                var ctrl2:Point = new Point();
                Utils.quadraticToCubic(start, curve, end, ctrl1, ctrl2);
                pdf.curveTo(ctrl1.x, ctrl1.y, ctrl2.x, ctrl2.y, end.x, end.y);
            }

            // Workaround to be able to leave the curve unclosed and change lineStyle
            // (see: http://code.google.com/p/alivepdf/issues/detail?id=81)
            // **************************************************
            pdf.moveTo(start.x, start.y);
            // **************************************************
            pdf.end();
        }
        
        private function drawEdgeArrow(pdf:PDF, points:Array, diameter:Number=0):void {
            if (points != null && points.length > 0) {
                if (diameter > 0 && points.length === 1) {
                    // Draw a circle:
                    var center:Point = points[0];
                    pdf.drawCircle(center.x, center.y, diameter/2);
                } else {
                    // Draw a polygon:
                    var coordinates:Array = [];
                    for each (var p:Point in points) {
                        coordinates.push(p.x);
                        coordinates.push(p.y);
                    }

                    pdf.drawPolygone(coordinates);
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
                        break;
                }
            }
        }
        
         private function sortByZOrder(list:DataList):Array {
        	var arr:Array = new Array();
        	
        	for each (var sp:DataSprite in list) arr.push(sp);
        	
            arr.sort(function(a:DataSprite, b:DataSprite):int {
                var z1:int = a.parent.getChildIndex(a);
                var z2:int = b.parent.getChildIndex(b);
                
                return z1 < z2 ? -1 : (z1 > z2 ? 1 : 0);
            });
            
            return arr;
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