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
    import org.cytoscapeweb.model.ExternalInterfaceProxy;
    import org.cytoscapeweb.model.GraphProxy;
    import org.cytoscapeweb.util.ExternalFunctions;
    import org.cytoscapeweb.util.GraphUtils;
    import org.cytoscapeweb.util.Groups;
    import org.cytoscapeweb.util.Utils;
    import org.cytoscapeweb.view.GraphMediator;
    import org.puremvc.as3.interfaces.INotification;
    import org.puremvc.as3.patterns.command.SimpleCommand;
    

    /**
     * Handle the selection of one or more nodes.
     * A nodes array must be sent as the body of the notification. 
     */
    public class SelectCommand extends SimpleCommand {
        
        override public function execute(notification:INotification):void {
            var list:* = notification.getBody();
            
            if (list != null && list.length > 0) {
                // Separate nodes and edges:
                var nodes:Array = [], edges:Array = [];
                for each (var ds:DataSprite in list) {
                    if (ds is NodeSprite) nodes.push(ds);
                    else edges.push(ds);
                }
 
                // First add the information to the model:
                var graphProxy:GraphProxy = facade.retrieveProxy(GraphProxy.NAME) as GraphProxy;
                nodes = graphProxy.addSelectedNodes(nodes);
                edges = graphProxy.addSelectedEdges(edges);

                // Then update the view:
                var mediator:GraphMediator = facade.retrieveMediator(GraphMediator.NAME) as GraphMediator;

                if (nodes.length > 0)
                    mediator.selectNodes(nodes);
                if (edges.length > 0)
                    mediator.selectEdges(edges);

                // Call external listeners:
                var extProxy:ExternalInterfaceProxy = facade.retrieveProxy(ExternalInterfaceProxy.NAME) as ExternalInterfaceProxy;
                var objs:Array, body:Object, type:String = "select";
                
                if (nodes.length > 0 && extProxy.hasListener(type, Groups.NODES)) {
                    objs = GraphUtils.toExtObjectsArray(nodes);
                    body = { functionName: ExternalFunctions.INVOKE_LISTENERS, 
                             argument: { type: type, group: Groups.NODES, target: objs } };
                    
                    sendNotification(ApplicationFacade.CALL_EXTERNAL_INTERFACE, body);
                }
                
                if (edges.length > 0 && extProxy.hasListener(type, Groups.EDGES)) {
                    objs = GraphUtils.toExtObjectsArray(edges);
                    body = { functionName: ExternalFunctions.INVOKE_LISTENERS, 
                             argument: { type: type, group: Groups.EDGES, target: objs } };

                    sendNotification(ApplicationFacade.CALL_EXTERNAL_INTERFACE, body);
                }
                
                if ((nodes.length > 0 || edges.length > 0) && extProxy.hasListener(type, Groups.NONE)) {
                    var all:Array = [];
                    all = all.concat(nodes).concat(edges);

                    objs = GraphUtils.toExtObjectsArray(all);
                    body = { functionName: ExternalFunctions.INVOKE_LISTENERS, 
                             argument: { type: type, group: Groups.NONE, target: objs } };

                    sendNotification(ApplicationFacade.CALL_EXTERNAL_INTERFACE, body);
                }
            }
        }
    }
}