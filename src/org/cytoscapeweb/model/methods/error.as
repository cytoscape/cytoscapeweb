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
package org.cytoscapeweb.model.methods {
    import org.cytoscapeweb.ApplicationFacade;
    import org.cytoscapeweb.model.error.CWError;
    import org.puremvc.as3.patterns.observer.Notification;

    /**
     * Gets a resource bundle string.
     */
    public function error(err:Error):void {
        var id:* = (err is CWError) ? CWError(err).code : err.errorID;
        id = id != null ? ""+id : null;
        
        var msg:String = err.message;
        var name:String = err.name;
        var stackTrace:String = err.getStackTrace();
        
        var b:Object = { msg: msg, id: id, name: name, stackTrace: stackTrace };
        var n:Notification = new Notification(ApplicationFacade.ERROR, b);
        
        ApplicationFacade.getInstance().notifyObservers(n);
    }
}