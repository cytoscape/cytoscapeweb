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
    import flare.util.Orientation;
    import flare.vis.operator.layout.Layout;
    import flare.vis.operator.layout.NodeLinkTreeLayout;
    
    
    
    /**
     * Abstract utility class defining constants for the layout names used by Cytoscape Web.
     */
    public class Layouts {
        
        // ========[ CONSTANTS ]====================================================================
        
        public static const CIRCLE:String = "Circle";
        public static const CIRCLE_TREE:String = "CircleTree";
        public static const FORCE_DIRECTED:String = "ForceDirected";
        public static const RADIAL:String = "Radial";
        public static const TREE:String = "Tree";
        public static const PRESET:String = "Preset";
        
        public static const DEFAULT_OPTIONS:Object = {
            Circle:  {
                angleWidth: -2 * Math.PI
            },
            CircleTree:  {
                angleWidth: -2 * Math.PI
            },
            Radial:  {
                angleWidth: -2 * Math.PI
                //radius: 60
            },
            Tree:  {
                orientation:  Orientation.TOP_TO_BOTTOM, // "leftToRight","rightToLeft","topToBottom","bottomToTop"
                depthSpace:   50,
                breadthSpace: 30,
                subtreeSpace: 5
            },
            ForceDirected:  {
                drag:        0.4,
                gravitation: -500,
                minDistance: 1,
                maxDistance: 10000,
                mass:        3,
                tension:     0.1,
                //restLength: 60
                iterations: 80,
                maxTime:    60000,
                autoStabilize: true
            },
            Preset: {
                
            }
        };
        
        // ========[ CONSTRUCTOR ]==================================================================
        
        /**
         * This constructor will throw an error, as this is an abstract class. 
         */
        public function Layouts() {
            throw new Error("This is an abstract class.");
        }
        
        // ========[ PUBLIC METHODS ]===============================================================
        
        public static function mergeOptions(name:String, o:Object):Object {
            var opt:Object = DEFAULT_OPTIONS[name];
            if (o == null) o = {};
            
            if (opt != null) {
                for (var k:String in opt) {
                    if (o[k] === undefined) o[k] = opt[k];
                }
            }
            
            return o;
        }
        
        // ========[ PRIVATE METHODS ]==============================================================

    }
}