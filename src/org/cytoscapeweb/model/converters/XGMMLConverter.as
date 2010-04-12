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
    import flare.vis.data.Data;
    import flare.vis.data.DataSprite;
    import flare.vis.data.NodeSprite;
    
    import flash.geom.Point;
    import flash.utils.ByteArray;
    import flash.utils.IDataInput;
    import flash.utils.IDataOutput;
    
    import mx.formatters.DateFormatter;
    import mx.utils.StringUtil;
    
    import org.cytoscapeweb.model.data.DiscreteVizMapperVO;
    import org.cytoscapeweb.model.data.GraphicsDataTable;
    import org.cytoscapeweb.model.data.VisualPropertyVO;
    import org.cytoscapeweb.model.data.VisualStyleVO;
    import org.cytoscapeweb.util.ArrowShapes;
    import org.cytoscapeweb.util.Fonts;
    import org.cytoscapeweb.util.NodeShapes;
    import org.cytoscapeweb.util.Utils;
    import org.cytoscapeweb.util.VisualProperties;
    import org.cytoscapeweb.util.methods.$each;


    /**
     * Converts data between XGMML markup and flare DataSet instances.
     * 
     * XGMML 1.0 Draft Specification:
     * 
     *   http://www.cs.rpi.edu/~puninj/XGMML/DOC/xgmml_schema.html
     *   http://www.cs.rpi.edu/~puninj/XGMML/draft-xgmml.html
     * 
     *   GLOBAL attributes (all XGMML elements can have them):
     * 
     *     id - Unique number to identify the elements of XGMML document
     *     name - String to identify the elements of XGMML document
     *     label - Text representation of the XGMML element
     *     labelanchor - Anchor position of the label related to the graphic representation of the XGMML element
     *
     *   GRAPH attributes:
     * 
     *     directed - Boolean value. Graph is directed if this attribute is 1 (true) otherwise is undirected. The default value is 0 (false).
     *     Vendor - Unsafe GML key to show the application that created the XGMML file.
     *     Scale - Unsafe numeric value to scale the size of the displayed graph.
     *     Rootnode - Unsafe id number to identify the root node of the graph. Useful for tree drawing.
     *     Layout - Unsafe string that represent the layout that can be applied to display the graph. The layout name is the name of the algorithm to assign position to the nodes of the graph. For example: circular.
     *     Graphic - Unsafe boolean value. If this value is 1 (true), the XGMML file includes graphical representation of the graph. False means that the XGMML file includes only topological structure of the graph and the application program is free to display the graph using any layout.
     * 
     *   NODE attributes:
     * 
     *     edgeanchor - GML key to position the edges related to the node
     *     weight - value (usually numerical) to show the node weight -Useful for weight graphs
     * 
     *   EDGE attributes:
     * 
     *     source - The id number of the source node of the edge
     *     target - The id number of the target node of the edge
     *     weight - A string (usually a number) representing the weight of the edge.
     * 
     *   ATT Attributes:
     * 
     *     name - Global attribute that contains the name of the metadata information.
     *     value - The value of the metadata information.
     *     type - The object type of the metadata information. Please refer to object type section. The default object type is string.
     */
    public class XGMMLConverter implements IDataConverter {
    	
    	private namespace _defNamespace = "http://www.cs.rpi.edu/XGMML";
        use namespace _defNamespace;
    	
        // ========[ CONSTANTS ]====================================================================
        
        private static const VIZMAP_ATTR_PREFIX:String = "vizmap:";
        
        private static const NODE_ATTR:Object = {
            id: 1, label: "", weight: 1
        }
        private static const EDGE_ATTR:Object = {
            id: 1, source: 1, target: 1, label: "", weight: 1, directed: false
        };
        private static const NODE_GRAPHICS_ATTR:Object = {
            type: [VisualProperties.NODE_SHAPE],
            h: [VisualProperties.NODE_SIZE],
            w: [VisualProperties.NODE_SIZE],
            fill: [VisualProperties.NODE_COLOR],
            width: [VisualProperties.NODE_LINE_WIDTH],
            outline: [VisualProperties.NODE_LINE_COLOR],
            'cy:nodeTransparency': [VisualProperties.NODE_ALPHA],
            'cy:nodeLabelFont': [VisualProperties.NODE_LABEL_FONT_NAME, VisualProperties.NODE_LABEL_FONT_SIZE]
        };
        private static const EDGE_GRAPHICS_ATTR:Object = {
            width: [VisualProperties.EDGE_WIDTH], 
            fill: [VisualProperties.EDGE_COLOR],
            'cy:sourceArrow': [VisualProperties.EDGE_SOURCE_ARROW_SHAPE],
            'cy:targetArrow': [VisualProperties.EDGE_TARGET_ARROW_SHAPE],
            'cy:sourceArrowColor': [VisualProperties.EDGE_SOURCE_ARROW_COLOR],
            'cy:targetArrowColor': [VisualProperties.EDGE_TARGET_ARROW_COLOR]
        };
    
        // TODO: customizable!!!
        // **********************
        private static const DOCUMENT_VERSION:String = "0.1";
        private static const GRAPH_LABEL:String    = "Cytoscape Web";
//        private static const NETWORK_TITLE:String  = "Cytoscape Web";
//        private static const NETWORK_TYPE:String   = "Protein-Protein Interaction";
//        private static const NETWORK_SOURCE:String = "http://www.cytoscape.org/";
//        private static const NETWORK_ABOUT:String  = "http://www.cytoscape.org/";
//        private static const NETWORK_FORMAT:String = "Cytoscape-XGMML";
        // **********************
        
        public static const DEFAULT_NAMESPACE:String   = "http://www.cs.rpi.edu/XGMML";
        private static const DMCI_NAMESPACE:String      = "http://purl.org/dc/elements/1.1/";
        private static const XLINK_NAMESPACE:String     = "http://www.w3.org/1999/xlink";
        private static const RDF_NAMESPACE:String       = "http://www.w3.org/1999/02/22-rdf-syntax-ns#";
        private static const CYTOSCAPE_NAMESPACE:String = "http://www.cytoscape.org";
    
        private static const ROOT:String = "<graph/>";       

        private static const GRAPH:String      = "graph";
        private static const DIRECTED:String   = "directed";
        private static const UNDIRECTED:String   = "undirected";
        private static const GRAPHIC_INFO:String = "Graphic";
        
        private static const ATTRIBUTE:String  = "att";
        private static const GRAPHICS:String   = "graphics";
        private static const DEFAULT:String    = "default";
        
        private static const NODE:String   = "node";
        private static const EDGE:String   = "edge";
        private static const ID:String     = "id";
        private static const LABEL:String  = "label";
        private static const SOURCE:String = "source";
        private static const TARGET:String = "target";
        private static const WEIGHT:String = "weight";
        private static const DATA:String   = "data";
        private static const TYPE:String   = "type";
        private static const NAME:String   = "name";
        private static const VALUE:String  = "value";
        
        private static const INTEGER:String = "integer";
        private static const REAL:String    = "real";
        private static const LIST:String    = "list";
        private static const STRING:String  = "string";
        private static const BOOLEAN:String  = "boolean";
        
        private static const TRUE:String  = "1";
        private static const FALSE:String = "0";
        
        // It has to specify the XGMML default namespace before getting nodes/edges:
        private static const NS:Namespace = new Namespace(DEFAULT_NAMESPACE);
        private static const CY:Namespace = new Namespace(CYTOSCAPE_NAMESPACE);
    	
        // ========[ PRIVATE PROPERTIES ]===========================================================
        
        private var _noGraphicInfo:Boolean = false;
        private var _style:VisualStyleVO;
        private var _points:Object;
        private var _minX:Number = Number.POSITIVE_INFINITY;
        private var _minY:Number = Number.POSITIVE_INFINITY;
        private var _maxX:Number = Number.NEGATIVE_INFINITY
        private var _maxY:Number = Number.NEGATIVE_INFINITY;
        
        private function get dateFormatter():DateFormatter {
            var dtf:DateFormatter = new DateFormatter();
            dtf.formatString = "YYYY-MM-DD JJ:NN:SS"; //e.g. "2009-01-26 00:43:57"
            return dtf;
        }
        
        // ========[ PUBLIC PROPERTIES ]============================================================
   
        public function get style():VisualStyleVO {
            return _style;
        }
        
        public function get points():Object {
            return _points;
        }
   
        // ========[ CONSTRUCTOR ]==================================================================
        
        public function XGMMLConverter(style:VisualStyleVO) {
        	_style = style;
        }
        
        // ========[ PUBLIC METHODS ]===============================================================
        
        // -- reader ----------------------------------------------------------
        
        /** @inheritDoc */
        public function read(input:IDataInput, schema:DataSchema=null):DataSet {
            var str:String = input.readUTFBytes(input.bytesAvailable);
            var idx:int = str.indexOf(ROOT);
            if (idx > 0) {
                str = str.substr(0, idx+ROOT.length) + str.substring(str.indexOf(">", idx));
            }
            return parse(XML(str), schema);
        }
        
        /**
         * Parses a XGMML object into a DataSet instance.
         * @param xgmml the XML object containing XGMML markup
         * @param schema a DataSchema (typically null, as XGMML contains
         *  schema information)
         * @return the parsed DataSet instance
         */
        public function parse(xgmml:XML, schema:DataSchema=null):DataSet {
            var lookup:Object = {};
            var nodes:Array = [], n:Object;
            var edges:Array = [], e:Object;
            var id:String, sid:String, tid:String;
            var def:Object, type:int;
            var group:String, attrName:String, attrType:String;
            
            // Does this XGMML model have graphical information?
            // Let's just check for explicit false statements, as if the default were true,
            // because Cytoscape never creates this attribute, but has graphics info.
            _noGraphicInfo = String(xgmml.@[GRAPHIC_INFO]) === FALSE;
            
            var nodeSchema:DataSchema = new DataSchema();
            var edgeSchema:DataSchema = new DataSchema();
            
            // set schema defaults
            nodeSchema.addField(new DataField(ID, DataUtil.STRING));
            nodeSchema.addField(new DataField(LABEL, DataUtil.STRING));
            nodeSchema.addField(new DataField(WEIGHT, DataUtil.NUMBER));
            
            edgeSchema.addField(new DataField(ID, DataUtil.STRING));
            edgeSchema.addField(new DataField(SOURCE, DataUtil.STRING));
            edgeSchema.addField(new DataField(TARGET, DataUtil.STRING));
            edgeSchema.addField(new DataField(LABEL, DataUtil.STRING)); // Edge label cannot be an ID!
            edgeSchema.addField(new DataField(WEIGHT, DataUtil.NUMBER));
            var directed:Boolean = TRUE == xgmml.@[DIRECTED] ? true : false;
            edgeSchema.addField(new DataField(DIRECTED, DataUtil.BOOLEAN, directed));

            // Parse Global
            // ------------------------------------------------------
            var bc:* = xgmml.att.(@name == "backgroundColor").@value;
            if (bc[0] != null) {
                bc = VisualProperties.parseValue(VisualProperties.BACKGROUND_COLOR, bc[0].toString());
                style.addVisualProperty(new VisualPropertyVO(VisualProperties.BACKGROUND_COLOR, bc));
            }
            
            // Parse nodes
            // ------------------------------------------------------
            for each (var node:XML in xgmml.node) {
                id = node.@[ID].toString();
                lookup[id] = (n = parseData(node, nodeSchema));
                nodes.push(n);
                parseGraphics(id, node, NODE_GRAPHICS_ATTR);
            }
            
            // Parse edges
            // ------------------------------------------------------
            // Parse IDs first:
            var edgesIds:Array = [];
            
            var edge:XML;
            for each (edge in xgmml.edge) {
                id = edge.@[ID].toString();
                if (StringUtil.trim(id) !== "") edgesIds.push(id);
            }
            
            var count:int = 1;
            
            // Parse the attributes:
            for each (edge in xgmml.edge) {
                id  = edge.@[ID].toString();
                sid = edge.@[SOURCE].toString();
                tid = edge.@[TARGET].toString();

				if (StringUtil.trim(id) === "") {
	                while (edgesIds.indexOf(count.toString()) != -1) ++count;
	                id = count.toString();
	                edgesIds.push(id);
	                edge.@[ID] = id;
	                count++;
				}
                
                // error checking
                if (!lookup.hasOwnProperty(sid))
                    error("Edge "+id+" references unknown node: "+sid);
                if (!lookup.hasOwnProperty(tid))
                    error("Edge "+id+" references unknown node: "+tid);
                                
                edges.push(e = parseData(edge, edgeSchema));
                parseGraphics(id, edge, EDGE_GRAPHICS_ATTR);
            }
            
            return new DataSet(
                new DataTable(nodes, nodeSchema),
                new DataTable(edges, edgeSchema)
            );
        }

        // -- writer ----------------------------------------------------------
        
        /** @inheritDoc */
        public function write(dtset:DataSet, output:IDataOutput=null):IDataOutput {
        	var bgColor:uint = style.getValue(VisualProperties.BACKGROUND_COLOR) as uint;
        	
            // Init XGMML:
            var xgmml:XML = 
	            <graph label={GRAPH_LABEL}
	                   xmlns:dc={DMCI_NAMESPACE}
	                   xmlns:xlink={XLINK_NAMESPACE}
	                   xmlns:rdf={RDF_NAMESPACE}
	                   xmlns:cy={CYTOSCAPE_NAMESPACE}
	                   xmlns={DEFAULT_NAMESPACE}
	                   directed={Data.fromDataSet(dtset).directedEdges ? TRUE : FALSE}
	                   Graphic={TRUE}>
                    <att name="documentVersion" value={DOCUMENT_VERSION}/>
<!--
                    <att name="networkMetadata">
	                    <rdf:RDF>
		                    <rdf:Description rdf:about={NETWORK_ABOUT}>
			                    <dc:type>{NETWORK_TYPE}</dc:type>
							    <dc:description>N/A</dc:description>
							    <dc:identifier>N/A</dc:identifier>
							    <dc:date>{dateFormatter.format(new Date())}</dc:date>
							    <dc:title>{NETWORK_TITLE}</dc:title>
							    <dc:source>{NETWORK_SOURCE}</dc:source>
							    <dc:format>{NETWORK_FORMAT}</dc:format>
	                        </rdf:Description>
	                    </rdf:RDF>
                    </att>
-->
					<att type="string" name="backgroundColor" value={Utils.rgbColorAsString(bgColor)}/>
					<att type="real" name="GRAPH_VIEW_ZOOM" value="1"/>
					<att type="real" name="GRAPH_VIEW_CENTER_X" value="0"/>
					<att type="real" name="GRAPH_VIEW_CENTER_Y" value="0"/>
                </graph>;
            
            // Add edge and node tags:
            addTags(xgmml, dtset, NODE);
            addTags(xgmml, dtset, EDGE);
            
            // To center the view:
            var w:Number = _maxX - _minX;
            var h:Number = _maxY - _minY;
            if (w != Infinity && w != -Infinity)
                xgmml.att.(@name == "GRAPH_VIEW_CENTER_X").@value = w/2;
            if (h != Infinity && h != -Infinity)
                xgmml.att.(@name == "GRAPH_VIEW_CENTER_Y").@value = h/2;
            
            // Return output:
            if (output == null) output = new ByteArray();
            output.writeUTFBytes(xgmml.toXMLString());
            
            return output;
        }
        
        // ========[ PRIVATE METHODS ]==============================================================
        
        private function parseData(tag:XML, schema:DataSchema):Object {
            var data:Object = {};
            var name:String, field:DataField, value:Object;
            
            // set default values
            for (var i:int = 0; i < schema.numFields; ++i) {
                field = schema.getFieldAt(i);
                data[field.name] = field.defaultValue;
            }
            
            // get attribute values
            for each (var attribute:XML in tag.@*) {
                name = attribute.name().toString();
                field = schema.getFieldByName(name);
                data[name] = DataUtil.parseValue(attribute[0].toString(), field.type);
            }
            
            // get "att" tags:
            for each (var att:XML in tag.att) {
            	parseAtt(att, schema, data);
            }
            
            // TODO: get RDF (Resource Description Framework) ???
            
            return data;
        }
        
        private function parseAtt(att:XML, schema:DataSchema, data:Object):void {
            var field:DataField, value:Object;
            var name:String = att.@[NAME].toString();
            
            if (name == null) return;
            
            var type:int = toCLType(att.@[TYPE].toString());
            
            // Add the attribute definition to the schema:
            if (schema.getFieldById(name) == null) {
                schema.addField(new DataField(name, type));
            }
            
            // Add <att> tags data:
            if (type === DataUtil.OBJECT) {
                // If it is a list, add the nested <att> tags recursively:
                var arr:Array = [];
                for each (var innerAtt:XML in att.att) {
                    var innerData:*;             
                    if (innerAtt.@[NAME][0] !== undefined) {
                        innerData = {};
                        parseAtt(innerAtt, schema, innerData);
                    } else {
                        var innerType:int = toCLType(innerAtt.@[TYPE].toString());
                        innerData = DataUtil.parseValue(innerAtt.@[VALUE], innerType);
                    }
                    arr.push(innerData);
                }
                data[name] = arr;
            } else {
                // Otherwise, just add the single att data:
                data[name] = DataUtil.parseValue(att.@[VALUE], type);
            }
        }

        private function parseGraphics(id:String, xml:XML, attrs:Object):void {
            // Note Cytoscape does not set the "Graphic" attribute,
            // so we just check whether or not there is a graphics tag:
            var g:XML = xml[GRAPHICS][0];
            
            if (!(g == null || _noGraphicInfo)) {
                // Styles (e.g. color, width...):
                for (var k:String in attrs) {
                    var v:*;
                    if (k.indexOf('cy:') === 0)
                        v = g.@CY::[k.replace('cy:', '')];
                    else
                        v = g.@[k]

                    if (v[0] != null) {
                        v = v[0].toString();
                        var propNames:Array = attrs[k];
                        for each (var pName:String in propNames) {
                            addVisualProperty(id, pName, v);
                        }
                    }
                }
                // Positioning (x,y):
                if (xml.localName() === NODE) {
                	var x:Number = g.@x[0]; var y:Number = g.@y[0];
                	if (!isNaN(x) && !isNaN(y)) {
                	    var p:Point = new Point(x, y);
                	    if (_points == null) _points = {};
                	    _points[id] = p;
                    }
                }
            }
        }

        private function addTags(xml:XML, dtset:DataSet, tagName:String):void {
            var attrs:Object;
            var graphAttrs:Object;
            var table:DataTable;
            
            if (tagName == NODE) {
            	table = dtset.nodes;
            	attrs = NODE_ATTR;
            	graphAttrs = NODE_GRAPHICS_ATTR;
            } else {
            	table = dtset.edges;
            	attrs = EDGE_ATTR;
            	graphAttrs = EDGE_GRAPHICS_ATTR;
            }
            
            var schema:DataSchema = table.schema;
            var tuples:Object = (table is GraphicsDataTable) ? GraphicsDataTable(table).dataSprites : table.data;
            
            $each(tuples, function(i:uint, obj:Object):void {
            	var data:Object = (obj is DataSprite) ? DataSprite(obj).data : table.data;
                var x:XML = <{tagName}/>;
                
                for (var name:String in data) {
                    var field:DataField = schema.getFieldByName(name);
                    
                    if (attrs.hasOwnProperty(name) &&
                        name !== WEIGHT) { // Cytoscape won't parse regular weight attributes...
                        // add as attribute
                        x.@[name] = toString(data[name], field.type);
                    } else {
                        if (data[name] != null) {
                            addAtt(x, name, schema, data);
                        }
                    }
                }
                
                // Cytoscape requires unique labels:
                if (data[LABEL] === undefined) x.@[LABEL] = toString(data[ID], DataUtil.STRING);
                
                // Write graphics tag:
                if (obj is DataSprite) {
                    var ds:DataSprite = DataSprite(obj);
                    var graphics:XML = <{GRAPHICS}/>;
                    var p:Point;
                    
                    // Node position:
                    if (ds is NodeSprite) {
                        var n:NodeSprite = NodeSprite(ds);
                        
                        if (n.parent != null)
                            p = n.parent.localToGlobal(new Point(n.x, n.y))
                        else
                            p = new Point(0, 0);
                        
                        graphics.@x = p.x;
                        graphics.@y = p.y;
                        
                        // For centering the network view:
                        var ns:Number = n.height;
                        _minX = Math.min(_minX, (n.x - ns/2));
                        _minY = Math.min(_minY, (n.y - ns/2));
                        _maxX = Math.max(_maxX, (n.x + ns/2));
                        _maxY = Math.max(_maxY, (n.y + ns/2));
                    }
                    
                    // Styles (color, width...):
                    for (var k:String in graphAttrs) {
                        addGraphicsAtt(graphics, k, graphAttrs[k], ds.data);
                    }

                    x.appendChild(graphics);
                }
                
                xml.appendChild(x);
            });
        }
        
        private function addAtt(xml:XML, name:String, schema:DataSchema, data:Object):void {
            var field:DataField = schema.getFieldByName(name);
            
            var type:String = fromCLType(field.type);
            var value:Object = data[name];
            
            var att:XML = <{ATTRIBUTE}/>;
            att.@[TYPE] = type;
            att.@[NAME] = name;
            
            // Add <att> tags data:
            if (value is Array) {
                // If it is an array, the att value is a list of other att tags:
                var arr:Array = value as Array;
                for each (var innerData:Object in arr) {
                    for (var innerName:String in innerData) {
                        addAtt(att, innerName, schema, innerData);
                    }
                }
            } else {
                // Otherwise, just add the att value:
                att.@[VALUE] = toString(value, field.type);
            }
      
            xml.appendChild(att);
        }
        
        private function addGraphicsAtt(xml:XML, attrName:String, propNames:Array, data:Object):void {
            var value:* = style.getValue(propNames[0], data);
                
            if (VisualProperties.isColor(propNames[0])) {
                value = Utils.rgbColorAsString(value);
            } else {
                switch (propNames[0]) {
                    case VisualProperties.NODE_SHAPE:
                        if (value != null) value = value.toUpperCase();
                        if (!NodeShapes.isValid(value)) value = NodeShapes.ELLIPSE;
                        break;
                    case VisualProperties.EDGE_SOURCE_ARROW_SHAPE:
                    case VisualProperties.EDGE_TARGET_ARROW_SHAPE:
                        value = fromCLArrowShape(value);
                        break;
                    case VisualProperties.NODE_LABEL_FONT_NAME:
                    case VisualProperties.NODE_LABEL_FONT_SIZE:
                        // e.g. "SansSerif-0-12"
                        value = style.getValue(VisualProperties.NODE_LABEL_FONT_NAME, data);
                        value = fromCLFontName(value);
                        // TODO: BOLD-Italic?
                        value += "-0-";
                        value += style.getValue(VisualProperties.NODE_LABEL_FONT_SIZE, data);
                        break;
                    default:
                        break;
                }
            }
            
            xml.@[attrName] = value;
        }
        
        private function addVisualProperty(id:String, propName:String, value:*):void {
            if (style != null) {
                var vp:VisualPropertyVO = style.getVisualProperty(propName);
                
                if (vp == null) {
                    vp = new VisualPropertyVO(propName);
                    style.addVisualProperty(vp);
                }

                // XGMML graphics values will always be mapped to Discrete Mappers:
                var dm:DiscreteVizMapperVO;
                
                if (vp.vizMapper is DiscreteVizMapperVO && vp.vizMapper.attrName === "id") {
                    dm = DiscreteVizMapperVO(vp.vizMapper);
                } else {
                    dm = new DiscreteVizMapperVO("id", propName);
                    vp.vizMapper = dm;
                }

                value = parseValue(propName, value);
                dm.addEntry(id, value);
            }
        }
        
        // -- static helpers --------------------------------------------------
        
        internal static function parseValue(propName:String, value:*):* {
            if (value != null) {
                switch (propName) {
                    case VisualProperties.EDGE_SOURCE_ARROW_SHAPE:
                    case VisualProperties.EDGE_TARGET_ARROW_SHAPE:
                        value = toCLArrowShape(value);
                        break;
                    case VisualProperties.NODE_LABEL_FONT_NAME:
                        // e.g. "Default-0-12"
                        value = value.replace(/(\.[bB]old)?-\d+-\d+/, "");
                        value = StringUtil.trim(value);
                        value = toCLFontName(value);
                        // TODO: BOLD-Italic
                        break;
                    case VisualProperties.NODE_LABEL_FONT_SIZE:
                        // e.g. "SanSerif-0-16"
                        var v:* = value.replace(/.+-\d+-/, "");
                        v = Number(v);
                        if (isNaN(v)) {
                            trace("[ERROR]: XGMMLConverter.parseValue: invalid label font: " + value);
                            v = 12;
                        }
                        value = v;
                        break;
                    default:
                        value = VisualProperties.parseValue(propName, value);
                        break;
                }
            }
            
            return value;
        }
        
        private static function toString(o:Object, type:int):String {
            return o != null ? o.toString() : ""; // TODO: formatting control?
        }
        
        /**
         * Converts from XGMML data types to Flare types.
         * XGMML TYPES: list | string | integer | real
         */
        private static function toCLType(type:String):int {
            switch (type) {
                case INTEGER: return DataUtil.INT;
                case REAL:    return DataUtil.NUMBER;
                case LIST:    return DataUtil.OBJECT;
                case STRING:
                default:      return DataUtil.STRING;
            }
        }
        
        /**
         * Converts from Flare data types to XGMML types.
         */
        private static function fromCLType(type:int):String {        	
            switch (type) {
                case DataUtil.INT:      return INTEGER;
                case DataUtil.NUMBER:   return REAL;
                case DataUtil.OBJECT:   return LIST;
                case DataUtil.BOOLEAN:  return BOOLEAN;
                case DataUtil.DATE:
                case DataUtil.STRING:
                default:                return STRING;
            }
        }
        
        private static function fromCLArrowShape(shape:String):String {
            shape = ArrowShapes.parse(shape);
            switch (shape) {
                case ArrowShapes.DELTA:   return "3";
                case ArrowShapes.DIAMOND: return "9";
                case ArrowShapes.CIRCLE:  return "12";
                case ArrowShapes.T:       return "15";
                default:                  return "0";
            }
        }
        
        private static function toCLArrowShape(shape:String):String {
            switch (shape) {
                case "3":  return ArrowShapes.DELTA;
                case "9":  return ArrowShapes.DIAMOND;
                case "12": return ArrowShapes.CIRCLE;
                case "15": return ArrowShapes.T;
                default:   return ArrowShapes.NONE;
            }
        }
    
        private static function fromCLFontName(font:String):String {
            switch (font) {
                case null:
                case "":
                case Fonts.SANS_SERIF: return "SansSerif";
                case Fonts.SERIF:      return "Serif";
                case Fonts.TYPEWRITER: return "Monospaced";
                default:               return font;
            }
        }
        
        private static function toCLFontName(font:String):String {
            switch (font) {
                case null:
                case "":
                case "Default":
                case "SansSerif":  return Fonts.SANS_SERIF;
                case "Serif":      return Fonts.SERIF;
                case "Monospaced": return Fonts.TYPEWRITER;
                default:           return font;
            }
        }
        
        private static function error(msg:String):void {
            throw new Error(msg);
        }
    }
}
