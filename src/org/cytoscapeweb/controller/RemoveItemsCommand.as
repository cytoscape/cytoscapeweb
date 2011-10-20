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
    import flare.vis.data.DataSprite;
    import flare.vis.data.NodeSprite;
    
    import org.cytoscapeweb.ApplicationFacade;
    import org.cytoscapeweb.model.methods.error;
    import org.cytoscapeweb.util.Groups;
    import org.cytoscapeweb.vis.data.CompoundNodeSprite;
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
                var ds:DataSprite, parent:CompoundNodeSprite;

                if (group == null) group = Groups.NONE;
                
                if (items == null) {
                    items = [];
                    if (group === Groups.NODES || group === Groups.NONE)
                        items = items.concat(graphProxy.nodes);
                    if (group === Groups.EDGES || group === Groups.NONE)
                        items = items.concat(graphProxy.edges);
                } else {
                    items = graphProxy.getDataSpriteList(items, group);
                }
    
                // save all affected parents for later:
                var lookup:Object = {};
                var parentNodes:Array = [];
                
                if (graphProxy.compoundGraph) {
                    for each (ds in items) {
                        if (ds is NodeSprite && ds.data.parent != null) {
                            if (lookup[ds.data.parent] == null) {
                                parent = graphProxy.getNode(ds.data.parent);
                                
                                if (parent != null) {
                                    lookup[ds.data.parent] = parent;
                                    parentNodes.push(parent);
                                }
                            }
                        }
                    }
                }
    
                graphMediator.dispose(items);
                graphProxy.remove(items);
				
				// shrink affected compound node bounds:
                if (parentNodes.length > 0) {
    				graphMediator.updateParentNodes(parentNodes);
                }
                
                if (updateVisualMappers) sendNotification(ApplicationFacade.GRAPH_DATA_CHANGED);
                else graphMediator.separateDisconnected();
                
            } catch (err:Error) {
                trace("[ERROR]: RemoveItemsCommand.execute: " + err.getStackTrace());
                error(err);
            }
        }
    }
}