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
    import flare.vis.data.DataList;
    import flare.vis.data.DataSprite;
    import flare.vis.data.EdgeSprite;
    import flare.vis.data.NodeSprite;
    
    import flash.geom.Point;
    import flash.utils.ByteArray;
    import flash.utils.IDataInput;
    import flash.utils.IDataOutput;
    
    import org.cytoscapeweb.model.error.CWError;
    import org.cytoscapeweb.util.DataSchemaUtils;
    import org.cytoscapeweb.util.ErrorCodes;
    import org.cytoscapeweb.util.Groups;
    import org.cytoscapeweb.util.Utils;
    import org.cytoscapeweb.vis.data.CompoundNodeSprite;
    
    
    /**
     * Converts data between plain objects (usually objects set through JavaScript) and 
     * flare DataSet instances.
     */
    public class ExternalObjectConverter implements IDataConverter {
        
        // ========[ CONSTANTS ]====================================================================
        
        public static const SCHEMA:String = "dataSchema";
        public static const DATA:String = "data";
        public static const NAME:String = "name";
        public static const TYPE:String = "type";
        public static const DEF_VALUE:String = "defValue";
        
        private static const NODE_ATTR:Object = {
            id: 1
        }
        private static const EDGE_ATTR:Object = {
            id: 1, directed: false, source: 1, target: 1
        };
        
        private static const INT:String = "int";
        private static const INTEGER:String = "integer";
        private static const NUMBER:String = "number";
        private static const BOOLEAN:String = "boolean";
        private static const STRING:String = "string";
        private static const OBJECT:String = "object";
        
        // ========[ PUBLIC METHODS ]===============================================================
        
        /** @inheritDoc */
        public function read(input:IDataInput, schema:DataSchema=null):DataSet {
            var obj:Object = input.readObject();
            return convertToDataSet(obj, schema);
        }
        
        /** @inheritDoc */
        public function write(ds:DataSet, output:IDataOutput=null):IDataOutput {
            // Plain object to output
            var obj:Object = toExtNetworkModel(ds);
            
            if (output == null) output = new ByteArray();
            output.writeObject(obj);
            
            return output;
        }
        
        /**
         * Convert a plain object object into a DataSet instance.
         * @param network the plain Object that contains "schema" and "data" fields.
         * @param schema a DataSchema (typically null, as the object should contains schema information)
         * @return the DataSet instance
         */
        public static function convertToDataSet(network:Object, schema:DataSchema=null):DataSet {
            var lookup:Object = {};
            var nodes:Array = []; // array of CompoundNodeSprites
            var edges:Array = []; // array of plain objects
            var obj:Object;
            var f:DataField, name:String, type:int, defValue:*, mandatoryDefValue:*;
            var directed:Boolean = false;
            
            if (network == null) network = {};
            if (network[SCHEMA] == null) network[SCHEMA] = {};
            if (network[DATA] == null) network[DATA] = {};
            
            // Convert from schema objects:
            var extNodesSchema:Array = network[SCHEMA][Groups.NODES];
            var extEdgesSchema:Array = network[SCHEMA][Groups.EDGES];
            
            for each (obj in extEdgesSchema) {
                if (obj[NAME] === DataSchemaUtils.DIRECTED) {
                    // It might be the edge's directed field...
                    directed = (obj[DEF_VALUE] == true);
                    break;
                }
            }
            
            var nodeSchema:DataSchema = DataSchemaUtils.minimumNodeSchema();
            var edgeSchema:DataSchema = DataSchemaUtils.minimumEdgeSchema(directed);
            
            var addToSchema:Function = function(objArr:Array, schema:DataSchema):void {
                for each (obj in objArr) {
                    name = obj[NAME];
                    if (name == null) throw new Error("Missing '"+NAME+"' field for Schema object.");
                    
                    type = toCW_Type(obj[TYPE]);
                    f = schema.getFieldByName(name);
                    
                    if (f == null) {
                        // Some types always require a default value, because they don't accept null.
                        switch(type) {
                            case DataUtil.INT: mandatoryDefValue = 0; break;
                            case DataUtil.BOOLEAN: mandatoryDefValue = false; break;
                            default: mandatoryDefValue = null;
                        }
                        
                        try {
                            defValue = normalizeDataValue(obj[DEF_VALUE], type, mandatoryDefValue);
                        } catch (err:Error) {
                            throw new CWError("Invalid default value of '" + name + "'--" + err.message,
                                              ErrorCodes.INVALID_DATA_CONVERSION);
                        }
                        
                        schema.addField(new DataField(name, type, defValue, name));
                    }
                }
            };

            addToSchema(extNodesSchema, nodeSchema);
            addToSchema(extEdgesSchema, edgeSchema);
            
            // Convert from plain data objects:
            var extNodesData:Array = network[DATA][Groups.NODES];
            var extEdgesData:Array = network[DATA][Groups.EDGES];
            
            // Read external node and edge data, and populate the nodes and 
            // edges array. We cannot use an array of plain nodes directly,
            // since Data.fromDataSet function creates NodeSprite instances
            // for node data. Therefore, nodes array will be populated by
            // CompoundNodeSprite instances.
            readData(extNodesData, extEdgesData, nodes, edges, nodeSchema, edgeSchema, lookup);
                        
            var cns:CompoundNodeSprite;
            var parent:CompoundNodeSprite;
            
            // add child nodes into the appropriate compounds using data parent
            // id information set by the readData function.
            for each (cns in nodes) {
                if (cns.data.parent != null) {
                    parent = (lookup[cns.data.parent] as CompoundNodeSprite); 
                    
                    // add the current compound node as a child
                    parent.addNode(cns);
                }
            }
            
            return new DataSet(
                new DataTable(nodes, nodeSchema),
                new DataTable(edges, edgeSchema)
            );
        }
        
        /**
         * Recursively reads node and edge data from the given external data
         * arrays, and populates the given nodes and edges arrays accordingly.
         * While edges array is populated with Object instances, nodes array 
         * is populated with CompoundNodeSprite instances.
         * 
         * @param extNodesData  external data array for nodes
         * @param extEdgesData  external data array for edges
         * @param nodes         node array to be populated
         * @param edges         edge array to be populated
         * @param nodeSchema    DataSchema for data fields of nodes
         * @param edgeSchema    DataSchema for data fields of edges
         * @param lookup        lookup map (by id) for nodes
         */
        private static function readData(extNodesData:Array,
                                         extEdgesData:Array,
                                         nodes:Array,
                                         edges:Array,
                                         nodeSchema:DataSchema,
                                         edgeSchema:DataSchema,
                                         lookup:Object):void {
            var obj:Object;
            var id:String, sid:String, tid:String;
            var cns:CompoundNodeSprite;
            
            // Nodes
            for each (obj in extNodesData) {
                cns = new CompoundNodeSprite();
                normalizeData(obj, nodeSchema)
                id = obj[DataSchemaUtils.ID];
                cns.data = obj;
                lookup[id] = cns;
                
                // add the node to the array of compound nodes
                nodes.push(cns);
            }
            
            // Edges
            for each (obj in extEdgesData) {
                normalizeData(obj, edgeSchema);
                id  = obj[DataSchemaUtils.ID];
                sid = obj[DataSchemaUtils.SOURCE];
                tid = obj[DataSchemaUtils.TARGET];
                
                if (!lookup.hasOwnProperty(sid))
                    throw new Error("Edge "+id+" references unknown node: "+sid);
                if (!lookup.hasOwnProperty(tid))
                    throw new Error("Edge "+id+" references unknown node: "+tid);
                
                edges.push(obj);
            }
        }
        
        
        public static function toExtSimpleNetworkModel(ds:DataSet):Object {
            var obj:Object = {};
            
            // Add schema
            obj[SCHEMA] = toExtSchema(ds.nodes.schema, ds.edges.schema);
            
            // Add graph data
            obj[DATA] = {};
            obj[DATA][Groups.NODES] = ds.nodes.data;
            obj[DATA][Groups.EDGES] = ds.edges.data;
            
            return obj;
        }
        
        
        /**
         * Creates a network model object representing the nodes and edges in
         * the given data set.
         * 
         * @param ds    DataSet of nodes and edges
         * @return      object representing the given data set
         */
        public static function toExtNetworkModel(ds:DataSet):Object {
            var obj:Object = {};
            
            // Add schema
            obj[SCHEMA] = toExtSchema(ds.nodes.schema, ds.edges.schema);
            
            // Add graph data
            obj[DATA] = {};
            obj[DATA][Groups.NODES] = ds.nodes.data;
            obj[DATA][Groups.EDGES] = ds.edges.data;
            
            return obj;
        }
        
        
        public static function toExtElementsArray(dataSprites:*, zoom:Number):Array {
            var arr:Array = null;
                     
            if (dataSprites is DataList || dataSprites is Array) {
                arr = [];
                for each (var ds:DataSprite in dataSprites) {
                    arr.push(toExtElement(ds, zoom));
                }
            }

            return arr;
        }
        
        public static function toExtElement(ds:DataSprite, zoom:Number):Object {
            var obj:Object = null;
            var p:Point;
            var n:NodeSprite, e:EdgeSprite;
            var scale:Number;

            if (ds != null) {
                // Data (attributes):
                obj = { data: ds.data };

                // Common Visual properties:
                obj.opacity = ds.alpha;
                obj.visible = ds.visible;
                obj.zIndex = ds.parent != null ? ds.parent.getChildIndex(ds) : -1;
                
                if (ds is NodeSprite) {
                    n = ds as NodeSprite;
                    
                    obj.group = Groups.NODES;
                    obj.shape = n.shape;
                    obj.size = Math.max(n.width, n.height);
                    obj.width = n.width;
                    obj.height = n.height;
                    obj.color = n.props.transparent ? "transparent" : Utils.rgbColorAsString(n.fillColor);
                    obj.borderColor = Utils.rgbColorAsString(n.lineColor);
                    obj.borderWidth = n.lineWidth;
                    obj.nodesCount = n is CompoundNodeSprite ? CompoundNodeSprite(n).nodesCount : 0;
//                    obj.degree = n.degree;
//                    obj.indegree = n.inDegree;
//                    obj.outdegree = n.outDegree;
                    
                    // Global coordinates:
                    p = getGlobalCoordinate(n);
                    obj.x = p.x;
                    obj.y = p.y;
                    obj.rawX = p.x / zoom;
                    obj.rawY = p.y / zoom;
                } else {
                    obj.group = Groups.EDGES;

                    e = ds as EdgeSprite;
                    obj.color = Utils.rgbColorAsString(e.lineColor);
                    obj.width = ds.lineWidth;
                    obj.sourceArrowShape = e.props.sourceArrowShape;
                    obj.targetArrowShape = e.props.targetArrowShape;
                    obj.sourceArrowColor = e.props.sourceArrowColor;
                    obj.targetArrowColor = e.props.targetArrowColor;
                    obj.curvature = e.props.curvature;
                    obj.merged = e.props.$merged ? true : false;
                    
                    if (e.props.$merged) {
                        var ee:Array = e.props.$edges;
                        ee = toExtElementsArray(ee, zoom);
                        obj.edges = ee;
                    }
                }
            }
           
            return obj;
        }
        
        public static function getGlobalCoordinate(n:NodeSprite):Point {
            var p:Point = new Point(n.x, n.y);
            if (n.parent) p = n.parent.localToGlobal(p);
            
            return p;
        }
        
        public static function toExtSchema(nodesSchema:DataSchema, edgesSchema:DataSchema):Object {
            var obj:Object = {};
            
            var convertFromDataFields:Function = function(fields:Array):Array {
                var arr:Array = [];
                
                if (fields != null) {
                    for each (var df:DataField in fields) {
                        var type:* = fromCW_Type(df.type);
                        var f:Object = {};
                        f[NAME] = df.name;
                        f[TYPE] = type;
                        f[DEF_VALUE] = df.defaultValue;
                        arr.push(f);
                    }
                }
                
                return arr;
            };
            
            obj[Groups.NODES] = convertFromDataFields(nodesSchema.fields);
            obj[Groups.EDGES] = convertFromDataFields(edgesSchema.fields);
            
            return obj;
        }
        
        public static function normalizeData(data:Object, schema:DataSchema):void {
            var name:String, field:DataField, value:*;
            
            // Set default values, if necessary:
            for (var i:int = 0; i < schema.numFields; ++i) {
                field = schema.getFieldAt(i);
                name = field.name;
                value = data[name];
                
                try {
                    data[name] = normalizeDataValue(value, field.type, field.defaultValue);
                } catch (err:Error) {
                    throw new CWError("Invalid value of '" + field.name + "'--" + err.message,
                                      ErrorCodes.INVALID_DATA_CONVERSION);
                }
            }
            
            // Look for missing fields:
            for (name in data) {
                field = schema.getFieldByName(name);

                if (field == null)
                    throw new Error("Cannot convert data object: Missing schema field for '"+name+"'. ");
            }
        }
        
        public static function normalizeDataValue(value:*, type:int, defValue:*=undefined):* {
            // Set default value, if necessary:
            if (value === undefined) value = defValue !== undefined ? defValue : null;

            // Validate and normalize numeric values:
            if (type === DataUtil.INT) {
                if ( value == null || !(typeof value === "number") || isNaN(value) )
                    throw new CWError("Invalid data type ("+(typeof value)+") for field of type 'int': " + value,
                                      ErrorCodes.INVALID_DATA_CONVERSION);
                value = int(value);
            } else if (type === DataUtil.NUMBER) {
                if (value === undefined) value = null;
                
                if ( value != null && (!(typeof value === "number") || isNaN(value)) )
                    throw new CWError("Invalid data type ("+(typeof value)+") for field of type 'number': " + value,
                                      ErrorCodes.INVALID_DATA_CONVERSION);
            } else if (type === DataUtil.BOOLEAN) {
                if ( !(value is Boolean) )
                    throw new CWError("Invalid data type ("+(typeof value)+") for field of type 'boolean': " + value,
                                      ErrorCodes.INVALID_DATA_CONVERSION);
            } else if (type === DataUtil.STRING) {
                if ( value != null && !(value is String) )
                    throw new CWError("Invalid data type ("+(typeof value)+") for field of type 'string': " + value,
                                      ErrorCodes.INVALID_DATA_CONVERSION);
            }
            
            return value
        }
        
        // ========[ PRIVATE METHODS ]==============================================================
        
        // -- static helpers --------------------------------------------------
        
        private static function toCW_Type(type:String):int {
            switch (type) {
                case INT:
                case INTEGER: return DataUtil.INT;
                case NUMBER:  return DataUtil.NUMBER;
                case BOOLEAN: return DataUtil.BOOLEAN;
                case STRING:  return DataUtil.STRING;
                case OBJECT:
                default:      return DataUtil.OBJECT;
            }
        }
        
        private static function fromCW_Type(type:int):String {
            switch (type) {
                case DataUtil.INT:      return INT;
                case DataUtil.BOOLEAN:  return BOOLEAN;
                case DataUtil.NUMBER:   return NUMBER;
                case DataUtil.STRING:   return STRING;
                case DataUtil.DATE:
                case DataUtil.OBJECT:
                default:                return OBJECT;
            }
        }
    }
}