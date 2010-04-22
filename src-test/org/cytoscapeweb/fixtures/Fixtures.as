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
package org.cytoscapeweb.fixtures {
    import flare.data.DataSet;
    import flare.vis.data.Data;
    
    import flash.utils.ByteArray;
    
    import org.cytoscapeweb.ApplicationFacade;
    import org.cytoscapeweb.model.GraphProxy;
    import org.cytoscapeweb.model.converters.GraphMLConverter;
    import org.cytoscapeweb.model.converters.SIFConverter;
    
    public class Fixtures {
        
        // ========[ CONSTANTS ]====================================================================
    
        [Embed(source="/assets/fixtures/simple.xml", mimeType="application/octet-stream")]
        public static const GRAPHML_SIMPLE:Class;
        
        [Embed(source="/assets/fixtures/tabs.sif", mimeType="application/octet-stream")]
        public static const SIF_TABS:Class;
        [Embed(source="/assets/fixtures/spaces.sif", mimeType="application/octet-stream")]
        public static const SIF_SPACES:Class;
        
        // ========[ PRIVATE PROPERTIES ]===========================================================
        
        private static var _xmlCache:Object = {};
        private static var _stringCache:Object = {};

        // ========[ PUBLIC PROPERTIES ]============================================================

        // ========[ PUBLIC METHODS ]===============================================================
        
        public static function getFixtureAsString(fixtureClass:Class):String {
            var txt:String = _stringCache[fixtureClass];
            
            if (txt == null) {
            	var ba:ByteArray = new fixtureClass() as ByteArray;
            	txt = ba.readUTFBytes(ba.length);
            	_stringCache[fixtureClass] = txt;
            }
            
            return txt;
        }
        
        public static function getFixtureAsXml(fixtureClass:Class):XML {
            var xml:XML = _xmlCache[fixtureClass];
            
            if (xml == null) {
            	var ba:ByteArray = new fixtureClass() as ByteArray;
            	xml = XML(ba.readUTFBytes(ba.length));
            	_xmlCache[fixtureClass] = xml;
            }
            
            return xml;
        }
        
        public static function getData(fixtureClass:Class):Data {
        	var ds:DataSet = getDataSet(fixtureClass);
            var graphProxy:GraphProxy = new GraphProxy(ds);
            var data:Data = graphProxy.graphData;

            return data;
        }
        
        public static function getDataSet(fixture:Class):DataSet {
            var ds:DataSet;
            
            if (isGraphML(fixture)) {
                var xml:XML = getFixtureAsXml(fixture);
                ds = new GraphMLConverter().parse(xml);
            } else if (isSIF(fixture)) {
                var sif:String = getFixtureAsString(fixture);
                ds = new SIFConverter().parse(sif);
            }

            return ds;
        }
        
        public static function getRandomData(num:int):Data {
            var data:Data = new Data();
            var nodes:Array = new Array(num);
            
            for (var i:int = 0; i < num; i++)
                nodes[i] = data.addNode();
            
            var source:int;
            var target:int;
            for (i = 0; i < num; ++i) {
                source = i;
                target = (i + 1) % num;
                data.addEdgeFor(nodes[source], nodes[target]);        
                
                if (Math.random() > 0.5) { 
                    target = (int) (Math.random() * num);
                    data.addEdgeFor(nodes[source], nodes[target]);        
                }   
            }
            
            return data;
        }
        
        // ========[ PRIVATE METHODS ]==============================================================

        private static function isGraphML(fixture:Class):Boolean {
            return fixture == Fixtures.GRAPHML_SIMPLE;
        }
        
        private static function isSIF(fixture:Class):Boolean {
            return fixture == Fixtures.SIF_SPACES || fixture == Fixtures.SIF_TABS;
        }
        
    }
}