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
    import org.cytoscapeweb.model.ConfigProxy;
    import org.cytoscapeweb.model.ExternalInterfaceProxy;
    import org.cytoscapeweb.model.data.VisualStyleBypassVO;
    import org.cytoscapeweb.util.ExternalFunctions;
    import org.cytoscapeweb.view.GraphMediator;
    import org.puremvc.as3.interfaces.INotification;
    import org.puremvc.as3.patterns.command.SimpleCommand;
    

    public class SetVisualStyleBypassCommand extends SimpleCommand {
        
        override public function execute(notification:INotification):void {
            var bypass:VisualStyleBypassVO = notification.getBody() as VisualStyleBypassVO;
            
            if (bypass != null) {
                var cfgProxy:ConfigProxy = facade.retrieveProxy(ConfigProxy.NAME) as ConfigProxy;
                cfgProxy.visualStyleBypass = bypass;
                
                var grMediator:GraphMediator = facade.retrieveMediator(GraphMediator.NAME) as GraphMediator;
                grMediator.applyVisualBypass(cfgProxy.visualStyle);
                
                var extProxy:ExternalInterfaceProxy = facade.retrieveProxy(ExternalInterfaceProxy.NAME) as ExternalInterfaceProxy;

                if (extProxy.hasListener("visualstyle")) {
                    var body:Object = { functionName: ExternalFunctions.INVOKE_LISTENERS, 
                                        argument: { type: "visualstyle", value: bypass.toObject() } };
                    
                    sendNotification(ApplicationFacade.CALL_EXTERNAL_INTERFACE, body);
                }
            }
        }
    }
}
