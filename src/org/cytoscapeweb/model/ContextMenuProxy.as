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
package org.cytoscapeweb.model {
    import org.puremvc.as3.patterns.proxy.Proxy;
    
    [Bindable]
    public class ContextMenuProxy extends Proxy {

        // ========[ CONSTANTS ]====================================================================

        public static const NAME:String = 'ContextMenuProxy';

        // ========[ PRIVATE PROPERTIES ]===========================================================

        // ========[ PUBLIC PROPERTIES ]============================================================
        
        public var id:String;
        
        public function get menuItems():Object {
            if (data == null)
                data = { none: [], nodes: [], edges: [] };
            
            return data;
        }

        public function set menuItems(items:Object):void {
            data = items;
        }

        // ========[ CONSTRUCTOR ]==================================================================

        public function ContextMenuProxy() {
            super(NAME);
        }

        // ========[ PUBLIC METHODS ]===============================================================

        public function addMenuItem(label:String, group:String="none"):void {
            var labelsList:Array = menuItems[group];
            
            if (labelsList.indexOf(label) === -1)
                labelsList.push(label);
        }
        
        public function removeMenuItem(label:String, group:String="none"):void {
            var labelsList:Array = menuItems[group];
            var idx:int = labelsList.indexOf(label);
            
            if (idx !== -1)
                labelsList.splice(idx, 1);
        }

        // ========[ PRIVATE METHODS ]==============================================================

    }
}
