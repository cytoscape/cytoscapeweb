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
    import flare.vis.data.Data;
    import flare.vis.data.DataList;
    import flare.vis.data.NodeSprite;
    
    import org.cytoscapeweb.view.layout.ForceDirectedLayout;
    
    
    /**
     * Abstract utility class defining constants for the layout names used by Cytoscape Web.
     */
    public class Layouts {
        
        // ========[ CONSTANTS ]====================================================================
        
        public static const CIRCLE:String = "Circle";
        public static const FORCE_DIRECTED:String = "ForceDirected";
        public static const RADIAL:String = "Radial";
        public static const TREE:String = "Tree";
        public static const COSE:String = "CompoundSpringEmbedder";
        public static const PRESET:String = "Preset";
        
        public static const DEFAULT_OPTIONS:Object = {
            Circle:  {
                angleWidth: 360, // in degrees
                tree: false
            },
            Radial:  {
                angleWidth: 360,
                radius: "auto"
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
                restLength:  "auto",
                seed:        undefined, // optional integer
                weightAttr:  null,
                weightNorm:  ForceDirectedLayout.NORMALIZED_WEIGHT,
                minWeight:   undefined,
                maxWeight:   undefined,
                iterations:  400,
                maxTime:     30000, // milliseconds
                autoStabilize: true
            },
            Preset: {
                points: [ ],
                fitToScreen: true
            },
            CompoundSpringEmbedder : {
                layoutQuality:                  "default", // Layout Quality
                incremental:                    false, // Incremental
                uniformLeafNodeSizes:           false, // Uniform Leaf Node Sizes
                tension:                        50, // Spring
                gravitation:                    -50, // Repulsion or Attraction
                smartDistance:                  true, // Smart Range Calculation
                centralGravitation:             50, // Central Gravity
                centralGravityDistance:         50, // Gravity Range
                compoundCentralGravitation:     50, // Compound Gravity
                compoundCentralGravityDistance: 50, // Compound Gravity Range
                restLength:                     50, // Desired Edge Length
                smartRestLength:                true, // Smart Edge Length Calculation
                multiLevelScaling:              false // Multi-Level Scaling
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
        
        public static function rootNode(data:Data):NodeSprite {
            var nodes:DataList = data.nodes;
            
            if (data.directedEdges) {
                for each (var n:NodeSprite in nodes) {
                    if (n.inDegree === 0 && n.outDegree > 0) return n;
                }
            }
            
            return data.nodes[0];
        }
        
        // ========[ PRIVATE METHODS ]==============================================================

    }
}