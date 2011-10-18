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
    import flare.util.Orientation;
    import flare.vis.data.Data;
    import flare.vis.data.DataList;
    import flare.vis.data.NodeSprite;
    import flare.vis.operator.layout.NodeLinkTreeLayout;
    
    import flash.geom.Point;
    import flash.geom.Rectangle;
    
    import org.cytoscapeweb.vis.data.DisconnectedTree;
    import org.cytoscapeweb.vis.data.DisconnectedTreeBuilder;
    
    /**
     * This is the same Flare layout, but modified to handle filtered out elements.
     * @see flare.vis.operator.layout.NodeLinkTreeLayout
     */
    public class NodeLinkTreeLayout extends flare.vis.operator.layout.NodeLinkTreeLayout {
        
        // -- Properties ------------------------------------------------------
        
        /** Property name for storing parameters for this layout. */
        public static const PARAMS:String = "nodeLinkTreeLayoutParams";
        
        protected var _depths:Array = new Array(20); // stores depth co-ords
        protected var _maxDepth:int = 0;
        protected var _ax:Number, _ay:Number; // for holding anchor co-ordinates
        
        protected var _data:Data;
        protected var _tree:DisconnectedTree;
        
        // -- Methods ---------------------------------------------------------
    
        /**
         * Creates a new NodeLinkTreeLayout.
         * @param orientation the orientation of the layout
         * @param depthSpace the space between depth levels in the tree
         * @param breadthSpace the space between siblings in the tree
         * @param subtreeSpace the space between different sub-trees
         */     
        public function NodeLinkTreeLayout(orientation:String=Orientation.LEFT_TO_RIGHT,
                                           depthSpace:Number=50,
                                           breadthSpace:Number=5,
                                           subtreeSpace:Number=25,
                                           data:Data=null) {
            super(orientation, depthSpace, breadthSpace, subtreeSpace);
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
            Arrays.fill(_depths, 0);
            _maxDepth = 0;
            
            var root:NodeSprite = layoutRoot as NodeSprite;
            if (root == null) { _t = null; return; }
            var rp:Params = params(root);

            firstWalk(root, 0, 1);                       // breadth/depth stats
            var a:Point = layoutAnchor;
            _ax = a.x; _ay = a.y;                        // determine anchor
            determineDepths();                           // sum depth info
            secondWalk(root, null, -rp.prelim, 0, true); // assign positions
            updateEdgePoints(_t);                        // update edges
        }

        protected override function autoAnchor():void {
            // otherwise generate anchor based on the bounds
            var b:Rectangle = layoutBounds;
            var r:NodeSprite = layoutRoot as NodeSprite;
            switch (orientation) {
                case Orientation.LEFT_TO_RIGHT:
                    _ax = b.x + depthSpacing + r.w;
                    _ay = b.y + b.height / 2;
                    break;
                case Orientation.RIGHT_TO_LEFT:
                    _ax = b.width - (depthSpacing + r.w);
                    _ay = b.y + b.height / 2;
                    break;
                case Orientation.TOP_TO_BOTTOM:
                    _ax = b.x + b.width / 2;
                    _ay = b.y + depthSpacing + r.h;
                    break;
                case Orientation.BOTTOM_TO_TOP:
                    _ax = b.x + b.width / 2;
                    _ay = b.height - (depthSpacing + r.h);
                    break;
                default:
                    throw new Error("Unrecognized orientation value");
            }
            _anchor.x = _ax;
            _anchor.y = _ay;
        }

        protected function firstWalk(n:NodeSprite, num:int, depth:uint):void {
            setSizes(n);
            updateDepths(depth, n);
            var np:Params = params(n);
            np.number = num;
            
            var expanded:Boolean = n.expanded;
            if (_tree.childDegree(n) == 0 || !expanded) // is leaf
            {
                var l:NodeSprite = _tree.prevNode(n);
                np.prelim = l==null ? 0 : params(l).prelim + spacing(l,n,true);
            }
            else if (expanded) // has children, is expanded
            {
                var midpoint:Number, i:uint;
                var lefty:NodeSprite = _tree.firstChildNode(n);
                var right:NodeSprite = _tree.lastChildNode(n);
                var ancestor:NodeSprite = lefty;
                var c:NodeSprite = lefty;
                
                for (i=0; c != null; ++i, c = _tree.nextNode(c)) {
                    firstWalk(c, i, depth+1);
                    ancestor = apportion(c, ancestor);
                }
                executeShifts(n);
                midpoint = 0.5 * (params(lefty).prelim + params(right).prelim);
                
                l = _tree.prevNode(n);
                if (l != null) {
                    np.prelim = params(l).prelim + spacing(l,n,true);
                    np.mod = np.prelim - midpoint;
                } else {
                    np.prelim = midpoint;
                }
            }
        }
    
        protected function apportion(v:NodeSprite, a:NodeSprite):NodeSprite {
            var w:NodeSprite = _tree.prevNode(v);
            if (w != null) {
                var vip:NodeSprite, vim:NodeSprite, vop:NodeSprite, vom:NodeSprite;
                var sip:Number, sim:Number, sop:Number, som:Number;
                
                vip = vop = v;
                vim = w;
                vom = _tree.firstChildNode(_tree.parentNode(vip));
                
                sip = params(vip).mod;
                sop = params(vop).mod;
                sim = params(vim).mod;
                som = params(vom).mod;
                
                var shift:Number;
                var nr:NodeSprite = nextRight(vim);
                var nl:NodeSprite = nextLeft(vip);
                while (nr != null && nl != null) {
                    vim = nr;
                    vip = nl;
                    vom = nextLeft(vom);
                    vop = nextRight(vop);
                    params(vop).ancestor = v;
                    shift = (params(vim).prelim + sim) - 
                        (params(vip).prelim + sip) + spacing(vim,vip,false);
                    
                    if (shift > 0) {
                        moveSubtree(ancestor(vim,v,a), v, shift);
                        sip += shift;
                        sop += shift;
                    }
                    
                    sim += params(vim).mod;
                    sip += params(vip).mod;
                    som += params(vom).mod;
                    sop += params(vop).mod;
                
                    nr = nextRight(vim);
                    nl = nextLeft(vip);
                }
                if (nr != null && nextRight(vop) == null) {
                    var vopp:Params = params(vop);
                    vopp.thread = nr;
                    vopp.mod += sim - sop;
                }
                if (nl != null && nextLeft(vom) == null) {
                    var vomp:Params = params(vom);
                    vomp.thread = nl;
                    vomp.mod += sip - som;
                    a = v;
                }
            }
            return a;
        }
    
        private function nextLeft(n:NodeSprite):NodeSprite {
            var c:NodeSprite = null;
            if (n.expanded) c = _tree.firstChildNode(n);
            return (c != null ? c : params(n).thread);
        }

        private function nextRight(n:NodeSprite):NodeSprite {
            var c:NodeSprite = null;
            if (n.expanded) c = _tree.lastChildNode(n);
            return (c != null ? c : params(n).thread);
        }

        private function moveSubtree(wm:NodeSprite, wp:NodeSprite, shift:Number):void {
            var wmp:Params = params(wm);
            var wpp:Params = params(wp);
            var subtrees:Number = wpp.number - wmp.number;
            wpp.change -= shift/subtrees;
            wpp.shift += shift;
            wmp.change += shift/subtrees;
            wpp.prelim += shift;
            wpp.mod += shift;
        }   

        private function executeShifts(n:NodeSprite):void {
            var shift:Number = 0, change:Number = 0;
            for (var c:NodeSprite = _tree.lastChildNode(n); c != null; c = _tree.prevNode(c)) {
                var cp:Params = params(c);
                cp.prelim += shift;
                cp.mod += shift;
                change += cp.change;
                shift += cp.shift + change;
            }
        }
        
        private function ancestor(vim:NodeSprite, v:NodeSprite, a:NodeSprite):NodeSprite {
            var vimp:Params = params(vim);
            var p:NodeSprite = _tree.parentNode(v);
            return (_tree.parentNode(vimp.ancestor) == p ? vimp.ancestor : a);
        }
    
        private function secondWalk(n:NodeSprite, p:NodeSprite, m:Number, depth:uint, visible:Boolean):void {
            // set position
            var np:Params = params(n);
            var o:Object = _t.$(n);
            setBreadth(o, p, (visible ? np.prelim : 0) + m);
            setDepth(o, p, _depths[depth]);
            setVisibility(n, o, visible);
            
            // recurse
            var v:Boolean = n.expanded ? visible : false;
            var b:Number = m + (n.expanded ? np.mod : np.prelim)
            if (v) depth += 1;
            for (var c:NodeSprite = _tree.firstChildNode(n); c != null; c = _tree.nextNode(c)) {
                secondWalk(c, n, b, depth, v);
            }
            np.clear();
        }

        private function setBreadth(n:Object, p:NodeSprite, b:Number):void {
            switch (orientation) {
                case Orientation.LEFT_TO_RIGHT:
                case Orientation.RIGHT_TO_LEFT:
                    n.y = _ay + b;
                    break;
                case Orientation.TOP_TO_BOTTOM:
                case Orientation.BOTTOM_TO_TOP:
                    n.x = _ax + b;
                    break;
                default:
                    throw new Error("Unrecognized orientation value");
            }
        }

        private function setDepth(n:Object, p:NodeSprite, d:Number):void {
            switch (orientation) {
                case Orientation.LEFT_TO_RIGHT:
                    n.x = _ax + d;
                    break;
                case Orientation.RIGHT_TO_LEFT:
                    n.x = _ax - d;
                    break;
                case Orientation.TOP_TO_BOTTOM:
                    n.y = _ay + d;
                    break;
                case Orientation.BOTTOM_TO_TOP:
                    n.y = _ax - d;
                    break;
                default:
                    throw new Error("Unrecognized orientation value");
            }
        }
        
        private function setVisibility(n:NodeSprite, o:Object, visible:Boolean):void {
//            o.alpha = visible ? 1.0 : 0.0;
            o.mouseEnabled = visible;
            if (_tree.parentEdge(n) != null) {
                o = _t.$(_tree.parentEdge(n));
//                o.alpha = visible ? 1.0 : 0.0;
                o.mouseEnabled = visible;
            }

        }
        
        private function setSizes(n:NodeSprite):void {
            if (n != null) {
                _t.endSize(n, _rect);
                n.w = _rect.width;
                n.h = _rect.height;
            }
        }
        
        private function spacing(l:NodeSprite, r:NodeSprite, siblings:Boolean):Number {
            var w:Boolean = Orientation.isVertical(orientation);
            return (siblings ? breadthSpacing : subtreeSpacing) + 0.5 *
                    (w ? l.w + r.w : l.h + r.h)
        }
    
        private function updateDepths(depth:uint, item:NodeSprite):void {
            var v:Boolean = Orientation.isVertical(orientation);
            var d:Number = v ? item.h : item.w;

            // resize if needed
            if (depth >= _depths.length) {
                _depths = Arrays.copy(_depths, new Array(int(1.5*depth)));
                for (var i:int=depth; i<_depths.length; ++i) _depths[i] = 0;
            } 

            _depths[depth] = Math.max(_depths[depth], d);
            _maxDepth = Math.max(_maxDepth, depth);
        }
    
        private function determineDepths():void {
            for (var i:uint=1; i<_maxDepth; ++i)
                _depths[i] += _depths[i-1] + depthSpacing;
        }
        
        // -- Parameter Access ------------------------------------------------
        
        private function params(n:NodeSprite):Params {
            var p:Params = n.props[PARAMS] as Params;
            if (p == null) {
                p = new Params();
                n.props[PARAMS] = p;
            }
            if (p.number == -2) { p.init(n); }
            return p;
        }
        
    }
}


import flare.vis.data.NodeSprite;

class Params {
    public var prelim:Number = 0;
    public var mod:Number = 0;
    public var shift:Number = 0;
    public var change:Number = 0;
    public var number:int = -2;
    public var ancestor:NodeSprite = null;
    public var thread:NodeSprite = null;
    
    public function init(item:NodeSprite):void
    {
        ancestor = item;
        number = -1;
    }

    public function clear():void
    {
        number = -2;
        prelim = mod = shift = change = 0;
        ancestor = thread = null;
    }
}
