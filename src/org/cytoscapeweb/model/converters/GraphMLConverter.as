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
	
	import flash.utils.ByteArray;
	import flash.utils.IDataInput;
	import flash.utils.IDataOutput;
	
	import org.cytoscapeweb.util.Utils;
	import org.cytoscapeweb.util.methods.$each;

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

		// ========[ PUBLIC PROPERTIES ]============================================================
		
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
		public function write(data:DataSet, output:IDataOutput=null):IDataOutput {			
			// init GraphML
			var graphml:XML = new XML(GRAPHML_HEADER);
			
			// add schema
			graphml = addSchema(graphml, data.nodes.schema, NODE, NODE_ATTR);
			graphml = addSchema(graphml, data.edges.schema, EDGE, EDGE_ATTR);
			
			// add graph data
			var graph:XML = new XML(<graph/>);
			var ed:Object = data.edges.schema.getFieldByName(DIRECTED).defaultValue;
			// ############################################
			// Patch for a Flare bug:
			// ############################################
			// graph.@[EDGEDEF] = ed==DIRECTED ? DIRECTED : UNDIRECTED;
			graph.@[EDGEDEF] = ed ? DIRECTED : UNDIRECTED;
			// ############################################
			addData(graph, data.nodes.data, data.nodes.schema, NODE, NODE_ATTR);
			addData(graph, data.edges.data, data.edges.schema, EDGE, EDGE_ATTR);
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
            
            var nodeSchema:DataSchema = new DataSchema();
            var edgeSchema:DataSchema = new DataSchema();
            
            // set schema defaults
            nodeSchema.addField(new DataField(ID, DataUtil.STRING));
            edgeSchema.addField(new DataField(ID, DataUtil.STRING));
            edgeSchema.addField(new DataField(SOURCE, DataUtil.STRING));
            edgeSchema.addField(new DataField(TARGET, DataUtil.STRING));
            edgeSchema.addField(new DataField(DIRECTED, DataUtil.BOOLEAN, DIRECTED == graphml.graph.@[EDGEDEF]));
            
            // parse data schema
            var keyList:XMLList = graphml..key;
            for each (var key:XML in keyList) {
                id       = key.@[ID].toString();
                group    = key.@[FOR].toString();
                attrName = key.@[ATTRNAME].toString();
                type     = toType(key.@[ATTRTYPE].toString());
                def = key[DEFAULT].toString();
                def = def != null && def.length > 0
                    ? DataUtil.parseValue(def, type) : null;
                    
                // Patch: accept "all" for node and edge schemas:
                // ############################################
                if (group === NODE || group === ALL)
                    nodeSchema.addField(new DataField(attrName, type, def, id));
                if (group === EDGE || group === ALL)
                    edgeSchema.addField(new DataField(attrName, type, def, id));
                // ############################################
            }
            
            // parse nodes
            var nodeList:XMLList = graphml..node;
            for each (var node:XML in nodeList) {
                id = node.@[ID].toString();
                lookup[id] = (n = parseData(node, nodeSchema));
                nodes.push(n);
            }
            
            // parse edges
            var edgeList:XMLList = graphml..edge;
            for each (var edge:XML in edgeList) {
                id  = edge.@[ID].toString();
                sid = edge.@[SOURCE].toString();
                tid = edge.@[TARGET].toString();
                
                // error checking
                if (!lookup.hasOwnProperty(sid))
                    error("Edge "+id+" references unknown node: "+sid);
                if (!lookup.hasOwnProperty(tid))
                    error("Edge "+id+" references unknown node: "+tid);
                                
                edges.push(e = parseData(edge, edgeSchema));
            }
            
            return new DataSet(
                new DataTable(nodes, nodeSchema),
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
				
				var key:XML = new XML(<key/>);
				key.@[ID] = field.id;
				key.@[FOR] = group;
				key.@[ATTRNAME] = field.name;
				key.@[ATTRTYPE] = fromType(field.type);
			
				if (field.defaultValue != null) {
					var def:XML = new XML(<default/>);
					def.appendChild(toString(field.defaultValue, field.type));
					key.appendChild(def);
				}
				
				xml = xml.appendChild(key);
			}
			return xml;
		}
		
		private static function addData(xml:XML, tuples:Array, schema:DataSchema, tag:String, attrs:Object):void {
			$each(tuples, function(i:uint, tuple:Object):void {
				var x:XML = new XML("<"+tag+"/>");
				
				for (var name:String in tuple) {
				    var value:* = tuple[name];
					var field:DataField = schema.getFieldByName(name);
					if (field != null && value == field.defaultValue) continue;

                    var dataType:int = field != null ? field.type : Utils.dataType(value);
                    var type:String = fromType(dataType); // GraphML type

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

				xml.appendChild(x);
			});
		}	
		
		// -- static helpers --------------------------------------------------
		
		private static function toString(o:Object, type:int):String {
			return o.toString(); // TODO: formatting control?
		}
		
		private static function toType(type:String):int {
			switch (type) {
				case INT:
				case INTEGER:
					return DataUtil.INT;
				case LONG:
				case FLOAT:
				case DOUBLE:
				case REAL:
					return DataUtil.NUMBER;
				case BOOLEAN:
					return DataUtil.BOOLEAN;
				case DATE:
					return DataUtil.DATE;
				case STRING:
				default:
					return DataUtil.STRING;
			}
		}
		
		private static function fromType(type:int):String {
			switch (type) {
				case DataUtil.INT: 		return INT;
				case DataUtil.BOOLEAN: 	return BOOLEAN;
				case DataUtil.NUMBER:	return DOUBLE;
				case DataUtil.DATE:		return DATE;
				case DataUtil.STRING:
				default:				return STRING;
			}
		}
		
		private static function error(msg:String):void {
			throw new Error(msg);
		}	
	}
}