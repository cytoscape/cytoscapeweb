package org.cytoscapeweb.view.layout.ivis.util
{
/*
import java.util.List;
import java.util.Map;
*/
import org.as3commons.collections.ArrayList;
import org.as3commons.collections.Map;
import org.ivis.util.QuickSort;

/**
 * This class is used for sorting an Object list or array according to a mapped
 * index for each Object.
 * 
 * @author Esat Belviranli
 *
 * Copyright: i-Vis Research Group, Bilkent University, 2007 - present
 */
public class IndexedObjectSort extends QuickSort
{
	/**
	 * Holds a mapping between an Object and index on which the sorting will be 
	 * based.
	 */
	private var indexMapping:Map/*<Object, Double>*/;
	
	/**
	 * Constructor 
	 */
	public function IndexedObjectSort(objectList:ArrayList/*<Object>*/,
		indexMapping:Map/*<Object, Double>*/,
		objectArray:Array = null)
	{
		super(objectList, objectArray);
		
		this.indexMapping = indexMapping;
	}
	
	/**
	 * Constructor 
	 */
	
//	public function IndexedObjectSort(objectArray:Array, 
//		indexMapping:Map/*<Object, Double>*/)
//	{
//		super(objectArray);
//		
//		this.indexMapping = indexMapping;
//	}
	

	/**
	 * This method is required by QuickSort. In this case, comparison is based
	 * on indexes given by the mapping above.
	 */
	override public function compare(a:*, b:*):Boolean
	{
	//	assert indexMapping.get(b) != null && indexMapping.get(a) != null;
		return indexMapping.itemFor(b) as Number > 
			indexMapping.itemFor(a) as Number;
	}
}
}