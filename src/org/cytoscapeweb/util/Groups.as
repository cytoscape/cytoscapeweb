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
    import flare.vis.data.DataSprite;
    import flare.vis.data.EdgeSprite;
    import flare.vis.data.NodeSprite;
    
    import mx.utils.StringUtil;
    
    
    
    /**
     * Abstract utility class defining constants for the groups of network elements.
     */
    public class Groups {
        
        // ========[ CONSTANTS ]====================================================================
        
        public static const NODES:String = "nodes";
		public static const COMPOUND_NODES:String = "compoundNodes";
        public static const EDGES:String = "edges";
        public static const NONE:String = "none";
        
        public static const REGULAR_EDGES:String = "regularEdges";
        public static const MERGED_EDGES:String = "mergedEdges";
        public static const SELECTED_NODES:String = "selectedNodes";
        public static const SELECTED_EDGES:String = "selectedEdges";
        public static const FILTERED_NODES:String = "filteredNodes";
        public static const FILTERED_EDGES:String = "filteredEdges";
        
        // ========[ CONSTRUCTOR ]==================================================================
        
        /**
         * This constructor will throw an error, as this is an abstract class. 
         */
        public function Groups() {
            throw new Error("This is an abstract class.");
        }
        
        // ========[ PUBLIC METHODS ]===============================================================
        
        public static function groupOf(ds:DataSprite):String {
            var gr:String = NONE;
            if (ds is NodeSprite) gr = NODES;
            else if (ds is EdgeSprite) gr = EDGES;
            return gr;
        }
        
        public static function parse(gr:String):String {
            if (gr != null) gr = StringUtil.trim(gr.toLowerCase());
            if (gr === NODES) return NODES;
            if (gr === EDGES) return EDGES;
            
            return null;
        }
        
        // ========[ PRIVATE METHODS ]==============================================================

    }
}