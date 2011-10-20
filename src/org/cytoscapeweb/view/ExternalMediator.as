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
package org.cytoscapeweb.view {
    import com.adobe.serialization.json.JSON;
    
    import flare.data.DataSchema;
    import flare.data.DataSet;
    import flare.vis.data.DataList;
    import flare.vis.data.DataSprite;
    import flare.vis.data.EdgeSprite;
    import flare.vis.data.NodeSprite;
    
    import flash.external.ExternalInterface;
    import flash.geom.Point;
    import flash.utils.ByteArray;
    
    import mx.utils.Base64Encoder;
    
    import org.cytoscapeweb.ApplicationFacade;
    import org.cytoscapeweb.model.converters.ExternalObjectConverter;
    import org.cytoscapeweb.model.data.FirstNeighborsVO;
    import org.cytoscapeweb.model.data.GraphicsDataTable;
    import org.cytoscapeweb.model.data.VisualStyleBypassVO;
    import org.cytoscapeweb.model.data.VisualStyleVO;
    import org.cytoscapeweb.model.error.CWError;
    import org.cytoscapeweb.model.methods.error;
    import org.cytoscapeweb.util.ExternalFunctions;
    import org.cytoscapeweb.util.Groups;
    import org.cytoscapeweb.vis.data.CompoundNodeSprite;
    import org.puremvc.as3.interfaces.INotification;
        
    /**
     * This mediator encapsulates the interaction with the JavaScript API.
     */
    public class ExternalMediator extends BaseMediator {

        // ========[ CONSTANTS ]====================================================================

        /** Cannonical name of the Mediator. */
        public static const NAME:String = "ExternalInterfaceMediator";
        
        // ========[ PRIVATE PROPERTIES ]===========================================================
        

        // ========[ CONSTRUCTOR ]==================================================================
   
        public function ExternalMediator(viewComponent:Object) {
            super(NAME, viewComponent, this);
        }

        // ========[ PUBLIC METHODS ]===============================================================
    
        /** @inheritDoc */
        override public function getMediatorName():String {
            return NAME;
        }
        
        /** @inheritDoc */
        override public function listNotificationInterests():Array {
            return [ApplicationFacade.ADD_CALLBACKS, ApplicationFacade.CALL_EXTERNAL_INTERFACE];
        }

        /** @inheritDoc */
        override public function handleNotification(n:INotification):void {
            switch (n.getName()) {
                case ApplicationFacade.ADD_CALLBACKS:
                    addCallbacks();
                    break;
                case ApplicationFacade.CALL_EXTERNAL_INTERFACE:
                    var options:Object = n.getBody();
                    var json:Boolean = ExternalFunctions.isJSON(options.functionName);
                    callExternalInterface(options.functionName, options.argument, json);
                    break;
            }
        }
        
        public function hasListener(type:String, group:String=Groups.NONE):Boolean {
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
                    error(err);
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
            menuProxy.addMenuItem(label, group);
        }
        
        private function removeContextMenuItem(label:String, group:String=null):void {
            if (group == null) group = Groups.NONE;
            menuProxy.removeMenuItem(label, group);
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

        private function enableCustomCursors(value:Boolean):void {
            sendNotification(ApplicationFacade.ENABLE_CUSTOM_CURSORS, value);
        }
        
        private function isCustomCursorsEnabled():Boolean {
            return configProxy.customCursorsEnabled;
        }

        private function enableGrabToPan(value:Boolean):void {
            sendNotification(ApplicationFacade.ENABLE_GRAB_TO_PAN, value);
        }
        
        private function isGrabToPanEnabled():Boolean {
            return configProxy.grabToPanEnabled;
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
        
        private function firstNeighbors(rootNodes:Array, ignoreFilteredOut:Boolean=false):String {
            var obj:Object = {};
            
            if (rootNodes != null && rootNodes.length > 0) {
                var nodes:Array = graphProxy.getDataSpriteList(rootNodes, Groups.NODES);
                
                if (nodes != null && nodes.length > 0) {
                    var fn:FirstNeighborsVO  = new FirstNeighborsVO(nodes, ignoreFilteredOut);
                    obj = fn.toObject(graphProxy.zoom);
                }
            }
            
            return JSON.encode(obj);
        }

        private function getNodeById(id:String):String {
            var obj:Object = ExternalObjectConverter.toExtElement(graphProxy.getNode(id),
                                                                  graphProxy.zoom);
            return JSON.encode(obj);
        }
        
        private function getEdgeById(id:String):String {
            var obj:Object = ExternalObjectConverter.toExtElement(graphProxy.getEdge(id),
                                                                  graphProxy.zoom);
            return JSON.encode(obj);
        }
        
        private function getNodes(topLevelOnly:Boolean=false):String {
            var nodes:* = graphProxy.graphData.nodes;
            var arr:*, n:NodeSprite;
            
            if (topLevelOnly) {
                arr = [];
                for each (n in nodes) {
                    if (n.data.parent == null) arr.push(n);
                }
            } else {
                arr = nodes != null ? nodes : [];
            }
            
            arr = ExternalObjectConverter.toExtElementsArray(arr, graphProxy.zoom);
            return JSON.encode(arr);
        }
        
        private function getChildNodes(parentId:String):String {
            var nodes:*, arr:Array = [];
            var cn:CompoundNodeSprite = graphProxy.getNode(parentId);
            
            if (cn != null)
                nodes = cn.getNodes();
            if (nodes != null)
                arr = ExternalObjectConverter.toExtElementsArray(nodes, graphProxy.zoom);
            
            return JSON.encode(arr);
        }
        
        private function getParentNodes():String {
            var nodes:DataList = graphProxy.graphData.group(Groups.COMPOUND_NODES);
            var list:* = nodes != null ? nodes : [];
            list = ExternalObjectConverter.toExtElementsArray(list, graphProxy.zoom);
            return JSON.encode(list);
        }
        
        private function getEdges():String {
            var edges:Array = graphProxy.edges;
            var arr:Array = ExternalObjectConverter.toExtElementsArray(edges, graphProxy.zoom);
            return JSON.encode(arr);
        }
        
        private function getMergedEdges():String {
            var edges:Array = graphProxy.mergedEdges;
            var arr:Array = ExternalObjectConverter.toExtElementsArray(edges, graphProxy.zoom);
            return JSON.encode(arr);
        }
        
        private function getSelectedNodes():String {
            var arr:Array = ExternalObjectConverter.toExtElementsArray(graphProxy.selectedNodes,
                                                                       graphProxy.zoom);
            return JSON.encode(arr);
        }
        
        private function getSelectedEdges():String {
            var arr:Array = ExternalObjectConverter.toExtElementsArray(graphProxy.selectedEdges,
                                                                       graphProxy.zoom);
            return JSON.encode(arr);
        }
        
        private function getLayout():Object {
            return configProxy.currentLayout;
        }
        
        private function applyLayout(layout:Object):void {
            sendNotification(ApplicationFacade.APPLY_LAYOUT, layout);
        }
        
        private function setVisualStyle(obj:Object):void {
            if (obj != null) {
                var style:VisualStyleVO = VisualStyleVO.fromObject(obj);
                sendNotification(ApplicationFacade.SET_VISUAL_STYLE, style);
            }
        }
        
        private function getVisualStyle():Object {
            return configProxy.visualStyle.toObject();
        }
        
        private function setVisualStyleBypass(json:/*{group->{id->{propName->value}}}*/String):void {
            var obj:Object = JSON.decode(json);
            var bypass:VisualStyleBypassVO = VisualStyleBypassVO.fromObject(obj);
            sendNotification(ApplicationFacade.SET_VISUAL_STYLE_BYPASS, bypass);
        }
        
        private function getVisualStyleBypass():String {
            var obj:Object = configProxy.visualStyleBypass.toObject();
            return JSON.encode(obj);
        }
        
        private function addElements(items:Array, updateVisualMappers:Boolean=false):String {
            var newAll:Array = [], newNodes:Array = [], newEdges:Array = [], ret:Array = [];
            var edgesToAdd:Array = [], childrenToAdd:Array = [];
            var gr:String, newElement:DataSprite, parent:CompoundNodeSprite, o:Object;
            var createdEdges:Array;
            
            try {                
                // Create element:
                for each (o in items) {
                    gr = Groups.parse(o.group);
                    
                    if (gr == null)
                        throw new CWError("The 'group' field of the new element  must be either '" + 
                            Groups.NODES + "' or '" + Groups.EDGES + "'.");
                    
                    if (gr === Groups.NODES) {
                        // Create nodes first!
                        // (instantiate every node as a compound node)
                        newElement = graphProxy.addNode(o.data);
                        
                        // Position it:
                        var p:Point = new Point(o.x, o.y);
                        p = graphMediator.vis.globalToLocal(p);
                        newElement.x = p.x;
                        newElement.y = p.y;
                        
                        // check if current node will be added into a compound
                        if (o.data != null && o.data.parent) {
                            // hold a reference for the new created sprite
                            // for fast access during compound node update
                            o.sprite = newElement;
                            // add to the list of child nodes to be added 
                            childrenToAdd.push(o);
                        }
                        
                        newNodes.push(newElement);
                        newAll.push(newElement);
                    } else {
                        // Just store the edge,
                        // so it can be added after all new nodes have been created first:
                        edgesToAdd.push(o);
                    }
                }
                
                // Now it is safe to add the edges:
                for each (o in edgesToAdd) {
                    createdEdges = graphProxy.addEdge(o.data);
                    newEdges.push(createdEdges[0]);
                    newAll.push(createdEdges[0]);
                    
                    if (createdEdges.length > 1) {
                        newEdges.push(createdEdges[1]);
                    }
                }
                
                // process child nodes to add, and update corresponding parent compound nodes
                for each (o in childrenToAdd) {
                    parent = this.graphProxy.getNode(o.data.parent);
                    this.graphProxy.addToParent(o.sprite, parent);
                }
                
                // Set listeners, styles, etc:
                graphMediator.initialize(Groups.NODES, newNodes);
                graphMediator.initialize(Groups.EDGES, newEdges);
                
                for each (o in childrenToAdd) {
                    parent = this.graphProxy.getNode(o.data.parent);
                    
                    if (parent != null) {
                        this.graphMediator.updateCompoundNode(parent);
                    }
                }
                
                // Do it before converting the Nodes/Edges to plain objects,
                // in order to get the rendered visual properties:
                if (updateVisualMappers)
                    sendNotification(ApplicationFacade.GRAPH_DATA_CHANGED);
                
                // Finally convert the items to a plain objects that can be returned:
                for each (newElement in newAll) {
                    o = ExternalObjectConverter.toExtElement(newElement, graphProxy.zoom);
                    ret.push(o);
                }
            } catch (err:Error) {
                trace("[ERROR]: addElements: " + err.getStackTrace());
                
                // Rollback--delete any new item:
                removeElements(Groups.NONE, newAll, updateVisualMappers);
                ret = [];
                
                error(err);
            }
            
            return JSON.encode(ret);
        }
        
        private function addNode(x:Number,
                                 y:Number,
                                 data:Object,
                                 updateVisualMappers:Boolean=false):String {
            var extObj:Object = null;
            var parentId:String = data != null ? data.parent : null;
            
            try {
                // create node (always create a CompoundNode instance)
                var ns:CompoundNodeSprite = graphProxy.addNode(data);
                var parent:CompoundNodeSprite = parentId != null ? graphProxy.getNode(parentId) : null;
                
                // position the node
                var p:Point = new Point(x, y);
                p = this.graphMediator.vis.globalToLocal(p);
                ns.x = p.x;
                ns.y = p.y;
                
                // set listeners, styles, etc.
                if (ns.isInitialized()) {
//                  // initialize the node as a compound node
//                  this.graphMediator.initialize(Groups.COMPOUND_NODES, [ns]);
                } else {
                    // initialize the node as a non-compound node
                    this.graphMediator.initialize(Groups.NODES, [ns]);
                }
                
                // update parent compound node if adding a node to another one
                if (parent != null) {
                    this.graphProxy.addToParent(ns, parent);
                    this.graphMediator.updateCompoundNode(parent);
                }
                
                if (updateVisualMappers) {
                    this.sendNotification(ApplicationFacade.GRAPH_DATA_CHANGED);
                }
                
                // convert to external object
                extObj = ExternalObjectConverter.toExtElement(ns, graphProxy.zoom);
            } catch (err:Error) {
                trace("[ERROR]: addNode: " + err.getStackTrace());
                error(err);
            }
            
            return JSON.encode(extObj);
        }
        
        private function addEdge(data:Object, updateVisualMappers:Boolean=false):String {
            var o:Object;
            
            try {
                // Create edge:
                var createdEdges:Array = graphProxy.addEdge(data);
                // Set listeners, styles, etc:
                graphMediator.initialize(Groups.EDGES, createdEdges);
                
                if (updateVisualMappers) sendNotification(ApplicationFacade.GRAPH_DATA_CHANGED);
                o = ExternalObjectConverter.toExtElement(createdEdges[0], graphProxy.zoom);
                
            } catch (err:Error) {
                trace("[ERROR]: addEdge: " + err.getStackTrace());
                error(err);
            }
            
            return JSON.encode(o);
        }
        
        private function removeElements(group:String=Groups.NONE,
                                        items:Array=null, 
                                        updateVisualMappers:Boolean=false):void {
            sendNotification(ApplicationFacade.REMOVE_ITEMS,
                             { group: group, items: items, updateVisualMappers: updateVisualMappers });
        }
        
        private function getDataSchema():String {
            var obj:Object = ExternalObjectConverter.toExtSchema(graphProxy.nodesSchema, graphProxy.edgesSchema);
            return JSON.encode(obj);
        }
        
        private function addDataField(group:String, dataField:Object):void {
            sendNotification(ApplicationFacade.ADD_DATA_FIELD, { group: group, dataField: dataField });
        }
        
        private function removeDataField(group:String, name:String):void {
            sendNotification(ApplicationFacade.REMOVE_DATA_FIELD, { group: group, name: name });
        }
        
        private function updateData(group:String, items:Array=null, data:Object=null):void {
            if (items != null || data != null)
                sendNotification(ApplicationFacade.UPDATE_DATA, { group: group, items: items, data: data });
        }
        
        private function getNetworkModel():String {
            var data:Object = graphProxy.graphData;
            var nodesSchema:DataSchema = graphProxy.nodesSchema;
            var edgesSchema:DataSchema = graphProxy.edgesSchema;
            
            var nodesTable:GraphicsDataTable = new GraphicsDataTable(data.nodes, nodesSchema);
            var edgesTable:GraphicsDataTable = new GraphicsDataTable(data.group(Groups.REGULAR_EDGES), edgesSchema);
            var ds:DataSet = new DataSet(nodesTable, edgesTable);
            
            var model:Object = ExternalObjectConverter.toExtNetworkModel(ds);
            
            return JSON.encode(model);
        }
        
        private function getNetworkAsText(format:String="xgmml", options:Object=null):String {
            var viewCenter:Point = graphMediator.getViewCenter();
            return graphProxy.getDataAsText(format, viewCenter, options);
        }
        
        private function getNetworkAsImage(format:String="pdf", options:Object=null):String {
            if (options == null) options = {};
            
            var appMediator:ApplicationMediator = facade.retrieveMediator(ApplicationMediator.NAME) as ApplicationMediator;
            var img:* = appMediator.getGraphImage(format, options.width, options.height);
            
            if (img is ByteArray) {
                var encoder:Base64Encoder = new Base64Encoder();
                encoder.encodeBytes(img);
                img = encoder.toString();
            }

            return "" + img;
        }
        
        private function exportNetwork(format:String, url:String, options:Object=null):void {
            sendNotification(ApplicationFacade.EXPORT_NETWORK, { format: format, url: url, options: options });
        }

        // ------------------------------------------------------------
        
        private function addCallbacks():void {
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
                                        "enableCustomCursors", "isCustomCursorsEnabled",
                                        "enableGrabToPan", "isGrabToPanEnabled", "panBy", "panToCenter", 
                                        "zoomTo", "zoomToFit", "getZoom", 
                                        "filter", "removeFilter", 
                                        "firstNeighbors", 
                                        "getNodes", "getParentNodes", "getChildNodes",
                                        "getEdges", "getMergedEdges", 
                                        "getNodeById", "getEdgeById",
                                        "getSelectedNodes", "getSelectedEdges", 
                                        "getLayout", "applyLayout", 
                                        "setVisualStyle", "getVisualStyle", 
                                        "getVisualStyleBypass", "setVisualStyleBypass",
                                        "addElements", "addNode", "addEdge", "removeElements",
                                        "getDataSchema", "addDataField", "removeDataField", "updateData",
                                        "getNetworkModel", "getNetworkAsText", "getNetworkAsImage", 
                                        "exportNetwork" ];

                for each (var f:String in functions) addFunction(f);

            } else {
                sendNotification(ApplicationFacade.EXT_INTERFACE_NOT_AVAILABLE);
            }
        }
        
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
