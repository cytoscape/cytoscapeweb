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
    
    import org.cytoscapeweb.model.ConfigProxy;
    import org.cytoscapeweb.model.GraphProxy;
    import org.cytoscapeweb.model.data.VisualStyleVO;
    import org.cytoscapeweb.model.methods.error;
    import org.cytoscapeweb.view.ApplicationMediator;
    import org.cytoscapeweb.view.GraphMediator;
    import org.cytoscapeweb.view.components.GraphView;
    import org.puremvc.as3.interfaces.INotification;
    import org.puremvc.as3.patterns.command.SimpleCommand;
    
    
    public class DrawGraphCommand extends SimpleCommand {
        
        override public function execute(notification:INotification):void {
            try {
                var options:Object = notification.getBody();
                var cfgProxy:ConfigProxy = facade.retrieveProxy(ConfigProxy.NAME) as ConfigProxy;
    
                if (options.visualStyle != null)
                    cfgProxy.visualStyle = VisualStyleVO.fromObject(options.visualStyle);
                if (options.layout != null)
                    cfgProxy.currentLayout = options.layout;
                if (options.edgesMerged != null)
                    cfgProxy.edgesMerged = options.edgesMerged;
                if (options.nodeTooltipsEnabled != null)
                    cfgProxy.nodeTooltipsEnabled = options.nodeTooltipsEnabled;
                if (options.edgeTooltipsEnabled != null)
                    cfgProxy.edgeTooltipsEnabled = options.edgeTooltipsEnabled;
                if (options.nodeLabelsVisible != null)
                    cfgProxy.nodeLabelsVisible = options.nodeLabelsVisible;
                if (options.edgeLabelsVisible != null)
                    cfgProxy.edgeLabelsVisible = options.edgeLabelsVisible;
                if (options.panZoomControlVisible != null)
                    cfgProxy.panZoomControlVisible = options.panZoomControlVisible;
                
                var graphProxy:GraphProxy = facade.retrieveProxy(GraphProxy.NAME) as GraphProxy;
                graphProxy.loadGraph(options);
                
                var appMediator:ApplicationMediator = facade.retrieveMediator(ApplicationMediator.NAME) as ApplicationMediator;
                appMediator.applyVisualStyle(cfgProxy.visualStyle);
                
                if (facade.hasMediator(GraphMediator.NAME))
                    facade.removeMediator(GraphMediator.NAME);
    
                var graphView:GraphView = CytoscapeWeb(appMediator.getViewComponent()).graphView;
                facade.registerMediator(new GraphMediator(graphView));
            
                var graphMediator:GraphMediator = facade.retrieveMediator(GraphMediator.NAME) as GraphMediator;
                graphMediator.drawGraph();
            } catch (err:Error) {
                error(err.message, err.errorID, err.name, err.getStackTrace());
            }
        }
    }
}