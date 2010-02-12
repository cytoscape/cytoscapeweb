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
    
    public class Fixtures {
        
        // ========[ CONSTANTS ]====================================================================
    
        [Embed(source="/assets/fixtures/simple.xml", mimeType="application/octet-stream")]
        public static const GRAPHML_SIMPLE:Class;
        
        // ========[ PRIVATE PROPERTIES ]===========================================================
        
        private static var _cache:Object;
        
        private static function get cache():Object {
            if (_cache == null) {
                _cache = new Object();
            }
            
            return _cache;
        }

        // ========[ PUBLIC PROPERTIES ]============================================================

        // ========[ PUBLIC METHODS ]===============================================================
        
        public static function getFixtureAsXml(fixtureClass:Class):XML {
            var xml:XML = cache[fixtureClass];
            
            if (xml == null) {
            	var ba:ByteArray = new fixtureClass() as ByteArray;
            	xml = XML(ba.readUTFBytes(ba.length));
            	cache[fixtureClass] = xml;
            }
            
            return xml;
        }
        
        public static function getData(fixtureClass:Class):Data {
        	var ds:DataSet = getDataSet(fixtureClass);
            var data:Data = Data.fromDataSet(ds);
            
            var graphProxy:GraphProxy = ApplicationFacade.getInstance().retrieveProxy(GraphProxy.NAME) as GraphProxy;
            graphProxy.dataSet = ds;
            graphProxy.graphData = data;
            data = graphProxy.graphData;

            return data;
        }
        
        public static function getDataSet(fixtureClass:Class):DataSet {
            var xml:XML = getFixtureAsXml(fixtureClass);
            var ds:DataSet = new GraphMLConverter().parse(xml);

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

    }
}