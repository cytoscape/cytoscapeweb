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
    import flare.data.DataUtil;
    
    import org.cytoscapeweb.ApplicationFacade;
    import org.cytoscapeweb.model.error.CWError;
    import org.cytoscapeweb.model.methods.error;
    import org.cytoscapeweb.util.Groups;
    import org.puremvc.as3.interfaces.INotification;
    

    /**
     * Add a custom attribute definition to the current node or edge data schema.
     */
    public class AddDataFieldCommand extends BaseSimpleCommand {
        
        override public function execute(notification:INotification):void {
            try {
                var body:Object = notification.getBody();
                var group:String = body.group;
                var df:Object = body.dataField;
                
                if (df == null) throw new Error("The 'dataField' object was not informed");
                if (df.name == null) throw new Error("The 'name' attribute of the 'dataField' object is mandatory");
                if (df.type == null) throw new Error("The 'type' attribute of the 'dataField' object is mandatory");
                
                if (group == null) group = Groups.NONE;
                
                var type:* = df.type;
                switch (type) {
                    case "boolean": type = DataUtil.BOOLEAN; break;
                    case "int":     type = DataUtil.INT; break;
                    case "number":  type = DataUtil.NUMBER; break;
                    case "string":  type = DataUtil.STRING; break;
                    case "object":
                    default:        type = DataUtil.OBJECT;
                }
                
                var added:Boolean = graphProxy.addDataField(group, df.name, type, df.defValue);
                
                if (added) sendNotification(ApplicationFacade.GRAPH_DATA_CHANGED);
            } catch (err:Error) {
                trace("[ERROR]: AddDataFieldCommand.execute: " + err.getStackTrace());
                error(err);
            }
        }
    }
}