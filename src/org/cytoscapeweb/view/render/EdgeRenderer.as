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
	import flare.util.Geometry;
	import flare.util.Shapes;
	import flare.vis.data.DataSprite;
	import flare.vis.data.EdgeSprite;
	import flare.vis.data.NodeSprite;
	import flare.vis.data.render.EdgeRenderer;
	
	import flash.display.Graphics;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import org.cytoscapeweb.util.ArrowShapes;
	import org.cytoscapeweb.util.NodeShapes;
	import org.cytoscapeweb.util.Utils;
	
	public class EdgeRenderer extends flare.vis.data.render.EdgeRenderer {

        // ========[ CONSTANTS ]====================================================================

        // ========[ PRIVATE PROPERTIES ]===========================================================

		private static var _instance:org.cytoscapeweb.view.render.EdgeRenderer = new org.cytoscapeweb.view.render.EdgeRenderer();
        /** Static AppEdgeRenderer instance. */
        public static function get instance():org.cytoscapeweb.view.render.EdgeRenderer { return _instance; }
        
        // ========[ PUBLIC METHODS ]===============================================================

        /** @inheritDoc */
        public override function render(d:DataSprite):void {
            var e:EdgeSprite = d as EdgeSprite;
            if (e == null || e.source == null || e.target == null) { return; }
            var g:Graphics = e.graphics;
            // ----------------------------------------------------
            // No need to continue if the edge is totally transparent:
            if (e.lineWidth == 0 || e.lineAlpha == 0) {
                g.clear();
                return;
            }
            // ----------------------------------------------------
            var s:NodeSprite = e.source;
            var t:NodeSprite = e.target;

            // This version of Renderer ignores the control points!
            // var ctrls:Array = e.points as Array;
            
            var x1:Number = e.x1, y1:Number = e.y1;
            var x2:Number = e.x2, y2:Number = e.y2;
            // Edge intersection points (with target and souce nodes):
            var _intT:Point = new Point(), _intS:Point = new Point();
            _intS.x = x1; _intS.y = y1;
            _intT.x = x2; _intT.y = y2;
            
            var op1:Point, op2:Point;
            // ----------------------------------------------------
			if (e.shape == Shapes.BEZIER) {
			    var h:Number = e.props.curvature;
			    op2 = op1 = Utils.orthogonalPoint(h, new Point(x1, y1), new Point(x2, y2));
			} else {
			    op1 = new Point(x1, y1);
			    op2 = new Point(x2, y2);
			}
            // ----------------------------------------------------

            var sourceShape:String = e.props.sourceArrowShape;
            var targetShape:String = e.props.targetArrowShape;

            // Get arrow styles:
            var sourceArrowStyle:Object, targetArrowStyle:Object;
            
            if (targetShape != ArrowShapes.NONE)
            	targetArrowStyle = ArrowShapes.getArrowStyle(e, targetShape, e.props.targetArrowColor);
            if (sourceShape != ArrowShapes.NONE)
                sourceArrowStyle = ArrowShapes.getArrowStyle(e, sourceShape, e.props.sourceArrowColor);

            // draw the edge
            g.clear(); // clear it out

            // get arrow tip point as intersection of edge with bounding box
            intersectNode(s, op2, new Point(x1, y1), _intS);
            intersectNode(t, op1, new Point(x2, y2), _intT);

            var curve:Point = (e.shape == Shapes.BEZIER ? op1 : null);
            
            // Using a bit mask to avoid transparent edges when fillcolor=0xffffffff.
            // See https://sourceforge.net/forum/message.php?msg_id=7393265
            var color:uint =  0xffffff & e.lineColor;
            
            var points:Object = draw(g, _intS, _intT, curve,
                                     { lineWidth: e.lineWidth, color: color, alpha: e.lineAlpha },
                                     sourceArrowStyle, targetArrowStyle);
                 
            // Store the draw points for future use (e.g. PDF generation):
            e.props.$points = points;
        }
        
        // ========[ PRIVATE METHODS ]==============================================================

        private  function draw(g:Graphics, start:Point, end:Point, curve:Point,
                               edgeStyle:Object, sourceArrowStyle:Object,
                               targetArrowStyle:Object):Object {            
            if (start.equals(end)) return points;
            
            // Start/end points of the line (without arrows):
            var sShaft:Point = start.clone(), eShaft:Point = end.clone();

            // Total length of the edge:
            var vector:Number = Point.distance(start, end);
            // Vector from curve (control point) to start/end:
            var slopeVector:Number;
            // Arrow height:
            var ah:Number;
            // Shaft width:
            var w:Number = edgeStyle.lineWidth;
            
            if (sourceArrowStyle != null) {
                ah = sourceArrowStyle.height + sourceArrowStyle.gap;
                // The arrow should follow the curve slope:
                if (curve != null) {
                    slopeVector = Point.distance(curve, start);
                    sShaft = Point.interpolate(curve, start, ah/slopeVector);
                } else {
                    sShaft = Point.interpolate(end, start, ah/vector);
                }
            }
            if (targetArrowStyle != null) {
                ah = targetArrowStyle.height + targetArrowStyle.gap;
                // The arrow should follow the curve slope:
                if (curve != null) {
                    slopeVector = Point.distance(curve, end);
                    eShaft = Point.interpolate(curve, end, ah/slopeVector);
                } else {
                    eShaft = Point.interpolate(start, end, ah/vector);
                }
            }

            var ds:Point = curve == null ? end.subtract(start) : curve.subtract(start);
            var de:Point = curve == null ? start.subtract(end) : curve.subtract(end);
            var ns:Point = new Point(ds.y, -ds.x);
            ns.normalize(w/2);
            var ne:Point = new Point(-de.y, de.x);
            ne.normalize(w/2);
            
            var sShaft1:Point = sShaft.add(ns);
            var sShaft2:Point = sShaft.subtract(ns);
            var eShaft1:Point = eShaft.add(ne);
            var eShaft2:Point = eShaft.subtract(ne);
            
            // Curve's external and internal points:
            var c1:Point, c2:Point;
            
            if (curve != null) {
                var d:Point = end.subtract(start);
                var n:Point = new Point(d.y, -d.x);
                n.normalize(w/2);
                c1 = curve.add(n);
                c2 = curve.subtract(n);
            }

            // Draw the shaft:
            // ---------------------------
            g.beginFill(edgeStyle.color, edgeStyle.alpha);
            g.moveTo(sShaft1.x, sShaft1.y);
            
            if (curve != null) {
                g.curveTo(c1.x, c1.y, eShaft1.x, eShaft1.y);
                g.lineTo(eShaft2.x, eShaft2.y);
                g.curveTo(c2.x, c2.y, sShaft2.x, sShaft2.y);
                g.lineTo(sShaft1.x, sShaft1.y);
            } else {
                g.lineTo(eShaft1.x, eShaft1.y);
                g.lineTo(eShaft2.x, eShaft2.y);
                g.lineTo(sShaft2.x, sShaft2.y);
                g.lineTo(sShaft1.x, sShaft1.y);
            }

            g.endFill();

            // Draw the source arrow:
            // ---------------------------
            var saPoints:Object;
            if (sourceArrowStyle != null)
                saPoints = drawArrow(g, sShaft, start, sShaft2, sShaft1, edgeStyle, sourceArrowStyle);
            
            // Draw the target arrow:
            // ---------------------------
            var taPoints:Object;
            if (targetArrowStyle != null)
                taPoints = drawArrow(g, eShaft, end, eShaft1, eShaft2, edgeStyle, targetArrowStyle);
            
            // Store the draw points for future use:
            // ------------------------------------------
            var points:Object = new Object();
            points.start = sShaft.clone();
            points.end = eShaft.clone();
            points.curve = curve != null ? curve.clone() : null;
            points.sourceArrow = saPoints != null ? saPoints.arrow : null;
            points.targetArrow = taPoints != null ? taPoints.arrow : null;
            points.sourceArrowJoint = saPoints != null ? saPoints.joint : null;
            points.targetArrowJoint = taPoints != null ? taPoints.joint : null;
            
            return points;
        }
        
        private function drawArrow(g:Graphics, start:Point, end:Point, eb1:Point, eb2:Point,
                                   edgeStyle:Object, arrowStyle:Object):Object {
            // Returned reference points:
            var points:Object = new Object();

            var aw:Number = arrowStyle.width/2;
            var ah:Number = arrowStyle.height;
            var shape:String = arrowStyle.shape;
            
            end = Point.interpolate(start, end, arrowStyle.gap / Point.distance(start, end));
            
            // Find perpendicular vector points for the arrow base:
            var n1:Point = new Point(start.x-end.x, start.y-end.y);
            var n2:Point = n1.clone();
            n1.normalize(1);
            n2.normalize(-1);
            var b1:Point = new Point(n1.y, -n1.x);
            var b2:Point = new Point(n2.y, -n2.x);
            b1 = new Point(start.x + b1.x * aw, start.y + b1.y * aw);
            b2 = new Point(start.x + b2.x * aw, start.y + b2.y * aw);

            g.lineStyle(0, 0x000000, 0);
            g.beginFill(arrowStyle.color, arrowStyle.alpha);
            
            switch (shape) {
                case ArrowShapes.T:
                    // Find the other points of the rectangle:
                    var d:Point = b2.subtract(b1);
                    var n:Point = new Point(-d.y, d.x);
                    n.normalize(ah);
                    var b3:Point = b2.add(n);
                    var b4:Point = b1.add(n);
                    g.moveTo(b1.x, b1.y);
                    g.lineTo(b2.x, b2.y);
                    g.lineTo(b3.x, b3.y);
                    g.lineTo(b4.x, b4.y);
                    g.lineTo(b1.x, b1.y);
                    g.endFill();
                    // Future reference points:
                    points.arrow = [b1.clone(), b2.clone(), b3.clone(), b4.clone()];
                    break;
                case ArrowShapes.CIRCLE:
                    var center:Point = Point.interpolate(start, end, 0.5);
                    g.drawCircle(center.x, center.y, ah/2);
                    g.endFill();
                    // Draw the junction between the arrow and the edge line:
                    points.joint = drawCircleArrowJoint(g, start, end, eb1, eb2, center, edgeStyle, arrowStyle);
                    // Future reference points:
                    points.arrow = [center.clone()];
                    break;
                case ArrowShapes.DIAMOND:
                    b1 = Point.interpolate(b1, end, 0.5);
                    b2 = Point.interpolate(b2, end, 0.5);
                    g.moveTo(start.x, start.y);
                    g.lineTo(b1.x, b1.y);
                    g.lineTo(end.x, end.y);
                    g.lineTo(b2.x, b2.y);
                    g.lineTo(start.x, start.y);
                    g.endFill();
                    // Future reference points:
                    points.arrow = [start.clone(), b1.clone(), end.clone(), b2.clone()];
                    // Draw the junction between the arrow and the edge line:
                    points.joint = drawDiamondArrowJoint(g, start, end, b1, b2, eb1, eb2, edgeStyle);
                    break;
                case ArrowShapes.DELTA:
                default:
                    g.moveTo(end.x, end.y);
                    g.lineTo(b1.x, b1.y);
                    g.lineTo(b2.x, b2.y);
                    g.lineTo(end.x, end.y);
                    g.endFill();
                    // Future reference points:
                    points.arrow = [end.clone(), b1.clone(), b2.clone()];
                    break;
            }

            return points;
        }

        private function drawCircleArrowJoint(g:Graphics, start:Point, end:Point,
                                              b1:Point, b2:Point, center:Point,
                                              edgeStyle:Object, arrowStyle:Object):Array {
            // Shaft width:
            var w:Number = edgeStyle.lineWidth;
            var ww:Number = w/2;
            // Circle radius:
            var r:Number = arrowStyle.height/2;
            // Find distance between the center of the circle and the imaginary line done by
            // the intersection points between the arrow joint and the circle (Pitagoras):
            var h:Number = Math.sqrt(r*r - ww*ww);
            // Another point distanced 2*h from the center:
            var p:Point = Point.interpolate(start, center, 2*h/r);

            // Get the points where the shaft should hit the base of the diamond shape:
            var int1:Point = Utils.orthogonalPoint(ww, center, p);
            var int2:Point = Utils.orthogonalPoint(-ww, center, p);
            // Bezier control point:
            var ctrl:Point = Utils.orthogonalPoint((r-h)*2, int1, int2);

            g.lineStyle(0, 0x000000, 0);
            g.beginFill(edgeStyle.color, edgeStyle.alpha);
            g.moveTo(int1.x, int1.y);
            g.lineTo(b1.x, b1.y);
            g.lineTo(b2.x, b2.y);
            g.lineTo(int2.x, int2.y);
            g.curveTo(ctrl.x, ctrl.y, int1.x, int1.y);
            g.endFill();
            
            return [int1.clone(), b1.clone(), b2.clone(), int2.clone(), ctrl.clone()];
        }
        
        private function drawDiamondArrowJoint(g:Graphics, start:Point, end:Point,
                                               b1:Point, b2:Point, e1:Point, e2:Point,
                                               edgeStyle:Object):Array {
            // Shaft width:
            var w:Number = edgeStyle.lineWidth/2;
            // Get the points where the shaft should hit the base of the diamond shape:
            var ee1:Point = Utils.orthogonalPoint(w, start, end);
            var ee2:Point = Utils.orthogonalPoint(-w, start, end);

            g.lineStyle(0, 0x000000, 0);
            g.beginFill(edgeStyle.color, edgeStyle.alpha);
            g.moveTo(start.x, start.y);

            var int1:Point = new Point(), int2:Point = new Point();
            
            if (Geometry.intersectLines(e1.x, e1.y, ee1.x, ee1.y, start.x, start.y, b1.x, b1.y, int1) > 0)
                g.lineTo(int1.x, int1.y);
            else if (Geometry.intersectLines(e1.x, e1.y, ee2.x, ee2.y, start.x, start.y, b2.x, b2.y, int1) > 0)
                g.lineTo(int1.x, int1.y);
            g.lineTo(e1.x, e1.y);
            g.lineTo(e2.x, e2.y);
  
            if (Geometry.intersectLines(e2.x, e2.y, ee2.x, ee2.y, start.x, start.y, b2.x, b2.y, int2) > 0)
                g.lineTo(int2.x, int2.y);
            else if (Geometry.intersectLines(e2.x, e2.y, ee1.x, ee1.y, start.x, start.y, b1.x, b1.y, int2) > 0)
                g.lineTo(int2.x, int2.y);

            g.lineTo(start.x, start.y);
            g.endFill();
            
            return [start.clone(), int1.clone(), e1.clone(), e2.clone(), int2.clone()];
        }

        private function intersectNode(n:NodeSprite, start:Point, end:Point, int:Point):void {
        	var r:Rectangle = n.getBounds(n.parent);
        	
        	switch (n.shape) {
                case NodeShapes.ELLIPSE:
                    intersectCircle(n.height/2, start, end, int);
                    break;
                case NodeShapes.ROUND_RECTANGLE:
                    intersectRoundRectangle(r, start, end, int);
                    break;
                default:
                    var points:Array = NodeShapes.getDrawPoints(r, n.shape);
                    intersectLines(points, start, end, int);
        	}
        }
        
        private function intersectCircle(radius:Number, start:Point, end:Point, ip:Point):void {
            var obj:Object = Utils.lineIntersectCircle(start, end, end, radius);
            if (obj.enter != null) {
                ip.x = obj.enter.x;
                ip.y = obj.enter.y;
            }
        }
        
        private function intersectRoundRectangle(r:Rectangle, start:Point, end:Point, ip:Point):void {
            var points:Array = NodeShapes.getDrawPoints(r, NodeShapes.ROUND_RECTANGLE);
            var res:int = Geometry.NO_INTERSECTION;
            var length:int = points.length;
            
            for (var i:int = 0; i < length; i += 4) {
                if (i+3 >= length) break;
                var x1:Number = points[i], y1:Number = points[i+1];
                var x2:Number = points[i+2], y2:Number = points[i+3];

                res = Geometry.intersectLines(x1, y1, x2, y2, start.x, start.y, end.x, end.y, ip);
                if (res > 0) break;
            }
            if (res <= 0) {
                // Verify if the edge intersects one of the rounded courners,
                // which are described by four circles.
                var radius:Number = r.width/4;
                // Calculate the center of the circles:
                var xR:Number = r.right, yB:Number = r.bottom;
                var xL:Number = r.left,  yT:Number = r.top;
                points = [ new Point(xL+radius, yT+radius),
                           new Point(xR-radius, yT+radius),
                           new Point(xR-radius, yB-radius),
                           new Point(xL+radius, yB-radius) ];
                
                for each (var c:Point in points) {
                    var obj:Object = Utils.lineIntersectCircle(start, end, c, radius);
                    if (obj.enter != null) {
                        ip.x = obj.enter.x;
                        ip.y = obj.enter.y;
                        break;
                    }
                }
            }
        }
        
        private function intersectLines(points:Array, start:Point, end:Point, ip:Point):int {
            var res:int = Geometry.NO_INTERSECTION;
            var length:int = points.length;
            
            for (var i:int = 0; i < length; i += 2) {
                if (i >= length) break;
                var x1:Number = points[i], y1:Number = points[i+1];
                var x2:Number, y2:Number;
                
                if (i+3 < length) {
                    x2 = points[i+2]; y2 = points[i+3];
                } else {
                    x2 = points[0]; y2 = points[1];
                }

                res = Geometry.intersectLines(x1, y1, x2, y2, start.x, start.y, end.x, end.y, ip);
                if (res > 0) break;
            }
            
            return res;
        }
    }
}