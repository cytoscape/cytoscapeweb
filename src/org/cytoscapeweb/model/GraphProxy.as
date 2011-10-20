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
    
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import flash.net.URLRequest;
    import flash.net.URLRequestHeader;
    import flash.net.URLRequestMethod;
    import flash.net.navigateToURL;
    import flash.utils.IDataOutput;
    
    import mx.utils.StringUtil;
    
    import org.cytoscapeweb.ApplicationFacade;
    import org.cytoscapeweb.model.converters.ExternalObjectConverter;
    import org.cytoscapeweb.model.converters.GraphMLConverter;
    import org.cytoscapeweb.model.converters.SIFConverter;
    import org.cytoscapeweb.model.converters.XGMMLConverter;
    import org.cytoscapeweb.model.data.ConfigVO;
    import org.cytoscapeweb.model.data.GraphicsDataTable;
    import org.cytoscapeweb.model.data.InteractionVO;
    import org.cytoscapeweb.model.data.VisualStyleVO;
    import org.cytoscapeweb.model.error.CWError;
    import org.cytoscapeweb.util.CompoundNodes;
    import org.cytoscapeweb.util.ErrorCodes;
    import org.cytoscapeweb.util.GraphUtils;
    import org.cytoscapeweb.util.Groups;
    import org.cytoscapeweb.util.Layouts;
    import org.cytoscapeweb.vis.data.CompoundNodeSprite;
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
        
        /**
         *  array of non-selected child nodes of selected compound nodes
         */
        private var _missingChildren:Array;
        
        /** Scale factor, between 0 and 1 */
        private var _zoom:Number = 1;
        /** The viewport center */
        private var _viewCenter:Point;

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
        
        /**
         * @param data It has to be a flare.vis.data.Data instance.
         */
        public override function setData(data:Object):void {
            super.setData(data);

            _ids = { "nodes": 0, "edges": 0, "mergedEdges": 0 };
            _nodesMap = {};
            _edgesMap = {};
            _interactions = {};
            data.addGroup(Groups.SELECTED_NODES);
            data.addGroup(Groups.SELECTED_EDGES);
            data.addGroup(Groups.REGULAR_EDGES);
            data.addGroup(Groups.MERGED_EDGES);
            data.addGroup(Groups.COMPOUND_NODES);
            
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
            var n:NodeSprite;
            for each (n in graphData.nodes) arr.push(n);
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
            var n:NodeSprite;
            var list:DataList = graphData.group(Groups.FILTERED_NODES);
            if (list != null) {
                arr = [];
                for each (n in list) arr.push(n);
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
                inter.update(edgesSchema);
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
        
        public function get viewCenter():Point {
            return _viewCenter;
        }
 
        public function set viewCenter(value:Point):void {
            _viewCenter = value;
        }

        /**
         * Finds non-selected children of the compound nodes in the given
         * node array, and returns the collected children in an array of nodes.
         * 
         * @return      array of nodes
         */
        public function get missingChildren():Array {
            // this map is used to avoid duplicates
            var childMap:Object;
            var children:Array;
            var nodes:Array = this.selectedNodes;
            var node:NodeSprite;
            
            // if missing children is set before, just return the
            // previously collected children
            if (_missingChildren != null) {
                children = _missingChildren;
            } else {
                // collect non-selected children of all selected compound nodes
                childMap = new Object();
                
                // for each node sprite in the selected nodes, search for missing children
                for each (var ns:NodeSprite in nodes) {
                    if (ns is CompoundNodeSprite) {
                        // get non-selected children of the current compound
                        children = CompoundNodes.getChildren(
                            (ns as CompoundNodeSprite),
                            CompoundNodes.NON_SELECTED);
                        
                        // concat the new children with the map
                        for each (node in children) {
                            // assuming the node.data.id is not null
                            childMap[node.data.id] = node;
                        }
                    }
                }
                
                // convert child map to an array
                children = new Array();
                
                for each (node in childMap) {
                    children.push(node);
                }
                
                // update missing children array
                _missingChildren = children;
            }
            
            return children;
        }
        
        /**
         * @return true if the graph contains one or moere compound nodes
         */
        public function get compoundGraph():Boolean {
            var g:DataList = graphData.group(Groups.COMPOUND_NODES);
            return g != null && g.length > 0;
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

        public function getNode(id:String):CompoundNodeSprite {
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

        public function addDataField(group:String, name:String, type:int, defValue:*=null):Boolean {
            var added:Boolean = false;
            
            if (group == null || group === Groups.NONE) {
                added = addDataField(Groups.NODES, name, type, defValue);
                added = addDataField(Groups.EDGES, name, type, defValue) || added;
            } else {
                name = StringUtil.trim(name);
                var schema:DataSchema = group === Groups.NODES ? nodesSchema : edgesSchema;
                
                if (schema.getFieldById(name) == null) {
                    // This field is not duplicated...
                    if (defValue == null) {
                        switch (type) {
                            case DataUtil.BOOLEAN: defValue = false; break;
                            case DataUtil.INT: defValue = 0; break;
                            default: defValue = null;
                        }
                    } else {
                        try {
                            defValue = ExternalObjectConverter.normalizeDataValue(defValue, type, null);
                        } catch (err:Error) {
                            throw new CWError("Cannot add data field '"+name+"':" + err.message,
                                              ErrorCodes.INVALID_DATA_CONVERSION);
                        }
                    }
                    
                    var field:DataField = new DataField(name, type, defValue);
                    schema.addField(field);
                    added = true;
                    
                    // Update nodes/edges data
                    var items:Array = group === Groups.NODES ? nodes : edges;
                    for each (var ds:DataSprite in items) {
                        ds.data[field.name] = field.defaultValue;
                    }
                } else {
                    throw new CWError("Cannot add data field '"+name+"': data field name already existis",
                                      ErrorCodes.INVALID_DATA_CONVERSION);
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
                if ( name != "id" &&
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
                if (ds is EdgeSprite && ds.props.$merged) {
                    throw new CWError("It is not allowed to update a merged edge data: " + ds.data.id);
                }
                
                var schema:DataSchema = ds is NodeSprite ? _nodesSchema : _edgesSchema;
                var updated:Boolean = false;
                
                for (var k:String in data) {
                    if ( k !== "id" && !(ds is EdgeSprite && (k === "source" || k === "target")) ) {
                        var f:DataField = schema.getFieldByName(k);
                        
                        if (f != null) {
                            var v:* = data[k];
                            
                            try {
                                v = ExternalObjectConverter.normalizeDataValue(v, f.type, f.defaultValue);
                            } catch (err:Error) {
                                throw new CWError("Cannot update data for '"+k+"':" + err.message,
                                                  ErrorCodes.INVALID_DATA_CONVERSION);
                            }
                            
                            ds.data[k] = v;
                            updated = true;
                        } else {
                            throw new CWError("Cannot update data: there is no Data Field for '"+k+"'.",
                                              ErrorCodes.MISSING_DATA_FIELD);
                        }
                    }
                }
                
                if (ds is EdgeSprite && updated) {
                    // Update the merged edge data
                    var edge:EdgeSprite = EdgeSprite(ds);
                    var interaction:InteractionVO = getInteraction(edge.source, edge.target);
                    interaction.update(edgesSchema);
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
            var n:NodeSprite;
            
            if (nodes != null && nodes.length > 0) {
                var list:DataList = graphData.group(Groups.SELECTED_NODES);
                
                for each (n in nodes) {
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
            var e:EdgeSprite;
            
            var change:Function = function(e:EdgeSprite):void {
                e.props.$selected = select;
                if (select) list.add(e)
                else list.remove(e);
                changed.push(e);
            }
            
            if (edges != null && edges.length > 0) {
                for each (e in edges) {
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

                for (var key:String in interactions)
                    interactions[key].update(edgesSchema, false);
            }
            
            return changed;
        }
        
        /**
         * Creates and adds a new CompoundNodeSprite to the graph data. Also,
         * sets the given data object as the data property of the sprite.
         * 
         * @param data  data associated with the compound node
         * @return      newly created NodeSprite
         */
        public function addNode(data:Object):CompoundNodeSprite {
            if (data == null) {
                data = {};
            }
            
            if (data.id == null) {
                data.id = nextId(Groups.NODES);
            } else if (hasId(Groups.NODES, data.id)) {
                throw new Error("Duplicate node id ('"+data.id+"')");
            }
            
            normalizeData(data, Groups.NODES);
            var cns:CompoundNodeSprite = new CompoundNodeSprite();
            
            if (data != null) {
                cns.data = data;
            }
                        
            // and newly created CompoundNodeSprite to the graph data, but do
            // not add it to the list of compound nodes. It will be added to
            // that list when a child node is added into the compound.
            this.graphData.addNode(cns);
            
            // postponed until the first child node
            //var list:DataList = this.graphData.group(Groups.COMPOUND_NODES);          
            //list.add(nodeSprite);
            this.createCache(cns);
            
            return cns;
        }
        
        public function addToParent(ns:NodeSprite, parent:CompoundNodeSprite):void {
           var group:DataList = this.graphData.group(Groups.COMPOUND_NODES);
            
            // initialize the compound node if it is not initialized,
            // yet. Also, add the compound to the compound node data group
            if (!parent.isInitialized()) {
                // initialize child node list
                parent.initialize();
                // add to the data group
                group.add(parent);
            }
            
            // add node into the target compound node
            parent.addNode(ns);
        }
        
        /**
         * Resets the missing children array in order to enable re-calculation
         * of missing child nodes in the getter method of missingChildren.
         */ 
        public function resetMissingChildren():void {
            _missingChildren = null;
        }
        
        /**
         * @return The newly created edges. The first element of the array is the added edge.
         *         There can be a second one, which is always a merged edge,
         *         but only if it was created as a result of adding the new element.  
         */
        public function addEdge(data:Object):Array {
            if (data == null) throw new CWError("The 'data' argument is mandatory",
                                                ErrorCodes.INVALID_DATA_CONVERSION);
            trace("add edge: " + data.id);
            var arr:Array = [];
            
            normalizeData(data, Groups.EDGES);
            
            var src:CompoundNodeSprite = getNode(data.source);
            var tgt:CompoundNodeSprite = getNode(data.target);
            
            if (src == null) throw new Error("Cannot find source node with id '"+data.source+"'");
            if (tgt == null) throw new Error("Cannot find target node with id '"+data.target+"'");
            
            if (data.id == null) data.id = nextId(Groups.EDGES);
            else if (hasId(Groups.EDGES, data.id)) throw new Error("Duplicate edge id ('"+data.id+"')");

            // Create edge:
            var e:EdgeSprite = graphData.addEdgeFor(src, tgt, data.directed, data);
            arr.push(e);
            
            // Add it to cache:
            createCache(e);

            // Get and update the interaction between the source and target nodes,
            // or create a new one if these pair of nodes are not linked yet:
            var inter:InteractionVO = getInteraction(e.source, e.target);
            
            if (inter == null) {
                inter = createInteraction(e.source, e.target);
                arr.push(inter.mergedEdge);
            } else {
                inter.update(edgesSchema);
            }
            
            return arr;
        }
        
        public function remove(items:Array):void {
            for each (var ds:DataSprite in items) {
                if (ds is CompoundNodeSprite) {
                    removeNode(ds as CompoundNodeSprite);
                } else {
                    removeEdge(ds as EdgeSprite);
                }
            }
            
            // Reset auto-increment ID lookup:
            if (nodes.length === 0) _ids[Groups.NODES] = 0;
            if (edges.length === 0) _ids[Groups.EDGES] = 0;
            if (mergedEdges.length === 0) _ids[Groups.MERGED_EDGES] = 0;
        }
        
        public function loadGraph(network:*, layout:*):void {
            try {
                var ds:DataSet;
                
                if (network is String) {
                    // Text:
                    var xml:XML = new XML(network);
                    
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
                            
                            this.zoom = xgmmlConverter.zoom;
                            this.viewCenter = xgmmlConverter.viewCenter;
                            
                            var points:Object = xgmmlConverter.points;
                            
                            // update node positions & layout info
                            if (points != null) {
                                if (layout == null) layout = {};
                                if (layout is String) layout = { name: layout };
                                
                                if (layout.name == null || layout.name === Layouts.PRESET) {
                                    layout.name = Layouts.PRESET;
                                    layout.options = Layouts.mergeOptions(Layouts.PRESET, layout.options);
                                    layout.options.points = points;
                                    config.currentLayout = layout;
                                }
                            }
                        }
                    } else {
                        // SIF:
                        ds = new SIFConverter().parse(network);
                    }
                } else {
                    // Plain objects:
                    ds = ExternalObjectConverter.convertToDataSet(network);
                }
                
                _nodesSchema = ds.nodes.schema;
                _edgesSchema = ds.edges.schema;
                
                var data:Data = Data.fromDataSet(ds);  
                
                setData(data);
                
                // add compound nodes to the corresponding data group
                for each (var ns:NodeSprite in data.nodes) {
                    if (ns is CompoundNodeSprite) {
                        if ((ns as CompoundNodeSprite).isInitialized()) {
                            data.group(Groups.COMPOUND_NODES).add(ns);
                        }
                    }
                }
            } catch (err:Error) {
                trace("[ERROR]: onLoadGraph_result: " + err.getStackTrace());
                throw err;
            }
        }
        
        public function getDataAsText(format:String="xgmml",
                                      viewCenter:Point=null,
                                      options:Object=null):String {
            var out:IDataOutput, nodesTable:DataTable, edgesTable:DataTable, dtSet:DataSet;
            format = StringUtil.trim(format.toLowerCase());
                        
            if (format === "xgmml" || format === "graphml") {
                // GraphicsDataTable is needed for both graphML and XGMML formats,
                // since we also require the information contained in the DataSprite instances
                // in addition to the raw data.
                nodesTable = new GraphicsDataTable(graphData.nodes, nodesSchema);
                edgesTable = new GraphicsDataTable(graphData.group(Groups.REGULAR_EDGES), edgesSchema);
                dtSet = new DataSet(nodesTable, edgesTable);
                
                if (format === "xgmml") {
                    var bounds:Rectangle = GraphUtils.getBounds(nodes, edges,
                                                                !configProxy.nodeLabelsVisible,
                                                                !configProxy.edgeLabelsVisible);
                    out = new XGMMLConverter(configProxy.visualStyle, zoom, viewCenter, bounds).write(dtSet);
                } else {
                    out = new GraphMLConverter().write(dtSet);
                }
            } else {
                // convert to SIF (it does not support compounds!)
                nodesTable = new DataTable(graphData.nodes.toDataArray(), nodesSchema);
                edgesTable = new DataTable(graphData.group(Groups.REGULAR_EDGES).toDataArray(), edgesSchema);
                dtSet = new DataSet(nodesTable, edgesTable);
                out = new SIFConverter(options).write(dtSet);
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
        
        private function removeNode(n:CompoundNodeSprite):void {
            if (n == null) return;
            var stack:Array = [n], edges:Array;
            var child:CompoundNodeSprite, parent:CompoundNodeSprite;
            
            while (stack.length > 0) {
                n = stack.pop();
                if (n.props.$deleted) continue;
                
                trace("Deleting Node (" + n.data.id + ")...");
                deleteCache(n);
           
                // Remove children:
                if (n.nodesCount > 0) {
                    for each (child in n.getNodes()) {
                        if (!child.props.$deleted) stack.push(child);
                    }
                }
                
                // Remove it from its parent, if it is a child:
                if (n.data.parent != null) {
                    parent = getNode(n.data.parent);
                    if (parent != null) {
                        parent.removeNode(n);
                        
                        if (parent.nodesCount === 0) {
                            graphData.group(Groups.COMPOUND_NODES).remove(parent);
                        }
                    }
                }
           
                // Also remove its linked edges:
                edges = [];
                n.visitEdges(function(e:EdgeSprite):Boolean {
                    edges.push(e);
                    return false;
                }, NodeSprite.GRAPH_LINKS);
                remove(edges);
                
                graphData.removeNode(n);
                n.props.$deleted = true;
            }
        }
        
        private function removeEdge(e:EdgeSprite):void {
            var stack:Array = [e], children:Array;
            var child:EdgeSprite, parent:EdgeSprite;
            var inter:InteractionVO;
            
            while (stack.length > 0) {
                e = stack.pop();
                if (e.props.$deleted) continue;
                
                trace("Deleting Edge (" + e.data.id + ")...");
                
                inter = getInteraction(e.source, e.target);
                
                // Delete edge:
                deleteCache(e);
                graphData.removeEdge(e);
                e.props.$deleted = true;
            
                // Delete or update related objects:
                if (e.props.$merged) {
                    // MERGED...
                    // Delete children ("regular") edges:
                    children = e.props.$edges;
                    
                    if (children.length > 0) {
                        for each (child in children) {
                            if (!child.props.$deleted) stack.push(child);
                        }
                    }
                    
                    delete _interactions[inter.key];
                } else {
                    // REGULAR EDGE:
                    // Update or delete the interaction:
                    if (inter != null) {
                        if (inter.edges.length > 0) {
                            inter.update(edgesSchema);
                        } else {
                            stack.push(inter.mergedEdge);
                        }
                    }
                }
            }
        }
        
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
                graphData.group(Groups.COMPOUND_NODES).remove(ds);
                
                fl = graphData.group(Groups.FILTERED_NODES);
                if (fl != null) fl.remove(ds);
                
                // Also remove parent from compound group, if it has no children:
                var parent:CompoundNodeSprite = this.getNode(ds.data.parent);
                if (parent != null && parent.nodesCount === 0) {
                    graphData.group(Groups.COMPOUND_NODES).remove(parent);
                    trace(">> removed compound from group >> "+parent.data.id);
                }
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
            var id:String;
            var prefix:String = gr === Groups.NODES ? "n" : (gr === Groups.MERGED_EDGES ? "me" : "e");
            var number:int = _ids[gr];
            do {
                number++;
                id = prefix + number;
            } while (hasId(gr, id))
            _ids[gr] = number;
            
            return id;
        }
        
        private function hasId(gr:String, id:*):Boolean {
            return gr === Groups.EDGES || gr === Groups.MERGED_EDGES ?
                      _edgesMap[""+id] !== undefined :
                      _nodesMap[""+id] !== undefined;
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
                inter = new InteractionVO(source, target, edgesSchema);
                _interactions[inter.key] = inter;
                
                var me:EdgeSprite = inter.mergedEdge;
                me.data.id = nextId(Groups.MERGED_EDGES);
                graphData.addEdge(me);
                createCache(me);
            }
            
            return inter;
        }
        
        private function normalizeData(data:Object, gr:String):void {
            var schema:DataSchema = gr === Data.NODES ? nodesSchema : edgesSchema;
            var f:DataField;
            var k:String, v:*;
            
            // Check data types:
            for (k in data) {
                v = data[k];
                f = schema.getFieldById(k);
                
                if (f == null) {
                    throw new CWError("Undefined data field: '"+k+"'",
                                      ErrorCodes.INVALID_DATA_CONVERSION);
                }
                
                try {
                    v = ExternalObjectConverter.normalizeDataValue(v, f.type, f.defaultValue);
                } catch (err:Error) {
                    throw new CWError("Invalid data value ('"+k+"'): "+err.message,
                                      ErrorCodes.INVALID_DATA_CONVERSION);
                }
                
                data[k] == v;
            }
            
            // Set default values :
            for each (f in schema.fields) {
                if (data[f.name] == null) data[f.name] = f.defaultValue;
            }
        }
    }
}
