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
    import com.adobe.serialization.json.JSON;
    
    import flash.external.ExternalInterface;
    import flash.utils.ByteArray;
    
    import mx.utils.Base64Encoder;
    
    import org.cytoscapeweb.ApplicationFacade;
    import org.cytoscapeweb.model.data.FirstNeighborsVO;
    import org.cytoscapeweb.model.data.VisualStyleBypassVO;
    import org.cytoscapeweb.model.data.VisualStyleVO;
    import org.cytoscapeweb.model.methods.error;
    import org.cytoscapeweb.util.ExternalFunctions;
    import org.cytoscapeweb.util.GraphUtils;
    import org.cytoscapeweb.util.Groups;
    import org.cytoscapeweb.view.ApplicationMediator;
    import org.puremvc.as3.patterns.proxy.Proxy;
	
    /**
    * This proxy encapsulates the interaction with the JavaScript API.
    */
    public class ExternalInterfaceProxy extends Proxy {

        // ========[ CONSTANTS ]====================================================================

        public static const NAME:String = 'ExternalInterfaceProxy';
        
        // ========[ PRIVATE PROPERTIES ]===========================================================
        
        private var _graphProxy:GraphProxy;
        private var _configProxy:ConfigProxy;
        private var _contextMenuProxy:ContextMenuProxy;
		
		private function get graphProxy():GraphProxy {
			if (_graphProxy == null)
                _graphProxy = ApplicationFacade.getInstance().retrieveProxy(GraphProxy.NAME) as GraphProxy;
            return _graphProxy;
		}

		private function get configProxy():ConfigProxy {
            if (_configProxy == null)
                _configProxy = ApplicationFacade.getInstance().retrieveProxy(ConfigProxy.NAME) as ConfigProxy;
            return _configProxy;
        }

        protected function get contextMenuProxy():ContextMenuProxy {
            if (_contextMenuProxy == null)
                _contextMenuProxy = facade.retrieveProxy(ContextMenuProxy.NAME) as ContextMenuProxy;
            return _contextMenuProxy;
        }
		
        // ========[ PUBLIC PROPERTIES ]============================================================
   
   
        // ========[ CONSTRUCTOR ]==================================================================
		
        public function ExternalInterfaceProxy() {
            super(NAME);
        }

        // ========[ PUBLIC METHODS ]===============================================================

        public function addCallbacks():void {
            if (ExternalInterface.available) {
                var functions:Array = [ "draw",
                                        "addContextMenuItem", "removeContextMenuItem", 
                                        "select", "deselect", 
                                        "mergeEdges", "isEdgesMerged", 
                                        "showNodeLabels", "isNodeLabelsVisible", 
                                        "showEdgeLabels", "isEdgeLabelsVisible", 
                                        "enableNodeTooltips", "isNodeTooltipsEnabled", 
                                        "enableEdgeTooltips", "isEdgeTooltipsEnabled", 
                                        "showPanZoomControl", "isPanZoomControlVisible", 
                                        "panBy", "panToCenter", 
                                        "zoomTo", "zoomToFit", "getZoom", 
                                        "filter", "removeFilter", 
                                        "firstNeighbors", 
                                        "getNodes", "getEdges", "getMergedEdges", 
                                        "getSelectedNodes", "getSelectedEdges", 
                                        "getLayout", "applyLayout", 
                                        "setVisualStyle", "getVisualStyle", 
                                        "getVisualStyleBypass", "setVisualStyleBypass",
                                        "getNetworkAsText", "getNetworkAsImage", 
                                        "exportNetwork" ];

	            for each (var f:String in functions) addFunction(f);

            } else {
                sendNotification(ApplicationFacade.EXT_INTERFACE_NOT_AVAILABLE);
	        }
        }
        
        public function hasListener(type:String, group:String="none"):Boolean {
            return callExternalInterface(ExternalFunctions.HAS_LISTENER, {type: type, group: group});
        }
        
        /**
         * Call a JavaScript function.
         * 
         * @param functionName The name of the JavaScript function.
         * @param argument The argument value.
         * @param json Whether or not the argument must be converted to the JSON format before
         *             the function is invoked.<br />
         *             Its important to convert nodes and edges data to JSON before calling JS functions
         *             from ActionScript, so graph attribute names can accept special characters such as:<br />
         *             <code>. - + * / \ :</code><br />
         *             Cytoscape usually creates attribute names such as "node.fillColor" or "vizmap:EDGE_COLOR"
         *             when exporting to XGMML, and those special characters crash the JS callback functions,
         *             because, apparently, Flash cannot call JS functions with argument objects that have
         *             one or more attribute names with those characters.
         * @return The return of the JavaScript function or <code>undefined</code> if the external
         *         function returns void.
         */
        public function callExternalInterface(functionName:String, argument:*, json:Boolean=false):* {
        	if (ExternalInterface.available) {
        	    var desigFunction:String;
        	    
        	    if (json && argument != null) {
                    argument = JSON.encode(argument);
                    // Call a proxy function instead, sending the name of the designated function.
                    desigFunction = functionName;
                    functionName = ExternalFunctions.DISPATCH;
        	    }
        	    
        	    functionName = "_cytoscapeWebInstances." + configProxy.id + "." + functionName;
        	    try {
            	    if (desigFunction != null)
                        return ExternalInterface.call(functionName, desigFunction, argument);
                    else
                        return ExternalInterface.call(functionName, argument);
                } catch (err:Error) {
                    error(err.message, err.errorID, err.name, err.getStackTrace());
                }
            } else {
                trace("Error [callExternalInterface]: ExternalInterface is NOT available!");
                return undefined;
            }
        }
	    
        // ========[ PRIVATE METHODS ]==============================================================

        // Callbacks ---------------------------------------------------
        
        private function draw(options:Object):void {
            sendNotification(ApplicationFacade.DRAW_GRAPH, options);
        }
        
        private function addContextMenuItem(label:String, group:String=null):void {
            if (group == null) group = Groups.NONE;
            contextMenuProxy.addMenuItem(label, group);
        }
        
        private function removeContextMenuItem(label:String, group:String=null):void {
            if (group == null) group = Groups.NONE;
            contextMenuProxy.removeMenuItem(label, group);
        }
        
        private function select(group:String, items:Array):void {
        	if (items == null)
                sendNotification(ApplicationFacade.SELECT_ALL, group);
            else
                sendNotification(ApplicationFacade.SELECT, graphProxy.getDataSpriteList(items, group));
        }
        
        private function deselect(group:String, items:Array):void {
        	if (items == null)
                sendNotification(ApplicationFacade.DESELECT_ALL, group);
        	else
                sendNotification(ApplicationFacade.DESELECT, graphProxy.getDataSpriteList(items, group));
        }
       
        private function mergeEdges(value:Boolean):void {
            sendNotification(ApplicationFacade.MERGE_EDGES, value);
        }
        
        private function isEdgesMerged():Boolean {
            return graphProxy.edgesMerged;
        }
        
        private function showPanZoomControl(value:Boolean):void {
            sendNotification(ApplicationFacade.SHOW_PANZOOM_CONTROL, value);
        }
        
        private function showNodeLabels(value:Boolean):void {
            sendNotification(ApplicationFacade.SHOW_LABELS, { value: value, group: Groups.NODES });
        }
        
        private function isNodeLabelsVisible():Boolean {
            return configProxy.nodeLabelsVisible;
        }
        
        private function showEdgeLabels(value:Boolean):void {
            sendNotification(ApplicationFacade.SHOW_LABELS, { value: value, group: Groups.EDGES });
        }
        
        private function isEdgeLabelsVisible():Boolean {
            return configProxy.edgeLabelsVisible;
        }
        
        private function enableNodeTooltips(val:Boolean):void {
            configProxy.nodeTooltipsEnabled = val;
        }
        
        private function isNodeTooltipsEnabled():Boolean {
            return configProxy.nodeTooltipsEnabled;
        }
        
        private function enableEdgeTooltips(value:Boolean):void {
            configProxy.edgeTooltipsEnabled = value;
        }
        
        private function isEdgeTooltipsEnabled():Boolean {
            return configProxy.edgeTooltipsEnabled;
        }
        
        private function isPanZoomControlVisible():Boolean {
            return configProxy.panZoomControlVisible;
        }

        private function panBy(panX:Number, panY:Number):void {
            sendNotification(ApplicationFacade.PAN_GRAPH, {panX: panX, panY: panY});
        }
        
        private function panToCenter():void {
            sendNotification(ApplicationFacade.CENTER_GRAPH);
        }
        
        private function zoomTo(scale:Number):void {
            sendNotification(ApplicationFacade.ZOOM_GRAPH, scale);
        }
        
        private function zoomToFit():void {
            sendNotification(ApplicationFacade.ZOOM_GRAPH_TO_FIT);
        }
        
        private function getZoom():Number {
            return graphProxy.zoom;
        }
        
        private function filter(group:String, items:Array, updateVisualMappers:Boolean=false):void {
            var filtered:Array = graphProxy.getDataSpriteList(items, group);
            sendNotification(ApplicationFacade.FILTER, 
                             { group: group, filtered: filtered, updateVisualMappers: updateVisualMappers });
        }
        
        private function removeFilter(group:String, updateVisualMappers:Boolean=false):void {
            sendNotification(ApplicationFacade.REMOVE_FILTER, 
                             { group: group, updateVisualMappers: updateVisualMappers });
        }
        
        private function firstNeighbors(rootNodes:Array, ignoreFilteredOut:Boolean=false):Object {
            var obj:Object = {};
            
            if (rootNodes != null && rootNodes.length > 0) {
	            var nodes:Array = graphProxy.getDataSpriteList(rootNodes, Groups.NODES);
	            
	            if (nodes != null && nodes.length > 0) {
		            var fn:FirstNeighborsVO  = new FirstNeighborsVO(nodes, ignoreFilteredOut);
	                obj = fn.toObject();
	                obj = JSON.encode(obj);
	            }
            }
            
            return obj;
        }

        private function getNodes():String {
            var arr:Array = GraphUtils.toExtObjectsArray(graphProxy.graphData.nodes);
            return JSON.encode(arr);
        }
        
        private function getEdges():String {
            var edges:Array = graphProxy.edges;
            var arr:Array = GraphUtils.toExtObjectsArray(edges);
            return JSON.encode(arr);
        }
        
        private function getMergedEdges():String {
            var edges:Array = graphProxy.mergedEdges;
            var arr:Array = GraphUtils.toExtObjectsArray(edges);
            return JSON.encode(arr);
        }
        
        private function getSelectedNodes():String {
            var arr:Array = GraphUtils.toExtObjectsArray(graphProxy.selectedNodes);
            return JSON.encode(arr);
        }
        
        private function getSelectedEdges():String {
            var arr:Array = GraphUtils.toExtObjectsArray(graphProxy.selectedEdges);
            return JSON.encode(arr);
        }
        
        private function getLayout():String {
            return configProxy.currentLayout;
        }
        
        private function setVisualStyle(style:Object):void {
            if (style != null) {
                var vo:VisualStyleVO = VisualStyleVO.fromObject(style);
                sendNotification(ApplicationFacade.SET_VISUAL_STYLE, vo);
            }
        }
        
        private function getVisualStyle():Object {
            return configProxy.visualStyle.toObject();
        }
        
        private function setVisualStyleBypass(obj:/*{group->{id->{propName->value}}}*/Object):void {
            var bypass:VisualStyleBypassVO = VisualStyleBypassVO.fromObject(obj);
            sendNotification(ApplicationFacade.SET_VISUAL_STYLE_BYPASS, bypass);
        }
        
        private function getVisualStyleBypass():Object {
            return configProxy.visualStyleBypass.toObject();
        }
        
        private function applyLayout(name:String):void {
            sendNotification(ApplicationFacade.APPLY_LAYOUT, name);
        }
        
        private function getNetworkAsText(format:String="xgmml", options:Object=null):String {
            return graphProxy.getDataAsText(format, options);
        }
        
        private function getNetworkAsImage(format:String="pdf", options:Object=null):String {
            if (options == null) options = {};
            // TODO: Refactor - proxy should NOT use a mediator!!!
            var appMediator:ApplicationMediator = facade.retrieveMediator(ApplicationMediator.NAME) as ApplicationMediator;
            var ba:ByteArray = appMediator.getGraphImage(format, options.width, options.height);
            
            var encoder:Base64Encoder = new Base64Encoder();
            encoder.encodeBytes(ba);

            return encoder.toString();
        }
        
        private function exportNetwork(format:String, url:String, options:Object=null):void {
            sendNotification(ApplicationFacade.EXPORT_NETWORK, { format: format, url: url, options: options });
        }

        // ------------------------------------------------------------

        private function addFunction(name:String):void {
            try {
                ExternalInterface.addCallback(name, this[name]);
            } catch(err:Error) {
                trace("Error [addFunction]: " + err);
                // TODO: decide what to do with this:
                sendNotification(ApplicationFacade.ADD_CALLBACK_ERROR, err);
            }
        }
    }
}
