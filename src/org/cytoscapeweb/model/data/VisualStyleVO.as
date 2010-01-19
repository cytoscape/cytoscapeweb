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
    import org.cytoscapeweb.util.NodeShapes;
    import org.cytoscapeweb.util.Utils;

	
	public class VisualStyleVO {
		
		// ========[ CONSTANTS ]====================================================================
		
        // ========[ PRIVATE PROPERTIES ]===========================================================
		
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
                    shape: NodeShapes.ELLIPSE,
                    size: 24,
                    color: "#f5f5f5",
                    opacity: 0.8,
                    borderColor: "#666666",
                    borderWidth: 1,
                    label: { passthroughMapper: { attrName: "label" } },
                    labelHorizontalAnchor: "left",
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
                    hoverGlowStrength: 6
                },
                edges: {
                    color: "#999999",
                    mergeColor: "#666666",
                    width: 1,
                    mergeWidth: 1,
                    opacity: 0.8,
                    mergeOpacity: 0.8,
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
        public var properties:Object;
        public var visualStyleBypass:VisualStyleBypassVO;

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
		
		public function getDefaultValue(visPropName:String):* {
			var value:* = null;
			var vp:VisualPropertyVO = getVisualProperty(visPropName);
			if (vp != null) value = vp.defaultValue;
			
			return value;
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
                    if (data != null && vp.vizMapper != null)
                        value = vp.vizMapper.getValue(data);
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
			var grName:String, pName:String;

			if (obj != null && obj !== _DEFAULT_OBJ) {
			    var defObj:Object = Utils.clone(_DEFAULT_OBJ);
			    
			    // Merge the given object with the default one:
			    for (grName in obj) {
			        var props:Object = obj[grName];
			        for (pName in props) {
			            var p:Object = props[pName];
			            var gr:Object = defObj[grName];
			            if (gr != null) gr[pName] = p;
			        }
			    }
			    
			    obj = defObj;
			}
			
			var style:VisualStyleVO = new VisualStyleVO();

            // global | nodes | edges
            for (grName in obj) {
                var group:Object = obj[grName];
                
                // Parse the visual properties:
                for (pName in group) {
                    var propName:String = grName+"."+pName;
                    var prop:Object = group[pName];
                    
                    var vp:VisualPropertyVO = VisualPropertyVO.fromObject(propName, prop);                   
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