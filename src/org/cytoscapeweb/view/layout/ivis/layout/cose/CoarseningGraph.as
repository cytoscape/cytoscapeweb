package org.cytoscapeweb.view.layout.ivis.layout.cose
{
import org.as3commons.collections.framework.IIterator;

import org.cytoscapeweb.view.layout.ivis.layout.LGraph;
import org.cytoscapeweb.view.layout.ivis.layout.LNode;
import org.cytoscapeweb.view.layout.ivis.layout.Layout;


/**
 * This class holds coarsening process specific graph data and implementations
 *
 * @author: Alper Karaçelik
 *
 * Copyright: i-Vis Research Group, Bilkent University, 2007 - present
 */
public class CoarseningGraph extends LGraph
{
// -----------------------------------------------------------------------------
// Section: Instance variables
// -----------------------------------------------------------------------------
	/**
	 * during the coarsening process, 
	 * CoSE nodes of coarser graph is created by the help of layout instance 
	 */
	private var layout:Layout;
	
// -----------------------------------------------------------------------------
// Section: Constructors and initialization
// -----------------------------------------------------------------------------
	/**
	 * Constructor
	 */
	public function CoarseningGraph(layout:Layout,
		parent:LNode = null,
		vGraph:Object = null)
	{
		super(parent, null, vGraph, layout);
		
		this.layout = layout;
	}	

// -----------------------------------------------------------------------------
// Section: Coarsening
// -----------------------------------------------------------------------------
	/**
	 * This method coarsens Gi to Gi+1
	 */
	public function coarsen():void
	{
		this.unmatchAll();
		
		var v:CoarseningNode, u:CoarseningNode;
		
		if (this.getNodes().size > 0)
		{
			// match each node with the one of the unmatched neighbors has minimum weight
			// if there is no unmatched neighbor, then match current node with itself
			while (!(this.getNodes().itemAt(0) as CoarseningNode).isMatched())
			{
				// get an unmatched node (v) and (if exists) matching of it (u).
				v = this.getNodes().itemAt(0) as CoarseningNode;
				u = v.getMatching();
				
				// node t is constructed by contracting u and v
				contract( v, u );
			}
			
			var iter:IIterator = this.getNodes().iterator();
			
			// construct pred1, pred2, next fields of referenced node from CoSEGraph
			//for each (var y:CoarseningNode in this.getNodes())
			while (iter.hasNext())
			{
				var y:CoarseningNode = iter.next() as CoarseningNode;
				
				// new CoSE node will be in Mi+1
				var z:CoSENode = this.layout.newNode(null) as CoSENode;
				
				z.setPred1(y.getNode1().getReference());
				y.getNode1().getReference().setNext(z);
				
				// if current node is not matched with itself
				if ( y.getNode2() != null )
				{
					z.setPred2(y.getNode2().getReference());
					y.getNode2().getReference().setNext(z);
				}
				
				y.setReference(z);
			}
		}
	}
	
	/**
	 * This method unflags all nodes as unmatched
	 * it should be called before each coarsening process
	 */
	private function unmatchAll():void
	{
		var iter:IIterator = this.getNodes().iterator();
		
		//for each (var v:CoarseningNode in this.getNodes())
		while (iter.hasNext())
		{
			var v:CoarseningNode = iter.next() as CoarseningNode;
		
			v.setMatched(false);
		}
	}
	
	/**
	 * This method contracts v and u
	 */
	private function contract( v:CoarseningNode, u:CoarseningNode):void
	{
		// t will be constructed by contracting v and u		
		var t:CoarseningNode= new CoarseningNode();
		this.addNode(t);
		
		t.setNode1( v );
		
		var x:CoarseningNode;
		var iter:IIterator;
		iter = v.getNeighborsList().iterator();
		
		//for each (x in v.getNeighborsList())
		while(iter.hasNext())
		{
			x = iter.next() as CoarseningNode;
			
			if (x != t)
			{
				this.addEdge( new CoarseningEdge(), t, x );
			}
		}
		
		t.setWeight( v.getWeight() );
		
		//remove contracted node from the graph
		this.removeNode(v);
		
		// if v has an unmatched neighbor, then u is not null and t.node2 = u
		// otherwise, leave t.node2 as null
		if ( u != null )
		{
			t.setNode2( u );
			
			iter = u.getNeighborsList().iterator();
			
			//for each (x in u.getNeighborsList())
			while(iter.hasNext())
			{
				x = iter.next() as CoarseningNode;
			
				if (x != t)
				{
					addEdge( new CoarseningEdge(), t, x );
				}
			}
			
			t.setWeight( t.getWeight() + u.getWeight() );
			
			//remove contracted node from the graph
			this.removeNode(u);
		}
		
		// t should be flagged as matched
		t.setMatched( true );
	}
	
// -----------------------------------------------------------------------------
// Section: Instance variables
// -----------------------------------------------------------------------------
	public function getLayout():Layout {
		return layout;
	}

	public function setLayout(layout:Layout):void {
		this.layout = layout;
	}
}
}