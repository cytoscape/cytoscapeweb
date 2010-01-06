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
    import flash.utils.ByteArray;
    
    import mx.utils.StringUtil;
    
    import org.cytoscapeweb.model.GraphProxy;
    import org.cytoscapeweb.model.methods.error;
    import org.cytoscapeweb.view.ApplicationMediator;
    import org.puremvc.as3.interfaces.INotification;
    import org.puremvc.as3.patterns.command.SimpleCommand;

    public class ExportNetworkCommand extends SimpleCommand {
    	
        override public function execute(notification:INotification):void {
            try {
                var body:Object = notification.getBody();
                var format:String = StringUtil.trim((""+body.format).toLowerCase());
                var url:String = body.url;
                var options:Object = body.options;
                var w:Number, h:Number, window:String, data:*;
                
                if (options != null) {
                    w = options.width;
                    h = options.height;
                    window = options.window;
                }
                if (window == null) window = "_self";
                
                var graphProxy:GraphProxy = facade.retrieveProxy(GraphProxy.NAME) as GraphProxy;

                if (format === "xgmml" || format === "graphml") {
                    // Get the XML:
                    data = graphProxy.getDataAsXml(format);
                } else {
                    // Get the image bytes from the graph mediator class:
                    var appMediator:ApplicationMediator = facade.retrieveMediator(ApplicationMediator.NAME) as ApplicationMediator;
                    data = appMediator.getGraphImage(format, w, h);
                }
                
                // Export:
                graphProxy.export(data, url, window);
                
            } catch (err:Error) {
                error(err.message, err.errorID, err.name, err.getStackTrace());
            }
        }
    }
}