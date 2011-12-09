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
    import flare.vis.data.DataList;
    import flare.vis.data.DataSprite;
    import flare.vis.data.EdgeSprite;
    import flare.vis.data.NodeSprite;
    
    import flash.geom.Point;
    import flash.geom.Rectangle;
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
    import org.cytoscapeweb.util.DataSchemaUtils;
    import org.cytoscapeweb.util.Fonts;
    import org.cytoscapeweb.util.LineStyles;
    import org.cytoscapeweb.util.NodeShapes;
    import org.cytoscapeweb.util.Utils;
    import org.cytoscapeweb.util.VisualProperties;
    import org.cytoscapeweb.util.methods.$each;
    import org.cytoscapeweb.vis.data.CompoundNodeSprite;


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
     *     Vendor - Unsafe GML key to show the application that created the XGMML file [ NOT IMPLEMENTED ].
     *     Scale - Unsafe numeric value to scale the size of the displayed graph [ NOT IMPLEMENTED ].
     *     Rootnode - Unsafe id number to identify the root node of the graph. Useful for tree drawing [ NOT IMPLEMENTED ].
     *     Layout - Unsafe string that represent the layout that can be applied to display the graph. The layout name is the name of the algorithm to assign position to the nodes of the graph. For example: circular [ NOT IMPLEMENTED ].
     *     Graphic - Unsafe boolean value. If this value is 1 (true), the XGMML file includes graphical representation of the graph. False means that the XGMML file includes only topological structure of the graph and the application program is free to display the graph using any layout.
     * 
     *   NODE attributes:
     * 
     *     edgeanchor - GML key to position the edges related to the node [ NOT IMPLEMENTED ]
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
            id: 1, label: "", weight: 1, name: ""
        }
        private static const EDGE_ATTR:Object = {
            id: 1, source: 1, target: 1, label: "", name: "", weight: 1, directed: false
        };
        private static const NODE_GRAPHICS_ATTR:Object = {
            type: [VisualProperties.NODE_SHAPE],
            w: [VisualProperties.NODE_WIDTH],
            h: [VisualProperties.NODE_HEIGHT],
            fill: [VisualProperties.NODE_COLOR],
            width: [VisualProperties.NODE_LINE_WIDTH],
            outline: [VisualProperties.NODE_LINE_COLOR],
            labelanchor: [VisualProperties.NODE_LABEL_HANCHOR, VisualProperties.NODE_LABEL_VANCHOR],
            'cy:nodeTransparency': [VisualProperties.NODE_ALPHA],
            'cy:nodeLabelFont': [VisualProperties.NODE_LABEL_FONT_NAME, VisualProperties.NODE_LABEL_FONT_SIZE]
        };
        private static const C_NODE_GRAPHICS_ATTR:Object = {
            type: [VisualProperties.C_NODE_SHAPE],
            // h and w handled separately for compound nodes
            //h: [VisualProperties.C_NODE_SIZE],
            //w: [VisualProperties.C_NODE_SIZE],
            fill: [VisualProperties.C_NODE_COLOR],
            width: [VisualProperties.C_NODE_LINE_WIDTH],
            outline: [VisualProperties.C_NODE_LINE_COLOR],
            labelanchor: [VisualProperties.C_NODE_LABEL_HANCHOR, VisualProperties.C_NODE_LABEL_VANCHOR],
            'cy:nodeTransparency': [VisualProperties.C_NODE_ALPHA],
            'cy:nodeLabelFont': [VisualProperties.C_NODE_LABEL_FONT_NAME, VisualProperties.C_NODE_LABEL_FONT_SIZE]
        };
        private static const EDGE_GRAPHICS_ATTR:Object = {
            width: [VisualProperties.EDGE_WIDTH], 
            fill: [VisualProperties.EDGE_COLOR],
            'cy:edgeLineType': [VisualProperties.EDGE_STYLE],
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
        private var _zoom:Number;
        private var _viewCenter:Point;
        private var _bounds:Rectangle;
        private var _points:Array;
        
        private function get dateFormatter():DateFormatter {
            var dtf:DateFormatter = new DateFormatter();
            dtf.formatString = "YYYY-MM-DD JJ:NN:SS"; //e.g. "2009-01-26 00:43:57"
            return dtf;
        }
        
        // ========[ PUBLIC PROPERTIES ]============================================================
   
        public function get zoom():Number {
            return _zoom;
        }
   
        public function get style():VisualStyleVO {
            return _style;
        }
        
        public function get viewCenter():Point {
            return _viewCenter;
        }
        
        public function get points():Array {
            return _points;
        }
   
        // ========[ CONSTRUCTOR ]==================================================================
        
        public function XGMMLConverter(style:VisualStyleVO, zoom:Number=1,
                                       viewCenter:Point=null, bounds:Rectangle= null) {
            _style = style;
            _zoom = zoom;
            _viewCenter = viewCenter;
            _bounds = bounds;
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
            var directed:Boolean = TRUE == xgmml.@[DIRECTED] ? true : false;
            
            var nodeSchema:DataSchema = DataSchemaUtils.minimumNodeSchema();
            var edgeSchema:DataSchema = DataSchemaUtils.minimumEdgeSchema(directed);
            
            // set schema defaults
            nodeSchema.addField(new DataField(LABEL, DataUtil.STRING));
            nodeSchema.addField(new DataField(WEIGHT, DataUtil.NUMBER));
            nodeSchema.addField(new DataField(NAME, DataUtil.STRING));
            
            edgeSchema.addField(new DataField(LABEL, DataUtil.STRING)); // Edge label cannot be an ID!
            edgeSchema.addField(new DataField(WEIGHT, DataUtil.NUMBER));

            // Parse Global
            // ------------------------------------------------------
            var bc:* = xgmml.att.(@name == "backgroundColor").@value[0];
            if (bc != null) {
                bc = VisualProperties.parseValue(VisualProperties.BACKGROUND_COLOR, bc.toString());
                style.addVisualProperty(new VisualPropertyVO(VisualProperties.BACKGROUND_COLOR, bc));
            }
            
            var scale:* = xgmml.att.(@name == "GRAPH_VIEW_ZOOM").@value[0];
            _zoom = scale != null ? new Number(scale.toString()) : 1.0;
            if (isNaN(_zoom)) _zoom = 1.0;
            
            var vx:* = xgmml.att.(@name == "GRAPH_VIEW_CENTER_X").@value[0];
            var vy:* = xgmml.att.(@name == "GRAPH_VIEW_CENTER_Y").@value[0];
            
            if (vx != null && vy != null) {
                vx = new Number(vx.toString());
                vy = new Number(vy.toString());
                
                if (!isNaN(vx) && !isNaN(vy)) {
                    _viewCenter = new Point(vx, vy);
                }
            }
            
            // Parse nodes
            // ------------------------------------------------------
            var nodesList:XMLList = xgmml..node;
            var node:XML;
            var cns:CompoundNodeSprite;
         
            // for each node in the node list create a CompoundNodeSprite
            // instance and add it to the nodeSprites array.
            for each (node in nodesList) {
                id = StringUtil.trim("" + node.@[ID]);
                
                if (id === "") {
                    throw new Error( "The 'id' attribute is mandatory for 'node' tags");
                }
                
                //lookup[id] = (n = parseData(node, nodeSchema));
                //nodes.push(n);
                
                n = parseData(node, nodeSchema);
                cns = new CompoundNodeSprite();
                cns.data = n;
                nodes.push(cns);
                lookup[id] = cns;
            }
           
            var graphList:XMLList = xgmml..graph;
            var graph:XML;
            var compound:XML
            
            // for each subgraph in the XML, initialize the CompoundNodeSprite
            // owning that subgraph.
            for each (graph in graphList) {
                // if the parent is undefined,
                // then the node is in the root graph.
                if (graph.parent() !== undefined) {
                    compound = graph.parent().parent(); // parent is <att>
                    id = compound.@[ID].toString();
                    cns = lookup[id] as CompoundNodeSprite;
                    
                    if (cns != null) {
                        cns.initialize();
                    }
                }
            }
            
            // add each node to its parent if it is not a node in the root
            
            for each (node in nodesList) {
                graph = node.parent();
                
                // if the parent is undefined,
                // then the node is in the root graph.
                if (graph.parent() !== undefined) {
                    compound = graph.parent().parent();
                    id = compound.@[ID].toString();
                    cns = lookup[id] as CompoundNodeSprite;
                    id = node.@[ID].toString();
                    
                    if (cns != null) {
                        cns.addNode(lookup[id] as CompoundNodeSprite);
                    }
                }
            }
            
            // parse graphics
            for each (node in nodesList) {
                id = StringUtil.trim("" + node.@[ID]);
                cns = lookup[id] as CompoundNodeSprite;
                
                if (cns.isInitialized()) {
                    parseGraphics(id, node, C_NODE_GRAPHICS_ATTR);
                    
                    // separately set width and height values for compound
                    // bounds, since bounds are not visual styles.
                    var g:XML = node[GRAPHICS][0];

                    if (!(g == null || _noGraphicInfo)) {
                        var bounds:Rectangle = new Rectangle();
                        
                        bounds.width = Number(g.@["w"]);
                        bounds.height = Number(g.@["h"]);
                        
                        cns.bounds = bounds;
                    }
                } else {
                    parseGraphics(id, node, NODE_GRAPHICS_ATTR);
                }
            }
            
            // set position values for compound bounds
            
            for each (var point:Object in points) {
                cns = lookup[point.id] as CompoundNodeSprite;
                
                if (cns.isInitialized()) {
                    cns.bounds.x = point.x - cns.bounds.width/2;
                    cns.bounds.y = point.y - cns.bounds.height/2;
                }
            }
            
            // Parse edges
            // ------------------------------------------------------
            // Parse IDs first:
            var edgesIds:Object = {};
            var edgesList:XMLList = xgmml..edge;
            var edge:XML;
            
            for each (edge in edgesList) {
                id = StringUtil.trim("" + edge.@[ID]);
                if (id !== "") edgesIds[id] = true;
            }
            
            var count:int = 1;
            
            // Parse the attributes:
            for each (edge in edgesList/*xgmml.edge*/) {
                id  = edge.@[ID].toString();
                sid = edge.@[SOURCE].toString();
                tid = edge.@[TARGET].toString();

                if (StringUtil.trim(id) === "") {
                    while (edgesIds[count.toString()] === true) ++count;
                    id = count.toString();
                    edgesIds[id] = true;
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
                    <att type="real" name="GRAPH_VIEW_ZOOM" value={zoom}/>
                </graph>;
            
            // View center:
            if (viewCenter != null) {
                xgmml.appendChild(<att type="real" name="GRAPH_VIEW_CENTER_X" value={viewCenter.x}/>);
                xgmml.appendChild(<att type="real" name="GRAPH_VIEW_CENTER_Y" value={viewCenter.y}/>);
            }
            
            var lookup:Object = new Object();
            
            // Add edge and node tags:
            addTags(xgmml, dtset, NODE, lookup);
            addTags(xgmml, dtset, EDGE, lookup);
            
            // Return output:
            if (output == null) output = new ByteArray();
            output.writeUTFBytes(xgmml.toXMLString());
            
            return output;
        }
        
        // ========[ PRIVATE METHODS ]==============================================================
        
        private function parseData(tag:XML, schema:DataSchema):Object {
            var data:Object = {};
            var name:String, field:DataField, value:Object;
            var i:int, att:XML;
            
            // set default values
            for (i = 0; i < schema.numFields; ++i) {
                field = schema.getFieldAt(i);
                data[field.name] = field.defaultValue;
            }
            
            // get attribute values
            for each (att in tag.@*) {
                name = att.name().toString();
                field = schema.getFieldByName(name);
                if (field != null)
                    data[name] = parseAttValue(att[0].toString(), field.type);
            }
            
            // get "att" tags:
            for each (att in tag.att) {
                parseAtt(att, schema, data);
            }
            
            return data;
        }
        
        private function parseAtt(att:XML, schema:DataSchema, data:Object):void {
            var field:DataField, value:Object;
            var name:String = att.@[NAME].toString();
            var def:* = null;
            
            // an attribute without a name should be ignored
            if (name == null || name.length == 0) {
                return;
            }
            
            var type:int = toCW_Type(att.@[TYPE].toString());
            
            // Add the attribute definition to the schema:
            if (schema.getFieldById(name) == null) {
                switch (type) {
                    case DataUtil.BOOLEAN: def = false; break;
                    case DataUtil.INT:     def = 0;     break;
                }
                
                schema.addField(new DataField(name, type, def));
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
                        var innerType:int = toCW_Type(innerAtt.@[TYPE].toString());
                        innerData = parseAttValue(innerAtt.@[VALUE], innerType);
                    }
                    arr.push(innerData);
                }
                data[name] = arr;
            } else {
                // Otherwise, just add the single att data:
                data[name] = parseAttValue(att.@[VALUE], type);
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
                        if (_points == null) _points = [];
                        _points.push({ id: id, x: x, y: y });
                    }
                }
            }
        }
        
        private function addTags(xml:XML,
                                 dtset:DataSet,
                                 tagName:String,
                                 lookup:Object,
                                 parentId:String = null):void {
            var attrs:Object;
            var graphAttrs:Object;
            var table:DataTable;
            var nx:Number, ny:Number;
            var cns:CompoundNodeSprite;
            
            // xml used when creating subgraphs for compound nodes
            var childXml:XML = null;
            
            var appendChild:Function = function(i:uint,
                                                tuple:Object,
                                                target:XML = null):void {
                var data:Object = (tuple is DataSprite) ? DataSprite(tuple).data : table.data;
                var x:XML = <{tagName}/>;
                
                for (var name:String in data) {
                    var field:DataField = schema.getFieldByName(name);
                    
                    if (attrs.hasOwnProperty(name) &&
                        name !== WEIGHT) { // Cytoscape won't parse regular weight attributes...
                        // add as attribute
                        x.@[name] = toString(data[name], field.type);
                    } else if (! (tagName === NODE && name === DataSchemaUtils.PARENT) ) {
                        if (data[name] != null) {
                            addAtt(x, name, schema, data[name]);
                        }
                    }
                }
                
                // Cytoscape requires unique labels:
                if (data[LABEL] === undefined) x.@[LABEL] = toString(data[ID], DataUtil.STRING);
                
                // Write graphics tag:
                if (tuple is DataSprite) {
                    var ds:DataSprite = tuple as DataSprite;
                    var graphics:XML = <{GRAPHICS}/>;
                    var p:Point;
                    
                    // Node position:
                    if (ds is NodeSprite) {
                        var n:NodeSprite = ds as NodeSprite;
                        nx = n.x;
                        ny = n.y;
                        
                        if (_bounds != null) {
                            nx -= _bounds.x;
                            ny -= _bounds.y;
                        }
                        
                        graphics.@x = nx;
                        graphics.@y = ny;
                    }
                    
                    if (ds is CompoundNodeSprite) {
                        if ((ds as CompoundNodeSprite).isInitialized()) {
                            graphAttrs = C_NODE_GRAPHICS_ATTR;
                        } else {
                            graphAttrs = NODE_GRAPHICS_ATTR;
                        }
                    }
                    
                    // Styles (color, width...):
                    for (var k:String in graphAttrs) {
                        addGraphicsAtt(graphics, k, graphAttrs[k], ds.data);
                    }
                    
                    // TODO check if new visual props WIDTH & HEIGHT can be used
                    // w and h values should be added separately, since
                    // visual style "size" does not work for compounds
                    
                    if ((ds is CompoundNodeSprite) &&
                        (ds as CompoundNodeSprite).isInitialized()) {
                        graphics.@["w"] = ds.width;
                        graphics.@["h"] = ds.height;
                    }
                    
                    x.appendChild(graphics);
                }
                
                if (target == null) {
                    // append to the root xml
                    xml.appendChild(x);
                } else {
                    // append to the given xml
                    target.appendChild(x);
                }
                
                childXml = x;
            }
            
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
            //var tuples:Object = (table is GraphicsDataTable) ? GraphicsDataTable(table).dataSprites : table.data;
            var tuples:Object;
            
            // array of compound nodes
            var compoundNodes:Array = new Array();
            
            // array of sprites (for both edges and simple nodes)
            var sprites:Array = new Array();
            
            if (table is GraphicsDataTable) {
                tuples = (table as GraphicsDataTable).dataSprites;
                
                // separate compound nodes and simple nodes if tuples are nodes.
                // separate intra-graph edges and inter-graph edges if
                // tuples are edges.
                
                for each (var ds:DataSprite in tuples) {
                    if (ds is CompoundNodeSprite) {
                        // check if compound node is initialized
                        if ((ds as CompoundNodeSprite).isInitialized()) {
                            // if no parent id is provided, then we are
                            // iterating the root graph. Include only
                            // 'parentless' compounds  
                            if (parentId == null) {
                                if (ds.data.parent == null) {
                                    compoundNodes.push(ds);
                                }
                            } else {
                                // if parent id is provided, it is safe to include 
                                // all initialized compound nodes.
                                compoundNodes.push(ds);
                            }
                        } else {
                            // If no parent id is provided include only
                            // parentless nodes' data.
                            if (parentId == null) {
                                if (ds.data.parent == null) {
                                    sprites.push(ds);
                                }
                            } else {
                                // if parent id is provided, it is safe to include data
                                sprites.push(ds);
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
                        // subgraph (i.e. in the same compound), then the
                        // edge information will be written to the
                        // corresponding subgraph.
                        if (sParentId != null && tParentId != null && sParentId == tParentId) {
                            // try to get the XML corresponding to the
                            // parent
                            target = lookup[sParentId] as XML;
                        }
                        
                        // check if the target parent compound is valid
                        if (target != null) {
                            appendChild(0, es, target);
                        } else {
                            // add the edge data to the array of data to be
                            // added to the root graph
                            sprites.push(es);
                        }
                    }
                }
                
                // write simple node information to the xml
                $each(sprites, appendChild);
                
                // for each compound node sprite, recursively write child node
                // information into a new subgraph
                
                for each (cns in compoundNodes) {
                    // sub graph for child nodes & edges
                    var subgraph:XML = new XML(<graph/>);
                    
                    // TODO set edge definition (directed or undirected) of the subgraph 
                    // subgraph.@[EDGEDEF] = xml.@[EDGEDEF].toString();
                    
                    // construct a map for <id, graph> pairs in order to
                    // use while writing edges              
                    lookup[cns.data.id] = subgraph;
                    
                    // add compound node data to the current graph 
                    appendChild(0, cns);
                    
                    var subList:DataList = new DataList("children");
                    
                    for each (var ns:NodeSprite in cns.getNodes()) {
                        subList.add(ns);
                    }
                    
                    var subDtSet:DataSet = new DataSet(
                           new GraphicsDataTable(subList, table.schema));
                    
                    // recursively add child node data
                    addTags(subgraph, subDtSet, tagName, lookup, cns.data.id);
                    
                    // add subgraph information to the current graph
                    var att:XML = new XML(<{ATTRIBUTE}/>);
                    att.appendChild(subgraph);
                    childXml.appendChild(att);
                }
            } else {
                tuples = table.data;
                $each(tuples, appendChild);
            }   
        }
        
        private function addAtt(xml:XML, name:String, schema:DataSchema, value:*):void {
            var field:DataField = schema.getFieldByName(name);
            var dataType:int = field != null ? field.type : Utils.dataType(value);
            
            var att:XML = <{ATTRIBUTE}/>;
            if (name != null) att.@[NAME] = name;

            // Add <att> tags data:
            if (dataType === DataUtil.OBJECT) {
                att.@[TYPE] = LIST;
                
                if (typeof value === "object" && !(value is Date)) {
                    // If it is an object or array, the att value is a list of other att tags:
                    for (var k:String in value) {
                        var entryValue:* = value[k];
                        var entryName:String = value is Array ? null : k;
    
                        if (entryName == null && typeof entryValue === "object") {
                            for (var kk:String in entryValue) {
                                addAtt(att, kk, schema, entryValue[kk]);
                            }
                        } else {
                            addAtt(att, entryName, schema, entryValue); 
                        }
                    }
                } else {
                    // It could be an OBJECT-type field, but be a date or string value, for example... 
                    addAtt(att, null, schema, toString(value, dataType));
                }
            } else {
                // Otherwise, just add the att value:
                att.@[TYPE] = fromCW_Type(dataType, value)
                att.@[VALUE] = toString(value, dataType);
            }
      
            xml.appendChild(att);
        }
        
        private function addGraphicsAtt(xml:XML, attrName:String, propNames:Array, data:Object):void {
            var value:* = style.getValue(propNames[0], data);
                
            if (VisualProperties.isColor(propNames[0])) {
                value = Utils.rgbColorAsString(value);
            } else {
                switch (propNames[0]) {
                    // TODO C_NODE_WIDTH & C_NODE_HEIGHT ?
                    case VisualProperties.NODE_WIDTH:
                    case VisualProperties.NODE_HEIGHT:
                        // if width/height not set, use size instead:
                        if (value == null || value < 0)
                            value = style.getValue(VisualProperties.NODE_SIZE, data);
                        break;
                    case VisualProperties.NODE_SHAPE:
                    case VisualProperties.C_NODE_SHAPE:
                        if (value != null) value = value.toUpperCase();
                        if (!NodeShapes.isValid(value)) value = NodeShapes.ELLIPSE;
                        break;
                    case VisualProperties.EDGE_SOURCE_ARROW_SHAPE:
                    case VisualProperties.EDGE_TARGET_ARROW_SHAPE:
                        value = fromCW_ArrowShape(value);
                        break;
                    case VisualProperties.NODE_LABEL_FONT_NAME:
                    case VisualProperties.NODE_LABEL_FONT_SIZE:
                        // e.g. "SansSerif-0-12"
                        value = style.getValue(VisualProperties.NODE_LABEL_FONT_NAME, data);
                        value = fromCW_FontName(value);
                        // TODO: BOLD-Italic?
                        value += "-0-";
                        value += style.getValue(VisualProperties.NODE_LABEL_FONT_SIZE, data);
                        break;
                    case VisualProperties.C_NODE_LABEL_FONT_NAME:                   
                    case VisualProperties.C_NODE_LABEL_FONT_SIZE:
                        // e.g. "SansSerif-0-12"
                        value = style.getValue(VisualProperties.C_NODE_LABEL_FONT_NAME, data);
                        value = fromCW_FontName(value);
                        // TODO: BOLD-Italic?
                        value += "-0-";
                        value += style.getValue(VisualProperties.C_NODE_LABEL_FONT_SIZE, data);
                        break;
                    case VisualProperties.NODE_LABEL_HANCHOR:
                    case VisualProperties.NODE_LABEL_VANCHOR:
                        value = fromCW_LabelAnchor(style.getValue(VisualProperties.NODE_LABEL_VANCHOR, data),
                            style.getValue(VisualProperties.NODE_LABEL_HANCHOR, data));
                        break;
                    case VisualProperties.C_NODE_LABEL_HANCHOR:
                    case VisualProperties.C_NODE_LABEL_VANCHOR:
                        value = fromCW_LabelAnchor(style.getValue(VisualProperties.C_NODE_LABEL_VANCHOR, data),
                            style.getValue(VisualProperties.C_NODE_LABEL_HANCHOR, data));
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

                value = parseGraphicsValue(propName, value);
                dm.addEntry(id, value);
            }
        }
        
        // -- static helpers --------------------------------------------------
        
        internal static function parseAttValue(value:String, type:int):* {
            var val:*;
            
            if (type === DataUtil.BOOLEAN) {
                // XGMML's boolean type is 0 or 1, but Cytoscape uses true/false, so let's
                // accept both:
                val = value != null && (value === TRUE || value.toLowerCase() === "true"); 
            } else {
                val = DataUtil.parseValue(value, type);
            }
            
            return val;
        }
        
        internal static function parseGraphicsValue(propName:String, value:*):* {
            if (value != null) {
                switch (propName) {
                    case VisualProperties.EDGE_STYLE:
                        value = toCW_EdgeStyle(value);
                        break;
                    case VisualProperties.EDGE_SOURCE_ARROW_SHAPE:
                    case VisualProperties.EDGE_TARGET_ARROW_SHAPE:
                        value = toCW_ArrowShape(value);
                        break;
                    case VisualProperties.NODE_LABEL_FONT_NAME:
                    case VisualProperties.C_NODE_LABEL_FONT_NAME:
                        // e.g. "Default-0-12"
                        value = value.replace(/(\.[bB]old)?-\d+(\.\d+)?-\d+(\.\d+)?/, "");
                        value = StringUtil.trim(value);
                        value = toCW_FontName(value);
                        // TODO: BOLD-Italic
                        break;
                    case VisualProperties.NODE_LABEL_FONT_SIZE:
                    case VisualProperties.C_NODE_LABEL_FONT_SIZE:
                        // e.g. "SanSerif-0-16"
                        var v:* = value.replace(/.+-[^\-]+-/, "");
                        v = Number(v);
                        if (isNaN(v)) {
                            trace("[ERROR]: XGMMLConverter.parseValue: invalid label font: " + value);
                            v = 12;
                        }
                        value = v;
                        break;
                    case VisualProperties.NODE_LABEL_HANCHOR:
                    case VisualProperties.C_NODE_LABEL_HANCHOR:
                        value = toCW_HAnchor(value);
                        break;
                    case VisualProperties.NODE_LABEL_VANCHOR:
                    case VisualProperties.C_NODE_LABEL_VANCHOR:
                        value = toCW_VAnchor(value);
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
        private static function toCW_Type(type:String):int {
            switch (type) {
                case INTEGER: return DataUtil.INT;
                case REAL:    return DataUtil.NUMBER;
                case BOOLEAN: return DataUtil.BOOLEAN;
                case LIST:    return DataUtil.OBJECT;
                case STRING:
                default:      return DataUtil.STRING;
            }
        }
        
        /**
         * Converts from Flare data types to XGMML types.
         */
        private static function fromCW_Type(type:int, value:*=null):String {            
            if (value is Date) return STRING;

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
        
        private static function toCW_EdgeStyle(line:String):String {
            return LineStyles.parse(line);
        }
        
        private static function fromCW_ArrowShape(shape:String):String {
            shape = ArrowShapes.parse(shape);
            switch (shape) {
                case ArrowShapes.DELTA:   return "3";
                case ArrowShapes.ARROW:   return "6";
                case ArrowShapes.DIAMOND: return "9";
                case ArrowShapes.CIRCLE:  return "12";
                case ArrowShapes.T:       return "15";
                default:                  return "0";
            }
        }
        
        private static function toCW_ArrowShape(shape:String):String {
            switch (shape) {
                case "3":  return ArrowShapes.DELTA;
                case "6":  return ArrowShapes.ARROW;
                case "9":  return ArrowShapes.DIAMOND;
                case "12": return ArrowShapes.CIRCLE;
                case "15": return ArrowShapes.T;
                //TODO: case "16": return ArrowShapes.HALF_ARROW_TOP;
                //TODO: case "17": return ArrowShapes.HALF_ARROW_BOTTOM;
                default:   return ArrowShapes.NONE;
            }
        }
    
        private static function fromCW_FontName(font:String):String {
            switch (font) {
                case null:
                case "":
                case Fonts.SANS_SERIF: return "SansSerif";
                case Fonts.SERIF:      return "Serif";
                case Fonts.TYPEWRITER: return "Monospaced";
                default:               return font;
            }
        }
        
        private static function toCW_FontName(font:String):String {
            switch (font) {
                case null:
                case "":
                case "Default":
                case "SanSerif":
                case "SansSerif":  return Fonts.SANS_SERIF;
                case "Serif":      return Fonts.SERIF;
                case "Monospaced": return Fonts.TYPEWRITER;
                default:           return font;
            }
        }
        
        private static function fromCW_LabelAnchor(va:String, ha:String):String {
            switch (va) {
                case "bottom":
                    if (ha === "left") return "ne";
                    if (ha === "right") return "nw";
                    return "n";
                case "top":
                    if (ha === "left") return "se";
                    if (ha === "right") return "sw";
                    return "s";
                default:
                    if (ha === "left") return "e";
                    if (ha === "right") return "w";
                    return "c";
            }
        }
        
        /**
         * @param hanchor the XGMML value for "labelanchor"
         *                (see http://www.cs.rpi.edu/~puninj/XGMML/draft-xgmml.html#GlobalA and 
         *                 http://www.inf.uni-konstanz.de/algo/lehre/ws04/pp/api/y/io/doc-files/gml-comments.html)
         */
        private static function toCW_HAnchor(labelanchor:String):String {
            if (labelanchor != null) labelanchor = labelanchor.toLowerCase();
            switch (labelanchor) {
                case "ne":
                case "se":
                case "e": return "left";
                case "nw":
                case "sw":
                case "w": return "right";
                default:  return "center";
            }
        }
        
        /**
         * @param vanchor the XGMML value for "labelanchor"
         *                (see http://www.cs.rpi.edu/~puninj/XGMML/draft-xgmml.html#GlobalA and 
         *                 http://www.inf.uni-konstanz.de/algo/lehre/ws04/pp/api/y/io/doc-files/gml-comments.html)
         */
        private static function toCW_VAnchor(labelanchor:String):String {
            if (labelanchor != null) labelanchor = labelanchor.toLowerCase();
            switch (labelanchor) {
                case "ne":
                case "nw":
                case "n": return "bottom";
                case "se":
                case "sw":
                case "s": return "top";
                default:  return "middle";
            }
        }
        
        private static function error(msg:String):void {
            throw new Error(msg);
        }
    }
}
