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
    import org.cytoscapeweb.model.converters.ExternalObjectConverter;
    import org.cytoscapeweb.util.ExternalFunctions;
    import org.cytoscapeweb.util.Groups;
    import org.puremvc.as3.interfaces.INotification;
    

    /**
     * Remove nodes and edges filters.
     */
    public class RemoveFilterCommand extends BaseSimpleCommand {
        
        override public function execute(notification:INotification):void {
            var gr:String = notification.getBody().group;
            var updateVisualMappers:Boolean = notification.getBody().updateVisualMappers;
            
            if (gr == null) gr = Groups.NONE;
            
            var groups:Array = [Groups.NONE];
            var updateNodes:Boolean = false;
            var updateEdges:Boolean = false;

            // Update the model:
            if (graphProxy.filteredNodes != null && (gr === Groups.NONE || gr === Groups.NODES)) {
                graphProxy.filteredNodes = null;
                updateNodes = true;
                groups.push(Groups.NODES);
            }
            if (graphProxy.filteredEdges != null && (gr === Groups.NONE || gr === Groups.EDGES)) {
                graphProxy.filteredEdges = null;
                updateEdges = true;
                groups.push(Groups.EDGES);
            }
            
            if (updateNodes || updateEdges) {
                if (updateVisualMappers) configProxy.bindGraphData(graphProxy.graphData);
                
                // Update the view:
                graphMediator.updateFilters(updateNodes, updateEdges, updateVisualMappers);
                
                // Call listeners:
                var objs:Array, body:Object, type:String = "filter";
            
                if (updateNodes && extMediator.hasListener(type, Groups.NODES)) {
                    body = { functionName: ExternalFunctions.INVOKE_LISTENERS, 
                             argument: { type: type, group: Groups.NODES, target: null } };
                    
                    sendNotification(ApplicationFacade.CALL_EXTERNAL_INTERFACE, body);
                }
                
                if (updateEdges && extMediator.hasListener(type, Groups.EDGES)) {
                    body = { functionName: ExternalFunctions.INVOKE_LISTENERS, 
                             argument: { type: type, group: Groups.EDGES, target: null } };
    
                    sendNotification(ApplicationFacade.CALL_EXTERNAL_INTERFACE, body);
                }
                
                if ((updateNodes || updateEdges) && extMediator.hasListener(type, Groups.NONE)) {
                    var all:Array = null;
                    var fn:Array = graphProxy.filteredNodes;
                    var fe:Array = graphProxy.filteredEdges;
                    if (fn != null || fe != null) {
                        all = [];
                        if (fn != null) all = all.concat(fn);
                        if (fe != null) all = all.concat(fe);
                    }
    
                    objs = ExternalObjectConverter.toExtElementsArray(all, graphProxy.zoom);
                    body = { functionName: ExternalFunctions.INVOKE_LISTENERS, 
                             argument: { type: type, group: Groups.NONE, target: objs } };
    
                    sendNotification(ApplicationFacade.CALL_EXTERNAL_INTERFACE, body);
                }
            }
        }
    }
}