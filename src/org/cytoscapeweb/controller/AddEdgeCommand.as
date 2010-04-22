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
    import flare.vis.data.EdgeSprite;
    
    import org.cytoscapeweb.ApplicationFacade;
    import org.cytoscapeweb.model.GraphProxy;
    import org.cytoscapeweb.model.methods.error;
    import org.cytoscapeweb.util.Groups;
    import org.cytoscapeweb.view.GraphMediator;
    import org.puremvc.as3.interfaces.INotification;
    import org.puremvc.as3.patterns.command.SimpleCommand;
    

    /**
     * Create a new edge and add it to the view.
     */
    public class AddEdgeCommand extends SimpleCommand {
        
        override public function execute(notification:INotification):void {
            try {
                var data:Object = notification.getBody().data;
                var updateVisualMappers:Boolean = notification.getBody().updateVisualMappers;
                
                var graphProxy:GraphProxy = facade.retrieveProxy(GraphProxy.NAME) as GraphProxy;
                var mediator:GraphMediator = facade.retrieveMediator(GraphMediator.NAME) as GraphMediator;
                
                // Create edge:
                var edges:Array = graphProxy.addEdge(data); // could return a new merged edge, too!

                // Set listeners, styles, etc:
                mediator.initialize(Groups.EDGES, edges);
                
                if (updateVisualMappers) sendNotification(ApplicationFacade.GRAPH_DATA_CHANGED);
            } catch (err:Error) {
                trace("[ERROR]: AddEdgeCommand.execute: " + err.getStackTrace());
                error(err.message, err.errorID, err.name, err.getStackTrace());
            }
        }
    }
}