package org.cytoscapeweb.view.layout.ivis.layout.cose
{
	/**
	 * This class implements Coarsening Graph specific data and functionality for edges.
	 *
	 * @author Alper Karaçelik
	 *
	 * Copyright: i-Vis Research Group, Bilkent University, 2007 - present
	 */
	public class CoarseningEdge extends CoSEEdge
	{
	// -----------------------------------------------------------------------------
	// Section: Constructors and initializations
	// -----------------------------------------------------------------------------
		/**
		 * Constructor
		 */
		public function CoarseningEdge(source:CoSENode = null,
									   target:CoSENode = null,
									   vEdge:* = null/*vEdge:Object = null*/)
		{
			super(source, target, vEdge);
		}
		
		/*
		public function CoarseningEdge()
		{
			this(null, null, null);
		}
		*/
	}
}