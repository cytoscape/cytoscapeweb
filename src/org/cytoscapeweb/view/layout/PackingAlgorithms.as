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
package org.cytoscapeweb.view.layout{
	import flare.util.Arrays;
	
	import flash.geom.Rectangle;
	

    /**
     * The 2D Packing algorithms used here were converted from the C# code written by Rod Stephens.
     * (http://www.devx.com/dotnet/Article/36005)
     */
    public class PackingAlgorithms {

        // =========================================================================================
        // FILL BY STRIPES
        // =========================================================================================

        // Start the recursion.
        public static function fillByStripes(bin_width:Number, rects:Array):Array {
            // Create a shalow copy of the rectangles array:
            var best_rects:Array = rects.concat();

            // Make variables to track and record the best solution.
            var is_positioned:Array = new Array();
            for each (var o:Object in best_rects)
                is_positioned.push(false);
            
            var num_unpositioned:int = best_rects.length;

            // Fill by stripes.
            var max_y:Number = 0;
            for (var i:int = 0; i < rects.length; i++) {
                // See if this rectangle is positioned.
                if (!is_positioned[i]) {
                    // Start a new stripe.
                    num_unpositioned -= 1;
                    is_positioned[i] = true;
                    best_rects[i].x = 0;
                    best_rects[i].y = max_y;
               
                    
                    // An int inside an array, just to pass it by reference:
                    var num_unpos_arr:Array = [num_unpositioned];

                    fillBoundedArea(best_rects[i].width,
                                    bin_width, max_y,
                                    max_y + best_rects[i].height,
                                    num_unpos_arr,
                                    best_rects,
                                    is_positioned);                   

                    num_unpositioned = num_unpos_arr[0];
                    if (num_unpositioned == 0) break;
                    max_y += best_rects[i].height;
                }
            }

            // Save the best solution.
            return Arrays.copy(best_rects, rects, 0, 0, best_rects.length);
        }

        /**
         * Use rectangles to fill the given sub-area.
         * Set the following for the best solution we find:
         *       xmin, xmax, etc.    - Bounds of the rectangle we are trying to fill.
         *       num_unpositioned    - The number of rectangles not yet positioned in this solution.
         *                             Used to control the recursion.
         *       rects()             - All rectangles for the problem, some positioned and others not. 
         *                             Initially this is the partial solution we are working from.
         *                             At end, this is the best solution we could find.
         *       is_positioned()     - Indicates which rectangles are positioned in this solution.
         *       max_y               - The largest Y value for this solution.
         */
        private static function fillBoundedArea(xmin:Number, xmax:Number, ymin:Number, ymax:Number,
                                         num_unpositioned_arr:Array, 
                                         rects:Array, 
                                         is_positioned:Array):void {
            // See if every rectangle has been positioned.
            var num_unpositioned:int = num_unpositioned_arr[0] as int;
//            trace(">> num_unpositioned : " + num_unpositioned);
            if (num_unpositioned <= 0) return;

            // Save a copy of the solution so far.
            var best_num_unpositioned:int = num_unpositioned;
            var best_rects:Array = deepCloneRectangles(rects);
            var best_is_positioned:Array = is_positioned.concat();

            // Currently we have no solution for this area.
            var best_density:Number = 0;

            // Some rectangles have not been positioned.
            // Loop through the available rectangles.
            for (var i:int = 0; i < rects.length; i++) {
                // See if this rectangle is not position and will fit.
                if ((!is_positioned[i]) && (rects[i].width <= xmax - xmin) && (rects[i].height <= ymax - ymin)) {
                    // It will fit. Try it.
                    // --------------------------------------------------
                    // Divide the remaining area horizontally.
                    var test1_num_unpositioned:int = num_unpositioned - 1;
                    var test1_rects:Array = rects.concat();
                    var test1_is_positioned:Array = is_positioned.concat();
                    test1_rects[i].x = xmin;
                    test1_rects[i].y = ymin;
                    test1_is_positioned[i] = true;

                    // Fill the area on the right.
                    // --------------------------------------------------
                    var test1_num_unpos_arr:Array = [test1_num_unpositioned];
                    fillBoundedArea(xmin + rects[i].width, xmax, ymin, ymin + rects[i].height,
                                    test1_num_unpos_arr, test1_rects, test1_is_positioned);
                    
                    // Fill the area on the bottom.
                    // --------------------------------------------------
                    fillBoundedArea(xmin, xmax, ymin + rects[i].height, ymax,
                                    test1_num_unpos_arr, test1_rects, test1_is_positioned);
                    test1_num_unpositioned = test1_num_unpos_arr[0];
                    
                    // Learn about the test solution.
                    // --------------------------------------------------
                    var test1_density:Number =
                        solutionDensity(
                            xmin + rects[i].width, xmax, ymin, ymin + rects[i].height,
                            xmin, xmax, ymin + rects[i].height, ymax,
                            test1_rects, test1_is_positioned);

                    // See if this is better than the current best solution.
                    // --------------------------------------------------
                    if (test1_density >= best_density) {
                        // The test is better. Save it.
                        best_density = test1_density;
                        best_rects = test1_rects;
                        best_is_positioned = test1_is_positioned;
                        best_num_unpositioned = test1_num_unpositioned;
                    }

                    // --------------------------------------------------
                    // Divide the remaining area vertically.
                    var test2_num_unpositioned:int = num_unpositioned - 1;
                    var test2_rects:Array = rects.concat();
                    var test2_is_positioned:Array = is_positioned.concat();
                    test2_rects[i].x = xmin;
                    test2_rects[i].y = ymin;
                    test2_is_positioned[i] = true;

                    // Fill the area on the right.
                    // --------------------------------------------------
                    var test2_num_unpos_arr:Array = [test2_num_unpositioned];
                    fillBoundedArea(xmin + rects[i].width, xmax, ymin, ymax,
                                    test2_num_unpos_arr, test2_rects, test2_is_positioned);
                    
                    // Fill the area on the bottom.
                    // --------------------------------------------------
                    fillBoundedArea(xmin, xmin + rects[i].width, ymin + rects[i].height, ymax,
                                    test2_num_unpos_arr, test2_rects, test2_is_positioned);
                    test2_num_unpositioned = test2_num_unpos_arr[0];

                    // Learn about the test solution.
                    var test2_density:Number =
                        solutionDensity(
                            xmin + rects[i].width, xmax, ymin, ymax,
                            xmin, xmin + rects[i].width, ymin + rects[i].height, ymax,
                            test2_rects, test2_is_positioned);

                    // See if this is better than the current best solution.
                    if (test2_density >= best_density) {
                        // The test is better. Save it.
                        best_density = test2_density;
                        best_rects = test2_rects;
                        best_is_positioned = test2_is_positioned;
                        best_num_unpositioned = test2_num_unpositioned;
                    }
                } // End trying this rectangle.
            } // End looping through the rectangles.

            // Return the best solution we found.
//            is_positioned = best_is_positioned;
//            rects = best_rects;
            Arrays.copy(best_is_positioned, is_positioned, 0, 0, best_is_positioned.length);
            Arrays.copy(best_rects, rects, 0, 0, best_rects.length);
            num_unpositioned_arr[0] = best_num_unpositioned;
        }

        /**
         * Find the density of the rectangles in the given areas for this solution.
         */
        private static function solutionDensity(xmin1:Number, xmax1:Number, ymin1:Number, ymax1:Number,
                                         xmin2:Number, xmax2:Number, ymin2:Number, ymax2:Number,
                                         rects:Array, is_positioned:Array):Number {
            var rect1:Rectangle = new Rectangle(xmin1, ymin1, xmax1 - xmin1, ymax1 - ymin1);
            var rect2:Rectangle = new Rectangle(xmin2, ymin2, xmax2 - xmin2, ymax2 - ymin2);
            var area_covered:Number = 0;
            
            for (var i:int = 0; i < rects.length; i++) {
                var r:Rectangle = rects[i] as Rectangle;
                if (is_positioned[i] && (r.intersects(rect1) || r.intersects(rect2))) {
                    area_covered += rects[i].width * rects[i].height;
                }
            }

            var denom:Number = rect1.width * rect1.height + rect2.width * rect2.height;
            if (Math.abs(denom) < 0.001) return 0;

            return area_covered / denom;
        }        
        
        private static function deepCloneRectangles(arr:Array):Array {
            var newArr:Array = null;
            
            if (arr != null) {
                newArr = new Array();
                for each (var r:Rectangle in arr)
                    newArr.push(new Rectangle(r.x, r.y, r.width, r.height));
            }
            
            return newArr;
        }
        
        // =========================================================================================
        // FILL BY ONE COLUMN
        // =========================================================================================

        /**
        * Fill in by rows in a single column.
        * 
        * Converted from C# examples by by Rod Stephens (http://www.devx.com/dotnet/Article/36005).
        */
        public static function fillByOneColumn(bin_width:Number, rects:Array):Array {
            // Make lists of positioned and not positioned rectangles.
            var not_positioned:Array = new Array();
            var positioned:Array = new Array();
            
            for (var i:int = 0; i < rects.length; i++)
                not_positioned.push(rects[i]);

            // Arrange the rectangles.
            var x:Number = 0;
            var y:Number = 0;
            var row_hgt:Number = 0;
            
            while (not_positioned.length > 0) {
                // Find the next rectangle that will fit on this row.
                var next_rect:int = -1;
                for (i = 0; i < not_positioned.length; i++) {
                    if (x + not_positioned[i].width <= bin_width) {
                        next_rect = i;
                        break;
                    }
                }

                // If we didn't find a rectangle that fits, start a new row.
                if (next_rect < 0) {
                    y += row_hgt;
                    x = 0;
                    row_hgt = 0;
                    next_rect = 0;
                }

                // Position the selected rectangle.
                var rect:Rectangle = not_positioned[next_rect];
                rect.x = x;
                rect.y = y;
                x += rect.width;
                if (row_hgt < rect.height) row_hgt = rect.height;

                // Move the rectangle into the positioned list.
                positioned.push(rect);
                not_positioned.splice(next_rect, 1);
            }

            return positioned;
        }
    }
}