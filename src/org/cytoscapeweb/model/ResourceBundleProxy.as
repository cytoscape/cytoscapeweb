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
package org.cytoscapeweb.model {
	import flash.events.Event;
	import flash.events.HTTPStatusEvent;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	
	import mx.resources.ResourceBundle;
	import mx.resources.ResourceManager;
	import mx.utils.StringUtil;
	
	import org.cytoscapeweb.ApplicationFacade;
	import org.puremvc.as3.patterns.proxy.Proxy;
	

    [Bindable]
    public class ResourceBundleProxy extends Proxy {

        // ========[ CONSTANTS ]====================================================================

        public static const NAME:String = 'ResourceBundleProxy';

        // ========[ PRIVATE PROPERTIES ]===========================================================

        /** Provided resource bundle */
        [ResourceBundle("bundle")]
        private var _bundle:ResourceBundle;

        // ========[ PUBLIC PROPERTIES ]============================================================

        [Bindable(event="resourceBundleChange")]
        public function get resourceBundle():ResourceBundle {
            return _bundle;
        }
        
        public function set resourceBundle(bundle:ResourceBundle):void {
            if (bundle != null) {
                _bundle = bundle;
                
                ResourceManager.getInstance().addResourceBundle(_bundle);
                ResourceManager.getInstance().update();
                
                sendNotification(ApplicationFacade.RESOURCE_BUNDLE_CHANGED, _bundle);
            }
        }
        
        // ========[ CONSTRUCTOR ]==================================================================

        public function ResourceBundleProxy(params:Object = null) {
            super(NAME);

            if (params != null && params.resourceBundleUrl != null) {
                load(params.resourceBundleUrl);
            }
            
            sendNotification(ApplicationFacade.RESOURCE_BUNDLE_CHANGED, resourceBundle);
        }

        // ========[ PUBLIC METHODS ]===============================================================
        

        // ========[ PRIVATE METHODS ]==============================================================
        
        private function load(url:String):void {
            var req:URLRequest = new URLRequest(url);

            var loader:URLLoader = new URLLoader();
            loader.addEventListener(Event.COMPLETE, doEvent);
            loader.addEventListener(Event.OPEN, doEvent);
            loader.addEventListener(HTTPStatusEvent.HTTP_STATUS, doEvent);
            loader.addEventListener(ProgressEvent.PROGRESS, doEvent);
            loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, doEvent);
            loader.addEventListener(IOErrorEvent.IO_ERROR, doEvent);
            loader.load(req);
        }

        private function doEvent(evt:Event):void {
            switch (evt.type) {
                case Event.COMPLETE:
                    var loader:URLLoader = evt.currentTarget as URLLoader;
                    var lines:Array = String(loader.data).split("\n");
                    
                    for each (var line:String in lines) {
                        line = StringUtil.trim(line);
                        
                        // Not a comment and has more than 2 chars:
                        if (line.length > 2 && line.charAt(0) != "#") {
                        	var idx:int = line.indexOf("=");
	                        
	                        // Must have '=' but cannot start with it:
	                        if (idx > 0 && line.length > idx) {
	                        	var key:String = StringUtil.trim(line.substr(0, idx));
	                        	var value:String = line.length > idx+1 ? StringUtil.trim(line.substr(idx+1)) : "";
		                        
		                        if (key != "") _bundle.content[key] = value;
		                    }
                        }
                    }
                    
                    resourceBundle = _bundle;
                    
                    break;
                case IOErrorEvent.IO_ERROR:
                case SecurityErrorEvent.SECURITY_ERROR:
                    trace("[INFO] No custom Resource Bundle found: " + evt.toString());
                    break;
            }
        }
    }
}