package org.cytoscapeweb.view.layout.ivis.layout.cose
{
	import org.cytoscapeweb.view.layout.ivis.layout.fd.FDLayoutConstants;


	/**
	 * This class maintains the constants used by CoSE layout.
	 *
	 * @author: Ugur Dogrusoz
	 *
	 * Copyright: i-Vis Research Group, Bilkent University, 2007 - present
	 */
	public class CoSEConstants extends FDLayoutConstants
	{
	// -----------------------------------------------------------------------------
	// Section: CoSE layout user options
	// -----------------------------------------------------------------------------
		public static const DEFAULT_USE_SMART_IDEAL_EDGE_LENGTH_CALCULATION:Boolean= true;
		public static const DEFAULT_USE_MULTI_LEVEL_SCALING:Boolean= false;
		
	// -----------------------------------------------------------------------------
	// Section: CoSE layout remaining contants
	// -----------------------------------------------------------------------------
		/**
		 * Default distance between each level in radial layout
		 */
		public static const DEFAULT_RADIAL_SEPARATION:Number=
			FDLayoutConstants.DEFAULT_EDGE_LENGTH;
	
		/**
		 * Default separation of trees in a forest when tiled to a grid
		 */
		public static const DEFAULT_COMPONENT_SEPERATION:int= 60;
	}
}