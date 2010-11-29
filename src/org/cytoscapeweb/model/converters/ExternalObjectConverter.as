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
    
    import org.cytoscapeweb.util.Groups;
    import org.cytoscapeweb.util.Utils;
    
    
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
        
        public static const ID:String = "id";
        public static const SOURCE:String = "source";
        public static const TARGET:String = "target";
        public static const DIRECTED:String = "directed";
        
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
            var nodes:Array = [], edges:Array = [];
            var id:String, sid:String, tid:String;
            var obj:Object;
            var f:DataField;
            var directed:Boolean = false;
            
            if (network == null) network = {};
            if (network[SCHEMA] == null) network[SCHEMA] = {};
            if (network[DATA] == null) network[DATA] = {};
            
            // Convert from schema objects:
            var extNodesSchema:Array = network[SCHEMA][Groups.NODES];
            var extEdgesSchema:Array = network[SCHEMA][Groups.EDGES];
            
            var nodeSchema:DataSchema = new DataSchema();
            nodeSchema.addField(new DataField(ID, DataUtil.STRING));
            
            var edgeSchema:DataSchema = new DataSchema();
            edgeSchema.addField(new DataField(ID, DataUtil.STRING));
            edgeSchema.addField(new DataField(SOURCE, DataUtil.STRING));
            edgeSchema.addField(new DataField(TARGET, DataUtil.STRING));
            
            var addToSchema:Function = function(objArr:Array, schema:DataSchema):void {
                for each (obj in objArr) {
                    var name:String = obj[NAME];
                    if (name == null) throw new Error("Missing '"+NAME+"' field for Schema object.");
                    if (name === DIRECTED) {
                        // Just get the default value; we will add the directed field later
                        directed = (obj[DEF_VALUE] == true);
                    } else {
                        f = schema.getFieldByName(name);
                        if (f == null) {
                            schema.addField(new DataField(name, obj[TYPE], obj[DEF_VALUE], name));
                        }
                    }
                }
            };

            addToSchema(extNodesSchema, nodeSchema);
            addToSchema(extEdgesSchema, edgeSchema);
            
            edgeSchema.addField(new DataField(DIRECTED, DataUtil.BOOLEAN, directed));
            
            // Convert from plain data objects:
            var extNodesData:Array = network[DATA][Groups.NODES];
            var extEdgesData:Array = network[DATA][Groups.EDGES];
            
            // Nodes
            for each (obj in extNodesData) {
                id = "" + obj[ID]; // always convert IDs to String!
                normalizeData(obj, nodeSchema)
                lookup[id] = obj;
                nodes.push(obj);
            }
            
            // Edges
            for each (obj in extEdgesData) {
                id  = "" + obj[ID];
                sid = "" + obj[SOURCE];
                tid = "" + obj[TARGET];
                
                if (!lookup.hasOwnProperty(sid))
                    throw new Error("Edge "+id+" references unknown node: "+sid);
                if (!lookup.hasOwnProperty(tid))
                    throw new Error("Edge "+id+" references unknown node: "+tid);
                
                normalizeData(obj, edgeSchema) 
                edges.push(obj);
            }
            
            return new DataSet(
                new DataTable(nodes, nodeSchema),
                new DataTable(edges, edgeSchema)
            );
        }
        
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
        
        public static function toExtElementsArray(dataSprites:*):Array {
            var arr:Array = null;
                     
            if (dataSprites is DataList || dataSprites is Array) {
                arr = [];
                for each (var ds:DataSprite in dataSprites) {
                    arr.push(toExtElement(ds));
                }
            }

            return arr;
        }
        
        public static function toExtElement(ds:DataSprite):Object {
            var obj:Object = null;

            if (ds != null) {
                // Data (attributes):
                obj = { data: ds.data };

                // Common Visual properties:
                obj.opacity = ds.alpha;
                obj.visible = ds.visible;
                
                if (ds is NodeSprite) {
                    obj.group = Groups.NODES;
                    obj.shape = ds.shape;
                    obj.size = ds.height;
                    obj.color = Utils.rgbColorAsString(ds.fillColor);
                    obj.borderColor = Utils.rgbColorAsString(ds.lineColor);
                    obj.borderWidth = ds.lineWidth;
                    
                    // Global coordinates:
                    var p:Point = new Point(ds.x, ds.y);
                    if (ds.parent) p = ds.parent.localToGlobal(p);
                    obj.x = p.x;
                    obj.y = p.y;
                } else {
                    obj.group = Groups.EDGES;

                    var e:EdgeSprite = EdgeSprite(ds);
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
                        ee = toExtElementsArray(ee);
                        obj.edges = ee;
                    }
                }
            }
           
            return obj;
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
        
        // ========[ PRIVATE METHODS ]==============================================================
        
        private static function normalizeData(data:Object, schema:DataSchema):void {
            var name:String, field:DataField, value:*;
            
            // Set default values, if necessary:
            for (var i:int = 0; i < schema.numFields; ++i) {
                field = schema.getFieldAt(i);
                name = field.name;
                value = data[name];
                if (value === undefined) data[name] = field.defaultValue;
            }
            
            // Look for missing fields:
            for (name in data) {
                field = schema.getFieldByName(name);

                if (field == null)
                    throw new Error("Cannot convert data object: Missing schema field for '"+name+"'. ");
            }
        }
        
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
                case DataUtil.DATE:
                case DataUtil.STRING:   return STRING;
                case DataUtil.OBJECT:
                default:                return OBJECT;
            }
        }
    }
}