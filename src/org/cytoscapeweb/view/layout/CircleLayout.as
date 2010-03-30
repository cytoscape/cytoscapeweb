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
    import flare.util.Property;
    import flare.vis.data.Data;
    import flare.vis.data.DataList;
    import flare.vis.data.NodeSprite;
    import flare.vis.operator.layout.CircleLayout;
    
    import flash.geom.Point;
    import flash.geom.Rectangle;
    
    import org.cytoscapeweb.vis.data.DisconnectedTreeBuilder;
    import org.cytoscapeweb.vis.data.DisconnectedTree;
    
    /**
     * This is the same Flare layout, but modified to work with disconnected components and to
     * ignore filtered out elements.
     * @see flare.vis.operator.layout.CircleLayout
     */
    public class CircleLayout extends flare.vis.operator.layout.CircleLayout {   
     
        protected var _data:Data;
        protected var _tree:DisconnectedTree;
     
        /**
         * Creates a new CircleLayout.
         * @param radiusField optional data field to encode as radius length
         * @param angleField optional data field to encode as angle
         * @param treeLayout boolean flag indicating if any tree-structure in
         *  the data should be used to inform the layout
         * @param data the data to process. Can be a disconnected data. If null the Visualization's
         *  data will be used instead.
         */
        public function CircleLayout(radiusField:String=null, angleField:String=null,
                                     treeLayout:Boolean=false, data:Data=null) {
            super(radiusField, angleField, treeLayout, Data.NODES);
            _data = data;
        }
        
        /** @inheritDoc */
        public override function setup():void {
            if (visualization == null) return;
            if (_data == null) _data = visualization.data;
            
            if (treeLayout) {
                if (!layoutRoot is NodeSprite) layoutRoot = _data.nodes[0];
                
                var tb:DisconnectedTreeBuilder = new DisconnectedTreeBuilder();
                tb.calculate(_data, NodeSprite(layoutRoot));
                _tree = DisconnectedTree(tb.tree);
            }
            
            _rBinding.data = _tree ? _tree : _data;
            _aBinding.data = _tree ? _tree : _data;
        }
        
        /** @inheritDoc */
        protected override function layout():void {           
            var list:DataList = _data.nodes;
            var i:int = 0, N:int = list.length, dr:Number;
            var visitor:Function = null;
            
            // determine radius
            var b:Rectangle = layoutBounds;
            _outer = Math.min(b.width, b.height)/2 - padding;
            _inner = isNaN(_innerFrac) ? _inner : _outer * _innerFrac;
            
            // set the anchor point
            var anchor:Point = layoutAnchor;
            list.visit(function(n:NodeSprite):void { n.origin = anchor; });
            
            // compute angles
            if (_aBinding.property) {
                // if angle property, get scale binding and do layout
                _aBinding.updateBinding();
                _aField = Property.$(_aBinding.property);
                visitor = function(n:NodeSprite):void {
                    var f:Number = _aBinding.interpolate(_aField.getValue(n));
                    _t.$(n).angle = minAngle(n.angle, 
                                             startAngle - f*angleWidth);
                };
            } else if (treeLayout) {
                // if tree mode, use tree order
                setTreeAngles();
            } else {
                // if nothing use total sort order
                i = 0;
                visitor = function(n:NodeSprite):void {
                    _t.$(n).angle = minAngle(n.angle, startAngle - (i/N)*angleWidth);
                    i++;
                };
            }
            if (visitor != null) list.visit(visitor);
            
            // compute radii
            visitor = null;
            if (_rBinding.property) {
                // if radius property, get scale binding and do layout
                _rBinding.updateBinding();
                _rField = Property.$(_rBinding.property);
                dr = _outer - _inner;
                visitor = function(n:NodeSprite):void {
                    var f:Number = _rBinding.interpolate(_rField.getValue(n));
                    _t.$(n).radius = _inner + f * dr;
                };
            } else if (treeLayout) {
                // if tree-mode, use tree depth
                setTreeRadii();
            } else {
                // if nothing, use outer radius
                visitor = function(n:NodeSprite):void {
                    _t.$(n).radius = _outer;
                };
            }
            if (visitor != null) list.visit(visitor);
            if (treeLayout) {
                // Modified here to accept another root:
                if (layoutRoot == null) layoutRoot = _data.tree.root;
                _t.$(layoutRoot).radius = 0;
            }
            
            // finish up
            updateEdgePoints(_t);
        }
        
        protected function setTreeAngles():void {
            // first pass, determine the angular spacing
            var root:NodeSprite = NodeSprite(layoutRoot), p:NodeSprite = null;
            var leafCount:int = 0, parentCount:int = 0;
            
            root.visitTreeDepthFirst(function(n:NodeSprite):void {
                if (_tree.childDegree(n) == 0) {
                    if (p != _tree.parentNode(n)) {
                        p = _tree.parentNode(n);
                        ++parentCount;
                    }
                    ++leafCount;
                }
            });
            var inc:Number = (-angleWidth) / (leafCount + parentCount);
            var angle:Number = startAngle;
            
            // second pass, set the angles
            root.visitTreeDepthFirst(function(n:NodeSprite):void {
                var a:Number = 0, b:Number;
                if (_tree.childDegree(n) == 0) {
                    if (p != _tree.parentNode(n)) {
                        p = _tree.parentNode(n);
                        angle += inc;
                    }
                    a = angle;
                    angle += inc;
                } else if (n.parent != null) {
                    a = _t.$(_tree.firstChildNode(n)).angle;
                    b = _t.$(_tree.lastChildNode(n)).angle - a;
                    while (b >  Math.PI) b -= 2*Math.PI;
                    while (b < -Math.PI) b += 2*Math.PI;
                    a += b / 2;
                }
                _t.$(n).angle = minAngle(n.angle, a);
            });
        }
        
        protected function setTreeRadii():void {
            var n:NodeSprite;
            var depth:Number = 0, dr:Number = _outer - _inner;
            var nodes:DataList = _tree.nodes;
            
            for each (n in nodes) {
                if (_tree.childDegree(n) == 0) {
                    depth = Math.max(n.depth, depth);
                    _t.$(n).radius = _outer;
                }
            }
            for each (n in nodes) {
                if (_tree.childDegree(n) != 0) {
                    _t.$(n).radius = _inner + (n.depth/depth) * dr;
                }
            }
            
            n = NodeSprite(layoutRoot);
            if (!_t.immediate) {
                delete _t._(n).values.radius;
                delete _t._(n).values.angle;
            }
            _t.$(n).x = n.origin.x;
            _t.$(n).y = n.origin.y;
        }
        
    }
}