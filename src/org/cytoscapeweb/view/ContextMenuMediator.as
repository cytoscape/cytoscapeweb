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
package org.cytoscapeweb.view {
    import flare.vis.data.EdgeSprite;
    import flare.vis.data.NodeSprite;
    
    import flash.events.ContextMenuEvent;
    import flash.ui.ContextMenu;
    import flash.ui.ContextMenuItem;
    
    import mx.events.FlexEvent;
    
    import org.cytoscapeweb.ApplicationFacade;
    import org.cytoscapeweb.model.ContextMenuProxy;
    import org.cytoscapeweb.model.converters.ExternalObjectConverter;
    import org.cytoscapeweb.util.ExternalFunctions;
    import org.cytoscapeweb.util.Groups;
        
    /**
     * Top level mediator for the application.
     */
    public class ContextMenuMediator extends BaseMediator {

        // ========[ CONSTANTS ]====================================================================

        /** Cannonical name of the Mediator. */
        public static const NAME:String = "ContextMenuMediator";
        
        // ========[ PRIVATE PROPERTIES ]===========================================================
        
        private var customContextMenu:ContextMenu;
        
        // Have to store the rolled over node/edge because, on Windows,
        // after displaying the context menu, the original node that has the mouse over it
        // loses focus and "graphProxy.rolledOverNode" would return null.
        private var _rolledOverNode:NodeSprite;
        private var _rolledOverEdge:EdgeSprite;
        
        private function get application():CytoscapeWeb {
            return viewComponent as CytoscapeWeb;
        }
        
        private var _contextMenuProxy:ContextMenuProxy;

        protected function get contextMenuProxy():ContextMenuProxy {
            if (_contextMenuProxy == null)
                _contextMenuProxy = facade.retrieveProxy(ContextMenuProxy.NAME) as ContextMenuProxy;
            return _contextMenuProxy;
        }

        // ========[ CONSTRUCTOR ]==================================================================
   
        public function ContextMenuMediator(viewComponent:Object) {
            super(NAME, viewComponent, this);
            application.addEventListener(FlexEvent.APPLICATION_COMPLETE, onApplicationComplete, false, 0, true);
        }

        // ========[ PUBLIC METHODS ]===============================================================
    
        override public function getMediatorName():String {
            return NAME;
        }
        
        // ========[ PRIVATE METHODS ]==============================================================

        private function onApplicationComplete(evt:FlexEvent):void {
            customContextMenu = new ContextMenu();
            customContextMenu.hideBuiltInItems();
            
            // Dinamicaly show/hide menu items:
            // -----------------------------------------------------------
            customContextMenu.addEventListener(ContextMenuEvent.MENU_SELECT, onMenuSelect);
            
            // Redefine the application context menu:
            // -----------------------------------------------------------
            application.contextMenu = customContextMenu;
        }
    
        private function onMenuSelect(evt:ContextMenuEvent):void {
            // Remove all previous menu items:
            // -----------------------------------------------------------
            var total:int = customContextMenu.customItems.length;
            for (var i:int = 0; i < total; i++) {
                customContextMenu.customItems.pop();
            }

            if (graphProxy.graphData != null) {
                // Have to keep a reference to the rolled over node and edge!
                _rolledOverNode = graphProxy.rolledOverNode;
                _rolledOverEdge = graphProxy.rolledOverEdge;
                var separator:Boolean = false;
                
                // Create custom menu items:
                // -----------------------------------------------------------
                var items:Object = contextMenuProxy.menuItems;
                if (items != null) {
                    var menuItem:ContextMenuItem;
                    var label:String;
                    
                    if (_rolledOverNode) {
                        for each (label in items[Groups.NODES]) {
                            addMenuItem(Groups.NODES, label, separator);
                            separator = false;
                        }
                        separator = true;
                    } else if (_rolledOverEdge) {
                        for each (label in items[Groups.EDGES]) {
                            addMenuItem(Groups.EDGES, label, separator);
                            separator = false;
                        }
                        separator = true;
                    }

                    for each (label in items[Groups.NONE]) {
                        addMenuItem(Groups.NONE, label, separator);
                        separator = false;
                    }
                }
            }
            
            function addMenuItem(group:String, label:String, separator:Boolean=false):void {
                var menuItem:ContextMenuItem = new ContextMenuItem(label, separator);
    
                menuItem.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT,
                    function(evt:ContextMenuEvent):void {
                        var target:* = _rolledOverNode ? _rolledOverNode : _rolledOverEdge;
                        target = ExternalObjectConverter.toExtElement(target, graphProxy.zoom);
                        
                        var body:Object = { functionName: ExternalFunctions.INVOKE_CONTEXT_MENU_CALLBACK, 
                                            argument: { type: "contextmenu",
                                                        group: group, 
                                                        value: evt.target.caption,
                                                        target: target,
                                                        mouseX: application.mouseX,
                                                        mouseY: application.mouseY } };
                        
                        sendNotification(ApplicationFacade.CALL_EXTERNAL_INTERFACE, body);
                    });
                    
                customContextMenu.customItems.push(menuItem);
            }
        }
    }
}
