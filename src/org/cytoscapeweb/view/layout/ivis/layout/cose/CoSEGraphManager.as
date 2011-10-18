package org.cytoscapeweb.view.layout.ivis.layout.cose
{
/*
import java.util.ArrayList;
import java.util.HashMap;
*/
import org.as3commons.collections.ArrayList;
import org.as3commons.collections.Map;
import org.as3commons.collections.framework.IIterator;
import org.cytoscapeweb.view.layout.ivis.layout.LEdge;
import org.cytoscapeweb.view.layout.ivis.layout.LGraphManager;
import org.cytoscapeweb.view.layout.ivis.layout.LNode;
import org.cytoscapeweb.view.layout.ivis.layout.Layout;


/**
 * This class implements a graph-manager for CoSE layout specific data and
 * functionality.
 *
 * @author Alper Karaçelik
 *
 * Copyright: i-Vis Research Group, Bilkent University, 2007 - present
 */
public class CoSEGraphManager extends LGraphManager
{
// -----------------------------------------------------------------------------
// Section: Constructors and initialization
// -----------------------------------------------------------------------------
	public function CoSEGraphManager(layout:Layout)
	{
		super(layout);
	}
// -----------------------------------------------------------------------------
// Section: Coarsening
// -----------------------------------------------------------------------------
	/**
	 * This method returns a list of CoSEGraphManager. 
	 * Returned list holds graphs finer to coarser (M0 to Mk)
	 * Additionally, this method is only called by M0.
	 */
	public function coarsenGraph():ArrayList/*<CoSEGraphManager>*/
	{
		// MList holds graph managers from M0 to Mk
		var MList:ArrayList/*<CoSEGraphManager>*/  = new ArrayList/*<CoSEGraphManager>*/();
		var prevNodeCount:int;
		var currNodeCount:int;
		
		// "this" graph manager holds the finest (input) graph
		MList.add(this);
		
		// coarsening graph G holds only the leaf nodes and the edges between them 
		// which are considered for coarsening process
		var G:CoarseningGraph= new CoarseningGraph(this.getLayout());
		
		// construct G0
		convertToCoarseningGraph(this.getRoot() as CoSEGraph, G);
		currNodeCount = G.getNodes().size;

		var lastM:CoSEGraphManager, newM:CoSEGraphManager;
		// if two graphs Gi and Gi+1 have the same order, 
		// then Gi = Gi+1 is the coarsest graph (Gk), so stop coarsening process
		do {
			prevNodeCount = currNodeCount;

			// coarsen Gi
			G.coarsen();

			// get current coarsest graph lastM = Mi and construct newM = Mi+1
			lastM = MList.itemAt(MList.size - 1) as CoSEGraphManager;
			newM = coarsen(lastM);
			
			MList.add(newM);
			currNodeCount = G.getNodes().size;

		} while ((prevNodeCount != currNodeCount) && (currNodeCount > 1));

		// change currently being used graph manager
		this.getLayout().setGraphManager(this);
		
		MList.removeAt( MList.size - 1);
		return MList;
	}
	
	/**
	 * This method converts given CoSEGraph to CoarseningGraph G0
	 * G0 consists of leaf nodes of CoSEGraph and edges between them
	 */
	private function convertToCoarseningGraph(coseG:CoSEGraph, G:CoarseningGraph):void
	{
		// we need a mapping between nodes in M0 and G0, for constructing the edges of G0
		var map:Map = new Map();

		var iter:IIterator;
		iter = coseG.getNodes().iterator();
		
		// construct nodes of G0
		//for each (var v:CoSENode in coseG.getNodes())
		while (iter.hasNext())
		{
			var v:CoSENode = iter.next() as CoSENode;
			// if current node is compound, 
			// then make a recursive call with child graph of current compound node 
			if (v.getChild() != null)
			{
				convertToCoarseningGraph(v.getChild() as CoSEGraph, G);
			}
			// otherwise current node is a leaf, and should be in the G0
			else
			{
				// v is a leaf node in CoSE graph, and is referenced by u in G0
				var u:CoarseningNode= new CoarseningNode();
				u.setReference(v);
				
				// construct a mapping between v (from CoSE graph) and u (from coarsening graph)
				map.add(v, u);
				
				G.addNode( u );
			}
		}

		iter = coseG.getEdges().iterator();
			
		// construct edges of G0
		//for each (var e:LEdge in coseG.getEdges())
		while (iter.hasNext())
		{
			var e:LEdge = iter.next() as LEdge;
			
			// if neither source nor target of e is a compound node
			// then, e is an edge between two leaf nodes
			if ((e.getSource().getChild() == null) && (e.getTarget().getChild() == null))
			{
				G.addEdge(new CoarseningEdge(),
					map.itemFor(e.getSource()) as LNode,
					map.itemFor(e.getTarget()) as LNode);
			}
		}
	}

	/**
	 * This method gets Mi (lastM) and coarsens to Mi+1
	 * Mi+1 is returned.
	 */
	private function coarsen(lastM:CoSEGraphManager):CoSEGraphManager
	{
		// create Mi+1 and root graph of it
		var newM:CoSEGraphManager= new CoSEGraphManager(lastM.getLayout());
		
		// change currently being used graph manager
		newM.getLayout().setGraphManager(newM);
		newM.addRoot();
		
		newM.getRoot().vGraphObject = lastM.getRoot().vGraphObject;

		// construct nodes of the coarser graph Mi+1
		this.coarsenNodes(lastM.getRoot() as CoSEGraph,
			newM.getRoot() as CoSEGraph);

		// change currently being used graph manager
		lastM.getLayout().setGraphManager(lastM);
		
		// add edges to the coarser graph Mi+1
		this.addEdges(lastM, newM);

		return newM;
	}

	/**
	 * This method coarsens nodes of Mi and creates nodes of the coarser graph Mi+1
	 * g: Mi, coarserG: Mi+1
	 */
	private function coarsenNodes(g:CoSEGraph, coarserG:CoSEGraph):void
	{
		var iter:IIterator = g.getNodes().iterator();
		
		//for each (var v:CoSENode in g.getNodes())
		while (iter.hasNext())
		{
			var v:CoSENode = iter.next() as CoSENode;
			
			// if v is compound
			// then, create the compound node v.next with an empty child graph
			// and, make a recursive call with v.child (Mi) and v.next.child (Mi+1)
			if (v.getChild() != null)
			{
				v.setNext(coarserG.getGraphManager().getLayout().newNode(null) as CoSENode);
				coarserG.getGraphManager().addGraph(coarserG.getGraphManager().getLayout().newGraph(null), 
					v.getNext());
				v.getNext().setPred1(v);
				coarserG.addNode(v.getNext());
				
				//v.getNext().getChild().vGraphObject = v.getChild().vGraphObject;
				
				coarsenNodes (v.getChild() as CoSEGraph, v.getNext().getChild() as CoSEGraph);
			}
			else
			{
				// v.next can be referenced by two nodes, so first check if it is processed before
				if (!v.getNext().isProcessed())
				{
					coarserG.addNode( v.getNext() );
					v.getNext().setProcessed(true);
				}
			}
			
			//v.getNext().vGraphObject = v.vGraphObject;
			
			// set location
			v.getNext().setLocation(v.getLocation().x, v.getLocation().y);
			v.getNext().setHeight(v.getHeight());
			v.getNext().setWidth(v.getWidth());
		}	
	}

	/**
	 * This method adds edges to the coarser graph.
	 * It should be called after coarsenNodes method is executed
	 * lastM: Mi, newM: Mi+1
	 */
	private function addEdges(lastM:CoSEGraphManager, newM:CoSEGraphManager):void
	{
		for each (var e:LEdge in lastM.getAllEdges())
		{
			// if e is an inter-graph edge or source or target of e is compound 
			// then, e has not contracted during coarsening process. Add e to the coarser graph.			
			if ( (e.isInterGraph()) || 
				(e.getSource().getChild() != null) || 
				(e.getTarget().getChild() != null) )
			{
				// check if e is not added before
				if ( ! (e.getSource() as CoSENode).getNext().getNeighborsList().
					has((e.getTarget() as CoSENode).getNext()) )
				{
					newM.addEdge(newM.getLayout().newEdge(null), 
						(e.getSource() as CoSENode).getNext(), 
						(e.getTarget() as CoSENode).getNext());
				}
			}

			// otherwise, if e is not contracted during coarsening process
			// then, add it to the  coarser graph
			else
			{
				if ((e.getSource() as CoSENode).getNext() !=
					(e.getTarget() as CoSENode).getNext())
				{
					// check if e is not added before
					if ( ! (e.getSource() as CoSENode).getNext().getNeighborsList().
						has((e.getTarget() as CoSENode).getNext()) )
					{
						newM.addEdge(newM.getLayout().newEdge(null), 
							(e.getSource() as CoSENode).getNext(), 
							(e.getTarget() as CoSENode).getNext());
					}
				}
			}
		}
	}

	
}
}