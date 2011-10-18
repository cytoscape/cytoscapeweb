package org.cytoscapeweb.view.layout.ivis.layout.cose
{
import org.as3commons.collections.framework.IIterator;

import org.cytoscapeweb.view.layout.ivis.layout.LGraphManager;
import org.cytoscapeweb.view.layout.ivis.layout.LNode;


/**
 * This class holds coarsening process specific node data and implementations
 *
 * @author Alper Karaçelik
 *
 * Copyright: i-Vis Research Group, Bilkent University, 2007 - present
 */
public class CoarseningNode extends LNode
{
// -----------------------------------------------------------------------------
// Section: Instance variables
// -----------------------------------------------------------------------------

	/**
	 * A coarsening node in G (coarsening graph) 
	 * references a CoSENode in M (CoSE graph manager)
	 */
	private var reference:CoSENode;
	
	/**
	 * node1 and node2 hold the contracted nodes
	 */
	private var node1:CoarseningNode;
	private var node2:CoarseningNode;
	/**
	 * matched flag of the coarsening node
	 */
	private var matched:Boolean;
	
	/**
	 * weight
	 */
	private var weight:int;
	
// -----------------------------------------------------------------------------
// Section: Constructors and initialization
// -----------------------------------------------------------------------------
	
	/*
	 * Constructor
	 */
	public function CoarseningNode(gm:LGraphManager = null,
		vNode:* = null/*vNode:Object = null*/)
	{
		super(gm, vNode);
		this.weight = 1;
	}

// -----------------------------------------------------------------------------
// Section: Getters and setter
// -----------------------------------------------------------------------------
	
	public function setMatched(matched:Boolean):void {
		this.matched = matched;
	}

	public function isMatched():Boolean {
		return matched;
	}

	public function setWeight(weight:int):void {
		this.weight = weight;
	}

	public function getWeight():int {
		return weight;
	}

	public function setNode1(node1:CoarseningNode):void {
		this.node1 = node1;
	}

	public function getNode1():CoarseningNode {
		return node1;
	}

	public function setNode2(node2:CoarseningNode):void {
		this.node2 = node2;
	}

	public function getNode2():CoarseningNode {
		return node2;
	}

	public function setReference(reference:CoSENode):void {
		this.reference = reference;
	}

	public function getReference():CoSENode {
		return reference;
	}

// -----------------------------------------------------------------------------
// Section: Other methods
// -----------------------------------------------------------------------------
	/**
	 * This method returns the matching of this node
	 * if this node does not have any unmacthed neighbor then returns null
	 */
	public function getMatching():CoarseningNode
	{
		var minWeighted:CoarseningNode= null;
		var minWeight:int= int.MAX_VALUE;

		var iter:IIterator = this.getNeighborsList().iterator();
		
		//for each (var v:CoarseningNode in this.getNeighborsList())
		while(iter.hasNext())
		{
			var v:CoarseningNode = iter.next() as CoarseningNode;
		
			if ((!v.isMatched()) && (v.getWeight() < minWeight))
			{
				minWeighted = v;
				minWeight = v.getWeight();
			}
		}

		return minWeighted;
	}
}
}