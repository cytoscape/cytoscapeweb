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
    import org.cytoscapeweb.model.ExternalInterfaceProxy;
    import org.cytoscapeweb.util.ExternalFunctions;
    import org.cytoscapeweb.util.Groups;
    import org.cytoscapeweb.view.ApplicationMediator;
    import org.puremvc.as3.interfaces.INotification;
    import org.puremvc.as3.patterns.command.SimpleCommand;
    

    /**
     * If there is an external listener (JavaScript) for "error" events, just call it.
     * Otherwise, ask Cytoscape Web to display it.
     */
    public class ShowErrorCommand extends SimpleCommand {
        
        override public function execute(notification:INotification):void {
            var b:* = notification.getBody();
            var msg:String = "Unknown Error", id:*, name:String, stackTrace:String;

            if (b is String) {
                msg = b;
            } else {
                if (b.hasOwnProperty("msg") && b.msg != null) msg = encode(b.msg);
                if (b.hasOwnProperty("id")) id = b.id;
                if (b.hasOwnProperty("name")) name = b.name;
                if (b.hasOwnProperty("stackTrace")) stackTrace = b.stackTrace;
            }

            var extProxy:ExternalInterfaceProxy = facade.retrieveProxy(ExternalInterfaceProxy.NAME) as ExternalInterfaceProxy;
            
            if (extProxy.hasListener("error", Groups.NONE)) {
                var err:Object = { msg: msg };
                if (id != null) err.id = id;
                if (name != null) err.name = name;
                if (stackTrace != null) err.stackTrace = encode(stackTrace);
                
                var arg:Object = { type: "error", group: Groups.NONE, value: err };
                var body:Object = { functionName: ExternalFunctions.INVOKE_LISTENERS, argument: arg };
                
                sendNotification(ApplicationFacade.CALL_EXTERNAL_INTERFACE, body);
            } else {
                var mediator:ApplicationMediator = facade.retrieveMediator(ApplicationMediator.NAME) as ApplicationMediator;
                mediator.showError(msg);
            }
        }
        
        private function encode(str:*):String {
            if (str is String) {
                str = str.replace(/[\\]/g, "\\\\").replace(/[\"]/g, "'");
            }
            return str;
        }
    }
}
