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
package org.cytoscapeweb.model.data {
    import org.cytoscapeweb.util.ArrowShapes;
    import org.cytoscapeweb.util.LineStyles;
    import org.cytoscapeweb.util.NodeShapes;
    import org.cytoscapeweb.util.Utils;

    
    public class VisualStyleVO {
        
        // ========[ CONSTANTS ]====================================================================
        
        // ========[ PRIVATE PROPERTIES ]===========================================================
        
        private var _properties:Object;
        private var _visualStyleBypass:VisualStyleBypassVO;
        
        internal static const _DEFAULT_OBJ:Object = {
              global: {
                    backgroundColor: "#ffffff",
                    tooltipDelay: 800,
                    selectionLineColor: "#8888ff",
                    selectionLineOpacity: 0.8,
                    selectionLineWidth: 1,
                    selectionFillColor: "#8888ff",
                    selectionFillOpacity: 0.1
                },
                nodes: {
                    // regular nodes
                    shape: NodeShapes.ELLIPSE,
                    size: 24,
//                    width: -1,
//                    height: -1,
                    color: "#f5f5f5",
                    opacity: 0.8,
                    borderColor: "#666666",
                    borderWidth: 1,
                    label: { passthroughMapper: { attrName: "label" } },
                    labelHorizontalAnchor: "center",
                    labelVerticalAnchor: "middle",
                    labelXOffset: 0,
                    labelYOffset: 0,
                    labelFontName: "Arial",
                    labelFontSize: 11,
                    labelFontColor: "#000000",
                    labelFontWeight: "normal",
                    labelFontStyle: "normal",
                    tooltipFont: "Arial",
                    tooltipFontSize: 11,
                    tooltipFontColor: "#000000",
                    tooltipBackgroundColor: "#f5f5cc",
                    tooltipBorderColor: "#000000",
                    labelGlowColor: "#ffffff",
                    labelGlowOpacity: 0,
                    labelGlowBlur: 2,
                    labelGlowStrength: 20,
                    selectionGlowColor: "#ffff33",
                    selectionGlowOpacity: 0.6,
                    selectionGlowBlur: 8,
                    selectionGlowStrength: 6,
                    hoverGlowColor: "#aae6ff",
                    hoverGlowOpacity: 0,
                    hoverGlowBlur: 8,
                    hoverGlowStrength: 6,
                    
                    // compound nodes
                    compoundPaddingLeft: 10,
                    compoundPaddingRight: 10,
                    compoundPaddingTop: 10,
                    compoundPaddingBottom: 10,
                    compoundShape: NodeShapes.RECTANGLE,
                    compoundSize: 48,
                    compoundColor: "#f5f5f5",
                    compoundOpacity: 0.8,
                    compoundBorderColor: "#666666",
                    compoundBorderWidth: 1,
                    compoundLabel: { passthroughMapper: { attrName: "label" } },
                    compoundLabelHorizontalAnchor: "center",
                    compoundLabelVerticalAnchor: "top",
                    compoundLabelXOffset: 0,
                    compoundLabelYOffset: 0,
                    compoundLabelFontName: "Arial",
                    compoundLabelFontSize: 11,
                    compoundLabelFontColor: "#000000",
                    compoundLabelFontWeight: "normal",
                    compoundLabelFontStyle: "normal",
                    compoundLabelGlowColor: "#ffffff",
                    compoundLabelGlowOpacity: 0,
                    compoundLabelGlowBlur: 2,
                    compoundLabelGlowStrength: 20,
                    compoundTooltipFont: "Arial",
                    compoundTooltipFontSize: 11,
                    compoundTooltipFontColor: "#000000",
                    compoundTooltipBackgroundColor: "#f5f5cc",
                    compoundTooltipBorderColor: "#000000",
                    compoundSelectionGlowColor: "#ffff33",
                    compoundSelectionGlowOpacity: 0.6,
                    compoundSelectionGlowBlur: 8,
                    compoundSelectionGlowStrength: 6,
                    compoundHoverGlowColor: "#aae6ff",
                    compoundHoverGlowOpacity: 0,
                    compoundHoverGlowBlur: 8,
                    compoundHoverGlowStrength: 6
                },
                edges: {
                    color: "#999999",
                    mergeColor: "#666666",
                    width: 1,
                    mergeWidth: 1,
                    opacity: 0.8,
                    mergeOpacity: 0.8,
                    style: LineStyles.SOLID,
                    mergeStyle: LineStyles.SOLID,
                    sourceArrowShape: "none",
                    targetArrowShape: {
                        defaultValue: "none",
                        discreteMapper: { attrName: "directed",
                                          entries: [ { attrValue: "true",  value: ArrowShapes.DELTA },
                                                     { attrValue: "false", value: ArrowShapes.NONE } ]
                        }
                    },
                    label: { passthroughMapper: { attrName: "label" } },
                    labelHorizontalAnchor: "center",
                    labelVerticalAnchor: "middle",
                    labelXOffset: 0,
                    labelYOffset: 0,
                    labelFontName: "Arial",
                    labelFontSize: 11,
                    labelFontColor: "#000000",
                    labelFontWeight: "normal",
                    labelFontStyle: "normal",
                    tooltipFont: "Arial",
                    tooltipFontSize: 11,
                    tooltipFontColor: "#000000",
                    tooltipBackgroundColor: "#f5f5cc",
                    tooltipBorderColor: "#000000",
                    labelGlowColor: "#ffffff",
                    labelGlowOpacity: 0,
                    labelGlowBlur: 2,
                    labelGlowStrength: 20,
                    selectionGlowColor: "#ffff33",
                    selectionGlowOpacity: 0.6,
                    selectionGlowBlur: 4,
                    selectionGlowStrength: 10,
                    curvature: 18
                }
        };
        
        // ========[ PUBLIC PROPERTIES ]============================================================
        
        /** A mapping of VisualPropertyVO objects that has the property name as keys. */
        public function get properties():Object {
            return _properties;
        }
        public function set properties(props:Object):void {
            _properties = props != null ? props : {};
        }
        
        public function get visualStyleBypass():VisualStyleBypassVO {
            return _visualStyleBypass;
        }
        public function set visualStyleBypass(bypass:VisualStyleBypassVO):void {
            _visualStyleBypass = bypass != null ? bypass : new VisualStyleBypassVO();
        }

        // ========[ CONSTRUCTOR ]==================================================================
        
        public function VisualStyleVO() {
            properties = {};
            visualStyleBypass = new VisualStyleBypassVO();
        }
        
        // ========[ PUBLIC METHODS ]===============================================================
        
        public function getVisualProperty(visPropName:String):VisualPropertyVO {
            return properties[visPropName] as VisualPropertyVO;
        }
        
        public function addVisualProperty(visProp:VisualPropertyVO):void {
            if (visProp != null)
                properties[visProp.name] = visProp;
        }
        
        public function removeVisualProperty(visPropName:String):void {
            delete properties[visPropName];
        }
        
        public function getValue(visPropName:String, data:Object=null):* {
            var value:*;
            
            // First, check if there is a bypass value:
            if (visualStyleBypass != null && data != null) {
                value = visualStyleBypass.getValue(visPropName, data.id);
            }
            if (value === undefined) {
                var vp:VisualPropertyVO = getVisualProperty(visPropName);
    
                if (vp != null) {
                    var mapper:VizMapperVO = vp.vizMapper;
                    
                    if (data != null && mapper != null) {
                        value = mapper.getValue(data);
                        
                        if (mapper is ContinuousVizMapperVO && isNaN(value))
                            value = null;
                    }
                    
                    if (value == null)
                        value = vp.defaultValue;
                }
            }
            
            return value;
        }
        
        public function hasVisualProperty(visPropName:String):Boolean {
            var vp:VisualPropertyVO = getVisualProperty(visPropName);
            return vp != null;
        }
        
        public function hasVizMapper(visPropName:String):Boolean {
            var vp:VisualPropertyVO = getVisualProperty(visPropName);
            return vp != null && vp.vizMapper != null;
        }
        
        public function getPropertiesAsArray():Array {
            var arr:Array = [];
            
            for (var key:* in properties)
                arr.push(properties[key]);
            
            return arr;
        }
        
        public function toObject():Object {
            var obj:Object = {};

            for each (var vp:VisualPropertyVO in properties) {
                var tokens:Array = vp.name.split(".");
                var grName:String = tokens[0];
                var pName:String = tokens[1];
                if (obj[grName] === undefined) obj[grName] = {} ;
                obj[grName][pName] = vp.toObject();
            }
            
            return obj;
        }
        
        public static function fromObject(obj:Object):VisualStyleVO {
            var grName:String, pName:String, props:Object, dprops:Object, dp:Object, p:Object;

            if (obj != null && obj !== _DEFAULT_OBJ) {
                var defObj:Object = Utils.clone(_DEFAULT_OBJ);
                
                // Merge the given object with the default one:
                for (grName in defObj) {
                    dprops = defObj[grName];
                    props = obj[grName];
                    // The custom style does not have this group:
                    if (props == null) props = obj[grName] = {};
                    
                    for (pName in dprops) {
                        dp = dprops[pName];
                        p = obj[grName][pName];
                        
                        if (p == null) {
                            // The custom style does not have this property, so set a default one:
                            props[pName] = dp;
                        } else if (typeof p === "object" && p["defaultValue"] == null) {
                            // The custom style has this property, but not a default value for it,
                            // so let's set one from the default style:
                            p["defaultValue"] = (dp != null && typeof dp === "object" && dp.hasOwnProperty("defaultValue")) ?
                                                dp["defaultValue"] :
                                                dp;
                        }
                    }
                }
            }
            
            var style:VisualStyleVO = new VisualStyleVO();

            // global | nodes | edges
            for (grName in obj) {
                var group:Object = obj[grName];
                
                // Parse the visual properties:
                for (pName in group) {
                    var propName:String = grName+"."+pName;
                    p = group[pName];
                    
                    var vp:VisualPropertyVO = VisualPropertyVO.fromObject(propName, p);                   
                    style.addVisualProperty(vp);
                }
            }
            
            return style;
        }
        
        public static function defaultVisualStyle():VisualStyleVO {
            return VisualStyleVO.fromObject(_DEFAULT_OBJ);
        }
    }
}