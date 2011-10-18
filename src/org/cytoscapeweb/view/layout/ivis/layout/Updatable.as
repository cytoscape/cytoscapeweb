package org.cytoscapeweb.view.layout.ivis.layout
{
	/**
	 * This is an interface for the updatable v-level graph objects.
	 * 
	 * @author Selcuk Onur Sumer
	 *
	 */
	public interface Updatable
	{
		/**
		 * Classes which implement this interface must implement an update
		 * method which may use the information in the given LGraphObject. 
		 * 
		 * @param lGraphObj		contains the l-level information of the object
		 */
		function update(lGraphObj:LGraphObject):void;
		
	}
}