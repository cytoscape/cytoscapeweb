package org.cytoscapeweb.view.layout.ivis.layout
{
/**
 * This class implements a base class for l-level graph objects (nodes, edges,
 * and graphs).
 *
 * @author: Ugur Dogrusoz
 *
 * Copyright: i-Vis Research Group, Bilkent University, 2007 - present
 */
public class LGraphObject
{
// -----------------------------------------------------------------------------
// Section: Instance variables
// -----------------------------------------------------------------------------
	/**
	 * Associated view object
	 */
	public var vGraphObject:*;//vGraphObject:Object;

	/**
	 * Label
	 */
	public var label:String;
	
// -----------------------------------------------------------------------------
// Section: Constructors and initialization
// -----------------------------------------------------------------------------
	public function LGraphObject(vGraphObject:*/*vGraphObject:Object*/)
	{
		this.vGraphObject = vGraphObject;
	}
}
}