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
    import flare.animate.Transitioner;
    import flare.display.TextSprite;
    import flare.util.Filter;
    import flare.util.Geometry;
    import flare.util.Shapes;
    import flare.vis.data.Data;
    import flare.vis.data.DataList;
    import flare.vis.data.DataSprite;
    import flare.vis.data.EdgeSprite;
    import flare.vis.operator.label.Labeler;
    
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.geom.Point;
    import flash.text.TextFormat;
    import flash.text.TextFormatAlign;
    
    import org.cytoscapeweb.util.Groups;
    import org.cytoscapeweb.util.NodeShapes;
    import org.cytoscapeweb.util.Utils;
    import org.cytoscapeweb.util.methods.$each;
    import org.cytoscapeweb.vis.data.CompoundNodeSprite;
    
    
    public class Labeler extends flare.vis.operator.label.Labeler {

        // ========[ CONSTANTS ]====================================================================
        
        // ========[ PRIVATE PROPERTIES ]===========================================================
        
        // ========[ PUBLIC PROPERTIES ]============================================================

        public var filters:Function;
        public var fontName:Function;
        public var fontColor:Function;
        public var fontSize:Function;
        public var fontWeight:Function;
        public var fontStyle:Function;
        public var hAnchor:Function;
        public var vAnchor:Function;
        public var xOffsetFunc:Function;
        public var yOffsetFunc:Function;

        // ========[ CONSTRUCTOR ]==================================================================

        public function Labeler(source:*=null, group:String=Data.NODES, 
                                format:TextFormat=null, filter:*=null) {
            var policy:String;
            
            if ((group === Data.NODES) || (group === Groups.COMPOUND_NODES)) {
                policy = LAYER;
            } else {
                policy = CHILD;
            }
            
            super(source, group, format, filter, policy);
            //super(source, group, format, filter, group === Data.NODES ? LAYER : CHILD);
        }
        
        // ========[ PROTECTED METHODS ]============================================================
        
        /** @inheritDoc */
        public override function setup():void {
            _labels = visualization.labels;
            if (_labels == null) {
                _labels = new Sprite();
                _labels.mouseChildren = false;
                _labels.mouseEnabled = false;
                _labels.useHandCursor = false;
                _labels.buttonMode = false;
                visualization.labels = _labels;
            }
            
            // IMPORTANT: When dragging nodes, the labeler might need to be updated:
            if (_policy === CHILD) {
                var elements:DataList;
                
                if (group === Data.NODES) {
                    elements = visualization.data.nodes;
                } else if (group === Groups.COMPOUND_NODES) {
                    elements = visualization.data.group(Groups.COMPOUND_NODES);
                } else {
                    elements = visualization.data.edges;
                }
                    
                $each(elements, function(i:uint, d:DataSprite):void {
                    d.addEventListener(Event.RENDER, onRender);
                });
            }
        }
        
        public override function operate(t:Transitioner=null):void {
            if (visualization != null) {
                _t = (t ? t : Transitioner.DEFAULT);
                
                var f:Function = Filter.$(filter);
                var list:DataList;

                if (group === Data.NODES) {
                    list = visualization.data.nodes;
                } else if (group === Groups.COMPOUND_NODES) {
                    list = visualization.data.group(Groups.COMPOUND_NODES);
                } else {
                    list = visualization.data.edges;
                }
                
                if (list != null) {
                    $each(list, function(i:uint, d:DataSprite):void {
                        if (f == null || f(d)) process(d);
                    });
                }
            }
        }
        
        /** @inheritDoc */
        protected override function process(d:DataSprite):void {
            var label:TextSprite = getLabel(d, true);
            label.filters = filters(d);
            label.alpha = d.alpha;
            
            if (_policy == LAYER) {
                // TODO: create merged edge labels property?
                var v:Boolean = d.visible && !(d is EdgeSprite && d.props.$merged);
                label.visible = v;
            }

            updateLabelPosition(label, d);
        }

        /** @inheritDoc */
        protected override function getLabel(d:DataSprite, create:Boolean=false, visible:Boolean=true):TextSprite {
            var label:TextSprite = _access.getValue(d);
            
            if (!label && !create) {
                return null;
            } else if (!label) {
                label = new TextSprite("", null, textMode);
                label.text = getLabelText(d);
                label.visible = visible;

                updateLabel(d, label);
                _access.setValue(d, label);
                
                if (_policy == LAYER) {
                    _labels.addChild(label);
                    label.x = d.x;
                    label.y = d.y;
                } else {
                    d.addChild(label);
                    // TODO: how to avoid this label from being clicked???
                    label.mouseEnabled = false;
                    label.mouseChildren = false;
                    label.buttonMode = false;
                    label.textField.mouseEnabled = false;
                    label.x = xOffset;
                    label.y = yOffset;
                }
            } else if (label && !cacheText) {
                label.text = getLabelText(d);
                updateLabel(d, label);
            }
            
            return label;
        }

        protected function updateLabelPosition(label:TextSprite, d:DataSprite):void {
            if (label == null) return;
            
            var x:Number = d.x;
            var y:Number = d.y;
            
            // The offset should be based on each node's size (not just from the node's center):
            var myXOffset:Number = 0, myYOffset:Number = 0;
            if (xOffsetFunc != null) myXOffset = xOffsetFunc(d);
            if (yOffsetFunc != null) myYOffset = yOffsetFunc(d);

            if (d is EdgeSprite) {
                var e:EdgeSprite = EdgeSprite(d);
                var pp:Object = e.props.$points;

                if (e.shape === Shapes.LINE) {
                    x = (e.source.x + e.target.x) / 2;
                    y = (e.source.y + e.target.y) / 2;
                } else if (e.props.$points != null) {
                    var p1:Point = e.props.$points.start;
                    var p2:Point = e.props.$points.end;
                    var mp:Point = new Point(); // Middle point for curved edges.
                    
                    if (e.source === e.target) {
                        // Loop...
                        var cc1:Point = new Point();
                        var cc2:Point = new Point();
                        var cc3:Point = new Point();
                        Geometry.cubicCoeff(p1, e.props.$points.c1, e.props.$points.c2, p2, cc1, cc2, cc3);
                        mp = Geometry.cubic(0.5, p1, cc1, cc2, cc3, mp);
                        x = mp.x;
                        y = mp.y;
                    } else {
                        // Label for a curved edge?
                        mp = Utils.bezierPoint(p1, p2, e.props.$points.c1, 0.5);
                        x = mp.x;
                        y = mp.y;
                    }
                }
            } else {
                // The offset should be based on each node's size (not just from the node's center):
                if      (label.horizontalAnchor === TextSprite.LEFT)  myXOffset += d.width/2;
                else if (label.horizontalAnchor === TextSprite.RIGHT) myXOffset -= d.width/2;
                if      (label.verticalAnchor === TextSprite.TOP)     myYOffset += d.height/2;
                else if (label.verticalAnchor === TextSprite.BOTTOM)  myYOffset -= d.height/2;
                
                if (d.props.autoSize) {
                    if (! (d is CompoundNodeSprite && (d as CompoundNodeSprite).nodesCount > 0)) {
                        d.render();
                        if (d.shape == NodeShapes.TRIANGLE) myYOffset += d.height/4;
                    }
                }
            }
            
            label.x = x + myXOffset;
            label.y = y + myYOffset;
            
            label.render();
        }

        protected function updateLabel(d:DataSprite, label:TextSprite):void {
            label.textMode = textMode;
            label.horizontalAnchor = horizontalAnchor;
            label.verticalAnchor = verticalAnchor;           

            if (hAnchor != null) label.horizontalAnchor = hAnchor(d);
            if (vAnchor != null) label.verticalAnchor = vAnchor(d);

            if (fontName != null) textFormat.font = fontName(d);
            if (fontColor != null) textFormat.color = fontColor(d);
            if (fontSize != null) textFormat.size = fontSize(d);
            if (fontWeight != null) textFormat.bold = (fontWeight(d) === "bold");
            if (fontStyle != null) textFormat.italic = (fontStyle(d) === "italic");
            
            if (label.horizontalAnchor === TextSprite.CENTER)
                textFormat.align = TextFormatAlign.CENTER;
            if (label.horizontalAnchor === TextSprite.RIGHT)
                textFormat.align = TextFormatAlign.RIGHT;
            if (label.horizontalAnchor === TextSprite.LEFT)
                textFormat.align = TextFormatAlign.LEFT;
                
            label.applyFormat(textFormat);
        }
        
        // ========[ PRIVATE METHODS ]==============================================================
        
        private function onRender(evt:Event):void {
            if (!visualization.continuousUpdates) {
                var d:DataSprite = evt.target as DataSprite;
                updateLabelPosition(d.props.label, d);
            }
        }
        
    }
}
