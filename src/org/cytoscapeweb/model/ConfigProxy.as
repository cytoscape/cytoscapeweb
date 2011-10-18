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
package org.cytoscapeweb.model {
    import flare.vis.data.Data;
    import flare.vis.data.EdgeSprite;
    import flare.vis.data.NodeSprite;
    
    import mx.utils.StringUtil;
    
    import org.cytoscapeweb.ApplicationFacade;
    import org.cytoscapeweb.model.data.ConfigVO;
    import org.cytoscapeweb.model.data.ContinuousVizMapperVO;
    import org.cytoscapeweb.model.data.VisualPropertyVO;
    import org.cytoscapeweb.model.data.VisualStyleBypassVO;
    import org.cytoscapeweb.model.data.VisualStyleVO;
    import org.cytoscapeweb.model.error.CWError;
    import org.cytoscapeweb.util.GraphUtils;
    import org.cytoscapeweb.util.Layouts;
    import org.puremvc.as3.patterns.proxy.Proxy;
    
    [Bindable]
    public class ConfigProxy extends Proxy {

        // ========[ CONSTANTS ]====================================================================

        public static const NAME:String = 'ConfigProxy';

        // ========[ PRIVATE PROPERTIES ]===========================================================

        // ========[ PUBLIC PROPERTIES ]============================================================
        
        public var id:String;
        
        public function get config():ConfigVO {
            return data as ConfigVO;
        }

        public function set config(cfg:ConfigVO):void {
            if (cfg != null && data != cfg) {
                data = cfg;
                sendNotification(ApplicationFacade.CONFIG_CHANGED, cfg);
            }
        }
        
        public function get panZoomControlVisible():Boolean {
            return config.panZoomControlVisible;
        }
        
        public function set panZoomControlVisible(visible:Boolean):void {
            config.panZoomControlVisible = visible;
        }
        
        public function get panZoomControlPosition():String {
            return config.panZoomControlPosition;
        }
        
        public function set panZoomControlPosition(position:String):void {
            config.panZoomControlPosition = position;
        }
        
        public function set grabToPanEnabled(enable:Boolean):void {
            config.grabToPanEnabled = enable;
        }
        
        public function get grabToPanEnabled():Boolean {
            return config.grabToPanEnabled;
        }
        
        public function get edgesMerged():Boolean {
            return config.edgesMerged;
        }
        
        public function set nodeLabelsVisible(visible:Boolean):void {
            config.nodeLabelsVisible = visible;
        }
        
        public function get nodeLabelsVisible():Boolean {
            return config.nodeLabelsVisible;
        }
        
        public function set edgeLabelsVisible(visible:Boolean):void {
            config.edgeLabelsVisible = visible;
        }
        
        public function get edgeLabelsVisible():Boolean {
            return config.edgeLabelsVisible;
        }
        
        public function set nodeTooltipsEnabled(enable:Boolean):void {
            config.nodeTooltipsEnabled = enable;
        }
        
        public function get nodeTooltipsEnabled():Boolean {
            return config.nodeTooltipsEnabled;
        }
        
        public function set edgeTooltipsEnabled(enable:Boolean):void {
            config.edgeTooltipsEnabled = enable;
        }
        
        public function get edgeTooltipsEnabled():Boolean {
            return config.edgeTooltipsEnabled;
        }
        
        public function set customCursorsEnabled(enable:Boolean):void {
            config.customCursorsEnabled = enable;
        }
        
        public function get customCursorsEnabled():Boolean {
            return config.customCursorsEnabled;
        }
        
        public function set edgesMerged(merged:Boolean):void {
            config.edgesMerged = merged;
        }
        
        public function get visualStyle():VisualStyleVO {
            return config.visualStyle;
        }
        
        public function set visualStyle(style:VisualStyleVO):void {
            if (style != null && style != config.visualStyle) {
                config.visualStyle = style;
                sendNotification(ApplicationFacade.VISUAL_STYLE_CHANGED, style);
            }
        }
        
        public function get visualStyleBypass():VisualStyleBypassVO {
            return config.visualStyle.visualStyleBypass;
        }
        
        public function set visualStyleBypass(bypass:VisualStyleBypassVO):void {
            config.visualStyle.visualStyleBypass = bypass;
        }
        
        public function get currentLayout():Object {
            return config.currentLayout;
        }

        public function set currentLayout(obj:Object):void {
            var name:String, options:Object;
            
            if (obj is String) {
                name = String(obj);
                options = {};
                obj = {};
            } else {
                name = obj.name;
                options = obj.options;
            }
            name = StringUtil.trim(name).toLowerCase();
            
            if (name != null) {
                switch (name) {
                    case Layouts.CIRCLE.toLowerCase():         name = Layouts.CIRCLE; break;
                    case Layouts.FORCE_DIRECTED.toLowerCase(): name = Layouts.FORCE_DIRECTED; break;
                    case Layouts.PRESET.toLowerCase():         name = Layouts.PRESET; break;
                    case Layouts.RADIAL.toLowerCase():         name = Layouts.RADIAL; break;
                    case Layouts.TREE.toLowerCase():           name = Layouts.TREE; break;
                    case Layouts.COSE.toLowerCase():           name = Layouts.COSE; break;
                    default:                                   throw new CWError("Invalid layout: " + name);
                }
                
                options = Layouts.mergeOptions(name, options);
                obj.name = name;
                obj.options = options;
                
                config.currentLayout = obj;
            }
        }
        
        public function get minZoom():Number {
            return config.minZoom;
        }
        
        public function set minZoom(value:Number):void {
            config.minZoom = value;
        }
        
        public function get maxZoom():Number {
            return config.maxZoom;
        }
        
        public function set maxZoom(value:Number):void {
            config.maxZoom = value;
        }
        
        public function get mouseDownToDragDelay():Number {
            return config.mouseDownToDragDelay;
        }
        
        public function set mouseDownToDragDelay(value:Number):void {
            config.mouseDownToDragDelay = value;
        }
        
        public function get preloadImages():Boolean {
            return config.preloadImages;
        }
        
        public function set preloadImages(value:Boolean):void {
            config.preloadImages = value;
        }

        // ========[ CONSTRUCTOR ]==================================================================

        public function ConfigProxy(params:Object = null) {
            super(NAME);
            config = ConfigVO.getDefault();

            if (params != null) {
                id = params.id;
            }
        }

        // ========[ PUBLIC METHODS ]===============================================================

        /**
         * It just binds the data to the VizMappers.
         */
        public function bindGraphData(data:Data):void {
            var nodesData:Array = [], edgesData:Array = [], mergedEdgesData:Array = [];
            
            if (data.nodes != null) {
                for each (var n:NodeSprite in data.nodes) {
                    if (!GraphUtils.isFilteredOut(n)) nodesData.push(n.data);
                }
            } if (data.edges != null) {
                for each (var e:EdgeSprite in data.edges) {
                    if (!GraphUtils.isFilteredOut(e)) {
                        if (!e.props.$merged) edgesData.push(e.data);
                        else                  mergedEdgesData.push(e.data);
                    }
               }
            }

            var props:Array = visualStyle.getPropertiesAsArray();
            
            for each (var p:VisualPropertyVO in props) {
                if (p.vizMapper is ContinuousVizMapperVO) {
                    if (p.isNodeProperty()) {
                        ContinuousVizMapperVO(p.vizMapper).dataList = nodesData;
                    } else if (p.isEdgeProperty()) {
                        if (p.isMergedEdgeProperty())
                            ContinuousVizMapperVO(p.vizMapper).dataList = mergedEdgesData;
                        else
                            ContinuousVizMapperVO(p.vizMapper).dataList = edgesData;
                    }
                }
            }
        }

        // ========[ PRIVATE METHODS ]==============================================================

    }
}