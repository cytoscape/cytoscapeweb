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
package org.cytoscapeweb.util {
    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.display.PixelSnapping;
    import flash.geom.Matrix;
    
    public class Images {
        
        // ========[ CONSTRUCTOR ]==================================================================
        
        /**
         * This constructor will throw an error, as this is an abstract class. 
         */
        public function Images() {
            throw new Error("This is an abstract class.");
        }

        // ========[ PUBLIC METHODS ]===============================================================

        public static function resizeBitmapToFit(bd:BitmapData, nw:Number, nh:Number):BitmapData {
            if (bd.width > 0 && bd.height > 0) {
                var w:Number = bd.width;
                var h:Number = bd.height;
                var originalRatio:Number = w/h;
                var maxRatio:Number = nw/nh;
                var scale:Number;
                
                if (originalRatio > maxRatio) { // scale by width
                    scale = nw/w;
                } else { // scale by height
                    scale = nh/h;
                }
                
                var m:Matrix = new Matrix();
                m.scale(scale, scale);
                m.translate(nw/2-(w*scale)/2, nh/2-(h*scale)/2);
                
                var bd2:BitmapData = new BitmapData(nw, nh, true, 0x000000);
                bd2.draw(bd, m, null, null, null, true);
    
                var bmp:Bitmap = new Bitmap(bd2, PixelSnapping.NEVER, true);
                
                return bmp.bitmapData;
            }
            
            return bd;
        }
    
//        private function resizeBitmap(bd:BitmapData, scale:Number):BitmapData {   
//            var matrix:Matrix = new Matrix();
//            matrix.scale(scale, scale);
//            
//            var bd2:BitmapData = new BitmapData(bd.width * scale, bd.height * scale, true, 0x000000);
//            bd2.draw(bd, matrix, null, null, null, true);
//
//            var bmp:Bitmap = new Bitmap(bd2, PixelSnapping.NEVER, true);
//            
//            return bmp.bitmapData;
//        }
    }
}