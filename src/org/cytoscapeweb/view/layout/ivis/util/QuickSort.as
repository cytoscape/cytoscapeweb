package org.cytoscapeweb.view.layout.ivis.util
{
	import flash.errors.IllegalOperationError;
	
	import org.as3commons.collections.ArrayList;

//import java.util.List;

/**
 * This class implements a generic quick sort. To use it, simply extend this
 * class and provide a comparison method.
 *
 * @author Alptug Dilek
 *
 * Copyright: i-Vis Research Group, Bilkent University, 2007 - present
 */
public /*abstract*/ class QuickSort
{
	// ArrayList required because of the replaceAt operation
	private var objectList:ArrayList/*<Object>*/;
	private var objectArray:Array;
	internal var fromList:Boolean;

	public function QuickSort(objectList:ArrayList/*<Object>*/,
		objectArray:Array = null)
	{
		if (objectArray == null)
		{
			this.objectList = objectList;
			this.fromList = true;
		}
		else
		{
			this.objectArray = objectArray;
			this.fromList = false;
		}
	}

	/*
	public function QuickSort(objectArray:Array)
	{
		this.objectArray = objectArray;
		this.fromList = false;
	}
	*/

	public function quicksort():void
	{
		var endIndex:int;

		if (fromList)
		{
			endIndex = objectList.size - 1;
		}
		else
		{
			endIndex = objectArray.length - 1;
		}

		// Prevent empty lists or arrays.
		if (endIndex >= 0)
		{
			qsort(0, endIndex);
		}
	}

	public function qsort(lo:int, hi:int):void
	{
	//  lo is the lower index, hi is the upper index
	//  of the region of array a that is to be sorted
		var i:int = lo;
		var j:int = hi;
		var temp:*;
		var middleIndex:int = (lo+hi)/2;
		var middle:* = getObjectAt(middleIndex);

		//  partition
		do
		{
			while (compare(getObjectAt(i), middle))
				i++;
			
			while (compare(middle, getObjectAt(j)))
				j--;

			if (i<=j)
			{
				temp = getObjectAt(i);
				setObjectAt(i, getObjectAt(j));
				setObjectAt(j, temp);
				i++;
				j--;
			}
			
		} while (i<=j);

		//  recursion
		if (lo<j)
			qsort(lo, j);
		if (i<hi)
			qsort(i, hi);
	}

	private function getObjectAt(i:int):*
	{
		if (fromList)
		{
			return objectList.itemAt(i);
		}
		else
		{
			return objectArray[i];
		}
	}

	private function setObjectAt(i:int, o:*):void
	{
		if (fromList)
		{
			objectList.replaceAt(i, o);
		}
		else
		{
			objectArray[i] = o;
		}
	}

	// must return true if b is greater than a in terms of comparison criteria
	public /*abstract*/ function compare(a:*, b:*):Boolean
	{
		throw new IllegalOperationError("abstract function must be overriden");
	}
}
}