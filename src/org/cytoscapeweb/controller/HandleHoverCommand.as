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
    import flare.vis.data.EdgeSprite;
    import flare.vis.data.NodeSprite;
    
    import org.cytoscapeweb.ApplicationFacade;
    import org.cytoscapeweb.model.converters.ExternalObjectConverter;
    import org.cytoscapeweb.util.ExternalFunctions;
    import org.cytoscapeweb.util.Groups;
    import org.puremvc.as3.interfaces.INotification;
    

    /**
     * Take the necessary actions after a node or edge was rolled-over/rolled-out.
     * The target DataSprite (node or edge) must be sent as the notification body.
     */
    public class HandleHoverCommand extends BaseSimpleCommand {
        
        override public function execute(notification:INotification):void {
            var ds:DataSprite = notification.getBody() as DataSprite;
            var action:String = notification.getName();
            var group:String = Groups.groupOf(ds);
            
            var type:String = action === ApplicationFacade.ROLLOVER_EVENT ? "mouseover" : "mouseout";
            var previousDs:DataSprite;
            
            switch (action) {
                case ApplicationFacade.ROLLOVER_EVENT:
                    if (ds is NodeSprite) {
                        previousDs = graphProxy.rolledOverNode;
                        graphProxy.rolledOverNode = NodeSprite(ds);
                    } else if (ds is EdgeSprite) {
                        previousDs = graphProxy.rolledOverEdge;
                        graphProxy.rolledOverEdge = EdgeSprite(ds);
                    }
                    break;
                case ApplicationFacade.ROLLOUT_EVENT:
                    if (ds is NodeSprite) {
                        previousDs = graphProxy.rolledOverNode;
                        graphProxy.rolledOverNode = null;
                    } else if (ds is EdgeSprite) {
                        previousDs = graphProxy.rolledOverEdge;
                        graphProxy.rolledOverEdge = null;
                    }
            }
            
            // Reset visual properties:
            if (previousDs != null) graphMediator.resetDataSprite(previousDs);
            if (ds != null) graphMediator.resetDataSprite(ds);
                
            // Call external listener:            
            if (extMediator.hasListener(type, group)) {
                var target:Object = ExternalObjectConverter.toExtElement(ds, graphProxy.zoom);

                var body:Object = { functionName: ExternalFunctions.INVOKE_LISTENERS, 
                                    argument: { type: type, group: group, target: target } };
                
                sendNotification(ApplicationFacade.CALL_EXTERNAL_INTERFACE, body);
            }
        }
    }
}
