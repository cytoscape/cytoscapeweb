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
    import flare.vis.data.NodeSprite;
    
    import flash.geom.Point;
    
    import org.cytoscapeweb.ApplicationFacade;
    import org.cytoscapeweb.model.GraphProxy;
    import org.cytoscapeweb.model.methods.error;
    import org.cytoscapeweb.util.Groups;
    import org.cytoscapeweb.view.GraphMediator;
    import org.puremvc.as3.interfaces.INotification;
    import org.puremvc.as3.patterns.command.SimpleCommand;
    

    /**
     * Create a new node and add it to the view.
     */
    public class AddNodeCommand extends SimpleCommand {
        
        override public function execute(notification:INotification):void {
            try {
                var data:Object = notification.getBody().data;
                var updateVisualMappers:Boolean = notification.getBody().updateVisualMappers;
                var x:Number = notification.getBody().x;
                var y:Number = notification.getBody().y;
                
                var graphProxy:GraphProxy = facade.retrieveProxy(GraphProxy.NAME) as GraphProxy;
                var mediator:GraphMediator = facade.retrieveMediator(GraphMediator.NAME) as GraphMediator;
                
                // Create node:
                var n:NodeSprite = graphProxy.addNode(data);

                // Position it:
                var p:Point = new Point(x, y);
                p = mediator.vis.globalToLocal(p);
                n.x = p.x;
                n.y = p.y;

                // Set listeners, styles, etc:
                mediator.initialize(Groups.NODES, [n]);
                
                if (updateVisualMappers) sendNotification(ApplicationFacade.GRAPH_DATA_CHANGED);
            } catch (err:Error) {
                trace("[ERROR]: AddNodeCommand.execute: " + err.getStackTrace());
                error(err.message, err.errorID, err.name, err.getStackTrace());
            }
        }
    }
}