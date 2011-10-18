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
    import flare.util.Arrays;
    import flare.vis.data.Data;
    import flare.vis.data.NodeSprite;
    import flare.vis.operator.layout.RadialTreeLayout;
    
    import flash.geom.Rectangle;
    
    import org.cytoscapeweb.util.GraphUtils;
    import org.cytoscapeweb.vis.data.DisconnectedTree;
    import org.cytoscapeweb.vis.data.DisconnectedTreeBuilder;
    
    /**
     * The same Flare layout, just modified to work with disconnected components and to
     * ignore filtered out elements.
     * @see flare.vis.operator.layout.RadialTreeLayout
     */
    public class RadialTreeLayout extends flare.vis.operator.layout.RadialTreeLayout {
    
        protected var _maxDepth:int = 0;
        protected var _theta1:Number = Math.PI/2;
        protected var _theta2:Number = Math.PI/2 - 2*Math.PI;
        protected var _setTheta:Boolean = false;
        protected var _prevRoot:NodeSprite = null;
        
        protected var _data:Data;
        protected var _tree:DisconnectedTree;
        
        /** @inheritDoc */
        public override function get startAngle():Number { return _theta1; }
        public override function set startAngle(a:Number):void {
            _theta2 += (a - _theta1);
            _theta1 = a;
            _setTheta = true;
        }
        
        /** @inheritDoc */
        public override function get angleWidth():Number { return _theta1 - _theta2; }
        public override function set angleWidth(w:Number):void {
            _theta2 = _theta1 - w;
            _setTheta = true;
        }

        // -- Methods ---------------------------------------------------------

        /**
         * Creates a new RadialTreeLayout.
         * @param radius the radius increment between depth levels
         * @param sortAngles flag indicating if nodes should be sorted by angle
         *  to maintain node ordering across spanning-tree configurations
         * @param autoScale flag indicating if the layout should automatically
         *  be scaled to fit within the layout bounds
         */     
        public function RadialTreeLayout(radius:Number=DEFAULT_RADIUS,
                                         sortAngles:Boolean=true, autoScale:Boolean=true,
                                         data:Data=null) {
            super(radius, sortAngles, autoScale);
            _data = data;
        }

        /** @inheritDoc */
        public override function setup():void {
            if (visualization == null) return;
            if (_data == null) _data = visualization.data;
            
            if (!layoutRoot is NodeSprite) layoutRoot = _data.nodes[0];
            
            var tb:DisconnectedTreeBuilder = new DisconnectedTreeBuilder();
            tb.calculate(_data, NodeSprite(layoutRoot));
            _tree = DisconnectedTree(tb.tree);
        }

        /** @inheritDoc */
        protected override function layout():void {
            var n:NodeSprite = layoutRoot as NodeSprite;
            if (n == null) { _t = null; return; }
            var np:Params = params(n);
            
            // calc relative widths and maximum tree depth
            // performs one pass over the tree
            _maxDepth = 0;
            calcAngularWidth(n, n.height);
            
            if (autoScale) setScale(layoutBounds);
            if (!_setTheta) calcAngularBounds(n);
            _anchor = layoutAnchor;
            
            // perform the layout
            if (_maxDepth > 0) {
                doLayout(n, radiusIncrement, _theta1, _theta2);
            } else if (n.childDegree > 0) {
                n.visitTreeDepthFirst(function(n:NodeSprite):void {
                    if (!GraphUtils.isFilteredOut(n)) {
                        n.origin = _anchor;
                        var o:Object = _t.$(n);
                        // collapse to inner radius
                        o.radius = o.h = o.v = radiusIncrement / 2;
//                        o.alpha = 0;
                        o.mouseEnabled = false;
//                        if (_tree.parentEdge(n) != null) _t.$(_tree.parentEdge(n)).alpha = false;
                    }
                });
            }
            
            // update properties of the root node
            np.angle = _theta2 - _theta1;
            n.origin = _anchor;
            update(n, 0, _theta1+np.angle/2, np.angle, true);
            if (!_t.immediate) {
                delete _t._(n).values.radius;
                delete _t._(n).values.angle;
            }
            _t.$(n).x = _anchor.x;
            _t.$(n).y = _anchor.y;
            
            updateEdgePoints(_t);
        }
        
        protected function setScale(bounds:Rectangle):void {
            var r:Number = Math.min(bounds.width, bounds.height)/2.0;
            if (_maxDepth > 0) radiusIncrement = r / _maxDepth;
        }
        
        /**
         * Calculates the angular bounds of the layout, attempting to
         * preserve the angular orientation of the display across transitions.
         */
        protected function calcAngularBounds(r:NodeSprite):void {
            if (_prevRoot == null || r == _prevRoot) {
                _prevRoot = r; return;
            }
            
            // try to find previous parent of root
            var p:NodeSprite = _prevRoot, pp:NodeSprite;
            while (true) {
                pp = _tree.parentNode(p);
                if (pp == r) {
                    break;
                } else if (pp == null) {
                    _prevRoot = r;
                    return;
                }
                p = pp;
            }
    
            // compute offset due to children's angular width
            var dt:Number = 0;
            
            for each (var n:NodeSprite in sortedChildren(r)) {
                if (n == p) break;
                dt += params(n).width;
            }
            
            var rw:Number = params(r).width;
            var pw:Number = params(p).width;
            dt = -2*Math.PI * (dt+pw/2)/rw;
    
            // set angular bounds
            _theta1 = dt + Math.atan2(p.y-r.y, p.x-r.x);
            _theta2 = _theta1 + 2*Math.PI;
            _prevRoot = r;     
        }
        
        /**
         * Computes relative measures of the angular widths of each
         * expanded subtree. Node diameters are taken into account
         * to improve space allocation for variable-sized nodes.
         * 
         * This method also updates the base angle value for nodes 
         * to ensure proper ordering of nodes.
         */
        protected function calcAngularWidth(n:NodeSprite, d:int):Number {
            if (d > _maxDepth) _maxDepth = d;       
            var aw:Number = 0, diameter:Number = 0, size:Number;
            
            if (useNodeSize && d > 0) {
                //diameter = 1;
                size = Math.max(n.width, n.height);
                diameter = n.expanded && _tree.childDegree(n) > 0 ? 0 : size;
            } else if (d > 0) {
                var w:Number = n.width, h:Number = n.height;
                diameter = Math.sqrt(w*w+h*h)/d;
                if (isNaN(diameter)) diameter = 0;
            }

            if (n.expanded && _tree.childDegree(n) > 0) {
                for (var c:NodeSprite = _tree.firstChildNode(n); c != null; c = _tree.nextNode(c)) {
                    aw += calcAngularWidth(c, d+1);
                }
                aw = Math.max(diameter, aw);
            } else {
                aw = diameter;
            }
            params(n).width = aw;
            return aw;
        }
        
        protected static function normalize(angle:Number):Number {
            while (angle > 2*Math.PI)
                angle -= 2*Math.PI;
            while (angle < 0)
                angle += 2*Math.PI;
            return angle;
        }

        protected function sortedChildren(n:NodeSprite):Array {
            var cc:int = _tree.childDegree(n);
            if (cc == 0) return Arrays.EMPTY;
            var angles:Array = new Array(cc);
            
            if (sortAngles) {
                // update base angle for node ordering          
                var base:Number = -_theta1;
                var p:NodeSprite = _tree.parentNode(n);
                if (p != null) base = normalize(Math.atan2(p.y-n.y, n.x-p.x));
                
                // collect the angles
                var c:NodeSprite = _tree.firstChildNode(n);
                for (var i:uint = 0; i < cc; ++i, c = _tree.nextNode(c)) {
                    angles[i] = normalize(-base + Math.atan2(c.y-n.y,n.x-c.x));
                }
                // get array of indices, sorted by angle
                angles = angles.sort(Array.NUMERIC | Array.RETURNINDEXEDARRAY);
                // switch in the actual nodes and return
                for (i=0; i<cc; ++i) {
                    angles[i] = _tree.childNode(n, angles[i]);
                }
            } else {
                for (i=0; i<cc; ++i) {
                    angles[i] = _tree.childNode(n, i);
                }
            }
            
            return angles;
        }
        
        /**
         * Compute the layout.
         * @param n the root of the current subtree under consideration
         * @param r the radius, current distance from the center
         * @param theta1 the start (in radians) of this subtree's angular region
         * @param theta2 the end (in radians) of this subtree's angular region
         */
        protected function doLayout(n:NodeSprite, r:Number, theta1:Number, theta2:Number):void {
            var dtheta:Number = theta2 - theta1;
            var dtheta2:Number = dtheta / 2.0;
            var width:Number = params(n).width;
            var cfrac:Number, nfrac:Number = 0;
            
            for each (var c:NodeSprite in sortedChildren(n)) {
                var cp:Params = params(c);
                cfrac = cp.width / width;
                if (c.expanded && _tree.childDegree(c) > 0) {
                    doLayout(c, r+radiusIncrement, theta1 + nfrac*dtheta,
                             theta1 + (nfrac+cfrac)*dtheta);
                } else if (_tree.childDegree(c) > 0) {
                    var cr:Number = r + radiusIncrement;
                    var ca:Number = theta1 + nfrac*dtheta + cfrac*dtheta2;
                    
                    c.visitTreeDepthFirst(function(n:NodeSprite):void {
                        n.origin = _anchor;
                        update(n, cr, minAngle(n.angle, ca), 0, false);
                    });
                }
                
                c.origin = _anchor;
                var a:Number = minAngle(c.angle, theta1 + nfrac*dtheta + cfrac*dtheta2);
                cp.angle = cfrac * dtheta;
                update(c, r, a, cp.angle, true);
                nfrac += cfrac;
            }
        }
        
        protected function update(n:NodeSprite, r:Number, a:Number, aw:Number, v:Boolean):void {
            var o:Object = _t.$(n);//, alpha:Number = v ? 1 : 0;
            o.radius = r;
            o.angle = a;
            if (aw == 0) {
                o.h = o.v = r - radiusIncrement/2;
            } else {
                o.h = r + radiusIncrement/2;
                o.v = r - radiusIncrement/2;
            }
            o.w = aw;
            o.u = a - aw/2;
//            o.alpha = alpha;
            o.mouseEnabled = v;
//            if (_tree.parentEdge(n) != null) _t.$(_tree.parentEdge(n)).alpha = alpha;
        }
                
        protected function params(n:NodeSprite):Params {
            var p:Params = n.props[PARAMS];
            if (p == null) {
                p = new Params();
                n.props[PARAMS] = p;
            }
            return p;
        }
        
    }
}

class Params {
    public var width:Number = 0;
    public var angle:Number = 0;
}
