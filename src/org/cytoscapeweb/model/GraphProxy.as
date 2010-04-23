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

        private var _nodesSchema:DataSchema;
        private var _edgesSchema:DataSchema;

        private var _ids:Object;
        private var _nodesMap:Object;
        private var _edgesMap:Object;
        private var _interactions:/*key->InteractionVO*/Object;
        
        private var _rolledOverNode:NodeSprite;
        private var _rolledOverEdge:EdgeSprite;
        
        /** Scale factor, between 0 and 1 */
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
        
        public function get graphData():Data {
            return data as Data;
        }
        
        public override function setData(data:Object):void {
            super.setData(data);

            _ids = { "nodes": 1, "edges": 1 };
            _nodesMap = {};
            _edgesMap = {};
            _interactions = {};
            data.addGroup(Groups.SELECTED_NODES);
            data.addGroup(Groups.SELECTED_EDGES);
            data.addGroup(Groups.REGULAR_EDGES);
            data.addGroup(Groups.MERGED_EDGES);
            
            if (data != null) {
                // Add missing Ids:
                cacheItems(data.nodes);
                cacheItems(data.edges);
                createMergedEdges();
            }
                
            sendNotification(ApplicationFacade.GRAPH_DATA_CHANGED, data);
        }
        
        public function get nodesSchema():DataSchema {
            return _nodesSchema;
        }
        
        public function get edgesSchema():DataSchema {
            return _edgesSchema;
        }
        
        /**
         * @return All edges, except the merged ones. 
         */
        public function get edges():Array {
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
	        
	        for (var key:String in _interactions) {
    	        var inter:InteractionVO = _interactions[key];
    	        inter.update();
            }
            
            if (value == null) graphData.removeGroup(Groups.FILTERED_EDGES);
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

        public function GraphProxy(ds:DataSet=null) {
            super(NAME);
            
            if (ds != null) {
                _nodesSchema = ds.nodes.schema;
                _edgesSchema = ds.edges.schema;
                var data:Data = Data.fromDataSet(ds);
                setData(data);
            }
        }

        // ========[ PUBLIC METHODS ]===============================================================

        public function getNode(id:String):NodeSprite {
            return _nodesMap[id];
        }
        
        public function getEdge(id:String):EdgeSprite {
            return _edgesMap[id];
        }
        
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
                            _nodesSchema = newSchema;
                        else
                            _edgesSchema = newSchema;
                        
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
	        	            push(getNode(id), data);
	        	        }
	    	            if (gr === Groups.EDGES || gr === Groups.NONE) {
	        	            push(getEdge(id), data);
	        	        }
                    }
                }
            }
            
            return list;
        }
        
        /**
         * @param nodes Array of nodes to select or deselect.
         * @param select true to select the nodes or false to deselect them.
         * @return The nodes that were actually changed.
         */
        public function changeNodesSelection(nodes:Array, select:Boolean):Array {
            var changed:Array = [];
            
            if (nodes != null && nodes.length > 0) {
                var list:DataList = graphData.group(Groups.SELECTED_NODES);
                
                for each (var n:NodeSprite in nodes) {
	                if (n.props.$selected !== select) {
                        n.props.$selected = select;
                        if (select) list.add(n)
                        else list.remove(n);
                        changed.push(n);
                    }
                }
            }
            
            return changed;
        }
        
        /**
         * @param edges Array of edges (they can be merged edges as well).
         * @param select true to select the edges or false to deselect them.
         * @return The edges that were actually changed (does NOT contain any merged edge).
         */
        public function changeEdgesSelection(edges:Array, select:Boolean):Array {
            var changed:Array = [];
            var interactions:Object = {}; // to update...
            var list:DataList = graphData.group(Groups.SELECTED_EDGES);
            
            var change:Function = function(e:EdgeSprite):void {
                e.props.$selected = select;
                if (select) list.add(e)
                else list.remove(e);
                changed.push(e);
            }
            
            if (edges != null && edges.length > 0) {
                for each (var e:EdgeSprite in edges) {
                    var update:Boolean = false;
                    
                    if (e.props.$merged) {
                        // If this is a merged edge, select or deselect its regular edges instead:
                        for each (var ee:EdgeSprite in e.props.$edges) {
                            if (!ee.props.$filteredOut && ee.props.$selected !== select) {
                                change(ee);
                                update = true;
                            }
                        }
                    } else if (e.props.$selected !== select) {
                        change(e);
                        update = true;
                    }
                    
                    if (update) {
                        var inter:InteractionVO = getInteraction(e.source, e.target);
                        interactions[inter.key] = inter;
                    }
                }

                for (var key:String in interactions) interactions[key].update();
            }
            
            return changed;
        }
        
        public function addNode(data:Object):NodeSprite {
            if (data == null) data = {};
            
            if (data.id == null) data.id = nextId(Groups.NODES);
            else if (hasId(Groups.NODES, data.id)) throw new Error("Duplicate node id ('"+data.id+"')");
            
            // Set default values :
            for each (var f:DataField in _nodesSchema.fields) {
                if (data[f.name] == null) data[f.name] = f.defaultValue;
            }
            
            if (data.label == null) data.label = data.id;

            var n:NodeSprite = graphData.addNode(data);
            createCache(n);
            
            return n;
        }
        
        public function addEdge(data:Object):EdgeSprite {
            if (data == null) throw new Error("The 'data' argument is mandatory");
            
            var src:NodeSprite = getNode(data.source);
            var tgt:NodeSprite = getNode(data.target);
            
            if (src == null) throw new Error("Cannot find source node with id '"+data.source+"'");
            if (tgt == null) throw new Error("Cannot find target node with id '"+data.target+"'");
            
            if (data.id == null) data.id = nextId(Groups.EDGES);
            else if (hasId(Groups.EDGES, data.id)) throw new Error("Duplicate edge id ("+data.id+"')");
            
            // Set default values :
            for each (var f:DataField in _edgesSchema.fields) {
                if (data[f.name] == null) data[f.name] = f.defaultValue;
            }
            
            // TODO: create Cytoscape format label:
            if (data.label == null) data.label = data.id;

            // Create edge:
            var e:EdgeSprite = graphData.addEdgeFor(src, tgt, data.directed, data);
            
            // Add it to cache:
            createCache(e);

            // Get and update the interaction between the source and target nodes,
            // or create a new one if these pair of nodes are not linked yet:
            var inter:InteractionVO = getInteraction(e.source, e.target);
            
            if (inter == null) {
                inter = createInteraction(e.source, e.target);
            } else {
                inter.update();
            }
            
            return e;
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
            deleteCache(n);
            
            if (n.props.$selected) graphData.group(Groups.SELECTED_NODES).remove(n);
            
            var filterList:DataList = graphData.group(Groups.FILTERED_NODES);
            if (filterList != null) filterList.remove(n);
       
            // Also remove its linked edges:
            var edges:Array = [];
            n.visitEdges(function(e:EdgeSprite):Boolean {
                edges.push(e);
                return false;
            }, NodeSprite.GRAPH_LINKS);
            remove(edges);
            
            graphData.removeNode(n);
        }
        
        public function removeEdge(e:EdgeSprite):void {
            if (e == null) return;
            deleteCache(e);
            
            // Delete edge:
            graphData.removeEdge(e);
            
            // Delete or update related objects:
            if (e.props.$merged) {
                // MERGED...
                // Delete children ("regular") edges:
                var children:Array = e.props.$edges;
                if (children.length > 0) remove(children);
            } else {
                // REGULAR EDGE:
                // Update or delete the interaction:
                var inter:InteractionVO = getInteraction(e.source, e.target);
                
                if (inter != null) {
                    var edgeCount:int = inter.edges.length;
                    
                    if (edgeCount > 0) {
                        inter.update();
                    } else {
                        delete _interactions[inter.key];
                        removeEdge(inter.mergedEdge);
                    }
                }
            }
        }

        public function loadGraph(options:Object):void {
        	var txt:String = options.network;
            
            if (txt != null) {
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
                    
                    _nodesSchema = ds.nodes.schema;
                    _edgesSchema = ds.edges.schema;
                    
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
                nodesTable = new GraphicsDataTable(graphData.nodes, nodesSchema);
                edgesTable = new GraphicsDataTable(graphData.group(Groups.REGULAR_EDGES), edgesSchema);
                dtSet = new DataSet(nodesTable, edgesTable);
                out = new XGMMLConverter(configProxy.visualStyle).write(dtSet);
            } else {
                nodesTable = new DataTable(graphData.nodes.toDataArray(), nodesSchema);
                edgesTable = new DataTable(graphData.group(Groups.REGULAR_EDGES).toDataArray(), edgesSchema);
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
         * Create a mapping of nodes and edges, with their IDs as key,
         * in order to make it easier to get them later.
         * Also set a unique number to missing nodes or edges IDs.  
         */
        private function cacheItems(list:*):void {
            var ds:DataSprite;
            var missing:Array = [];
            
            // 1rs iteration: cache items that have id:
            for each (ds in list) {
                if (ds.data.id != null) createCache(ds);
                else missing.push(ds);
            }
            // 2nd iteration: set missing IDs:
            for each (ds in missing) {
               ds.data.id = nextId(ds is NodeSprite ? Groups.NODES : Groups.EDGES);
               createCache(ds);
            }
        }
        
        private function createCache(ds:DataSprite):void {
            if (ds is NodeSprite) {
                _nodesMap[ds.data.id] = ds;
            } else if (ds is EdgeSprite) {
                _edgesMap[ds.data.id] = ds;
                
                if (ds.props.$merged) {
                    graphData.group(Groups.MERGED_EDGES).add(ds);
                } else {
                    graphData.group(Groups.REGULAR_EDGES).add(ds);
                }
            }
        }
        
        private function deleteCache(ds:DataSprite):void {
            var fl:DataList;
            
            if (ds is NodeSprite) {
                delete _nodesMap[ds.data.id];
                
                graphData.group(Groups.SELECTED_NODES).remove(ds);
                
                fl = graphData.group(Groups.FILTERED_NODES);
                if (fl != null) fl.remove(ds);
                
            } else if (ds is EdgeSprite) {
                delete _edgesMap[ds.data.id];

                graphData.group(Groups.SELECTED_EDGES).remove(ds);
                
                fl = graphData.group(Groups.FILTERED_EDGES);
                if (fl != null) fl.remove(ds);
                
                if (ds.props.$merged) {
                    graphData.group(Groups.MERGED_EDGES).remove(ds);
                } else {
                    graphData.group(Groups.REGULAR_EDGES).remove(ds);
                }
            }
        }
        
        private function nextId(gr:String):String {
    		var id:int = _ids[gr];
    		while (hasId(gr, id)) { id++; }
    		_ids[gr] = id;
    		return ""+id;
        }
        
        private function hasId(gr:String, id:*):Boolean {
        	return gr === Groups.EDGES ? _edgesMap[""+id] !== undefined : _nodesMap[""+id] !== undefined;
        }
        
        private function createMergedEdges():void {            
            var inter:InteractionVO;

            for each (var e:EdgeSprite in graphData.edges) {
                if (!e.props.$merged) {
                    inter = getInteraction(e.source, e.target);
                    if (inter == null) createInteraction(e.source, e.target);
                }
            }
        }
        
        private function createInteraction(source:NodeSprite, target:NodeSprite):InteractionVO {
            var inter:InteractionVO;
            
            if (getInteraction(source, target) == null) {
                inter = new InteractionVO(source, target);
                _interactions[inter.key] = inter;
                
                var me:EdgeSprite = inter.mergedEdge;
                me.data.id = nextId(Groups.EDGES);
                graphData.addEdge(me);
                createCache(me);
            }
            
            return inter;
        }
    }
}
