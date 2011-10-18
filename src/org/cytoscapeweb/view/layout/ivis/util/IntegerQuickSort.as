package org.cytoscapeweb.view.layout.ivis.util
{
	import org.as3commons.collections.ArrayList;

	//import java.util.List;
	
	/**
	 * This class implements a quick sort for integers.
	 *
	 * @author Ugur Dogrusoz
	 *
	 * Copyright: i-Vis Research Group, Bilkent University, 2007 - present
	 */
	public class IntegerQuickSort extends QuickSort
	{
		public function IntegerQuickSort(objectList:ArrayList/*<Object>*/)
		{
			super(objectList);
		}
	
		override public function compare(a:*, b:*):Boolean
		{
			
			var i:int = a as int;
			var j:int = b as int;
	
			return j > i;
		}
	}
}