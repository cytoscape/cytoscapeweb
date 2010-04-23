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
package org.cytoscapeweb.controller {
    import org.cytoscapeweb.ApplicationFacade;
    import org.cytoscapeweb.model.methods.error;
    import org.cytoscapeweb.util.Groups;
    import org.puremvc.as3.interfaces.INotification;
    

    /**
     * Permanently remove nodes and edges from the network.
     */
    public class RemoveItemsCommand extends BaseSimpleCommand {
        
        override public function execute(notification:INotification):void {
            try {
                var group:String = notification.getBody().group;
                var items:Array = notification.getBody().items;
                var updateVisualMappers:Boolean = notification.getBody().updateVisualMappers;
                
                if (group == null) group = Groups.NONE;
                
                items = graphProxy.getDataSpriteList(items, group);
                            
                if (items.length === 0) {
                    if (group === Groups.NODES || group === Groups.NONE) items = items.concat(graphProxy.nodes);
                    if (group === Groups.EDGES || group === Groups.NONE) items = items.concat(graphProxy.edges);
                }
    
                graphMediator.dispose(items);
                graphProxy.remove(items);
                
                if (updateVisualMappers) sendNotification(ApplicationFacade.GRAPH_DATA_CHANGED);
                else graphMediator.separateDisconnected();
                
            } catch (err:Error) {
                trace("[ERROR]: RemoveItemsCommand.execute: " + err.getStackTrace());
                error(err.message, err.errorID, err.name, err.getStackTrace());
            }
        }
    }
}