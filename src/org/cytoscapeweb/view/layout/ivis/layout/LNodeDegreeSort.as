package org.cytoscapeweb.view.layout.ivis.layout
{
//import java.util.List;

import org.as3commons.collections.ArrayList;
import org.ivis.util.QuickSort;

/**
 * This class implements sorting with respect to degrees of LNodes.
 *
 * @author Alptug Dilek
 *
 * Copyright: i-Vis Research Group, Bilkent University, 2007 - present
 */
public class LNodeDegreeSort extends QuickSort
{
	public function LNodeDegreeSort(objectList:ArrayList/*<Object>*/,
		objectArray:Array = null)
	{
		super(objectList, objectArray);
	}

	/*
	public function LNodeDegreeSort(objectArray:Array)
	{
		super(objectArray);
	}
	*/

	override public function compare(a:*, b:*/*a:Object, b:Object*/):Boolean
	{
		var node1:LNode = a as LNode;
		var node2:LNode = b as LNode;

		return (node2.getEdges().size > node1.getEdges().size);
	}
}
}