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
    import org.cytoscapeweb.model.converters.ExternalObjectConverter;
    import org.cytoscapeweb.util.ExternalFunctions;
    import org.cytoscapeweb.util.Groups;
    import org.puremvc.as3.interfaces.INotification;
    

    /**
     * Take the necessary actions after a node or edge was clicked or double-clicked.
     * The target DataSprite (node or edge) must be sent as the notification body.
     */
    public class HandleClickCommand extends BaseSimpleCommand {
        
        override public function execute(notification:INotification):void {
            var body:Object = notification.getBody();
            var ds:DataSprite, mouseX:Number, mouseY:Number;
            
            if (body != null) {
            	ds = body.target as DataSprite;
            	mouseX = body.mouseX;
            	mouseY = body.mouseY;
            }
            
            var action:String = notification.getName();
            var group:String = Groups.groupOf(ds); 
            
            var type:String = action === ApplicationFacade.DOUBLE_CLICK_EVENT ? "dblclick" : "click";
            
            // Call external listener:            
            if (extMediator.hasListener(type, group)) {
                var target:Object = ExternalObjectConverter.toExtElement(ds, graphProxy.zoom);
                
                body = { functionName: ExternalFunctions.INVOKE_LISTENERS, 
                         argument: { type: type,
                                     group: group, 
                                     target: target,
                                     mouseX: mouseX,
                                     mouseY: mouseY } };
                
                sendNotification(ApplicationFacade.CALL_EXTERNAL_INTERFACE, body);
            }
        }
    }
}
