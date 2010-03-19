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
        
        public static const GRP_SELECTED_NODES:String = "selectedNodes";
        public static const GRP_SELECTED_EDGES:String = "selectedEdges";
        public static const GRP_REGULAR_EDGES:String = "regularEdges";
        public static const GRP_MERGED_EDGES:String = "mergedEdges";

        // ========[ PRIVATE PROPERTIES ]===========================================================

        private var _graphData:Data;
        private var _interactions:/*key->InteractionVO*/Object;
        private var _parentEdges:/*regularEdgeId->mergedEdgeSprite*/Object;
        private var _rolledOverNode:NodeSprite;
        private var _rolledOverEdge:EdgeSprite;
        private var _filteredNodes:Array;
        private var _filteredEdges:Array;
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
            return _graphData;
        }
        
        public function set graphData(data:Data):void {
            this._graphData = data;
            
            if (data != null) {
                // Add missing Ids:
                setIdentifiers(data.nodes);
                createInteractions();
                createMergedEdges();
                setIdentifiers(data.edges);
                
                // TODO: do we really need these Flare groups?
                // Add data groups to house selected nodes and edges:
                data.addGroup(GraphProxy.GRP_SELECTED_NODES);
                data.addGroup(GraphProxy.GRP_SELECTED_EDGES);
                
                // Create a mapping of nodes and edges, with their IDs as key,
                // in order to make it easier to get them later:
                _nodesMap = {};
                for each (var n:NodeSprite in data.nodes) _nodesMap[n.data.id] = n;
                _edgesMap = {};
                for each (var e:EdgeSprite in data.edges) _edgesMap[e.data.id] = e;
            }
                
            sendNotification(ApplicationFacade.GRAPH_DATA_CHANGED, data);
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
            
            for each (var n:NodeSprite in graphData.nodes) {
                arr.push(n);
            }
            
            return arr;
        }
        
        /**
         * @return The merged edges only. 
         */
        public function get mergedEdges():Array {
            var arr:Array = [];
            
            var list:DataList = graphData.group(GRP_MERGED_EDGES);           
            for each (var e:EdgeSprite in list) arr.push(e);
            
            return arr;
        }

        public function get filteredNodes():Array {
            return _filteredNodes;
        }

        /**
         * @param value Array of edge data objects. 
         */
        public function set filteredNodes(value:Array):void {
            if (_filteredNodes != value) {
                _filteredNodes = value;
                
                for each (var n:NodeSprite in graphData.nodes) n.props.$filteredOut = value != null;
                if (value != null) {
                    for each (n in value) n.props.$filteredOut = false;
                }
            }
        }

        public function get filteredEdges():Array {
            return _filteredEdges;
        }

        /**
         * @param value Array of edge data objects. 
         */
        public function set filteredEdges(value:Array):void {
        	if (_filteredEdges != value) {
	            _filteredEdges = value;
	            
                for each (var e:EdgeSprite in graphData.edges) {
                    e.props.$filteredOut = value != null;
                }
                
    	        if (value != null) {
                    for each (e in value) e.props.$filteredOut = false;
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
	            
	            updateMergedEdgesSelection();
	            updateMergedEdgesData();
	        }
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
        	var list:DataList = graphData.group(GRP_SELECTED_NODES);
        	for each (var n:NodeSprite in list) arr.push(n);

            return arr;
        }
        
        public function get selectedEdges():Array {
            var arr:Array = [];
            var list:DataList = graphData.group(GRP_SELECTED_EDGES);           
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

        public function getDataSpriteList(objList:Array, group:String=null):Array {
        	var list:Array = null;
        	if (group == null) group = Groups.NONE;
        	
            if (objList != null) {
                list = [];
                for each (var obj:* in objList) {
                    if (obj != null) {
	                    var id:* = obj;
	                    var gr:String = group;
	                    
	                    if (obj && obj.hasOwnProperty("data") && obj.data.id)
	                       id = obj.data.id;
	                    if (group === Groups.NONE && obj.hasOwnProperty("group"))
	                       gr = obj.group;
	                    
	    	            var ds:DataSprite = null;
	    	            if (gr === Groups.NODES || gr === Groups.NONE) {
	        	            ds = _nodesMap[id];
	        	            if (ds != null) list.push(ds);
	        	        }
	    	            if (ds == null && (gr === Groups.EDGES || gr === Groups.NONE)) {
	        	            ds = _edgesMap[id];
	        	            if (ds != null) list.push(ds);
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
                var list:DataList = graphData.group(GRP_SELECTED_NODES);
                
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
                var list:DataList = graphData.group(GRP_SELECTED_NODES);
                
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
                var list:DataList = graphData.group(GRP_SELECTED_EDGES);

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
        
        /**
         * @param edges Array of edges (they can be merged edges as well).
         * @return The edges that were actually deselected (does NOT contain any "fake" merged edge).
         */
        public function removeSelectedEdges(edges:Array):Array {
            var deselected:Array = [];
            var bundled:Array = [];
            
            if (edges != null && edges.length > 0) {
                var list:DataList = graphData.group(GRP_SELECTED_EDGES);
                
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
                    graphData = Data.fromDataSet(ds);
                } catch (err:Error) {
                    trace("[ERROR]: onLoadGraph_result: " + err.getStackTrace());
                    throw err;
                }
            } else {
                throw new Error("Cannot load network: data is empty!");
            }
        }
        
        public function getDataAsText(format:String="xgmml"):String {
            var out:IDataOutput, nodesTable:DataTable, edgesTable:DataTable, dtSet:DataSet;
            var edges:DataList = new DataList(Data.EDGES);
            var edgesData:Array = [];
            
            // Use only real edges (not the merged ones):
            for each (var e:EdgeSprite in graphData.edges) {
                if (!e.props.$merged) {
                    edges.add(e);
                    edgesData.push(e.data);
                }
            }
            
            format = StringUtil.trim(format.toLowerCase());
                        
            if (format === "xgmml") {
                nodesTable = new GraphicsDataTable(graphData.nodes, dataSet.nodes.schema);
                edgesTable = new GraphicsDataTable(edges, dataSet.edges.schema);
                dtSet = new DataSet(nodesTable, edgesTable);
                out = new XGMMLConverter(configProxy.visualStyle).write(dtSet);
            } else {
                nodesTable = new DataTable(graphData.nodes.toDataArray(), dataSet.nodes.schema);
                edgesTable = new DataTable(edgesData, dataSet.edges.schema);
                dtSet = new DataSet(nodesTable, edgesTable);

                if (format === "graphml") {
                    out = new GraphMLConverter().write(dtSet);
                } else {
                    // SIF
                    out = new SIFConverter().write(dtSet);
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
            var reList:DataList = new DataList(GraphProxy.GRP_REGULAR_EDGES);
            graphData.addGroup(GraphProxy.GRP_REGULAR_EDGES, reList);
            
            var meList:DataList = new DataList(GraphProxy.GRP_MERGED_EDGES);
            graphData.addGroup(GraphProxy.GRP_MERGED_EDGES, meList);
            
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
                    _parentEdges[e.data.id] = me;
                    // Separate the regular edges in another list, because data.edges will have both
                    // regular and merged ones:
                    reList.add(e);
                }
            }

            updateMergedEdgesData();
        }
        
        private function updateMergedEdgesData():void {
            var fields:Array = dataSet.edges.schema.fields;
            var numericFields:Array = [];
            var df:DataField;
            
            for each (df in fields) {
                if ((df.type === DataUtil.NUMBER || df.type === DataUtil.INT) && df.name !== "id")
                    numericFields.push(df);
            }

            for each (var edge:EdgeSprite in graphData.edges) {
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
