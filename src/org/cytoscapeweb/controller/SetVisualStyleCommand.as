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
	import org.cytoscapeweb.view.render.ImageCache;
	import org.puremvc.as3.interfaces.INotification;
	

    public class SetVisualStyleCommand extends BaseSimpleCommand {
        
        private var _imgCache:ImageCache = ImageCache.instance;
        
        override public function execute(notification:INotification):void {
            var style:VisualStyleVO = notification.getBody() as VisualStyleVO;
            style.visualStyleBypass = configProxy.visualStyleBypass;
            
            if (style != null) {
                // Set the new style:
                configProxy.visualStyle = style;
                
                // Then bind the data again, so the new vizMappers can work:
                configProxy.bindGraphData(graphProxy.graphData);
                
                // Preload images?
                if (configProxy.preloadImages) {
                    _imgCache.loadImages(configProxy.visualStyle, graphProxy.nodes, ready);
                } else {
                    _imgCache.dispose(); // TODO: implement a better way of disposing previous images.
                    ready();
                }
            }
        }
        
        private function ready(obj:Object=null):void {
            // Ask the mediators to apply the new style:
            appMediator.applyVisualStyle(configProxy.visualStyle);
            graphMediator.applyVisualStyle(configProxy.visualStyle);
            
            if (graphProxy.compoundGraph) {
                graphMediator.updateParentNodes(graphProxy.nodes);
            }
        }
    }
}