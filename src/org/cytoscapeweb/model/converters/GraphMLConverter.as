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
    import flare.data.DataField;
    import flare.data.DataSchema;
    import flare.data.DataSet;
    import flare.data.DataTable;
    import flare.data.DataUtil;
    import flare.data.converters.IDataConverter;
    import flare.vis.data.DataSprite;
    import flare.vis.data.EdgeSprite;
    
    import flash.utils.ByteArray;
    import flash.utils.IDataInput;
    import flash.utils.IDataOutput;
    
    import org.cytoscapeweb.model.data.GraphicsDataTable;
    import org.cytoscapeweb.util.DataSchemaUtils;
    import org.cytoscapeweb.util.Groups;
    import org.cytoscapeweb.util.Utils;
    import org.cytoscapeweb.util.methods.$each;
    import org.cytoscapeweb.vis.data.CompoundNodeSprite;

    /**
     * Converts data between GraphML markup and flare DataSet instances.
     * <a href="http://graphml.graphdrawing.org/">GraphML</a> is a
     * standardized XML format supporting graph structure and typed data
     * schemas for both nodes and edges.
     * 
     * Note: Just copied from Flare, in order to fix some errors, because it's
     * hard to inherit from the original GraphMLConverter.
     */
    public class GraphMLConverter implements IDataConverter {
        
        private namespace _defNamespace = "http://graphml.graphdrawing.org/xmlns";
        use namespace _defNamespace;
        
        // ========[ CONSTANTS ]====================================================================
        
        private static const NODE_ATTR:Object = {
            id: 1
        }
        private static const EDGE_ATTR:Object = {
            id: 1, directed: false, source: 1, target: 1
        };
        
        private static const GRAPHML_HEADER:String = 
            "<graphml xmlns=\"http://graphml.graphdrawing.org/xmlns\" "  +
                     "xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" " +
                     "xsi:schemaLocation=\"http://graphml.graphdrawing.org/xmlns " +
                     "http://graphml.graphdrawing.org/xmlns/1.0/graphml.xsd\"/>";
        
        public static const GRAPHML:String    = "graphml";
        private static const ID:String         = "id";
        private static const GRAPH:String      = "graph";
        private static const EDGEDEF:String    = "edgedefault";
        private static const DIRECTED:String   = "directed";
        private static const UNDIRECTED:String = "undirected";
        
        private static const KEY:String        = "key";
        private static const FOR:String        = "for";
        private static const ALL:String        = "all";
        private static const ATTRNAME:String   = "attr.name";
        private static const ATTRTYPE:String   = "attr.type";
        private static const DEFAULT:String    = "default";
        
        private static const NODE:String   = "node";
        private static const EDGE:String   = "edge";
        private static const SOURCE:String = "source";
        private static const TARGET:String = "target";
        private static const TYPE:String   = "type";
        
        private static const INT:String = "int";
        private static const INTEGER:String = "integer";
        private static const LONG:String = "long";
        private static const FLOAT:String = "float";
        private static const DOUBLE:String = "double";
        private static const REAL:String = "real";
        private static const BOOLEAN:String = "boolean";
        private static const STRING:String = "string";
        private static const DATE:String = "date";

        // ========[ PUBLIC METHODS ]===============================================================
        
        /** @inheritDoc */
        public function read(input:IDataInput, schema:DataSchema=null):DataSet {
            var str:String = input.readUTFBytes(input.bytesAvailable);
            var idx:int = str.indexOf(GRAPHML);
            if (idx > 0) {
                str = str.substr(0, idx+GRAPHML.length) + 
                    str.substring(str.indexOf(">", idx));
            }
            return parse(XML(str), schema);
        }
        
        /** @inheritDoc */
        public function write(ds:DataSet, output:IDataOutput=null):IDataOutput {            
            // init GraphML
            var graphml:XML = new XML(GRAPHML_HEADER);
            
            // add schema
            graphml = addSchema(graphml, ds.nodes.schema, NODE, NODE_ATTR);
            graphml = addSchema(graphml, ds.edges.schema, EDGE, EDGE_ATTR);
            
            // add graph data
            var graph:XML = new XML(<graph/>);
            var ed:Object = ds.edges.schema.getFieldByName(DIRECTED).defaultValue;
            // ############################################
            // Patch for a Flare bug:
            // ############################################
            // graph.@[EDGEDEF] = ed==DIRECTED ? DIRECTED : UNDIRECTED;
            graph.@[EDGEDEF] = ed ? DIRECTED : UNDIRECTED;
            // ############################################
            //addData(graph, ds.nodes.data, ds.nodes.schema, NODE, NODE_ATTR);
            //addData(graph, ds.edges.data, ds.edges.schema, EDGE, EDGE_ATTR);
            
            // init xml lookup <id, xml> which is needed to construct compound
            // structure correctly
            var lookup:Object = new Object();
            
            var nodes:Array = new Array();
            var edges:Array = new Array();
            var sprite:Object;
            
            // populate nodes array with NodeSprite instances
            for each (sprite in (ds.nodes as GraphicsDataTable).dataSprites) {
                nodes.push(sprite);
            }
            
            // populate edges array with EdgeSprite instances
            for each (sprite in (ds.edges as GraphicsDataTable).dataSprites) {
                edges.push(sprite);
            }
            
            // add node data
            addData(graph, nodes, ds.nodes.schema, NODE, NODE_ATTR, lookup);
            // add edge data
            addData(graph, edges, ds.edges.schema, EDGE, EDGE_ATTR, lookup);
            
            graphml = graphml.appendChild(graph);
            
            if (output == null) output = new ByteArray();
            output.writeUTFBytes(graphml.toXMLString());
            
            return output;
        }
        
        /**
         * Parses a GraphML XML object into a DataSet instance.
         * @param graphml the XML object containing GraphML markup
         * @param schema a DataSchema (typically null, as GraphML contains
         *  schema information)
         * @return the parsed DataSet instance
         */
        public function parse(graphml:XML, schema:DataSchema=null):DataSet {
            var lookup:Object = {};
            var nodes:Array = [], edges:Array = [];
            var n:Object, e:Object;
            var id:String, sid:String, tid:String;
            var def:Object, type:int;
            var group:String, attrName:String, attrType:String;
            var directed:Boolean = DIRECTED == graphml.graph.@[EDGEDEF]
            
            var nodeSchema:DataSchema = DataSchemaUtils.minimumNodeSchema();
            var edgeSchema:DataSchema = DataSchemaUtils.minimumEdgeSchema(directed);
            
            // parse data schema
            var keyList:XMLList = graphml..key;
            
            for each (var key:XML in keyList) {
                id       = key.@[ID].toString();
                group    = key.@[FOR].toString();
                attrName = key.@[ATTRNAME].toString();
                type     = toCW_Type(key.@[ATTRTYPE].toString());
                def = key[DEFAULT].toString();
                def = def != null && def.length > 0 ? DataUtil.parseValue(def, type) : null;
                
                if (def == null) {
                    switch (type) {
                        case DataUtil.BOOLEAN: def = false; break;
                        case DataUtil.INT:     def = 0;     break;
                    }
                }
                
                if ( (group === NODE || group === ALL) && nodeSchema.getFieldById(id) == null )
                    nodeSchema.addField(new DataField(attrName, type, def, id));
                if ( (group === EDGE || group === ALL) && edgeSchema.getFieldById(id) == null )
                    edgeSchema.addField(new DataField(attrName, type, def, id));
            }
            
            var childNodes:XMLList = graphml.graph.child("node");
            
            // parse nodes
            var nodeList:XMLList = graphml..node;
            var nodeSprites:Array = new Array();
            var cns:CompoundNodeSprite;
            var node:XML;
            
            // for each node in the node list create a CompoundNodeSprite
            // instance and add it to the nodeSprites array.
            for each (node in nodeList) {
                id = node.@[ID].toString();
                //lookup[id] = (n = parseData(node, nodeSchema));
                n = parseData(node, nodeSchema)
                //nodes.push(n);
                cns = new CompoundNodeSprite();
                cns.data = n;
                lookup[id] = cns;
                nodeSprites.push(cns);
            }
            
            var graphList:XMLList = graphml..graph;
            var graph:XML;
            var compound:XML
            
            // for each subgraph in the XML, initialize the CompoundNodeSprite
            // owning that subgraph.
            
            for each (graph in graphList) {
                // if the parent is GRAPHML, then the node is in the root graph.
                if (graph.parent().name() !== GRAPHML) {
                    compound = graph.parent();
                    id = compound.@[ID].toString();
                    cns = lookup[id] as CompoundNodeSprite;
                    
                    if (cns != null) {
                        cns.initialize();
                    }
                }
            }
            
            // add each node to its parent if it is not a node in the root
            
            for each (node in nodeList) {
                graph = node.parent();
            
                // if the parent is GRAPHML, then the node is in the root graph.
                if (graph.parent().name() !== GRAPHML) {
                    compound = graph.parent();
                    id = compound.@[ID].toString();
                    cns = lookup[id] as CompoundNodeSprite;
                    id = node.@[ID].toString();
                    
                    if (cns != null) {
                        cns.addNode(lookup[id] as CompoundNodeSprite);
                    }
                }
            }
            
            // parse edges
            var edgeList:XMLList = graphml..edge;
            
            for each (var edge:XML in edgeList) {
                id  = edge.@[ID].toString();
                sid = edge.@[SOURCE].toString();
                tid = edge.@[TARGET].toString();
                
                // error checking
                if (!lookup.hasOwnProperty(sid))
                    throw new Error("Edge "+id+" references unknown node: "+sid);
                if (!lookup.hasOwnProperty(tid))
                    throw new Error("Edge "+id+" references unknown node: "+tid);
                                
                edges.push(e = parseData(edge, edgeSchema));
            }
            
            return new DataSet(
                //new DataTable(nodes, nodeSchema),
                new DataTable(nodeSprites, nodeSchema),
                new DataTable(edges, edgeSchema)
            );
        }
        
        // ========[ PROTECTED METHODS ]============================================================

        protected function parseData(node:XML, schema:DataSchema):Object {
            var n:Object = {};
            var name:String, field:DataField, value:Object;
            
            // set default values
            for (var i:int = 0; i < schema.numFields; ++i) {
                field = schema.getFieldAt(i);
                n[field.name] = field.defaultValue;
            }
            
            // get attribute values
            for each (var attr:XML in node.@*) {
                name = attr.name().toString();
                field = schema.getFieldByName(name);
                n[name] = DataUtil.parseValue(attr[0].toString(), field.type);
            }
            
            // get data values in XML
            for each (var data:XML in node.data) {
                var key:String = data.@[KEY].toString();
                field = schema.getFieldById(key);
                
                // Better throwing an error:
                if (field == null)
                    throw new Error("Cannot parse GraphML: Missing data key definition for '"+key+"'. " + 
                                    "Please see http://graphml.graphdrawing.org/primer/graphml-primer.html#Attributes");
                
                name = field.name;
                n[name] = DataUtil.parseValue(data[0].toString(), field.type);
            }
            
            return n;
        }
        
        // ========[ PRIVATE METHODS ]==============================================================
        
        private static function addSchema(xml:XML, schema:DataSchema, group:String, attrs:Object):XML {
            var field:DataField;
            
            for (var i:int = 0; i < schema.numFields; ++i) {
                field = schema.getFieldAt(i);
                if (attrs.hasOwnProperty(field.name)) continue;
                if (group === Groups.NODES && field.name === DataSchemaUtils.PARENT) continue;
                
                var key:XML = new XML(<key/>);
                key.@[ID] = field.id;
                key.@[FOR] = group;
                key.@[ATTRNAME] = field.name;
                key.@[ATTRTYPE] = fromCW_Type(field.type);
            
                if (field.defaultValue != null) {
                    var def:XML = new XML(<default/>);
                    def.appendChild(toString(field.defaultValue, field.type));
                    key.appendChild(def);
                }
                
                xml = xml.appendChild(key);
            }
            return xml;
        }
        
        /**
         * Adds the data of the sprites in the given array to the specified
         * XML object. The given sprite array is supposed to contain DataSprite
         * instances. Also, adds the given schema information to the XML. 
         * 
         * @param xml       target XML object to add data
         * @param sprites   array of DataSprite instances   
         * @param schema    DataSchema for nodes or edges
         * @param tag       tag of the data (node, edge, etc.)
         * @param attrs     list of XML attributes
         * @param lookup    lookup map for <id, sprite> pairs
         * @param parentId  optional parent id for recursive calls
         */
        private static function addData(xml:XML,
                                        tuples:Array,
                                        schema:DataSchema, 
                                        tag:String, 
                                        attrs:Object, 
                                        lookup:Object, 
                                        parentId:String = null):void {
            // xml used when creating subgraphs for compound nodes
            var childXml:XML = null;
            var cn:CompoundNodeSprite;
            
            /**
             * Function (as a variable) to append a child xml representing the
             * given tuple data to the target XML. If target is null, then
             * the xml is appended to the root xml.
             */
            var appendChild:Function = function(i:uint,  tuple:Object, target:XML = null):void {
                var x:XML = new XML("<"+tag+"/>");
                
                for (var name:String in tuple) {
                	if (tag === NODE && name === DataSchemaUtils.PARENT) continue;
                	
                    var value:* = tuple[name];
                    var field:DataField = schema.getFieldByName(name);
                    if (field != null && value == field.defaultValue) continue;
                    
                    var dataType:int = field != null ? field.type : Utils.dataType(value);
                    var type:String = fromCW_Type(dataType); // GraphML type
                    
                    if (attrs.hasOwnProperty(name)) {
                        // add as attribute
                        x.@[name] = toString(value, dataType);
                    } else {
                        // add as data child tag
                        var data:XML = new XML(<data/>);
                        data.@[KEY] = name;
                        data.appendChild(toString(value, dataType));
                        x.appendChild(data);
                    }
                }
                
                if (target == null) {
                    // append to the root xml
                    xml.appendChild(x);
                } else {
                    // append to the given xml
                    target.appendChild(x);
                }
                
                // update child xml
                childXml = x;
            };
            
            // array of compound nodes
            var compoundNodes:Array = new Array();
            
            // array of data (for both edges and simple nodes)
            var plainData:Array = new Array();
            
            // separate compound nodes and simple nodes if tuples are nodes.
            // separate intra-graph edges and inter-graph edges if tuples are edges.
            for each (var ds:DataSprite in tuples) {
                if (ds is CompoundNodeSprite) {
                    cn = ds as CompoundNodeSprite;
                    
                    // check if compound node is initialized
                    if (cn.isInitialized()) {
                        if (parentId == null) {
                            // if no parent id is provided, then we are iterating
                            // the root graph. Include only 'parentless' compounds  
                            if (cn.data.parent == null) {
                                compoundNodes.push(cn);
                            }
                        } else {
                            // if parent id is provided, it is safe to include all
                            // initialized compound nodes.
                            compoundNodes.push(cn);
                        }
                    } else {
                        if (parentId == null) {
                            // If no parent id is provided include only parentless nodes' data.
                            if (cn.data.parent == null) {
                                plainData.push(cn.data);
                            }
                        } else {
                            // if parent id is provided, it is safe to include data
                            plainData.push(cn.data);
                        }
                    }
                } else if (ds is EdgeSprite) {
                    var es:EdgeSprite =  ds as EdgeSprite;
                    var target:XML = null;
                    var sParentId:String;
                    var tParentId:String;
                    
                    sParentId = es.source.data.parent;
                    tParentId = es.target.data.parent;
                    
                    // if both source and target parents are in the same
                    // subgraph (i.e. in the same compound), then the edge
                    // information will be written to the corresponding subgraph.
                    if (sParentId != null && tParentId != null && sParentId == tParentId) {
                        // try to get the XML corresponding to the parent
                        target = lookup[sParentId] as XML;
                    }
                    
                    // check if the target parent compound is valid
                    if (target != null) {
                        appendChild(0, es.data, target);
                    } else {
                        // add the edge data to the array of data to be added to the root graph
                        plainData.push(es.data);
                    }
                }
            }
            
            // write simple node information to the xml
            $each(plainData, appendChild);
            
            var subgraph:XML;
            
            // for each compound node sprite, recursively write child node
            // information into a new subgraph
            
            for each (var cns:CompoundNodeSprite in compoundNodes) {
                // sub graph for child nodes & edges
                subgraph = new XML(<graph/>);
                
                // set edge definition (directed or undirected) of the subgraph 
                subgraph.@[EDGEDEF] = xml.@[EDGEDEF].toString();
                
                // construct a map for <id, graph> pairs in order to
                // use while writing edges              
                lookup[cns.data.id] = subgraph;
                
                // add compound node data to the current graph 
                appendChild(0, cns.data);
                
                // recursively add child node data
                addData(subgraph, cns.getNodes(), schema, tag, attrs, lookup, cns.data.id);
                
                // add subgraph information to the current graph
                childXml.appendChild(subgraph);
            }
        }
        
        // -- static helpers --------------------------------------------------
        
        private static function toString(o:Object, type:int):String {
            if (o is Array) return (o as Array).join(",");
            return o != null ? o.toString() : ""; // TODO: formatting control?
        }
        
        private static function toCW_Type(type:String):int {
            switch (type) {
                case INT:
                case INTEGER: return DataUtil.INT;
                case LONG:
                case FLOAT:
                case DOUBLE:
                case REAL:    return DataUtil.NUMBER;
                case BOOLEAN: return DataUtil.BOOLEAN;
                case DATE:    return DataUtil.DATE;
                case STRING:
                default:      return DataUtil.STRING;
            }
        }
        
        private static function fromCW_Type(type:int):String {
            switch (type) {
                case DataUtil.INT:      return INT;
                case DataUtil.BOOLEAN:  return BOOLEAN;
                case DataUtil.NUMBER:   return DOUBLE;
                case DataUtil.DATE:     return DATE;
                case DataUtil.STRING:
                default:                return STRING;
            }
        }
        
        private static function error(msg:String):void {
            throw new Error(msg);
        }   
    }
}