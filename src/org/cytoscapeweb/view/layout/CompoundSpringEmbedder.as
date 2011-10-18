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
package org.cytoscapeweb.view.layout
{
	import flare.vis.data.EdgeSprite;
	import flare.vis.data.NodeSprite;
	import flare.vis.operator.layout.Layout;
	
	import org.cytoscapeweb.util.GraphUtils;
	import org.cytoscapeweb.util.Groups;
	import org.cytoscapeweb.view.layout.ivis.layout.CoSEOptions;
	import org.cytoscapeweb.view.layout.ivis.layout.GeneralOptions;
	import org.cytoscapeweb.view.layout.ivis.layout.LEdge;
	import org.cytoscapeweb.view.layout.ivis.layout.LGraph;
	import org.cytoscapeweb.view.layout.ivis.layout.LGraphManager;
	import org.cytoscapeweb.view.layout.ivis.layout.LNode;
	import org.cytoscapeweb.view.layout.ivis.layout.Layout;
	import org.cytoscapeweb.view.layout.ivis.layout.LayoutConstants;
	import org.cytoscapeweb.view.layout.ivis.layout.LayoutOptionsPack;
	import org.cytoscapeweb.view.layout.ivis.layout.cose.CoSELayout;
	import org.cytoscapeweb.vis.data.CompoundNodeSprite;

	/**
	 * This layout uses a ported version of CoSE algorithm. CoSE is a part of
	 * chiLay (Chisio) project which is developed by i-Vis Research Group
	 * of Bilkent University.
	 *  
	 * Original algorithm, which is written in Java programming language, can be 
	 * found on the project webpage http://sourceforge.net/projects/chisio/
	 */
	public class CompoundSpringEmbedder extends flare.vis.operator.layout.Layout
	{
		protected var _ivisLayout:org.cytoscapeweb.view.layout.ivis.layout.Layout;
		protected var _cwToLayout:Object;
		protected var _layoutToCw:Object;
		
		public function CompoundSpringEmbedder()
		{
			this._cwToLayout = new Object();
			this._layoutToCw = new Object();
			
			this._ivisLayout = new CoSELayout();
		}
		
		/**
		 * Sets the layout options provided by the options object. 
		 * 
		 * @param options	object that contains layout options.
		 */
		public function setOptions(options:Object):void
		{
			// set layout parameters
			
			var genOpts:GeneralOptions =
				LayoutOptionsPack.getInstance().getGeneral();
			
			var coseOpts:CoSEOptions =
				LayoutOptionsPack.getInstance().getCoSE();
			
			var quality:int;
			
			if (options.layoutQuality == "proof")
			{
				quality = LayoutConstants.PROOF_QUALITY;
			}
			else if (options.layoutQuality == "draft")
			{
				quality = LayoutConstants.DRAFT_QUALITY;
			}
			else
			{
				quality = LayoutConstants.DEFAULT_QUALITY;
			}
			
			genOpts.setLayoutQuality(quality);
			genOpts.setIncremental(options.incremental);
			genOpts.setUniformLeafNodeSizes(options.uniformLeafNodeSizes);
			
			coseOpts.setRepulsionStrength(-1 * options.gravitation);
			coseOpts.setSpringStrength(options.tension);			
			coseOpts.setSmartRepulsionRangeCalc(options.smartDistance);
			coseOpts.setGravityStrength(options.centralGravitation);
			coseOpts.setGravityRange(options.centralGravityDistance);
			coseOpts.setCompoundGravityStrength(options.compoundCentralGravitation);
			coseOpts.setCompoundGravityRange(options.compoundCentralGravityDistance);
			coseOpts.setIdealEdgeLength(options.restLength);
			coseOpts.setSmartEdgeLengthCalc(options.smartRestLength);
			coseOpts.setMultiLevelScaling(options.multiLevelScaling);
			
			/*
			trace ("layoutQuality: " + options.layoutQuality);
			trace ("incremental: " + options.incremental);
			trace ("uniformLeafNodeSizes: " + options.uniformLeafNodeSizes);
			
			trace ("tension: " + options.tension);
			trace ("repulsion: " + options.repulsion);
			trace ("smartDistance: " + options.smartDistance);
			trace ("gravitation: " + options.gravitation);
			trace ("gravityDistance: " + options.gravityDistance);
			trace ("compoundGravitation: " + options.compoundGravitation);
			trace ("compoundGravityDistance: " + options.compoundGravityDistance);
			trace ("restLength: " + options.restLength);
			trace ("smartRestLength: " + options.smartRestLength);
			trace ("multiLevelScaling: " + options.multiLevelScaling);
			*/
		}
		
		override protected function layout():void
		{
			// create topology for chiLay
			this.createTopology();
			
			// DEBUG: print topology
			this._ivisLayout.getGraphManager().printTopology();
			
			// DEBUG: print initial values
			//visualization.data.nodes.visit(this.updateNode);
			
			// run layout
			this._ivisLayout.runLayout();
			
			// update sprites
			//visualization.data.nodes.visit(this.updateNode);
			for each (var ns:NodeSprite in visualization.data.nodes)
			{
				updateNode(ns);
			}
		}
		
		/**
		 * Updates the given node sprite by copying corresponding LNode's x and
		 * y coordinates.
		 * 
		 * @param ns	node sprite to be updated
		 */
		protected function updateNode(ns:NodeSprite):void
		{	
			var node:LNode = this._cwToLayout[ns];
			
			if (node != null)
			{
				ns.x = node.getCenterX();
				ns.y = node.getCenterY();
			}
		}
		
		/**
		 * Creates l-level topology of the graph from the given compound model.
		 */
		protected function createTopology():void
		{	
			// create initial topology: a graph manager associated with the layout,
			// containing an empty root graph as its only graph
			
			var gm:LGraphManager = this._ivisLayout.getGraphManager();
			var lroot:LGraph = gm.addRoot();
			//lroot.vGraphObject = this.root;
			lroot.label = "root"; // for debugging purposes
			
			// for each CompoundNodeSprite at the root level (i.e. parentless)
			// in the data set, create an LNode
			
			for each (var ns:NodeSprite in visualization.data.nodes)
			{
				var cns:CompoundNodeSprite;
				
				if (ns is CompoundNodeSprite)
				{
					cns = ns as CompoundNodeSprite;
					
					// ignore filtered-out nodes
					if (cns.data.parent == null && !GraphUtils.isFilteredOut(cns))
					{
						this.createNode(cns, null, this._ivisLayout);
					}
				}
			}
			
			// for each EdgeSprite in the data set, create an LEdge
			
			for each (var es:EdgeSprite in
				visualization.data.group(Groups.REGULAR_EDGES))
			{
				// ignore filtered-out edges
				if (!GraphUtils.isFilteredOut(es))
				{
					this.createEdge(es, this._ivisLayout);
				}
			}
			
			gm.updateBounds();
		}
		
		/**
		 * Creates an LNode for the given NodeModel object.
		 * 
		 * @param node		NodeSprite representing the node
		 * @param parent	parent node of the given node
		 * @param layout	layout of the graph
		 */
		protected function createNode(node:CompoundNodeSprite,
			parent:CompoundNodeSprite,
			layout:org.cytoscapeweb.view.layout.ivis.layout.Layout):void
		{
			var lNode:LNode = layout.newNode(null/*node*/);
			
			// for debugging purposes
			lNode.label = node.data.id;
			//trace("vNode [" + node.data.id + "]" + "x: " + node.x +
			//	" y: " + node.y +
			//	" w: " + node.width +
			//	" h: " + node.height);
			
			var rootGraph:LGraph = layout.getGraphManager().getRoot(); 
			
			this._cwToLayout[node] = lNode;
			this._layoutToCw[lNode] = node;
			
			// if the node has a parent add the l-node as a child of the parent
			// l-node. Otherwise add the node to the root graph.
			
			if (parent != null)
			{
				var parentLNode:LNode = this._cwToLayout[parent] as LNode;
				//function parentLNode.getChild():assert != null : 
				//"Parent node doesn't have child graph.";
				parentLNode.getChild().addNode(lNode);
			}
			else
			{
				rootGraph.addNode(lNode);
			}
			
			// copy geometry
			
			lNode.setLocation(node.x, node.y);
			
			// TODO copy cluster ID (zero means unclustered)
			
			/*
			var clusterID:int = node.getClusterID();
			
			if (clusterID != 0)
			{
				//assert clusterID > 0;
				lNode.setClusterID(Integer.toString(clusterID));
			}
			*/
			
			// if node is a compound, recursively create child nodes
			
			if (node.isInitialized())
			{
				// add new LGraph to the graph manager for the compound node
				layout.getGraphManager().addGraph(layout.newGraph(null), lNode);
				
				// for each NodeModel in the node set create an LNode
				for each (var cns:CompoundNodeSprite in node.getNodes())
				{
					if (!GraphUtils.isFilteredOut(cns))
					{
						this.createNode(cns,
							node,
							layout);
					}
				}
				
				lNode.updateBounds();
			}
			else
			{
				lNode.setWidth(node.width);
				lNode.setHeight(node.height);
			}
		}
		
		/**
		 * Creates an LEdge for the given EdgeSprite.
		 * 
		 * @param edge		source edge 
		 * @param layout	layout of the graph
		 */
		protected function createEdge(edge:EdgeSprite,
			layout:org.cytoscapeweb.view.layout.ivis.layout.Layout):void
		{
			var lEdge:LEdge = layout.newEdge(null/*edge*/);
			lEdge.label = edge.data.id; // for debugging purposes
			
			var sourceLNode:LNode = this._cwToLayout[edge.source] as LNode;
			var targetLNode:LNode = this._cwToLayout[edge.target] as LNode;
			
			layout.getGraphManager().addEdge(lEdge, sourceLNode, targetLNode);
			
			//var bendPoints:List= edge.getBendpoints();
		}
	}
}