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
	
	
    /**
     * Abstract utility class defining names of visual attributes.
     */
    public class VisualProperties {
    	
        // ========[ CONSTANTS ]====================================================================
    	
    	// Global properties:
    	//------------------------------
    	public static const BACKGROUND_COLOR:String = "global.backgroundColor";
    	public static const TOOLTIP_DELAY:String = "global.tooltipDelay";
    	
    	// Selection Rectangle:
    	public static const SELECTION_LINE_COLOR:String = "global.selectionLineColor";
    	public static const SELECTION_LINE_ALPHA:String = "global.selectionLineOpacity";
    	public static const SELECTION_LINE_WIDTH:String = "global.selectionLineWidth";
    	public static const SELECTION_FILL_COLOR:String = "global.selectionFillColor";
    	public static const SELECTION_FILL_ALPHA:String = "global.selectionFillOpacity";

        // Nodes properties:
        //------------------------------
        public static const NODE_SHAPE:String = "nodes.shape";
        public static const NODE_SIZE:String = "nodes.size";
        public static const NODE_COLOR:String = "nodes.color";
        public static const NODE_ALPHA:String = "nodes.opacity";
        public static const NODE_LINE_COLOR:String = "nodes.borderColor";
        public static const NODE_LINE_WIDTH:String = "nodes.borderWidth";

        public static const NODE_TOOLTIP_TEXT:String = "nodes.tooltipText";
        public static const NODE_TOOLTIP_FONT:String = "nodes.tooltipFont";
        public static const NODE_TOOLTIP_FONT_SIZE:String = "nodes.tooltipFontSize";
        public static const NODE_TOOLTIP_COLOR:String = "nodes.tooltipFontColor";
        public static const NODE_TOOLTIP_BACKGROUND_COLOR:String = "nodes.tooltipBackgroundColor";
        public static const NODE_TOOLTIP_BORDER_COLOR:String = "nodes.tooltipBorderColor";

        public static const NODE_LABEL:String = "nodes.label";
        public static const NODE_LABEL_FONT_NAME:String = "nodes.labelFontName";
        public static const NODE_LABEL_FONT_SIZE:String = "nodes.labelFontSize";
        public static const NODE_LABEL_FONT_COLOR:String = "nodes.labelFontColor";
        public static const NODE_LABEL_FONT_WEIGHT:String = "nodes.labelFontWeight";
        public static const NODE_LABEL_FONT_STYLE:String = "nodes.labelFontStyle";
        public static const NODE_LABEL_HANCHOR:String = "nodes.labelHorizontalAnchor";
        public static const NODE_LABEL_VANCHOR:String = "nodes.labelVerticalAnchor";
        public static const NODE_LABEL_XOFFSET:String = "nodes.labelXOffset";
        public static const NODE_LABEL_YOFFSET:String = "nodes.labelYOffset";
        
        public static const NODE_LABEL_GLOW_COLOR:String = "nodes.labelGlowColor";
        public static const NODE_LABEL_GLOW_ALPHA:String = "nodes.labelGlowOpacity";
        public static const NODE_LABEL_GLOW_BLUR:String = "nodes.labelGlowBlur";
        public static const NODE_LABEL_GLOW_STRENGTH:String = "nodes.labelGlowStrength";
        
        public static const NODE_SELECTION_COLOR:String = "nodes.selectionColor";
        public static const NODE_SELECTION_ALPHA:String = "nodes.selectionOpacity";
        public static const NODE_SELECTION_LINE_COLOR:String = "nodes.selectionBorderColor";
        public static const NODE_SELECTION_LINE_WIDTH:String = "nodes.selectionBorderWidth";
        public static const NODE_SELECTION_GLOW_COLOR:String = "nodes.selectionGlowColor";
        public static const NODE_SELECTION_GLOW_ALPHA:String = "nodes.selectionGlowOpacity";
        public static const NODE_SELECTION_GLOW_BLUR:String = "nodes.selectionGlowBlur";
        public static const NODE_SELECTION_GLOW_STRENGTH:String = "nodes.selectionGlowStrength";

        public static const NODE_HOVER_ALPHA:String = "nodes.hoverOpacity";
        public static const NODE_HOVER_LINE_COLOR:String = "nodes.hoverBorderColor";
        public static const NODE_HOVER_LINE_WIDTH:String = "nodes.hoverBorderWidth";
        public static const NODE_HOVER_GLOW_COLOR:String = "nodes.hoverGlowColor";
        public static const NODE_HOVER_GLOW_ALPHA:String = "nodes.hoverGlowOpacity";
        public static const NODE_HOVER_GLOW_BLUR:String = "nodes.hoverGlowBlur";
        public static const NODE_HOVER_GLOW_STRENGTH:String = "nodes.hoverGlowStrength";
        
        // Edge's properties:
        //------------------------------
        public static const EDGE_COLOR:String = "edges.color";
        public static const EDGE_WIDTH:String = "edges.width";
        public static const EDGE_ALPHA:String = "edges.opacity";
        
        public static const EDGE_COLOR_MERGE:String = "edges.mergeColor";
        public static const EDGE_WIDTH_MERGE:String = "edges.mergeWidth";
        public static const EDGE_ALPHA_MERGE:String = "edges.mergeOpacity";

        public static const EDGE_SOURCE_ARROW_SHAPE:String = "edges.sourceArrowShape";
        public static const EDGE_SOURCE_ARROW_COLOR:String = "edges.sourceArrowColor";
        public static const EDGE_TARGET_ARROW_SHAPE:String = "edges.targetArrowShape";
        public static const EDGE_TARGET_ARROW_COLOR:String = "edges.targetArrowColor";
        
        public static const EDGE_TOOLTIP_TEXT:String = "edges.tooltipText";
        public static const EDGE_TOOLTIP_FONT:String = "edges.tooltipFont";
        public static const EDGE_TOOLTIP_FONT_SIZE:String = "edges.tooltipFontSize";
        public static const EDGE_TOOLTIP_COLOR:String = "edges.tooltipFontColor";
        public static const EDGE_TOOLTIP_BACKGROUND_COLOR:String = "edges.tooltipBackgroundColor";
        public static const EDGE_TOOLTIP_BORDER_COLOR:String = "edges.tooltipBorderColor";
        
        // TODO rename and create colors, etc:
        public static const EDGE_TOOLTIP_TEXT_MERGE:String = "edges.mergeTooltipText";
        
        public static const EDGE_LABEL:String = "edges.label";
        public static const EDGE_LABEL_FONT_NAME:String = "edges.labelFontName";
        public static const EDGE_LABEL_FONT_SIZE:String = "edges.labelFontSize";
        public static const EDGE_LABEL_FONT_COLOR:String = "edges.labelFontColor";
        public static const EDGE_LABEL_FONT_WEIGHT:String = "edges.labelFontWeight";
        public static const EDGE_LABEL_FONT_STYLE:String = "edges.labelFontStyle";

        public static const EDGE_LABEL_GLOW_COLOR:String = "edges.labelGlowColor";
        public static const EDGE_LABEL_GLOW_ALPHA:String = "edges.labelGlowOpacity";
        public static const EDGE_LABEL_GLOW_BLUR:String = "edges.labelGlowBlur";
        public static const EDGE_LABEL_GLOW_STRENGTH:String = "edges.labelGlowStrength";
        
        public static const EDGE_SELECTION_COLOR:String = "edges.selectionColor";
        public static const EDGE_SELECTION_ALPHA:String = "edges.selectionOpacity";
        public static const EDGE_SELECTION_GLOW_COLOR:String = "edges.selectionGlowColor";
        public static const EDGE_SELECTION_GLOW_ALPHA:String = "edges.selectionGlowOpacity";
        public static const EDGE_SELECTION_GLOW_BLUR:String = "edges.selectionGlowBlur";
        public static const EDGE_SELECTION_GLOW_STRENGTH:String = "edges.selectionGlowStrength";
        
        public static const EDGE_HOVER_ALPHA:String = "edges.hoverOpacity";
        
        public static const EDGE_CURVATURE:String = "edges.curvature"; 
        
        // ========[ CONSTRUCTOR ]==================================================================
        
        /**
         * This constructor will throw an error, as this is an abstract class. 
         */
        public function VisualProperties() {
            throw new Error("This is an abstract class.");
        }
        
        // ========[ PUBLIC METHODS ]===============================================================
        
        /**
         * @param name the name of the visual property.
         * @param value the visual property value to be converted.
         */
        public static function parseValue(name:String, value:*):* {
        	if (value === undefined) value = null;

            if (isColor(name)) {
            	var color:uint = Utils.rgbColorAsUint(value);
            	// Add alpha, which is required by for most of the colors:
            	if (name != BACKGROUND_COLOR) color += 0xff000000;
                value = color;
            } else if (isNumber(name)) {
            	value = Number(value);
            } else if (name == VisualProperties.NODE_SHAPE) {
                value = NodeShapes.parse(value);
            } else if (name == VisualProperties.EDGE_SOURCE_ARROW_SHAPE ||
                       name == VisualProperties.EDGE_TARGET_ARROW_SHAPE) {
                value = ArrowShapes.parse(value);
            } else if (isString(name)) {
                if (value == null) value = "";
            }
            
            return value;
        }
        
        /**
         * @param name the name of the visual property.
         * @param value the visual property value to be converted.
         */
        public static function toExportValue(name:String, value:*):* {
            if (value === undefined) value = null;
            
            if (isColor(name)) {
                value = Utils.rgbColorAsString(uint(value));
            } else if (isNumber(name)) {
                value = Number(value);
            } else if (isString(name)) {
                if (value == null) value = "";
                else value = value.toString();
            }
            
            return value;
        }
        
        public static function isColor(name:String):Boolean {
            return name.toLowerCase().indexOf("color") != -1;
        }
        
        public static function isNumber(name:String):Boolean {
            if (name != null) {
                var tokens:Array = ["width", "height", "size", "opacity", "offset", "curvature", "delay", "blur", "strength"];
                
                name = name.toLowerCase();
                for each (var s:String in tokens) {
                    if (name.indexOf(s) != -1) return true;
                }
            }
            
            return false;
        }
        
        public static function isString(name:String):Boolean {
            return !(isNumber(name) || isColor(name));
        }
        
         public static function isGlobal(name:String):Boolean {
            return name.indexOf("global.") === 0;
        }
        
        public static function isNode(name:String):Boolean {
            return name.indexOf("nodes.") === 0;
        }
        
        public static function isEdge(name:String):Boolean {
            return name.indexOf("edges.") === 0;
        }
        
        public static function isMergedEdge(name:String):Boolean {
            return isEdge(name) && name.toLowerCase().indexOf("merge") !== -1;
        }
        
        public static function getGroup(name:String):String {
            var gr:String;
            if (name != null) {
                if (name.indexOf(Groups.NODES) === 0) gr = Groups.NODES;
                else if (name.indexOf(Groups.EDGES) === 0) gr = Groups.EDGES;
                else gr = "global";
            }
            return gr;
        }

        // ========[ PRIVATE METHODS ]==============================================================

    }
}