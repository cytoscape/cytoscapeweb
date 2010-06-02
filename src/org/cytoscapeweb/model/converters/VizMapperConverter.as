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
    import mx.formatters.DateFormatter;
    import mx.utils.StringUtil;
    
    import org.cytoscapeweb.model.data.ContinuousVizMapperVO;
    import org.cytoscapeweb.model.data.DiscreteVizMapperVO;
    import org.cytoscapeweb.model.data.PassthroughVizMapperVO;
    import org.cytoscapeweb.model.data.VisualPropertyVO;
    import org.cytoscapeweb.model.data.VisualStyleVO;
    import org.cytoscapeweb.model.data.VizMapperVO;
    import org.cytoscapeweb.util.Fonts;
    import org.cytoscapeweb.util.NodeShapes;
    import org.cytoscapeweb.util.Utils;
    import org.cytoscapeweb.util.VisualProperties;


    /**
     * Converts visual styles from and to Cytoscape's VizMapper properties files.
     */
    public class VizMapperConverter {

        // ========[ CONSTANTS ]====================================================================
        
        private static const DEFAULT_STYLE_NAME:String = "default";

        // Cytoscape types:
        private static const BOOLEAN:int = 1;
        private static const NUMBER:int = 2;
        private static const INT:int = 3;
        private static const STRING:int = 4;
        
        private static const HEADER:String =
            "#This file specifies visual mappings for Cytoscape and has been automatically generated.\n" +
            "# WARNING: any changes you make to this file while Cytoscape is running may be overwritten.\n" +
            "# Any changes may make these visual mappings unreadable.\n" +
            "# Please make sure you know what you are doing before modifying this file by hand.\n" +
            "#\n";
        
        // ========[ PRIVATE PROPERTIES ]===========================================================
        
        private var _styleName:String;
     
        private static const CYTOSCAPE_PROPS:Object = {
            backgroundcolor: [VisualProperties.BACKGROUND_COLOR],
            nodefillcolor: [VisualProperties.NODE_COLOR],
            nodeopacity: [VisualProperties.NODE_ALPHA],
            nodebordercolor: [VisualProperties.NODE_LINE_COLOR],
            nodelinewidth: [VisualProperties.NODE_LINE_WIDTH],
            nodeshape: [VisualProperties.NODE_SHAPE],
            nodesize: [VisualProperties.NODE_SIZE],
            nodeuniformsize: [VisualProperties.NODE_SIZE],
            nodelabel: [VisualProperties.NODE_LABEL],
            nodefont: [VisualProperties.NODE_LABEL_FONT_NAME, VisualProperties.NODE_LABEL_FONT_WEIGHT, VisualProperties.NODE_LABEL_FONT_STYLE],
            nodefontsize: [VisualProperties.NODE_LABEL_FONT_SIZE],
            nodelabelcolor: [VisualProperties.NODE_LABEL_FONT_COLOR],
            nodelabelposition: [VisualProperties.NODE_LABEL_HANCHOR, VisualProperties.NODE_LABEL_VANCHOR, VisualProperties.NODE_LABEL_XOFFSET, VisualProperties.NODE_LABEL_YOFFSET],
            nodetooltip: [VisualProperties.NODE_TOOLTIP_TEXT],
            nodeselectioncolor: [VisualProperties.NODE_SELECTION_COLOR],
            edgecolor: [VisualProperties.EDGE_COLOR],
            edgelinewidth: [VisualProperties.EDGE_WIDTH],
            edgesourcearrowshape: [VisualProperties.EDGE_SOURCE_ARROW_SHAPE],
            edgesourcearrowcolor: [VisualProperties.EDGE_SOURCE_ARROW_COLOR],
            edgetargetarrowshape: [VisualProperties.EDGE_TARGET_ARROW_SHAPE],
            edgetargetarrowcolor: [VisualProperties.EDGE_TARGET_ARROW_COLOR],
            edgelabel: [VisualProperties.EDGE_LABEL],
            edgefont: [VisualProperties.EDGE_LABEL_FONT_NAME, VisualProperties.EDGE_LABEL_FONT_WEIGHT, VisualProperties.EDGE_LABEL_FONT_STYLE],
            edgefontsize: [VisualProperties.EDGE_LABEL_FONT_SIZE],
            edgelabelcolor: [VisualProperties.EDGE_LABEL_FONT_COLOR],
            edgetooltip: [VisualProperties.EDGE_TOOLTIP_TEXT],
            edgeopacity: [VisualProperties.EDGE_ALPHA, VisualProperties.EDGE_ALPHA_MERGE],
            edgeselectioncolor: [VisualProperties.EDGE_SELECTION_COLOR]
        };
        
        // ========[ PUBLIC PROPERTIES ]============================================================
   
        public function get styleName():String {
            return _styleName == null ? DEFAULT_STYLE_NAME : _styleName;
        }   
        
        // ========[ CONSTRUCTOR ]==================================================================
        
        public function VizMapperConverter() {
        }
        
        // ========[ PUBLIC METHODS ]===============================================================

        public function read(propsText:String, name:String=null):VisualStyleVO {
            _styleName = name;
            
            var vs:VisualStyleVO = VisualStyleVO.defaultVisualStyle();
            var props:Properties = new Properties(propsText);
            var values:Object = props.values;
            var k:String, pname:String, vp:VisualPropertyVO;
            var v:*, pvalue:*;
            var mappersList:Array = []; // store parsed vizmappers
            var mapper:VizMapperVO;
            
            // Remove some cytoweb default styles:
            vs.removeVisualProperty(VisualProperties.NODE_TOOLTIP_TEXT);
            vs.removeVisualProperty(VisualProperties.EDGE_TOOLTIP_TEXT);
            vs.removeVisualProperty(VisualProperties.NODE_LABEL);
            vs.removeVisualProperty(VisualProperties.EDGE_LABEL);
            vs.removeVisualProperty(VisualProperties.NODE_SELECTION_GLOW_ALPHA);
            vs.removeVisualProperty(VisualProperties.EDGE_SELECTION_GLOW_ALPHA);
            
            var pattern:RegExp = new RegExp(
                "globalAppearanceCalculator\."+styleName+"\.default|" + 
                "edgeAppearanceCalculator\."+styleName+"\.(defaultEdge|edge)|" +
                "nodeAppearanceCalculator\."+styleName+"\.(defaultNode|node)"
            );
            var replacePattern:RegExp = new RegExp(
                "(globalAppearanceCalculator|" + 
                "edgeAppearanceCalculator|edgeColorCalculator|edgeOpacityCalculator|edgeLabelCalculator|" +
                "edgeSourceArrowOpacityCalculator|edgeSourceArrowColorCalculator|edgeSourceArrowShapeCalculator|" +
                "edgeTargetArrowOpacityCalculator|edgeTargetArrowColorCalculator|edgeTargetArrowShapeCalculator|" +
                "nodeAppearanceCalculator|nodeLabelCalculator)" +
                "\."+styleName+"\."
            );
            
            for (k in values) {
                if (k.search(pattern) > -1) {
                    v = values[k];
                    var def:Boolean = k.search(/\..+?\.default./) > 0;
                    // Use just the final token as key:
                    k = k.replace(replacePattern, "");
                    
                    if (def) {
                        // Default value:
                        // ---------------------------------
                        k = k.replace("default", "").toLowerCase();
                        
                        for each (pname in CYTOSCAPE_PROPS[k]) {
                            pvalue = parseValue(pname, v);
                            if (pvalue !== undefined) {
                                vp = new VisualPropertyVO(pname, pvalue);
                                vs.addVisualProperty(vp);
                            }
                        }
                    } else {
                        // Mappings:
                        // ---------------------------------
                        // The initial token of the name of the mapper property. Example:
                        //     - The mapper definition:
                        //       (...).edgeColorCalculator = MySytle-Edge Color-Discrete Mapper
                        //     - The mapper values:
                        //       edgeColorCalculator.MySytle-Edge\ Color-Discrete\ Mapper.(...) = (...)
                        var vmk:String = k + "." + v;
                        k = k.replace("Calculator", "").toLowerCase();
                        
                        for each (pname in CYTOSCAPE_PROPS[k]) {
                            var vmType:String = values[vmk+".mapping.type"];
                            var attrName:String = values[vmk+".mapping.controller"];
                            if (attrName === "ID") attrName = "label";
                            
                            switch (vmType) {
                                case "PassThroughMapping":
                                    mapper = new PassthroughVizMapperVO(attrName, pname);
                                    break;
                                case "DiscreteMapping":
                                    var dm:DiscreteVizMapperVO = new DiscreteVizMapperVO(attrName, pname);
                                    var type:int = int(values[vmk+".mapping.controllerType"]);
                                    
                                    for (var attrValue:* in values) {
                                        if (attrValue.indexOf(vmk+".mapping.map.") > -1) {
                                            pvalue = values[attrValue];
                                            pvalue = parseValue(pname, pvalue);
                                            
                                            attrValue = attrValue.replace(vmk+".mapping.map.", "");
                                            attrValue = parseAttrValue(attrValue, type);
                                            
                                            dm.addEntry(attrValue, pvalue);
                                        }
                                    }

                                    mapper = dm;
                                    break;
                                case "ContinuousMapping":
                                    // Important: Cytoscape Web accepts only 2 boundary values!
                                    var minValue:* = values[vmk+".mapping.bv0.equal"];
                                    var maxValue:* = values[vmk+".mapping.bv1.equal"];
                                    minValue = parseValue(pname, minValue);
                                    maxValue = parseValue(pname, maxValue);
                                    mapper = new ContinuousVizMapperVO(attrName, pname, minValue, maxValue);
                                    break;
                            }
                            
                            if (mapper != null) mappersList.push(mapper);
                        }
                    }
                }
            }
            
            // Now that all the visual properties are parsed, add the mappers:
            for each (mapper in mappersList) {
                pname = mapper.propName;
                vp = vs.getVisualProperty(pname);
                
                if (vp == null) {
                    vp = new VisualPropertyVO(pname);
                    vs.addVisualProperty(vp);
                }
                
                vp.vizMapper = mapper;
            }

            return vs;
        }

        public function write(style:VisualStyleVO, name:String=null):String {
            _styleName = name;
            var txt:String = HEADER;
            
            // Add date to header:
            var df:DateFormatter = new DateFormatter();
            df.formatString = "EEE MMMM D H:NN:SS YYYY";
            txt += "#" + df.format(new Date());

            // Add properties:
            var props:Array = style.getPropertiesAsArray();
            
            for each (var vp:VisualPropertyVO in props) {
                var n:String = vp.name;
                var v:* = vp.defaultValue;
                var mapper:VizMapperVO = vp.vizMapper;

                // Add default or global values:
                v = propsValue(style, n, v);
                var key:String = fromCWProperty(n);
                txt += (key + "=" + v);
                
                // Add mapper values:
                if (mapper != null) {
                    // TODO
                }
            }
            
            return txt;
        }
        
        // ========[ PRIVATE METHODS ]==============================================================
        
        // -- static helpers --------------------------------------------------
        
        private function propsValue(style:VisualStyleVO, propName:String, value:*):* { 
            // TODO...
            return value;
        }

        private function parseValue(propName:String, value:*):* {
            if (value != null) {
                switch (propName) {
                    case VisualProperties.NODE_LABEL_FONT_NAME:
                    case VisualProperties.EDGE_LABEL_FONT_NAME:
                        // e.g. "Monospaced.bold,plain,12"
                        value = value.replace(/(.bold)?,[^,]+,\d+/, "");
                        value = StringUtil.trim(value);
                        value = toCW_FontName(value);
                        break;
                    case VisualProperties.NODE_LABEL_FONT_WEIGHT:
                    case VisualProperties.EDGE_LABEL_FONT_WEIGHT:
                        // e.g. "SansSerif.bold,plain,12"
                        value = value.search(/\.(bold),/) < 0 ? "normal" : "bold";
                        break;
                    case VisualProperties.NODE_LABEL_FONT_STYLE:
                    case VisualProperties.EDGE_LABEL_FONT_STYLE:
                        // e.g. "SansSerif.bold,plain,12"
                        value = value.search(/[^,]+,(italic),/) < 0 ? "normal" : "italic";
                        break;
                    case VisualProperties.NODE_LABEL_FONT_SIZE:
                    case VisualProperties.EDGE_LABEL_FONT_SIZE:
                        // e.g. "SansSerif.bold,plain,12"
                        value = value.replace(/[^,]+,[^,]+,/, "");
                        value = Number(value);
                        break;
                    case VisualProperties.NODE_LABEL_HANCHOR:
                        // e.g. "E,W,c,10,20" (node_anchor,label_anchor,label_justification,x_offset,y_offset)
                        value = value.replace(/,[A-Z]+,[a-z]+,\d+,\d+/, "");
                        value = toCW_HAnchor(value);
                        break;
                    case VisualProperties.NODE_LABEL_VANCHOR:
                        // e.g. "E,W,c,10,20"
                        value = value.replace(/,[A-Z]+,[a-z]+,\d+,\d+/, "");
                        value = toCW_VAnchor(value);
                        break;
                    case VisualProperties.NODE_LABEL_XOFFSET:
                        // e.g. "E,W,c,10,20"
                        value = value.replace(/[A-Z]+,[A-Z]+,[a-z]+,/, "").replace(/,\d+/, "");
                        value = Number(value);
                        if (isNaN(value)) value = 0;
                        break;
                    case VisualProperties.NODE_LABEL_YOFFSET:
                        // e.g. "E,W,c,10,20"
                        value = value.replace(/[A-Z]+,[A-Z]+,[a-z]+,\d+,/, "");
                        value = Number(value);
                        if (isNaN(value)) value = 0;
                        break;
                    case VisualProperties.NODE_TOOLTIP_TEXT:
                    case VisualProperties.EDGE_TOOLTIP_TEXT:
                        if (value === '') value = undefined;
                        break;
                    default:
                        if (VisualProperties.isAlpha(propName)) value = Number(value)/255; // convert from 0-255 to 0-1
                        value = VisualProperties.parseValue(propName, value);
                        break;
                }
            }
            
            return value;
        }
        
        private function parseAttrValue(value:String, dataType:int):* {
            switch (dataType) {
                case BOOLEAN: return StringUtil.trim(value).toLocaleLowerCase() === "true";
                case NUMBER:  return Number(value);
                case INT:     return int(value);
                default:      return value;
            }
        }
//        
//        private static function toString(o:Object, type:int):String {
//            return o != null ? o.toString() : ""; // TODO: formatting control?
//        }
        
        private function fromCWProperty(p:String):String {
            // TODO:
            return null;
        }
    
        private function fromCW_FontName(font:String):String {
            switch (font) {
                case null:
                case "":
                case Fonts.SANS_SERIF: return "SansSerif";
                case Fonts.SERIF:      return "Serif";
                case Fonts.TYPEWRITER: return "Monospaced";
                default:               return font;
            }
        }
        
        private function toCW_FontName(font:String):String {
            switch (font) {
                case null:
                case "":
                case "Default":
                case "SanSerif":
                case "SansSerif":  return Fonts.SANS_SERIF;
                case "Serif":      return Fonts.SERIF;
                case "Monospaced": return Fonts.TYPEWRITER;
                default:           return font;
            }
        }
        
        /**
         * @param hanchor the Cytoscape value for "node anchor points"
         */
        private function toCW_HAnchor(hanchor:String):String {
            switch (hanchor) {
                case "NE":
                case "SE":
                case "E": return "left";
                case "NW":
                case "SW":
                case "W": return "right";
                default:  return "center";
            }
        }
        
        /**
         * @param vanchor the Cytoscape value for "node anchor points"
         */
        private function toCW_VAnchor(vanchor:String):String {
            switch (vanchor) {
                case "NE":
                case "NW":
                case "N": return "bottom";
                case "SE":
                case "SW":
                case "S": return "top";
                default:  return "middle";
            }
        }
    }
}

// ========[ CLASSES ]==========================================================================

class VizMapperProps {
    
    public var name:String;
    
    public var globalAppearanceCalculator:Object;
}