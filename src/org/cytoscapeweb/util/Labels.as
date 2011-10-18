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
    import flare.display.TextSprite;
    import flare.vis.data.DataSprite;
    import flare.vis.data.EdgeSprite;
    import flare.vis.data.NodeSprite;
    
    import flash.filters.GlowFilter;
    
    import mx.utils.StringUtil;
    
    import org.cytoscapeweb.ApplicationFacade;
    import org.cytoscapeweb.model.ConfigProxy;
    import org.cytoscapeweb.model.data.VisualStyleVO;
    import org.cytoscapeweb.vis.data.CompoundNodeSprite;
    
    
    public class Labels {
        
        // ========[ CONSTANTS ]====================================================================
        
        // ========[ PRIVATE PROPERTIES ]===========================================================

        private static var _configProxy:ConfigProxy;

        private static function get configProxy():ConfigProxy {
            if (_configProxy == null)
                _configProxy = ApplicationFacade.getInstance().retrieveProxy(ConfigProxy.NAME) as ConfigProxy;
            return _configProxy;
        }
        
        private static function get style():VisualStyleVO {
            return configProxy.visualStyle;
        }
        
        // ========[ CONSTRUCTOR ]==================================================================
        
        /**
         * This constructor will throw an error, as this is an abstract class. 
         */
        public function Labels() {
            throw new Error("This is an abstract class.");
        }
        
        // ========[ PUBLIC PROPERTIES ]============================================================

        
        // ========[ PUBLIC METHODS ]===============================================================
        
        public static function text(d:DataSprite):String {            
            return style.getValue(_$(VisualProperties.NODE_LABEL, d), d.data);
        }
        
        public static function labelFontSize(d:DataSprite):int {
            var size:Number = style.getValue(_$(VisualProperties.NODE_LABEL_FONT_SIZE, d), d.data);
            return Math.round(size);
        }
        
        public static function labelFontColor(d:DataSprite):uint {
            return style.getValue(_$(VisualProperties.NODE_LABEL_FONT_COLOR, d), d.data);
        }
        
        public static function labelFontName(d:DataSprite):String {
            return style.getValue(_$(VisualProperties.NODE_LABEL_FONT_NAME, d), d.data);
        }
        
        public static function labelFontWeight(d:DataSprite):String {
            var s:String = style.getValue(_$(VisualProperties.NODE_LABEL_FONT_WEIGHT, d), d.data);
            if (s != null) s = StringUtil.trim(s).toLowerCase();
            
            return s;
        }
        
        public static function labelFontStyle(d:DataSprite):String {
            var s:String = style.getValue(_$(VisualProperties.NODE_LABEL_FONT_STYLE, d), d.data);
            if (s != null) s = StringUtil.trim(s).toLowerCase();
            
            return s;
        }
        
        public static function labelHAnchor(d:DataSprite):int {
            if (d is NodeSprite && d.props.autoSize) {
                if (! (d is CompoundNodeSprite && (d as CompoundNodeSprite).nodesCount > 0))
                    return TextSprite.CENTER;
            }
            return Anchors.toFlareAnchor(style.getValue(_$(VisualProperties.NODE_LABEL_HANCHOR, d), d.data));
        }
        
        public static function labelVAnchor(d:DataSprite):int {
           if (d is NodeSprite && d.props.autoSize) {
                if (! (d is CompoundNodeSprite && (d as CompoundNodeSprite).nodesCount > 0))
                    return TextSprite.MIDDLE;
            }
            return Anchors.toFlareAnchor(style.getValue(_$(VisualProperties.NODE_LABEL_VANCHOR, d), d.data));
        }
        
        public static function labelXOffset(d:DataSprite):Number {
            return style.getValue(_$(VisualProperties.NODE_LABEL_XOFFSET, d), d.data);
        }
        
        public static function labelYOffset(d:DataSprite):Number {
            return style.getValue(_$(VisualProperties.NODE_LABEL_YOFFSET, d), d.data);
        }
        
        public static function filters(d:DataSprite):Array {
            var data:Object = d.data;
            var glowColor:uint = style.getValue(_$(VisualProperties.NODE_LABEL_GLOW_COLOR, d), data);
            var glowAlpha:Number = style.getValue(_$(VisualProperties.NODE_LABEL_GLOW_ALPHA, d), data);
            var glowBlur:Number = style.getValue(_$(VisualProperties.NODE_LABEL_GLOW_BLUR, d), data);
            var glowStrength:Number = style.getValue(_$(VisualProperties.NODE_LABEL_GLOW_STRENGTH, d), data);
            
            return [new GlowFilter(glowColor, glowAlpha, glowBlur, glowBlur, glowStrength)];
        }
        
        // ========[ PRIVATE METHODS ]==============================================================
        
        /**
         * @param propName A node property name.
         * @param d A node or edge sprite.
         * @return The analogue edge property name if the DataSprite is an edge or a compound node
         */
        private static function _$(propName:String, d:DataSprite):String {
            if (propName != null && d is EdgeSprite) {
                propName = propName.replace("node", "edge");
            } else if (propName != null && d is CompoundNodeSprite) {
                if ((d as CompoundNodeSprite).isInitialized()) {
                    var idx:int = propName.indexOf(".");
                    
                    // convert from node.property to node.compoundProperty
                    
                    propName = propName.substring(0,idx+1) + "compound" +
                        propName.charAt(idx+1).toUpperCase() +
                        propName.substring(idx+2);
                }
            }
            
            return propName;
        }
        
    }
}