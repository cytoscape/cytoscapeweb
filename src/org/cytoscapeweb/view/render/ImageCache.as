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
    import flare.vis.data.NodeSprite;
    
    import flash.display.BitmapData;
    import flash.display.Loader;
    import flash.events.Event;
    import flash.events.IOErrorEvent;
    import flash.net.URLRequest;
    import flash.system.LoaderContext;
    
    import mx.utils.StringUtil;
    
    import org.cytoscapeweb.model.data.DiscreteVizMapperVO;
    import org.cytoscapeweb.model.data.VisualPropertyVO;
    import org.cytoscapeweb.model.data.VisualStyleBypassVO;
    import org.cytoscapeweb.model.data.VisualStyleVO;
    import org.cytoscapeweb.model.data.VizMapperVO;
    import org.cytoscapeweb.model.error.CWError;
    import org.cytoscapeweb.model.methods.error;
    import org.cytoscapeweb.util.ErrorCodes;
    import org.cytoscapeweb.util.VisualProperties;
    
    
    public class ImageCache {
        
        // ========[ CONSTANTS ]====================================================================
        
        private const IMG_PROPS:Array = [ VisualProperties.NODE_IMAGE ];
        
        // ========[ PRIVATE PROPERTIES ]===========================================================
        
        private var _images:/*URL->BitmapData*/Object = {};
        private var _broken:/*URL->Boolean*/Object = {};
        private var _imgCounter:/*URL->int*/Object = {};
        private var _styleUrl:/*URL->Boolean*/Object = {};
        private var _bypassUrl:/*URL->Boolean*/Object = {};
        private var _onLoadingEnd:Function;
        
        // ========[ PUBLIC PROPERTIES ]============================================================
        
        public function get size():int {
            var count:int = 0;
            for (var url:String in _images) {
                if (_images[url] is BitmapData) count++;
            }
            return count;
        }
                
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
        
        /**
         * @param style A VisualStyleVO or VisualStyleBypassVO object
         * @param nodes An optional array of nodes. Necessary if loading from a VisualStyleVO that
         *              sets images from Passthrough or Custom mappers.
         * @param onLoadingEnd An optional callback function
         */
        public function loadImages(style:*, nodes:Array=null, onLoadingEnd:Function=null):void {trace("ImageCache.loadImages...");
            var url:String, values:Array, pname:String;
            _onLoadingEnd = onLoadingEnd;

            function loadIfNew(url:String, urlMap:Object):void {
                url = normalize(url);
                if (!contains(url)) {
                    urlMap[url] = true;
                    loadImage(url);
                }
            }
            
            // Load all distinct URL values:
            if (style is VisualStyleVO) {
                // Decrease image counter for all current images associated with the previous visual style:
                releasePrevious(_styleUrl);
                var vs:VisualStyleVO = VisualStyleVO(style);
                
                for each (pname in IMG_PROPS) {
                    if (vs.hasVisualProperty(pname)) {
                        var vp:VisualPropertyVO = vs.getVisualProperty(pname);
                        // Default value:
                        url = vp.defaultValue;
                        loadIfNew(url, _styleUrl);
                        
                        // Discrete Mapper values:
                        var mapper:VizMapperVO= vp.vizMapper;
                        
                        if (mapper is DiscreteVizMapperVO) {
                            var dm:DiscreteVizMapperVO = DiscreteVizMapperVO(mapper);
                            values = dm.distinctValues;
                            
                            for each (url in values) {
                                loadIfNew(url, _styleUrl);
                            }
                        } else if (mapper != null && nodes != null) {
                            for each (var n:NodeSprite in nodes) {
                               url = mapper.getValue(n.data);
                               loadIfNew(url, _styleUrl);
                            }
                        }
                    }
                }
            } else if (style is VisualStyleBypassVO) {
                releasePrevious(_bypassUrl);

                for each (pname in IMG_PROPS) {
                    values = VisualStyleBypassVO(style).getValuesSet(pname);
                    
                    for each (url in values) {
                        loadIfNew(url, _bypassUrl);
                    }
                }
            }
            
            deleteUnusedImages();
            checkOnLoadingEnd();
        }
        
        public function getImage(url:String):BitmapData {trace("getImage: " + url);
            return _images[normalize(url)];
        }
        
        public function loadImage(url:String, onImgLoaded:Function=null):void {trace("loadImage...");
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
                    retain(url);
                    if (onImgLoaded != null) onImgLoaded(url, bmp);
                    checkOnLoadingEnd();
                });
                
                loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, function(e:IOErrorEvent):void {trace("ImageCache - Error loading image: " + e);
                    _broken[url] = true;
                    error(new CWError("Image cannot be loaded: "+url+" ("+e.type+"--"+e.text+")", ErrorCodes.BROKEN_IMAGE));
                    checkOnLoadingEnd();
                });
                
                loader.load(urlRequest, new LoaderContext(true));
            }
        }
        
        public function releaseBypassImages():void {
            releasePrevious(_bypassUrl);
            deleteUnusedImages();
        }
        
        public function dispose():void {
            _images = {};
            _broken = {};
            _imgCounter= {};
            _styleUrl = {};
            _bypassUrl = {};
            _onLoadingEnd = null;
        }
        
        // ========[ PRIVATE METHODS ]==============================================================
        
        /**
         * It actually just trims the URL string or return an empty string if it is null;
         */
        private function normalize(url:String):String {
            return url != null ? StringUtil.trim(url) : "";
        }
        
        private function checkOnLoadingEnd():void {
            if (_onLoadingEnd != null) {
                if (!isLoading()) {
                    // Execute the callback function only once!
                    var fn:Function = _onLoadingEnd;
                    _onLoadingEnd = null;
                    fn(undefined);
                }
            }
        }
        
        private function retain(url:String):void {
            var count:int = _imgCounter[url];
            if (isNaN(count)) count = 0;
            _imgCounter[url] = ++count;
        }
        
        private function release(url:String):void {
            var count:int = _imgCounter[url];
            _imgCounter[url] = --count;
        }
        
        private function releasePrevious(urlMap:Object):void {
            for (var url:String in urlMap) release(url);
        }
        
        private function deleteUnusedImages():void {
            for (var url:String in _imgCounter) {
                if (_imgCounter[url] === 0) {
                    delete _imgCounter[url];
                    delete _broken[url];
                    
                    var bd:BitmapData = _images[url];
                    if (bd != null) bd.dispose();
                    delete _images[url];
                }
            }
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