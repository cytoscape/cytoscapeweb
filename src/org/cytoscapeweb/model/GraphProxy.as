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
	import flare.data.DataField;
	import flare.data.DataSchema;
	import flare.data.DataSet;
	import flare.data.DataTable;
	import flare.data.DataUtil;
	import flare.vis.data.Data;
	import flare.vis.data.DataList;
	import flare.vis.data.DataSprite;
	import flare.vis.data.EdgeSprite;
	import flare.vis.data.NodeSprite;
	
	import flash.net.URLRequest;
	import flash.net.URLRequestHeader;
	import flash.net.URLRequestMethod;
	import flash.net.navigateToURL;
	import flash.utils.IDataOutput;
	
	import mx.utils.StringUtil;
	
	import org.cytoscapeweb.ApplicationFacade;
	import org.cytoscapeweb.model.converters.GraphMLConverter;
	import org.cytoscapeweb.model.converters.SIFConverter;
	import org.cytoscapeweb.model.converters.XGMMLConverter;
	import org.cytoscapeweb.model.data.ConfigVO;
	import org.cytoscapeweb.model.data.GraphicsDataTable;
	import org.cytoscapeweb.model.data.InteractionVO;
	import org.cytoscapeweb.model.data.VisualStyleVO;
	import org.cytoscapeweb.util.Groups;
	import org.cytoscapeweb.util.Layouts;
	import org.puremvc.as3.patterns.proxy.Proxy;
	
    [Bindable]
    public class GraphProxy extends Proxy {

        // ========[ CONSTANTS ]====================================================================

        public static const NAME:String = 'GraphProxy';

        // ========[ PRIVATE PROPERTIES ]===========================================================

        private var _interactions:/*key->InteractionVO*/Object;
        private var _parentEdges:/*regularEdge->mergedEdgeSprite*/Object;
        private var _rolledOverNode:NodeSprite;
        private var _rolledOverEdge:EdgeSprite;
        private var _nodesMap:Object = {};
        private var _edgesMap:Object = {};
        // Scale factor, between 0 and 1:
        private var _zoom:Number = 1;

        private var _configProxy:ConfigProxy;
        
        private function get configProxy():ConfigProxy {
            if (_configProxy == null)
                _configProxy = facade.retrieveProxy(ConfigProxy.NAME) as ConfigProxy;
            return _configProxy;
        }
        
        private function get config():ConfigVO {
            return configProxy.config;
        }

        // ========[ PUBLIC PROPERTIES ]============================================================
        
        public var dataSet:DataSet;
        
        public function get graphData():Data {
            return data as Data;
        }
        
        public override function setData(data:Object):void {
            super.setData(data);
            
            if (data != null) {
                // Add missing Ids:
                setIdentifiers(data.nodes);
                createInteractions();
                createMergedEdges();
                setIdentifiers(data.edges);
                
                // TODO: do we really need these Flare groups?
                // Add data groups to house selected nodes and edges:
                data.addGroup(Groups.SELECTED_NODES);
                data.addGroup(Groups.SELECTED_EDGES);
                
                // Create a mapping of nodes and edges, with their IDs as key,
                // in order to make it easier to get them later:
                _nodesMap = {};
                for each (var n:NodeSprite in data.nodes) _nodesMap[n.data.id] = n;
                _edgesMap = {};
                for each (var e:EdgeSprite in data.edges) _edgesMap[e.data.id] = e;
            }
                
            sendNotification(ApplicationFacade.GRAPH_DATA_CHANGED, data);
        }
        
        public function get nodesSchema():DataSchema {
            if (dataSet != null) {
                return dataSet.nodes.schema;
            }
            return null;
        }
        
        public function get edgesSchema():DataSchema {
            if (dataSet != null) {
                return dataSet.edges.schema;
            }
            return null;
        }
        
        /**
         * @return All edges, except the merged ones. 
         */
        public function get edges():Array {
            // TODO: cache it (use data groups???)
            var arr:Array = [];
            
            for each (var e:EdgeSprite in graphData.edges) {
                // Ignore the ones used to represent merged edges:
                if (!e.props.$merged) arr.push(e);
            }
            
            return arr;
        }
        
        public function get nodes():Array {
            var arr:Array = [];
            for each (var n:NodeSprite in graphData.nodes) arr.push(n);
            return arr;
        }
        
        /**
         * @return The merged edges only. 
         */
        public function get mergedEdges():Array {
            var arr:Array = [];
            
            var list:DataList = graphData.group(Groups.MERGED_EDGES);
            for each (var e:EdgeSprite in list) arr.push(e);
            
            return arr;
        }

        public function get filteredNodes():Array {
            var arr:Array = null;
            var list:DataList = graphData.group(Groups.FILTERED_NODES);
            if (list != null) {
                arr = [];
                for each (var n:NodeSprite in list) arr.push(n);
            }
            return arr;
        }

        /**
         * @param value Array of edge data objects. 
         */
        public function set filteredNodes(value:Array):void {
            var list:DataList = graphData.group(Groups.FILTERED_NODES);
            var n:NodeSprite;
            
            if (list == null && value != null) {
                list = graphData.addGroup(Groups.FILTERED_NODES);
            }

            for each (n in graphData.nodes) {
                n.props.$filteredOut = value != null;
                if (value != null) list.remove(n);
            }
            for each (n in value) {
                n.props.$filteredOut = false;
                list.add(n);
            }
            if (value == null) graphData.removeGroup(Groups.FILTERED_NODES);
        }

        public function get filteredEdges():Array {
            var arr:Array = null;
            var list:DataList = graphData.group(Groups.FILTERED_EDGES);
            if (list != null) {
                arr = [];
                for each (var e:EdgeSprite in list) arr.push(e);
            }
            return arr;
        }

        /**
         * @param value Array of edge data objects. 
         */
        public function set filteredEdges(value:Array):void {
            var list:DataList = graphData.group(Groups.FILTERED_EDGES);
            var e:EdgeSprite;
        	
        	if (list == null && value != null) {
                list = graphData.addGroup(Groups.FILTERED_EDGES);
            }
        	
            for each (e in graphData.edges) {
                e.props.$filteredOut = value != null;
                if (value != null) list.remove(e);
            }
            
	        if (value != null) {
                for each (e in value) {
                    e.props.$filteredOut = false;
                    list.add(e);
                }
	        }
	        
	        for each (e in graphData.edges) {
    	        if (e.props.$merged) {
                    for each (var ee:EdgeSprite in e.props.$edges) {
                        if (!ee.props.$filteredOut) {
                            e.props.$filteredOut = false;
                            break;
                        }
                    }
                }
            }
            
            if (value == null) graphData.removeGroup(Groups.FILTERED_EDGES);
            
            updateMergedEdgesSelection();
            updateMergedEdgesData(graphData.group(Groups.MERGED_EDGES));
        }

        public function get edgesMerged():Boolean {
            return config.edgesMerged;
        }
        
        public function get rolledOverNode():NodeSprite {
            return _rolledOverNode;
        }
 
        public function set rolledOverNode(node:NodeSprite):void {
            if (_rolledOverNode != node) {
	            if (_rolledOverNode != null) _rolledOverNode.props.$hover = false;
                if (node != null) node.props.$hover = true;
                _rolledOverNode = node;
	        }
        }
        
        public function get selectedNodes():Array {
        	var arr:Array = [];
        	var list:DataList = graphData.group(Groups.SELECTED_NODES);
        	for each (var n:NodeSprite in list) arr.push(n);

            return arr;
        }
        
        public function get selectedEdges():Array {
            var arr:Array = [];
            var list:DataList = graphData.group(Groups.SELECTED_EDGES);           
            for each (var e:EdgeSprite in list) arr.push(e);
            
            return arr;
        }
        
        public function get selectedMergedEdges():Array {
            var arr:Array = [];
            for each (var e:EdgeSprite in graphData.edges) {
                if (e.props.$merged && e.props.$selected) arr.push(e);
            }
            
            return arr;
        }
        
        public function get rolledOverEdge():EdgeSprite {
            return _rolledOverEdge;
        }
 
        public function set rolledOverEdge(edge:EdgeSprite):void {
            if (_rolledOverEdge != edge) {
                if (_rolledOverEdge != null) _rolledOverEdge.props.$hover = false;
                if (edge != null) edge.props.$hover = true;
                _rolledOverEdge = edge;
            }
        }
        
        public function get zoom():Number {
            return _zoom;
        }
 
        public function set zoom(value:Number):void {
            _zoom = value;
        }

        // ========[ CONSTRUCTOR ]==================================================================

        public function GraphProxy() {
            super(NAME);
        }

        // ========[ PUBLIC METHODS ]===============================================================

        public function getInteraction(node1:NodeSprite, node2:NodeSprite):InteractionVO {
            var inter:InteractionVO = null;
            
            if (_interactions != null) {
                var k:String = InteractionVO.createKey(node1, node2);
                inter = _interactions[k];
            }
            
            return inter;
        }

        public function addDataField(group:String, name:String, type:int, defValue:Object=null):Boolean {
            var added:Boolean = false;
            
            if (group == null || group === Groups.NONE) {
                added = addDataField(Groups.NODES, name, type, defValue);
                added = addDataField(Groups.EDGES, name, type, defValue) || added;
            } else {
                name = StringUtil.trim(name);
                var schema:DataSchema = group === Groups.NODES ? nodesSchema : edgesSchema;
                
                if (schema.getFieldById(name) == null) {
                    // This field is not duplicated...
                    var field:DataField = new DataField(name, type, defValue);
                    schema.addField(field);
                    added = true;
                    
                    // Update nodes/edges data
                    var items:Array = group === Groups.NODES ? nodes : edges;
                    for each (var ds:DataSprite in items) {
                        ds.data[field.name] = field.defaultValue;
                    }
                }
            }
            
            return added;
        }
        
        public function removeDataField(group:String, name:String):Boolean {
            var removed:Boolean = false;

            if (group == null || group === Groups.NONE) {
                removed = removeDataField(Groups.NODES, name);
                removed = removeDataField(Groups.EDGES, name) || removed;
            } else {
                name = StringUtil.trim(name);
                if ( name != "id" && name != "label" &&
                    !(group === Groups.EDGES && (name === "source" || 
                                                 name === "target" || 
                                                 name === "directed")) ) {
                
                    var schema:DataSchema = group === Groups.NODES ? nodesSchema : edgesSchema;
                    
                    // No method to delete a data field? :-(
                    // So let's just create a new schema:
                    var newSchema:DataSchema = new DataSchema();
                    var fields:Array = schema.fields;

                    for each (var df:DataField in fields) {
                        if (df.name != name)
                            newSchema.addField(df);
                        else 
                            removed = true;
                    }
                    
                    if (removed) {
                        // Update the Data Set:
                        if (group === Groups.NODES)
                            dataSet.nodes.schema = newSchema;
                        else
                            dataSet.edges.schema = newSchema;
                        
                        // Update nodes/edges data
                        var items:Array = group === Groups.NODES ? nodes : edges;
                        for each (var ds:DataSprite in items) {
                            delete ds.data[name];
                        }
                    }
                }
            }
            
            return removed;
        }
        
        public function updateData(ds:DataSprite, data:Object):void {
            if (ds != null && data != null) {
                for (var k:String in data) {
                    if ( ds.data[k] !== undefined && k !== "id" &&
                        !(ds is EdgeSprite && (k === "source" || k === "target")) )
                        ds.data[k] = data[k];
                }
            }
        }

        public function getDataSpriteList(objList:Array, group:String=null, mergeData:Boolean=false):Array {
        	var list:Array = null;
        	if (group == null) group = Groups.NONE;
        	
            if (objList != null) {
                list = [];
                
                var push:Function = function (ds:DataSprite, d:Object):void {
                    if (ds != null) {
                        list.push(ds);
                        if (mergeData) updateData(ds, d);
                    }
                };
                
                for each (var obj:* in objList) {
                    if (obj != null) {
	                    var id:* = obj;
	                    var gr:String = group;
	                    var data:Object = null;
	                    
	                    if (obj && obj.hasOwnProperty("data") && obj.data.id) {
	                       data = obj.data;
	                       id = data.id;
	                    }
	                    if (group === Groups.NONE && obj.hasOwnProperty("group"))
	                       gr = obj.group;

	    	            // If an edge and a node has the same requested id and group is NONE,
	    	            // both are included:
	    	            if (gr === Groups.NODES || gr === Groups.NONE) {
	        	            push(_nodesMap[id], data);
	        	        }
	    	            if (gr === Groups.EDGES || gr === Groups.NONE) {
	        	            push(_edgesMap[id], data);
	        	        }
                    }
                }
            }
            
            return list;
        }
        
        /**
         * @return The nodes that were actually selected.
         */
        public function addSelectedNodes(nodes:Array):Array {
            var selected:Array = [];
            
            if (nodes != null && nodes.length > 0) {
                var list:DataList = graphData.group(Groups.SELECTED_NODES);
                
                for each (var n:NodeSprite in nodes) {
	                if (!list.contains(n)) {
                        n.props.$selected = true;
                        list.add(n);
                        selected.push(n);
                    }
                }
            }
            
            return selected;
        }
        
        /**
         * @return The nodes that were actually deselected.
         */
        public function removeSelectedNodes(nodes:Array):Array {
            var deselected:Array = [];
            
            if (nodes != null && nodes.length > 0) {
                var list:DataList = graphData.group(Groups.SELECTED_NODES);
                
                for each (var n:NodeSprite in nodes) {
                    if (list.contains(n)) {
                        n.props.$selected = false;
                        list.remove(n);
                        deselected.push(n);
                    }
                }
            }
            
            return deselected;
        }
        
        /**
         * @param edges Array of edges (they can be merged edges as well).
         * @return The edges that were actually selected (does NOT contain any merged edge).
         */
        public function addSelectedEdges(edges:Array):Array {
            var selected:Array = [];
            var bundled:Array = [];
            
            if (edges != null && edges.length > 0) {
                var list:DataList = graphData.group(Groups.SELECTED_EDGES);

                for each (var e:EdgeSprite in edges) {
                    if (e.props.$merged) {
                        // If this is a merged edge, select its bundled edges instead:
                        for each (var ee:EdgeSprite in e.props.$edges) {
                            if (!ee.props.$filteredOut) bundled.push(ee);
                        }
                    } else if (!list.contains(e)) {
                        e.props.$selected = true;
                        list.add(e);
                        selected.push(e);
                    }
                }
                
                if (bundled.length > 0) {
                    selected = selected.concat(addSelectedEdges(bundled));
                }      
                updateMergedEdgesSelection();      
            }
            
            return selected;
        }
        
        public function remove(items:Array):void {
            // Remove event listeners:
            for each (var ds:DataSprite in items) {
                if (ds is NodeSprite) {
                    removeNode(NodeSprite(ds));
                } else {
                    removeEdge(EdgeSprite(ds));
                }
            }
        }
        
        public function removeNode(n:NodeSprite):void {
            if (n == null) return;
            delete _nodesMap[n.data.id];
            
            if (n.props.$selected) graphData.group(Groups.SELECTED_NODES).remove(n);
            
            var filterList:DataList = graphData.group(Groups.FILTERED_NODES);
            if (filterList != null) filterList.remove(n);
       
            // Also remove its linked edges:
            var edges:Array = [];
            n.visitEdges(function(e:EdgeSprite):Boolean {
                edges.push(e);
                return false;
            });
            remove(edges);
            
            graphData.removeNode(n);
        }
        
        public function removeEdge(e:EdgeSprite):void {
            if (e == null) return;
            delete _edgesMap[e.data.id];
            
            if (e.props.$selected) graphData.group(Groups.SELECTED_EDGES).remove(e);
            
            graphData.removeEdge(e);
            
            if (e.props.$merged) {
                graphData.group(Groups.MERGED_EDGES).remove(e);
                // Delete children ("regular") edges:
                var children:Array = e.props.$edges;
                if (children.length > 0) remove(children);
            } else {
                graphData.group(Groups.REGULAR_EDGES).remove(e);
                
                var filterList:DataList = graphData.group(Groups.FILTERED_EDGES);
                if (filterList != null) filterList.remove(e);
                
                // Update or delete its merged edge:
                var parent:EdgeSprite = _parentEdges[e];
                if (parent != null) {
                    delete _parentEdges[e];
                    var edges:Array = parent.props.$edges;
                    var newEdges:Array = [];
                    for each (var ee:EdgeSprite in edges) {
                        if (_edgesMap[ee.data.id] != null) newEdges.push(ee);
                    }
                    parent.props.$edges = newEdges;
                    if (newEdges.length === 0) removeEdge(parent);
                    else updateMergedEdgesData([parent]);
                }
                // TODO: Update the sibling edges index:
                var inter:InteractionVO = getInteraction(e.source, e.target);
                if (inter != null) {
                    if (_nodesMap[e.source.data.id] != null && _nodesMap[e.target.data.id] != null)
                        inter.update();
                    else
                        delete _interactions[inter.key];
                }
            }
        }
        
        /**
         * @param edges Array of edges (they can be merged edges as well).
         * @return The edges that were actually deselected (does NOT contain any "fake" merged edge).
         */
        public function removeSelectedEdges(edges:Array):Array {
            var deselected:Array = [];
            var bundled:Array = [];
            
            if (edges != null && edges.length > 0) {
                var list:DataList = graphData.group(Groups.SELECTED_EDGES);
                
                for each (var e:EdgeSprite in edges) {
                    if (e.props.$merged) {
                        // If this is a merged edge, deselect its referenced edges instead:
                        for each (var ee:EdgeSprite in e.props.$edges) {
                            if (!ee.props.$filteredOut) bundled.push(ee);
                        }
                    } else if (list.contains(e)) {
                        e.props.$selected = false;
                        list.remove(e);
                        deselected.push(e);
                    }
                }
                
                if (bundled.length > 0) {
                    deselected = deselected.concat(removeSelectedEdges(bundled));       
                }
                updateMergedEdgesSelection();
            }
            
            return deselected;
        }

        public function loadGraph(options:Object):void {
        	var txt:String = options.network;
            var empty:Boolean = (txt == null || StringUtil.trim(txt) === "");
            
            if (!empty) {
                try {
                    var xml:XML = new XML(txt);
                    var ds:DataSet;
                    
                    if (xml != null && xml.name() != null) {
                        var isGraphml:Boolean = xml.name().localName === GraphMLConverter.GRAPHML;
                        
                        if (isGraphml) {
                            // GraphML:
                            ds = new GraphMLConverter().parse(xml);
                        } else {
                            // XGMML:
                            var style:VisualStyleVO = configProxy.visualStyle;
                            
                            var xgmmlConverter:XGMMLConverter = new XGMMLConverter(style);
                            ds = xgmmlConverter.parse(xml);
                            
                            var points:Object = xgmmlConverter.points;
                            if (points != null) {
                                // TODO: do not force the preset layout??? Users might want to load an XGMML with another layout!
                                config.currentLayout = Layouts.PRESET;
                                config.nodesPoints = points;
                            }
                        }
                    } else {
                        // SIF:
                        ds = new SIFConverter().parse(txt);
                    }
                    dataSet = ds;
                    setData(Data.fromDataSet(ds));
                } catch (err:Error) {
                    trace("[ERROR]: onLoadGraph_result: " + err.getStackTrace());
                    throw err;
                }
            } else {
                throw new Error("Cannot load network: data is empty!");
            }
        }
        
        public function getDataAsText(format:String="xgmml", options:Object=null):String {
            var out:IDataOutput, nodesTable:DataTable, edgesTable:DataTable, dtSet:DataSet;
            format = StringUtil.trim(format.toLowerCase());
                        
            if (format === "xgmml") {
                nodesTable = new GraphicsDataTable(graphData.nodes, dataSet.nodes.schema);
                edgesTable = new GraphicsDataTable(graphData.group(Groups.REGULAR_EDGES), dataSet.edges.schema);
                dtSet = new DataSet(nodesTable, edgesTable);
                out = new XGMMLConverter(configProxy.visualStyle).write(dtSet);
            } else {
                nodesTable = new DataTable(graphData.nodes.toDataArray(), dataSet.nodes.schema);
                edgesTable = new DataTable(graphData.group(Groups.REGULAR_EDGES).toDataArray(), dataSet.edges.schema);
                dtSet = new DataSet(nodesTable, edgesTable);

                if (format === "graphml") {
                    out = new GraphMLConverter().write(dtSet);
                } else {
                    var interaction:String =  options != null ? options.interactionAttr : null;
                    out = new SIFConverter(interaction).write(dtSet);
                }
            }

            return "" + out;
        }

        /**
         * Send the the network data to a URL.
         */
        public function export(data:Object, url:String, window:String="_self"):void {
        	var request:URLRequest = new URLRequest(url);
            var header:URLRequestHeader = new URLRequestHeader("Content-type", "application/octet-stream");
            request.requestHeaders.push(header);
            request.method = URLRequestMethod.POST;
            request.data = data;
            navigateToURL(request, window);
        }
        
        // ========[ PRIVATE METHODS ]==============================================================
        
        /**
         * Set a unique number to missing nodes or edges IDs.  
         */
        private function setIdentifiers(list:*):void {
        	if (list != null) {
                var ids:Object = {};
                var count:int = 1;
    			
        		var sp:DataSprite;
        		// 1rs iteration: get existing IDs:
        		for each (sp in list) {
        			if (sp.data.id != null) ids[""+sp.data.id] = true;
        		}
        		// 2nd iteration: set missing IDs:
                for each (sp in list) {
                    if (sp.data.id == null) {
                    	while (ids[count.toString()]) ++count;
                        sp.data.id = count.toString();
                        count++;
                    }
                }
            }
        }
        
        private function createInteractions():void {
            _interactions = new Object();
            var inter:InteractionVO;
            
            if (graphData != null) {
                for each (var edge:EdgeSprite in graphData.edges) {
                    inter = getInteraction(edge.source, edge.target);
                    
                    if (inter == null) {
                        inter = new InteractionVO(edge.source, edge.target);
                        _interactions[inter.key] = inter;
                    }
                    
                    inter.addEdge(edge);
                }

                for (var k:String in _interactions) {
                    inter = _interactions[k];
                    for each (var e:EdgeSprite in inter.edges) {
                        // It will be important to correctly render multiple edges:
                        e.props.adjacentIndex = inter.getAdjacentIndex(e);
                    }
                }
            }
        }
        
        private function createMergedEdges():void {
            var reList:DataList = new DataList(Groups.REGULAR_EDGES);
            graphData.addGroup(Groups.REGULAR_EDGES, reList);
            
            var meList:DataList = new DataList(Groups.MERGED_EDGES);
            graphData.addGroup(Groups.MERGED_EDGES, meList);
            
            _parentEdges = {};
            
            for (var k:String in _interactions) {
                var inter:InteractionVO = _interactions[k];
                var edges:Array = inter.edges;
                
                // Create a fake merged edge:
                var src:NodeSprite = inter.node1;
                var tgt:NodeSprite = inter.node2;
                var dt:Object = { source: src.data.id, target: tgt.data.id };
                var me:EdgeSprite = graphData.addEdgeFor(src, tgt, false, dt);
                me.data.directed = false;
                me.props.$merged = true;
                me.props.$edges = edges;
                me.props.$getDataList = function():Array {
                    var dataList:Array = [];
                    for each (var e:EdgeSprite in this.$edges) {
                        if (!e.props.$filteredOut) dataList.push(e.data);
                    }
                    return dataList;
                }
                me.props.$getFilteredEdges = function():Array {
                    var filteredList:Array = [];
                    for each (var e:EdgeSprite in this.$edges) {
                        if (!e.props.$filteredOut) filteredList.push(e);
                    }
                    return filteredList;
                }
                
                meList.add(me);
                for each (var e:EdgeSprite in edges) {
                    _parentEdges[e] = me;
                    // Separate the regular edges in another list, because data.edges will have both
                    // regular and merged ones:
                    reList.add(e);
                }
            }

            updateMergedEdgesData(graphData.group(Groups.MERGED_EDGES));
        }
        
        private function updateMergedEdgesData(edges:*):void {
            var fields:Array = dataSet.edges.schema.fields;
            var numericFields:Array = [];
            var df:DataField;
            
            for each (df in fields) {
                if ((df.type === DataUtil.NUMBER || df.type === DataUtil.INT) && df.name !== "id")
                    numericFields.push(df);
            }

            for each (var edge:EdgeSprite in edges) {
                if (!edge.props.$merged) continue;
                
                // Create sum and avg data values for numeric attributes:
                for each (df in numericFields) {
                    edge.data["sum:"+df.name] = edge.data["avg:"+df.name] = 0;
                }
                
                var count:Number = 0;
                
                for each (var e:EdgeSprite in edge.props.$edges) {
                    if (!e.props.$filteredOut) {
                        count++;
                        for each (df in numericFields) {
                            var v:Number = e.data[df.name] as Number;
                            edge.data["sum:"+df.name] = edge.data["avg:"+df.name] += v;
                        }
                    }
                }
                for each (df in numericFields) {
                    if (count > 1) edge.data["avg:"+df.name] /= count;
                    if (df.type === DataUtil.INT) {
                        edge.data["sum:"+df.name] = Math.round(edge.data["sum:"+df.name]);
                        edge.data["avg:"+df.name] = Math.round(edge.data["avg:"+df.name]);
                    }
                }
            }
        }
        
        private function updateMergedEdgesSelection():void {
            for each (var e:EdgeSprite in graphData.edges) {
                if (e.props.$merged) e.props.$selected = isMergedEdgeSelected(e);
            }
        }
        
        private function isMergedEdgeSelected(edge:EdgeSprite):Boolean {
            if (edge.props.$edges) {
                for each (var e:EdgeSprite in edge.props.$edges) {
                    if (e.props.$selected && !e.props.$filteredOut) return true;
                }
            }
            return false;
        }
    }
}
