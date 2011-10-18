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
package org.cytoscapeweb.util {
    
    import flare.data.DataField;
    import flare.data.DataSchema;
    import flare.data.DataUtil;
    
    
    public class DataSchemaUtils {
        
        // ========[ CONSTANTS ]====================================================================
        
        public static const ID:String = "id";
        public static const PARENT:String = "parent";
        public static const SOURCE:String = "source";
        public static const TARGET:String = "target";
        public static const DIRECTED:String = "directed";
        
        // ========[ CONSTRUCTOR ]==================================================================
        
        /**
         * This constructor will throw an error, as this is an abstract class. 
         */
        public function DataSchemaUtils() {
             throw new Error("This is an abstract class.");
        }
        
        // ========[ PUBLIC METHODS ]===============================================================
        
        public static function minimumNodeSchema():DataSchema {
            var schema:DataSchema = new DataSchema();
            schema.addField(new DataField(ID, DataUtil.STRING));
            schema.addField(new DataField(PARENT, DataUtil.STRING));
            
            return schema;
        }
        
        /**
         * @param directed The default value for the directed data field. 
         */
        public static function minimumEdgeSchema(directed:Boolean=false):DataSchema {
            var schema:DataSchema = new DataSchema();
            schema.addField(new DataField(ID, DataUtil.STRING));
            schema.addField(new DataField(SOURCE, DataUtil.STRING));
            schema.addField(new DataField(TARGET, DataUtil.STRING));
            schema.addField(new DataField(DIRECTED, DataUtil.BOOLEAN, directed));
            
            return schema;
        }
    }
}