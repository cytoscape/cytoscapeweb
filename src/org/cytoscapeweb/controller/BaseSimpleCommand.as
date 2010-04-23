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
    import org.cytoscapeweb.model.ContextMenuProxy;
    import org.cytoscapeweb.model.GraphProxy;
    import org.cytoscapeweb.view.ApplicationMediator;
    import org.cytoscapeweb.view.ExternalMediator;
    import org.cytoscapeweb.view.GraphMediator;
    import org.puremvc.as3.patterns.command.SimpleCommand;

    /**
     * Abstract superclass of all simple commands used by Cytoscape Web.
     * It just exposes the proxies and mediators to its subclasses.
     */ 
    public class BaseSimpleCommand extends SimpleCommand {
     
        // ========[ PRIVATE PROPERTIES ]===========================================================
        
        private var _configProxy:ConfigProxy;
        private var _graphProxy:GraphProxy;
        private var _menuProxy:ContextMenuProxy;
        private var _extMediator:ExternalMediator;
        private var _appMediator:ApplicationMediator;
        private var _graphMediator:GraphMediator;

        // ========[ PROTECTED PROPERTIES ]=========================================================
   
        protected function get graphProxy():GraphProxy {
            if (_graphProxy == null)
                _graphProxy = facade.retrieveProxy(GraphProxy.NAME) as GraphProxy;
            return _graphProxy;
        }
        
        protected function get configProxy():ConfigProxy {
            if (_configProxy == null)
                _configProxy = facade.retrieveProxy(ConfigProxy.NAME) as ConfigProxy;
            return _configProxy;
        }
        
        protected function get menuProxy():ContextMenuProxy {
            if (_menuProxy == null)
                _menuProxy = facade.retrieveProxy(ContextMenuProxy.NAME) as ContextMenuProxy;
            return _menuProxy;
        }
        
        protected function get extMediator():ExternalMediator {
            if (_extMediator == null)
                _extMediator = facade.retrieveMediator(ExternalMediator.NAME) as ExternalMediator;
            return _extMediator;
        }
        
        protected function get appMediator():ApplicationMediator {
            if (_appMediator == null)
                _appMediator = facade.retrieveMediator(ApplicationMediator.NAME) as ApplicationMediator;
            return _appMediator;
        }
        
        protected function get graphMediator():GraphMediator {
            if (_graphMediator == null)
                _graphMediator = facade.retrieveMediator(GraphMediator.NAME) as GraphMediator;
            return _graphMediator;
        }
    }
}