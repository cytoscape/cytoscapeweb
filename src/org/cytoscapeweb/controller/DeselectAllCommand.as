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
    import org.cytoscapeweb.util.Groups;
    import org.puremvc.as3.interfaces.INotification;
    

    /**
     * Handle the deselection of all nodes and edges.
     */
    public class DeselectAllCommand extends BaseSimpleCommand {
        
        override public function execute(notification:INotification):void {
            var group:String = notification.getBody() as String;
            if (group == null) group = Groups.NONE;

            if (group === Groups.NODES) {
                sendNotification(ApplicationFacade.DESELECT, graphProxy.selectedNodes);
            } else if (group === Groups.EDGES) {
	            var edges:Array = graphProxy.edgesMerged ? graphProxy.selectedMergedEdges : graphProxy.selectedEdges;
	            sendNotification(ApplicationFacade.DESELECT, edges);
	        } else if (group === Groups.NONE) {
	            var arr:Array = graphProxy.edgesMerged ? graphProxy.selectedMergedEdges : graphProxy.selectedEdges;
	            arr = arr.concat(graphProxy.selectedNodes);
	            sendNotification(ApplicationFacade.DESELECT, arr);
	        }
        }
    }
}
