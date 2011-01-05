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
    
    import org.cytoscapeweb.ApplicationFacade;
    import org.cytoscapeweb.model.methods.error;
    import org.cytoscapeweb.util.Groups;
    import org.cytoscapeweb.util.methods.$each;
    import org.puremvc.as3.interfaces.INotification;
    

    /**
     * Update node and edge data attributes.
     */
    public class UpdateDataCommand extends BaseSimpleCommand {
        
        override public function execute(notification:INotification):void {
            try {
                var body:Object = notification.getBody();
                var group:String = body.group;
                if (group == null) group = Groups.NONE;
                var items:Array = body.items;
                var data:Object = body.data;
                
                items = graphProxy.getDataSpriteList(items, group, true);
                if (items == null) items = [];
                
                if (items.length === 0) {
                    if (group === Groups.NODES || group === Groups.NONE)
                        items = items.concat(graphProxy.nodes);
                    if (group === Groups.EDGES || group === Groups.NONE)
                        items = items.concat(graphProxy.edges);
                }
                
                if (items != null && data != null) {
                    $each(items, function(i:uint, ds:DataSprite):void {
                        graphProxy.updateData(ds, data);
                    });
                }
                
                sendNotification(ApplicationFacade.GRAPH_DATA_CHANGED);
            } catch (err:Error) {
                trace("[ERROR]: UpdateDataCommand.execute: " + err.getStackTrace());
                error(err);
            }
        }
    }
}
