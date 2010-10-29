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
package org.cytoscapeweb.view.render {
    import flash.display.BitmapData;
    import flash.display.Loader;
    import flash.events.Event;
    import flash.events.IOErrorEvent;
    import flash.net.URLRequest;
    import flash.utils.Dictionary;
    
    import mx.utils.StringUtil;
    
    import org.cytoscapeweb.model.data.DiscreteVizMapperVO;
    import org.cytoscapeweb.model.data.VisualPropertyVO;
    import org.cytoscapeweb.model.data.VisualStyleVO;
    import org.cytoscapeweb.model.methods.error;
    import org.cytoscapeweb.util.ErrorCodes;
    import org.cytoscapeweb.util.VisualProperties;
    import org.cytoscapeweb.util.methods.$each;
    
    
    public class ImageCache {
        
        // ========[ CONSTANTS ]====================================================================
        
        private const IMG_PROPS:Array = [ VisualProperties.NODE_IMAGE ];
        
        // ========[ PRIVATE PROPERTIES ]===========================================================
        
        private var _images:Object = {};
        private var _broken:Object = {};
        
        // ========[ PUBLIC METHODS ]===============================================================
        
        public function isLoading():Boolean {
            for (var url:String in _images) {
                if (_images[url] === null) return true;
            }
            return false;
        }
        
        public function isLoaded(url:String):Boolean {
            url = normalize(url);
            return _images[url] != null;
        }
        
        public function isBroken(url:String):Boolean {
            url = normalize(url);
            return _broken[url];
        }
        
        public function contains(url:String):Boolean {
            url = normalize(url);
            return _images[url] !== undefined;
        }
        
        public function loadImages(style:VisualStyleVO):void {
            // First, clean the cache:
            _images = {};
            _broken = {};
            
            // Then load all distinct URL values:
            $each(IMG_PROPS, function(i:uint, pname:String):Boolean { 
                if (style.hasVisualProperty(pname)) {
                    var vp:VisualPropertyVO = style.getVisualProperty(pname);
                    // Default value:
                    if (!contains(vp.defaultValue)) loadImage(vp.defaultValue);
                    
                    // Discrete Mapper values:
                    var mapper:DiscreteVizMapperVO = vp.vizMapper as DiscreteVizMapperVO;
                    if (mapper != null) {
                        var values:Array = mapper.distinctValues;
                        
                        $each(IMG_PROPS, function(j:uint, url:String):Boolean {
                           if (!contains(url)) loadImage(url);
                           return false; 
                        });
                    }
                }
                return false;
            });
        }
        
        public function getImage(url:String):BitmapData {trace("getImage...");
            return _images[normalize(url)];
        }
        
        public function loadImage(url:String):void {trace("loadImage...");
            url = normalize(url);
            var bmp:BitmapData;
            
            if (url.length > 0) {
                _images[url] = null; // this flags the image state as "loading"
                _broken[url] = false;
                
                var urlRequest:URLRequest = new URLRequest(url);
                var loader:Loader = new Loader();
                
                loader.contentLoaderInfo.addEventListener(Event.COMPLETE, function(e:Event):void {trace(">> IMG LOADED: " + url);
                    bmp = e.target.content.bitmapData;
                    _images[url] = bmp;
                    _broken[url] = false;
                });
                
                loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, function(e:IOErrorEvent):void {trace("ImageCache - Error loading image: " + e);
                    _broken[url] = true;
                    error("Image cannot be loaded: " + url, ErrorCodes.BROKEN_IMAGE, e.type, e.text);
                });
                
                loader.load(urlRequest);
            }
        }
        
        // ========[ PRIVATE METHODS ]==============================================================
        
        /**
         * It actually just trims the URL string or return an empty string if it is null;
         */
        private function normalize(url:String):String {
            return url != null ? StringUtil.trim(url) : "";
        }
        
        // ========[ SINGLETON STUFF ]==============================================================

        private static var _instance:ImageCache;
        
        public function ImageCache(lock:SingletonLock) {
            if (lock == null) throw new Error("Invalid Singleton access. Use ImageCache.instance().");
        }
        
        public static function get instance():ImageCache {
            if (_instance == null) _instance = new ImageCache(new SingletonLock());
            return _instance;
        }

    }
}

/**
 * This is a private class declared outside of the package that is only accessible 
 * to classes inside of the Model.as file.
 * Because of that, no outside code is able to get a reference to this class to pass
 * to the constructor, which enables us to prevent outside instantiation.
 */
class SingletonLock { }