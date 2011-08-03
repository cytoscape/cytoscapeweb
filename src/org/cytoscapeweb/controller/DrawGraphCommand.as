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
    
    import org.cytoscapeweb.model.data.VisualStyleVO;
    import org.cytoscapeweb.model.methods.error;
    import org.cytoscapeweb.util.BoxPositions;
    import org.cytoscapeweb.view.GraphMediator;
    import org.cytoscapeweb.view.components.GraphView;
    import org.cytoscapeweb.view.render.ImageCache;
    import org.puremvc.as3.interfaces.INotification;
    
    
    public class DrawGraphCommand extends BaseSimpleCommand {
        
        private var _imgCache:ImageCache = ImageCache.instance;
        
        override public function execute(notification:INotification):void {
            try {
                var options:Object = notification.getBody();
    
                configProxy.panZoomControlPosition = BoxPositions.parse(options.panZoomControlPosition);
    
                if (options.visualStyle != null)
                    configProxy.visualStyle = VisualStyleVO.fromObject(options.visualStyle);
                if (options.layout != null)
                    configProxy.currentLayout = options.layout;
                if (options.edgesMerged != null)
                    configProxy.edgesMerged = options.edgesMerged;
                if (options.nodeTooltipsEnabled != null)
                    configProxy.nodeTooltipsEnabled = options.nodeTooltipsEnabled;
                if (options.edgeTooltipsEnabled != null)
                    configProxy.edgeTooltipsEnabled = options.edgeTooltipsEnabled;
                if (options.nodeLabelsVisible != null)
                    configProxy.nodeLabelsVisible = options.nodeLabelsVisible;
                if (options.edgeLabelsVisible != null)
                    configProxy.edgeLabelsVisible = options.edgeLabelsVisible;
                if (options.panZoomControlVisible != null)
                    configProxy.panZoomControlVisible = options.panZoomControlVisible;
                if (options.mouseDownToDragDelay != null)
                    configProxy.mouseDownToDragDelay = options.mouseDownToDragDelay;
                if (options.preloadImages != null)
                    configProxy.preloadImages = options.preloadImages;
                
                // Load the model:
                graphProxy.loadGraph(options.network, configProxy.currentLayout);
                
                if (configProxy.preloadImages)
                    _imgCache.loadImages(configProxy.visualStyle, graphProxy.nodes, draw);
                else
                    draw();
                
                function draw():void {
	                appMediator.applyVisualStyle(configProxy.visualStyle);
	
	                var graphView:GraphView = CytoscapeWeb(appMediator.getViewComponent()).graphView;
	                facade.registerMediator(new GraphMediator(graphView));
	
	                graphMediator.drawGraph();
	            }
            } catch (err:Error) {
                trace("[ERROR]: DrawGraphCommand.execute: " + err.getStackTrace());
                error(err);
            }
        }
    }
}