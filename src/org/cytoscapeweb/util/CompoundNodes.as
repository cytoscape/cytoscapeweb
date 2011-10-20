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
package org.cytoscapeweb.util {
    
    import flare.util.IEvaluable;
    import flare.vis.data.NodeSprite;
    
    import flash.filters.GlowFilter;
    
    import org.cytoscapeweb.ApplicationFacade;
    import org.cytoscapeweb.model.ConfigProxy;
    import org.cytoscapeweb.model.GraphProxy;
    import org.cytoscapeweb.model.data.VisualStyleBypassVO;
    import org.cytoscapeweb.model.data.VisualStyleVO;
    import org.cytoscapeweb.view.render.CompoundNodeRenderer;
    import org.cytoscapeweb.vis.data.CompoundNodeSprite;

    public class CompoundNodes {
        
        public static const ALL:String = "all";
        public static const SELECTED:String = "selected";
        public static const NON_SELECTED:String = "non-selected";
        
        private static var _properties:Object;
        private static var _configProxy:ConfigProxy;
        private static var _graphProxy:GraphProxy;
        
        private static function get configProxy():ConfigProxy {
            if (_configProxy == null) {
                _configProxy = ApplicationFacade.getInstance().
                    retrieveProxy(ConfigProxy.NAME) as ConfigProxy;
            }
            
            return _configProxy;
        }
        
        private static function get graphProxy():GraphProxy {
            if (_graphProxy == null) {
                _graphProxy = ApplicationFacade.getInstance().
                    retrieveProxy(GraphProxy.NAME) as GraphProxy;
            }
            
            return _graphProxy;
        }
        
        private static function get style():VisualStyleVO {
            return configProxy.visualStyle;
        }
        
        private static function get bypass():VisualStyleBypassVO {
            return configProxy.visualStyleBypass;
        }
        
        public function CompoundNodes() {
            throw new Error("This is an abstract class.");
        }
        
        /**
         * This method returns visual style properties which are specific to 
         * compound nodes.
         */
        public static function get properties():Object {
            if (CompoundNodes._properties == null) {
                CompoundNodes._properties = {
                        shape: CompoundNodes.shape,
                        //"props.compoundWidth": Nodes.width,
                        //"props.compoundHeight": Nodes.height,
                        //"props.compoundAutoSize": Nodes.autoSize,
                        size: CompoundNodes.size,
                        paddingLeft: CompoundNodes.paddingLeft,
                        paddingRight: CompoundNodes.paddingRight,
                        paddingTop: CompoundNodes.paddingTop,
                        paddingBottom: CompoundNodes.paddingBottom,
                        fillColor: CompoundNodes.fillColor,
                        lineColor: CompoundNodes.lineColor, 
                        lineWidth: CompoundNodes.lineWidth,
                        alpha: CompoundNodes.alpha,
                        "props.transparent": CompoundNodes.transparent,
                        "props.imageUrl": CompoundNodes.imageUrl,
                        visible: Nodes.visible,
                        buttonMode: true,
                        filters: CompoundNodes.filters,
                        renderer: CompoundNodeRenderer.instance
                };
            }
            
            return _properties;
        }
        
        public static function shape(n:NodeSprite):String {
            var shape:String = CompoundNodes.style.getValue(VisualProperties.C_NODE_SHAPE, n.data);
            shape = NodeShapes.parse(shape);
            
            switch (shape) {
                case NodeShapes.ROUND_RECTANGLE:
                case NodeShapes.RECTANGLE:
                case NodeShapes.ELLIPSE:
                    // these are the only supported compound node shapes!
                    break;
                default:
                    shape = NodeShapes.RECTANGLE;
            }
            
            return shape;
        }
        
        public static function size(n:NodeSprite):Number {
            // set size as double size of a simple node
            var size:Number = style.getValue(
                VisualProperties.NODE_SIZE, n.data) * 2;
            
            return size / _properties.renderer.defaultSize;
        }
        
        public static function fillColor(n:NodeSprite):uint {
            var propName:String = VisualProperties.C_NODE_COLOR;
            
            if (n.props.$selected && 
                style.hasVisualProperty(VisualProperties.C_NODE_SELECTION_COLOR)) {
                propName = VisualProperties.C_NODE_SELECTION_COLOR;
            }
            
            return style.getValue(propName, n.data);
        }
        
        public static function lineColor(n:NodeSprite):uint {
            var propName:String = VisualProperties.C_NODE_LINE_COLOR;
            
            if (n.props.$hover &&
                style.hasVisualProperty(VisualProperties.C_NODE_HOVER_LINE_COLOR)) {
                propName = VisualProperties.C_NODE_HOVER_LINE_COLOR;
            } else if (n.props.$selected &&
                       style.hasVisualProperty( VisualProperties.C_NODE_SELECTION_LINE_COLOR)) {
                propName = VisualProperties.C_NODE_SELECTION_LINE_COLOR;
            }
            
            return style.getValue(propName, n.data);
        }
        
        public static function lineWidth(n:NodeSprite):Number {
            var propName:String = VisualProperties.C_NODE_LINE_WIDTH;
            
            if (n.props.$hover &&
                style.hasVisualProperty( VisualProperties.C_NODE_HOVER_LINE_WIDTH)) {
                propName = VisualProperties.C_NODE_HOVER_LINE_WIDTH;
            } else if (n.props.$selected &&
                       style.hasVisualProperty( VisualProperties.C_NODE_SELECTION_LINE_WIDTH)) {
                propName = VisualProperties.C_NODE_SELECTION_LINE_WIDTH;
            }
            
            return style.getValue(propName, n.data);
        }
        
        public static function selectionLineWidth(n:NodeSprite):Number {
            var propName:String = VisualProperties.C_NODE_LINE_WIDTH;
            
            if (style.hasVisualProperty(VisualProperties.C_NODE_SELECTION_LINE_WIDTH)) {
                propName = VisualProperties.C_NODE_SELECTION_LINE_WIDTH;
            } else if (n.props.$hover &&
                       style.hasVisualProperty(VisualProperties.C_NODE_HOVER_LINE_WIDTH)) {
                propName = VisualProperties.C_NODE_HOVER_LINE_WIDTH;
            }
            
            return style.getValue(propName, n.data);
        }
        
        public static function alpha(n:NodeSprite):Number {
            var propName:String = VisualProperties.C_NODE_ALPHA;
            
            if (n.props.$hover &&
                style.hasVisualProperty(VisualProperties.C_NODE_HOVER_ALPHA)) {
                propName = VisualProperties.C_NODE_HOVER_ALPHA;
            } else if (n.props.$selected &&
                style.hasVisualProperty(VisualProperties.C_NODE_SELECTION_ALPHA)) {
                propName = VisualProperties.C_NODE_SELECTION_ALPHA;
            }
            
            return style.getValue(propName, n.data);
        }
        
        public static function transparent(n:NodeSprite):Boolean {
            var propName:String = VisualProperties.C_NODE_COLOR;
            
            if (n.props.$selected &&
                style.hasVisualProperty(VisualProperties.C_NODE_SELECTION_COLOR)) {
                propName = VisualProperties.C_NODE_SELECTION_COLOR;
            }
            
            return style.getValue(propName, n.data) < 0;
        }
        
        public static function selectionAlpha(n:NodeSprite):Number {
            var propName:String = VisualProperties.C_NODE_ALPHA;
            
            if (style.hasVisualProperty(VisualProperties.C_NODE_SELECTION_ALPHA)) {
                propName = VisualProperties.C_NODE_SELECTION_ALPHA;
            }
            
            return style.getValue(propName, n.data);
        }
        
        public static function filters(n:NodeSprite, selectNow:Boolean=false):Array {
            var filters:Array = [];
            var glow:GlowFilter = null;
            
            if (!selectNow && n.props.$hover) {
                glow = hoverGlow(n);
            }
            if (glow == null && n.props.$selected) {
                glow = selectionGlow(n);
            }
            if (glow != null) {
                filters.push(glow);
            }
            
            return filters;
        }
        
        public static function selectionGlow(n:NodeSprite):GlowFilter {
            var filter:GlowFilter = null;
            var data:Object = n.data;
            var alpha:Number = style.getValue(VisualProperties.C_NODE_SELECTION_GLOW_ALPHA, data);            
            var blur:Number = style.getValue(VisualProperties.C_NODE_SELECTION_GLOW_BLUR, data);
            var strength:Number = style.getValue(VisualProperties.C_NODE_SELECTION_GLOW_STRENGTH, data);
            
            if (alpha > 0 && blur > 0 && strength > 0) {
                var color:uint = style.getValue(VisualProperties.C_NODE_SELECTION_GLOW_COLOR, data);           
                filter = new GlowFilter(color, alpha, blur, blur, strength);
            }
            
            return filter;
        }
        
        public static function hoverGlow(n:NodeSprite):GlowFilter {
            var filter:GlowFilter = null;
            var data:Object = n.data;
            var alpha:Number = style.getValue(VisualProperties.C_NODE_HOVER_GLOW_ALPHA, data);
            var blur:Number = style.getValue(VisualProperties.C_NODE_HOVER_GLOW_BLUR, data);
            var strength:Number = style.getValue(VisualProperties.C_NODE_HOVER_GLOW_STRENGTH, data);
            
            if (alpha > 0 && blur > 0 && strength > 0) {
                var color:uint = style.getValue(VisualProperties.C_NODE_HOVER_GLOW_COLOR, data);
                filter = new GlowFilter(color, alpha, blur, blur, strength);
            }
            
            return filter;
        }
        
        public static function imageUrl(n:NodeSprite):String {
            var propName:String = VisualProperties.C_NODE_IMAGE;
            // TODO: selected/mouseover images
            return style.getValue(propName, n.data);
        }
        
        public static function paddingLeft(n:NodeSprite):Number {
            var margin:Number = style.getValue(VisualProperties.C_NODE_PADDING_LEFT, n.data);
            return margin;
        }
        
        public static function paddingRight(n:NodeSprite):Number {
            var margin:Number = style.getValue(VisualProperties.C_NODE_PADDING_RIGHT, n.data);
            return margin;
        }
        
        public static function paddingTop(n:NodeSprite):Number {
            var margin:Number = style.getValue(VisualProperties.C_NODE_PADDING_TOP, n.data);
            return margin;
        }
        
        public static function paddingBottom(n:NodeSprite):Number {
            var margin:Number = style.getValue(VisualProperties.C_NODE_PADDING_BOTTOM, n.data);
            return margin;
        }
        
        /**
         * Recursively populates an array of NodeSprite instances with the
         * children of selected type for the given CompoundNodeSprite. All
         * children are collected by default, type can be selected and
         * non-selected children.
         * 
         * @param cns   compound node sprite whose children are collected 
         */
        public static function getChildren(cns:CompoundNodeSprite,
                                           type:String=CompoundNodes.ALL):Array {
            var children:Array = new Array();
            var condition:Boolean;
            
            if (cns != null) {
                for each (var ns:NodeSprite in cns.getNodes()) {
                    if (type === CompoundNodes.SELECTED) {
                        condition = ns.props.$selected;
                    } else if (type === CompoundNodes.NON_SELECTED) {
                        condition = !ns.props.$selected;
                    } else {
                        // default case is all children (always true)
                        condition = true;
                    }
                    
                    // process the node if the condition meets
                    if (condition) {
                        // add current node to the list
                        children.push(ns);
                    }
                    
                    if (ns is CompoundNodeSprite) {
                        // recursively collect child nodes
                        children = children.concat(getChildren(ns as CompoundNodeSprite, type));
                    }
                }
            }
            
            return children;
        }
        
        /**
         * Populates an array of CompoundNodeSprite instances with the parents
         * of selected type for the given CompoundNodeSprite. All parents
         * up to root are collected by default, type can be selected and
         * non-selected parents.
         * 
         * @param ns    node sprite whose parents are collected 
         */
        public static function getParents(ns:CompoundNodeSprite,
                                          type:String = CompoundNodes.ALL):Array {
            var parents:Array = new Array();
            var condition:Boolean;
            var parent:NodeSprite;
            var parentId:String;
            
            if (ns != null) {
                parentId = ns.data.parent;
                
                while (parentId != null) {
                    // get parent
                    parent = graphProxy.getNode(parentId);
                    
                    if (parent == null) {
                        break;
                    }
                    
                    if (type === CompoundNodes.SELECTED) {
                        condition = parent.props.$selected;
                    } else if (type === CompoundNodes.NON_SELECTED) {
                        condition = !parent.props.$selected;
                    } else {
                        // default case is all parents (always true)
                        condition = true;
                    }
                    
                    // process the node if the condition meets
                    if (condition) {
                        // add current node to the list
                        parents.push(parent);
                    }
                    
                    // advance to next node (avoid circular dependencies)
                    if (parent.data.parent !== ns.data.id) {
                        parentId = parent.data.parent;
                    } else {
                        parentId = null;
                    }
                }
            }
            
            return parents;
        }
    }
}