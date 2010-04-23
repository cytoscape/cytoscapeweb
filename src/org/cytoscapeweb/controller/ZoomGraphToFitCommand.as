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
    import org.cytoscapeweb.util.ExternalFunctions;
    import org.puremvc.as3.interfaces.INotification;
    

    /**
     * Scale the graph to 100% or less until it fits the canvas. 
     */
    public class ZoomGraphToFitCommand extends BaseSimpleCommand {
        
        override public function execute(notification:INotification):void {
            var scale:Number = graphProxy.zoom;
            
            graphMediator.zoomGraphToFit();

            var newScale:Number = graphProxy.zoom;
            
            if (newScale != scale) {
                // Call external listener:
                if (extMediator.hasListener("zoom")) {
                    var body:Object = { functionName: ExternalFunctions.INVOKE_LISTENERS, 
                                        argument: { type: "zoom", value: newScale } };
                    
                    sendNotification(ApplicationFacade.CALL_EXTERNAL_INTERFACE, body);
                }
            }
        }
    }
}
