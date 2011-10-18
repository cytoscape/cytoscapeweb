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
package org.cytoscapeweb.model.data {

    import org.cytoscapeweb.util.BoxPositions;
    import org.cytoscapeweb.util.Layouts;


    public class ConfigVO {
        
        // ========[ CONSTANTS ]====================================================================

        // ========[ PRIVATE PROPERTIES ]===========================================================
        
        private static var _defaultCfg:ConfigVO;

        // ========[ PUBLIC PROPERTIES ]============================================================
        
        public var panZoomControlVisible:Boolean = true;
        public var panZoomControlPosition:String = BoxPositions.BOTTOM_RIGHT;
        public var grabToPanEnabled:Boolean;
        public var edgesMerged:Boolean;
        public var nodeLabelsVisible:Boolean = true;
        public var edgeLabelsVisible:Boolean;
        public var nodeTooltipsEnabled:Boolean;
        public var edgeTooltipsEnabled:Boolean;
        public var customCursorsEnabled:Boolean = true;
        public var visualStyle:VisualStyleVO;
        public var currentLayout:Object;
        public var minZoom:Number = 0.002;
        public var maxZoom:Number = 3;
        public var mouseDownToDragDelay:Number = 400;
        public var preloadImages:Boolean = true;
        
        // ========[ CONSTRUCTOR ]==================================================================
        
        public function ConfigVO() {
            currentLayout = {
                name: Layouts.FORCE_DIRECTED,
                options: Layouts.DEFAULT_OPTIONS[Layouts.FORCE_DIRECTED]
            };
        }
        
        // ========[ PUBLIC METHODS ]===============================================================
        
        public static function getDefault():ConfigVO {
            if (_defaultCfg == null) {
                _defaultCfg = new ConfigVO();
                _defaultCfg.visualStyle = VisualStyleVO.defaultVisualStyle();
            }
            
            return _defaultCfg;
        }

        // ========[ PRIVATE METHODS ]==============================================================

    }
}