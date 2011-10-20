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
package org.cytoscapeweb.vis.data {
	import flare.vis.data.NodeSprite;
	
	import flash.geom.Rectangle;
	
	import org.cytoscapeweb.model.error.CWError;
	import org.cytoscapeweb.util.NodeShapes;
	import org.cytoscapeweb.util.Nodes;

	/**
	 * This class represents a Compound Node with its child nodes, bounds and
	 * padding values. A compound node can contain any other node (both simple
	 * node and compound node) as its child.
	 * 
	 * @author Selcuk Onur Sumer
	 */ 
	public class CompoundNodeSprite extends NodeSprite {
	    
		// ==================== [ PRIVATE PROPERTIES ] =========================
		
		/**
		 * Contains child nodes of this compound node as a map of NodeSprite
		 * objects.
		 */
		private var _nodesMap:Object;
		
		private var _nodesCount:int;
		private var _bounds:Rectangle;
		private var _paddingLeft:Number;
		private var _paddingRight:Number;
		private var _paddingTop:Number;
		private var _paddingBottom:Number;
		
		// ===================== [ PUBLIC PROPERTIES ] =========================

        public function get nodesCount():int {
            return _nodesCount;
        }

		/**
		 * Bounds enclosing children of the compound node.
		 */
		public function get bounds():Rectangle {
			return _bounds;
		}
		
		public function set bounds(rect:Rectangle):void {
			_bounds = rect;
		}
		
		/**
		 * Width of the right padding of the compound node
		 */
		public function get paddingRight():Number {
			return _paddingRight;
		}

		public function set paddingRight(value:Number):void {
			_paddingRight = value;
		}

		/**
		 * Height of the top padding of the compound node
		 */
		public function get paddingTop():Number {
			return _paddingTop;
		}

		public function set paddingTop(value:Number):void {
			_paddingTop = value;
		}

		/**
		 * Height of the bottom padding of the compound node
		 */
		public function get paddingBottom():Number {
			return _paddingBottom;
		}

		public function set paddingBottom(value:Number):void {
			_paddingBottom = value;
		}

		/**
		 * Width of the left padding of the compound node
		 */
		public function get paddingLeft():Number {
			return _paddingLeft;
		}

		public function set paddingLeft(value:Number):void {
			_paddingLeft = value;
		}
		
		// ========================= [ CONSTRUCTOR ] ===========================
		
		public function CompoundNodeSprite() {
			this._nodesMap = null;
			this._bounds = null;
		}
		
		// ====================== [ PUBLIC FUNCTIONS ] =========================
		
		/**
		 * Initializes the map of children for this compound node.
		 */
		public function initialize():void {
			this._nodesMap = new Object();
		}
		
		public function isInitialized():Boolean {
			return this._nodesMap != null;
		}
		
		public function allChildrenInvisible():Boolean {
			var invisible:Boolean = true; 
			
			for each (var ns:CompoundNodeSprite in this._nodesMap) {
				if (Nodes.visible(ns)) {
					invisible = false;
					break;
				}
			}
			
			return invisible;
		}
		
		/**
		 * Adds the given node sprite to the child map of the compound node.
		 * This function assumes that the given node sprite has an id in its data field.
		 * @param ns	child node sprite to be added
		 */
		public function addNode(ns:NodeSprite):void {
		    var descendent:CompoundNodeSprite = ns as CompoundNodeSprite;
		    var stack:Array = [descendent];
		    var id:String = ns.data.id;
		    
		    // check for circular dependencies:
		    do {
                descendent = stack.pop();
                
                if (descendent.data.id === this.data.parent) {
                    throw new CWError("Cannot add child node '"+ns.data.id+"' to node '" + this.data.id + 
                                      "', because it would create a circular dependency.");
                }
                
                for each (descendent in descendent.getNodes()) {
                    stack.push(descendent);
                }
			} while (stack.length > 0);
		    
		    if (!isInitialized()) initialize();
		    
			// add the node to the child node list of this node
			this._nodesMap[ns.data.id] = ns;
			// set the parent id of the added node
			ns.data.parent = this.data.id;
			this._nodesCount++;
			
			this.dirty();
		}
		
		/**
		 * Removes the given node sprite from the child list of the compound node.
		 * @param ns	child node sprite to be removed
		 */ 
		public function removeNode(ns:NodeSprite):void {
			var parentId:String = ns.data.parent;
			
			// check if given node is a child of this compound
			if (this._nodesMap != null && parentId == this.data.id) {
				// reset the parent id of the removed node
				delete ns.data.parent;
				// remove the node from the list of child nodes 
				delete this._nodesMap[ns.data.id];
				this._nodesCount--;
				
				if (this._nodesCount === 0) { // not a compound node anymore
				    this._nodesMap = null;
				    this.resetBounds();
				}
				
				this.dirty();
			}
		}
		
		/**
		 * Returns (one-level) child nodes of this compound node. If the map
		 * of children is not initialized, then returns an empty array.
		 */
		public function getNodes():Array {
			var nodeList:Array = new Array();
			
			if (this._nodesMap != null) {
				for each (var ns:CompoundNodeSprite in this._nodesMap) {
					nodeList.push(ns);
				}
			}
			
			return nodeList;
		}
		
		public function updateBounds(bounds:Rectangle):void {
		    var shapePaddingX:Number = 0;
		    var shapePaddingY:Number = 0;
		    
			// extend bounds by adding padding width & height
			bounds.x -= this.paddingLeft;
			bounds.y -= this.paddingTop;
			bounds.height += this.paddingTop + this.paddingBottom;
			bounds.width += this.paddingLeft + this.paddingRight;
			
			switch (shape) {
                case NodeShapes.ROUND_RECTANGLE:
                    shapePaddingX = NodeShapes.getRoundRectCornerRadius(bounds.width, bounds.height);
                    shapePaddingY = (shapePaddingX /= 2);
                    break;
                case NodeShapes.ELLIPSE:
                    // circumscribe the bounds rectangle
                    var newW:Number = (bounds.width / Math.sqrt(2)) * 2;
                    var newH:Number = (bounds.height / Math.sqrt(2)) * 2;
                    shapePaddingX = (newW - bounds.width) / 2;
                    shapePaddingY = (newH - bounds.height) / 2;
                    break;
            }
            
            if (shapePaddingX > 0 || shapePaddingY > 0) {
                // Just to preveet the child nodes from being rendered outise the parent when close
                // to the corners of a round rectangle, for example
                bounds.x -= shapePaddingX;
                bounds.y -= shapePaddingY;
                bounds.width += shapePaddingX * 2;
                bounds.height += shapePaddingY * 2;
            }
            
            // set bounds
            _bounds = bounds;
            
            // also update x & y coordinates of the compound node by using the new bounds
            this.x = bounds.x + (bounds.width / 2);
            this.y = bounds.y + (bounds.height / 2);
		}
		
		// ====================== [ PRIVATE FUNCTIONS ] ========================
		
		private function resetBounds():void {
            _bounds = null;
        }
	}
}