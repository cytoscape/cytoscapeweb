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
    import flash.utils.setTimeout;
    
    import flexunit.framework.TestCase;
    
    import org.cytoscapeweb.model.data.VisualStyleVO;
    
    
    public class ImageCacheTest extends TestCase {
        
        private const IMG_1:String = "assets/images/icons/arrow_d_666666.png";
        private const IMG_2:String = "assets/images/icons/zoom_fit_666666.png";
        private const IMG_3:String = "assets/images/icons/closed_hand.png";
        
        private const EMPTY_VS:Object = {
            global: {
                backgroundColor: "#000000"
            }
        };
        private const SIMPLE_VS:Object = {
            global: {
                backgroundColor: "#000000",
                image: IMG_2 // Should be ignored for now!
            },
            nodes: {
                opacity: 1,
                image: IMG_1,
                size: 40
            },
            edges: {
                opacity: 1,
                color: "#ff0000",
                image: IMG_3 // Should be ignored!
            }
        };
        
        private var _cache:ImageCache = ImageCache.instance;
        private var _emptyVs:VisualStyleVO;
        private var _simpleVs:VisualStyleVO;
        
        public override function setUp():void {
            _emptyVs = VisualStyleVO.fromObject(EMPTY_VS);
            _simpleVs = VisualStyleVO.fromObject(SIMPLE_VS);
        }
        
        // ========[ TESTS ]========================================================================
        
        public function testLoadImagesFromSimpleVisualStyle():void {
            // Initial state:
            assertEquals(0, _cache.size);
            assertFalse(_cache.isLoading());
            
            // Load images:
            function runTest():void {
               assertEquals(1, _cache.size);
               assertFalse(_cache.isLoading());
               
               assertTrue(_cache.contains(IMG_1));
               assertFalse(_cache.contains(IMG_2));
               assertFalse(_cache.contains(IMG_3));
               
               assertTrue(_cache.isLoaded(IMG_1));
               assertFalse(_cache.isLoaded(IMG_2));
               assertFalse(_cache.isLoaded(IMG_3));
               
               assertFalse(_cache.isBroken(IMG_1));
               assertFalse(_cache.isBroken(IMG_2));
               assertFalse(_cache.isBroken(IMG_3));
            }
            
            _cache.loadImages(_simpleVs, null, addAsync(runTest, 3000));
        }
        
        public function testDispose():void {
            function runTest():void {
                // Initial state:
                assertTrue(_cache.size > 0);
                assertFalse(_cache.isLoading());
                
                _cache.dispose();
                assertEquals(0, _cache.size);
                assertFalse(_cache.isLoading());
            };
            
            _cache.loadImages(_simpleVs, null, addAsync(runTest, 3000));
        }

    }
}