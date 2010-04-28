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
package org.cytoscapeweb.util.methods {

    /**
    * Invoke the passed function for each list element or just call the function a number of times.
    * The advantage of this method over regular "for" and "while" loops is that it ignores the
    * timeout exceptions that occur when the loop lasts more than 60 seconds.
    * @param listOrLength an array-like object or just the number of times to call the function.
    * @param fn the callback function to be called each time - e.g. function(i:uint, o:Object):Boolean { }.
    *           If the function return true, the iteration is ended with an early exit.
    * @param mutable if true, indicates that the number of elements in the list may change between each iteration.
    */
    public function $each(listOrLength:*, fn:Function, mutable:Boolean=false):void {
        if (listOrLength != null) {
            var list:*;
            var length:uint = 0;
            
            if (listOrLength is Number || listOrLength is int || listOrLength is uint) {
                length = uint(listOrLength);
            } else {
                list = listOrLength;
                length = list.length;
            }

            var finished:Boolean = false;
            var i:uint = 0;
  
            while (!finished) {
                try {
                    if (list != null)
                        while (i < length) {
                            if (fn(i, list[i])) break;
                            i++;
                            if (mutable) length = list.length;
                        }
                    else {
                        while (i < length) {
                            if (fn(i, null)) break;
                            i++;
                        }
                    }
                    finished = true;
                } catch (err:Error) {
                    if (err.errorID === 1502 || err.errorID === 1503)
                        trace("[ $each ] Timeout at iteration " + i + ": " + err.getStackTrace());
                    else
                        throw err;
                }
            }
        }
    }
}