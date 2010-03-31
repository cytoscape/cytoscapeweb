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
    
    import mx.utils.StringUtil;

    /**
     * Converts data between the Simple Interaction Format and flare DataSet instances.
     * The <a href="http://cytoscape.wodaklab.org/wiki/Cytoscape_User_Manual/Network_Formats">SIF</a>
     * format specifies nodes and interactions only, while other formats store additional 
     * information about network layout and allow network data exchange with a variety of other 
     * network programs and data sources.
     * 
     * This format does not include any layout information.
     * 
     * Whitespace (space or tab) is used to delimit the names in the  simple interaction file
     * format. However, in some cases spaces are desired in a node name or edge type.
     * The standard is that, if the file contains any tab characters, then tabs are used
     * to delimit the fields and spaces are considered part of the name.
     * If the file contains no tabs, then any spaces are delimiters that separate names 
     * (and names cannot contain spaces).
     * 
     * The name of each node will be set to its "id" and "label" attributes.
     * 
     * The relationship type will be set to the edge's "interaction" and "label" attributes.
     * The edge "id" will be formed by the name of the source and target nodes plus the interaction
     * type (e.g. "sourceName (edgeType) targetName").
     * 
     * Format:
     * 
     * nodeA <relationship type> nodeB
     * nodeC <relationship type> nodeA
     * nodeD <relationship type> nodeE nodeF nodeB
     * nodeG
     * ...
     * nodeY <relationship type> nodeZ
     * 
     * 
     * Example:
     * 
     * node1 typeA node2
     * node2 typeB node3 node4 node5
     * node0
     */
    public class SIFConverter implements IDataConverter {    
        
        private namespace _defNamespace = "http://graphml.graphdrawing.org/xmlns";
        use namespace _defNamespace;
        
        // ========[ CONSTANTS ]====================================================================

        private static const ID:String          = "id";
        private static const LABEL:String       = "label";
        private static const INTERACTION:String = "interaction";
        private static const DIRECTED:String    = "directed";
        private static const SOURCE:String      = "source";
        private static const TARGET:String      = "target";        

        // ========[ PRIVATE PROPERTIES ]===========================================================

        private var _interaction:String;

        // ========[ CONSTRUCTOR ]==================================================================

        public function SIFConverter(interactionAttr:String=null) {
            super();
            _interaction = interactionAttr != null ? interactionAttr : INTERACTION;
        }

        // ========[ PUBLIC PROPERTIES ]============================================================
        
        /** @inheritDoc */
        public function read(input:IDataInput, schema:DataSchema=null):DataSet {
            var sif:String = input.readUTFBytes(input.bytesAvailable);
            return parse(sif);
        }
        
        /** @inheritDoc */
        public function write(ds:DataSet, output:IDataOutput=null):IDataOutput {          
            var sif:String = "";
            
            if (ds != null) {
                var lookup:Object = {};
                var nodes:Array = ds.nodes.data;
                var edges:Array = ds.edges.data;
           
                for each (var e:Object in edges) {
                    var src:String = e[SOURCE];
                    var tgt:String = e[TARGET];
                    var inter:String = e.hasOwnProperty(_interaction) ? e[_interaction] : e.id;
                    
                    sif += (src + "\t" + inter + "\t" + tgt + "\n");
                    lookup[src] = true;
                    lookup[tgt] = true;
                }
                for each (var n:Object in nodes) {
                    if (!lookup[n.id]) {
                        sif += n.id + "\n";
                        lookup[n.id] = true;
                    }
                }
           
                if (output == null) output = new ByteArray();
                output.writeUTFBytes(sif);
            }
            
            return output;
        }
        
        public function parse(sif:String):DataSet {
            var nodeLookup:Object = {}, edgeLookup:Object = {};
            var nodes:Array = [], edges:Array = [];
            var n:Object, e:Object;
            
            var nodeSchema:DataSchema = new DataSchema();
            var edgeSchema:DataSchema = new DataSchema();
            
            // set schema defaults
            nodeSchema.addField(new DataField(ID, DataUtil.STRING));
            nodeSchema.addField(new DataField(LABEL, DataUtil.STRING));

            edgeSchema.addField(new DataField(ID, DataUtil.STRING));
            edgeSchema.addField(new DataField(LABEL, DataUtil.STRING));
            edgeSchema.addField(new DataField(_interaction, DataUtil.STRING));
            edgeSchema.addField(new DataField(SOURCE, DataUtil.STRING));
            edgeSchema.addField(new DataField(TARGET, DataUtil.STRING));
            edgeSchema.addField(new DataField(DIRECTED, DataUtil.BOOLEAN, false));
            
            var delimiter:String = " ";
            if (sif.indexOf("\t") >= 0) delimiter = "\t";
            
            var lines:Array = sif.split("\n");
            
            for each (var newLine:String in lines) {
                if (newLine.length === 0) continue;
                
                // Split the lines into interactions:
                var tokens:Array = newLine.split(delimiter);
                var source:String, targets:Array = [], interaction:String;
                var nodeNames:Array = [];

                var count:int = 0;
                
                for each (var t:String in tokens) {
                    t = StringUtil.trim(t);
                    if (t.length === 0) continue;
                    
                    if (count === 0) {
                        nodeNames.push(source = t);
                    } else if (count === 1) {
                        interaction = t;
                    } else {
                        targets.push(t);
                        nodeNames.push(t);
                    }
                    count++;
                }
                
                // Create the nodes data:
                for each (var name:String in nodeNames) {
                    if (!nodeLookup[name]) {
                        nodeLookup[name] = n = createNodeData(name);
                        nodes.push(n);
                    }
                }
                // Create the edges for each target:
                if (interaction != null && targets.length > 0) {
                    for each (var target:String in targets) {
                        var k:String = source+" ("+interaction+") "+target;
                        if (!edgeLookup[k]) {
                            edgeLookup[k] = e = createEdgeData(interaction, source, target);
                            edges.push(e);
                        }
                    }
                }
            }
            
            return new DataSet(
                new DataTable(nodes, nodeSchema),
                new DataTable(edges, edgeSchema)
            );
        }

        // ========[ PROTECTED METHODS ]============================================================

        protected function createNodeData(name:String):Object {
            var data:Object = {};
            data[ID] = data[LABEL] = name;

            return data;
        }
        
        protected function createEdgeData(interaction:String, source:String, target:String):Object {
            var data:Object = {};
            data[ID] = source + " (" + interaction + ") " + target;
            data[_interaction] = data[LABEL] = interaction;
            data[SOURCE] = source;
            data[TARGET] = target;
            data[DIRECTED] = false;

            return data;
        }
        
        // ========[ PRIVATE METHODS ]==============================================================
        
    }
}