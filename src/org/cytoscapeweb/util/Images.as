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
    import flash.geom.Rectangle;
    
    public class Images {
        
        // ========[ CONSTRUCTOR ]==================================================================
        
        /**
         * This constructor will throw an error, as this is an abstract class. 
         */
        public function Images() {
            throw new Error("This is an abstract class.");
        }

        // ========[ PUBLIC METHODS ]===============================================================

        public static function resizeToFill(bd:BitmapData, rect:Rectangle):BitmapData {
            if (bd.width > 0 && bd.height > 0 && rect.height > 0 && rect.width > 0) {
            	var rw:Number = rect.width;
            	var rh:Number = rect.height;
                var w:Number = bd.width;
                var h:Number = bd.height;
                var originalRatio:Number = w/h;
                var maxRatio:Number = rw/rh;
                var scale:Number;
                
                if (originalRatio < maxRatio) { // scale by width
                    scale = rw/w;
                } else { // scale by height
                    scale = rh/h;
                }
                
                bd = resize(bd, scale, rw/2-(w*scale)/2, rh/2-(h*scale)/2);
            }
            
            return bd;
        }
    
        public static function resize(bd:BitmapData, scale:Number, dx:Number=0, dy:Number=0):BitmapData {   
            var matrix:Matrix = new Matrix();
            matrix.scale(scale, scale);
            matrix.translate(dx, dy);
            
            var bd2:BitmapData = new BitmapData(bd.width * scale, bd.height * scale, true, 0x000000);
            bd2.draw(bd, matrix, null, null, null, true);

            var bmp:Bitmap = new Bitmap(bd2, PixelSnapping.NEVER, true);
            
            return bmp.bitmapData;
        }
    }
}