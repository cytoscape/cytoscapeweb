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
    import org.cytoscapeweb.model.*;
    import org.cytoscapeweb.util.ExternalFunctions;
    import org.cytoscapeweb.view.*;
    import org.puremvc.as3.interfaces.INotification;
    import org.puremvc.as3.patterns.command.SimpleCommand;

    public class StartupCommand extends SimpleCommand {
        /**
         * Register the Proxies (MODEL) and Mediators (VIEW).
         * 
         * Before the user can be presented or interact with any of the application’s data, 
         * the Model must be placed in a consistent, known state.
         */
        override public function execute(notification:INotification):void {
            var app:CytoscapeWeb = notification.getBody() as CytoscapeWeb;

            // First, register the model classes:
            facade.registerProxy(new ConfigProxy(app.parameters));
            facade.registerProxy(new ResourceBundleProxy(app.parameters));
            facade.registerProxy(new GraphProxy());
            facade.registerProxy(new ContextMenuProxy());

            // Then, register the view:
            facade.registerMediator(new ApplicationMediator(app));
            facade.registerMediator(new ContextMenuMediator(app));
            facade.registerMediator(new PanZoomMediator(app.panZoomBox));
            facade.registerMediator(new ExternalMediator(app));
            
            // Should be called before addind the callbacks, because of a bug in Internet Explorer:
            sendNotification(ApplicationFacade.CALL_EXTERNAL_INTERFACE, { functionName: ExternalFunctions.BEFORE_COMPLETE });
            // Add the callback functions, in order to allow the Flash player
            // to comunicate with JavaScript functions:
            sendNotification(ApplicationFacade.ADD_CALLBACKS);
        }
    }
}